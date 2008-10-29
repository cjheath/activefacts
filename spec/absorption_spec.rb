#
# ActiveFacts tests: Test the relational absorption by compiling CQL fragments.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'treetop'
require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/input/cql'
require 'activefacts/persistence'

describe "Absorption" do
  Prologue = %Q{
    vocabulary Test;
    DateTime is defined as DateAndTime();
    Month is defined as VariableLengthText(3);
    Season is defined as VariableLengthText(6);
    PartyID is defined as AutoCounter();
    ClaimID is defined as AutoCounter();
  }
  Claim = %Q{
    Claim is identified by ClaimID where
      Claim has exactly one ClaimID,
      ClaimID is of at most one Claim;
  }
  Incident = %Q{
    Incident is identified by Claim where
      Claim concerns at most one Incident,
      Incident is of exactly one Claim;
  }
  Party = %Q{
    Party is identified by PartyID where
      Party has exactly one PartyID,
      PartyID is of at most one Party;
  }
  Person = %Q{
    Person is a kind of Party;
  }

  Tests = [
    { :should => "inject a value column into the table for an independent ValueType",
      :cql => %Q{
        #{Prologue}
        Month is in exactly one Season;
      },
      :tables => { "Month" => [ "Month-Value", "Season" ] }
    },

    { :should => "absorb a one-to-one along the identification path",
      :cql => %Q{
        #{Prologue} #{Claim} #{Incident}
        Incident relates to loss on exactly one DateTime;
      },
      :tables => { "Claim" => ["ClaimID", "Incident.DateTime"]}
    },

    { :should => "absorb an objectified binary with single-role UC",
      :cql => %Q{
        #{Prologue} #{Claim} #{Party} #{Person}
        Lodgement is where
          Claim was lodged by at most one Person;
        Lodgement was made at at most one DateTime;
        Person has exactly one birth-Date;
      },
      :tables => {
        "Claim" => ["ClaimID", "Lodgement.DateTime", "Lodgement.Lodgement.Party.PartyID"],
        "Party" => ["PartyID", "Person.birth-Date"]
      }
    },

  ]

  setup do
  end

  Tests.each do |test|
    should = test[:should]
    cql = test[:cql]
    expected_tables = test[:tables]
    it "should #{should}" do
      @compiler = ActiveFacts::Input::CQL.new(cql, should)
      @vocabulary = @compiler.read

      # Ensure that the same tables were generated:
      tables = @vocabulary.tables
      tables.map(&:name).sort.should == expected_tables.keys.sort

      # Ensure that the same column descriptions were generated:
      tables.sort_by(&:name).each do |table|
        column_descriptions = table.absorbed_roles.all_role_ref.map{|rr| rr.describe}.sort
        column_descriptions.should == expected_tables[table.name].sort
      end
    end
  end
end
