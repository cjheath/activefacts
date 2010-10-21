#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'helpers/test_parser'

describe "Invalid Numbers and Strings" do
  InvalidValueTypes = [
    "a is written as b(08);",                           # Invalid octalnumber
    "a is written as b(0xDice);",                       # Invalid hexadecimal
    "a is written as b(- 1);",                          # Invalid negative
    "a is written as b(+ 1);",                          # Invalid positive
    "b(- 1e-4);",                                       # Negative integer with negative exponent
    "a is written as b(-077);",                         # Invalid negative octal
    "a is written as b(-0xFace);",                      # Invalid negative hexadecimal
    "a is written as b(.0);",                           # Invalid real
    "a is written as b(0.);",                           # Invalid real
    "b() inch ^2 ; ",                                   # Illegal whitespace around unit exponent
    "b() inch^ 2 ; ",                                   # Illegal whitespace around unit exponent
    "b() restricted to { '\\7a' };",                    # String with bad octal escape
    "b() restricted to { '\001' };",                    # String with control char
    "b() restricted to { '\n' };",                      # String with literal newline
    "b() restricted to { 0..'A' };",                    # Cross-typed range
    "b() restricted to { 'a'..27 };",                   # Cross-typed range
  ]

  before :each do
    @parser = TestParser.new
  end

  InvalidValueTypes.each do |c|
    source, ast = *c
    it "should not parse #{source.inspect}" do
      result = @parser.parse_all(source, :definition)

      # puts @parser.failure_reason unless result.success?
      result.should be_nil
    end
  end
end
