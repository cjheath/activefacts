#
# ActiveFacts test:
#
# Parse all NORMA files, compute the composition (list of tables)
# and compare that with NORMA's output.
#
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/persistence'
require 'activefacts/support'
require 'activefacts/input/orm'

include ActiveFacts
include ActiveFacts::Metamodel

Exceptions = {
  "Blog" => ["Author", "Comment", "Paragraph", "Post", "Topic"],
  "DeathAsBinary" => ["Person"],
  "Metamodel" => ["AllowedRange", "Constraint", "Correspondence", "Derivation", "Fact", "FactType", "Feature", "Instance", "JoinPath", "Reading", "Role", "RoleRef", "RoleSequence", "RoleValue", "SetComparisonRoles", "Unit", "ValueRestriction"],
  "MetamodelTerms" => ["AllowedValue", "Concept", "Constraint", "Derivation", "Fact", "FactType", "Import", "Instance", "Join", "JoinRole", "ParamValue", "Reading", "Role", "RoleRef", "RoleSequence", "RoleValue", "SetComparisonRoles", "Term", "Unit", "ValueRestriction"],
  "OilSupply" => ["AcceptableSubstitutes", "Month", "ProductionForecast", "RegionalDemand", "TransportRoute"],
  "OilSupplyWithCosts" => ["AcceptableSubstitutes", "Month", "ProductionForecast", "RegionalDemand", "TransportRoute"],
  "Orienteering" => ["Club", "Entry", "Event", "EventControl", "EventScoringMethod", "Map", "Person", "Punch", "PunchPlacement", "Series", "Visit"],
  "SeparateSubtype" => ["Claim", "VehicleIncident"],
  "Warehousing" => ["Bin", "DirectOrderMatch", "DispatchItem", "Party", "Product", "PurchaseOrder", "PurchaseOrderItem", "ReceivedItem", "SalesOrder", "SalesOrderItem", "TransferRequest", "Warehouse"]
}

def extract_created_tables_from_sql sql_file
  File.open(sql_file) do |f|
    f.
    readlines.
    select do |l|
      l =~ /CREATE TABLE/
    end.
    map do |l|
      l.chomp.gsub(/.*CREATE TABLE\s+\W*(\w+\.)?"?(\w+)"?.*/, '\2')
    end.
    sort
  end
end

describe "Relational Composition from NORMA" do
  #Dir["examples/norma/B*.orm"].each do |orm_file|
  #Dir["examples/norma/Ins*.orm"].each do |orm_file|
  #Dir["examples/norma/Meta*.orm"].each do |orm_file|
  #Dir["examples/norma/W*.orm"].each do |orm_file|
  Dir["examples/norma/*.orm"].each do |orm_file|
    expected_tables = Exceptions[File.basename(orm_file, ".orm")]
    if !expected_tables
      sql_file_pattern = orm_file.sub(/\.orm\Z/, '*.sql')
      sql_file = Dir[sql_file_pattern][0]
      next unless sql_file
    end

    it "should load #{orm_file} and compute #{
        expected_tables ?
          "the expected list of tables" :
          "a list of tables similar to those in #{sql_file}"
      }" do

      # Read the ORM file:
      vocabulary = ActiveFacts::Input::ORM.readfile(orm_file)

      # Get the list of tables from NORMA's SQL:
      expected_tables ||= extract_created_tables_from_sql(sql_file)

      # Get the list of tables from our composition:
      tables = vocabulary.tables
      table_names = tables.map{|o| o.name }.sort

      # Save the actual and expected composition to files
      actual_tables_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.tables')
      File.open(actual_tables_file, "w") { |f| f.puts table_names*"\n" }
      expected_tables_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.expected.tables')
      File.open(expected_tables_file, "w") { |f| f.puts expected_tables*"\n" }

      # Check that the list matched:
      table_names.should == expected_tables

      # Calculate the columns and column names; REVISIT: check the results
      tables.each do |table|
        table.columns
      end

      File.delete(actual_tables_file)
      File.delete(expected_tables_file)
    end
  end
end
