#
# ActiveFacts tests: Parse all CQL files and check the generated Rails schema.rb
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/rails/schema'

describe "CQL Loader with Rails schema.rb output" do
  cql_failures = {
    "Airline" => "Contains unsupported queries",
    "CompanyQuery" => "Contains unsupported queries",
  }
  cql_schemarb_failures = {
    "OrienteeringER" => "Invalid model, it just works differently in CQL"
  }

  # Generate and return the Rails schema.rb for the given vocabulary
  def schemarb(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::Rails::SchemaRb.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    actual_file = cql_file.sub(%r{examples/CQL/(.*).cql}, 'spec/actual/\1.schemarb')
    expected_file = cql_file.sub(%r{examples/CQL/(.*).cql\Z}, 'examples/schemarb/\1.schemarb')

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

      # Build and save the actual file:
      schemarb_text = schemarb(vocabulary)
      File.open(actual_file, "w") { |f| f.write schemarb_text }

      schemarb_text.sub!(/(Schema.define\(:version => )[0-9]*/, '\1')
      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }.sub(/(Schema.define\(:version => )[0-9]*/, '\1')
      broken = cql_schemarb_failures[File.basename(cql_file, ".cql")]
      if broken
        pending(broken) {
          schemarb_text.should_not differ_from(expected_text)
        }
      else
        # Discard index names:
        schemarb_text.gsub!(/ INDEX (\[[^\]]*\]|`[^`]*`|[^ ]*) ON /, ' INDEX <Name is hidden> ON ')
        expected_text.gsub!(/ INDEX (\[[^\]]*\]|`[^`]*`|[^ ]*) ON /, ' INDEX <Name is hidden> ON ')
        schemarb_text.should_not differ_from(expected_text)
        File.delete(actual_file)  # It succeeded, we don't need the file.
      end
    end
  end
end
