#
#       ActiveFacts Generators.
#       Provides version number from the --version option
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    # Generate nothing from an ActiveFacts vocabulary. This is useful to check the file can be read ok.
    # Invoke as
    #   afgen --null <file>.cql
    class VERSION
    private
      def initialize(vocabulary, *options)
        puts ActiveFacts::VERSION
        exit 0
      end

    public
    end
  end
end

ActiveFacts::Registry.generator('version', ActiveFacts::Generate::VERSION)
