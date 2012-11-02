#
# ActiveFacts tests: Parse all CQL files and check the generated Ruby.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/persistence'
require 'activefacts/input/orm'
require 'activefacts/generate/sql/server'

describe "NORMA Loader with SQL output" do
  orm_failures = {
    "SubtypePI" => "Has an illegal uniqueness constraint",
  }
  # Generate and return the SQL for the given vocabulary
  def sql(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::SQL::SERVER.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/norma/#{pattern}.orm"].each do |orm_file|
    expected_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'examples/SQL/\1.sql')
    actual_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.sql')
    base = File.basename(orm_file, ".orm")

    it "should load #{orm_file} and dump SQL matching #{expected_file}" do
      begin
        vocabulary = ActiveFacts::Input::ORM.readfile(orm_file)
      rescue => e
        raise unless orm_failures.include?(base)
        pending orm_failures[base]
      end

      # Build and save the actual file:
      sql_text = sql(vocabulary)
      File.open(actual_file, "w") { |f| f.write sql_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }
      sql_text.gsub!(/ INDEX (\[[^\]]*\]|`[^`]*`|[^ ]*) ON /, ' INDEX <Name is hidden> ON ')
      expected_text.gsub!(/ INDEX (\[[^\]]*\]|`[^`]*`|[^ ]*) ON /, ' INDEX <Name is hidden> ON ')
      sql_text.should_not differ_from(expected_text)
      File.delete(actual_file)  # It succeeded, we don't need the file.
    end
  end
end
