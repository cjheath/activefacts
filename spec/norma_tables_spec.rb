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

describe "Relational Composition from NORMA" do
  #Dir["examples/norma/Bl*.orm"].each do |orm_file|
  #Dir["examples/norma/[AC]*.orm"].each do |orm_file|
  #Dir["examples/norma/Comp*r.orm"].each do |orm_file|
  Dir["examples/norma/Comp*e.orm"].each do |orm_file|
  #Dir["examples/norma/Ins*.orm"].each do |orm_file|
  #Dir["examples/norma/Meta*.orm"].each do |orm_file|
  #Dir["examples/norma/OilSupply.*orm"].each do |orm_file|
  #Dir["examples/norma/*.orm"].each do |orm_file|
    sql_file_pattern = orm_file.sub(/\.orm\Z/, '*.sql')
    sql_files = Dir[sql_file_pattern]
    next unless sql_files.size > 0

    it "should load #{orm_file} and compute a list of tables similar to those in #{sql_files[0]}" do
      pending
      vocabulary = ActiveFacts::Input::ORM.readfile(orm_file)

      # Get the list of tables from NORMA's SQL:
      sql_tables = File.open(sql_files[0]) do |f|
        f.
        readlines.
        select do |l|
          l =~ /CREATE TABLE/
        end.
        map do |l|
          l.chomp.gsub(/.*CREATE TABLE\s+\W*(\w+\.)?(\w+).*/, '\2')
        end.
        sort
      end

      # Get the list of tables from our composition:
      composition = vocabulary.
        constellation.
        Concept.
        values.
        select do |o|
          !(ValueType === o && o.supertype && o.supertype.name == 'TrueOrFalseLogical' and o.all_role.size == 0) and
          o.independent?
        end.
        sort_by do |o|
          o.name
        end.
        map do |o|
          o.name
        end

      # Save the actual and expected composition to files
      actual_tables = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.tables')
      File.open(actual_tables, "w") { |f| f.puts composition*"\n" }
      norma_tables = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.norma.tables')
      File.open(norma_tables, "w") { |f| f.puts sql_tables*"\n" }

      if composition != sql_tables
        puts "="*20 + " reasons " + "="*20
        # Show only the reasons for the differences:
        #((composition+sql_tables).uniq-(composition&sql_tables)).
        # Show the reasons for all entity types:
        vocabulary.
        all_feature.
        select{|f| EntityType === f || f.independent? }.
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
