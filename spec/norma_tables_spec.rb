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
require 'activefacts/generate/cql'

include ActiveFacts
include ActiveFacts::Metamodel

Exceptions = {
  "Blog" => ["Author", "Comment", "Paragraph", "Post", "Topic"],
  "DeathAsBinary" => ["Person"],
  "Insurance" => ["Asset", "Claim", "ContactMethods", "ContractorAppointment", "Cover", "CoverType", "CoverWording", "DamagedProperty", "DemeritKind", "LossType", "LostItem", "Party", "Policy", "Product", "State", "ThirdParty", "UnderwritingDemerit", "Witness"],
  "Metamodel" => ["AllowedRange", "Coefficient", "Constraint", "Correspondence", "Fact", "FactType", "Feature", "Instance", "JoinPath", "Reading", "Role", "RoleRef", "RoleSequence", "RoleValue", "SetComparisonRoles", "Unit", "UnitBasis", "ValueRestriction"],
  "OilSupplyWithCosts" => ["AcceptableSubstitutes", "Month", "ProductionForecast", "RegionalDemand", "TransportRoute"],
  "Orienteering" => ["Club", "Entry", "Event", "EventControl", "EventScoringMethod", "Map", "Person", "Punch", "PunchPlacement", "Series", "Visit"],
  "Warehousing" => ["Bin", "DirectOrderMatch", "DispatchItem", "Party", "Product", "PurchaseOrder", "PurchaseOrderItem", "ReceivedItem", "SalesOrder", "SalesOrderItem", "TransferRequest", "Warehouse"]
}

describe "Relational Composition from NORMA" do
  #Dir["examples/norma/B*.orm"].each do |orm_file|
  #Dir["examples/norma/Ins*.orm"].each do |orm_file|
  Dir["examples/norma/*.orm"].each do |orm_file|
    sql_tables = Exceptions[File.basename(orm_file, ".orm")]
    if !sql_tables
      sql_file_pattern = orm_file.sub(/\.orm\Z/, '*.sql')
      sql_files = Dir[sql_file_pattern]
      next unless sql_files.size > 0
    end

    it "should load #{orm_file} and compute #{
        sql_tables ? "the expected lost of tables" :
          "a list of tables similar to those in #{sql_files[0]}"
      }" do

      vocabulary = ActiveFacts::Input::ORM.readfile(orm_file)

      # Get the list of tables from NORMA's SQL:
      sql_tables ||= File.open(sql_files[0]) do |f|
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

      # Get the list of tables from our composition:
      composition = vocabulary.tables.map{|o| o.name }.sort

      # Save the actual and expected composition to files
      actual_tables = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.tables')
      File.open(actual_tables, "w") { |f| f.puts composition*"\n" }
      norma_tables = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.norma.tables')
      File.open(norma_tables, "w") { |f| f.puts sql_tables*"\n" }

      if false && composition != sql_tables
        #puts "="*20 + " reasons " + "="*20
        # Show only the reasons for the differences:
        #((composition+sql_tables).uniq-(composition&sql_tables)).
        # Show the reasons for all entity types:
        vocabulary.
        all_feature.
        select{|f| EntityType === f || f.independent }.
        map{|f| f.name}.
        sort.
        each do |concept_name|
          concept = vocabulary.constellation.Feature(concept_name, vocabulary)
          puts "#{concept_name}:\n\t#{concept.dependency_reasons*"\n\t"}"
        end
      end

      composition.should == sql_tables

      File.delete(actual_tables)
      File.delete(norma_tables)
    end
  end
end
