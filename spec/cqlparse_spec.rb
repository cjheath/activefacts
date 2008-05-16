#
# ActiveFacts tests: parse all CQL files
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/cql/parser'
require 'activefacts/generate/cql'

describe "CQL Parser" do
  # Generate and return the CQL for the given vocabulary
  def cql(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::CQLDumper.new(vocabulary.constellation)
    @dumper.dump(output)
    output.rewind
    output.readlines
  end

  #Dir["examples/CQL/Bl*.cql"].each do |cql_in|
  Dir["examples/CQL/Metamodel.cql"].each do |cql_in|
  #Dir["examples/CQL/*.cql"].each do |cql_in|
    expected_file = cql_in.sub(%r{/CQL/(.*).cql\Z}, '/CQL/\1.cql')
    next unless File.exists? expected_file

    it "should load and dump valid CQL for #{cql_in}" do
      parser = ActiveFacts::CQLParser.new
      result = File.open(cql_in) { |f|
          parser.parse(f.read)
        }
      result.should_not be_nil

      # REVISIT: result should be able to derive a vocabulary that we can dump
      #puts "=============================== #{cql_in} ==============================="
      #p result.definitions

      # cql(vocabulary).sort.should == File.open(expected_file) {|f| f.readlines}.sort
    end
  end
end
