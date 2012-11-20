#
#       ActiveFacts Generators.
#       Generate *no* output for ActiveFacts vocabularies; i.e. just a stub
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    # Generate nothing from an ActiveFacts vocabulary. This is useful to check the file can be read ok.
    # Invoke as
    #   afgen --null <file>.cql
    class NULL
    private
      def initialize(vocabulary, *options)
        @vocabulary = vocabulary
        @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
        @tables = options.include? "tables"
        @columns = options.include? "columns"
        @indices = options.include? "indices"
      end

    public
      def generate(out = $>)
        @vocabulary.tables if @tables || @columns || @indices
      end
    end
  end
end

ActiveFacts::Registry.generator('null', ActiveFacts::Generate::NULL)
