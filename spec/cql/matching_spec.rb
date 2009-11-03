#
# ActiveFacts CQL Fact Type matching tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
# require File.dirname(__FILE__) + '/../helpers/test_parser'

describe "Fact Type Role Matching" do
  Prefix = %q{
    vocabulary Tests;
    Boy is written as String;
    Girl is written as String;
  }
  BaseConcepts = 3  # String, Boy, Girl

  def self.SingleFact
    lambda {|c|
      c.FactType.size.should == 1
      @fact_type = c.FactType.values[0]
    }
  end

  def self.ReadingCount n
    lambda {|c|
      unless @fact_type.all_reading.size == n
        puts "SPEC FAILED, wrong number of readings (should be #{n}):\n\t#{
          @fact_type.all_reading.map{ |r| r.expand}*"\n\t"
        }"
      end
      @fact_type.all_reading.size.should == n
    }
  end

  def self.PresenceConstraintCount n
    lambda{ |c|
      @fact_type.all_role.map{|r|
        r.all_role_ref.map{|rr|
          rr.role_sequence.all_presence_constraint.to_a
        }
      }.flatten.uniq.size.should == n
    }
  end

  def self.ConceptCount n
    lambda {|c|
      c.Concept.values.size.should == n
    }
  end

  def self.Concept name
    lambda {|c|
      @concept = c.Concept[[["Tests"], name]]
      @concept.should_not == nil
    }
  end

  def self.WrittenAs name
    lambda {|c|
      @base_type = c.Concept[[["Tests"], name]]
      @base_type.class.should == ActiveFacts::Metamodel::ValueType
      @concept.class.should == ActiveFacts::Metamodel::ValueType
      @concept.supertype.should == @base_type
    }
  end

  def self.PreferredIdentifier num_roles
    lambda {|c|
      @preferred_identifier = @concept.preferred_identifier
      @preferred_identifier.should_not == nil
      @preferred_identifier.role_sequence.all_role_ref.size.should == num_roles
      #@preferred_identifier.min_frequency.should == 1
      @preferred_identifier.max_frequency.should == 1
      @preferred_identifier.is_preferred_identifier.should == true
    }
  end

  def self.PreferredIdentifierRolePlayedBy name, num = 0
    lambda {|c|
      @preferred_identifier.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}[num].role.concept.name.should == name
    }
  end

  def self.pending(msg = "TODO") # , &b
    lambda {|c|
      raise Spec::Example::ExamplePendingError.new(msg)
    }
  end

  def self.ReadingContainsHyphenatedWord reading_num
    lambda {|c|
      hyphenated_reading =
        c.FactType.values[0].all_reading.select {|reading|
          reading.ordinal == reading_num
        }[0]
      hyphenated_reading.should_not == nil
      (hyphenated_reading.text =~ /[a-z]-[a-z]/).should_not == nil
    }
  end

  SimpleBinaryFactTypeTests = [
    [ # Simple create
      %q{Girl is going out with at most one Boy; },
      SingleFact(),
        ReadingCount(1),
        PresenceConstraintCount(1)
    ],
    [ # Create with explicit adjective
      %q{Girl is going out with at most one ugly-Boy;},
      SingleFact(),
        ReadingCount(1),
        PresenceConstraintCount(1)
    ],
    [ # Simple match
      %q{Girl is going out with at most one Boy; },
      %q{
        Girl is going out with Boy,
          Boy is going out with Girl;
      },
      SingleFact(),
        ReadingCount(2),
        PresenceConstraintCount(1)
    ],
    [ # Simple match with repetition
      %q{Girl is going out with at most one Boy; },
      %q{
        Girl is going out with Boy,
          Girl is going out with Boy,
          Boy is going out with Girl,
          Boy is going out with Girl;
      },
      SingleFact(),
        PresenceConstraintCount(1),
        pending("duplicate new clauses are not eliminated"),
        ReadingCount(2),
    ],
    [ # Simple match with a new presence Constraint
      %q{Girl is going out with at most one Boy; },
      %q{
        Girl is going out with Boy,
          Boy is going out with at most one Girl;
      },
      SingleFact(),
        ReadingCount(2),
        PresenceConstraintCount(2)
    ],
    [ # RoleName matching
      %q{Girl is going out with at most one Boy;},
      %q{
        Boy is going out with Girlfriend,
          Girl (as Girlfriend) is going out with at most one Boy;
      },
      SingleFact(),
        ReadingCount(3),
        PresenceConstraintCount(1)
    ],
    [ # Match with explicit adjective
      %q{Girl is going out with at most one ugly-Boy;},
      %q{Girl is going out with at most one ugly-Boy,
        ugly-Boy is best friend of Girl;
      },
      SingleFact(),
        ReadingCount(2),
        PresenceConstraintCount(1)
    ],
    [ # Match with implicit adjective
      %q{Girl is going out with at most one ugly-Boy;},
      %q{Girl is going out with ugly Boy,
        Boy is going out with Girl;
      },
      SingleFact(),
        ReadingCount(2),
        PresenceConstraintCount(1)
    ],
    [ # Match with explicit trailing adjective
      %q{Girl is going out with at most one Boy-monster;},
      %q{Girl is going out with Boy-monster,
        Boy is going out with Girl;
      },
      SingleFact(),
        ReadingCount(2),
        PresenceConstraintCount(1)
    ],
    [ # Match with implicit trailing adjective
      %q{Girl is going out with at most one Boy-monster;},
      %q{Girl is going out with Boy monster,
        Boy is going out with Girl;
      },
      SingleFact(),
        ReadingCount(2),
        PresenceConstraintCount(1)
    ],
    [ # Match with two explicit adjectives
      %q{Girl is going out with at most one ugly- bad Boy;},
      %q{Girl is going out with ugly- bad Boy,
        ugly- bad Boy is going out with Girl;
      },
      SingleFact(),
        ReadingCount(2),
        PresenceConstraintCount(1)
    ],
    [ # Match with two implicit adjective
      %q{Girl is going out with at most one ugly- bad Boy;},
      %q{Girl is going out with ugly bad Boy,
        Boy is going out with Girl;
      },
      SingleFact(),
        ReadingCount(2),
        PresenceConstraintCount(1)
    ],
    [ # Match with two explicit trailing adjective
      %q{Girl is going out with at most one Boy real -monster;},
      %q{Girl is going out with Boy real -monster,
        Boy is going out with Girl;
      },
      SingleFact(),
        ReadingCount(2),
        PresenceConstraintCount(1)
    ],
    [ # Match with two implicit trailing adjectives
      %q{Girl is going out with at most one Boy real -monster;},
      %q{Girl is going out with Boy real monster,
        Boy is going out with Girl;
      },
      SingleFact(),
        ReadingCount(2),
        PresenceConstraintCount(1)
    ],
    [ # Match with hyphenated word
      %q{Girl is going out with at most one Boy; },
      %q{
        Girl is going out with Boy,
          Boy is out driving a semi-trailer with Girl;
      },
      SingleFact(),
        ReadingCount(2),
        ReadingContainsHyphenatedWord(1),
        PresenceConstraintCount(1)
    ],
    [ # Match with implicit leading ignoring explicit trailing adjective
      %q{Girl is going out with at most one ugly-Boy;},
      %q{Girl is going out with ugly Boy-monster,
        Boy is going out with Girl;
      },
      SingleFact(),
        ReadingCount(3),
        PresenceConstraintCount(1)
    ],
    [ # Match with implicit leading ignoring implicit trailing adjective
      %q{Girl is going out with at most one ugly-Boy;},
      %q{Girl is going out with ugly Boy monster,
        Boy-monster is going out with Girl;
      },
      SingleFact(),
        ReadingCount(3),
        PresenceConstraintCount(1)
    ],
    [ # Match with implicit trailing ignoring explicit leading adjective
      %q{Girl is going out with at most one Boy-monster;},
      %q{Girl is going out with ugly-Boy monster,
        Boy is going out with Girl;
      },
      SingleFact(),
        ReadingCount(3),
        PresenceConstraintCount(1)
    ],
    [ # Match with implicit trailing ignoring implicit leading adjective
      %q{Girl is going out with at most one Boy-monster;},
      %q{Girl is going out with ugly Boy monster,
        ugly-Boy is going out with Girl;
      },
      SingleFact(),
        ReadingCount(3),
        PresenceConstraintCount(1)
    ],
  ]

  EntityIdentificationTests = [
    [
      # REVISIT: At present, this doesn't add the minimum frequency constraint that a preferred identifier requires.
      %q{Thong is written as String;},
      %q{Thing is identified by Thong where Thing has one Thong;},
      Concept('Thong'),
        WrittenAs('String'),
      SingleFact(),
        ReadingCount(1),
      ConceptCount(2+BaseConcepts),
      Concept('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('Thong'),
    ],
    [
      %q{Thong is written as String;},
      %q{Thing is identified by Thong where Thing has one Thong, Thong is of one Thing;},
      SingleFact(),
        ReadingCount(2),
      ConceptCount(2+BaseConcepts),
      Concept('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('Thong'),
    ],
  ]
  AllTests =
    SimpleBinaryFactTypeTests +
    EntityIdentificationTests

  before :each do
    @compiler = ActiveFacts::CQL::Compiler.new(Prefix)
  end

  AllTests.each do |tests|
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
          rescue Spec::Example::ExamplePendingError
            raise
          rescue => e
            puts "Failed on\n\t"+tests.select{|t| t.is_a?(String)}*" "
            raise
          end
        end
      end
    end
  end
end
