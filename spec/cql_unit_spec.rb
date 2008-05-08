require 'rubygems'
require 'treetop'
require 'activefacts/cql'

describe "Valid Numbers, Strings and Ranges" do
  ValidNumbersEtc = [
    "a=b();",                                   # Basic data type declaration, minimal whitespace
    "a = b ( ) ; ",                             # Basic data type declaration, maximal whitespace
    "a is defined as b();",                     # Verbally named data type declaration
    "a=b() inch;",                              # Data type declaration with unit
    "a=b() inch ; ",                            # Data type declaration with unit
    "a=b() inch^2 ; ",                          # Data type declaration with unit and exponent

    # Comments etc as whitespace
    "\na\n= \nb\n(\n)\n;\n",                    # Basic data type declaration, newlines for whitespace
    "\ra\r=\rb\r(\r)\r;\r",                     # Basic data type declaration, returns for whitespace
    "\ta\t=\tb\t(\t)\t;\t",                     # Basic data type declaration, tabs for whitespace
    " /* Plugh */ a /* Plugh */ =\n b /* *Plugh* / */ ( /* *Plugh* / */ ) /* *Plugh* / */ ; /* *Plugh* / */ ",
    "//Plugh\na // Plugh\n = // Plugh\n b // Plugh\n ( // Plugh\n ) // Plugh\n ; // Plugh\n ",

    # Integers
    "a=b(0);",                                  # Integer zero
    "a=b( 0 ) ; ",                              # Integer zero, maximal whitespace
    "a=b(1);",                                  # Integer one
    "a=b(-1);",                                 # Integer negative one
    "a=b(+1);",                                 # Positive integer
    "a=b(1e4);",                                # Integer with exponent
    "a=b(1e-4);",                               # Integer with negative exponent
    "a=b(-1e-4);",                              # Negative integer with negative exponent
    "a=b(077);",                                # Octal integer
    "a=b(0xFace8);",                            # Hexadecimal integer
    "a=b(0,1);",                                # Two parameters
    "a=b( 0 , 1 );",

    # Reals
    "a=b(1.0);",
    "a=b(-1.0);",
    "a=b(+1.0);",
    "a=b(0.1);",
    "a=b(-0.1);",
    "a=b(+0.1);",
    "a=b(0.0);",
    "a=b(-0.0);",
    "a=b(+0.0);",

    # Integer value restrictions
    "a=b()restricted to{1};",                   # Integer, minimal whitespace
    "a=b() restricted to { 1 } ;",              # Integer, maximal whitespace
    "a=b() restricted to {1..2};",              # Integer range, minimal whitespace
    "a=b() restricted to { 1 .. 2 };",          # Integer range, maximal whitespace
    "a=b() restricted to {..2};",               # Integer range with open start, minimal whitespace
    "a=b() restricted to { .. 2 };",            # Integer range with open start, maximal whitespace
    "a=b() restricted to { ..2,3};",            # Range followed by integer, minimal whitespace
    "a=b() restricted to { 1,..2,3};",          # Integer, open-start range, integer, minimal whitespace
    "a=b() restricted to { .. 2 , 3 };",        # Range followed by integer, maximal whitespace
    "a=b() restricted to { ..2 , 3..4 };",      # Range followed by range
    "a=b() restricted to { ..2, 3..};",         # Range followed by range with open end, minimal whitespace
    "a=b() restricted to { ..2, 3 .. };",       # Range followed by range with open end, maximal whitespace
    "a=b() restricted to { 1e4 } ;",            # Integer with exponent
    "a=b() restricted to { -1e4 } ;",           # Negative integer with exponent
    "a=b() restricted to { 1e-4 } ;",           # Integer with negative exponent
    "a=b() restricted to { -1e-4 } ;",          # Negative integer with negative exponent

    # Real value restrictions
    "a=b() restricted to {1.0};",               # Real, minimal whitespace
    "a=b() restricted to { 1.0 } ;",            # Real, maximal whitespace
    "a=b() restricted to { 1.0e4 } ;",          # Real with exponent
    "a=b() restricted to { 1.0e-4 } ;",         # Real with negative exponent
    "a=b() restricted to { -1.0e-4 } ;",        # Negative real with negative exponent
    "a=b() restricted to { 1.1 .. 2.2 } ;",     # Real range, maximal whitespace
    "a=b() restricted to { -1.1 .. 2.2 } ;",    # Real range, maximal whitespace
    "a=b() restricted to { 1.1..2.2};",         # Real range, minimal whitespace
    "a=b() restricted to { 1.1..2 } ;",         # Real-integer range
    "a=b() restricted to { 1..2.2 } ;",         # Integer-real range
    "a=b() restricted to { ..2.2};",            # Real range with open start
    "a=b() restricted to { 1.1.. };",           # Real range with open end
    "a=b() restricted to { 1.1.., 2 };",        # Real range with open end and following integer

    # Strings and string value restrictions
    "a=b() restricted to {''};",                # String, empty, minimal whitespace
    "a=b() restricted to {'A'};",               # String, minimal whitespace
    "a=b() restricted to { 'A' };",             # String, maximal whitespace
    "a=b() restricted to { '\\b\\t\\f\\n\\r\\e\\\\' };",  # String with special escapes
    "a=b() restricted to { ' ' };",             # String with space
    "a=b() restricted to { '\t' };",            # String with literal tab
    "a=b() restricted to { '\\0' };",           # String with nul character
    "a=b() restricted to { '\\077' };",         # String with octal escape
    "a=b() restricted to { '\\0xA9' };",        # String with hexadecimal escape
    "a=b() restricted to { '\\0uBabe' };",      # String with unicode escape
    "a=b() restricted to {'A'..'F'};",          # String range, minimal whitespace
    "a=b() restricted to { 'A' .. 'F' };",      # String range, maximal whitespace
    "a=b() restricted to { ..'F' };",           # String range, open start
    "a=b() restricted to { 'A'.. };",           # String range, open end
  ]

  setup do
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
    "a=b(08);",                                 # Invalid octalnumber
    "a=b(0xDice);",                             # Invalid hexadecimal
    "a=b(- 1);",                                # Invalid negative
    "a=b(+ 1);",                                # Invalid positive
    "b(- 1e-4);",                               # Negative integer with negative exponent
    "a=b(-077);",                               # Invalid negative octal
    "a=b(-0xFace);",                            # Invalid negative hexadecimal
    "a=b(.0);",                                 # Invalid real
    "a=b(0.);",                                 # Invalid real
    "a=b(0,1,2) ;",                             # Invalid; only two parameters allowed
    "b() inch ^2 ; ",                           # Illegal whitespace around unit exponent
    "b() inch^ 2 ; ",                           # Illegal whitespace around unit exponent
    "b() restricted to { '\\7a' };",            # String with bad octal escape
    "b() restricted to { '\001' };",            # String with control char
    "b() restricted to { '\n' };",              # String with literal newline
    "b() restricted to { 0..'A' };",            # Cross-typed range
    "b() restricted to { 'a'..27 };",           # Cross-typed range
  ]

  setup do
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
    [ "a = b(1, 2) inch restricted to { 3 .. 4 } inch ;",
      [["a", [:data_type, "b", [ 1, 2 ], "inch", [[3, 4]]]]]
    ],
#    [ "a c = b(1, 2) inch restricted to { 3 .. 4 } inch ;",
#      [["a c", [:data_type, "b", [1, 2], "inch", [[3, 4]]]]]
#    ],
  ]

  setup do
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
  EntityTypes = [
    [ "a = entity(.id):c;",                     # Entity type declaration with reference mode
      [["a", [:entity_type, nil, {:mode=>"id"}, [[:fact_clause, [], [{:words=>["c"]}]]]]]]
    ],
    [ "a = entity ( . id ) : c ;",              # Entity type declaration with reference mode, maximal whitespace
      [["a", [:entity_type, nil, {:mode=>"id"}, [[:fact_clause, [], [{:words=>["c"]}]]]]]]
    ],
    [ "a = entity(.id) where c;",               # Entity type declaration with reference mode and where
      [["a", [:entity_type, nil, {:mode=>"id"}, [[:fact_clause, [], [{:words=>["c"]}]]]]]]
    ],
    [ "a = entity identified by b: c;",         # Entity type declaration
      [["a", [:entity_type, nil, {:roles=>["b"]}, [[:fact_clause, [], [{:words=>["c"]}]]]]]]
    ],
    [ "a = entity identified by b where c;",            # Entity type declaration with where
      [["a", [:entity_type, nil, {:roles=>["b"]}, [[:fact_clause, [], [{:words=>["c"]}]]]]]]
    ],
    [ "a = entity identified by b and c: d;",   # Entity type declaration with two-part identifier
      [["a", [:entity_type, nil, {:roles=>["b", "c"]}, [[:fact_clause, [], [{:words=>["d"]}]]]]]]
    ],
    [ "a = entity identified by b, c: d;",              # Entity type declaration with two-part identifier
      [["a", [:entity_type, nil, {:roles=>["b", "c"]}, [[:fact_clause, [], [{:words=>["d"]}]]]]]]
    ],
    [ "a=b(); c=entity identified by a:d;",
      [["a", [:data_type, "b", [ false, false ], false, false]],
        ["c", [:entity_type, nil, {:roles=>["a"]}, [[:fact_clause, [], [{:words=>["d"]}]]]]]]
    ],
    [ " a = b ( ) ; c = entity identified by a : d ; ",
      [["a", [:data_type, "b", [ false, false ], false, false]],
        ["c", [:entity_type, nil, {:roles=>["a"]}, [[:fact_clause, [], [{:words=>["d"]}]]]]]]
    ],
    [ "a=entity(.c):maybe d;",
      [["a", [:entity_type, nil, {:mode=>"c"}, [[:fact_clause, ["maybe"], [{:words=>["d"]}]]]]]]
    ],
    [ "Director = Person directs company, company is directed by Person;",
      [["Director", [:fact_type, [[:fact_clause, [], [{:words=>["Person", "directs", "company"]}]], [:fact_clause, [], [{:words=>["company", "is", "directed", "by", "Person"]}]]]]]]
    ],
    [ "a: maybe a has completely- green b -totally [transitive, acyclic], b -c = 2;",
      [[nil, [:fact_type, [[:fact_clause, [], [{:words=>["a"]}]]], [:fact_clause, ["maybe", "transitive", "acyclic"], [{:words=>["a", "has"]}, {:words=>["green", "b"], :leading_adjective=>"completely", :trailing_adjective=>"totally"}]], ["=", [:+, [:variable, "b"], [:-, [:variable, "c"]]], 2]]]]
    ],
    [ "Director: Person directs company;",
      [[nil, [:fact_type, [[:fact_clause, [], [{:words=>["Director"]}]]], [:fact_clause, [], [{:words=>["Person", "directs", "company"]}]]]]]
    ],
    [ "Director is old: Person directs company, Person is of age, age > 60;",
      [[nil, [:fact_type, [[:fact_clause, [], [{:words=>["Director", "is", "old"]}]]], [:fact_clause, [], [{:words=>["Person", "directs", "company"]}]], [:fact_clause, [], [{:words=>["Person", "is", "of", "age"]}]], [">", [:variable, "age"], 60]]]]
    ],
    [ "Employee is a kind of Person;",
      [["Employee", [:entity_type, ["Person"], nil, []]]]
    ],
    [ "Employee is a subtype of Person;",
      [["Employee", [:entity_type, ["Person"], nil, []]]]
    ],
    [ "Employee = subtype of Person;",
      [["Employee", [:entity_type, ["Person"], nil, []]]]
    ],
    [ "Employee is defined as subtype of Person;",
      [["Employee", [:entity_type, ["Person"], nil, []]]]
    ],
    [ "AustralianEmployee = subtype of Employee, Australian;",
      [["AustralianEmployee", [:entity_type, ["Employee", "Australian"], nil, []]]]
    ],
    [ "Employee is a kind of Person identified by EmployeeNumber;",
      [["Employee", [:entity_type, ["Person"], {:roles=>["EmployeeNumber"]}, []]]]
    ],
    [ "Employee = subtype of Person identified by EmployeeNumber;",
      [["Employee", [:entity_type, ["Person"], {:roles=>["EmployeeNumber"]}, []]]]
    ],
    [ "Employee is defined as subtype of Person identified by EmployeeNumber;",
      [["Employee", [:entity_type, ["Person"], {:roles=>["EmployeeNumber"]}, []]]]
    ],
    [ "AustralianEmployee = subtype of Employee, Australian identified by TaxFileNumber;",
      [["AustralianEmployee", [:entity_type, ["Employee", "Australian"], {:roles=>["TaxFileNumber"]}, []]]]
    ],
  ]

  setup do
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
    [ "Person is independent: Person has taxable- Income, taxable Income >= 20000 dollars;",
      [[nil, [:fact_type, [[:fact_clause, [], [{:words=>["Person", "is", "independent"]}]]], [:fact_clause, [], [{:words=>["Person", "has"]}, {:leading_adjective=>"taxable", :words=>["Income"]}]], [">=", [:variable, "taxable", "Income"], [20000, "dollars"]]]]]
    ],
    [ "Window requires toughening: Window has width-mm, Window has height-mm, width mm * height mm >= 10 foot^2;",
      [[nil, [:fact_type, [[:fact_clause, [], [{:words=>["Window", "requires", "toughening"]}]]], [:fact_clause, [], [{:words=>["Window", "has"]}, {:leading_adjective=>"width", :words=>["mm"]}]], [:fact_clause, [], [{:words=>["Window", "has"]}, {:leading_adjective=>"height", :words=>["mm"]}]], [">=", [:*, [:variable, "width", "mm"], [:variable, "height", "mm"]], [10, "foot^2"]]]]]
    ],
    # REVISIT: Test all quantifiers
    # REVISIT: Test all post-qualifiers
    # REVISIT: Test functions
    [ "AnnualIncome = Person has total- Income in Year: Person has total- Income.sum(), Income was earned in current- time.Year;",
      [["AnnualIncome", [:fact_type, [[:fact_clause, [], [{:words=>["Person", "has"]}, {:leading_adjective=>"total", :words=>["Income", "in", "Year"]}]]], [:fact_clause, [], [{:words=>["Person", "has"]}, {:function=>[:"(", "sum"], :leading_adjective=>"total", :words=>["Income"]}]], [:fact_clause, [], [{:words=>["Income", "was", "earned", "in"]}, {:function=>[:"(", "Year"], :leading_adjective=>"current", :words=>["time"]}]]]]]
    ],
  ]

  setup do
    @parser = ActiveFacts::CQLParser.new
  end

  FactTypes.each do |c|
    source, ast = *c
    it "should parse #{source.inspect}" do
      result = @parser.parse_all(source, :definition)

      #REVISIT: @parser.failure_reason.should be_nil

      result.should_not be_nil

      result.map{|d| d.value}.should == ast if ast
      puts result.map{|d| d.value}.inspect unless ast
    end
  end
end
