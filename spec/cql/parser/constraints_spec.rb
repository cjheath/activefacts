#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'spec/helpers/test_parser'
require 'activefacts/support'
require 'activefacts/api/support'
require File.dirname(__FILE__) + '/../../helpers/test_parser'

describe "Constraint" do
  Constraints = [
    [ "each combination FamilyName, GivenName occurs at most one time in Competitor has FamilyName, Competitor has GivenName;",
      ["PresenceConstraint over [[{Competitor} \"has\" {FamilyName}], [{Competitor} \"has\" {GivenName}]] -1 over ({FamilyName}, {GivenName})"]
    ],
  ]

  before :each do
    @parser = TestParser.new
  end

  Constraints.each do |c|
    source, ast, definition = *c
    it "should parse #{source.inspect}" do
      result = @parser.parse_all(source, :definition)

      puts @parser.failure_reason unless result
      result.should_not be_nil

      canonical_form = result.map{|d| d.ast.to_s}
      if ast
        canonical_form.should == ast
      else
        puts "#{source.inspect} should compile to"
        puts "\t#{canonical_form}"
      end
    end
  end
end
