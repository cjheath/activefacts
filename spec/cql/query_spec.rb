#
# ActiveFacts CQL Queries
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'rspec/expectations'

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
require File.dirname(__FILE__) + '/../helpers/compile_helpers'

describe "a query" do
  describe "when compiled" do
    before :each do
      extend CompileHelpers

      prefix = %q{
        vocabulary Tests;
        Name is written as String;
        year/years converts to 365.25 day;
        Age is written as Integer year;
        Person is identified by its Name;
        Person is of Age;

        Company is identified by its Name;
        Directorship is where Person directs Company;
      }
      @compiler = ActiveFacts::CQL::Compiler.new('Test')
      @compiler.compile(prefix)
      @constellation = @compiler.vocabulary.constellation

      baseline
    end

    describe "over bare object types" do

      it "should contain a bare variable" do
        compile %q{Person? }
        queries.size.should == 1
        query = queries[0]
        query.all_variable.size.should == 1
        variable = query.all_variable.single
        variable.query.should == query
        variable.ordinal.should == 0
        variable.object_type.name.should == 'Person'
        variable.role_name.should == nil
        variable.subscript.should == nil
        variable.value.should == nil
        variable.all_aggregation_as_aggregated_variable.size.should == 0
        variable.all_aggregation.size.should == 0
        variable.all_play.size.should == 0
      end

      it "that's an objectification, should contain a bare variable" do
        compile %q{Directorship? }
        queries.size.should == 1
        query = queries[0]
        query.all_variable.size.should == 1
        variable = query.all_variable.single
        variable.query.should == query
        variable.ordinal.should == 0
        variable.object_type.name.should == 'Directorship'
        variable.role_name.should == nil
        variable.subscript.should == nil
        variable.value.should == nil
        variable.all_aggregation_as_aggregated_variable.size.should == 0
        variable.all_aggregation.size.should == 0
        variable.all_play.size.should == 0
      end

      it "should contain two bare variables for a cross-join" do
        compile %q{Person, Age? }
        queries.size.should == 1
        query = queries[0]
        query.all_variable.size.should == 2
        variable0, variable1 = *query.all_variable.to_a
        variable0.query.should == query
        variable0.ordinal.should == 0
        variable0.object_type.name.should == 'Person'
        variable0.role_name.should == nil
        variable0.subscript.should == nil
        variable0.value.should == nil
        variable0.all_aggregation_as_aggregated_variable.size.should == 0
        variable0.all_aggregation.size.should == 0
        variable0.all_play.size.should == 0

        variable1.query.should == query
        variable1.ordinal.should == 1
        variable1.object_type.name.should == 'Age'
        variable1.role_name.should == nil
        variable1.subscript.should == nil
        variable1.value.should == nil
        variable1.all_aggregation_as_aggregated_variable.size.should == 0
        variable1.all_aggregation.size.should == 0
        variable1.all_play.size.should == 0
      end
    end

    describe "relating two object types" do
      before :each do
        compile %q{which Person is of Age 21 years? }
      end

      it "should contain a single query" do
        # Check the query:
        queries.size.should == 1
        query = queries[0]
        query.all_variable.size.should == 2
      end

      it "should contain two variables" do
        query = queries[0]
        variable0, variable1 = *query.all_variable.to_a

        # Check the variables:
        variable0.query.should == query
        variable0.ordinal.should == 0
        variable0.object_type.name.should == 'Person'
        variable0.role_name.should == nil
        variable0.subscript.should == nil
        variable0.all_aggregation_as_aggregated_variable.size.should == 0
        variable0.all_aggregation.size.should == 0
        variable0.value.should == nil

        variable1.query.should == query
        variable1.ordinal.should == 1
        variable1.object_type.name.should == 'Age'
        variable1.role_name.should == nil
        variable1.subscript.should == nil
        variable1.all_aggregation_as_aggregated_variable.size.should == 0
        variable1.all_aggregation.size.should == 0
      end

      it "should preserve value bindings" do
        query = queries[0]
        variable0, variable1 = *query.all_variable.to_a

        # Check the value came through ok:
        value = variable1.value
        value.literal.should == "21"
        value.is_literal_string.should_not be_truthy
        value.unit.name.should == 'year'
      end

      it "each variable should have one play" do
        query = queries[0]
        variable0, variable1 = *query.all_variable.to_a

        variable0.all_play.size.should == 1
        play0 = variable0.all_play.single
        play0.all_step_as_input_play.size.should == 1
        play0.all_step_as_output_play.size.should == 0
        play0.step.should be_nil

        variable1.all_play.size.should == 1
        play1 = variable1.all_play.single
        play1.all_step_as_input_play.size.should == 0
        play1.all_step_as_output_play.size.should == 1
        play1.step.should be_nil
      end

      it "both plays should be through one step" do
        query = queries[0]
        variable0, variable1 = *query.all_variable.to_a
        play0 = variable0.all_play.single
        play1 = variable1.all_play.single
        step = play0.all_step_as_input_play.single

        # Check the step/play setup
        step.all_incidental_play.size.should == 0
        step.should == play1.all_step_as_output_play.single
      end

      it "the step should have correct characteristics" do
        query = queries[0]
        variable0, variable1 = *query.all_variable.to_a
        play0 = variable0.all_play.single
        play1 = variable1.all_play.single
        step = play0.all_step_as_input_play.single

        step.alternative_set.should == nil
        step.is_disallowed.should be_falsy
        step.is_optional.should be_falsy
        step.fact_type.should_not be_nil
        step.fact_type.default_reading.should == 'Person is of Age'
      end
      # print 'Variable roles: '; p variable.class.all_role.keys

      it "should project only the correct variables" do
        query = queries[0]
        variable0, variable1 = *query.all_variable.to_a
        play0 = variable0.all_play.single
        play1 = variable1.all_play.single

        # Check the projections:
        skip("No projections recorded for bare queries yet") { play0.role_ref.should_not be_nil }
        skip("No projections recorded for bare queries yet") { play1.role_ref.should be_nil }
      end

    end

    describe "delving into an objectified binary" do
      before :each do
        compile %q{Directorship (in which some Person (as Director) directs which Company)? }
      end

      it "should contain a single query" do
        # Check the query:
        queries.size.should == 1
        query = queries[0]
        query.all_variable.size.should == 3
      end

      it "should contain three variables" do
        query = queries[0]
        variable0, variable1, variable2 = *query.all_variable.to_a

        # Check the variables:
        variable0.query.should == query
        variable0.ordinal.should == 0
        variable0.object_type.name.should == 'Directorship'
        variable0.role_name.should == nil
        variable0.subscript.should == nil
        variable0.all_aggregation_as_aggregated_variable.size.should == 0
        variable0.all_aggregation.size.should == 0
        variable0.value.should == nil

        variable1.query.should == query
        variable1.ordinal.should == 1
        variable1.object_type.name.should == 'Person'
        variable1.subscript.should == nil
        variable1.all_aggregation_as_aggregated_variable.size.should == 0
        variable1.all_aggregation.size.should == 0

        variable2.query.should == query
        variable2.ordinal.should == 2
        variable2.object_type.name.should == 'Company'
        variable2.role_name.should == nil
        variable2.subscript.should == nil
        variable2.all_aggregation_as_aggregated_variable.size.should == 0
        variable2.all_aggregation.size.should == 0
      end

      it "should assign variable's role names" do
        query = queries[0]
        variable0, variable1, variable2 = *query.all_variable.to_a

        skip("Role names are not yet assigned in queries") {variable1.role_name.should == 'Director'}
      end

      it "the variables should have the right plays" do
        query = queries[0]
        variable0, variable1, variable2 = *query.all_variable.to_a

        variable0.all_play.size.should == 1
        variable1.all_play.size.should == 1
        variable2.all_play.size.should == 1

        play0 = variable0.all_play.single
        play0.all_step_as_input_play.size.should == 1
        play0.all_step_as_output_play.size.should == 0
        play0.step.should be_nil
        step0i = play0.all_step_as_input_play.single

        variable1.all_play.size.should == 1
        play1 = variable1.all_play.single
        play1.all_step_as_input_play.size.should == 1
        play1.all_step_as_output_play.size.should == 1
        play1.step.should be_nil
        step1i = play1.all_step_as_input_play.single
        step1o = play1.all_step_as_input_play.single

        variable2.all_play.size.should == 1
        play2 = variable2.all_play.single
        play2.all_step_as_input_play.size.should == 0
        play2.all_step_as_output_play.size.should == 1
        play2.step.should be_nil
        step2o = play2.all_step_as_output_play.single

        step0i.fact_type.should be_kind_of(ActiveFacts::Metamodel::LinkFactType)
        step0i.fact_type.default_reading.should == 'Directorship involves Person'

        step1i.should == step1o
        step1i.should == step2o
        step1i.fact_type.default_reading.should == 'Person directs Company'

      end

    end

  end

  describe "when verbalised" do
    #it "should fail a failing test" do
    #  false.should be_truthy
    #end
  end
end
