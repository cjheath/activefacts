module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class FactType < Concept
        attr_reader :fact_type
        attr_writer :name

        def initialize name, readings, conditions = nil, returning = nil
          super name
          @readings = readings
          @conditions = conditions
          @returning = returning
        end

        def compile constellation, vocabulary
          raise "Queries not yet handled" unless @conditions.empty? and !@returning

          #
          # Process:
          # * Identify all role players
          # * Match up the players in all @readings
          #   - Be aware of multiple roles with the same player, and bind tight/loose using subscripts/role_names/adjectives
          #   - Reject the fact type unless all @readings match
          # * Find any existing fact type that matches any reading, or make a new one
          # * Add each reading that doesn't already exist in the fact type
          # * Create any ring constraint(s)
          # * Create embedded presence constraints
          # * If fact type has no identifier, arrange to create the implicit one (before first use?)
          # * Objectify the fact type if @name
          #

          context = CompilationContext.new(vocabulary)
          @readings.each{ |reading| reading.identify_players_with_role_name(context) }
          @readings.each{ |reading| reading.identify_other_players(context) }
          @readings.each{ |reading| reading.bind_roles context }  # Create the Compiler::Roles

          # REVISIT: Loose binding goes here; it might merge some Compiler#Roles

          verify_matching_roles # All readings of a fact type must have the same roles

          matched_readings = @readings.select{ |reading| reading.match_existing_fact_type context }
          fact_types = matched_readings.map{ |reading| reading.fact_type }.uniq
          raise "Clauses match different existing fact types" if fact_types.size > 1
          @fact_type = fact_types[0]

          # Ignore any useless readings:
          @readings.reject!{|reading| reading.is_existential_type }
          return true unless @readings.size > 0   # Nothing interesting was said.

          unless @fact_type
            first_reading = @readings[0]
            @fact_type = first_reading.make_fact_type(vocabulary)
            first_reading.make_reading(vocabulary, @fact_type)
          end

          @readings.each do |reading|
            unless reading.fact_type
              reading.make_reading(vocabulary, @fact_type)
            end
          end

          matched_readings.each{ |reading| reading.adjust_for_match }

          true
        end

        def verify_matching_roles
          readings_by_roles =
            @readings.inject({}) do |hash, reading|
              roles = reading.role_refs.map{|rr| rr.role}
              raise "Fact types may not have duplicate roles" if roles.uniq.size < roles.size
              (hash[roles.sort] ||= []) << reading
              hash
            end
          unless readings_by_roles.size == 1
            raise "All readings in a fact type definition must have the same role players compare (#{
                readings_by_roles.keys.map do |key|
                  key.map{|k| k.inspect}*", "
                end*") with ("
              })"
          end
        end
      end

    end
  end
end
