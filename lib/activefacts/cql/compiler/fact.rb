module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class Fact
        def initialize readings
          @readings = readings
        end

        def compile constellation, vocabulary
          puts "REVISIT: Fact Instances are not yet compiled: #{@readings.inspect}"
        end
      end

    end
  end
end
