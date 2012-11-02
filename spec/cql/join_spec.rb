#
# ActiveFacts CQL query compilation tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# A query has at least one Step.
# Each Step is over two Variables.
# Each Variable is associated with one or more Role Refs
# For a given Variable, all the Role Refs are for Roles played by the same ObjectType (which the Variable is for)
# For a given Step, both Variables have a Role Ref in the same Fact Type (which the Step traverses)
# ... except in the case of an objectification Step, see below
# A RoleRef of a Variable may be for a Role (played by an objectified Fact Type) of an Implicit Fact Type (implied by a Role of that objectified Fact Type)
# A Step that traverses an Implicit Fact Type has a Variable involving the single Role of that FT, and another Variable involving the role that implied it (an objectification step)
# The Fact Type traversed by a Step may be a Type Inheritance Fact Type (a subtyping step)

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
# require File.dirname(__FILE__) + '/../helpers/compiler_helper'  # Can't see how to include/extend these methods correctly

describe "query construction from CQL" do
  QueriesPrefix = %q{
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

  QueryTests = [
    %q{
      Purchase Order Item matches Sales Order Item
        only if Purchase Order Item is for Product and Sales Order Item is for Product;
    }

  ]

  before :each do
    @compiler.compile(QueriesPrefix).should_not be_nil
  end

  QueryTests.each do |test|
    it "should process '#{test}' correctly" do
      result = @compiler.compile(test)
      puts @compiler.failure_reason unless result
      result.should_not be_nil
      # REVISIT: Add some assertions here!
    end
  end

end
