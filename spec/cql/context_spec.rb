#
# ActiveFacts CQL Business Context Note tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/parser'
require File.dirname(__FILE__) + '/../helpers/test_parser'

describe "Business Context Notes" do
  # (according_to people ',')? (because / as_opposed_to / so_that / to_avoid) discussion (',' as_agreed_by)? s
  Prefix = %q{
    Person is written as Person;
  }
  Notes = [
    # Constraints:
    [ 'each Person occurs one time in Person is employed, Person is unemployed (because it can be no other way!);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :presence, [["Person"]], [1, 1], [[[{:word=>"Person"}, {:word=>"is"}, {:word=>"employed"}]], [[{:word=>"Person"}, {:word=>"is"}, {:word=>"unemployed"}]]], [nil, "because", "it can be no other way!", []], []]]]
    ],
    [ 'each Person occurs one time in Person is employed, Person is unemployed (as opposed to blah!);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :presence, [["Person"]], [1, 1], [[[{:word=>"Person"}, {:word=>"is"}, {:word=>"employed"}]], [[{:word=>"Person"}, {:word=>"is"}, {:word=>"unemployed"}]]], [nil, "as_opposed_to", " blah!", []], []]]]
    ],
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (so that blah);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :set, [["Person"]], [1, nil], [[[{:word=>"Person"}, {:word=>"is"}, {:word=>"employed"}]], [[{:word=>"Person"}, {:word=>"is"}, {:word=>"a"}, {:word=>"bad"}, {:word=>"credit"}, {:word=>"risk"}]]], [nil, "so_that", " blah", []], []]]]
    ],
    [ 'Person is good credit risk only if Person is employed (to avoid lending to people who can\'t repay);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :subset, [[[{:word=>"Person"}, {:word=>"is"}, {:word=>"good"}, {:word=>"credit"}, {:word=>"risk"}]], [[{:word=>"Person"}, {:word=>"is"}, {:word=>"employed"}]]], [nil, "to_avoid", " lending to people who can't repay", []], []]]]
    ],
    [ 'Person is good credit risk if and only if Person is employed (to avoid lending to people who can\'t repay);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :equality, [[[{:word=>"Person"}, {:word=>"is"}, {:word=>"good"}, {:word=>"credit"}, {:word=>"risk"}]], [[{:word=>"Person"}, {:word=>"is"}, {:word=>"employed"}]]], [nil, "to_avoid", " lending to people who can't repay", []], []]]]
    ],
    # Entity and Fact types
    [ 'Foo is identified by Bar [independent] where Foo has one Bar (so that we have an id);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], ["Foo", [:entity_type, [], {:roles=>[["Bar"]]}, ["independent"], [[:fact_clause, [], [{:word=>"Foo"}, {:word=>"has"}, {:quantifier=>[1, 1], :quantifier_restriction=>[], :word=>"Bar"}], [nil, "so_that", " we have an id", []]]]]]]
    ],
    [ 'Foo has one Bar (so that we have an id), Bar is of one Foo (because we need that);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:fact_type, [[:fact_clause, [], [{:word=>"Foo"}, {:word=>"has"}, {:quantifier=>[1, 1], :quantifier_restriction=>[], :word=>"Bar"}], [nil, "so_that", " we have an id", []]], [:fact_clause, [], [{:word=>"Bar"}, {:word=>"is"}, {:word=>"of"}, {:quantifier=>[1, 1], :quantifier_restriction=>[], :word=>"Foo"}], [nil, "because", "we need that", []]]], []]]]
    ],
    # REVISIT: No context notes on quantifiers yet
    # As agreed by:
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (so that blah, as agreed by Jim);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :set, [["Person"]], [1, nil], [[[{:word=>"Person"}, {:word=>"is"}, {:word=>"employed"}]], [[{:word=>"Person"}, {:word=>"is"}, {:word=>"a"}, {:word=>"bad"}, {:word=>"credit"}, {:word=>"risk"}]]], [nil, "so_that", " blah", [nil, ["Jim"]]], []]]] 
    ],
    # REVISIT: Populate an "as agreed by" with a date
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (so that blah, as agreed on 29 March by Jim);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :set, [["Person"]], [1, nil], [[[{:word=>"Person"}, {:word=>"is"}, {:word=>"employed"}]], [[{:word=>"Person"}, {:word=>"is"}, {:word=>"a"}, {:word=>"bad"}, {:word=>"credit"}, {:word=>"risk"}]]], [nil, "so_that", " blah", ["29 March", ["Jim"]]], []]]]
    ],
    # According to:
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (according to jim, so that blah);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :set, [["Person"]], [1, nil], [[[{:word=>"Person"}, {:word=>"is"}, {:word=>"employed"}]], [[{:word=>"Person"}, {:word=>"is"}, {:word=>"a"}, {:word=>"bad"}, {:word=>"credit"}, {:word=>"risk"}]]], [["jim"], "so_that", " blah", []], []]]]
    ],
  ]

  before :each do
    @parser = TestParser.new
  end

  Notes.each do |c|
    source, ast = *c
    it "should parse #{source.inspect}" do
      #debugger
      result = @parser.parse_all(Prefix+source, :definition)

      puts @parser.failure_reason unless result
      result.should_not be_nil
      result.map{|d| d.value}.should == ast if ast
      # Uncomment this to see what should replace "nil" in the cases above:
      #puts result.map{|d| d.value}.inspect unless ast
    end
  end
end
