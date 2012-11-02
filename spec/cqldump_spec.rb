#
# ActiveFacts tests: Test the generated CQL for some simple cases.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'stringio'
require 'activefacts/support'
require 'activefacts/vocabulary'
require 'activefacts/generate/cql'

describe "CQL Dumper" do
  def self.hide(*a,&b)
  end

  before :each do
    @constellation = ActiveFacts::API::Constellation.new(ActiveFacts::Metamodel)
    @vocabulary = @constellation.Vocabulary("TestVocab")
    @string_type = @constellation.ValueType(@vocabulary, "String", :guid => :new)
    @integer_type = @constellation.ValueType(@vocabulary, "Integer", :guid => :new)
    @dumper = ActiveFacts::Generate::CQL.new(@constellation)
  end

  def cql
    output = StringIO.new
    @dumper.generate(output)
    output.rewind
    output.read
  end

  it "should dump a String ValueType" do
    vt = @constellation.ValueType(@vocabulary, "Name", :supertype => @string_type, :length => 20, :guid => :new)
    vt.supertype = @string_type
    vt.length = 20
    #p vt.class.roles.keys.sort_by{|s| s.to_s}
    #p vt.supertype
    cql.should == <<END
vocabulary TestVocab;

/*
 * Value Types
 */
Name is written as String(20);

END
  end

  it "should dump an Integer ValueType" do
    vt = @constellation.ValueType(@vocabulary, "Count", :supertype => @integer_type, :length => 32, :guid => :new)
    cql.should == <<END
vocabulary TestVocab;

/*
 * Value Types
 */
Count is written as Integer(32);

END
  end

  def value_type(name, datatype = "String", length = 0, scale = 0)
    dt = @constellation.ValueType(@vocabulary, datatype, :guid => :new)
    vt = @constellation.ValueType(@vocabulary, name, :supertype => dt, :guid => :new)
    vt.length = length if length != 0
    vt.scale = scale if scale != 0
    vt
  end

  def one_to_many(one, many, reading)
    # Combine them with a fact type:
    ft = @constellation.FactType(:new)
    role0 = @constellation.Role(ft, 0, :object_type => one, :guid => :new)
    role1 = @constellation.Role(ft, 1, :object_type => many, :guid => :new)

    # Make a role sequence:
    rs = @constellation.RoleSequence(:new)
    rr0 = @constellation.RoleRef(rs, 0, :role => role0)
    rr1 = @constellation.RoleRef(rs, 1, :role => role1)

    # Make a uniqueness constraint:
    pcrs = @constellation.RoleSequence(:new)
    @constellation.RoleRef(pcrs, 0, :role => role0)
    pc = @constellation.PresenceConstraint(:new, :is_mandatory => false, :is_preferred_identifier => false, :max_frequency => 1, :min_frequency => 0, :role_sequence => pcrs)

    # Make a new reading:
    reading = @constellation.Reading(ft, ft.all_reading.size, :role_sequence => rs, :text => reading)

    ft
  end

  def one_to_one(first, second, reading)
    # Combine them with a fact type:
    ft = @constellation.FactType(:new)
    role0 = @constellation.Role(ft, 0, :object_type => first, :guid => :new)
    role1 = @constellation.Role(ft, 1, :object_type => second, :guid => :new)

    # Make a role sequence for the reading
    rs = @constellation.RoleSequence(:new)
    rr0 = @constellation.RoleRef(rs, 0, :role => role0)
    rr1 = @constellation.RoleRef(rs, 1, :role => role1)

    # Make a new reading:
    reading = @constellation.Reading(ft, ft.all_reading.size, :role_sequence => rs, :text => reading)

    # Make a uniqueness constraint for the first role
    first_rs = @constellation.RoleSequence(:new)
    @constellation.RoleRef(first_rs, 0, :role => role0)
    first_pc = @constellation.PresenceConstraint(:new, :is_mandatory => true, :is_preferred_identifier => false, :max_frequency => 1, :min_frequency => 1, :role_sequence => first_rs)

    # Make a uniqueness constraint for the second role
    second_rs = @constellation.RoleSequence(:new)
    @constellation.RoleRef(second_rs, 0, :role => role1)
    second_pc = @constellation.PresenceConstraint(:new, :is_mandatory => true, :is_preferred_identifier => true, :max_frequency => 1, :min_frequency => 1, :role_sequence => second_rs)

    ft
  end

  it "should dump a VT-VT FactType" do
    # Make two valuetypes:
    st = value_type("Name", "String", 20)
    vt = value_type("Count", "Integer", 32)

    ft = one_to_many(st, vt, "{0} occurs {1} times")

    #puts @constellation.verbalise #; exit

    cql.should == <<END
vocabulary TestVocab;

/*
 * Value Types
 */
Count is written as Integer(32);
Name is written as String(20);

/*
 * Fact Types
 */
Name occurs Count times;

END
  end

  it "should dump an named EntityType" do
    vt = @constellation.ValueType(@vocabulary, "Name", :supertype => @string_type, :length => 20, :guid => :new)
    et = @constellation.EntityType(@vocabulary, "Company", :guid => :new)

    ft = one_to_one(et, vt, "{0} is called {1}")

    cql.should == <<END
vocabulary TestVocab;

/*
 * Value Types
 */
Name is written as String(20);

/*
 * Entity Types
 */
Company is identified by Name where
	Company is called Name;

END

  end

end
