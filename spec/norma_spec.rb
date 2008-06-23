#
# ActiveFacts tests: Parse all NORMA files and check the generated CQL.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/orm'
require 'activefacts/generate/cql'

include ActiveFacts

describe "Norma Loader" do
  # Generate and return the CQL for the given vocabulary
  def cql(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::CQL.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.readlines
  end

  #Dir["examples/norma/Bl*.orm"].each do |norma|
  #Dir["examples/norma/Meta*.orm"].each do |norma|
  #Dir["examples/norma/[AC]*.orm"].each do |norma|
  Dir["examples/norma/*.orm"].each do |norma|
    expected_file = norma.sub(%r{/norma/(.*).orm\Z}, '/CQL/\1.cql')
    next unless File.exists? expected_file

    actual_file = norma.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.cql')

    it "should load and dump valid CQL for #{norma}" do
      vocabulary = ActiveFacts::Input::ORM.readfile(norma)

      cql = cql(vocabulary)
      # Save the actual file:
      File.open(actual_file, "w") { |f| f.write cql*"" }

      cql.should == File.open(expected_file) {|f| f.readlines}
    end
  end
end
