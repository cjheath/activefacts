#
# ActiveFacts tests: Compare column lists created by aborption and by generated Ruby.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'

describe "Requiring vocabularies in Ruby" do
  ruby_failures = {
    "MetamodelNext" => "Has a duplicate role name",
  }
  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/ruby/#{pattern}.rb"].each do |ruby_file|
    base = File.basename(ruby_file, ".rb")
    next if ruby_failures.include?(base)
    it "#{ruby_file} should load cleanly" do
      require ruby_file
    end
  end
end
