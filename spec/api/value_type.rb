describe "Value Type class definitions" do
  setup do
    unless Object.const_defined?("M1")	# Is there a way to do once-only setup?
      module M1
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
    end

    @classes = [M1::Name, M1::Year,M1::Weight]
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
	vocabulary.should == M1
      }
  end

  it "should return a vocabulary that knows about this concept" do
    @classes.each { |klass|
	vocabulary = klass.vocabulary
	vocabulary.respond_to?(:concept).should be_true
	vocabulary.concept.has_key?(klass.basename).should be_true
      }
  end

  it "should respond to roles()" do
    @classes.each { |klass|
	klass.respond_to?(:roles).should be_true
      }
  end

  it "should contain only the added role definitions" do
    M1::Name.roles.size.should == 4
    (@classes-[M1::Name]).each { |klass|
	klass.roles.size.should == 1
      }
  end

  it "should return the role definition" do
    # Check the role definition may not be accessed by passing an index:
    lambda {
      role = M1::Name.roles(0)
    }.should raise_error

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

  # REVISIT: role value restrictions

  it "should fail on a non-ValueClass" do
    lambda{
      class NameNotString
	value_type
      end
    }.should raise_error
  end
end
