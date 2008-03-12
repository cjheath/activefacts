#
# Read an ORM2 Vocabulary from a NORMA file
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
$:.unshift File.dirname(File.expand_path(__FILE__))+"/../lib"

require 'rubygems'
require 'activefacts'
require 'activefacts/norma'
require "pp"
include ActiveFacts

arg = ARGV.shift
generator = "text"
if arg =~ /^--(.*)/
  generator = $1
  arg = ARGV.shift
end
require "activefacts/generate/#{generator}"

vocabulary = ActiveFacts::Norma.read(arg)

vocabulary.dump
#vocabulary.preferred_ids.each{|c| puts "#{c}" }
#vocabulary.dump_entity_types
#vocabulary.dump_fact_types
