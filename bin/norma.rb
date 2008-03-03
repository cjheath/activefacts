#
# Read an ORM2 model from a NORMA file
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
$:.unshift File.dirname(File.expand_path(__FILE__))+"/../lib"

require 'rubygems'
require 'active_support'
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

model = ActiveFacts::Norma.read(arg)

model.dump
#model.preferred_ids.each{|c| puts "#{c}" }
#model.dump_entity_types
#model.dump_fact_types
