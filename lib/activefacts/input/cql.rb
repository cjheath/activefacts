#       Compile a CQL file into an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/cql/parser'
require 'activefacts/cql/compiler'

module ActiveFacts
  module Input #:nodoc:
    # Compile CQL to an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --<generator> <file>.cql
    class CQL
      # Read the specified file
      def self.readfile(filename)
        File.open(filename) {|file|
          read(file, filename)
        }
      rescue => e
        puts e.message+"\n\t"+e.backtrace*"\n\t" if debug :exception
        raise "In #{filename} #{e.message.strip}"
      end

      # Read the specified input stream
      def self.read(file, filename = "stdin")
        readstring(file.read, filename)
      end 

      # Read the specified input string
      def self.readstring(str, filename = "string")
        ActiveFacts::CQL::Compiler.new(str, filename).vocabulary
      end 
    end
  end
end
