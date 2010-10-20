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

describe "CQL Loader with SQL output" do
  cql_failures = {
    "Airline" => "Contains unsupported queries",
    "CompanyQuery" => "Contains unsupported queries",
  }
  cql_sql_failures = {
    "OrienteeringER" => "Invalid model, it just works differently in CQL"
  }

  # Generate and return the SQL for the given vocabulary
  def sql(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::SQL::SERVER.new(vocabulary.constellation)
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
        # Discard index names:
        sql_text.gsub!(/ INDEX (\[[^\]]*\]|`[^`]*`|[^ ]*) ON /, ' INDEX <Name is hidden> ON ')
        expected_text.gsub!(/ INDEX (\[[^\]]*\]|`[^`]*`|[^ ]*) ON /, ' INDEX <Name is hidden> ON ')
        sql_text.should_not differ_from(expected_text)
        File.delete(actual_file)  # It succeeded, we don't need the file.
      end
    end
  end
end
