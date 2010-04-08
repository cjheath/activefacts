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

          # If a reading matched but the match left extra adjectives, we need to make a new RoleSequence for them:
          matched_readings.each do |reading|
            reading.adjust_for_match
          end

          @readings.each do |reading|
            reading.make_embedded_presence_constraints vocabulary
          end

          # Objectify the fact type if necessary:
          if @name
            if @fact_type.entity_type and @name != @fact_type.entity_type.name
              raise "Cannot objectify fact type as #{@name} and as #{@fact_type.entity_type.name}"
            end
            constellation.EntityType(vocabulary, @name, :fact_type => @fact_type)
          end

          # REVISIT: This isn't the thing to do long term; it needs to be added later only if we find no other constraint
          make_default_identifier_for_fact_type vocabulary

          true
        end

        def make_default_identifier_for_fact_type(vocabulary, prefer = true)
          return if @fact_type.all_role.size == 1 && !@fact_type.entity_type     # Non-objectified unaries don't need a PI

          # REVISIT: It's possible that this fact type is objectified and inherits identification through a supertype.

          # If there's a preferred alethic uniqueness constraint over the fact type already, we're done
          return if @fact_type.all_role.
            detect do |r|
              r.all_role_ref.detect do |rr|
                rr.role_sequence.all_presence_constraint.detect do |pc|
                  pc.max_frequency == 1 && !pc.enforcement && pc.is_preferred_identifier
                end
              end
            end

          # If there's an existing presence constraint that can be converted into a PC, do that:
          @readings.each do |reading|
            rr = reading.role_refs[-1] or next
            epc = rr.embedded_presence_constraint or next
            epc.max_frequency == 1 or next
            next if epc.enforcement
            epc.is_preferred_identifier = true
            return
          end

          raise "Fact type must be named as it has no identifying uniqueness constraint" unless @name || @fact_type.all_role.size == 1
          vocabulary.constellation.PresenceConstraint(
            :new,
            :vocabulary => vocabulary,
            :name => @fact_type.entity_type ? @fact_type.entity_type.name+"PK" : '',
            :role_sequence => @fact_type.preferred_reading.role_sequence,
            :is_preferred_identifier => true,
            :max_frequency => 1,
            :is_preferred_identifier => prefer
          )
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
