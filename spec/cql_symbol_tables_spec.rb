#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

=begin

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/input/cql'

describe "CQL Symbol table" do

  # A Form here is a form of reference to a object_type, being a name and optional adjectives, possibly designated by a role name:
  # Struct.new("Form", :object_type, :name, :leading_adjective, :trailing_adjective, :role_name)
  # def initialize(constellation, vocabulary)
  # def bind(words, leading_adjective = nil, trailing_adjective = nil, role_name = nil, allowed_forward = false, leading_speculative = false, trailing_speculative = false)

  before :each do
    include ActiveFacts::Input::CQL
    @constellation = ActiveFacts::API::Constellation.new(ActiveFacts::Metamodel)
    @vocabulary = @constellation.Vocabulary("Test")
    @symbols = ActiveFacts::CQL::Compiler::SymbolTable.new(@constellation, @vocabulary)
  end

  Definitions = [
    [ "predefined value type",
      ["Date"],
      ["Date", nil, nil, nil]],
    [ "predefined value type as word array",
      [["Date"]],
      ["Date", nil, nil, nil]],
    [ "predefined value type with inline leading adjective",
      [["Birth", "Date"]],
      ["Date", "Birth", nil, nil]],
    [ "predefined value types with inline trailing adjective",
      [["Date", "OfBirth"]],
      ["Date", nil, "OfBirth", nil]],
    [ "predefined value type with two inline adjectives",
      [["Second", "Birth", "Date"]],
      nil],   # Illegal
    [ "predefined value type with defined leading adjective",
      ["Date", "Birth"],
      ["Date", "Birth", nil, nil]],
    [ "predefined value types with defined trailing adjective",
      ["Date", nil, "OfBirth"],
      ["Date", nil, "OfBirth", nil]],
    [ "predefined value type with inline and defined leading adjective",
      [["Second", "Date"], "Birth"],
      nil],   # Illegal
    [ "predefined value types with inline and defined trailing adjective",
      [["Second", "Date"], nil, "OfBirth"],
      nil],   # Illegal

    [ "predefined type with role name",
      ["Date", nil, nil, "BirthDate"],
      ["Date", nil, nil, "BirthDate"]],

    [ "forward-referenced type",
      ["Unknown", nil, nil, nil, true],
      ["Unknown", nil, nil, nil]],
    [ "forward-referenced type with inline adjective",
      [["Haha", "Unknown"], nil, nil, nil, true],
      nil],   # Illegal

    [ "entity type",
      ["Person"],
      ["Person", nil, nil, nil]],
    [ "entity type as word array",
      [["Person"]],
      ["Person", nil, nil, nil]],
    [ "entity type with inline leading adjective",
      [["Birth", "Person"]],
      ["Person", "Birth", nil, nil]],
    [ "entity types with inline trailing adjective",
      [["Person", "OfBirth"]],
      ["Person", nil, "OfBirth", nil]],
    [ "entity type with two inline adjectives",
      [["Second", "Birth", "Person"]],
      nil],   # Illegal
    [ "entity type with defined leading adjective",
      ["Person", "Birth"],
      ["Person", "Birth", nil, nil]],
    [ "entity types with defined trailing adjective",
      ["Person", nil, "OfBirth"],
      ["Person", nil, "OfBirth", nil]],
    [ "entity type with inline and defined leading adjective",
      [["Second", "Person"], "Birth"],
      nil],   # Illegal
    [ "entity types with inline and defined trailing adjective",
      [["Second", "Person"], nil, "OfBirth"],
      nil],   # Illegal

    [ "entity type with role name",
      ["Person", nil, nil, "Father"],
      ["Person", nil, nil, "Father"]],
  ]

  Definitions.each do |c|
    description, args, result = *c

    it "should define #{description}" do
      if result
        # Predefine an entity type, some cases use it:
        @constellation.EntityType(@vocabulary.identifying_role_values, "Person", :guid => :new)

        player, bound = @symbols.bind(*args)
        player.should_not be_nil
        player.should == bound.object_type
        [bound.name, bound.leading_adjective, bound.trailing_adjective, bound.role_name].should == result
      else
        lambda {player, bound = @symbols.bind(*args)}.should raise_error
      end
    end
  end

  it "should disallow binding to a role name where a leading adjective is provided" do
    object_type, = @symbols.bind("Name", nil, nil, "GivenName", true)
    lambda{player, bound = @symbols.bind("GivenName", "SomeAdj")}.should raise_error
  end

  it "should disallow binding to a role name where a trailing adjective is provided" do
    object_type, = @symbols.bind("Name", nil, nil, "GivenName", true)
    lambda{player, bound = @symbols.bind("GivenName", nil, "SomeAdj")}.should raise_error
  end

  it "should disallow binding to a role name and defining a new role name" do
    object_type, = @symbols.bind("Name", nil, nil, "GivenName", true)
    lambda{player, bound = @symbols.bind("GivenName", nil, nil, "SomeName")}.should raise_error
  end

  Predefined = [
    [ "Name",   "Given",  nil,      nil,          true  ],
    [ "Nom",    nil,      "Donné",  nil,          true  ],
    [ "Name",   nil,      nil,      "GivenName",  true  ],
    [ "Simple", nil,      nil,                          ],
  ]

  it "should allow adding a role name to an adjectival form without one" do
    object_type, = @symbols.bind("Name", "Given", nil, nil, true)
    player, bound = @symbols.bind("Name", nil, nil, "GivenName")
    player.should == object_type
  end

  it "should create new binding with a role name rather than binding to existing simple player without adjectives" do
    object_type, bare = @symbols.bind("Name", nil, nil, nil, true)
    player, bound = @symbols.bind("Name", nil, nil, "SomeAdj")
    bare.should_not == bound
  end

  it "should disallow adding a role name which is the name of an existing object_type" do
    object_type, = @symbols.bind("Name", "Given", nil, nil, true)
    lambda{player, bound = @symbols.bind("Name", "Given", nil, "Date")}.should raise_error
  end

  it "should disallow adding a role name to a role player that already has one" do
    object_type, first = @symbols.bind("Name", "Given", nil, "GivenName", true)
    player, bound = @symbols.bind("Name", "Given", nil, "FirstName")
    first.should_not == bound
  end

  it "should bind to an existing player without adjectives" do
    object_type, = @symbols.bind("Name", nil, nil, nil, true)
    player, bound = @symbols.bind("Name")
    player.should == object_type
  end

  it "should bind to an existing player using a leading adjective" do
    object_type, = @symbols.bind("Name", nil, nil, nil, true)
    player, bound = @symbols.bind("Name", "Given")
    player.should == object_type
  end

  it "should bind to an existing player using a trailing adjective" do
    object_type, = @symbols.bind("Name", nil, nil, nil, true)
    player, bound = @symbols.bind("Name", nil, "Donné")
    player.should == object_type
  end

  it "should bind to an existing player only using the defined leading adjective" do
    object_type, = @symbols.bind("Name", "Given", nil, nil, true)
    player, bound = @symbols.bind("Name", "Given")
    player.should == object_type
    forms = [bound]

    player, alt = @symbols.bind("Name")
    forms.should_not be_include(alt)
    forms << alt

    player, alt = @symbols.bind("Name", nil, "Donné")
    forms.should_not be_include(alt)
    forms << alt

    player, alt = @symbols.bind("Name", "Given", "Donné")
    forms.should_not be_include(alt)
  end

  it "should bind to an existing player only using a defined trailing adjective" do
    object_type, = @symbols.bind("Name", nil, "Donné", nil, true)
    player, bound = @symbols.bind("Name", nil, "Donné")
    player.should == object_type
    forms = [bound]

    player, alt = @symbols.bind("Name")
    forms.should_not be_include(alt)
    forms << alt

    player, alt = @symbols.bind("Name", "Given")
    forms.should_not be_include(alt)
    forms << alt

    player, alt = @symbols.bind("Name", "Given", "Donné")
    forms.should_not be_include(alt)
  end

  it "should bind to an existing player only using defined leading and trailing adjective" do
    object_type, = @symbols.bind("Name", "Given", "Donné", nil, true)
    player, bound = @symbols.bind("Name", "Given", "Donné")
    player.should == object_type
    forms = [bound]

    player, alt = @symbols.bind("Name")
    forms.should_not be_include(alt)
    forms << alt

    player, alt = @symbols.bind("Name", "Given")
    forms.should_not be_include(alt)
    forms << alt

    player, alt = @symbols.bind("Name", nil, "Donné")
    forms.should_not be_include(alt)
  end

  it "should bind to an existing player using a speculative leading adjective" do
    object_type, = @symbols.bind("Name", "Given", nil, nil, true)
    player, bound = @symbols.bind("Name", l = "Given", t = "Donné", nil, nil, true, true)
    player.should == object_type
    bound.leading_adjective.should == "Given"
    bound.trailing_adjective.should be_nil
    l.should be_empty
    t.should == "Donné"
  end

  it "should bind to an existing player using a speculative trailing adjective" do
    object_type, = @symbols.bind("Name", nil, "Donné", nil, true)
    player, bound = @symbols.bind("Name", l = "Given", t = "Donné", nil, nil, true, true)
    player.should == object_type
    l.should == "Given"
    t.should be_empty
  end

  it "should bind to an existing player using a speculative leading and trailing adjective" do
    object_type, = @symbols.bind("Name", "Given", "Donné", nil, true)
    player, bound = @symbols.bind("Name", l = "Given", t = "Donné", nil, nil, true, true)
    player.should == object_type
    l.should be_empty
    t.should be_empty
  end

end
=end
