#
# ActiveFacts tests: Parse all NORMA files and check the generated CQL.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/cql'

include ActiveFacts

describe "CQL Parser" do
  KNOWN_FAILURES = %w{
    Airline
    CompanyDirectorEmployee
    CompanyQuery
    EmployeeManagerCEO
    Insurance
    Metamodel
    OrienteeringER
  }

  #Dir["examples/CQL/Bl*.cql"].each do |cql_file|
  #Dir["examples/CQL/Meta*.cql"].each do |cql_file|
  #Dir["examples/CQL/[ACG]*.cql"].each do |cql_file|
  Dir["examples/CQL/*.cql"].each do |cql_file|
    it "should load CQL #{cql_file} without parse errors" do
      pending if KNOWN_FAILURES.include? File.basename(cql_file, ".cql")
      lambda { vocabulary = ActiveFacts::Input::CQL.readfile(cql_file) }.should_not raise_error
    end
  end
end
