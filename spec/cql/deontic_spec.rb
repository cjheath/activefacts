#
# ActiveFacts CQL Deontic Constraints tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/parser'
require File.dirname(__FILE__) + '/../helpers/test_parser'

describe "Deontic Constraints" do
  DeonticPrefix = %q{
    Person is written as Person;
  }
  Cases = [
    # Constraints:
    [ 'each Person occurs one time (otherwise alert fraud dept) in Person is employed, Person is unemployed;',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :presence, [["Person"]], [1, 1], [[[{:word=>"Person", :term=>"Person"}, "is", "employed"]], [[{:word=>"Person", :term=>"Person"}, "is", "unemployed"]]], nil, ["alert", "fraud dept"]]]]
    ],
    [ 'for each Person at most one of these holds ( otherwise email auditors ) : Person has borrowed cash, Person is a bad credit risk;',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :set, [["Person"]], [nil, 1], [[[{:word=>"Person", :term=>"Person"}, "has", "borrowed", "cash"]], [[{:word=>"Person", :term=>"Person"}, "is", "a", "bad", "credit", "risk"]]], nil, ["email", "auditors"]]]]
    ],
    [ 'either Person has borrowed cash or Person is a bad credit risk ( otherwise email auditors );',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :set, nil, [1, nil], [[[{:word=>"Person", :term=>"Person"}, "has", "borrowed", "cash"]], [[{:word=>"Person", :term=>"Person"}, "is", "a", "bad", "credit", "risk"]]], nil, ["email", "auditors"]]]]
    ],
    [ 'either Person has borrowed cash or Person is a bad credit risk but not both ( otherwise email auditors );',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :set, nil, [1, 1], [[[{:word=>"Person", :term=>"Person"}, "has", "borrowed", "cash"]], [[{:word=>"Person", :term=>"Person"}, "is", "a", "bad", "credit", "risk"]]], nil, ["email", "auditors"]]]]
    ],
    [ 'Person is good credit risk only if Person is employed (otherwise consider foreclosure);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :subset, [[[{:word=>"Person", :term=>"Person"}, "is", "good", "credit", "risk"]], [[{:word=>"Person", :term=>"Person"}, "is", "employed"]]], nil, ["consider", "foreclosure"]]]]
    ],
    [ 'Person is good credit risk if and only if Person is employed (otherwise log event);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:constraint, :equality, [[[{:word=>"Person", :term=>"Person"}, "is", "good", "credit", "risk"]], [[{:word=>"Person", :term=>"Person"}, "is", "employed"]]], nil, ["log", "event"]]]]
    ],
    [ 'Foo is written as Nr restricted to {1..10} (otherwise log);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], ["Foo", [:value_type, "Nr", [], [], [[1, 10]], [], ["log", nil]]]]
    ],
    [ 'Foo is identified by its Nr restricted to {1..10} (otherwise log);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], ["Foo", [:entity_type, [], {:parameters=>[], :mode=>"Nr", :enforcement=>["log", nil], :restriction=>[[1, 10]]}, [], nil]]]
    ],
    [ 'Foo has at most one (otherwise notify security) Bar, Bar is of one Foo restricted to {1..10};',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:fact_type, [[:fact_clause, [], [{:word=>"Foo", :term=>"Foo"}, "has", {:quantifier_restriction=>["notify", "security"], :quantifier=>[nil, 1], :word=>"Bar", :term=>"Bar"}], nil], [:fact_clause, [], [{:word=>"Bar", :term=>"Bar"}, "is", "of", {:quantifier_restriction=>[], :quantifier=>[1, 1], :word=>"Foo", :restriction_enforcement=>[], :restriction=>[[1, 10]], :term=>"Foo"}], nil]], []]]]
    ],
    [ 'Foo has at most one Bar, Bar is of one Foo restricted to {1..10} (otherwise log exception);',
      [["Person", [:value_type, "Person", [], [], [], [], nil]], [nil, [:fact_type, [[:fact_clause, [], [{:word=>"Foo", :term=>"Foo"}, "has", {:word=>"Bar", :term=>"Bar", :quantifier_restriction=>[], :quantifier=>[nil, 1]}], nil], [:fact_clause, [], [{:word=>"Bar", :term=>"Bar"}, "is", "of", {:word=>"Foo", :term=>"Foo", :quantifier_restriction=>[], :quantifier=>[1, 1], :restriction_enforcement=>["log", "exception"], :restriction=>[[1, 10]]}], nil]], []]]]
    ],
  ]

  before :each do
    @parser = TestParser.new
  end

  Cases.each do |c|
    source, ast = *c
    it "should parse #{source.inspect}" do
      #debugger
      result = @parser.parse_all(DeonticPrefix+source, :definition)

      unless result
        debugger
        puts @parser.failure_reason
      end
      result.should_not be_nil
      result.map{|d| d.value}.should == ast if ast
      # Uncomment this to see what should replace "nil" in the cases above:
      puts result.map{|d| d.value}.inspect unless ast
    end
  end
end
