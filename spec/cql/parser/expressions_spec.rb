#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'helpers/test_parser'

describe "Expression Derived Fact Types" do
  XDFactTypes = [
    [ "Director is old: Person directs Company, Person is of Age, Age > 60;",
      [%q{FactType: [{Director} "is old"] where {Person} "directs" {Company}, {Person} "is of" {Age}, (> {Age} 60)}]
    ],
    [ "Director is old: Person directs company, Person is of Age > 3*20;",
      [%q{FactType: [{Director} "is old"] where {Person} "directs company", {Person} "is of" {Age}, (> {Age} (* 3 20))}]
    ],
#    Illegal contracted comparison: operator doesn't follow a role
#    [ "Director is old: Person directs company, Person is of Age considerable > 3*20;",
#    ],
    [ "A is a farce: maybe A has completely- B [transitive, acyclic], B -c = 2;",
      [%q{FactType: [{A} "is a farce"] where ["maybe", "transitive", "acyclic"] {A} "has" {completely- B}, (= {B -c} 2)}]
    ],
    [ "A is a farce: maybe A has completely- green B [transitive, acyclic], B -c = 2;",
      [%q{FactType: [{A} "is a farce"] where ["maybe", "transitive", "acyclic"] {A} "has" {completely- green B}, (= {B -c} 2)}]
    ],
    [ "A is a farce: maybe A has B green -totally [transitive, acyclic], B -c = 2;",
      [%q{FactType: [{A} "is a farce"] where ["maybe", "transitive", "acyclic"] {A} "has" {B green -totally}, (= {B -c} 2)}]
    ],
    [ "Person is independent: Person has taxable- Income, taxable Income >= 20000 dollars;",
      [%q{FactType: [{Person} "is independent"] where {Person} "has" {taxable- Income}, (>= {taxable- Income} (20000 in dollars))}]
    ],
    [ "Window requires toughening: Window has Width -mm, Window has Height -mm, Width mm * Height mm >= 10 foot^2;",
      [%q{FactType: [{Window} "requires toughening"] where {Window} "has" {Width -mm}, {Window} "has" {Height -mm}, (>= (* {Width -mm} {Height -mm}) (10 in foot^2))}]
    ],
    # REVISIT: Test all quantifiers
    # REVISIT: Test all post-qualifiers
    # REVISIT: Test functions
    [ "AnnualIncome is where Person has total- Income in Year: Person has total- Income.sum(), Income was earned in current- Time.Year() (as Year);",
      [%q{FactType: AnnualIncome [{Person} "has" {total- Income} "in" {Year}] where {Person} "has" {total- Income}, {Income} "was earned in" {current- Time (as Year)}}]
    ]
  ]

  before :each do
    @parser = TestParser.new
  end

  XDFactTypes.each do |c|
    source, expected_ast, definition = *c
    it "should parse #{source.inspect}" do
      result = @parser.parse_all(source, :definition)

      pending '"'+@parser.failure_reason+'"' unless result

      #result = [result[-1]]
      canonical_form = result.map{|d| d.ast.to_s}
      if expected_ast
        canonical_form.should == expected_ast
      else
        pending "Should compile to #{canonical_form}"
      end
    end
  end
end
