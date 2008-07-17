#
# ActiveFacts tests: Parse all CQL files and check the generated Ruby.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/orm'
require 'activefacts/generate/ruby'

include ActiveFacts

class String
  def strip_comments()
    c_comment = %r{/\*((?!\*/).)*\*/}m
    gsub(c_comment, '').gsub(%r{\n\n+},"\n")
  end
end

describe "NORMA Loader with Ruby output" do
  # Generate and return the Ruby for the given vocabulary
  def ruby(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::RUBY.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  #Dir["examples/norma/Bl*.orm"].each do |norma|
  #Dir["examples/norma/Meta*.orm"].each do |norma|
  #Dir["examples/norma/[ACG]*.orm"].each do |norma|
  Dir["examples/norma/*.orm"].each do |norma|
    expected_file = norma.sub(%r{examples/norma/(.*).orm\Z}, 'examples/ruby/\1.rb')
    actual_file = norma.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.rb')
    next unless File.exists? expected_file

    it "should load ORM and dump valid Ruby for #{norma}" do
      vocabulary = ActiveFacts::Input::ORM.readfile(norma)

      # Build and save the actual file:
      ruby_text = ruby(vocabulary)
      File.open(actual_file, "w") { |f| f.write ruby_text }

      ruby_text.should == File.open(expected_file) {|f| f.read }
      File.delete(actual_file)  # It succeeded, we don't need the file.
    end
  end
end
