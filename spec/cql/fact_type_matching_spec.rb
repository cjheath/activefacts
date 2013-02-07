#
# ActiveFacts CQL Fact Type matching tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
$: << Dir::getwd

require 'rspec/expectations'

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
require File.dirname(__FILE__) + '/../helpers/compile_helpers'

describe "When matching a reading" do
  before :each do
    extend CompileHelpers

    prefix = %q{
      vocabulary Tests;
      Boy is written as String;
      Girl is written as Integer;
    }
    @compiler = ActiveFacts::CQL::Compiler.new('Test')
    @compiler.compile(prefix)
    @compiler.vocabulary.finalise
    @constellation = @compiler.vocabulary.constellation

    baseline
  end

  describe "with no existing fact type" do
    it "should create a simple fact type" do
      compile %q{Girl is going out with at most one Boy; }
      (new_fact_types = fact_types).size.should == 1
      (fact_type = new_fact_types[0]).all_reading.size.should == 1
      (pcs = fact_pcs(fact_type)).size.should == 1
    end

    it "should create a simple fact type using an explicit adjective" do
      compile %q{Girl is going out with at most one ugly-Boy;}
      (new_fact_types = fact_types).size.should == 1
      (fact_type = new_fact_types[0]).all_reading.size.should == 1
      (pcs = fact_pcs(fact_type)).size.should == 1
    end
  end

  describe "on an existing fact type" do
    before :each do
      #debug_enable("binding"); debug_enable("matching"); debug_enable("matching_fails"); debug_enable("parse")
    end
    after :each do
      #debug_disable("binding"); debug_disable("matching"); debug_disable("matching_fails"); debug_disable("parse")
    end

    describe "with no adjectives or role names" do
      before :each do
        compile %q{Girl is going out with at most one Boy;}
        # baseline
      end

      it "should recognise and add a reading" do
        compile %q{
            Girl is going out with Boy,
              Boy is going out with Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 1
      end

      it "should remove duplicate new readings" do
        pending("duplicate new clauses cause an error") do
          compile %q{
              Girl is going out with Boy,
                Girl is going out with Boy,
                Boy is going out with Girl,
                Boy is going out with Girl;
            }
          (new_fact_types = fact_types).size.should == 1
          (fact_type = new_fact_types[0]).all_reading.size.should == 2
          (pcs = fact_pcs(fact_type)).size.should == 1
        end
      end

      it "should add new presence constraints" do
        compile %q{
            Girl is going out with Boy,
            Boy is going out with at most one Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 2
      end

      it "should add a new reading with a hyphenated word" do
        compile %q{
            Girl is going out with Boy,
            Boy is out driving a semi-trailer with Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (readings = (fact_type = new_fact_types[0]).all_reading.to_a).size.should == 2
        readings.detect{|r| r.text =~ /semi-trailer/}.should be_true
        (pcs = fact_pcs(fact_type)).size.should == 1
      end

    end

    describe "with role names" do
      before :each do
        compile %q{Girl (as Girlfriend) is going out with at most one Boy;}
        # baseline
      end

      it "should match role names" do
        pending("duplicate new clauses cause an error") do
          compile %q{
              Girl (as Girlfriend) is going out with Boy,
              Boy is going out with Girlfriend;
            }
          (new_fact_types = fact_types).size.should == 1
          (fact_type = new_fact_types[0]).all_reading.size.should == 3
          (pcs = fact_pcs(fact_type)).size.should == 2
        end
      end
    end

    describe "with a leading adjective" do
      before :each do
        compile %q{Girl is going out with at most one ugly-Boy;}
        @fact_type = fact_types[0]
        @initial_reading = fact_readings(@fact_type)[0]
        # baseline
      end

      it "should not match without the adjective" do
        baseline
        compile %q{
            Girl is going out with at most one Boy,
            Boy is best friend of Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        new_fact_types[0].all_reading.size.should == 2
        fact_pcs(new_fact_types[0]).size.should == 1
      end

      it "should not match without the adjective and with the new reading first" do
        baseline
        compile %q{
            Boy is best friend of Girl,
            Girl is going out with at most one Boy;
          }
        (new_fact_types = fact_types).size.should == 1
        new_fact_types[0].all_reading.size.should == 2
        fact_pcs(new_fact_types[0]).size.should == 1
      end

      it "should match using explicit adjective" do
        compile %q{
            Girl is going out with at most one ugly-Boy,
            Boy is best friend of Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 1
      end

      it "should match using implicit adjective" do
        compile %q{
            Girl is going out with ugly Boy,
            ugly-Boy is best friend of Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 1
      end

      it "should match using implicit adjective and new explicit trailing adjective" do
        compile %q{
            Girl is going out with ugly Boy-monster,
            Boy monster is going out with Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        new_reading = (fact_readings(@fact_type) - [@initial_reading])[0]
        new_reading.text.should == "{0} is going out with {1}"
        new_reading.role_sequence.all_role_ref_in_order[0].trailing_adjective.should == "monster"
        (pcs = fact_pcs(fact_type)).size.should == 1
      end
    end

    describe "with a trailing adjective" do
      before :each do
        compile %q{Girl is going out with at most one Boy-monster;}
        # baseline
      end

      it "should match using explicit adjective" do
        compile %q{
            Girl is going out with Boy-monster,
            Boy is going out with Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 1
      end

      it "should match using implicit adjective" do
        compile %q{
            Girl is going out with Boy monster,
            Boy is going out with Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 1
      end

      it "should match using implicit adjective and new explicit leading adjective" do
        baseline
        compile %q{
            Girl is going out with ugly-Boy monster,
            Boy is going out with Girl;
          }
	@compiler.vocabulary.finalise
        (new_fact_types = fact_types).size.should == 1
        fact_type = new_fact_types[0]
        fact_type.all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 1
      end
    end

    describe "with double adjectives" do
      before :each do
        compile %q{Girl is going out with at most one ugly- bad Boy;}
        # baseline
      end

      it "should match using explicit adjectives" do
        compile %q{
            Girl is going out with ugly- bad Boy,
            ugly- bad Boy is going out with Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 1
      end

      it "should match using implicit adjectives" do
        compile %q{
            Girl is going out with ugly bad Boy,
            nasty- ugly bad Boy is going out with Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 1
      end
    end

    describe "with double trailing adjectives" do
      before :each do
        compile %q{Girl is going out with at most one Boy real -monster;}
        # baseline
      end

      it "should match using explicit adjectives" do
        compile %q{
            Girl is going out with Boy real -monster,
            Boy is going out with Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 1
      end

      it "should match using implicit adjectives" do
        compile %q{
            Girl is going out with Boy real monster,
            Boy is going out with Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 1
      end
    end

    describe "with hyphenated adjectives" do
      before :each do
        compile %q{Girl is going out with at most one butt-- ugly Boy;}
        # baseline
      end

      it "should compile them correctly" do
        (new_fact_types = fact_types).size.should == 1
        (readings = new_fact_types[0].all_reading).size.should == 1
        (role_refs = readings.single.role_sequence.all_role_ref).size.should == 2
        (boy_role_ref = role_refs.sort_by{|rr| rr.ordinal}[1])
        boy_role_ref.leading_adjective.should == 'butt-ugly'
      end

      it "should match using explicit adjectives" do
        compile %q{
            Girl is going out with butt-- ugly Boy,
            butt-ugly Boy is going out with Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 1
        # REVISIT: Check new and existing reading
      end

      it "should match using implicit adjectives" do
        compile %q{
            Girl is going out with butt-- ugly Boy,
            butt-ugly Boy is going out with Girl;
          }
        (new_fact_types = fact_types).size.should == 1
        (fact_type = new_fact_types[0]).all_reading.size.should == 2
        (pcs = fact_pcs(fact_type)).size.should == 1
        # REVISIT: Check new and existing reading
      end
    end

    describe "with hyphenated trailing adjectives" do
      before :each do
        compile %q{Girl is going out with at most one Boy tres --gross;}
        # baseline
      end

      it "should compile them correctly" do
        (new_fact_types = fact_types).size.should == 1
        (readings = new_fact_types[0].all_reading).size.should == 1
        (role_refs = readings.single.role_sequence.all_role_ref).size.should == 2
        (boy_role_ref = role_refs.sort_by{|rr| rr.ordinal}[1])
        boy_role_ref.trailing_adjective.should == 'tres-gross'
      end

    end
  end
end
