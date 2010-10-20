#
# ActiveFacts tests: Value types in the Runtime API
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/api'

describe "Value Type class definitions" do
  before :each do
    Object.send :remove_const, :Mod if Object.const_defined?("Mod")
    module Mod
      class Name < String
        value_type
        has_one :name
      end
      class Year < Int
        value_type
        has_one :name
      end
      class Weight < Real
        value_type
        has_one :name
      end
    end

    @classes = [Mod::Name, Mod::Year,Mod::Weight]
    @attrs = [:name, :name, :name]

  end

  it "should respond_to verbalise" do
    @classes.each { |klass|
        klass.respond_to?(:verbalise).should be_true
      }
  end

  it "should not pollute the value class" do
    @classes.each { |klass|
        klass.superclass.respond_to?(:verbalise).should_not be_true
      }
  end

  it "should return a string from verbalise" do
    @classes.each { |klass|
        v = klass.verbalise
        v.should_not be_nil
        v.should_not =~ /REVISIT/
      }
  end

  it "should respond_to vocabulary" do
    @classes.each { |klass|
        klass.respond_to?(:vocabulary).should be_true
      }
  end

  it "should return the parent module as the vocabulary" do
    @classes.each { |klass|
        vocabulary = klass.vocabulary
        vocabulary.should == Mod
      }
  end

  it "should return a vocabulary that knows about this object_type" do
    @classes.each { |klass|
        vocabulary = klass.vocabulary
        vocabulary.respond_to?(:object_type).should be_true
        vocabulary.object_type.has_key?(klass.basename).should be_true
      }
  end

  it "should respond to roles()" do
    @classes.each { |klass|
        klass.respond_to?(:roles).should be_true
      }
  end

  it "should contain only the added role definitions" do
    Mod::Name.roles.size.should == 4
    (@classes-[Mod::Name]).each { |klass|
        klass.roles.size.should == 1
      }
  end

  it "should return the role definition" do
    # Check the role definition may not be accessed by passing an index:
    Mod::Name.roles(0).should be_nil

    @classes.zip(@attrs).each { |pair|
        klass, attr = *pair
        role = klass.roles(attr)
        role.should_not be_nil

        role = klass.roles(attr.to_s)
        role.should_not be_nil

        # Check the role definition may be accessed by indexing the returned array:
        role = klass.roles[attr]
        role.should_not be_nil

        # Check the role definition array by .include?
        klass.roles.include?(attr).should be_true
      }
  end

  # REVISIT: role value constraints

  it "should fail on a non-ValueClass" do
    lambda{
      class NameNotString
        value_type
      end
    }.should raise_error
  end
end
