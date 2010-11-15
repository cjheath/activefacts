#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'spec_helper'
require 'helpers/test_parser'

describe "ASTs from Derived Fact Types with expressions" do
  it "should parse a simple comparison clause" do
    %q{
      each combination FamilyName, GivenName occurs at most one time in Competitor has FamilyName, Competitor has GivenName;
    }.should parse_to_ast \
      "PresenceConstraint over [[{Competitor} \"has\" {FamilyName}], [{Competitor} \"has\" {GivenName}]] -1 over ({FamilyName}, {GivenName})"
  end
end
