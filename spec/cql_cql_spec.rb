#
# ActiveFacts tests: Parse all CQL files and check the generated CQL.
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
  CQL_CQL_FAILURES = %w{
    Airline
    CompanyQuery
    Insurance
    OddIdentifier
    OrienteeringER
    ServiceDirector
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
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    actual_file = cql_file.sub(%r{examples/CQL/}, 'spec/actual/')

    it "should load CQL and dump valid CQL for #{cql_file}" do
      pending if CQL_CQL_FAILURES.include? File.basename(cql_file, ".cql")
      vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)

      # Build and save the actual file:
      cql_text = cql(vocabulary)
      File.open(actual_file, "w") { |f| f.write cql_text }

      expected_text = File.open(cql_file) {|f| f.read.strip_comments }.scan(/.*?\n/)
      cql_text.strip_comments.scan(/.*?\n/).should == expected_text
      File.delete(actual_file)  # It succeeded, we don't need the file.
    end
  end
end
