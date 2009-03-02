

# ActiveFacts tests: Compare column lists created by aborption and by generated Ruby.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/orm'
require 'activefacts/persistence'
require 'activefacts/generate/ruby'

include ActiveFacts

describe "Column lists from absorption compared with Ruby's" do
  ABSORPTION_RUBY_FAILURES = %w{
    XXMetamodel
  }

  # Generate and return the Ruby for the given vocabulary
  def ruby(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::RUBY.new(vocabulary.constellation, "sql")
    @dumper.generate(output)
    output.rewind
    output.read
  end

  #Dir["examples/norma/Add*.orm"].each do |orm_file|
  #Dir["examples/norma/Bl*.orm"].each do |orm_file|
  #Dir["examples/norma/Death.orm"].each do |orm_file|
  #Dir["examples/norma/Genealogy*.orm"].each do |orm_file|
  #Dir["examples/norma/Insu*.orm"].each do |orm_file|
  #Dir["examples/norma/Metamodel.orm"].each do |orm_file|
  #Dir["examples/norma/OrienteeringER.orm"].each do |orm_file|
  #Dir["examples/norma/Test*.orm"].each do |orm_file|
  #Dir["examples/norma/[ACG]*.orm"].each do |orm_file|

  Dir["examples/norma/*.orm"].each do |orm_file|
    expected_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'examples/ruby/\1.rb')
    actual_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.rb')

    it "should load #{orm_file} and generate relational composition and Ruby with matching column names" do
      pending if ABSORPTION_RUBY_FAILURES.include? File.basename(orm_file, ".orm")
      vocabulary = ActiveFacts::Input::ORM.readfile(orm_file)

      # Get the list of tables from the relational composition:
      absorption_tables = vocabulary.tables.sort_by(&:name)
      absorption_table_names = absorption_tables.map{|at| at.name}

      # Build the Ruby and eval it:
      ruby_text = ruby(vocabulary)
      File.open(actual_file, "w") { |f| f.write ruby_text }
      Object.send :eval, ruby_text

      # Get a list of table classes in the new module, sorted by name
      mod = eval(vocabulary.name)
      ruby_tables = mod.constants.map{|n|
          c = mod.const_get(n)
          c.class == Class && c.is_table ? c : nil
        }.compact.sort_by{|c|
          c.basename
        }
      ruby_table_names = ruby_tables.map{|c| c.basename}

      # Assert that the list of tables is the same:
      ruby_table_names.should == absorption_table_names

      # So we get to see the full differences, figure them here and assert them to be empty:
      diffs = {}
      ruby_tables.each{|rt|
        next unless rt.is_entity_type
        absorption_table = absorption_tables.select{|at| at.name == rt.basename}[0]
        absorption_columns = absorption_table.columns.map{|c| c.name("").downcase}.sort
        ruby_columns = rt.columns.map{|c| c.gsub(/\./,'').downcase}.sort
        missing = absorption_columns - ruby_columns
        extra = ruby_columns - absorption_columns
        unless missing.empty? and extra.empty?
          diffs[rt.basename] = missing.map{|m| "-"+m} + extra.map{|e| '+'+e}
        end
      }
      diffs.should == {}

      # Clean up:
      Object.send :remove_const, vocabulary.name.to_sym
      File.delete(actual_file)  # It succeeded, we don't need the file.
    end
  end
end
