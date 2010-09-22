#! /usr/bin/env ruby
#
#       ActiveFacts: Interactive IRB command-line for DataMapper models
#
# Copyright (c) 2010 Clifford Heath. Read the LICENSE file.
#
require 'dm-core'

if ARGV[0] == '-l'
  DataMapper::Logger.new($stdout, :debug)
  ARGV.shift
end
DataMapper.setup(:default, 'sqlite::memory:')

require ARGV.shift

DataMapper.finalize

require 'dm-migrations'

DataMapper.auto_migrate!

require 'irb'

IRB.start(__FILE__)
