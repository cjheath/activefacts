#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

=begin
REVISIT: These tests are important, but the intermediate layer they test no longer exists. Find another solution!

require 'spec/helpers/test_parser'
require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/parser'
require File.dirname(__FILE__) + '/../helpers/test_parser'

describe "Valid Numbers, Strings and Ranges" do
  ValidNumbersEtc = [
    "a is written as b;",                               # Value type declaration, no params, minimal whitespace
    "a is written as B;",                               # Value type declaration, no params, minimal whitespace
    "a is written as b();",                             # Value type declaration, minimal whitespace
    "a is written as b ;",                              # Value type declaration, no params, trailing whitespace
    "a is written as b ( ) ; ",                         # Value type declaration, maximal whitespace

    # Comments and newlines, etc as whitespace
    "\na\nis written as \nb\n(\n)\n;\n",                # Basic value type declaration, newlines for whitespace
    "\ra\ris written as\rb\r(\r)\r;\r",                 # Basic value type declaration, returns for whitespace
    "\ta\tis written as\tb\t(\t)\t;\t",                 # Basic value type declaration, tabs for whitespace
    " /* Plugh */ a /* Plugh */ is written as\n b /* *Plugh* / */ ( /* *Plugh* / */ ) /* *Plugh* / */ ; /* *Plugh* / */ ",
    "//Plugh\na // Plugh\n is written as // Plugh\n b // Plugh\n ( // Plugh\n ) // Plugh\n ; // Plugh\n ",

    # Integers
    "a is written as b(0);",                            # Integer zero
    "a is written as b( 0 ) ; ",                        # Integer zero, maximal whitespace
    "a is written as b(1);",                            # Integer one
    "a is written as b(-1);",                           # Integer negative one
    "a is written as b(+1);",                           # Positive integer
    "a is written as b(1e4);",                          # Integer with exponent
    "a is written as b(1e-4);",                         # Integer with negative exponent
    "a is written as b(-1e-4);",                        # Negative integer with negative exponent
    "a is written as b(077);",                          # Octal integer
    "a is written as b(0xFace8);",                      # Hexadecimal integer
    "a is written as b(0,1);",                          # Two parameters
    "a is written as b( 0 , 1 );",
    "a is written as b(0,1,2) ;",                       # Three parameters now allowed

    # Reals
    "a is written as b(1.0);",
    "a is written as b(-1.0);",
    "a is written as b(+1.0);",
    "a is written as b(0.1);",
    "a is written as b(-0.1);",
    "a is written as b(+0.1);",
    "a is written as b(0.0);",
    "a is written as b(-0.0);",
    "a is written as b(+0.0);",

    # Value types with units
    "a is written as b inch;",                          # Value type declaration with unit
    "a is written as b() inch ; ",                      # Value type declaration with unit and whitespace
    "a is written as b() inch;",                        # Value type declaration with unit
    "a is written as b inch^2;",                        # Value type declaration with unit and exponent
    "a is written as b() inch^2 ; ",                    # Value type declaration with unit and exponent with maximum whitespace
    "a is written as b second^-1;",                     # Value type declaration with unit and negative exponent
    "a is written as b inch inch;",                     # Value type declaration with repeated unit
    "a is written as b inch^2/minute^-1;",              # Value type declaration with unit and divided unit with exponents
    "a is written as b() second^-1/mm^-1 mm^-1;",       # Value type declaration with repeated divided unit

    # Integer value constraints
    "a is written as b()restricted to{1};",             # Integer, minimal whitespace
    "a is written as b() restricted to { 1 } ;",        # Integer, maximal whitespace
    "a is written as b() restricted to {1..2};",        # Integer range, minimal whitespace
    "a is written as b() restricted to { 1 .. 2 };",    # Integer range, maximal whitespace
    "a is written as b() restricted to {..2};",         # Integer range with open start, minimal whitespace
    "a is written as b() restricted to { .. 2 };",      # Integer range with open start, maximal whitespace
    "a is written as b() restricted to { ..2,3};",      # Range followed by integer, minimal whitespace
    "a is written as b() restricted to { 1,..2,3};",    # Integer, open-start range, integer, minimal whitespace
    "a is written as b() restricted to { .. 2 , 3 };",  # Range followed by integer, maximal whitespace
    "a is written as b() restricted to { ..2 , 3..4 };",# Range followed by range
    "a is written as b() restricted to { ..2, 3..};",   # Range followed by range with open end, minimal whitespace
    "a is written as b() restricted to { ..2, 3 .. };", # Range followed by range with open end, maximal whitespace
    "a is written as b() restricted to { 1e4 } ;",      # Integer with exponent
    "a is written as b() restricted to { -1e4 } ;",     # Negative integer with exponent
    "a is written as b() restricted to { 1e-4 } ;",     # Integer with negative exponent
    "a is written as b() restricted to { -1e-4 } ;",    # Negative integer with negative exponent

    # Real value constraints
    "a is written as b() restricted to {1.0};",         # Real, minimal whitespace
    "a is written as b() restricted to { 1.0 } ;",      # Real, maximal whitespace
    "a is written as b() restricted to { 1.0e4 } ;",    # Real with exponent
    "a is written as b() restricted to { 1.0e-4 } ;",   # Real with negative exponent
    "a is written as b() restricted to { -1.0e-4 } ;",  # Negative real with negative exponent
    "a is written as b() restricted to { 1.1 .. 2.2 } ;",       # Real range, maximal whitespace
    "a is written as b() restricted to { -1.1 .. 2.2 } ;",      # Real range, maximal whitespace
    "a is written as b() restricted to { 1.1..2.2};",   # Real range, minimal whitespace
    "a is written as b() restricted to { 1.1..2 } ;",   # Real-integer range
    "a is written as b() restricted to { 1..2.2 } ;",   # Integer-real range
    "a is written as b() restricted to { ..2.2};",      # Real range with open start
    "a is written as b() restricted to { 1.1.. };",     # Real range with open end
    "a is written as b() restricted to { 1.1.., 2 };",  # Real range with open end and following integer

    # Strings and string value constraints
    "a is written as b() restricted to {''};",          # String, empty, minimal whitespace
    "a is written as b() restricted to {'A'};",         # String, minimal whitespace
    "a is written as b() restricted to { 'A' };",       # String, maximal whitespace
    "a is written as b() restricted to { '\\b\\t\\f\\n\\r\\e\\\\' };",  # String with special escapes
    "a is written as b() restricted to { ' ' };",       # String with space
    "a is written as b() restricted to { '\t' };",      # String with literal tab
    "a is written as b() restricted to { '\\0' };",     # String with nul character
    "a is written as b() restricted to { '\\077' };",   # String with octal escape
    "a is written as b() restricted to { '\\0xA9' };",  # String with hexadecimal escape
    "a is written as b() restricted to { '\\0uBabe' };",# String with unicode escape
    "a is written as b() restricted to {'A'..'F'};",    # String range, minimal whitespace
    "a is written as b() restricted to { 'A' .. 'F' };",# String range, maximal whitespace
    "a is written as b() restricted to { ..'F' };",     # String range, open start
    "a is written as b() restricted to { 'A'.. };",     # String range, open end

    # Value constraints with units
    "a is written as b() restricted to {1} inches^2/second;",    # constraint with units and exponent
    "a is written as b() second^-1/mm^-1 mm^-1 restricted to {1} inches^2/second;",    # type with unit and constraint with units and exponent
  ]

  before :each do
    @parser = TestParser.new
  end

  ValidNumbersEtc.each do |c|
    source, ast = *[c].flatten
    it "should parse #{source.inspect}" do
      result = @parser.parse_all(source, :definition)

      puts @parser.failure_reason unless result
      result.should_not be_nil
      result.map{|d| d.value}.should == ast if ast
      # puts result.map{|d| d.value}.inspect unless ast
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
      [["a", [:value_type, "b", [1, 2], [["inch", 1]], [[3, 4]], [], []]]]
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

      result.map{|d| d.value}.should == ast if ast
      puts result.map{|d| d.value}.inspect unless ast
    end
  end
end

describe "Entity Types" do
  EntityTypes_RefMode = [
    [ "a is identified by its id;",                     # Entity type declaration with reference mode
      [["a", [:entity_type, [], {:enforcement=>nil, :mode=>"id", :parameters=>[], :value_constraint=>nil}, [], nil]]] 
    ],
    [ "a is identified by its number(12);",                     # Entity type declaration with reference mode
      [["a", [:entity_type, [], {:enforcement=>nil, :mode=>"number", :parameters=>[12], :value_constraint=>nil}, [], nil]]]
    ],
    [ "a is identified by its id:c;",                   # Entity type declaration with reference mode and fact type(s)
      [["a", [:entity_type, [], {:enforcement=>nil, :mode=>"id", :parameters=>[], :value_constraint=>nil}, [], [[:fact_clause, [], ["c"], nil]]]]]
    ],
    [ "a is identified by its id where c;",             # Entity type declaration with reference mode and where
      [["a", [:entity_type, [], {:enforcement=>nil, :mode=>"id", :parameters=>[], :value_constraint=>nil}, [], [[:fact_clause, [], ["c"], nil]]]]]
    ],
  ]

  EntityTypes_Simple = [
    [ "a is identified by b: c;",                       # Entity type declaration
      [["a", [:entity_type, [], {:roles=>[["b"]]}, [], [[:fact_clause, [], ["c"], nil]]]]]
    ],
    [ "a is identified by b where c;",                  # Entity type declaration with where
      [["a", [:entity_type, [], {:roles=>[["b"]]}, [], [[:fact_clause, [], ["c"], nil]]]]]
    ],
    [ "a is identified by b and c: d;",                 # Entity type declaration with two-part identifier
      [["a", [:entity_type, [], {:roles=>[["b"], ["c"]]}, [], [[:fact_clause, [], ["d"], nil]]]]]
    ],
    [ "a is identified by b, c: d;",                    # Entity type declaration with two-part identifier
      [["a", [:entity_type, [], {:roles=>[["b"], ["c"]]}, [], [[:fact_clause, [], ["d"], nil]]]]]
    ],
    [ "a is written as b(); c is identified by a:d;",
      [["a", [:value_type, "b", [], [], [], [], nil]], ["c", [:entity_type, [], {:roles=>[["a"]]}, [], [[:fact_clause, [], ["d"], nil]]]]]
    ],
    [ " a is written as b ( ) ; c is identified by a : d ; ",
      [["a", [:value_type, "b", [], [], [], [], nil]], ["c", [:entity_type, [], {:roles=>[["a"]]}, [], [[:fact_clause, [], ["d"], nil]]]]]
    ],
    [ "a is identified by c:maybe d;",
      [["a", [:entity_type, [], {:roles=>[["c"]]}, [], [[:fact_clause, ["maybe"], ["d"], nil]]]]]
    ],
  ]

  EntityTypes_Objectified = [
    [ "Director is where Person directs Company, Company is directed by Person;",
      [["Director", [:fact_type, [[:fact_clause, [], [{:word=>"Person", :term=>"Person"}, "directs", {:word=>"Company", :term=>"Company"}], nil], [:fact_clause, [], [{:word=>"Company", :term=>"Company"}, "is", "directed", "by", {:word=>"Person", :term=>"Person"}], nil]], []]]]
    ],
    [ "Director: Person directs company;",
      [[nil, [:fact_type, [[:fact_clause, [], [{:word=>"Director", :term=>"Director"}], nil]], [[:fact_clause, [], [{:word=>"Person", :term=>"Person"}, "directs", "company"], nil]]]]]
    ],
  ]

  EntityTypes_Subtypes = [
    [ "Employee is a kind of Person;",
      [["Employee", [:entity_type, ["Person"], nil, [], nil]]]
    ],
    [ "Employee is a subtype of Person;",
      [["Employee", [:entity_type, ["Person"], nil, [], nil]]]
    ],
    [ "AustralianEmployee is a subtype of Employee, Australian;",
      [["AustralianEmployee", [:entity_type, ["Employee", "Australian"], nil, [], nil]]]
    ],
    [ "Employee is a kind of Person identified by EmployeeNumber;",
      [["Employee", [:entity_type, ["Person"], {:roles=>[["EmployeeNumber"]]}, [], nil]]]
    ],
    [ "Employee is a subtype of Person identified by EmployeeNumber;",
      [["Employee", [:entity_type, ["Person"], {:roles=>[["EmployeeNumber"]]}, [], nil]]]
    ],
    [ "AustralianEmployee is a subtype of Employee, Australian identified by TaxFileNumber;",
      [["AustralianEmployee", [:entity_type, ["Employee", "Australian"], {:roles=>[["TaxFileNumber"]]}, [], nil]]]
    ],
  ]

  EntityTypes =
    EntityTypes_RefMode +
    EntityTypes_Simple +
    EntityTypes_Objectified +
    EntityTypes_Subtypes

  before :each do
    @parser = TestParser.new
  end

  EntityTypes.each do |c|
    source, ast = *c
    it "should parse #{source.inspect}" do
      result = @parser.parse_all(source, :definition)

      puts @parser.failure_reason unless result

      result.should_not be_nil
      if ast
        result.map{|d| d.value}.should == ast
      else
        puts "\n"+result.map{|d| d.value}.inspect
      end
    end
  end
end

describe "Fact Types" do
  FactTypes = [
    [ "Foo has at most one Bar, Bar is of one Foo restricted to {1..10};",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"Foo", :term=>"Foo"}, "has", {:quantifier_restriction=>[], :word=>"Bar", :term=>"Bar", :quantifier=>[nil, 1]}], nil], [:fact_clause, [], [{:word=>"Bar", :term=>"Bar"}, "is", "of", {:value_constraint=>[[1, 10]], :quantifier_restriction=>[], :word=>"Foo", :term=>"Foo", :quantifier=>[1, 1], :value_constraint_enforcement=>[]}], nil]], []]]
    ],
    [ "Bar(1) is related to Bar(2), primary-Bar(1) has secondary-Bar(2);",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"Bar", :term=>"Bar", :role_name=>1}, "is", "related", "to", {:word=>"Bar", :term=>"Bar", :role_name=>2}], nil], [:fact_clause, [], [{:leading_adjective=>"primary", :word=>"primary Bar", :term=>"Bar", :role_name=>1}, "has", {:leading_adjective=>"secondary", :word=>"secondary Bar", :term=>"Bar", :role_name=>2}], nil]], []]]
    ],
    [ "Director is old: Person directs company, Person is of Age, Age > 60;",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"Director", :term=>"Director"}, "is", "old"], nil]], [[:fact_clause, [], [{:word=>"Person", :term=>"Person"}, "directs", "company"], nil], [:fact_clause, [], [{:word=>"Person", :term=>"Person"}, "is", "of", {:word=>"Age", :term=>"Age"}], nil], [">", [:variable, "Age"], 60]]]]
    ],
    [ "A is a farce: maybe A has completely- B [transitive, acyclic], B -c = 2;",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"A", :term=>"A"}, "is", "a", "farce"], nil]], [[:fact_clause, ["maybe", "transitive", "acyclic"], [{:word=>"A", :term=>"A"}, "has", {:leading_adjective=>"completely", :word=>"completely B", :term=>"B"}], nil], ["=", [:variable, "B c"], 2]]]]
    ],
    [ "A is a farce: maybe A has completely- green B [transitive, acyclic], B -c = 2;",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"A", :term=>"A"}, "is", "a", "farce"], nil]], [[:fact_clause, ["maybe", "transitive", "acyclic"], [{:word=>"A", :term=>"A"}, "has", {:leading_adjective=>"completely green", :word=>"completely green B", :term=>"B"}], nil], ["=", [:variable, "B c"], 2]]]]
    ],
    [ "A is a farce: maybe A has B green -totally [transitive, acyclic], B -c = 2;",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"A", :term=>"A"}, "is", "a", "farce"], nil]], [[:fact_clause, ["maybe", "transitive", "acyclic"], [{:word=>"A", :term=>"A"}, "has", {:trailing_adjective=>"green totally", :word=>"B green totally", :term=>"B"}], nil], ["=", [:variable, "B c"], 2]]]]
    ],
    [ "Person is independent: Person has taxable- Income, taxable Income >= 20000 dollars;",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"Person", :term=>"Person"}, "is", "independent"], nil]], [[:fact_clause, [], [{:word=>"Person", :term=>"Person"}, "has", {:leading_adjective=>"taxable", :word=>"taxable Income", :term=>"Income"}], nil], [">=", [:variable, "taxable Income"], [20000, "dollars"]]]]]
    ],
    [ "Window requires toughening: Window has Width -mm, Window has Height -mm, Width mm * Height mm >= 10 foot^2;",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"Window", :term=>"Window"}, "requires", "toughening"], nil]], [[:fact_clause, [], [{:word=>"Window", :term=>"Window"}, "has", {:trailing_adjective=>"mm", :word=>"Width mm", :term=>"Width"}], nil], [:fact_clause, [], [{:word=>"Window", :term=>"Window"}, "has", {:trailing_adjective=>"mm", :word=>"Height mm", :term=>"Height"}], nil], [">=", [:*, [:variable, "Width mm"], [:variable, "Height mm"]], [10, "foot^2"]]]]]
    ],
    # REVISIT: Test all quantifiers
    # REVISIT: Test all post-qualifiers
    # REVISIT: Test functions
    [ "AnnualIncome is where Person has total- Income in Year: Person has total- Income.sum(), Income was earned in current- Time.Year() (as Year);",
      ["AnnualIncome", [:fact_type, [[:fact_clause, [], [{:word=>"Person", :term=>"Person"}, "has", {:leading_adjective=>"total", :word=>"total Income", :term=>"Income"}, "in", {:word=>"Year", :term=>"Year"}], nil]], [[:fact_clause, [], [{:word=>"Person", :term=>"Person"}, "has", {:leading_adjective=>"total", :function=>[:"(", "sum"], :word=>"total Income", :term=>"Income"}], nil], [:fact_clause, [], [{:word=>"Income", :term=>"Income"}, "was", "earned", "in", {:leading_adjective=>"current", :function=>[:"(", "Year"], :role_name=>"Year", :word=>"current Time", :term=>"Time"}], nil]]]]
    ],
    [ "A is interesting : b- C has F -g;",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"A", :term=>"A"}, "is", "interesting"], nil]], [[:fact_clause, [], [{:leading_adjective=>"b", :word=>"b C", :term=>"C"}, "has", {:trailing_adjective=>"g", :word=>"F g", :term=>"F"}], nil]]]]
    ]
  ]

  before :each do
    @parser = TestParser.new
  end

  FactTypes.each do |c|
    source, ast, definition = *c
    it "should parse #{source.inspect}" do
      definitions = @parser.parse_all(source, :definition)

      puts @parser.failure_reason unless definitions

      definitions.should_not be_nil
      result = definitions[-1]

      if (definition)
        result.definition.should == definition
      else
        #p @parser.definition(result)
      end

      result.value.should == ast if ast
      puts result.map{|d| d.value}.inspect unless ast
    end
  end
end

describe "Constraint" do
  Constraints = [
    [ "each combination FamilyName, GivenName occurs at most one time in Competitor has FamilyName, Competitor has GivenName;",
      [nil, [:constraint, :presence, [["FamilyName"], ["GivenName"]], [nil, 1], [[[{:word=>"Competitor", :term=>"Competitor"}, "has", {:word=>"FamilyName", :term=>"FamilyName"}]], [[{:word=>"Competitor", :term=>"Competitor"}, "has", {:word=>"GivenName", :term=>"GivenName"}]]], nil, []]]
    ],
  ]

  before :each do
    @parser = TestParser.new
  end

  Constraints.each do |c|
    source, ast, definition = *c
    it "should parse #{source.inspect}" do
      definitions = @parser.parse_all(source, :definition)

      puts @parser.failure_reason unless definitions

      definitions.should_not be_nil
      result = definitions[-1]

      if (definition)
        result.definition.should == definition
      else
        #p @parser.definition(result)
      end

      result.value.should == ast if ast

      result.value.inspect unless ast
    end
  end
end
=end
