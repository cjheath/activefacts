#
# ActiveFacts tests: Parse all NORMA files and check the generated JSON.
# Copyright (c) 2011 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/orm'
require 'activefacts/generate/json'

describe "Norma Loader" do
  orm_failures = {
    "SubtypePI" => "Has an illegal uniqueness constraint",
  }

  # Generate and return the CQL for the given vocabulary
  def json(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::JSON.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  def sequential_uuids t
    i = 1
    sequence = {}
    t.gsub /"........-....-....-....-......"/ do |uuid|
      (sequence[uuid] ||= i += 1).to_s
    end
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/norma/#{pattern}.orm"].each do |orm_file|
    expected_file = orm_file.sub(%r{/norma/(.*).orm\Z}, '/json/\1.json')
    actual_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.json')
    base = File.basename(orm_file, ".orm")

    it "should load #{orm_file} and dump CQL matching #{expected_file}" do
      begin
        vocabulary = ActiveFacts::Input::ORM.readfile(orm_file, 'diagrams')
      rescue => e
        raise unless orm_failures.include?(base)
        pending orm_failures[base]
      end

      json_text = json(vocabulary)
      # Save the actual file:
      File.open(actual_file, "w") { |f| f.write json_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }
      sequential_uuids(json_text).should_not differ_from(sequential_uuids(expected_text))
      File.delete(actual_file)
    end
  end
end
