#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'helpers/test_parser'

describe "Value Types" do
  ValueTypes = [
    [ "a is written as b(1, 2) in inch restricted to { 3 .. 4 } inch ;",
      ['ValueType: a is written as b(1, 2) in [["inch", 1]] ValueConstraint to ([3..4]) in [["inch", 1]];']
    ],
#    [ "a c  is written as b(1, 2) inch restricted to { 3 .. 4 } inch ;",
#      [["a c", [:value_type, "b", [1, 2], "inch", [[3, 4]]]]]
#    ],
  ]

  before :each do
    @parser = TestParser.new
  end

  ValueTypes.each do |c|
    source, ast = *c
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
