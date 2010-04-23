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

        def compile
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

          context = CompilationContext.new(@vocabulary)
          @readings.each{ |reading| reading.identify_players_with_role_name(context) }
          @readings.each{ |reading| reading.identify_other_players(context) }
          @readings.each{ |reading| reading.bind_roles context }  # Create the Compiler::Bindings

          # REVISIT: Loose binding goes here; it might merge some Compiler#Roles

          verify_matching_roles # All readings of a fact type must have the same roles

          # Ignore any useless readings:
          @readings.reject!{|reading| reading.is_existential_type }
          return true unless @readings.size > 0   # Nothing interesting was said.

          # See if any existing fact type is being invoked (presumably to objectify it)
          existing_readings = @readings.select{ |reading| reading.match_existing_fact_type context }
          fact_types = existing_readings.map{ |reading| reading.fact_type }.uniq
          raise "Clauses match different existing fact types" if fact_types.size > 1
          @fact_type = fact_types[0]

          # If not, make a new fact type:
          unless @fact_type
            first_reading = @readings[0]
            @fact_type = first_reading.make_fact_type(@vocabulary)
            first_reading.make_reading(@vocabulary, @fact_type)
            first_reading.make_embedded_presence_constraints vocabulary
            existing_readings = [first_reading]
          end

          # Now make any new readings:
          (@readings - existing_readings).each do |reading|
            reading.make_reading(@vocabulary, @fact_type)
            reading.make_embedded_presence_constraints vocabulary
          end

          # If a reading matched but the match left extra adjectives, we need to make a new RoleSequence for them:
          existing_readings.each do |reading|
            reading.adjust_for_match
          end

          # Objectify the fact type if necessary:
          if @name
            if @fact_type.entity_type and @name != @fact_type.entity_type.name
              raise "Cannot objectify fact type as #{@name} and as #{@fact_type.entity_type.name}"
            end
            @constellation.EntityType(@vocabulary, @name, :fact_type => @fact_type)
          end

          # REVISIT: This isn't the thing to do long term; it needs to be added later only if we find no other constraint
          make_default_identifier_for_fact_type

          true
        end

        def make_default_identifier_for_fact_type(prefer = true)
          # Non-objectified unaries don't need a PI:
          return if @fact_type.all_role.size == 1 && !@fact_type.entity_type

          # It's possible that this fact type is objectified and inherits identification through a supertype.
          return if @fact_type.entity_type and @fact_type.entity_type.all_type_inheritance_as_subtype.detect{|ti| ti.provides_identification}

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

          # REVISIT: We need to check uniqueness constraints after processing the whole vocabulary
          # raise "Fact type must be named as it has no identifying uniqueness constraint" unless @name || @fact_type.all_role.size == 1

          @constellation.PresenceConstraint(
            :new,
            :vocabulary => @vocabulary,
            :name => @fact_type.entity_type ? @fact_type.entity_type.name+"PK" : '',
            :role_sequence => @fact_type.preferred_reading.role_sequence,
            :is_preferred_identifier => true,
            :max_frequency => 1,
            :is_preferred_identifier => prefer
          )
        end

        def verify_matching_roles
          readings_by_role_refs =
            @readings.inject({}) do |hash, reading|
              keys = reading.role_refs.map{|rr| rr.key.map{|k| k || ''}}.sort
              raise "Fact types may not have duplicate roles" if keys.uniq.size < keys.size
              (hash[keys] ||= []) << reading
              hash
            end

          if readings_by_role_refs.size != 1
            raise "All readings in a fact type definition must have the same role players compare (#{
                readings_by_role_refs.keys.map do |keys|
                  keys.map{|key| key.select{|k| !k.empty?}*"-" }*", "
                end*") with ("
              })"
          end
        end
      end

    end
  end
end
