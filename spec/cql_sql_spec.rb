#
# ActiveFacts tests: Parse all CQL files and check the generated SQL.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'spec/spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/sql/server'

include ActiveFacts
include ActiveFacts::Metamodel

describe "CQL Loader with SQL output" do
  cql_failures = {
    "Airline" => "Contains unsupported queries",
    "CompanyQuery" => "Contains unsupported queries",
    "OrienteeringER" => "Large fact type reading cannot be matched",
    "ServiceDirector" => "Constraints contain adjectives that require looser matching",
  }
  cql_sql_failures = {
    "Blog" => "Drops uniqueness constraints",
    "CompanyDirectorEmployee" => "Names an index automatically from CQL, but explicitly from NORMA",
    "Insurance" => "CQL doesn't have an option for subtype separation",
    "Metamodel" =>
        "Names an index automatically from CQL, but explicitly from NORMA" + " " +
        "Drops uniqueness constraints",
    "Orienteering" =>
        "Names an index automatically from CQL, but explicitly from NORMA" + " " +
        "Drops uniqueness constraints",
    "RedundantDependency" => "Drops uniqueness constraints",
    "SubtypePI" => "Names an index automatically from CQL, but explicitly from NORMA",
    "Tests.Test5.Load" => "Names an index automatically from CQL, but explicitly from NORMA",
  }

  # Generate and return the SQL for the given vocabulary
  def sql(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::SQL::SERVER.new(vocabulary.constellation, "norma")
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    actual_file = cql_file.sub(%r{examples/CQL/(.*).cql}, 'spec/actual/\1.sql')
    expected_file = cql_file.sub(%r{examples/CQL/(.*).cql\Z}, 'examples/SQL/\1.sql')

    it "should load #{cql_file} and dump SQL matching #{expected_file}" do
      vocabulary = nil
      broken = cql_failures[File.basename(cql_file, ".cql")]
      if broken
        pending(broken) {
          vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)
        }
      else
        vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)
      end

      # Build and save the actual file:
      sql_text = sql(vocabulary)
      File.open(actual_file, "w") { |f| f.write sql_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }
      broken = cql_sql_failures[File.basename(cql_file, ".cql")]
      if broken
        pending(broken) {
          sql_text.should_not differ_from(expected_text)
        }
      else
        sql_text.should_not differ_from(expected_text)
        File.delete(actual_file)  # It succeeded, we don't need the file.
      end
    end
  end
end
