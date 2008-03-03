describe "Roles" do
  setup do
    unless Object.const_defined?("M5")	# Is there a way to do once-only setup?
      module M5
	class Name < String
	  value_type
	end
	class LegalEntity
	  entity_type :name
	  binary :name
	end
	class Contract
	  entity_type :first, :second
	  binary :first, LegalEntity
	  binary :second, LegalEntity
	end
	class Person < LegalEntity
	  # entity_type	  # No identifier needed, inherit from superclass
	  # New identifier:
	  entity_type :family, :given
	  binary :family, Name
	  binary :given, Name
	  binary :related_to, LegalEntity
	end
      end
      # print "concept: "; p M5.concept
    end
  end

  it "should associate a role name with a matching existing concept" do
    module M5
      class Existing1 < String
	value_type
	binary :name
      end
    end
    role = M5::Existing1.roles(:name)
    role.should_not be_nil
    role.player.should == M5::Name
  end

  it "should inject the respective role name into the matching concept" do
    M5::Name.roles(:all_existing1).should_not be_nil
    M5::LegalEntity.roles(:all_contract_by_first).should_not be_nil
  end

  it "should associate a role name with a matching concept after it's created" do
    module M5
      class Existing2 < String
	value_type
	binary :given_name
      end
    end
    # print "M5::Existing2.roles = "; p M5::Existing2.roles
    r = M5::Existing2.roles(:given_name)
    r.should_not be_nil
    Symbol.should === r.player
    module M5
      class GivenName < String
	value_type
      end
    end
    # puts "Should resolve now:"
    r = M5::Existing2.roles(:given_name)
    r.should_not be_nil
    r.player.should == M5::GivenName
  end

  it "should handle subtyping a value type" do
    module M5
      class FamilyName < Name
	value_type
	binary :patriarch, Person, 1
      end
    end
    r = M5::FamilyName.roles(:patriarch)
    r.should_not be_nil
    r.player.should == M5::Person
    r.player.roles(:family_name).player.should == M5::FamilyName
  end

  it "should instantiate the matching concept on assignment" do
    c = ActiveFacts::Constellation.new(M5)
    bloggs = c.LegalEntity("Bloggs")
    acme = c.LegalEntity("Acme, Inc")
    contract = c.Contract("Bloggs", acme)
    contract.first.should == bloggs
  end

  it "should append the player into the respective role array in the matching concept" do
    le = M5::LegalEntity.new("Foo")
    le.respond_to?(:name).should be_true
    name = le.name
    name.respond_to?(:all_legal_entity).should be_true

    #pending
    name.all_legal_entity.should === [le]
  end

  it "should instantiate subclasses sensibly" do
    c = ActiveFacts::Constellation.new(M5)
    bloggs = c.LegalEntity("Bloggs & Co")
    #pending
    p = c.Person("Fred", "Bloggs")
    p.related_to = "Bloggs & Co"
    M5::LegalEntity.should === p.related_to
    bloggs.object_id.should == p.related_to.object_id
  end

end
