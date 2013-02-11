#
# ActiveFacts tests: Parse all CQL files and check the surrogate key transformation
# Copyright (c) 2012 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/absorption'
require 'activefacts/generate/transform/surrogate'

describe "CQL Loader with Surrogate transformation" do
  cql_failures = {
  }

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    expected_file = cql_file.sub(%r{/CQL/(.*).cql\Z}, '/transform-surrogate/\1.transform-surrogate')
    actual_file = cql_file.sub(%r{examples/CQL/(.*).cql\Z}, 'spec/actual/\1.transform-surrogate')

    next unless ENV["AFTESTS"] || File.exists?(expected_file)

    it "should load #{cql_file} and make transformations like #{expected_file}" do
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
      output = StringIO.new

      transformer = ActiveFacts::Generate::Transform::Surrogate.new(vocabulary)
      transformer.generate(output)

      absorption = ActiveFacts::Generate::Absorption.new(vocabulary)
      absorption.generate(output)

      # Save the output from the StringIO:
      output.rewind
      transformed_text = output.read
      Dir.mkdir "spec/actual" rescue nil
      File.open(actual_file, "w") { |f| f.write transformed_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }
      transformed_text.should_not differ_from(expected_text)
      File.delete(actual_file)  # It succeeded, we don't need the file.
    end
  end
end
