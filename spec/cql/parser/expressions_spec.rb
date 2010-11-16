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
    %q{
      Director is old: Person directs Company, Person is of Age, Age > 60;
    }.should parse_to_ast \
      %q{FactType: [{Director} "is old"] where {Person} "directs" {Company},
        {Person} "is of" {Age},
        (> {Age} 60)}
  end

  it "should parse simple comparison clause having an unmarked adjective" do
    %q{
      Person is independent: Person has taxable- Income, taxable Income >= 20000 dollars;
    }.should parse_to_ast \
      %q{FactType: [{Person} "is independent"] where {Person} "has" {taxable- Income},
        (>= {taxable- Income} (20000 in dollars))}
  end

  it "should parse a reading with a contracted comparison expression" do
    %q{
      Director is old: Person directs company, Person is of Age > 20+2*20;
    }.should parse_to_ast \
      %q{FactType: [{Director} "is old"] where {Person} "directs company",
        {Person} "is of" {Age},
        (> {Age} (+ 20 (* 2 20)))}
  end

  it "should parse a comparison expression with a contracted reading" do
    %q{
      Director is old: Person directs company, 3*30 >= Age that is of Person;
    }.should parse_to_ast \
      %q{FactType: [{Director} "is old"] where {Person} "directs company",
        (>= (* 3 30) {Age}), {Age} "is of" {Person}}
  end

  it "should fail to parse a contracted comparison that doesn't follow a role" do
    %q{
      Director is old: Person directs company, Person is of Age considerable > 3*20;
    }.should fail_to_parse /Expected (.|\n)* after (.|\n)* Age considerable $/
  end

  it "should parse pre and post-qualifiers and leading and trailing adjectives with contracted comparisons" do
    %q{
      A is a farce: maybe A has completely- B [transitive, acyclic] < 5, B -c = 2;
    }.should parse_to_ast %q{FactType: [{A} "is a farce"] where ["acyclic", "maybe", "transitive"] {A} "has" {completely- B}, (< {completely- B} 5), (= {B -c} 2)}
  end

  it "should parse multiple leading and trailing adjectives with contracted comparisons" do
    %q{
      A is a farce: maybe A has completely- green B [transitive, acyclic] < 9, B c -d = 2;
    }.should parse_to_ast \
      %q{FactType: [{A} "is a farce"] where ["acyclic", "maybe", "transitive"] {A} "has" {completely- green B},
      (< {completely- green B} 9), (= {B c -d} 2)}
  end

  it "should parse a comparison clause containing units" do
    %q{foot converts to 254 mm;
      Width is written as Integer mm;
      Window requires toughening: Window has Width, Window has Height, Width * Height >= 10 foot^2;
    }.should parse_to_ast \
      %q{Unit(foot) is 254/1+0 mm^1},
      %q{ValueType: Width is written as Integer in [["mm", 1]];},
      %q{FactType: [{Window} "requires toughening"] where {Window} "has" {Width},
        {Window} "has" {Height}, (>= (* {Width} {Height}) (10 in foot^2))}
  end

  it "should parse a fact type containing a function call" do
    %q{
      AnnualIncome is where Person has total- Income in Year: Person has total- Income.sum(),
      Income was earned in current- Time.Year() (as Year);
    }.should parse_to_ast \
      %q{FactType: AnnualIncome [{Person} "has" {total- Income} "in" {Year}] where {Person} "has" {total- Income},
        {Income} "was earned in" {current- Time (as Year)}}
  end

  # REVISIT: Test all quantifiers
  # REVISIT: Test all post-qualifiers

end
