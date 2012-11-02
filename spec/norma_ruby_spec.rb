#
# ActiveFacts tests: Parse all CQL files and check the generated Ruby.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/orm'
require 'activefacts/generate/ruby'

class String
  def strip_comments()
    c_comment = %r{/\*((?!\*/).)*\*/}m
    gsub(c_comment, '').gsub(%r{\n\n+},"\n")
  end
end

describe "NORMA Loader with Ruby output" do
  orm_failures = {
    "SubtypePI" => "Has an illegal uniqueness constraint",
  }

  # Generate and return the Ruby for the given vocabulary
  def ruby(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::RUBY.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/norma/#{pattern}.orm"].each do |orm_file|
    expected_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'examples/ruby/\1.rb')
    actual_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.rb')
    base = File.basename(orm_file, ".orm")

    it "should load #{orm_file} and dump Ruby matching #{expected_file}" do
      begin
        vocabulary = ActiveFacts::Input::ORM.readfile(orm_file)
      rescue => e
        raise unless orm_failures.include?(base)
        pending orm_failures[base]
      end

      # Build and save the actual file:
      ruby_text = ruby(vocabulary)
      File.open(actual_file, "w") { |f| f.write ruby_text }

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      expected_text = File.open(expected_file) {|f| f.read }
      ruby_text.should_not differ_from(expected_text)
      File.delete(actual_file)  # It succeeded, we don't need the file.
    end
  end
end
