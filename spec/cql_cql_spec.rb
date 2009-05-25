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
  cql_failures = {
    "Airline" => "Contains queries, unsupported",
    "CompanyQuery" => "Contains queries, unsupported",
    "OrienteeringER" => "Doesn't parse due to difficult fact type match",
    "ServiceDirector" => "Doesn't parse some constraints due to mis-matched adjectives"
  }
  cql_cql_failures = {
    "Insurance" => "Misses a subtype join in a constraint verbalisation",
    "OddIdentifier" => "Doesn't support identification of object fact types using mixed external/internal roles",
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
      broken = cql_failures[File.basename(actual_file, ".cql")]
      vocabulary = nil
      if broken
        pending(broken) {
          vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)
        }
      else
        vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)
      end

      # Build and save the actual file:
      cql_text = cql(vocabulary)
      File.open(actual_file, "w") { |f| f.write cql_text }

      expected_text = File.open(cql_file) {|f| f.read.strip_comments }.scan(/.*?\n/)
      stripped_and_split = cql_text.strip_comments.scan(/.*?\n/)
      broken = cql_cql_failures[File.basename(actual_file, ".cql")]
      if broken
        pending(broken) {
          stripped_and_split.should == expected_text
        }
      else
        stripped_and_split.should == expected_text
        File.delete(actual_file)  # It succeeded, we don't need the file.
      end
    end
  end
end
