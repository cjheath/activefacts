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
require 'activefacts/dump'
require "pp"
include ActiveFacts

model = ActiveFacts::Norma.read(ARGV[0])

model.dump
