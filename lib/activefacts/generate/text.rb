#
#       ActiveFacts Generators.
#       Generate text output (verbalise the meta-vocabulary) for ActiveFacts vocabularies.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Generate
    # Generate a text verbalisation of the metamodel constellation created for an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --text <file>.cql
    class TEXT
    private
      def initialize(vocabulary)
        @vocabulary = vocabulary
        @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
      end

    public
      def generate(out = $>)
        out.puts @vocabulary.constellation.verbalise
      end
    end
  end
end

ActiveFacts::Registry.generator('text', ActiveFacts::Generate::TEXT)
