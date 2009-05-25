#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'treetop'
require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/parser'

describe "Valid Numbers, Strings and Ranges" do
  ValidNumbersEtc = [
    "a is written as b;",				# Value type declaration, no params, minimal whitespace
    "a is written as b();",				# Value type declaration, minimal whitespace
    "a is written as b ;",				# Value type declaration, no params, trailing whitespace
    "a is written as b ( ) ; ",				# Value type declaration, maximal whitespace

    # Comments and newlines, etc as whitespace
    "\na\nis written as \nb\n(\n)\n;\n",		# Basic value type declaration, newlines for whitespace
    "\ra\ris written as\rb\r(\r)\r;\r",			# Basic value type declaration, returns for whitespace
    "\ta\tis written as\tb\t(\t)\t;\t",			# Basic value type declaration, tabs for whitespace
    " /* Plugh */ a /* Plugh */ is written as\n b /* *Plugh* / */ ( /* *Plugh* / */ ) /* *Plugh* / */ ; /* *Plugh* / */ ",
    "//Plugh\na // Plugh\n is written as // Plugh\n b // Plugh\n ( // Plugh\n ) // Plugh\n ; // Plugh\n ",

    # Integers
    "a is written as b(0);",				# Integer zero
    "a is written as b( 0 ) ; ",			# Integer zero, maximal whitespace
    "a is written as b(1);",				# Integer one
    "a is written as b(-1);",				# Integer negative one
    "a is written as b(+1);",				# Positive integer
    "a is written as b(1e4);",				# Integer with exponent
    "a is written as b(1e-4);",				# Integer with negative exponent
    "a is written as b(-1e-4);",			# Negative integer with negative exponent
    "a is written as b(077);",				# Octal integer
    "a is written as b(0xFace8);",			# Hexadecimal integer
    "a is written as b(0,1);",				# Two parameters
    "a is written as b( 0 , 1 );",
    "a is written as b(0,1,2) ;",			# Three parameters now allowed

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
    "a is written as b inch;",				# Value type declaration with unit
    "a is written as b() inch ; ",			# Value type declaration with unit and whitespace
    "a is written as b() inch;",			# Value type declaration with unit
    "a is written as b inch^2;",			# Value type declaration with unit and exponent
    "a is written as b() inch^2 ; ",			# Value type declaration with unit and exponent with maximum whitespace
    "a is written as b second^-1;",			# Value type declaration with unit and negative exponent
    "a is written as b inch inch;",			# Value type declaration with repeated unit
    "a is written as b inch^2/minute^-1;",		# Value type declaration with unit and divided unit with exponents
    "a is written as b() second^-1/mm^-1 mm^-1;",       # Value type declaration with repeated divided unit

    # Integer value restrictions
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

    # Real value restrictions
    "a is written as b() restricted to {1.0};",         # Real, minimal whitespace
    "a is written as b() restricted to { 1.0 } ;",      # Real, maximal whitespace
    "a is written as b() restricted to { 1.0e4 } ;",    # Real with exponent
    "a is written as b() restricted to { 1.0e-4 } ;",   # Real with negative exponent
    "a is written as b() restricted to { -1.0e-4 } ;",  # Negative real with negative exponent
    "a is written as b() restricted to { 1.1 .. 2.2 } ;",	# Real range, maximal whitespace
    "a is written as b() restricted to { -1.1 .. 2.2 } ;",	# Real range, maximal whitespace
    "a is written as b() restricted to { 1.1..2.2};",   # Real range, minimal whitespace
    "a is written as b() restricted to { 1.1..2 } ;",   # Real-integer range
    "a is written as b() restricted to { 1..2.2 } ;",   # Integer-real range
    "a is written as b() restricted to { ..2.2};",      # Real range with open start
    "a is written as b() restricted to { 1.1.. };",     # Real range with open end
    "a is written as b() restricted to { 1.1.., 2 };",  # Real range with open end and following integer

    # Strings and string value restrictions
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

    # Value restrictions with units
    "a is written as b() restricted to {1} inches^2/second;",    # restriction with units and exponent
    "a is written as b() second^-1/mm^-1 mm^-1 restricted to {1} inches^2/second;",    # type with unit and restriction with units and exponent
  ]

  before :each do
    @parser = ActiveFacts::CQLParser.new
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
    "b(- 1e-4);",					# Negative integer with negative exponent
    "a is written as b(-077);",                         # Invalid negative octal
    "a is written as b(-0xFace);",                      # Invalid negative hexadecimal
    "a is written as b(.0);",                           # Invalid real
    "a is written as b(0.);",                           # Invalid real
    "b() inch ^2 ; ",					# Illegal whitespace around unit exponent
    "b() inch^ 2 ; ",					# Illegal whitespace around unit exponent
    "b() restricted to { '\\7a' };",			# String with bad octal escape
    "b() restricted to { '\001' };",			# String with control char
    "b() restricted to { '\n' };",			# String with literal newline
    "b() restricted to { 0..'A' };",			# Cross-typed range
    "b() restricted to { 'a'..27 };",			# Cross-typed range
  ]

  before :each do
    @parser = ActiveFacts::CQLParser.new
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

describe "Data Types" do
  DataTypes = [
    [ "a is written as b(1, 2) inch restricted to { 3 .. 4 } inch ;",
      [["a", [:data_type, "b", [ 1, 2 ], "inch", [[3, 4]]]]]
    ],
#    [ "a c  is written as b(1, 2) inch restricted to { 3 .. 4 } inch ;",
#      [["a c", [:data_type, "b", [1, 2], "inch", [[3, 4]]]]]
#    ],
  ]

  before :each do
    @parser = ActiveFacts::CQLParser.new
  end

  DataTypes.each do |c|
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
    [ "a is identified by its id;",			# Entity type declaration with reference mode
      [["a", [:entity_type, [], {:mode=>"id"}, nil]]]
    ],
    [ "a is identified by its id:c;",			# Entity type declaration with reference mode and fact type(s)
      [["a", [:entity_type, [], {:mode=>"id"}, [[:fact_clause, [], [{:word=>"c"}]]]]]]
    ],
    [ "a is identified by its id where c;",             # Entity type declaration with reference mode and where
      [["a", [:entity_type, [], {:mode=>"id"}, [[:fact_clause, [], [{:word=>"c"}]]]]]]
    ],
  ]

  EntityTypes_Simple = [
    [ "a is identified by b: c;",			# Entity type declaration
      [["a", [:entity_type, [], {:roles=>[["b"]]}, [[:fact_clause, [], [{:word=>"c"}]]]]]]
    ],
    [ "a is identified by b where c;",			# Entity type declaration with where
      [["a", [:entity_type, [], {:roles=>[["b"]]}, [[:fact_clause, [], [{:word=>"c"}]]]]]]
    ],
    [ "a is identified by b and c: d;",			# Entity type declaration with two-part identifier
      [["a", [:entity_type, [], {:roles=>[["b"], ["c"]]}, [[:fact_clause, [], [{:word=>"d"}]]]]]]
    ],
    [ "a is identified by b, c: d;",			# Entity type declaration with two-part identifier
      [["a", [:entity_type, [], {:roles=>[["b"], ["c"]]}, [[:fact_clause, [], [{:word=>"d"}]]]]]]
    ],
    [ "a is written as b(); c is identified by a:d;",
      [["a", [:data_type, "b", [], nil, []]],
        ["c", [:entity_type, [], {:roles=>[["a"]]}, [[:fact_clause, [], [{:word=>"d"}]]]]]]
    ],
    [ " a is written as b ( ) ; c is identified by a : d ; ",
      [["a", [:data_type, "b", [ ], nil, []]],
        ["c", [:entity_type, [], {:roles=>[["a"]]}, [[:fact_clause, [], [{:word=>"d"}]]]]]]
    ],
    [ "a is identified by c:maybe d;",
      [["a", [:entity_type, [], {:roles=>[["c"]]}, [[:fact_clause, ["maybe"], [{:word=>"d"}]]]]]]
    ],
  ]

  EntityTypes_Objectified = [
    [ "Director = Person directs Company, Company is directed by Person;",
      [["Director", [:fact_type, [[:fact_clause, [], [{:word=>"Person"}, {:word=>"directs"}, {:word=>"Company"}]], [:fact_clause, [], [{:word=>"Company"}, {:word=>"is"}, {:word=>"directed"}, {:word=>"by"}, {:word=>"Person"}]]], []]]]
    ],
    [ "Director: Person directs company;",
      [[nil, [:fact_type, [[:fact_clause, [], [{:word=>"Director"}]]], [[:fact_clause, [], [{:word=>"Person"}, {:word=>"directs"}, {:word=>"company"}]]]]]]
    ],
  ]

  EntityTypes_Subtypes = [
    [ "Employee is a kind of Person;",
      [["Employee", [:entity_type, ["Person"], nil, nil]]]
    ],
    [ "Employee is a subtype of Person;",
      [["Employee", [:entity_type, ["Person"], nil, nil]]]
    ],
    [ "AustralianEmployee is a subtype of Employee, Australian;",
      [["AustralianEmployee", [:entity_type, ["Employee", "Australian"], nil, nil]]]
    ],
    [ "Employee is a kind of Person identified by EmployeeNumber;",
      [["Employee", [:entity_type, ["Person"], {:roles=>[["EmployeeNumber"]]}, nil]]]
    ],
    [ "Employee is a subtype of Person identified by EmployeeNumber;",
      [["Employee", [:entity_type, ["Person"], {:roles=>[["EmployeeNumber"]]}, nil]]]
    ],
    [ "AustralianEmployee is a subtype of Employee, Australian identified by TaxFileNumber;",
      [["AustralianEmployee", [:entity_type, ["Employee", "Australian"], {:roles=>[["TaxFileNumber"]]}, nil]]]
    ],
  ]

  EntityTypes =
    EntityTypes_RefMode +
    EntityTypes_Simple +
    EntityTypes_Objectified +
    EntityTypes_Subtypes

  before :each do
    @parser = ActiveFacts::CQLParser.new
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
    [ "Director is old: Person directs company, Person is of age, age > 60;",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"Director"}, {:word=>"is"}, {:word=>"old"}]]], [[:fact_clause, [], [{:word=>"Person"}, {:word=>"directs"}, {:word=>"company"}]], [:fact_clause, [], [{:word=>"Person"}, {:word=>"is"}, {:word=>"of"}, {:word=>"age"}]], [">", [:variable, "age"], 60]]]]
    ],
    [ "a: maybe a has completely- green b -totally [transitive, acyclic], b -c = 2;",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"a"}]]], [[:fact_clause, ["maybe", "transitive", "acyclic"], [{:word=>"a"}, {:word=>"has"}, {:word=>"green", :leading_adjective=>"completely"}, {:word=>"b", :trailing_adjective=>"totally"}]], ["=", [:+, [:variable, "b"], [:-, [:variable, "c"]]], 2]]]]
    ],
    [ "Person is independent: Person has taxable- Income, taxable Income >= 20000 dollars;",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"Person"}, {:word=>"is"}, {:word=>"independent"}]]], [[:fact_clause, [], [{:word=>"Person"}, {:word=>"has"}, {:leading_adjective=>"taxable", :word=>"Income"}]], [">=", [:variable, "taxable", "Income"], [20000, "dollars"]]]]]
    ],
    [ "Window requires toughening: Window has width-mm, Window has height-mm, width mm * height mm >= 10 foot^2;",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"Window"}, {:word=>"requires"}, {:word=>"toughening"}]]], [[:fact_clause, [], [{:word=>"Window"}, {:word=>"has"}, {:leading_adjective=>"width", :word=>"mm"}]], [:fact_clause, [], [{:word=>"Window"}, {:word=>"has"}, {:leading_adjective=>"height", :word=>"mm"}]], [">=", [:*, [:variable, "width", "mm"], [:variable, "height", "mm"]], [10, "foot^2"]]]]]
    ],
    # REVISIT: Test all quantifiers
    # REVISIT: Test all post-qualifiers
    # REVISIT: Test functions
    [ "AnnualIncome is where Person has total- Income in Year: Person has total- Income.sum(), Income was earned in current- time.Year() (as Year);",
      ["AnnualIncome", [:fact_type, [[:fact_clause, [], [{:word=>"Person"}, {:word=>"has"}, {:leading_adjective=>"total", :word=>"Income"}, {:word=>"in"}, {:word=>"Year"}]]], [[:fact_clause, [], [{:word=>"Person"}, {:word=>"has"}, {:function=>[:"(", "sum"], :leading_adjective=>"total", :word=>"Income"}]], [:fact_clause, [], [{:word=>"Income"}, {:word=>"was"}, {:word=>"earned"}, {:word=>"in"}, {:function=>[:"(", "Year"], :word=>"time", :role_name=>"Year", :leading_adjective=>"current"}]]]]]
    ],
    [ "a is interesting : b- c -d has e- f -g;",
      [nil, [:fact_type, [[:fact_clause, [], [{:word=>"a"}, {:word=>"is"}, {:word=>"interesting"}]]], [[:fact_clause, [], [{:trailing_adjective=>"d", :word=>"c", :leading_adjective=>"b"}, {:word=>"has"}, {:trailing_adjective=>"g", :word=>"f", :leading_adjective=>"e"}]]]]]
    ]
  ]

  before :each do
    @parser = ActiveFacts::CQLParser.new
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
