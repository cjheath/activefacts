#
# ActiveFacts tests: Parse all NORMA files and check the generated JSON Metadata
# Copyright (c) 2013 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/orm'
require 'activefacts/generate/metadata/json'

describe "NORMA Loader with JSON Metadata output" do
  orm_failures = {
  }
  norma_metadata_json_failures = {
  }

  # Generate and return the JSON Metadata for the given vocabulary
  def metadata_json(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::Metadata::JSON.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/norma/#{pattern}.orm"].each do |orm_file|
    expected_file = orm_file.sub(%r{/norma/(.*).orm\Z}, '/metadata_json/\1.metadata.json')
    actual_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.metadata.json')
    base = File.basename(orm_file, ".orm")

    next unless ENV["AFTESTS"] || File.exists?(expected_file)

    it "should load #{orm_file} and dump JSON Metadata matching #{expected_file}" do
      vocabulary = nil
      begin
        vocabulary = ActiveFacts::Input::ORM.readfile(orm_file)
      rescue => e
        raise unless orm_failures.include?(base)
        pending orm_failures[base]
      end
      vocabulary.finalise

      # Build and save the actual file:
      metadata_json_text = metadata_json(vocabulary)
      Dir.mkdir "spec/actual" rescue nil
      File.open(actual_file, "w") { |f| f.write metadata_json_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }
      broken = norma_metadata_json_failures[base]
      if broken
        pending(broken) {
          metadata_json_text.should_not differ_from(expected_text)
        }
      else
        metadata_json_text.should_not differ_from(expected_text)
        File.delete(actual_file)  # It succeeded, we don't need the file.
      end
    end
  end
end
