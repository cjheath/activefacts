#
# ActiveFacts tests: Parse all NORMA files and check the generated CQL.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/cql'

include ActiveFacts

class String
  def strip_comments()
    c_comment = %r{/\*((?!\*/).)*\*/}m
    gsub(c_comment, '').gsub(%r{\n\n+},"\n")
  end
end

describe "CQL Loader" do
  # Generate and return the CQL for the given vocabulary
  def cql(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::CQL.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  #Dir["examples/CQL/Bl*.cql"].each do |cql_file|
  #Dir["examples/CQL/Meta*.cql"].each do |cql_file|
  #Dir["examples/CQL/[ACG]*.cql"].each do |cql_file|
  Dir["examples/CQL/*.cql"].each do |cql_file|
    actual_file = cql_file.sub(%r{examples/CQL/}, 'spec/actual/')

    it "should load and dump valid CQL for #{cql_file}" do
      vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)

      # Build and save the actual file:
      cql_text = cql(vocabulary)
      File.open(actual_file, "w") { |f| f.write cql_text }

      expected_text = File.open(cql_file) {|f| f.read.strip_comments }.scan(/.*?\n/)
      cql_text.strip_comments.scan(/.*?\n/).should == expected_text
      File.delete(actual_file)  # It succeeded, we don't need the file.
    end
  end

  it "should handle role names in identifiers, with and without adjectives and duplicate role players"
end
