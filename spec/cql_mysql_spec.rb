#
# ActiveFacts tests: Parse all CQL files and check the generated SQL.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/sql/mysql'

include ActiveFacts
include ActiveFacts::Metamodel

describe "CQL Loader with SQL output" do
  cql_failures = {
    "Airline" => "Contains queries, unsupported",
    "CompanyQuery" => "Contains queries, unsupported",
    "OrienteeringER" => "Doesn't parse due to difficult fact type match",
    "ServiceDirector" => "Doesn't parse some constraints due to mis-matched adjectives"
  }
  cql_mysql_failures = {
    "Metamodel" => "An index to enforce uniqueness on the nesting fact type isn't emitted",
  }

  # Generate and return the SQL for the given vocabulary
  def sql(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::SQL::MYSQL.new(vocabulary.constellation, "norma")
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    actual_file = cql_file.sub(%r{examples/CQL/(.*).cql}, 'spec/actual/\1.my.sql')
    expected_file = cql_file.sub(%r{examples/CQL/(.*).cql\Z}, 'examples/MySQL/\1.sql')

    it "should load #{cql_file} and dump MySQL matching #{expected_file}" do
      broken = cql_failures[File.basename(cql_file, ".cql")]
      vocabulary = nil
      if broken
        pending(broken) {
          lambda { vocabulary = ActiveFacts::Input::CQL.readfile(cql_file) }.should_not raise_error
        }
      else
        lambda { vocabulary = ActiveFacts::Input::CQL.readfile(cql_file) }.should_not raise_error
      end

      # Build and save the actual file:
      sql_text = sql(vocabulary)
      File.open(actual_file, "w") { |f| f.write sql_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file
      broken = cql_mysql_failures[File.basename(actual_file, ".cql")]
      if broken
        pending(broken) {
          sql_text.should == File.open(expected_file) {|f| f.read }
        }
      else
        sql_text.should == File.open(expected_file) {|f| f.read }
        File.delete(actual_file)  # It succeeded, we don't need the file.
      end
    end
  end
end
