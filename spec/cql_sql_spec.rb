#
# ActiveFacts tests: Parse all CQL files and check the generated SQL.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/sql/server'

include ActiveFacts
include ActiveFacts::Metamodel

describe "CQL Loader with SQL output" do
  CQL_SQL_FAILURES = %w{
    Airline
    CompanyQuery
    Insurance
    OrienteeringER
    ServiceDirector
    SimplestUnary
  }

  # Generate and return the SQL for the given vocabulary
  def sql(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::SQL::SERVER.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  #Dir["examples/CQL/Bl*.cql"].each do |cql_file|
  #Dir["examples/CQL/Meta*.cql"].each do |cql_file|
  #Dir["examples/CQL/[ACG]*.cql"].each do |cql_file|
  Dir["examples/CQL/*.cql"].each do |cql_file|
    actual_file = cql_file.sub(%r{examples/CQL/(.*).cql}, 'spec/actual/\1.sql')
    expected_file = cql_file.sub(%r{examples/CQL/(.*).cql\Z}, 'examples/SQL/\1.sql')

    it "should load #{cql_file} and dump SQL matching #{expected_file}" do
      pending if CQL_SQL_FAILURES.include? File.basename(cql_file, ".cql")
      vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)

      # Build and save the actual file:
      sql_text = sql(vocabulary)
      File.open(actual_file, "w") { |f| f.write sql_text }

      pending unless File.exists? expected_file
      sql_text.should == File.open(expected_file) {|f| f.read }
      File.delete(actual_file)  # It succeeded, we don't need the file.
    end
  end
end
