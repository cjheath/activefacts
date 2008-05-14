#
# ActiveFacts tests: Test the generated CQL for some simple cases.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/generate/cql'

describe "CQL Dumper" do
  def self.hide(*a,&b)
  end

  setup do
    @constellation = ActiveFacts::Constellation.new(ActiveFacts::Metamodel)
    @vocabulary = @constellation.Vocabulary("TestVocab", nil)
    @string_type = @constellation.ValueType("String", @vocabulary)
    @integer_type = @constellation.ValueType("Integer", @vocabulary)
    @dumper = ActiveFacts::Generate::CQL.new(@constellation)
  end

  def cql
    output = StringIO.new
    @dumper.generate(output)
    output.rewind
    output.read
  end

  it "should dump a String ValueType" do
    vt = @constellation.ValueType("Name", @vocabulary, :supertype => @string_type, :length => 20)
    cql.should == <<END
vocabulary TestVocab;

/*
 * Value Types
 */
Name = String(20);

END
  end

  it "should dump an Integer ValueType" do
    vt = @constellation.ValueType("Count", @vocabulary, :supertype => @integer_type, :length => 32)
    cql.should == <<END
vocabulary TestVocab;

/*
 * Value Types
 */
Count = Integer(32);

END
  end

  def value_type(name, datatype = "String", length = 0, scale = 0)
    dt = @constellation.ValueType(datatype, @vocabulary)
    vt = @constellation.ValueType(name, @vocabulary, :supertype => dt)
    vt.length = length if length != 0
    vt.scale = scale if scale != 0
    vt
  end

  def one_to_many(one, many, reading)
    # Join them with a fact type:
    ft = @constellation.FactType(:new)
    role0 = @constellation.Role(:new, :concept => one, :fact_type => ft)
    role1 = @constellation.Role(:new, :concept => many, :fact_type => ft)

    # Make a role sequence:
    rs = @constellation.RoleSequence(:new)
    rr0 = @constellation.RoleRef(rs, 0, :role => role0)
    rr1 = @constellation.RoleRef(rs, 1, :role => role1)

    # Make a uniqueness constraint:
    pcrs = @constellation.RoleSequence(:new)
    @constellation.RoleRef(pcrs, 0, :role => role0)
    pc = @constellation.PresenceConstraint(:new, :is_mandatory => false, :is_preferred_identifier => false, :max_frequency => 1, :min_frequency => 0, :role_sequence => pcrs)

    # Make a new reading:
    reading = @constellation.Reading(ft, ft.all_reading.size, :role_sequence => rs, :reading_text => reading)

    ft
  end

  def one_to_one(first, second, reading)
    # Join them with a fact type:
    ft = @constellation.FactType(:new)
    role0 = @constellation.Role(:new, :concept => first, :fact_type => ft)
    role1 = @constellation.Role(:new, :concept => second, :fact_type => ft)

    # Make a role sequence for the reading
    rs = @constellation.RoleSequence(:new)
    rr0 = @constellation.RoleRef(rs, 0, :role => role0)
    rr1 = @constellation.RoleRef(rs, 1, :role => role1)

    # Make a new reading:
    reading = @constellation.Reading(ft, ft.all_reading.size, :role_sequence => rs, :reading_text => reading)

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
Count = Integer(32);
Name = String(20);

/*
 * Fact Types
 */
Name occurs Count times;

END
  end

  it "should dump an named EntityType" do
    vt = @constellation.ValueType("Name", @vocabulary, :supertype => @string_type, :length => 20)
    et = @constellation.EntityType("Company", @vocabulary)

    ft = one_to_one(et, vt, "{0} is called {1}")

    cql.should == <<END
vocabulary TestVocab;

/*
 * Value Types
 */
Name = String(20);

/*
 * Entity Types
 */
Company = entity identified by Name:
	Company is called Name;

END

  end

end
