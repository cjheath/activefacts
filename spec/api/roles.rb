#
# ActiveFacts tests: Roles of object_type classes in the Runtime API
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/api'

describe "Roles" do
  before :each do
    Object.send :remove_const, :Mod if Object.const_defined?("Mod")
    module Mod
      class Name < String
        value_type
      end
      class LegalEntity
        identified_by :name
        has_one :name
      end
      class Contract
        identified_by :first, :second
        has_one :first, :class => LegalEntity
        has_one :second, :class => LegalEntity
      end
      class Person < LegalEntity
        # identified_by         # No identifier needed, inherit from superclass
        # New identifier:
        identified_by :family, :given
        has_one :family, :class => Name
        has_one :given, :class => Name
        has_one :related_to, :class => LegalEntity
      end
    end
    # print "object_type: "; p Mod.object_type
  end

  it "should associate a role name with a matching existing object_type" do
    module Mod
      class Existing1 < String
        value_type
        has_one :name
      end
    end
    role = Mod::Existing1.roles(:name)
    role.should_not be_nil
    role.counterpart_object_type.should == Mod::Name
  end

  it "should inject the respective role name into the matching object_type" do
    module Mod
      class Existing1 < String
        value_type
        has_one :name
      end
    end
    Mod::Name.roles(:all_existing1).should_not be_nil
    Mod::LegalEntity.roles(:all_contract_as_first).should_not be_nil
  end

  it "should associate a role name with a matching object_type after it's created" do
    module Mod
      class Existing2 < String
        value_type
        has_one :given_name
      end
    end
    # print "Mod::Existing2.roles = "; p Mod::Existing2.roles
    r = Mod::Existing2.roles(:given_name)
    r.should_not be_nil
    Symbol.should === r.counterpart_object_type
    module Mod
      class GivenName < String
        value_type
      end
    end
    # puts "Should resolve now:"
    r = Mod::Existing2.roles(:given_name)
    r.should_not be_nil
    r.counterpart_object_type.should == Mod::GivenName
  end

  it "should handle subtyping a value type" do
    module Mod
      class FamilyName < Name
        value_type
        one_to_one :patriarch, :class => Person
      end
    end
    r = Mod::FamilyName.roles(:patriarch)
    r.should_not be_nil
    r.counterpart_object_type.should == Mod::Person
    r.counterpart_object_type.roles(:family_name_as_patriarch).counterpart_object_type.should == Mod::FamilyName
  end

  it "should instantiate the matching object_type on assignment" do
    c = ActiveFacts::API::Constellation.new(Mod)
    bloggs = c.LegalEntity("Bloggs")
    acme = c.LegalEntity("Acme, Inc")
    contract = c.Contract("Bloggs", acme)
    #contract = c.Contract("Bloggs", "Acme, Inc")
    contract.first.should == bloggs
    contract.second.should == acme
    end

  it "should append the counterpart into the respective role array in the matching object_type" do
    foo = Mod::Name.new("Foo")
    le = Mod::LegalEntity.new(foo)
    le.respond_to?(:name).should be_true
    name = le.name
    name.respond_to?(:all_legal_entity).should be_true

    #pending
    Array(name.all_legal_entity).should === [le]
  end

  it "should instantiate subclasses sensibly" do
    c = ActiveFacts::API::Constellation.new(Mod)
    bloggs = c.LegalEntity("Bloggs & Co")
    #pending
    p = c.Person("Fred", "Bloggs")
    p.related_to = "Bloggs & Co"
    p.related_to.should be_is_a(Mod::LegalEntity)
    bloggs.object_id.should == p.related_to.object_id
  end

end
