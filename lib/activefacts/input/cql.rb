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
        # Augment the exception message, but preserve the backtrace
        ne = StandardError.new("In #{filename} #{e.message.strip}")
        ne.set_backtrace(e.backtrace)
        raise ne
      end

      # Read the specified input stream
      def self.read(file, filename = "stdin")
        readstring(file.read, filename)
      end 

      # Read the specified input string
      def self.readstring(str, filename = "string")
        compiler = ActiveFacts::CQL::Compiler.new(str, filename)
        compiler.compile
      end 
    end
  end
end
