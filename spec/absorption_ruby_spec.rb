#
# ActiveFacts tests: Compare column lists created by aborption and by generated Ruby.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'spec/spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/orm'
require 'activefacts/persistence'
require 'activefacts/generate/ruby'

include ActiveFacts

describe "Column lists from absorption compared with Ruby's" do
  ABSORPTION_RUBY_FAILURES = {
    "Metamodel" => "Overlaps with ActiveFacts Metamodel",
    "MetamodelNext" => "Overlaps with ActiveFacts Metamodel",
    "ServiceDirector" => "Lacks standard AutoTimestamp class",
    "UnaryIdentification" => "No PI for VisitStatus",
  }

  # Generate and return the Ruby for the given vocabulary
  def ruby(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::RUBY.new(vocabulary.constellation, "sql")
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/norma/#{pattern}.orm"].each do |orm_file|
    expected_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'examples/ruby/\1.rb')
    actual_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.rb')

    it "should load #{orm_file} and generate relational composition and Ruby with matching column names" do
      vocabulary = ActiveFacts::Input::ORM.readfile(orm_file)

      # Get the list of tables from the relational composition:
      absorption_tables = vocabulary.tables.sort_by(&:name)
      absorption_table_names = absorption_tables.map{|at| at.name.gsub(/\s/,'')}

      # Build the Ruby and eval it:
      ruby_text = ruby(vocabulary)
      File.open(actual_file, "w") { |f| f.write ruby_text }

      broken = ABSORPTION_RUBY_FAILURES[File.basename(orm_file, ".orm")]
      eval_it = lambda { Object.send :eval, ruby_text }
      if broken
        pending(broken) {
          lambda {
            eval_it.call
          }.should_not raise_error
        }
      else
        lambda {
            eval_it.call
        }.should_not raise_error
      end

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
      ruby_table_names.should_not differ_from(absorption_table_names)

      # Clean up:
      Object.send :remove_const, vocabulary.name.to_sym
      File.delete(actual_file)  # It succeeded, we don't need the file.
    end
  end
end
