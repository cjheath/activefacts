#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'spec/helpers/test_parser'
require 'activefacts/support'
require 'activefacts/api/support'
require File.dirname(__FILE__) + '/../../helpers/test_parser'

describe "Valid Numbers, Strings and Ranges" do
  ValidNumbersEtc = [
    [ "a is written as b;",                               # Value type declaration, no params, minimal whitespace
      ['ValueType: a is written as b;']
    ],
    [ "a is written as B;",                               # Value type declaration, no params, minimal whitespace
      ['ValueType: a is written as B;']
    ],
    [ "a is written as b();",                             # Value type declaration, minimal whitespace
      ['ValueType: a is written as b;']
    ],
    [ "a is written as b ;",                              # Value type declaration, no params, trailing whitespace
      ['ValueType: a is written as b;']
    ],
    [ "a is written as b ( ) ; ",                         # Value type declaration, maximal whitespace
      ['ValueType: a is written as b;']
    ],

    # Comments and newlines, etc as whitespace
    [ "\na\nis written as \nb\n(\n)\n;\n",                # Basic value type declaration, newlines for whitespace
      ['ValueType: a is written as b;']
    ],
    [ "\ra\ris written as\rb\r(\r)\r;\r",                 # Basic value type declaration, returns for whitespace
      ['ValueType: a is written as b;']
    ],
    [ "\ta\tis written as\tb\t(\t)\t;\t",                 # Basic value type declaration, tabs for whitespace
      ['ValueType: a is written as b;']
    ],
    [ " /* Plugh */ a /* Plugh */ is written as\n b /* *Plugh* / */ ( /* *Plugh* / */ ) /* *Plugh* / */ ; /* *Plugh* / */ ",
      ['ValueType: a is written as b;']
    ],
    [ "//Plugh\na // Plugh\n is written as // Plugh\n b // Plugh\n ( // Plugh\n ) // Plugh\n ; // Plugh\n ",
      ['ValueType: a is written as b;']
    ],

    # Integers
    [ "a is written as b(0);",                            # Integer zero
      ['ValueType: a is written as b(0);']
    ],
    [ "a is written as b( 0 ) ; ",                        # Integer zero, maximal whitespace
      ['ValueType: a is written as b(0);']
    ],
    [ "a is written as b(1);",                            # Integer one
      ['ValueType: a is written as b(1);']
    ],
    [ "a is written as b(-1);",                           # Integer negative one
      ['ValueType: a is written as b(-1);']
    ],
    [ "a is written as b(+1);",                           # Positive integer
      ['ValueType: a is written as b(1);']
    ],
    [ "a is written as b(1e4);",                          # Integer with exponent
      ['ValueType: a is written as b(10000.0);']
    ],
    [ "a is written as b(1e-4);",                         # Integer with negative exponent
      ['ValueType: a is written as b(0.0001);']
    ],
    [ "a is written as b(-1e-4);",                        # Negative integer with negative exponent
      ['ValueType: a is written as b(-0.0001);']
    ],
    [ "a is written as b(077);",                          # Octal integer
      ['ValueType: a is written as b(63);']
    ],
    [ "a is written as b(0xFace8);",                      # Hexadecimal integer
      ['ValueType: a is written as b(1027304);']
    ],
    [ "a is written as b(0,1);",                          # Two parameters
      ['ValueType: a is written as b(0, 1);']
    ],
    [ "a is written as b( 0 , 1 );",
      ['ValueType: a is written as b(0, 1);']
    ],
    [ "a is written as b(0,1,2) ;",                       # Three parameters now allowed
      ['ValueType: a is written as b(0, 1, 2);']
    ],

    # Reals
    [ "a is written as b(1.0);",
      ['ValueType: a is written as b(1.0);']
    ],
    [ "a is written as b(-1.0);",
      ['ValueType: a is written as b(-1.0);']
    ],
    [ "a is written as b(+1.0);",
      ['ValueType: a is written as b(1.0);']
    ],
    [ "a is written as b(0.1);",
      ['ValueType: a is written as b(0.1);']
    ],
    [ "a is written as b(-0.1);",
      ['ValueType: a is written as b(-0.1);']
    ],
    [ "a is written as b(+0.1);",
      ['ValueType: a is written as b(0.1);']
    ],
    [ "a is written as b(0.0);",
      ['ValueType: a is written as b(0.0);']
    ],
    [ "a is written as b(-0.0);",
      ['ValueType: a is written as b(-0.0);']
    ],
    [ "a is written as b(+0.0);",
      ['ValueType: a is written as b(0.0);']
    ],

    # Value types with units
    [ "a is written as b inch;",                          # Value type declaration with unit
      ['ValueType: a is written as b in [["inch", 1]];']
    ],
    [ "a is written as b() inch ; ",                      # Value type declaration with unit and whitespace
      ['ValueType: a is written as b in [["inch", 1]];']
    ],
    [ "a is written as b() inch;",                        # Value type declaration with unit
      ['ValueType: a is written as b in [["inch", 1]];']
    ],
    [ "a is written as b inch^2;",                        # Value type declaration with unit and exponent
      ['ValueType: a is written as b in [["inch", 2]];']
    ],
    [ "a is written as b() inch^2 ; ",                    # Value type declaration with unit and exponent with maximum whitespace
      ['ValueType: a is written as b in [["inch", 2]];']
    ],
    [ "a is written as b second^-1;",                     # Value type declaration with unit and negative exponent
      ['ValueType: a is written as b in [["second", -1]];']
    ],
    [ "a is written as b inch inch;",                     # Value type declaration with repeated unit
      ['ValueType: a is written as b in [["inch", 1], ["inch", 1]];']
    ],
    [ "a is written as b inch^2/minute^-1;",              # Value type declaration with unit and divided unit with exponents
      ['ValueType: a is written as b in [["inch", 2], ["minute", 1]];']
    ],
    [ "a is written as b() second^-1/mm^-1 mm^-1;",       # Value type declaration with repeated divided unit
      ['ValueType: a is written as b in [["second", -1], ["mm", 1], ["mm", 1]];']
    ],

    # Integer value constraints
    [ "a is written as b()restricted to{1};",             # Integer, minimal whitespace
      ['ValueType: a is written as b ValueConstraint to ([1]);']
    ],
    [ "a is written as b() restricted to { 1 } ;",        # Integer, maximal whitespace
      ['ValueType: a is written as b ValueConstraint to ([1]);']
    ],
    [ "a is written as b() restricted to {1..2};",        # Integer range, minimal whitespace
      ['ValueType: a is written as b ValueConstraint to ([1..2]);']
    ],
    [ "a is written as b() restricted to { 1 .. 2 };",    # Integer range, maximal whitespace
      ['ValueType: a is written as b ValueConstraint to ([1..2]);']
    ],
    [ "a is written as b() restricted to {..2};",         # Integer range with open start, minimal whitespace
      ['ValueType: a is written as b ValueConstraint to ([-Infinity..2]);']
    ],
    [ "a is written as b() restricted to { .. 2 };",      # Integer range with open start, maximal whitespace
      ['ValueType: a is written as b ValueConstraint to ([-Infinity..2]);']
    ],
    [ "a is written as b() restricted to { ..2,3};",      # Range followed by integer, minimal whitespace
      ['ValueType: a is written as b ValueConstraint to ([-Infinity..2, 3]);']
    ],
    [ "a is written as b() restricted to { 1,..2,3};",    # Integer, open-start range, integer, minimal whitespace
      ['ValueType: a is written as b ValueConstraint to ([1, -Infinity..2, 3]);']
    ],
    [ "a is written as b() restricted to { .. 2 , 3 };",  # Range followed by integer, maximal whitespace
      ['ValueType: a is written as b ValueConstraint to ([-Infinity..2, 3]);']
    ],
    [ "a is written as b() restricted to { ..2 , 3..4 };",# Range followed by range
      ['ValueType: a is written as b ValueConstraint to ([-Infinity..2, 3..4]);']
    ],
    [ "a is written as b() restricted to { ..2, 3..};",   # Range followed by range with open end, minimal whitespace
      ['ValueType: a is written as b ValueConstraint to ([-Infinity..2, 3..Infinity]);']
    ],
    [ "a is written as b() restricted to { ..2, 3 .. };", # Range followed by range with open end, maximal whitespace
      ['ValueType: a is written as b ValueConstraint to ([-Infinity..2, 3..Infinity]);']
    ],
    [ "a is written as b() restricted to { 1e4 } ;",      # Integer with exponent
      ['ValueType: a is written as b ValueConstraint to ([10000.0]);']
    ],
    [ "a is written as b() restricted to { -1e4 } ;",     # Negative integer with exponent
      ['ValueType: a is written as b ValueConstraint to ([-10000.0]);']
    ],
    [ "a is written as b() restricted to { 1e-4 } ;",     # Integer with negative exponent
      ['ValueType: a is written as b ValueConstraint to ([0.0001]);']
    ],
    [ "a is written as b() restricted to { -1e-4 } ;",    # Negative integer with negative exponent
      ['ValueType: a is written as b ValueConstraint to ([-0.0001]);']
    ],

    # Real value constraints
    [ "a is written as b() restricted to {1.0};",         # Real, minimal whitespace
      ['ValueType: a is written as b ValueConstraint to ([1.0]);']
    ],
    [ "a is written as b() restricted to { 1.0 } ;",      # Real, maximal whitespace
      ['ValueType: a is written as b ValueConstraint to ([1.0]);']
    ],
    [ "a is written as b() restricted to { 1.0e4 } ;",    # Real with exponent
      ['ValueType: a is written as b ValueConstraint to ([10000.0]);']
    ],
    [ "a is written as b() restricted to { 1.0e-4 } ;",   # Real with negative exponent
      ['ValueType: a is written as b ValueConstraint to ([0.0001]);']
    ],
    [ "a is written as b() restricted to { -1.0e-4 } ;",  # Negative real with negative exponent
      ['ValueType: a is written as b ValueConstraint to ([-0.0001]);']
    ],
    [ "a is written as b() restricted to { 1.1 .. 2.2 } ;",       # Real range, maximal whitespace
      ['ValueType: a is written as b ValueConstraint to ([1.1..2.2]);']
    ],
    [ "a is written as b() restricted to { -1.1 .. 2.2 } ;",      # Real range, maximal whitespace
      ['ValueType: a is written as b ValueConstraint to ([-1.1..2.2]);']
    ],
    [ "a is written as b() restricted to { 1.1..2.2};",   # Real range, minimal whitespace
      ['ValueType: a is written as b ValueConstraint to ([1.1..2.2]);']
    ],
    [ "a is written as b() restricted to { 1.1..2 } ;",   # Real-integer range
      ['ValueType: a is written as b ValueConstraint to ([1.1..2]);']
    ],
    [ "a is written as b() restricted to { 1..2.2 } ;",   # Integer-real range
      ['ValueType: a is written as b ValueConstraint to ([1..2.2]);']
    ],
    [ "a is written as b() restricted to { ..2.2};",      # Real range with open start
      ['ValueType: a is written as b ValueConstraint to ([-Infinity..2.2]);']
    ],
    [ "a is written as b() restricted to { 1.1.. };",     # Real range with open end
      ['ValueType: a is written as b ValueConstraint to ([1.1..Infinity]);']
    ],
    [ "a is written as b() restricted to { 1.1.., 2 };",  # Real range with open end and following integer
      ['ValueType: a is written as b ValueConstraint to ([1.1..Infinity, 2]);']
    ],

    # Strings and string value constraints
    [ "a is written as b() restricted to {''};",          # String, empty, minimal whitespace
      ['ValueType: a is written as b ValueConstraint to (["\'\'"]);']
    ],
    [ "a is written as b() restricted to {'A'};",         # String, minimal whitespace
      ['ValueType: a is written as b ValueConstraint to (["\'A\'"]);']
    ],
    [ "a is written as b() restricted to { 'A' };",       # String, maximal whitespace
      ['ValueType: a is written as b ValueConstraint to (["\'A\'"]);']
    ],
    [ "a is written as b() restricted to { '\\b\\t\\f\\n\\r\\e\\\\' };",  # String with special escapes
      ["ValueType: a is written as b ValueConstraint to ([\"'\\\\b\\\\t\\\\f\\\\n\\\\r\\\\e\\\\\\\\'\"]);"]
    ],
    [ "a is written as b() restricted to { ' ' };",       # String with space
      ['ValueType: a is written as b ValueConstraint to (["\' \'"]);']
    ],
    [ "a is written as b() restricted to { '\t' };",      # String with literal tab
      ['ValueType: a is written as b ValueConstraint to (["\'\t\'"]);']
    ],
    [ "a is written as b() restricted to { '\\0' };",     # String with nul character
      ["ValueType: a is written as b ValueConstraint to ([\"'\\\\0'\"]);"]
    ],
    [ "a is written as b() restricted to { '\\077' };",   # String with octal escape
      ["ValueType: a is written as b ValueConstraint to ([\"'\\\\077'\"]);"]
    ],
    [ "a is written as b() restricted to { '\\0xA9' };",  # String with hexadecimal escape
      ["ValueType: a is written as b ValueConstraint to ([\"'\\\\0xA9'\"]);"]
    ],
    [ "a is written as b() restricted to { '\\0uBabe' };",# String with unicode escape
      ["ValueType: a is written as b ValueConstraint to ([\"'\\\\0uBabe'\"]);"]
    ],
    [ "a is written as b() restricted to {'A'..'F'};",    # String range, minimal whitespace
      ['ValueType: a is written as b ValueConstraint to (["\'A\'".."\'F\'"]);']
    ],
    [ "a is written as b() restricted to { 'A' .. 'F' };",# String range, maximal whitespace
      ['ValueType: a is written as b ValueConstraint to (["\'A\'".."\'F\'"]);']
    ],
    [ "a is written as b() restricted to { ..'F' };",     # String range, open start
      ['ValueType: a is written as b ValueConstraint to (["MIN".."F"]);']
    ],
    [ "a is written as b() restricted to { 'A'.. };",     # String range, open end
      ['ValueType: a is written as b ValueConstraint to (["\'A\'".."MAX"]);']
    ],

    # Value constraints with units
    [ "a is written as b() restricted to {1} inches^2/second;",    # constraint with units and exponent
      ['ValueType: a is written as b ValueConstraint to ([1]) in [["inches", 2], ["second", -1]];']
    ],
    [ "a is written as b() second^-1/mm^-1 mm^-1 restricted to {1} inches^2/second;",    # type with unit and constraint with units and exponent
      #['a is written as b ValueConstraint to ([1]) in [["inches", 2], ["second", -1]];']
      ["ValueType: a is written as b in [[\"second\", -1], [\"mm\", 1], [\"mm\", 1]] ValueConstraint to ([1]) in [[\"inches\", 2], [\"second\", -1]];"]
    ],
  ]

  before :each do
    @parser = TestParser.new
  end

  ValidNumbersEtc.each do |c|
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

