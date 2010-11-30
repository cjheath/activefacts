#
# ActiveFacts CQL Fact Type matching tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'rspec/expectations'

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
# require File.dirname(__FILE__) + '/../helpers/compiler_helper'  # Can't see how to include/extend these methods correctly

describe "When compiling a join, " do
  before :each do
    prefix = %q{
      vocabulary Tests;
      Boy is written as String;
      Girl is written as Integer;
      Age is written as Integer;
      Boy is of Age;
      Boy is going out with Girl, Girl is going out with Boy;
    }
    @compiler = ActiveFacts::CQL::Compiler.new('Test')
    @compiler.compile(prefix)
    @constellation = @compiler.vocabulary.constellation

    def self.baseline
      @base_facts = @constellation.FactType.values-@constellation.ImplicitFactType.values
      @base_objects = @constellation.ObjectType.values
    end

    baseline

    def self.fact_types
      @constellation.FactType.values-@base_facts-@constellation.ImplicitFactType.values
    end

    def self.object_types
      @constellation.ObjectType.values-@base_objects
    end

    def self.fact_pcs fact_type
      fact_type.all_role.map{|r| r.all_role_ref.map{|rr| rr.role_sequence.all_presence_constraint.to_a}}.flatten.uniq
    end

    def self.derivation fact_type
      join = (joins = @constellation.Join.values.to_a)[0]
      # PENDING: When the fact type's roles are projected, use this instead:
      # joins = fact_type.all_role.map{|r| r.all_join_role.map{|jr| jr.join}}.flatten.uniq
      joins.size.should == 1
      joins[0]
    end

    def self.compile string
      lambda {
        @compiler.compile string
      }.should_not raise_error
    end
  end

  shared_examples_for "single contractions" do
    it "should produce one fact type" do
      (new_fact_types = fact_types).size.should == 1
    end
    it "the fact type should have one reading" do
      fact_type = fact_types[0]
      fact_type.all_reading.size.should == 1
    end
    it "the fact type should have no presence constraints" do
      fact_type = fact_types[0]
      (pcs = fact_pcs(fact_type)).size.should == 0
    end
    it "should produce one join" do
      fact_type = fact_types[0]
      join = derivation(fact_type)
    end
    it "the join should have 3 nodes" do
      fact_type = fact_types[0]
      join = derivation(fact_type)
      nodes = join.all_join_node.to_a
      nodes.size.should == 3
    end
    it "the join should have 2 steps" do
      fact_type = fact_types[0]
      join = derivation(fact_type)
      steps = join.all_join_step.to_a
      steps.size.should == 2
    end

    it "and should project the fact type roles from the join" do
      pending "Join roles are not yet projected" do
        join = derivation(fact_type)
        joins = fact_type.all_role.map{|r| r.all_join_role.map{|jr| jr.join}}.flatten.uniq
        joins.size == 1
        joins.should == [join]
      end
    end
  end

  describe "right contractions having" do
    describe "a single contraction using 'who'" do
      before :each do
        compile %q{Boy is relevant where Girl is going out with Boy who is of Age; }
      end

      it_should_behave_like "single contractions"
    end

    describe "a single contraction using 'that'" do
      before :each do
        compile %q{Boy is relevant where Girl is going out with Boy that is of Age; }
      end

      it_should_behave_like "single contractions"
    end
  end

  describe "left contractions having" do
    describe "a single contraction" do
      before :each do
        compile %q{Boy is relevant where Boy is of Age and is going out with Girl; }
      end

      it_should_behave_like "single contractions"
    end
  end
end
