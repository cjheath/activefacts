#
# ActiveFacts tests: Parse all CQL files and check the generated Rails models
# Copyright (c) 2013 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/transform/surrogate'
require 'activefacts/generate/rails/models'

describe "CQL Loader with Rails models output" do
  cql_failures = {
    "Airline" => "Contains unsupported queries",
    "CompanyQuery" => "Contains unsupported queries",
  }
  cql_models_failures = {
    "OrienteeringER" => "Invalid model, it just works differently in CQL"
  }

  # Generate and return the Rails models for the given vocabulary
  def models(vocabulary)
    output = StringIO.new

    @dumper = ActiveFacts::Generate::Rails::Models.new(vocabulary.constellation, "concern=Concernz")
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    actual_file = cql_file.sub(%r{examples/CQL/(.*).cql}, 'spec/actual/\1.models')
    expected_file = cql_file.sub(%r{examples/CQL/(.*).cql\Z}, 'examples/models/\1.models')

    next unless ENV["AFTESTS"] || File.exists?(expected_file)

    it "should load #{cql_file} and dump Rails models matching #{expected_file}" do
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

      transformer = ActiveFacts::Generate::Transform::Surrogate.new(vocabulary)
      transformer.generate(nil)

      # Build and save the actual file:
      models_text = models(vocabulary)
      Dir.mkdir "spec/actual" rescue nil
      File.open(actual_file, "w") { |f| f.write models_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }
      broken = cql_models_failures[File.basename(cql_file, ".cql")]
      if broken
        pending(broken) {
          models_text.should_not differ_from(expected_text)
        }
      else
        models_text.should_not differ_from(expected_text)
        File.delete(actual_file)  # It succeeded, we don't need the file.
      end
    end
  end
end
