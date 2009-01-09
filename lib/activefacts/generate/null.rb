#
# Generate text output for ActiveFacts vocabularies.
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    class NULL
      def initialize(vocabulary, *options)
        @vocabulary = vocabulary
        @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
        @tables = options.include? "tables"
        @columns = options.include? "columns"
        @indices = options.include? "indices"
      end

      def generate(out = $>)
        @vocabulary.tables if @tables || @columns || @indices
      end
    end
  end
end

