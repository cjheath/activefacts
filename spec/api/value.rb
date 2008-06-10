#
# ActiveFacts tests: Value instances in the Runtime API
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
describe "Value Type instances" do
  setup do
    Object.send :remove_const, :Mod if Object.const_defined?("Mod")
    module Mod
      class IntValue < Int
        value_type
      end
      class RealValue < Real
        value_type
      end
      class DateValue < Date
        value_type
      end
      class AutoCounterValue < AutoCounter
        value_type
      end
      class StringValue < String
        value_type
        has_one :int_value
      end

      class TestByInt
        identified_by :int_value
        has_one :int_value
        has_one :real_value
        has_one :date_value
        has_one :auto_counter_value
        has_one :string_value
      end

      class TestByReal
        identified_by :real_value
        has_one :int_value
        has_one :real_value
        has_one :date_value
        has_one :auto_counter_value
        has_one :string_value
      end

      class TestByDate
        identified_by :date_value
        has_one :int_value
        has_one :real_value
        has_one :date_value
        has_one :auto_counter_value
        has_one :string_value
      end

      class TestByAutoCounter
        identified_by :auto_counter_value
        has_one :int_value
        has_one :real_value
        has_one :date_value
        has_one :auto_counter_value
        has_one :string_value
      end

      class TestByString
        identified_by :string_value
        has_one :int_value
        has_one :real_value
        has_one :date_value
        has_one :auto_counter_value
        has_one :string_value
      end
    end

    @int_value = Mod::IntValue.new(1)
    @real_value = Mod::RealValue.new(1.0)
    @date_value = Mod::DateValue.new(2008, 04, 20)

    @auto_counter_value = Mod::AutoCounterValue.new(1)
    @auto_counter_value_new = Mod::AutoCounterValue.new(:new)
    @string_value = Mod::StringValue.new("one")
    @test_by_int = Mod::TestByInt.new(2)
    @test_by_real = Mod::TestByReal.new(2.0)
    #@test_by_date = Mod::TestByDate.new(2008,04,28)
    @test_by_date = Mod::TestByDate.new(Date.new(2008,04,28))
    @test_by_auto_counter = Mod::TestByAutoCounter.new(2)
    @test_by_auto_counter_new = Mod::TestByAutoCounter.new(:new)
    @test_by_string = Mod::TestByString.new("two")

    # These arrays get zipped together in various ways. Keep them aligned.
    @value_types = [ Mod::IntValue, Mod::RealValue, Mod::AutoCounterValue, Mod::AutoCounterValue, Mod::StringValue, Mod::DateValue ]
    @values = [ @int_value, @real_value, @auto_counter_value, @auto_counter_value_new, @string_value, @date_value ]
    @entity_types = [ Mod::TestByInt, Mod::TestByReal, Mod::TestByAutoCounter, Mod::TestByString, Mod::TestByDate ]
    @entities = [ @test_by_int, @test_by_real, @test_by_auto_counter, @test_by_string, @test_by_date, @test_by_auto_counter_new ]
    @roles = [ :int_value, :real_value, :date_value, :auto_counter_value, :string_value ]
    @role_values = [ 3, 3.0, Date.new(2008, 4, 21), :new, "three" ]
  end

  it "All value types should respond to verbalise" do
    @value_types.each do |value_type|
      #puts value_type.verbalise
      value_type.respond_to?(:verbalise).should be_true
    end
  end

  it "All entity types identified by a value role should respond to verbalise" do
    @entity_types.each do |entity_type|
      #puts entity_type.verbalise
      entity_type.respond_to?(:verbalise).should be_true
    end
  end

  it "All types of values should respond to verbalise" do
    @values.each do |value|
      #puts value.verbalise
      value.respond_to?(:verbalise).should be_true
    end
  end

  it "Entity types identified by all types of value role should respond to verbalise" do
    @entities.each do |entity|
      #puts entity.verbalise
      entity.respond_to?(:verbalise).should be_true
    end
  end

  it "should verbalise correctly" do
    @string_value.verbalise.should == "StringValue 'one'"
  end

  it "All types of value and entity should respond to constellation" do
    (@values+@entities).each do |instance|
      instance.respond_to?(:constellation).should be_true
    end
  end

  it "Each entity should respond to its roles" do
    @entities.each do |entity|
      @roles.each do |role|
        entity.respond_to?(role).should be_true
        entity.respond_to?(:"#{role}=").should be_true
      end
    end
  end

  it "should allow its non-identifying roles to be assigned" do
    @entities.zip(@roles).each do |entity, identifying_role|
      @roles.zip(@role_values).each do |role, value|
        next if role == identifying_role
        lambda {
            entity.send(:"#{role}=", value)
          }.should_not raise_error
      end
    end
  end

  it "should not allow its identifying roles to be assigned" do
    pending
    @entities.zip(@roles, @role_values).each do |entity, role, value|
      lambda {
          entity.send(:"#{role}=", value)
        }.should raise_error
    end
  end

  it "should return the Concept in response to .class()" do
      (@value_types+@entity_types).zip((@values+@entities)).each do |concept, instance|
        instance.class.should == concept
      end
  end

  it "should return the module in response to .vocabulary()" do
      (@value_types+@entity_types).zip((@values+@entities)).each do |concept, instance|
        instance.class.vocabulary.should == Mod
      end
  end

end
