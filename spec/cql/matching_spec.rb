#
# ActiveFacts CQL Fact Type matching tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
# require File.dirname(__FILE__) + '/../helpers/test_parser'

describe "Fact Type Matching" do
  Prefix = %q{
    vocabulary Tests;
    Boy is written as String;
    Girl is written as String;
  }

  OneFactTwoReadings = 
    lambda {|c|
      c.FactType.size.should == 1
      c.FactType.values[0].all_reading.size.should == 2
    }

  OneFactThreeReadings = 
    lambda {|c|
      c.FactType.size.should == 1
      c.FactType.values[0].all_reading.size.should == 3
    }

  ReadingContainsHyphenatedWord =
    lambda {|c|
      hyphenated_readings =
        c.FactType.values[0].all_reading.select {|reading|
          reading.text =~ /[a-z]-[a-z]/
        }
      hyphenated_readings.size.should == 1
    }

  Tests = [
    [ # Simple match
      %q{Girl is going out with at most one Boy; },
      %q{
        Girl is going out with Boy,
          Boy is going out with Girl;
      },
      OneFactTwoReadings
    ],
    [ # Simple match with a new presence Constraint
      %q{Girl is going out with at most one Boy; },
      %q{
        Girl is going out with Boy,
          Boy is going out with at most one Girl;
      },
      OneFactTwoReadings,
=begin
      lambda{ |c|
        # pending
        fact_type = c.FactType.values[0]
        fact_type.all_role.map{|r|
          r.all_role_ref.map{|rr|
            rr.role_sequence.all_presence_constraint.to_a
          }
        }.flatten.uniq.size.should == 2
      }
=end
    ],
    [ # RoleName matching
      %q{Girl is going out with at most one Boy;},
      %q{
        Boy is going out with Girlfriend,
          Girl (as Girlfriend) is going out with at most one Boy;
      },
      OneFactThreeReadings
    ],
    [ # Match with explicit adjective
      %q{Girl is going out with at most one ugly-Boy;},
      %q{Girl is going out with ugly-Boy,
        ugly-Boy is going out with Girl;
      },
      OneFactTwoReadings,
    ],
    [ # Match with implicit adjective
      %q{Girl is going out with at most one ugly-Boy;},
      %q{Girl is going out with ugly Boy,
        Boy is going out with Girl;
      },
      OneFactTwoReadings,
    ],
    [ # Match with explicit trailing adjective
      %q{Girl is going out with at most one Boy-monster;},
      %q{Girl is going out with Boy-monster,
        Boy is going out with Girl;
      },
      OneFactTwoReadings,
    ],
    [ # Match with implicit trailing adjective
      %q{Girl is going out with at most one Boy-monster;},
      %q{Girl is going out with Boy monster,
        Boy is going out with Girl;
      },
      OneFactTwoReadings,
    ],
    [ # Match with two explicit adjectives
      %q{Girl is going out with at most one ugly- bad Boy;},
      %q{Girl is going out with ugly- bad Boy,
        ugly- bad Boy is going out with Girl;
      },
      OneFactTwoReadings,
    ],
    [ # Match with two implicit adjective
      %q{Girl is going out with at most one ugly- bad Boy;},
      %q{Girl is going out with ugly bad Boy,
        Boy is going out with Girl;
      },
      OneFactTwoReadings,
    ],
    [ # Match with two explicit trailing adjective
      %q{Girl is going out with at most one Boy real -monster;},
      %q{Girl is going out with Boy real -monster,
        Boy is going out with Girl;
      },
      OneFactTwoReadings,
    ],
    [ # Match with two implicit trailing adjectives
      %q{Girl is going out with at most one Boy real -monster;},
      %q{Girl is going out with Boy real monster,
        Boy is going out with Girl;
      },
      OneFactTwoReadings,
    ],
    [ # Match with hyphenated word
      %q{Girl is going out with at most one Boy; },
      %q{
        Girl is going out with Boy,
          Boy is out driving a semi-trailer with Girl;
      },
      OneFactTwoReadings,
      ReadingContainsHyphenatedWord
    ],
    [ # Match with implicit leading ignoring explicit trailing adjective
      %q{Girl is going out with at most one ugly-Boy;},
      %q{Girl is going out with ugly Boy-monster,
        Boy is going out with Girl;
      },
      OneFactThreeReadings,
    ],
    [ # Match with implicit leading ignoring implicit trailing adjective
      %q{Girl is going out with at most one ugly-Boy;},
      %q{Girl is going out with ugly Boy monster,
        Boy-monster is going out with Girl;
      },
      OneFactThreeReadings,
    ],
    [ # Match with implicit trailing ignoring explicit leading adjective
      %q{Girl is going out with at most one Boy-monster;},
      %q{Girl is going out with ugly-Boy monster,
        Boy is going out with Girl;
      },
      OneFactThreeReadings,
    ],
    [ # Match with implicit trailing ignoring implicit leading adjective
      %q{Girl is going out with at most one Boy-monster;},
      %q{Girl is going out with ugly Boy monster,
        ugly-Boy is going out with Girl;
      },
      OneFactThreeReadings,
    ],
  ]

  before :each do
    @compiler = ActiveFacts::CQL::Compiler.new(Prefix)
  end

  Tests.each do |tests|
    it "should process #{tests.select{|t| t.is_a?(String)}*' '} correctly" do
      tests.each do |test|
        case test
        when String
          result = @compiler.compile(test)
          puts @compiler.failure_reason unless result
          result.should_not be_nil
        when Proc
          begin
            test.call(@compiler.vocabulary.constellation)
          rescue => e
            puts "Failed on\n\t"+tests.select{|t| t.is_a?(String)}*" "
            raise
          end
        end
      end
    end
  end
end
