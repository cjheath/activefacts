#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'helpers/test_parser'

describe "Entity Types" do
  EntityTypes_RefMode = [
    [ "a is identified by its id;",                     # Entity type declaration with reference mode
      ["EntityType: a identified by its id;"]
    ],
    [ "a is identified by its number(12);",                     # Entity type declaration with reference mode
      ["EntityType: a identified by its number(12);"]
    ],
    [ "a is identified by its id where c;",                   # Entity type declaration with reference mode and fact type(s)
      ["EntityType: a identified by its id where [{c}];"]
    ],
    [ "a is identified by its id where c;",             # Entity type declaration with reference mode and where
      ["EntityType: a identified by its id where [{c}];"]
    ],
  ]

  EntityTypes_Simple = [
    [ "a is identified by b where c;",                       # Entity type declaration
      ["EntityType: a [{b}] where [{c}];"]
    ],
    [ "a is identified by b where c;",                  # Entity type declaration with where
      ["EntityType: a [{b}] where [{c}];"]
    ],
    [ "a is identified by b and c where d;",                 # Entity type declaration with two-part identifier
      ["EntityType: a [{b}, {c}] where [\"d\"];"]
    ],
    [ "a is identified by b, c where d;",                    # Entity type declaration with two-part identifier
      ["EntityType: a [{b}, {c}] where [\"d\"];"]
    ],
    [ "a is written as b(); e is identified by a where d;",
      ["ValueType: a is written as b;", "EntityType: e [{a}] where [\"d\"];"]
    ],
    [ " a is written as b ( ) ; e is identified by a where d ; ",
      ["ValueType: a is written as b;", "EntityType: e [{a}] where [\"d\"];"]
    ],
    [ "e is written as b; a is identified by e where maybe d;",
      ["ValueType: e is written as b;", "EntityType: a [{e}] where [[\"maybe\"] \"d\"];"]
    ],
  ]

  EntityTypes_Objectified = [
    [ "Director is where b directs c, c is directed by b;",
      ["FactType: Director [{b} \"directs\" {c}, {c} \"is directed by\" {b}]"]
    ],
  ]

  EntityTypes_Subtypes = [
    [ "Employee is a kind of Person;",
      ["EntityType: Employee < Person nil;"]
    ],
    [ "Employee is a subtype of Person;",
      ["EntityType: Employee < Person nil;"]
    ],
    [ "AustralianEmployee is a subtype of Employee, Australian;",
      ["EntityType: AustralianEmployee < Employee,Australian nil;"]
    ],
    [ "Employee is a kind of Person identified by EmployeeNumber;",
      ["EntityType: Employee < Person [{EmployeeNumber}];"]
    ],
    [ "Employee is a subtype of Person identified by EmployeeNumber;",
      ["EntityType: Employee < Person [{EmployeeNumber}];"]
    ],
    [ "AustralianEmployee is a subtype of Employee, Australian identified by TaxFileNumber;",
      ["EntityType: AustralianEmployee < Employee,Australian [{TaxFileNumber}];"]
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
