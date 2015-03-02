#
# ActiveFacts CQL Fact Type matching tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'rspec/expectations'

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
# require File.dirname(__FILE__) + '/../helpers/compiler_helper'  # Can't see how to include/extend these methods correctly

describe "When compiling an entity type, " do
  MatchingPrefix = %q{
    vocabulary Tests;
    Boy is written as String;
    Girl is written as Integer;
  }
  BaseObjectTypes = 4  # Integer, String, Boy, Girl

  def self.SingleFact &b
    lambda {|c|
      real_fact_types = c.FactType.values-c.LinkFactType.values
      real_fact_types.size.should == 1
      @fact_type = real_fact_types[0]
      b.call(@fact_type) if b
      @fact_type
    }
  end

  def self.FactHavingPlayers(*a, &b)
    lambda {|c|
      @fact_type = c.FactType.detect do |key, ft|
        ft.all_role.map{|r| r.object_type.name}.sort == a.sort
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

  def self.ObjectTypeCount n
    lambda {|c|
      @constellation = c
      c.ObjectType.values.size.should == n
    }
  end

  def self.ObjectType name, &b
    lambda {|c|
      @object_type = c.ObjectType[[["Tests"], name]]
      @object_type.should_not == nil
      b.call(@object_type) if b
      @object_type
    }
  end

  def self.WrittenAs name
    lambda {|c|
      @base_type = c.ObjectType[[["Tests"], name]]
      @base_type.class.should == ActiveFacts::Metamodel::ValueType
      @object_type.class.should == ActiveFacts::Metamodel::ValueType
      @object_type.supertype.should == @base_type
    }
  end

  def self.PreferredIdentifier num_roles
    lambda {|c|
      @preferred_identifier = @object_type.preferred_identifier
      @preferred_identifier.should_not == nil
      @preferred_identifier.role_sequence.all_role_ref.size.should == num_roles
      #@preferred_identifier.min_frequency.should == 1
      @preferred_identifier.max_frequency.should == 1
      @preferred_identifier.is_preferred_identifier.should == true
    }
  end

  def self.PreferredIdentifierRolePlayedBy name, num = 0
    lambda {|c|
      @preferred_identifier.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}[num].role.object_type.name.should == name
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
      raise RSpec::Core::Pending::PendingExampleFixedError.new(msg) unless raised
      throw :pending_declared_in_example, msg
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

  EntityIdentificationTests = [
    [
      # REVISIT: At present, this doesn't add the minimum frequency constraint that a preferred identifier requires.
      %q{Thong is written as String;},
      %q{Thing is identified by Thong where Thing has one Thong;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 1
        PresenceConstraints(fact_type).size.should == 2
      end,
      ObjectType('Thong') do |object_type|
        object_type.class.should == ActiveFacts::Metamodel::ValueType
        # REVISIT: Figure out how WrittenAs can access the constellation.
        WrittenAs('String')
      end,
      ObjectTypeCount(2+BaseObjectTypes),
      ObjectType('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('Thong'),
    ],

    [ # Auto-create Id and Thing Id:
      %q{Thing is identified by its Id;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
      end,
      ObjectTypeCount(3+BaseObjectTypes),
      ObjectType('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('Thing Id'),
    ],

    [ # Auto-create Thing Id:
      %q{Id is written as String;},
      %q{Thing is identified by its Id;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
      end,
      ObjectTypeCount(3+BaseObjectTypes),
      ObjectType('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('Thing Id'),
    ],

    [ # Auto-create nothing (identifying value type exists already)
      %q{Thing Id is written as String;},
      %q{Thing is identified by its Id;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
      end,
      ObjectTypeCount(2+BaseObjectTypes),
      ObjectType('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('Thing Id'),
    ],

    [ # Auto-create nothing (identifying entity type exists already so don't create a VT)
      %q{Id is written as Id;},
      %q{Thing Id is identified by Id where Thing Id has one Id, Id is of one Thing Id;},
      %q{Thing is identified by its Id;},
      FactHavingPlayers("Thing", "Thing Id") do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
      end,
      ObjectTypeCount(3+BaseObjectTypes),
      ObjectType('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('Thing Id'),
    ],

    [
      %q{Thong is written as String;},
      %q{Thing is identified by Thong where Thing has one Thong, Thong is of one Thing;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
      end,
      ObjectTypeCount(2+BaseObjectTypes),
      ObjectType('Thing'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('Thong'),
    ],

    [   # Objectified fact type with internal identification
      %q{Relationship is where Boy relates to Girl;},
      SingleFact() do |fact_type|
        Readings(fact_type).size.should == 1
        PresenceConstraints(fact_type).size.should == 1
      end,
      ObjectTypeCount(1+BaseObjectTypes),
      ObjectType('Relationship'),
        PreferredIdentifier(2),
#          PreferredIdentifierRolePlayedBy('Thong'),
    ],

    [   # Objectified fact type with external identification
      %q{Relationship is identified by its Id where Boy relates to Girl;},
      ObjectTypeCount(3+BaseObjectTypes),
      ObjectType('Relationship'),
        PreferredIdentifier(1),   # 1 role in PI
          PreferredIdentifierRolePlayedBy('Relationship Id'),
      FactHavingPlayers('Relationship', 'Relationship Id') do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
        fact_type.all_reading.detect{|r| r.text == '{0} has {1}'}.should_not == nil
        fact_type.all_reading.detect{|r| r.text == '{0} is of {1}'}.should_not == nil
      end,
      FactHavingPlayers('Boy', 'Girl') do |fact_type|
        fact_type.entity_type.should == @object_type
      end,
    ],

    [   # Objectified fact type with external identification and explicit reading
      %q{Relationship is identified by its Id where Boy relates to Girl, Relationship is known by Relationship Id;},
      ObjectTypeCount(3+BaseObjectTypes),
      ObjectType('Relationship'),
        PreferredIdentifier(1),
          PreferredIdentifierRolePlayedBy('Relationship Id'),
      FactHavingPlayers('Relationship', 'Relationship Id') do |fact_type|
        Readings(fact_type).size.should == 2
        PresenceConstraints(fact_type).size.should == 2
        fact_type.all_reading.detect{|r| r.text == '{0} is known by {1}'}.should_not == nil
        fact_type.all_reading.detect{|r| r.text == '{0} is of {1}'}.should_not == nil
      end,
      FactHavingPlayers('Boy', 'Girl') do |fact_type|
        fact_type.entity_type.should == @object_type
      end,
    ],

  ]

  AllTests =
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
	  @compiler.vocabulary.finalise
        when Proc
          begin
            test.call(@compiler.vocabulary.constellation)
          rescue RSpec::Expectations::ExpectationNotMetError
            raise
          rescue RSpec::Core::Pending::PendingDeclaredInExample
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
