#
# ActiveFacts tests: Parse all CQL files and check the generated Rails models
# Copyright (c) 2013 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
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
    @dumper = ActiveFacts::Generate::Rails::Models.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    actual_file = cql_file.sub(%r{examples/CQL/(.*).cql}, 'spec/actual/\1.models')
    expected_file = cql_file.sub(%r{examples/CQL/(.*).cql\Z}, 'examples/models/\1.models')

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

      # Build and save the actual file:
      models_text = models(vocabulary)
      File.open(actual_file, "w") { |f| f.write models_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }
      broken = cql_models_failures[File.basename(cql_file, ".cql")]
      if broken
        pending(broken) {
          models_text.should_not differ_from(expected_text)
        }
      else
        # Discard index names:
        models_text.gsub!(/ INDEX (\[[^\]]*\]|`[^`]*`|[^ ]*) ON /, ' INDEX <Name is hidden> ON ')
        expected_text.gsub!(/ INDEX (\[[^\]]*\]|`[^`]*`|[^ ]*) ON /, ' INDEX <Name is hidden> ON ')
        models_text.should_not differ_from(expected_text)
        File.delete(actual_file)  # It succeeded, we don't need the file.
      end
    end
  end
end
