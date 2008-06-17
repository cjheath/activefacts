#
# Generate text output for ActiveFacts vocabularies.
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
module ActiveFacts
  module Generate
    class NULL
      def initialize(vocabulary)
        @vocabulary = vocabulary
      end

      def generate(out = $>)
      end
    end
  end
end

