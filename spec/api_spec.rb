require 'rubygems'
require 'activefacts/api'

describe "Value Type class definitions" do
  setup do
    unless Object.const_defined?("M1")	# Is there a way to do once-only setup?
      module M1
	class StringValue < String
	  value_type
	  single :attr
	end
      end
    end
  end

  it "should respond_to verbalise" do
    M1::StringValue.respond_to?(:verbalise).should be_true
  end

  it "should not pollute the value class" do
    String.respond_to?(:verbalise).should_not be_true
  end

  it "should return a string from verbalise" do
    v = M1::StringValue.verbalise
    v.should_not be_nil
    v.should_not =~ /REVISIT/
  end

  it "should respond_to vocabulary" do
    M1::StringValue.respond_to?(:vocabulary).should be_true
  end

  it "should return the parent module as the vocabulary" do
    vocabulary = M1::StringValue.vocabulary
    # vocabulary.should === Module
    vocabulary.should == M1
  end

  it "should return a vocabulary that knows about this concept" do
    vocabulary = M1::StringValue.vocabulary
    vocabulary.respond_to?(:concept).should be_true
    vocabulary.concept.has_key?("StringValue").should be_true
  end

  it "should respond to role()" do
    M1::StringValue.respond_to?(:role).should be_true
  end

  it "should contain only the added role definition" do
    M1::StringValue.role.size.should == 1
  end

  it "should return the role definition" do
    # Check the role definition may be accessed by passing an index:
    role = M1::StringValue.role(0)
    role.should == :attr

    # Check the role definition may be accessed by indexing the returned array:
    role = M1::StringValue.role[0]
    role.should == :attr

    # Check the role definition array by .include?
    M1::StringValue.role.include?(:attr).should be_true
  end

  it "should fail on a non-ValueClass" do
    lambda{
      class StringValue
	value_type
      end
    }.should raise_error
  end
end

describe "Entity Type class definitions" do
  setup do
    unless Object.const_defined?("M4")	# Is there a way to do once-only setup?
      module M4
	class Name < String
	  value_type
	end
	class LegalEntity
	end
	class Person < LegalEntity
	  entity_type :name
	  single :name, Name
	end
      end
    end
  end

  it "should respond_to verbalise" do
    M4::Person.respond_to?(:verbalise).should be_true
  end

  it "should not pollute the superclass" do
    M4::LegalEntity.respond_to?(:verbalise).should_not be_true
    Class.respond_to?(:verbalise).should_not be_true
  end

  it "should return a string from verbalise" do
    v = M4::Person.verbalise
    v.should_not be_nil
    v.should_not =~ /REVISIT/
  end

  it "should respond_to vocabulary" do
    M4::Person.respond_to?(:vocabulary).should be_true
  end

  it "should return the parent module as the vocabulary" do
    vocabulary = M4::Person.vocabulary
    vocabulary.should == M4
  end

  it "should return a vocabulary that knows about this concept" do
    vocabulary = M4::Person.vocabulary
    vocabulary.respond_to?(:concept).should be_true
    vocabulary.concept.has_key?("Person").should be_true
  end

  it "should respond to role()" do
    M4::Person.respond_to?(:role).should be_true
  end

  it "should contain only the added role definition" do
    M4::Person.role.size.should == 1
  end

  it "should return the role definition" do
    # Check the role definition may be accessed by passing an index:
    role = M4::Person.role(0)
    role.should == :name

    # Check the role definition may be accessed by indexing the returned array:
    role = M4::Person.role[0]
    role.should == :name

    # Check the role definition array by .include?
    M4::Person.role.include?(:name).should be_true
  end

  it "should fail on a ValueClass" do
    lambda{
      class SomeClass < String
	entity_type
      end
    }.should raise_error
  end

  it "should return the identifying roles" do
    M4::Person.identifying_roles.should == [:name]
  end

  it "should disallow role names for concepts that exist unless that concept plays that role" do
    lambda {
	module M4
	  class Bad
	    entity_type :name, :nothing_yet
	    single :name, LegalEntity
	  end
	end
      }.should raise_error
  end
end

describe "Value Type instances" do
  setup do
    unless Object.const_defined?("M2")	# Is there a way to do once-only setup?
      module M2
	class StringValue < String
	  value_type
	  single :attr	  # REVISIT: role definition is incomplete
	end
      end
    end
    @string_value = M2::StringValue.new("value")
  end

  it "should respond to verbalise" do
    @string_value.respond_to?(:verbalise).should be_true
  end

  it "should verbalise correctly" do
    @string_value.verbalise.should == "StringValue 'value'"
  end

  it "should respond to constellation" do
    @string_value.respond_to?(:constellation).should be_true
  end

  it "should respond to query" do
    @string_value.respond_to?(:query).should be_true
    lambda {
	@string_value.query
      }.should_not raise_error
  end

  it "should respond to its roles" do
    @string_value.respond_to?(:attr).should be_true
    @string_value.respond_to?(:"attr=").should be_true
  end

  it "should allow its roles to be assigned" do
    lambda {
	@string_value.attr = 23	  # REVISIT: No type-checking on roles yet
      }.should_not raise_error
  end

  it "should allow its roles to be assigned" do
      @string_value.attr = 23
      @string_value.attr.should == 23
  end

  it "should return the ValueType in response to .class()" do
      @string_value.class.vocabulary.should == M2
  end

end

describe "A Constellation instance" do
  setup do
    unless Object.const_defined?("M3")	# Is there a way to do once-only setup?
      module M3
	class StringValue < String
	  value_type
	  single :attr
	end
      end
    end
    @constellation = ActiveFacts::Constellation.new(M3, 97)   # Query can be anything, here
  end

  it "should support fetching its vocabulary and query" do
    @constellation.vocabulary.should == M3
    @constellation.query.should == 97
  end

  it "should support methods to construct instances of any concept" do
    c = nil
    lambda {
	c = @constellation.StringValue("foo")
      }.should_not raise_error
    c.class.should == M3::StringValue
    c.constellation.should == @constellation
  end

  it "should re-use instances constructed the same way" do
    bar1 = @constellation.StringValue("bar")
    bar2 = @constellation.StringValue("bar")
    bar1.object_id.should == bar2.object_id
  end

  it "should index instances" do
    bar1 = @constellation.StringValue("baz")
    @constellation.instances[M3::StringValue].keys.sort.should == ["baz"]
  end

end
