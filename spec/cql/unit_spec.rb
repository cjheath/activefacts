#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'spec/helpers/test_parser'
require 'activefacts/support'
require 'activefacts/api/support'
require File.dirname(__FILE__) + '/../helpers/test_parser'

describe "Valid Numbers, Strings and Ranges" do
  ValidNumbersEtc = [
    [ "a is written as b;",                               # Value type declaration, no params, minimal whitespace
      ['a is written as b;']
    ],
    [ "a is written as B;",                               # Value type declaration, no params, minimal whitespace
      ['a is written as B;']
    ],
    [ "a is written as b();",                             # Value type declaration, minimal whitespace
      ['a is written as b;']
    ],
    [ "a is written as b ;",                              # Value type declaration, no params, trailing whitespace
      ['a is written as b;']
    ],
    [ "a is written as b ( ) ; ",                         # Value type declaration, maximal whitespace
      ['a is written as b;']
    ],

    # Comments and newlines, etc as whitespace
    [ "\na\nis written as \nb\n(\n)\n;\n",                # Basic value type declaration, newlines for whitespace
      ['a is written as b;']
    ],
    [ "\ra\ris written as\rb\r(\r)\r;\r",                 # Basic value type declaration, returns for whitespace
      ['a is written as b;']
    ],
    [ "\ta\tis written as\tb\t(\t)\t;\t",                 # Basic value type declaration, tabs for whitespace
      ['a is written as b;']
    ],
    [ " /* Plugh */ a /* Plugh */ is written as\n b /* *Plugh* / */ ( /* *Plugh* / */ ) /* *Plugh* / */ ; /* *Plugh* / */ ",
      ['a is written as b;']
    ],
    [ "//Plugh\na // Plugh\n is written as // Plugh\n b // Plugh\n ( // Plugh\n ) // Plugh\n ; // Plugh\n ",
      ['a is written as b;']
    ],

    # Integers
    [ "a is written as b(0);",                            # Integer zero
      ['a is written as b(0);']
    ],
    [ "a is written as b( 0 ) ; ",                        # Integer zero, maximal whitespace
      ['a is written as b(0);']
    ],
    [ "a is written as b(1);",                            # Integer one
      ['a is written as b(1);']
    ],
    [ "a is written as b(-1);",                           # Integer negative one
      ['a is written as b(-1);']
    ],
    [ "a is written as b(+1);",                           # Positive integer
      ['a is written as b(1);']
    ],
    [ "a is written as b(1e4);",                          # Integer with exponent
      ['a is written as b(10000.0);']
    ],
    [ "a is written as b(1e-4);",                         # Integer with negative exponent
      ['a is written as b(0.0001);']
    ],
    [ "a is written as b(-1e-4);",                        # Negative integer with negative exponent
      ['a is written as b(-0.0001);']
    ],
    [ "a is written as b(077);",                          # Octal integer
      ['a is written as b(63);']
    ],
    [ "a is written as b(0xFace8);",                      # Hexadecimal integer
      ['a is written as b(1027304);']
    ],
    [ "a is written as b(0,1);",                          # Two parameters
      ['a is written as b(0, 1);']
    ],
    [ "a is written as b( 0 , 1 );",
      ['a is written as b(0, 1);']
    ],
    [ "a is written as b(0,1,2) ;",                       # Three parameters now allowed
      ['a is written as b(0, 1, 2);']
    ],

    # Reals
    [ "a is written as b(1.0);",
      ['a is written as b(1.0);']
    ],
    [ "a is written as b(-1.0);",
      ['a is written as b(-1.0);']
    ],
    [ "a is written as b(+1.0);",
      ['a is written as b(1.0);']
    ],
    [ "a is written as b(0.1);",
      ['a is written as b(0.1);']
    ],
    [ "a is written as b(-0.1);",
      ['a is written as b(-0.1);']
    ],
    [ "a is written as b(+0.1);",
      ['a is written as b(0.1);']
    ],
    [ "a is written as b(0.0);",
      ['a is written as b(0.0);']
    ],
    [ "a is written as b(-0.0);",
      ['a is written as b(-0.0);']
    ],
    [ "a is written as b(+0.0);",
      ['a is written as b(0.0);']
    ],

    # Value types with units
    [ "a is written as b inch;",                          # Value type declaration with unit
      ['a is written as b in [["inch", 1]];']
    ],
    [ "a is written as b() inch ; ",                      # Value type declaration with unit and whitespace
      ['a is written as b in [["inch", 1]];']
    ],
    [ "a is written as b() inch;",                        # Value type declaration with unit
      ['a is written as b in [["inch", 1]];']
    ],
    [ "a is written as b inch^2;",                        # Value type declaration with unit and exponent
      ['a is written as b in [["inch", 2]];']
    ],
    [ "a is written as b() inch^2 ; ",                    # Value type declaration with unit and exponent with maximum whitespace
      ['a is written as b in [["inch", 2]];']
    ],
    [ "a is written as b second^-1;",                     # Value type declaration with unit and negative exponent
      ['a is written as b in [["second", -1]];']
    ],
    [ "a is written as b inch inch;",                     # Value type declaration with repeated unit
      ['a is written as b in [["inch", 1], ["inch", 1]];']
    ],
    [ "a is written as b inch^2/minute^-1;",              # Value type declaration with unit and divided unit with exponents
      ['a is written as b in [["inch", 2], ["minute", 1]];']
    ],
    [ "a is written as b() second^-1/mm^-1 mm^-1;",       # Value type declaration with repeated divided unit
      ['a is written as b in [["second", -1], ["mm", 1], ["mm", 1]];']
    ],

    # Integer value constraints
    [ "a is written as b()restricted to{1};",             # Integer, minimal whitespace
      ['a is written as b ValueConstraint to ([1]);']
    ],
    [ "a is written as b() restricted to { 1 } ;",        # Integer, maximal whitespace
      ['a is written as b ValueConstraint to ([1]);']
    ],
    [ "a is written as b() restricted to {1..2};",        # Integer range, minimal whitespace
      ['a is written as b ValueConstraint to ([1..2]);']
    ],
    [ "a is written as b() restricted to { 1 .. 2 };",    # Integer range, maximal whitespace
      ['a is written as b ValueConstraint to ([1..2]);']
    ],
    [ "a is written as b() restricted to {..2};",         # Integer range with open start, minimal whitespace
      ['a is written as b ValueConstraint to ([-Infinity..2]);']
    ],
    [ "a is written as b() restricted to { .. 2 };",      # Integer range with open start, maximal whitespace
      ['a is written as b ValueConstraint to ([-Infinity..2]);']
    ],
    [ "a is written as b() restricted to { ..2,3};",      # Range followed by integer, minimal whitespace
      ['a is written as b ValueConstraint to ([-Infinity..2, 3]);']
    ],
    [ "a is written as b() restricted to { 1,..2,3};",    # Integer, open-start range, integer, minimal whitespace
      ['a is written as b ValueConstraint to ([1, -Infinity..2, 3]);']
    ],
    [ "a is written as b() restricted to { .. 2 , 3 };",  # Range followed by integer, maximal whitespace
      ['a is written as b ValueConstraint to ([-Infinity..2, 3]);']
    ],
    [ "a is written as b() restricted to { ..2 , 3..4 };",# Range followed by range
      ['a is written as b ValueConstraint to ([-Infinity..2, 3..4]);']
    ],
    [ "a is written as b() restricted to { ..2, 3..};",   # Range followed by range with open end, minimal whitespace
      ['a is written as b ValueConstraint to ([-Infinity..2, 3..Infinity]);']
    ],
    [ "a is written as b() restricted to { ..2, 3 .. };", # Range followed by range with open end, maximal whitespace
      ['a is written as b ValueConstraint to ([-Infinity..2, 3..Infinity]);']
    ],
    [ "a is written as b() restricted to { 1e4 } ;",      # Integer with exponent
      ['a is written as b ValueConstraint to ([10000.0]);']
    ],
    [ "a is written as b() restricted to { -1e4 } ;",     # Negative integer with exponent
      ['a is written as b ValueConstraint to ([-10000.0]);']
    ],
    [ "a is written as b() restricted to { 1e-4 } ;",     # Integer with negative exponent
      ['a is written as b ValueConstraint to ([0.0001]);']
    ],
    [ "a is written as b() restricted to { -1e-4 } ;",    # Negative integer with negative exponent
      ['a is written as b ValueConstraint to ([-0.0001]);']
    ],

    # Real value constraints
    [ "a is written as b() restricted to {1.0};",         # Real, minimal whitespace
      ['a is written as b ValueConstraint to ([1.0]);']
    ],
    [ "a is written as b() restricted to { 1.0 } ;",      # Real, maximal whitespace
      ['a is written as b ValueConstraint to ([1.0]);']
    ],
    [ "a is written as b() restricted to { 1.0e4 } ;",    # Real with exponent
      ['a is written as b ValueConstraint to ([10000.0]);']
    ],
    [ "a is written as b() restricted to { 1.0e-4 } ;",   # Real with negative exponent
      ['a is written as b ValueConstraint to ([0.0001]);']
    ],
    [ "a is written as b() restricted to { -1.0e-4 } ;",  # Negative real with negative exponent
      ['a is written as b ValueConstraint to ([-0.0001]);']
    ],
    [ "a is written as b() restricted to { 1.1 .. 2.2 } ;",       # Real range, maximal whitespace
      ['a is written as b ValueConstraint to ([1.1..2.2]);']
    ],
    [ "a is written as b() restricted to { -1.1 .. 2.2 } ;",      # Real range, maximal whitespace
      ['a is written as b ValueConstraint to ([-1.1..2.2]);']
    ],
    [ "a is written as b() restricted to { 1.1..2.2};",   # Real range, minimal whitespace
      ['a is written as b ValueConstraint to ([1.1..2.2]);']
    ],
    [ "a is written as b() restricted to { 1.1..2 } ;",   # Real-integer range
      ['a is written as b ValueConstraint to ([1.1..2]);']
    ],
    [ "a is written as b() restricted to { 1..2.2 } ;",   # Integer-real range
      ['a is written as b ValueConstraint to ([1..2.2]);']
    ],
    [ "a is written as b() restricted to { ..2.2};",      # Real range with open start
      ['a is written as b ValueConstraint to ([-Infinity..2.2]);']
    ],
    [ "a is written as b() restricted to { 1.1.. };",     # Real range with open end
      ['a is written as b ValueConstraint to ([1.1..Infinity]);']
    ],
    [ "a is written as b() restricted to { 1.1.., 2 };",  # Real range with open end and following integer
      ['a is written as b ValueConstraint to ([1.1..Infinity, 2]);']
    ],

    # Strings and string value constraints
    [ "a is written as b() restricted to {''};",          # String, empty, minimal whitespace
      ['a is written as b ValueConstraint to (["\'\'"]);']
    ],
    [ "a is written as b() restricted to {'A'};",         # String, minimal whitespace
      ['a is written as b ValueConstraint to (["\'A\'"]);']
    ],
    [ "a is written as b() restricted to { 'A' };",       # String, maximal whitespace
      ['a is written as b ValueConstraint to (["\'A\'"]);']
    ],
    [ "a is written as b() restricted to { '\\b\\t\\f\\n\\r\\e\\\\' };",  # String with special escapes
      ["a is written as b ValueConstraint to ([\"'\\\\b\\\\t\\\\f\\\\n\\\\r\\\\e\\\\\\\\'\"]);"]
    ],
    [ "a is written as b() restricted to { ' ' };",       # String with space
      ['a is written as b ValueConstraint to (["\' \'"]);']
    ],
    [ "a is written as b() restricted to { '\t' };",      # String with literal tab
      ['a is written as b ValueConstraint to (["\'\t\'"]);']
    ],
    [ "a is written as b() restricted to { '\\0' };",     # String with nul character
      ["a is written as b ValueConstraint to ([\"'\\\\0'\"]);"]
    ],
    [ "a is written as b() restricted to { '\\077' };",   # String with octal escape
      ["a is written as b ValueConstraint to ([\"'\\\\077'\"]);"]
    ],
    [ "a is written as b() restricted to { '\\0xA9' };",  # String with hexadecimal escape
      ["a is written as b ValueConstraint to ([\"'\\\\0xA9'\"]);"]
    ],
    [ "a is written as b() restricted to { '\\0uBabe' };",# String with unicode escape
      ["a is written as b ValueConstraint to ([\"'\\\\0uBabe'\"]);"]
    ],
    [ "a is written as b() restricted to {'A'..'F'};",    # String range, minimal whitespace
      ['a is written as b ValueConstraint to (["\'A\'".."\'F\'"]);']
    ],
    [ "a is written as b() restricted to { 'A' .. 'F' };",# String range, maximal whitespace
      ['a is written as b ValueConstraint to (["\'A\'".."\'F\'"]);']
    ],
    [ "a is written as b() restricted to { ..'F' };",     # String range, open start
      ['a is written as b ValueConstraint to (["MIN".."F"]);']
    ],
    [ "a is written as b() restricted to { 'A'.. };",     # String range, open end
      ['a is written as b ValueConstraint to (["\'A\'".."MAX"]);']
    ],

    # Value constraints with units
    [ "a is written as b() restricted to {1} inches^2/second;",    # constraint with units and exponent
      ['a is written as b ValueConstraint to ([1]) in [["inches", 2], ["second", -1]];']
    ],
    [ "a is written as b() second^-1/mm^-1 mm^-1 restricted to {1} inches^2/second;",    # type with unit and constraint with units and exponent
      #['a is written as b ValueConstraint to ([1]) in [["inches", 2], ["second", -1]];']
      ["a is written as b in [[\"second\", -1], [\"mm\", 1], [\"mm\", 1]] ValueConstraint to ([1]) in [[\"inches\", 2], [\"second\", -1]];"]
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

describe "Value Types" do
  ValueTypes = [
    [ "a is written as b(1, 2) inch restricted to { 3 .. 4 } inch ;",
      ['a is written as b(1, 2) in [["inch", 1]] ValueConstraint to ([3..4]) in [["inch", 1]];']
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

describe "Entity Types" do
  EntityTypes_RefMode = [
    [ "a is identified by its id;",                     # Entity type declaration with reference mode
      ["a identified by its id;"]
    ],
    [ "a is identified by its number(12);",                     # Entity type declaration with reference mode
      ["a identified by its number(12);"]
    ],
    [ "a is identified by its id where c;",                   # Entity type declaration with reference mode and fact type(s)
      ["a identified by its id where [{c}];"]
    ],
    [ "a is identified by its id where c;",             # Entity type declaration with reference mode and where
      ["a identified by its id where [{c}];"]
    ],
  ]

  EntityTypes_Simple = [
    [ "a is identified by b where c;",                       # Entity type declaration
      ["a [{b}] where [{c}];"]
    ],
    [ "a is identified by b where c;",                  # Entity type declaration with where
      ["a [{b}] where [{c}];"]
    ],
    [ "a is identified by b and c where d;",                 # Entity type declaration with two-part identifier
      ["a [{b}, {c}] where [\"d\"];"]
    ],
    [ "a is identified by b, c where d;",                    # Entity type declaration with two-part identifier
      ["a [{b}, {c}] where [\"d\"];"]
    ],
    [ "a is written as b(); e is identified by a where d;",
      ["a is written as b;", "e [{a}] where [\"d\"];"]
    ],
    [ " a is written as b ( ) ; e is identified by a where d ; ",
      ["a is written as b;", "e [{a}] where [\"d\"];"]
    ],
    [ "e is written as b; a is identified by e where maybe d;",
      ["e is written as b;", "a [{e}] where [[\"maybe\"] \"d\"];"]
    ],
  ]

  EntityTypes_Objectified = [
    [ "Director is where b directs c, c is directed by b;",
      ["Director [{b} \"directs\" {c}, {c} \"is directed by\" {b}]"]
    ],
  ]

  EntityTypes_Subtypes = [
    [ "Employee is a kind of Person;",
      ["Employee < Person nil;"]
    ],
    [ "Employee is a subtype of Person;",
      ["Employee < Person nil;"]
    ],
    [ "AustralianEmployee is a subtype of Employee, Australian;",
      ["AustralianEmployee < Employee,Australian nil;"]
    ],
    [ "Employee is a kind of Person identified by EmployeeNumber;",
      ["Employee < Person [{EmployeeNumber}];"]
    ],
    [ "Employee is a subtype of Person identified by EmployeeNumber;",
      ["Employee < Person [{EmployeeNumber}];"]
    ],
    [ "AustralianEmployee is a subtype of Employee, Australian identified by TaxFileNumber;",
      ["AustralianEmployee < Employee,Australian [{TaxFileNumber}];"]
    ],
  ]

  EntityTypes =
    EntityTypes_RefMode +
    EntityTypes_Simple +
    EntityTypes_Objectified +
    EntityTypes_Subtypes

  before :each do
    @parser = TestParser.new
    @parser.parse_all("c is written as b;", :definition)
  end

  EntityTypes.each do |c|
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

describe "Fact Types" do
  FactTypes = [
    [ "Foo has at most one Bar, Bar is of one Foo restricted to {1..10};",
      [" [{Foo} \"has\" {[..1] Bar}, {Bar} \"is of\" {[1..1] Foo ValueConstraint to ([1..10])}]"]
    ],
    [ "Bar(1) is related to Bar(2), primary-Bar(1) has secondary-Bar(2);",
      [" [{Bar(1)} \"is related to\" {Bar(2)}, {primary- Bar(1)} \"has\" {secondary- Bar(2)}]"]
    ],
    [ "Director is old: Person directs company, Person is of Age, Age > 60;",
      [" [{Director} \"is old\"] where {Person} \"directs company\", {Person} \"is of\" {Age}, ({Age}) > (60)"]
    ],
    [ "A is a farce: maybe A has completely- B [transitive, acyclic], B -c = 2;",
      [" [{A} \"is a farce\"] where [\"maybe\", \"transitive\", \"acyclic\"] {A} \"has\" {completely- B}, ({B -c}) = (2)"]
    ],
    [ "A is a farce: maybe A has completely- green B [transitive, acyclic], B -c = 2;",
      [" [{A} \"is a farce\"] where [\"maybe\", \"transitive\", \"acyclic\"] {A} \"has\" {completely- green B}, ({B -c}) = (2)"]
    ],
    [ "A is a farce: maybe A has B green -totally [transitive, acyclic], B -c = 2;",
      [" [{A} \"is a farce\"] where [\"maybe\", \"transitive\", \"acyclic\"] {A} \"has\" {B green -totally}, ({B -c}) = (2)"]
    ],
    [ "Person is independent: Person has taxable- Income, taxable Income >= 20000 dollars;",
      [" [{Person} \"is independent\"] where {Person} \"has\" {taxable- Income}, ({taxable- Income}) >= (20000 in dollars)"]
    ],
    [ "Window requires toughening: Window has Width -mm, Window has Height -mm, Width mm * Height mm >= 10 foot^2;",
      [" [{Window} \"requires toughening\"] where {Window} \"has\" {Width -mm}, {Window} \"has\" {Height -mm}, (({Width -mm}) + ({Height -mm})) >= (10 in foot^2)"]
    ],
    # REVISIT: Test all quantifiers
    # REVISIT: Test all post-qualifiers
    # REVISIT: Test functions
    [ "AnnualIncome is where Person has total- Income in Year: Person has total- Income.sum(), Income was earned in current- Time.Year() (as Year);",
      ["AnnualIncome [{Person} \"has\" {total- Income} \"in\" {Year}] where {Person} \"has\" {total- Income}, {Income} \"was earned in\" {current- Time (as Year)}"]
    ],
    [ "A is interesting : b- C has F -g;",
      [" [{A} \"is interesting\"] where {b- C} \"has\" {F -g}"]
    ]
  ]

  before :each do
    @parser = TestParser.new
  end

  FactTypes.each do |c|
    source, ast, definition = *c
    it "should parse #{source.inspect}" do
      result = @parser.parse_all(source, :definition)

      puts @parser.failure_reason unless result

      #result = [result[-1]]
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
