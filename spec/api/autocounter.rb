#
# ActiveFacts tests: Value instances in the Runtime API
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/api'

describe "AutoCounter Value Type instances" do
  before :each do
    Object.send :remove_const, :Mod if Object.const_defined?("Mod")
    module Mod
      class ThingId < AutoCounter
        value_type
      end
      class Thing
        identified_by :thing_id
        has_one :thing_id
      end
      class Ordinal < Int
        value_type
      end
      class ThingFacet
        identified_by :thing, :ordinal
        has_one :thing
        has_one :ordinal
      end
    end
    @constellation = ActiveFacts::API::Constellation.new(Mod)
    @thing = Mod::Thing.new(:new)
    @thing_id = Mod::ThingId.new
  end

  it "should respond to verbalise" do
    @thing_id.respond_to?(:verbalise).should be_true
  end

  it "should verbalise correctly" do
    @thing_id.verbalise.should =~ /ThingId 'new_[0-9]+'/
  end

  it "should respond to constellation" do
    @thing_id.respond_to?(:constellation).should be_true
  end

  it "should respond to its roles" do
    @thing_id.respond_to?(:all_thing).should be_true
  end

  it "should allow prevent invalid role assignment" do
    lambda {
        @thing.thing_id = "foo"
      }.should raise_error
  end

  it "should not allow its identifying roles to be assigned" do
    lambda {
        @thing.thing_id = @thing_id
      }.should raise_error
  end

  it "should allow an existing counter to be re-used" do
    @new_thing = Mod::Thing.new(@thing_id)
    @new_thing.thing_id.should == @thing_id
  end

  it "should return the ValueType in response to .class()" do
    @thing_id.class.vocabulary.should == Mod
  end

  it "should not allow a counter to be cloned" do
    lambda {
      @thing_id.clone
    }.should raise_error
  end

  it "should allow an existing counter-identified object to be re-used" do
    thing = @constellation.Thing(:new)
    facets = []
    facets << @constellation.ThingFacet(thing, 0)
    facets << @constellation.ThingFacet(thing, 1)
    facets[0].thing.object_id.should == facets[1].thing.object_id
    facets[0].thing.thing_id.object_id.should == facets[1].thing.thing_id.object_id
  end

end
