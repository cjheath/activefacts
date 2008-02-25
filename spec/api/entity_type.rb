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
	  binary :name, Name
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

  it "should respond to roles()" do
    M4::Person.respond_to?(:roles).should be_true
  end

  it "should contain only the added role definition" do
    M4::Person.roles.size.should == 1
  end

  it "should return the role definition" do
    # Check the role definition may be accessed by passing an index:
    lambda{
      role = M4::Person.roles(0)
    }.should raise_error

    role = M4::Person.roles(:name)
    role.should_not be_nil

    role = M4::Person.roles("name")
    role.should_not be_nil

    # Check the role definition may be accessed by indexing the returned hash:
    role = M4::Person.roles[:name]
    role.should_not be_nil

    # Check the role definition array by .include?
    M4::Person.roles.include?(:name).should be_true
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

  it "should prevent a role name from matching a concept that exists unless that concept is the player" do
    lambda {
	module M4
	  class LegalEntity
	  end
	  class Bad
	    entity_type :name
	    binary :name, LegalEntity
	  end
	end
      }.should raise_error
  end
end
