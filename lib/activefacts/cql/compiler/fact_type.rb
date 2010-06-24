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
          raise "Queries not yet handled: #{@source}" unless @conditions.empty? and !@returning

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

          @context = CompilationContext.new(@vocabulary)
          @readings.each{ |reading| reading.identify_players_with_role_name(@context) }
          @readings.each{ |reading| reading.identify_other_players(@context) }
          @readings.each{ |reading| reading.bind_roles @context }  # Create the Compiler::Bindings

          verify_matching_roles   # All readings of a fact type must have the same roles

          # Ignore any useless readings:
          @readings.reject!{|reading| reading.is_existential_type }
          return true unless @readings.size > 0   # Nothing interesting was said.

          # See if any existing fact type is being invoked (presumably to objectify or extend it)
          @fact_type = check_compatibility_of_matched_readings

          if !@fact_type
            # Make a new fact type:
            first_reading = @readings[0]
            @fact_type = first_reading.make_fact_type(@vocabulary)
            first_reading.make_reading(@vocabulary, @fact_type)
            first_reading.make_embedded_constraints vocabulary
            @fact_type.create_implicit_fact_type_for_unary if @fact_type.all_role.size == 1 && !@name
            @existing_readings = [first_reading]
          elsif (n = @readings.size - @existing_readings.size) > 0
            debug :binding, "Extending existing fact type with #{n} new readings"
          end

          # Now make any new readings:
          new_readings = @readings - @existing_readings
          new_readings.each do |reading|
            reading.make_reading(@vocabulary, @fact_type)
            reading.make_embedded_constraints vocabulary
          end

          # If a reading matched but the match left extra adjectives, we need to make a new RoleSequence for them:
          @existing_readings.each do |reading|
            reading.adjust_for_match
          end

          # Objectify the fact type if necessary:
          if @name
            if @fact_type.entity_type and @name != @fact_type.entity_type.name
              raise "Cannot objectify fact type as #{@name} and as #{@fact_type.entity_type.name}"
            end
            @constellation.EntityType(@vocabulary, @name, :fact_type => @fact_type).create_implicit_fact_types
          end

          # REVISIT: This isn't the thing to do long term; it needs to be added later only if we find no other constraint
          make_default_identifier_for_fact_type

          @readings.each do |reading|
            next unless reading.context_note
            reading.context_note.compile(@constellation, @fact_type)
          end

          @fact_type
        end

        def check_compatibility_of_matched_readings
          @existing_readings = @readings.
            select{ |reading| reading.match_existing_fact_type @context }.
            sort_by{ |reading| reading.side_effects.cost }
          fact_types = @existing_readings.map{ |reading| reading.fact_type }.uniq.compact
          if (fact_types.size > 1)
            # There must be only one fact type with exact matches:
            if @existing_readings[0].side_effects.cost != 0 or
              @existing_readings.detect{|r| r.fact_type != fact_types[0] && r.side_effects.cost == 0 }
              raise "Clauses match different existing fact types '#{fact_types.map{|ft| ft.preferred_reading.expand}*"', '"}'"
            end
            # Try to make false-matched readings match the chosen one instead
            @existing_readings.reject!{|r| r.fact_type != fact_types[0] }
          end
          fact_types[0]
        end

        def make_default_identifier_for_fact_type(prefer = true)
          # Non-objectified unaries don't need a PI:
          return if @fact_type.all_role.size == 1 && !@fact_type.entity_type

          # It's possible that this fact type is objectified and inherits identification through a supertype.
          return if @fact_type.entity_type and @fact_type.entity_type.all_type_inheritance_as_subtype.detect{|ti| ti.provides_identification}

          # If it's a non-objectified binary and there's an alethic uniqueness constraint over the fact type already, we're done
          return if !@fact_type.entity_type &&
            @fact_type.all_role.size == 2 &&
            @fact_type.all_role.
              detect do |r|
                r.all_role_ref.detect do |rr|
                  rr.role_sequence.all_presence_constraint.detect do |pc|
                    pc.max_frequency == 1 && !pc.enforcement
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
            :max_frequency => 1,
            :is_preferred_identifier => prefer
          )
        end

        def has_more_adjectives(less, more)
          return false if less.leading_adjective && less.leading_adjective != more.leading_adjective
          return false if less.trailing_adjective && less.trailing_adjective != more.trailing_adjective
          return true
        end

        def verify_matching_roles
          role_refs_by_reading_and_key = {}
          readings_by_role_refs =
            @readings.inject({}) do |hash, reading|
              keys = reading.role_refs.map do |rr|
                key = rr.key.compact
                role_refs_by_reading_and_key[[reading, key]] = rr
                key
              end.sort
              raise "Fact types may not have duplicate roles" if keys.uniq.size < keys.size
              (hash[keys] ||= []) << reading
              hash
            end

          if readings_by_role_refs.size != 1
            # Attempt loose binding here; it might merge some Compiler::RoleRefs to share the same Bindings
            variants = readings_by_role_refs.keys
            (readings_by_role_refs.size-1).downto(1) do |m|   # Start with the last one
              0.upto(m-1) do |l|                              # Try to rebind onto any lower one
                common = variants[m]&variants[l]
                readings_l = readings_by_role_refs[variants[l]]
                readings_m = readings_by_role_refs[variants[m]]
                l_keys = variants[l]-common
                m_keys = variants[m]-common
                debug :binding, "Try to collapse variant #{m} onto #{l}; diffs are #{l_keys.inspect} -> #{m_keys.inspect}"
                rebindings = 0
                l_keys.each_with_index do |l_key, i|
                  # Find possible rebinding candidates; there must be exactly one.
                  candidates = []
                  (0...m_keys.size).each do |j|
                    m_key = m_keys[j]
                    l_role_ref = role_refs_by_reading_and_key[[readings_l[0], l_key]]
                    m_role_ref = role_refs_by_reading_and_key[[readings_m[0], m_key]]
                    debug :binding, "Can we match #{l_role_ref.inspect} (#{i}) with #{m_role_ref.inspect} (#{j})?"
                    next if m_role_ref.player != l_role_ref.player
                    if has_more_adjectives(m_role_ref, l_role_ref)
                      debug :binding, "can rebind #{m_role_ref.inspect} to #{l_role_ref.inspect}"
                      candidates << [m_role_ref, l_role_ref]
                    elsif has_more_adjectives(l_role_ref, m_role_ref)
                      debug :binding, "can rebind #{l_role_ref.inspect} to #{m_role_ref.inspect}"
                      candidates << [l_role_ref, m_role_ref]
                    end
                  end

                  # debug :binding, "found #{candidates.size} rebinding candidates for this role"
                  debug :binding, "rebinding is ambiguous so not attempted" if candidates.size > 1
                  if (candidates.size == 1)
                    candidates[0][0].rebind_to(@context, candidates[0][1])
                    rebindings += 1
                  end

                end
                if (rebindings == l_keys.size)
                  # Successfully rebound this fact type
                  debug :binding, "Successfully rebound readings #{readings_l.map{|r|r.inspect}*'; '} on to #{readings_m.map{|r|r.inspect}*'; '}"
                  break
                else
                  # No point continuing, we failed on this one.
                  raise "All readings in a fact type definition must have matching role players, compare (#{
                      readings_by_role_refs.keys.map do |keys|
                        keys.map{|key| key*'-' }*", "
                      end*") with ("
                    })"
                end

              end
            end
          # else all readings already matched
          end
        end
      end

    end
  end
end
