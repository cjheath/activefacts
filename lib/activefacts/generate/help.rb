#
#       ActiveFacts Generators.
#       Provides help for afgen - from afgen --help
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    # Generate nothing from an ActiveFacts vocabulary. This is useful to check the file can be read ok.
    # Invoke as
    #   afgen --null <file>.cql
    class HELP
    private
      def initialize(vocabulary, *options)
        puts %Q{
Usage: afgen --generator[=options] file.inp[=options]
        options are comma-separated lists. Use =help to get more information.

Available generators are:
        #{$:.map{|path|
            Dir[path+"/activefacts/generate/**.rb"].map{|p|
                p.sub(%r{.*/}, '').sub(/\.rb/,'')
            }
        }.flatten.uniq.sort.join("\n\t")
}

inp is the name of a file input handler. Available input handlers are:
        #{$:.map{|path|
            Dir[path+"/activefacts/input/**.rb"].map{|p|
                p.sub(%r{.*/}, '').sub(/\.rb/,'')
            }
        }.flatten.uniq.sort.join("\n\t")
}
}
      end

    public
      def generate(out = $>)
      end
    end
  end
end

