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
      nil
    ],
    [ 'for each Person at most one of these holds ( otherwise email auditors ) : Person has borrowed cash, Person is a bad credit risk;',
      nil
    ],
    [ 'either Person has borrowed cash or Person is a bad credit risk ( otherwise email auditors );',
      nil
    ],
    [ 'either Person has borrowed cash or Person is a bad credit risk but not both ( otherwise email auditors );',
      nil
    ],
    [ 'Person is good credit risk only if Person is employed (otherwise consider foreclosure);',
      nil
    ],
    [ 'Person is good credit risk if and only if Person is employed (otherwise log event);',
      nil
    ],
    [ 'Foo is written as Nr restricted to {1..10} (otherwise log);',
      nil
    ],
    [ 'Foo is identified by its Nr restricted to {1..10} (otherwise log);',
      nil
    ],
    [ 'Foo has at most one (otherwise notify security) Bar, Bar is of one Foo restricted to {1..10};',
      nil
    ],
    [ 'Foo has at most one Bar, Bar is of one Foo restricted to {1..10} (otherwise log exception);',
      nil
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
      #puts result.map{|d| d.value}.inspect unless ast
    end
  end
end
