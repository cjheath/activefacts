#
# ActiveFacts tests: Parse all CQL files and check the generated CQL.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require File.dirname(__FILE__) + '/spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/cql'

describe "CQL Loader" do
  cql_failures = {
    "Airline" => "Contains queries, unsupported",
    "CompanyQuery" => "Contains queries, unsupported",
    #"MetamodelNext" => "Fails due to weak adjective/role matching",
    #"ServiceDirector" => "Doesn't parse some constraints due to mis-matched adjectives",
    #"OddIdentifier" => "The odd identifier is built correctly but cannot be found by the current implementation",
    "units" => "Unit verbalisation into CQL is not implemented"
  }
  cql_cql_failures = {
#    "Insurance" => "Misses a query in a subset constraint",
#    "OddIdentifier" => "Doesn't support identification of object fact types using mixed external/internal roles",
  }
  # Generate and return the CQL for the given vocabulary
  def cql(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::CQL.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    actual_file = cql_file.sub(%r{examples/CQL/}, 'spec/actual/')

    it "should load CQL and dump valid CQL for #{cql_file}" do
      broken = cql_failures[File.basename(actual_file, ".cql")]
      vocabulary = nil
      if broken
        pending(broken) {
          vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)
        }
      else
        begin
          vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)
        rescue => e
          debug :exception, "#{e.message}\n" +
            "\t#{e.backtrace*"\n\t"}"
          raise
        end
      end

      # Build and save the actual file:
      cql_text = cql(vocabulary)
      File.open(actual_file, "w") { |f| f.write cql_text }
      expected_text = File.open(cql_file) {|f| f.read }

      broken = cql_cql_failures[File.basename(actual_file, ".cql")]
      if broken
        pending(broken) {
          cql_text.should_not differ_from(expected_text)
        }
      else
        cql_text.should_not differ_from(expected_text)
        File.delete(actual_file)  # It succeeded, we don't need the file.
      end
    end
  end
end
