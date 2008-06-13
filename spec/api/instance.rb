#
# ActiveFacts tests: Value instances in the Runtime API
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require "ruby-debug"

describe "An instance of every type of Concept" do
  setup do
    Object.send :remove_const, :Mod if Object.const_defined?("Mod")
    module Mod
      # These are the bas value types we're going to test:
      @base_types = [
          Int, Real, AutoCounter, String, Date, DateTime
        ]

      # Construct the names of the roles they play:
      @base_type_roles = @base_types.map do |t|
        t.name.snakecase
      end
      @role_names = @base_type_roles.inject([]) {|a, t|
          a << :"#{t}_value"
        } +
        @base_type_roles.inject([]) {|a, t|
          a << :"#{t}_sub_value"
        }

      # Create a value type and a subtype of that value type for each base type:
      @base_types.each do |base_type|
        eval %Q{
          class #{base_type.name}Value < #{base_type.name}
            value_type
          end

          class #{base_type.name}SubValue < #{base_type.name}Value
            # Note no new "value_type" is required here, it comes through inheritance
          end
        }
      end

      # Create a TestByX, TestByXSub, and TestSubByX class for all base types X
      # Each class has a has_one and a one_to_one for all roles.
      # and is identified by the has_one :x role
      @base_types.each do |base_type|
        eval %Q{
          class TestBy#{base_type.name}
            identified_by :#{base_type.name.snakecase}_value#{
              @role_names.map do |role_name|
                %Q{
            has_one :#{role_name}
            one_to_one :one_#{role_name}, #{role_name.to_s.camelcase(true)}}
              end*""
            }
          end

          class TestBy#{base_type.name}Sub
            identified_by :#{base_type.name.snakecase}_sub_value#{
              @role_names.map do |role_name|
                %Q{
            has_one :#{role_name}
            one_to_one :one_#{role_name}, #{role_name.to_s.camelcase(true)}}
              end*""
            }
          end

          class TestSubBy#{base_type.name} < TestBy#{base_type.name}
            # Entity subtypes, inherit identification and all roles
          end
        }
      end
    end

    # Simple Values
    @int = 0
    @real = 0.0
    @auto_counter = 0
    @new_auto_counter = :new
    @string = "zero"
    @date = [2008, 04, 19]
    @date_time = [2008, 04, 19, 10, 28, 14]

    # Value Type instances
    @int_value = Mod::IntValue.new(1)
    @real_value = Mod::RealValue.new(1.0)
    @auto_counter_value = Mod::AutoCounterValue.new(1)
    @new_auto_counter_value = Mod::AutoCounterValue.new(:new)
    @string_value = Mod::StringValue.new("one")
    @date_value = Mod::DateValue.new(2008, 04, 20)
    @date_time_value = Mod::DateTimeValue.new(2008, 04, 20, 10, 28, 14)

    # Value SubType instances
    @int_sub_value = Mod::IntSubValue.new(4)
    @real_sub_value = Mod::RealSubValue.new(4.0)
    @auto_counter_sub_value = Mod::AutoCounterSubValue.new(4)
    @auto_counter_sub_value_new = Mod::AutoCounterSubValue.new(:new)
    @string_sub_value = Mod::StringSubValue.new("five")
    @date_sub_value = Mod::DateSubValue.new(2008, 04, 25)
    @date_time_sub_value = Mod::DateTimeSubValue.new(2008, 04, 26, 10, 28, 14)

    # Entities identified by Value Type and SubType instances
    @test_by_int = Mod::TestByInt.new(2)
    @test_by_real = Mod::TestByReal.new(2.0)
    @test_by_auto_counter = Mod::TestByAutoCounter.new(2)
    @test_by_auto_counter_new = Mod::TestByAutoCounter.new(:new)
    @test_by_string = Mod::TestByString.new("two")
    #@test_by_date = Mod::TestByDate.new(2008,04,28)
    @test_by_date = Mod::TestByDate.new(Date.new(2008,04,28))
    @test_by_date_time = Mod::TestByDateTime.new(2008,04,28,10,28,15)
    #@test_by_date_time = Mod::TestByDateTime.new(DateTime.new(2008,04,28,10,28,15))

    @test_by_int_sub = Mod::TestByIntSub.new(2)
    @test_by_real_sub = Mod::TestByRealSub.new(5.0)
    @test_by_auto_counter_sub = Mod::TestByAutoCounterSub.new(6)
    @test_by_auto_counter_new_sub = Mod::TestByAutoCounterSub.new(:new)
    @test_by_string_sub = Mod::TestByStringSub.new("six")
    @test_by_date_sub = Mod::TestByDateSub.new(Date.new(2008,04,27))
    @test_by_date_time_sub = Mod::TestByDateTimeSub.new(2008,04,29,10,28,15)

    # Entity subtypes
    @test_sub_by_int = Mod::TestSubByInt.new(2)
    @test_sub_by_real = Mod::TestSubByReal.new(2.0)
    @test_sub_by_auto_counter = Mod::TestSubByAutoCounter.new(2)
    @test_sub_by_auto_counter_new = Mod::TestSubByAutoCounter.new(:new)
    @test_sub_by_string = Mod::TestSubByString.new("two")
    @test_sub_by_date = Mod::TestSubByDate.new(Date.new(2008,04,28))
    @test_sub_by_date_time = Mod::TestSubByDateTime.new(2008,04,28,10,28,15)

    # These arrays get zipped together in various ways. Keep them aligned.
    @values = [
        @int, @real, @auto_counter, @new_auto_counter,
        @string, @date, @date_time,
      ]
    @classes = [
        Int, Real, AutoCounter, AutoCounter,
        String, Date, DateTime,
      ]
    @value_types = [
        Mod::IntValue, Mod::RealValue, Mod::AutoCounterValue, Mod::AutoCounterValue,
        Mod::StringValue, Mod::DateValue, Mod::DateTimeValue,
        Mod::IntSubValue, Mod::RealSubValue, Mod::AutoCounterSubValue, Mod::AutoCounterSubValue,
        Mod::StringSubValue, Mod::DateSubValue, Mod::DateTimeSubValue,
        ]
    @value_instances = [
        @int_value, @real_value, @auto_counter_value, @new_auto_counter_value,
        @string_value, @date_value, @date_time_value,
        @int_sub_value, @real_sub_value, @auto_counter_sub_value, @auto_counter_sub_value_new,
        @string_sub_value, @date_sub_value, @date_time_sub_value,
        @int_value, @real_value, @auto_counter_value, @new_auto_counter_value,
        @string_value, @date_value, @date_time_value,
      ]
    @entity_types = [
        Mod::TestByInt, Mod::TestByReal, Mod::TestByAutoCounter, Mod::TestByAutoCounter,
        Mod::TestByString, Mod::TestByDate, Mod::TestByDateTime,
        Mod::TestByIntSub, Mod::TestByRealSub, Mod::TestByAutoCounterSub, Mod::TestByAutoCounterSub,
        Mod::TestByStringSub, Mod::TestByDateSub, Mod::TestByDateTimeSub,
        Mod::TestSubByInt, Mod::TestSubByReal, Mod::TestSubByAutoCounter, Mod::TestSubByAutoCounter,
        Mod::TestSubByString, Mod::TestSubByDate, Mod::TestSubByDateTime,
      ]
    @entities = [
        @test_by_int, @test_by_real, @test_by_auto_counter, @test_by_auto_counter_new,
        @test_by_string, @test_by_date, @test_by_date_time,
        @test_by_int_sub, @test_by_real_sub, @test_by_auto_counter_sub, @test_by_auto_counter_new_sub,
        @test_by_string_sub, @test_by_date_sub, @test_by_date_time_sub,
        @test_sub_by_int, @test_sub_by_real, @test_sub_by_auto_counter, @test_sub_by_auto_counter_new,
        @test_sub_by_string, @test_sub_by_date, @test_sub_by_date_time,
      ]
    @roles = [
        :int_value, :real_value, :auto_counter_value, :auto_counter_value,
        :string_value, :date_value, :date_time_value,
        :int_sub_value, :real_sub_value, :auto_counter_sub_value, :auto_counter_sub_value,
        :string_sub_value, :date_sub_value, :date_time_sub_value
      ]
    @role_values = [
        3, 3.0, 6, 7,
        "three", Date.new(2008,4,21), DateTime.new(2008,4,22,10,28,16),
      ]
    @subtype_role_instances = [
        Mod::IntSubValue.new(6), Mod::RealSubValue.new(6.0),
        Mod::AutoCounterSubValue.new(:new), Mod::AutoCounterSubValue.new(8),
        Mod::StringSubValue.new("seven"),
        Mod::DateSubValue.new(2008,4,29), Mod::DateTimeSubValue.new(2008,4,30,10,28,16)
      ]
  end

  it "if a value type, should verbalise" do
    @value_types.each do |value_type|
      #puts "#{value_type} verbalises as #{value_type.verbalise}"
      value_type.respond_to?(:verbalise).should be_true
      verbalisation = value_type.verbalise
      verbalisation.should =~ %r{\b#{value_type.basename}\b}
      verbalisation.should =~ %r{\b#{value_type.superclass.basename}\b}
    end
  end

  it "if an entity type, should verbalise" do
    @entity_types.each do |entity_type|
      #puts entity_type.verbalise
      entity_type.respond_to?(:verbalise).should be_true
      verbalisation = entity_type.verbalise
      verbalisation.should =~ %r{\b#{entity_type.basename}\b}

      # All identifying roles should be in the verbalisation.
      # Strictly this should be the role name, but we don't set names here.
      entity_type.identifying_roles.each do |ir|
          role = entity_type.roles(ir)
          role.should_not be_nil
          player = role.player
          verbalisation.should =~ %r{\b#{player.basename}\b}
        end
    end
  end

  it "if a value, should verbalise" do
    @value_instances.each do |value|
      #puts value.verbalise
      value.respond_to?(:verbalise).should be_true
      verbalisation = value.verbalise
      verbalisation.should =~ %r{\b#{value.class.basename}\b}
    end
  end

  it "if an entity, should respond to verbalise" do
    @entities.each do |entity|
      #puts entity.verbalise
      entity.respond_to?(:verbalise).should be_true
      verbalisation = entity.verbalise
      verbalisation.should =~ %r{\b#{entity.class.basename}\b}
      entity.class.identifying_roles.each do |ir|
          role = entity.class.roles(ir)
          role.should_not be_nil
          player = role.player
          verbalisation.should =~ %r{\b#{player.basename}\b}
        end
    end
  end

  it "should respond to constellation" do
    (@value_instances+@entities).each do |instance|
      instance.respond_to?(:constellation).should be_true
    end
  end

  it "should respond to all its roles" do
    @entities.each do |entity|
      @roles.each do |role|
        entity.respond_to?(role).should be_true
        entity.respond_to?(:"#{role}=").should be_true
        entity.respond_to?(:"one_#{role}").should be_true
        entity.respond_to?(:"one_#{role}=").should be_true
      end
    end
  end

  it "should return the Concept in response to .class()" do
    @value_types.zip(@value_instances).each do |concept, instance|
      instance.class.should == concept
    end
    @entity_types.zip((@entities)).each do |concept, instance|
      instance.class.should == concept
    end
  end

  it "should return the module in response to .vocabulary()" do
    (@value_types+@entity_types).zip((@value_instances+@entities)).each do |concept, instance|
      instance.class.vocabulary.should == Mod
    end
  end

  it "each entity type should be able to be constructed using simple values" do
    @entity_types.zip(@values+@values+@values, @classes+@classes+@classes).each do |entity_type, value, klass|
      # An identifier parameter can be an array containing a simple value too
      [ value,
        Array === value ? nil : [value],
#        entity_type.new(value) # REVISIT: It's not yet the case that an instance of the correct type can be used as a constructor parameter
      ].compact.each do |value|
        e = nil
        lambda {
            #puts "Constructing #{entity_type} using #{value.class} #{value.inspect}:"
            e = entity_type.new(value)
          }.should_not raise_error
        # Verify that the identifying role has a equivalent value (except AutoCounter):
        role_name = entity_type.identifying_roles[0]
        role = entity_type.roles(role_name)
        player = role.player
        player_superclasses = [ player.superclass, player.superclass.superclass ]
        e.send(role_name).should == klass.new(*value) unless player_superclasses.include?(AutoCounter)
      end
    end
  end

  it "that are entities should not allow its identifying roles to be assigned" do
    pending
    @entities.zip(@roles, @role_values).each do |entity, role, value|
      lambda {
          entity.send(:"#{role}=", value)
        }.should raise_error
    end
  end

  it "should allow its non-identifying roles to be assigned values" do
    @entities.zip(@roles).each do |entity, identifying_role|
      @roles.zip(@role_values).each do |role, value|
        next if role == identifying_role
        lambda {
            entity.send(:"#{role}=", value)
          }.should_not raise_error
        lambda {
            entity.send(:"one_#{role}=", value)
          }.should_not raise_error
      end
    end
  end

  it "should allow its non-identifying roles to be assigned instances" do
    @entities.zip(@roles).each do |entity, identifying_role|
      @roles.zip(@value_types, @role_values).each do |role, klass, value|
        next unless value
        next if role == identifying_role
        instance = klass.new(value)
        lambda {
            entity.send(:"#{role}=", instance)
          }.should_not raise_error
        entity.send(role).class.should == klass
        lambda {
            entity.send(:"one_#{role}=", instance)
          }.should_not raise_error
        entity.send(:"one_#{role}").class.should == klass
      end
    end
  end

  it "should allow its non-identifying roles to be assigned instances of value subtypes, retaining the subtype" do
    @entities.zip(@roles).each do |entity, identifying_role|
      @roles.zip(@subtype_role_instances).each do |role, instance|
        next unless instance
        next if role == identifying_role
        lambda {
            entity.send(:"#{role}=", instance)
          }.should_not raise_error
        entity.send(role).class.should == instance.class
        lambda {
            entity.send(:"one_#{role}=", instance)
          }.should_not raise_error
        entity.send(:"one_#{role}").class.should == instance.class
      end
    end
  end

  it "should allow its non-identifying roles to be assigned nil" do
    @entities.zip(@roles).each do |entity, identifying_role|
      @roles.zip(@role_values).each do |role, value|
        next if role == identifying_role
        entity.send(:"#{role}=", value)
        lambda {
            entity.send(:"#{role}=", nil)
          }.should_not raise_error
        lambda {
            entity.send(:"one_#{role}=", nil)
          }.should_not raise_error
      end
    end
  end

end
