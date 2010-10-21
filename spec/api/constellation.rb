#
# ActiveFacts tests: Constellation instances in the Runtime API
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/api'

describe "A Constellation instance" do
  before :each do
    Object.send :remove_const, :Mod if Object.const_defined?("Mod")
    module Mod
      @base_types = [
          Int, Real, AutoCounter, String, Date, DateTime
        ]

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

      class Name < StringValue
        value_type
        #has_one :attr, Name
      end

      class LegalEntity
        identified_by :name
        has_one :name
      end

      class SurrogateId
        identified_by :auto_counter_value
        has_one :auto_counter_value
      end

      class Company < LegalEntity
        supertypes SurrogateId
      end

      class Person < LegalEntity
        identified_by :name, :family_name     # REVISIT: want a way to role_alias :name, :given_name
        supertypes SurrogateId

        has_one :family_name, :class => Name
      end
    end
    @constellation = ActiveFacts::API::Constellation.new(Mod)
  end

  it "should support fetching its vocabulary" do
    @constellation.vocabulary.should == Mod
  end

#  it "should support fetching its query" do
#    pending
#    @constellation.query.should == Mod
#  end

  it "should support methods to construct instances of any object_type" do
    name = foo = acme = fred_fly = nil
    lambda {
        name = @constellation.Name("foo")
        foo = @constellation.LegalEntity("foo")
        acme = @constellation.Company("Acme, Inc")
        fred_fly = @constellation.Person("fred", "fly")
      }.should_not raise_error
    name.class.should == Mod::Name
    name.constellation.should == @constellation
    foo.class.should == Mod::LegalEntity
    foo.constellation.should == @constellation
    acme.class.should == Mod::Company
    acme.constellation.should == @constellation
    fred_fly.class.should == Mod::Person
    fred_fly.constellation.should == @constellation
  end

  it "should re-use instances constructed the same way" do
    name1 = @constellation.Name("foo")
    foo1 = @constellation.LegalEntity("foo")
    acme1 = @constellation.Company("Acme, Inc")
    fred_fly1 = @constellation.Person("fred", "fly")

    name2 = @constellation.Name("foo")
    foo2 = @constellation.LegalEntity("foo")
    acme2 = @constellation.Company("Acme, Inc")
    fred_fly2 = @constellation.Person("fred", "fly")

    name1.object_id.should == name2.object_id
    foo1.object_id.should == foo2.object_id
    acme1.object_id.should == acme2.object_id
    fred_fly1.object_id.should == fred_fly2.object_id
  end

  it "should index value instances, including by its superclasses" do
    baz = @constellation.Name("baz")
    @constellation.Name.keys.sort.should == ["baz"]

    @constellation.StringValue.keys.sort.should == ["baz"]
  end

  it "should index entity instances, including by its superclass and secondary supertypes" do
    name = "Acme, Inc"
    fred = "Fred"
    fly = "Fly"
    acme = @constellation.Company name, :auto_counter_value => :new
    fred_fly = @constellation.Person fred, fly, :auto_counter_value => :new

    # REVISIT: This should be illegal:
    #fred_fly.auto_counter_value = :new

    @constellation.Person.keys.sort.should == [[fred, fly]]
    @constellation.Company.keys.sort.should == [[name]]

    @constellation.LegalEntity.keys.sort.should be_include([name])
    @constellation.LegalEntity.keys.sort.should be_include([fred])

    @constellation.SurrogateId.values.should be_include(acme)
    @constellation.SurrogateId.values.should be_include(fred_fly)
  end

end
