#
# ActiveFacts tests: Parse all CQL files and check the generated JSON Metadata
# Copyright (c) 2013 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/metadata/json'

describe "CQL Loader with JSON Metadata output" do
  cql_failures = {
    "Airline" => "Contains unsupported queries",
    "CompanyQuery" => "Contains unsupported queries",
  }
  cql_json_metadata_failures = {
    "OrienteeringER" => "Invalid model, it just works differently in CQL"
  }

  # Generate and return the JSON Metadata for the given vocabulary
  def json_metadata(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::Metadata::JSON.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    actual_file = cql_file.sub(%r{examples/CQL/(.*).cql}, 'spec/actual/\1.metadata.json')
    expected_file = cql_file.sub(%r{examples/CQL/(.*).cql\Z}, 'examples/json_metadata/\1.metadata.json')

    next unless ENV["AFTESTS"] || File.exists?(expected_file)

    it "should load #{cql_file} and dump JSON Metadata matching #{expected_file}" do
      vocabulary = nil
      broken = cql_failures[File.basename(cql_file, ".cql")]
      if broken
        pending(broken) {
          vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)
        }
      else
        vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)
      end
      vocabulary.finalise

      # Build and save the actual file:
      json_metadata_text = json_metadata(vocabulary)
      Dir.mkdir "spec/actual" rescue nil
      File.open(actual_file, "w") { |f| f.write json_metadata_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }
      broken = cql_json_metadata_failures[File.basename(cql_file, ".cql")]
      if broken
        pending(broken) {
          json_metadata_text.should_not differ_from(expected_text)
        }
      else
        json_metadata_text.should_not differ_from(expected_text)
        File.delete(actual_file)  # It succeeded, we don't need the file.
      end
    end
  end
end
