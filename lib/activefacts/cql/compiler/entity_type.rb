module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class EntityType < Concept
        def initialize name, supers, identification, pragmas, conditions
          super name
          @supers = supers
          @identification = identification
          @pragmas = pragmas
          @conditions = conditions
        end

        def compile constellation, vocabulary
        end
      end

    end
  end
end

