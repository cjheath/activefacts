#
# ActiveFacts test:
#
# Parse all NORMA files, compute the composition (list of tables)
# and compare that with NORMA's output.
#
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/persistence'
require 'activefacts/support'
require 'activefacts/input/orm'

# The exceptions table is keyed by the model name, and contains the added and removed table names vs NORMA
orm_failures = {
}
norma_table_exceptions = {
  "Metamodel" => [%w{Query}, %w{Agreement Enforcement}],          # ActiveFacts absorbs Agreement into ContextNote, Enforcement into Constraint
  "MetamodelNext" => [[], %w{Agreement Enforcement TypeInheritance}],
  "Orienteering" => [%w{Punch}, []],                                # NORMA doesn't make a table for the IDENTITY field
  "OrienteeringER" => [%w{SeriesEvent}, []],                        # NORMA doesn't make a table for the IDENTITY field
  "RedundantDependency" => [%w{Politician StateOrProvince}, %w{LegislativeDistrict}],   # NORMA doesn't make a table for the 3 IDENTITY fields
  "Warehousing" => [%w{Product Warehouse}, []],                     # NORMA doesn't make a table for the IDENTITY field
  "ServiceDirector" => [%w{DataStoreService MonitorNotificationUser}, %w{DataStoreFileHostSystem }],
  "SeparateSubtype" => [%w{Claim}, %w{Incident}],
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
  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/norma/#{pattern}.orm"].each do |orm_file|
    exception = norma_table_exceptions[File.basename(orm_file, ".orm")]
    sql_file_pattern = orm_file.sub(/\.orm\Z/, '.*sql')
    sql_file = Dir[sql_file_pattern][0]
    next unless sql_file
    base = File.basename(orm_file, ".orm")

    it "should load #{orm_file} and compute #{
        (exception ? "a modified" :  "the same") + " list of tables similar to those in #{sql_file}"
      }" do

      # Read the ORM file:
      begin
        vocabulary = ActiveFacts::Input::ORM.readfile(orm_file)
      rescue => e
        raise unless orm_failures.include?(base)
        pending orm_failures[base]
      end

      # Get the list of tables from NORMA's SQL:
      expected_tables = extract_created_tables_from_sql(sql_file)
      if exception
        expected_tables = expected_tables + exception[0] - exception[1]
      end

      # Get the list of tables from our composition:
      tables = vocabulary.tables
      table_names = tables.map{|o| o.name.gsub(/\s/,'')}.sort

      # Save the actual and expected composition to files
      actual_tables_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.tables')
      File.open(actual_tables_file, "w") { |f| f.puts table_names*"\n" }
      expected_tables_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.expected.tables')
      File.open(expected_tables_file, "w") { |f| f.puts expected_tables*"\n" }

      # Check that the list matched:
      table_names.should_not differ_from(expected_tables)

      # Calculate the columns and column names; REVISIT: check the results
      tables.each do |table|
        table.columns
      end

      File.delete(actual_tables_file)
      File.delete(expected_tables_file)
    end
  end
end
