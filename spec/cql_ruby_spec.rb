#
# ActiveFacts tests: Parse all CQL files and check the generated Ruby.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'spec/spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/ruby'

class String
  def strip_comments()
    c_comment = %r{/\*((?!\*/).)*\*/}m
    gsub(c_comment, '').gsub(%r{\n\n+},"\n")
  end
end

describe "CQL Loader with Ruby output" do
  cql_failures = {
    "Airline" => "Contains queries, not supported",
    "CompanyQuery" => "Contains queries, not supported",
    "OrienteeringER" => "Invalid model, it just works differently in CQL"
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
      vocabulary = nil
      broken = cql_failures[File.basename(cql_file, ".cql")]
      if broken
        pending(broken) {
          vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)
        }
      else
        vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)
      end

      # Build and save the actual file:
      ruby_text = ruby(vocabulary)
      File.open(actual_file, "w") { |f| f.write ruby_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }
#      if broken
#        pending(broken) {
#          ruby_text.should == File.open(expected_file) {|f| f.read }
#        }
#      else
        ruby_text.should_not differ_from(expected_text)
        File.delete(actual_file)  # It succeeded, we don't need the file.
#      end
    end
  end
end
