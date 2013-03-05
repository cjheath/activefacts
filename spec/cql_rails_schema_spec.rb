#
# ActiveFacts tests: Parse all CQL files and check the generated Rails schema.rb
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/transform/surrogate'
require 'activefacts/generate/rails/schema'

describe "CQL Loader with Rails schema.rb output" do
  cql_failures = {
    "Airline" => "Contains unsupported queries",
    "CompanyQuery" => "Contains unsupported queries",
  }
  cql_schema_rb_failures = {
    "OrienteeringER" => "Invalid model, it just works differently in CQL"
  }

  # Generate and return the Rails schema.rb for the given vocabulary
  def schema_rb(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::Rails::SchemaRb.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    actual_file = cql_file.sub(%r{examples/CQL/(.*).cql}, 'spec/actual/\1.schema.rb')
    expected_file = cql_file.sub(%r{examples/CQL/(.*).cql\Z}, 'examples/schema_rb/\1.schema.rb')

    next unless ENV["AFTESTS"] || File.exists?(expected_file)

    it "should load #{cql_file} and dump Rails schema.rb matching #{expected_file}" do
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
      schema_rb_text = schema_rb(vocabulary)
      Dir.mkdir "spec/actual" rescue nil
      File.open(actual_file, "w") { |f| f.write schema_rb_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }
      broken = cql_schema_rb_failures[File.basename(cql_file, ".cql")]
      if broken
        pending(broken) {
          schema_rb_text.should_not differ_from(expected_text)
        }
      else
        # Discard version timestamps:
        schema_rb_text.gsub!(/(Schema.define\(:version => |# schema.rb auto-generated using ActiveFacts for .* on )[-0-9]*/, '\1')
        expected_text.gsub!(/(Schema.define\(:version => |# schema.rb auto-generated using ActiveFacts for .* on )[-0-9]*/, '\1')
        schema_rb_text.should_not differ_from(expected_text)
        File.delete(actual_file)  # It succeeded, we don't need the file.
      end
    end
  end
end
