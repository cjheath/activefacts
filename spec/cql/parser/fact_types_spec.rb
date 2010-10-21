#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'helpers/test_parser'

describe "Fact Types" do
  FactTypes = [
    [ "Foo has at most one Bar, Bar is of one Foo restricted to {1..10};",
      ["FactType: [{Foo} \"has\" {[..1] Bar}, {Bar} \"is of\" {[1..1] Foo ValueConstraint to ([1..10])}]"]
    ],
    [ "Bar(1) is related to Bar(2), primary-Bar(1) has secondary-Bar(2);",
      ["FactType: [{Bar(1)} \"is related to\" {Bar(2)}, {primary- Bar(1)} \"has\" {secondary- Bar(2)}]"]
    ],
    [ "Director is old: Person directs company, Person is of Age, Age > 60;",
      ["FactType: [{Director} \"is old\"] where {Person} \"directs company\", {Person} \"is of\" {Age}, ({Age}) > (60)"]
    ],
    [ "A is a farce: maybe A has completely- B [transitive, acyclic], B -c = 2;",
      ["FactType: [{A} \"is a farce\"] where [\"maybe\", \"transitive\", \"acyclic\"] {A} \"has\" {completely- B}, ({B -c}) = (2)"]
    ],
    [ "A is a farce: maybe A has completely- green B [transitive, acyclic], B -c = 2;",
      ["FactType: [{A} \"is a farce\"] where [\"maybe\", \"transitive\", \"acyclic\"] {A} \"has\" {completely- green B}, ({B -c}) = (2)"]
    ],
    [ "A is a farce: maybe A has B green -totally [transitive, acyclic], B -c = 2;",
      ["FactType: [{A} \"is a farce\"] where [\"maybe\", \"transitive\", \"acyclic\"] {A} \"has\" {B green -totally}, ({B -c}) = (2)"]
    ],
    [ "Person is independent: Person has taxable- Income, taxable Income >= 20000 dollars;",
      ["FactType: [{Person} \"is independent\"] where {Person} \"has\" {taxable- Income}, ({taxable- Income}) >= (20000 in dollars)"]
    ],
    [ "Window requires toughening: Window has Width -mm, Window has Height -mm, Width mm * Height mm >= 10 foot^2;",
      ["FactType: [{Window} \"requires toughening\"] where {Window} \"has\" {Width -mm}, {Window} \"has\" {Height -mm}, (({Width -mm}) + ({Height -mm})) >= (10 in foot^2)"]
    ],
    # REVISIT: Test all quantifiers
    # REVISIT: Test all post-qualifiers
    # REVISIT: Test functions
    [ "AnnualIncome is where Person has total- Income in Year: Person has total- Income.sum(), Income was earned in current- Time.Year() (as Year);",
      ["FactType: AnnualIncome [{Person} \"has\" {total- Income} \"in\" {Year}] where {Person} \"has\" {total- Income}, {Income} \"was earned in\" {current- Time (as Year)}"]
    ],
    [ "A is interesting : b- C has F -g;",
      ["FactType: [{A} \"is interesting\"] where {b- C} \"has\" {F -g}"]
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
