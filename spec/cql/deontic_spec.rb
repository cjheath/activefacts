#
# ActiveFacts CQL Deontic Constraints tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'

describe "Deontic Constraints" do
  DeonticPrefix = %q{
    vocabulary Test;
    Person is written as Person;
    Person is employed;
    Person is unemployed;
    Person has borrowed cash;
    Person is a bad credit risk;
    Nr is written as Nr;
    Person is good credit risk;
    Bar is written as Bar;
    Baz is written as Baz;
  }
  Cases = [
    # Constraints:
    [ 'each Person occurs one time (otherwise alert fraud dept) in Person is employed, Person is unemployed;',
      'alert', 'fraud dept'
    ],
    [ 'for each Person at most one of these holds ( otherwise email auditors ) : Person has borrowed cash, Person is a bad credit risk;',
      'email', 'auditors'
    ],
    [ 'either Person has borrowed cash or Person is a bad credit risk ( otherwise email auditors );',
      'email', 'auditors'
    ],
    [ 'either Person has borrowed cash or Person is a bad credit risk but not both ( otherwise email auditors );',
      'email', 'auditors'
    ],
    [ 'Person is good credit risk only if Person is employed (otherwise consider foreclosure);',
      'consider', 'foreclosure'
    ],
    [ 'Person is good credit risk if and only if Person is employed (otherwise log event);',
      'log', 'event'
    ],
    [ 'Foo is written as Nr restricted to {1..10} (otherwise log);',
      'log', ''
    ],
    [ 'Foo is identified by its Nr restricted to {1..10} (otherwise log);',
      'log', ''
    ],
    [ 'Baz has at most one (otherwise notify security) Bar, Bar is of one Baz restricted to {1..10};',
      'notify', 'security'
    ],
    [ 'Baz has at most one Bar, Bar is of one Baz restricted to {1..10} (otherwise log exception);',
      'log', 'exception'
    ],
  ]

  before :each do
    @compiler = ActiveFacts::CQL::Compiler.new('Test')
  end

  Cases.each do |c|
    source, action, agent = *c
    it "should parse #{source.inspect}" do
      result = @compiler.compile(DeonticPrefix+source)
      puts @compiler.failure_reason unless result
      result.should_not be_nil
      constellation = @compiler.vocabulary.constellation

      enforcements = 
        constellation.Constraint.values.map do |c|
          c.enforcement
        end.compact
      enforcements.size.should == 1
      enforcements[0].enforcement_code.should == action if action 
      if agent
        if agent != ''
          enforcements[0].agent.agent_name.should == agent
        else
          enforcements[0].agent.should be_nil
        end
      end

      #result.map{|d| d.value}.should == ast if ast
      # Uncomment this to see what should replace "nil" in the cases above:
      #puts result.map{|d| d.value}.inspect unless ast
    end
  end
end
