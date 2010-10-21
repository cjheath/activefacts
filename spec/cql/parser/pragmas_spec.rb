#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'helpers/test_parser'

describe "Entity Types" do
  IndependentObjectTypes = [
    # Value types
    [ "a is written as b [independent];",
      ['ValueType: a is written as b, pragmas [independent];'],
    ],
    [ "a [independent] is written as b;",
      ['ValueType: a is written as b, pragmas [independent];'],
    ],

    # Entity types
    [ "a is identified by its id [independent];",
      ['EntityType: a identified by its id, pragmas [independent];']
    ],
    [ "a [independent] is identified by its id;",
      ['EntityType: a identified by its id, pragmas [independent];']
    ],
    [ "a is independent identified by its id;",
      ['EntityType: a identified by its id, pragmas [independent];']
    ],
    [ "a is identified by b [independent] where a has one b;",
      ['EntityType: a [{b}] where [{a} "has" {[1..1] b}], pragmas [independent];']
    ],
    [ "a is independent identified by b where a has one b;",
      ['EntityType: a [{b}] where [{a} "has" {[1..1] b}], pragmas [independent];']
    ],

    # Subtypes
    [ "Employee [independent] is a kind of Person;",
      ['EntityType: Employee < Person nil, pragmas [independent];']
    ],
    [ "Employee is a kind of Person [independent];",
      ['EntityType: Employee < Person nil, pragmas [independent];']
    ],
    [ "Employee is a kind of independent Person;",
      ['EntityType: Employee < Person nil, pragmas [independent];']
    ],
    [ "Employee is a kind of Person identified by its id [independent];",
      ["EntityType: Employee < Person identified by its id, pragmas [independent];"]
    ],

    # Fact Types
    [ "Director is where c relates to b;",
      ["FactType: Director [{c} \"relates to\" {b}]"]
    ],
    [ "Director [independent] is where c relates to b;",
      ["FactType: Director [{c} \"relates to\" {b}], pragmas [independent]"]
    ],
    [ "Director is independent where c relates to b;",
      ["FactType: Director [{c} \"relates to\" {b}], pragmas [independent]"]
    ],
  ]

  PragmaObjectTypes =
    IndependentObjectTypes

  before :each do
    @parser = TestParser.new
    @parser.parse_all("c is written as b;", :definition)
  end

  PragmaObjectTypes.each do |c|
    source, ast = *c
    it "should parse #{source.inspect}" do
      result = @parser.parse_all(source, :definition)

      puts @parser.failure_reason unless result
      result.should_not be_nil

      canonical_form = result.map{|d| d.ast.to_s}
      if ast
        canonical_form.should == ast
      else
        pending "#{source.inspect} should compile to\n" +
          "\t#{canonical_form}"
      end
    end
  end
end
