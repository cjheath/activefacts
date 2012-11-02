#
# ActiveFacts tests: Parse all NORMA files and check the generated CQL.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/orm'
require 'activefacts/generate/cql'

describe "Norma Loader" do
  orm_failures = {
    "SubtypePI" => "Has an illegal uniqueness constraint",
  }
  orm_cql_failures = {
    # "OddIdentifier" => "Strange identification pattern is incorrectly verbalised to CQL",  # Fixed
    "UnaryIdentification" => "No PI for VisitStatus",
    "Supervision" => "Derivations are not imported from NORMA",
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
  Dir["examples/norma/#{pattern}.orm"].each do |orm_file|
    expected_file = orm_file.sub(%r{/norma/(.*).orm\Z}, '/CQL/\1.cql')
    actual_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.cql')
    base = File.basename(orm_file, ".orm")

    it "should load #{orm_file} and dump CQL matching #{expected_file}" do
      begin
        vocabulary = ActiveFacts::Input::ORM.readfile(orm_file)
      rescue => e
        raise unless orm_failures.include?(base)
        pending orm_failures[base]
      end

      cql_text = cql(vocabulary)
      # Save the actual file:
      File.open(actual_file, "w") { |f| f.write cql_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }

      broken = orm_cql_failures[base]
      if broken
        pending(broken) {
          cql_text.should_not differ_from(expected_text)
        }
      else
        cql_text.should_not differ_from(expected_text)
        File.delete(actual_file)
      end
    end
  end
end
