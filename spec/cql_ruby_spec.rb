#
# ActiveFacts tests: Parse all CQL files and check the generated Ruby.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/ruby'

include ActiveFacts

class String
  def strip_comments()
    c_comment = %r{/\*((?!\*/).)*\*/}m
    gsub(c_comment, '').gsub(%r{\n\n+},"\n")
  end
end

describe "CQL Loader with Ruby output" do
  KNOWN_FAILURES = %w{
    Airline
    CompanyDirectorEmployee
    CompanyQuery
    EmployeeManagerCEO
    Insurance
    Metamodel
    OrienteeringER
    ServiceDirector
  }

  # Generate and return the Ruby for the given vocabulary
  def ruby(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::RUBY.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  #Dir["examples/CQL/Bl*.cql"].each do |cql_file|
  #Dir["examples/CQL/Meta*.cql"].each do |cql_file|
  #Dir["examples/CQL/[ACG]*.cql"].each do |cql_file|
  Dir["examples/CQL/*.cql"].each do |cql_file|
    expected_file = cql_file.sub(%r{/CQL/(.*).cql\Z}, '/ruby/\1.rb')
    actual_file = cql_file.sub(%r{examples/CQL/(.*).cql\Z}, 'spec/actual/\1.rb')
    next unless File.exists? expected_file

    it "should load CQL and dump valid Ruby for #{cql_file}" do
      pending if KNOWN_FAILURES.include? File.basename(cql_file, ".cql")
      vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)

      # Build and save the actual file:
      ruby_text = ruby(vocabulary)
      File.open(actual_file, "w") { |f| f.write ruby_text }

      ruby_text.should == File.open(expected_file) {|f| f.read }
      File.delete(actual_file)  # It succeeded, we don't need the file.
    end
  end
end
