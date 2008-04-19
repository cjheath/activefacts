require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/norma'
require 'activefacts/generate/cql'

describe "Norma Loader" do
  # Generate and return the CQL for the given vocabulary
  def cql(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::CQLDumper.new(vocabulary.constellation)
    @dumper.dump(output)
    output.rewind
    output.readlines
  end

  Dir["examples/norma/*.orm"].each do |norma|
  #Dir["examples/norma/Bl*.orm"].each do |norma|
    expected_file = norma.sub(%r{/norma/(.*).orm\Z}, '/output/\1.cql')
    next unless File.exists? expected_file

    it "should load and dump valid CQL for #{norma}" do
      vocabulary = ActiveFacts::Norma.read(norma)

      cql(vocabulary).sort.should == File.open(expected_file) {|f| f.readlines}.sort
    end
  end
end
