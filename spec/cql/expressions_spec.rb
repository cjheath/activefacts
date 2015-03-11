#
# ActiveFacts CQL Expressions
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'rspec/expectations'

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
require File.dirname(__FILE__) + '/../helpers/compile_helpers'

describe "When compiling expressions" do
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

  describe "expressions" do

    it "should create appropriate fact types" do
      compile %q{Person is of Age >= 3*(9+11)? }

      new_fact_types = fact_types
      # new_fact_types.each { |ft| puts "new fact type: #{ft.default_reading}" }
      new_fact_types.size.should == 3
  end

  it "should create derived fact types and project the roles" do
      compile %q{Person is old where Person is of Age >= 3*(9+11); }

      new_fact_types = fact_types
      # new_fact_types.each { |ft| puts "new fact type: #{ft.default_reading}" }
      new_fact_types.size.should == 4

      is_old_ft = new_fact_types.detect{|ft| ft.all_reading.detect{|r| r.text =~ /is old/} }
      (is_old_ft.all_reading.map{ |r| r.expand }*', ').should == "Person is old"

      new_readings = new_fact_types.
	reject{|ft| ft == is_old_ft}.
	map{|ft| ft.all_reading.map{|r| r.expand}*", "}

      new_readings.should include("Boolean = Age >= PRODUCT_OF<Integer SUM_OF<Integer, Integer>>")
      new_readings.should include("PRODUCT_OF<Integer SUM_OF<Integer, Integer>> = Integer * SUM_OF<Integer, Integer>")
      new_readings.should include("SUM_OF<Integer, Integer> = Integer + Integer")

      # one_query_with_value 60, 'year'
    end
  end
end
