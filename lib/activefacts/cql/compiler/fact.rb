module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class Fact < Definition
        def initialize readings
          @readings = readings
        end

        def compile
          puts "REVISIT: Fact Instances are not yet compiled: #{@readings.inspect}"
        end
      end

    end
  end
end
