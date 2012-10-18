#
# ActiveFacts CQL join compilation tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# A join has at least one JoinStep.
# Each Join Step is over two Join Nodes.
# Each Join Node is associated with one or more Role Refs
# For a given Join Node, all the Role Refs are for Roles played by the same ObjectType (which the Join Node is for)
# For a given Join Step, both Join Nodes have a Role Ref in the same Fact Type (which the Join Step traverses)
# ... except in the case of an objectification Join Step, see below
# A RoleRef of a Join Node may be for a Role (played by an objectified Fact Type) of an Implicit Fact Type (implied by a Role of that objectified Fact Type)
# A Join Step that traverses an Implicit Fact Type has a Join Node involving the single Role of that FT, and another Join Node involving the role that implied it (an objectification join step)
# The Fact Type traversed by a Join Step may be a Type Inheritance Fact Type (a subtyping join step)

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
# require File.dirname(__FILE__) + '/../helpers/compiler_helper'  # Can't see how to include/extend these methods correctly

describe "Join construction from CQL" do
  JoinsPrefix = %q{
    vocabulary Tests;
    Product is identified by its Name;
    Purchase Order Item is identified by its ID;
    Sales Order Item is identified by its ID;
    Purchase Order Item is for one Product;
    Sales Order Item is for one Product;
    Purchase Order Item matches Sales Order Item;
  }
  before :each do
    @compiler = ActiveFacts::CQL::Compiler.new('Test')
  end

  JoinTests = [
    %q{
      Purchase Order Item matches Sales Order Item
        only if Purchase Order Item is for Product and Sales Order Item is for Product;
    }

  ]

  before :each do
    @compiler.compile(JoinsPrefix).should_not be_nil
  end

  JoinTests.each do |test|
    it "should process '#{test}' correctly" do
      result = @compiler.compile(test)
      puts @compiler.failure_reason unless result
      result.should_not be_nil
      # REVISIT: Add some assertions here!
    end
  end

end
