#
# ActiveFacts CQL Fact Type matching tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
# require File.dirname(__FILE__) + '/../helpers/compiler_helper'  # Can't see how to include/extend these methods correctly

describe "Fact Type Role Matching" do
  MatchingPrefix = %q{
    vocabulary Tests;
    Boy is written as String;
    Girl is written as String;
  }
  BaseConcepts = 3  # String, Boy, Girl

  def self.SingleFact &b
    lambda {|c|
      c.FactType.size.should == 1
      @fact_type = c.FactType.values[0]
      b.call(@fact_type) if b
      @fact_type
    }
  end

  def self.FactHavingPlayers(*a, &b)
    lambda {|c|
      @fact_type = c.FactType.detect do |key, ft|
        ft.all_role.map{|r| r.concept.name}.sort == a.sort
      end
      b.call(@fact_type) if b
      @fact_type
    }
  end

  def self.PresenceConstraints fact_type, &b
    @presence_constraints =
      fact_type.all_role.map{|r|
        r.all_role_ref.map{|rr|
          rr.role_sequence.all_presence_constraint.to_a
        }
      }.flatten.uniq
    b.call(@presence_constraints) if b
    @presence_constraints
  end

  def self.Readings fact_type, &b
    @readings = fact_type.all_reading.sort_by{|r| r.ordinal}
    b.call(@readings) if b
    @readings
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
      @constellation = c
      c.Concept.values.size.should == n
    }
  end

  def self.Concept name, &b
    lambda {|c|
      @concept = c.Concept[[["Tests"], name]]
      @concept.should_not == nil
      b.call(@concept) if b
      @concept
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

  class BlackHole
    def method_missing(m,*a,&b)
      self
    end
  end
  class PendingSilencer
    def STDOUT; BlackHole.new; end
    def puts; BlackHole.new; end
    def p; BlackHole.new; end
  end

  def self.pending(msg = "TODO", &b)
    lambda {|*c|
      raised = nil
      begin
        example = b.call
        eval(lambda { example.call(*c) }, BlackHole.new)
      rescue => raised
      end
      raise Spec::Example::PendingExampleFixedError.new(msg) unless raised
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
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 1
        PresenceConstraints(fact_type) do |pcs|
          pcs.size.should == 1
        end
      end
    ],
    [ # Create with explicit adjective
      %q{Girl is going out with at most one ugly-Boy;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 1
        PresenceConstraints(fact_type).size.should == 1
      end
    ],
    [ # Simple match
      %q{Girl is going out with at most one Boy; },
      %q{
        Girl is going out with Boy,
          Boy is going out with Girl;
      },
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 1
      end
    ],
    [ # Simple match with repetition
      %q{Girl is going out with at most one Boy; },
      %q{
        Girl is going out with Boy,
          Girl is going out with Boy,
          Boy is going out with Girl,
          Boy is going out with Girl;
      },
      SingleFact() do |fact_type|
        PresenceConstraints(fact_type).size.should == 1
        pending("duplicate new clauses are not eliminated") do
          Readings(fact_type).size.should == 2
        end.call      # Must call the pending block
      end,
#      pending("duplicate new clauses are not eliminated") do
#        @readings.size.should == 2
#      end
    ],
    [ # Simple match with a new presence Constraint
      %q{Girl is going out with at most one Boy; },
      %q{
        Girl is going out with Boy,
          Boy is going out with at most one Girl;
      },
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
      end
    ],
    [ # RoleName matching
      %q{Girl is going out with at most one Boy;},
      %q{
        Boy is going out with Girlfriend,
          Girl (as Girlfriend) is going out with at most one Boy;
      },
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 3
        PresenceConstraints(fact_type).size.should == 1
      end
    ],
    [ # Match with explicit adjective
      %q{Girl is going out with at most one ugly-Boy;},
      %q{Girl is going out with at most one ugly-Boy,
        ugly-Boy is best friend of Girl;
      },
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 1
      end
    ],
    [ # Match with implicit adjective
      %q{Girl is going out with at most one ugly-Boy;},
      %q{Girl is going out with ugly Boy,
        Boy is going out with Girl;
      },
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 1
      end
    ],
    [ # Match with explicit trailing adjective
      %q{Girl is going out with at most one Boy-monster;},
      %q{Girl is going out with Boy-monster,
        Boy is going out with Girl;
      },
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 1
      end
    ],
    [ # Match with implicit trailing adjective
      %q{Girl is going out with at most one Boy-monster;},
      %q{Girl is going out with Boy monster,
        Boy is going out with Girl;
      },
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 1
      end
    ],
    [ # Match with two explicit adjectives
      %q{Girl is going out with at most one ugly- bad Boy;},
      %q{Girl is going out with ugly- bad Boy,
        ugly- bad Boy is going out with Girl;
      },
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 1
      end
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
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 1
      end
    ],
    [ # Match with two implicit trailing adjectives
      %q{Girl is going out with at most one Boy real -monster;},
      %q{Girl is going out with Boy real monster,
        Boy is going out with Girl;
      },
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 1
      end
    ],
    [ # Match with hyphenated word
      %q{Girl is going out with at most one Boy; },
      %q{
        Girl is going out with Boy,
          Boy is out driving a semi-trailer with Girl;
      },
      SingleFact() do |fact_type|
        (readings = Readings(fact_type)).size.should == 2
        ## REVISIT: Refactor test
        #ReadingContainsHyphenatedWord(readings[1])
        ReadingContainsHyphenatedWord(1)
        PresenceConstraintCount(1)
      end
    ],
    [ # Match with implicit leading ignoring explicit trailing adjective
      %q{Girl is going out with at most one ugly-Boy;},
      %q{Girl is going out with ugly Boy-monster,
        Boy is going out with Girl;
      },
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 3
        PresenceConstraints(fact_type).size.should == 1
      end
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
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 3
        PresenceConstraints(fact_type).size.should == 1
      end
    ],
    [ # Match with implicit trailing ignoring implicit leading adjective
      %q{Girl is going out with at most one Boy-monster;},
      %q{Girl is going out with ugly Boy monster,
        ugly-Boy is going out with Girl;
      },
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 3
        PresenceConstraints(fact_type).size.should == 1
      end
    ],
  ]

  EntityIdentificationTests = [
    [
      # REVISIT: At present, this doesn't add the minimum frequency constraint that a preferred identifier requires.
      %q{Thong is written as String;},
      %q{Thing is identified by Thong where Thing has one Thong;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 1
        PresenceConstraints(fact_type).size.should == 2
      end,
      Concept('Thong') do |concept|
        concept.class.should == ActiveFacts::Metamodel::ValueType
        # REVISIT: Figure out how WrittenAs can access the constellation.
        WrittenAs('String')
      end,
      ConceptCount(2+BaseConcepts),
      Concept('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('Thong'),
    ],

    [ # Auto-create Id and ThingId:
      %q{Thing is identified by its Id;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
      end,
      ConceptCount(3+BaseConcepts),
      Concept('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('ThingId'),
    ],

    [ # Auto-create ThingId:
      %q{Id is written as String;},
      %q{Thing is identified by its Id;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
      end,
      ConceptCount(3+BaseConcepts),
      Concept('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('ThingId'),
    ],

    [ # Auto-create nothing (identifying value type exists already)
      %q{ThingId is written as String;},
      %q{Thing is identified by its Id;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
      end,
      ConceptCount(2+BaseConcepts),
      Concept('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('ThingId'),
    ],

    [ # Auto-create nothing (identifying entity type exists already so don't create a VT)
      %q{ThingId is identified by Id where ThingId has one Id, Id is of one ThingId;},
      %q{Thing is identified by its Id;},
      FactHavingPlayers("Thing", "ThingId") do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
      end,
      ConceptCount(3+BaseConcepts),
      Concept('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('ThingId'),
    ],

    [
      %q{Thong is written as String;},
      %q{Thing is identified by Thong where Thing has one Thong, Thong is of one Thing;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
      end,
      ConceptCount(2+BaseConcepts),
      Concept('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('Thong'),
    ],

    [   # Objectified fact type with internal identification
      %q{Relationship is where Boy relates to Girl;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 1
        PresenceConstraints(fact_type).size.should == 1
      end,
      ConceptCount(1+BaseConcepts),
      Concept('Relationship'),
        PreferredIdentifier(2),
#          PreferredIdentifierRolePlayedBy('Thong'),
    ],

    [   # Objectified fact type with external identification
      %q{Relationship is identified by its Id where Boy relates to Girl;},
      ConceptCount(3+BaseConcepts),
      Concept('Relationship'),
        PreferredIdentifier(1),   # 1 role in PI
          PreferredIdentifierRolePlayedBy('RelationshipId'),
      FactHavingPlayers('Relationship', 'RelationshipId') do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
        fact_type.all_reading.detect{|r| r.text == '{0} has {1}'}.should_not == nil
        fact_type.all_reading.detect{|r| r.text == '{0} is of {1}'}.should_not == nil
      end,
      FactHavingPlayers('Boy', 'Girl') do |fact_type|
        fact_type.entity_type.should == @concept
      end,
    ],

    [   # Objectified fact type with external identification and explicit reading
      %q{Relationship is identified by its Id where Boy relates to Girl, Relationship is known by RelationshipId;},
      ConceptCount(3+BaseConcepts),
      Concept('Relationship'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('RelationshipId'),
      FactHavingPlayers('Relationship', 'RelationshipId') do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
        fact_type.all_reading.detect{|r| r.text == '{0} is known by {1}'}.should_not == nil
        fact_type.all_reading.detect{|r| r.text == '{0} is of {1}'}.should_not == nil
      end,
      FactHavingPlayers('Boy', 'Girl') do |fact_type|
        fact_type.entity_type.should == @concept
      end,
    ],

  ]
  AllTests =
#    SimpleBinaryFactTypeTests +
    EntityIdentificationTests

  before :each do
    @compiler = ActiveFacts::CQL::Compiler.new('Test')
  end

  AllTests.each do |tests|
    it "should process '#{(tests.select{|t| t.is_a?(String)}*' ').gsub(/\s+/m,' ')}' correctly" do
      tests.each do |test|
        case test
        when String
          result = @compiler.compile(MatchingPrefix+test)
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
