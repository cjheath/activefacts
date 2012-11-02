#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'spec_helper'
require 'helpers/test_parser'

describe "ASTs from Derived Fact Types with expressions" do
  it "should parse a simple comparison clause" do
    # Director is old: Company is directed by Person who is of Age > 60;
    %q{
      Director is old: Person directs Company, Person is of Age, Age > 60;
    }.should parse_to_ast \
      %q{FactType: [{Director} "is old"] where {Person} "directs" {Company} ,
        {Person} "is of" {Age} ,
        compare>({Age} 60)}
  end

  it "should parse a comparison clause with subscripts" do
    %q{
      Director is old: Person directs Company, Person has Salary(2), Person is of Age(1), Age(1) > Salary(2);
    }.should parse_to_ast \
      %q{
        FactType: [{Director} "is old"]
        where {Person} "directs" {Company} ,
        {Person} "has" {Salary(2)} ,
        {Person} "is of" {Age(1)} ,
        compare>({Age(1)} {Salary(2)})
      }
  end

  it "should parse simple comparison clause having an unmarked adjective" do
    %q{
      Person is independent: Person has taxable- Income and taxable Income >= 20000 dollars or Person has sugar-Daddy;
    }.should parse_to_ast \
      %q{FactType: [{Person} "is independent"] where {Person} "has" {taxable- Income} and
        compare>=({taxable- Income} (20000 in dollars)) or {Person} "has" {sugar- Daddy}}
  end

  it "should parse a reading with a contracted comparison expression" do
    %q{
      Director is old: Person directs company, Person is of Age > 20+2*20;
    }.should parse_to_ast \
      %q{FactType: [{Director} "is old"] where {Person} "directs company" ,
        {Person} "is of" {Age}
        > compare>({Age} sum(20 product(2 20)))}
  end

  it "should parse a right-contracted comparison clause after a right-contracted clause" do
    %q{
      Director is old: Company is directed by Person who is of Age > 60;
    }.should parse_to_ast \
      %q{FactType: [{Director} "is old"] where {Company} "is directed by" {Person} who
        {Person} "is of" {Age} >
        compare>({Age} 60)}
  end

  it "should parse a simple reading with qualifiers" do
    %q{
      Person(1) is ancestor of Person(2): maybe Person(1) is parent of Person(2) [transitive];
    }.should parse_to_ast \
      %q{FactType: [{Person(1)} "is ancestor of" {Person(2)}] where
        ["maybe", "transitive"] {Person(1)} "is parent of" {Person(2)}}
  end

  it "should parse a contracted reading with qualifiers" do
    %q{
      Person(1) provides lineage of Person(2): maybe Person(2) is child of Person(1) [transitive] who is male;
    }.should parse_to_ast \
      %q{FactType: [{Person(1)} "provides lineage of" {Person(2)}] where
        ["maybe", "transitive"] {Person(2)} "is child of" {Person(1)} 
        who {Person(1)} "is male"}
  end

  it "should parse a contracted readings and comparisons with qualifiers" do
    %q{
      Person(1) is ancestor of adult Person(2):
        maybe Person(1) is parent of Person(2) [transitive]
          who maybe is of Age [static]
            definitely >= 21;
    }.should parse_to_ast \
      %q{FactType: [{Person(1)} "is ancestor of adult" {Person(2)}] where
        ["maybe", "transitive"] {Person(1)} "is parent of" {Person(2)}
        who ["maybe", "static"] {Person(2)} "is of" {Age}
        >= compare>=({Age} 21, [definitely])}
  end

  it "should parse a comparison expression with a contracted reading" do
    %q{
      Director is old: Person directs company, 3*30 >= Age that is of Person;
    }.should parse_to_ast \
      %q{FactType: [{Director} "is old"] where {Person} "directs company" ,
        compare>=(product(3 30) {Age})
        that {Age} "is of" {Person}}
  end

  it "should parse a comparison expression with a contracted comparison" do
    %q{
      Director is old: Person directs company, Person is of Age, maybe 20 <= Age definitely < 60;
    }.should parse_to_ast \
      %q{FactType: [{Director} "is old"] where {Person} "directs company" ,
        {Person} "is of" {Age} ,
        compare<=(20 {Age}, [maybe]) 
        < compare<({Age} 60, [definitely])}
  end

  it "should parse a comparison expression with right-contracted then left-contracted comparisons"
    # Director is probably adult: Person directs company, Person is of Age maybe >= 21 and definitely < 60;
  # end

  it "should fail to parse a contracted comparison that doesn't follow a role" do
    %q{
      Director is old: Person directs company, Person is of Age considerable > 3*20;
    }.should fail_to_parse /Expected (.|\n)* after (.|\n)* Age considerable $/
  end

  it "should parse pre and post-qualifiers and leading and trailing adjectives with contracted comparisons" do
    %q{
      A is a farce: maybe A has completely- B [transitive, acyclic] < 5, B -c = 2;
    }.should parse_to_ast \
      %q{FactType: [{A} "is a farce"] where ["acyclic", "maybe", "transitive"] {A} "has" {completely- B}
        < compare<({completely- B} 5)
        , compare=({B -c} 2)}
  end

  it "should parse multiple leading and trailing adjectives with contracted comparisons" do
    %q{
      A is a farce: maybe A has completely- green B [transitive, acyclic] < 9, B c -d = 2;
    }.should parse_to_ast \
      %q{FactType: [{A} "is a farce"] where ["acyclic", "maybe", "transitive"] {A} "has" {completely- green B} 
      < compare<({completely- green B} 9)
      , compare=({B c -d} 2)}
  end

  it "should parse a comparison clause containing units" do
    %q{
      254 mm converts to foot/feet;
      Width is written as Integer mm;
      Window requires toughening where
        Window has Width,
        Window has Height,
        Width * Height >= 10 feet^2;
    }.should parse_to_ast \
      %q{Unit(foot/feet) is 254/1+0 mm^1},
      %q{ValueType: Width is written as Integer in [["mm", 1]];},
      %q{FactType: [{Window} "requires toughening"] where {Window} "has" {Width} ,
        {Window} "has" {Height}
        , compare>=(product({Width} {Height}) (10 in feet^2))}
  end

  it "should parse nested expressions" do
    %q{
      A is written as B;
      A > B+3*(4+5)?
    }.should parse_to_ast \
      %q{ValueType: A is written as B;},
      %q{FactType: [] where compare>({A} sum({B} product(3 sum(4 5))))}
  end

  it "should parse a fact type containing an expression with subscripts"

  it "should parse a fact type containing objectification steps and contractions" do
    %q{
      Driving was negligent where
        Driving (where maybe Driver drove in Incident [acyclic] that definitely is of Claim [intransitive]) followed Intoxication [static];
    }.should parse_to_ast \
      %q{
        FactType: [{Driving} "was negligent"] where ["static"] {Driving}
        (where ["acyclic", "maybe"] {Driver} "drove in" {Incident}
          that ["definitely", "intransitive"] {Incident} "is of" {Claim})
        "followed" {Intoxication}
      }
  end

end
