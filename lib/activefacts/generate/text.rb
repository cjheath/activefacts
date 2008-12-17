#
# Generate text output for ActiveFacts vocabularies.
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
module ActiveFacts
  module Generate
    class TEXT
      def initialize(vocabulary)
        @vocabulary = vocabulary
        @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
      end

      def generate(out = $>)
        out.puts @vocabulary.constellation.verbalise
      end
    end
  end
end

