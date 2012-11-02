#
# ActiveFacts CQL Comparison Fact Type tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'rspec/expectations'

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
require File.dirname(__FILE__) + '/../helpers/compile_helpers'

describe "When matching a reading with an existing fact type" do
  before :each do
    extend CompileHelpers

    prefix = %q{
      vocabulary Tests;
      Name is written as String;
      year/years converts to 365.25 day;
      Age is written as Integer year;
      Person is identified by its Name;
      Person is of Age;

      // Company is identified by its Name;
      // Directorship is where Person directs Company;
    }
    @compiler = ActiveFacts::CQL::Compiler.new('Test')
    @compiler.compile(prefix)
    @constellation = @compiler.vocabulary.constellation

    baseline
  end

  describe "equality comparisons" do
    before :each do
      #debug_enable("binding"); debug_enable("matching"); debug_enable("matching_fails"); debug_enable("parse")
    end
    after :each do
      #debug_disable("binding"); debug_disable("matching"); debug_disable("matching_fails"); debug_disable("parse")
    end

    def value_should_match value, lit, unit = nil
      value.should_not be_nil
      value.literal.should == lit.to_s
      (!!value.is_a_string).should == lit.is_a?(String)
      if unit
        value.unit.should_not be_nil
        value.unit.name.should == unit
      else
        value.unit.should be_nil
      end
    end

    def one_query_with_value v, unit = nil
      queries.size.should == 1
      (jss = steps).size.should == 2
      (jns = variables).size.should == 3
      integer_node = jns.detect{|jn| jn.object_type.name == 'Integer'}
      integer_node.should_not be_nil
      value_should_match integer_node.value, v, unit
      # pending should test content of the steps
    end

    it "should create a comparison fact type" do
      compile %q{Person is old where Person is of Age >= 60 years; }
      (new_fact_types = fact_types).size.should == 2

      is_old_ft = new_fact_types.detect{|ft| ft.all_reading.detect{|r| r.text =~ /is old/} }
      (is_old_ft.all_reading.map{ |r| r.expand }*', ').should == "Person is old"

      comparison_ft = (new_fact_types - [is_old_ft])[0]
      (comparison_ft.all_reading.map{ |r| r.expand }*', ').should == "Boolean = Age >= Integer"

      one_query_with_value 60, 'year'
    end

    it "should create a comparison fact type twice without duplication"

    it "should parse a query and comparison fact type" do
      compile %q{Person is of Age >= 60 years? }
      (new_fact_types = fact_types).size.should == 1
      (readings = new_fact_types[0].all_reading).size.should == 1
      readings.single.text.should == '{0} = {1} >= {2}'

      one_query_with_value 60, 'year'
    end
  end
end
