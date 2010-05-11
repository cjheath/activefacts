#
# ActiveFacts tests: Parse all NORMA files and check the generated CQL.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/cql'

include ActiveFacts

describe "CQL Parser" do
  cql_failures = {
    "Airline" => "Contains queries, unsupported",
    "CompanyQuery" => "Contains queries, unsupported",
    "ServiceDirector" => "Contains constraints with mismatched adjectives",
  }

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    it "should load CQL #{cql_file} without parse errors" do
      broken = cql_failures[File.basename(cql_file, ".cql")]

      if broken
        pending(broken) {
          lambda { vocabulary = ActiveFacts::Input::CQL.readfile(cql_file) }.should_not raise_error
        }
      else
        lambda { vocabulary = ActiveFacts::Input::CQL.readfile(cql_file) }.should_not raise_error
      end
    end
  end
end
