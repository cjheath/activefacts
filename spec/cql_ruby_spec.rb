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
  CQL_RUBY_FAILURES = %w{
    Airline
    CompanyQuery
    Insurance
    OrienteeringER
    Orienteering
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

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    expected_file = cql_file.sub(%r{/CQL/(.*).cql\Z}, '/ruby/\1.rb')
    actual_file = cql_file.sub(%r{examples/CQL/(.*).cql\Z}, 'spec/actual/\1.rb')

    it "should load #{cql_file} and dump Ruby matching #{expected_file}" do
      pending if CQL_RUBY_FAILURES.include? File.basename(cql_file, ".cql")
      vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)

      # Build and save the actual file:
      ruby_text = ruby(vocabulary)
      File.open(actual_file, "w") { |f| f.write ruby_text }

      pending unless File.exists? expected_file
      ruby_text.should == File.open(expected_file) {|f| f.read }
      File.delete(actual_file)  # It succeeded, we don't need the file.
    end
  end
end
