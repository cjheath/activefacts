#
#       ActiveFacts Vocabulary Metamodel.
#       Verbaliser for the ActiveFacts Vocabulary
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Metamodel

    class Join
      class Verbaliser
        attr_reader :join, :role_refs
        attr_reader :join_nodes                 # All Join Nodes
        attr_reader :join_steps                 # All remaining unemitted Join Steps
        attr_reader :join_steps_by_join_node    # A Hash by Join Node containing an array of remaining steps

        def initialize join, role_refs
          @join = join
          @role_refs = role_refs
          @join_nodes = join.all_join_node.sort_by{|jn| jn.ordinal}
          @join_steps = @join_nodes.map{|jn| jn.all_join_step_as_input_join_node.to_a + jn.all_join_step_as_output_join_node.to_a }.flatten.uniq
          @join_steps_by_join_node = @join_nodes.
            inject({}) do |h, jn|
              jn.all_join_step_as_input_join_node.each{|js| (h[jn] ||= []) << js}
              jn.all_join_step_as_output_join_node.each{|js| (h[jn] ||= []) << js}
              h
            end
        end

        # Remove this step now that we've processed it:
        def step_completed(step)
          @join_steps.delete(step)

          input_node = step.input_join_node
          steps = @join_steps_by_join_node[input_node]
          steps.delete(step)
          @join_steps_by_join_node.delete(input_node) if steps.empty?

          output_node = step.output_join_node
          if (input_node != output_node)
            steps = @join_steps_by_join_node[output_node]
            steps.delete(step)
            @join_steps_by_join_node.delete(output_node) if steps.empty?
          end
        end

        def choose_step(next_node)
          next_steps = @join_steps_by_join_node[next_node]

          # If we don't have a next_node against which we can contract,
          # so just use any join step involving this node, or just any step.
          if next_steps
            if next_step = next_steps.detect { |ns| !ns.is_objectification_step }
              debug :join, "Chose new non-objectification step: #{next_step.describe}"
              return next_step
            end
          end

          if next_step = @join_steps.detect { |ns| !ns.is_objectification_step }
            debug :join, "Chose random non-objectification step: #{next_step.describe}"
            return next_step
          end

          next_step = @join_steps[0]
          if next_step
            debug :join, "Chose new random step from #{join_steps.size}: #{next_step.describe}"
            return next_step
          end
          raise "Internal error: There are more join steps here, but we failed to choose one"
        end

        # The join step we just emitted (using the reading given) is contractable iff
        # the reading has the next_node's role player as the final text
        def node_contractable_against_reading(next_node, reading)
          reading &&
            # Find whether last role has no following text, and its ordinal
          (reading.text =~ /\{([0-9])\}$/) &&
            # This reading's RoleRef for that role:
          (role_ref = reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i}) &&
            # was that RoleRef for the upcoming node?
          role_ref.role.all_role_ref.detect{|rr| rr.join_node == next_node}
        end

        def reading_starts_with_node(reading, next_node)
          reading.text =~ /^\{([0-9])\}/ and
            role_ref = reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i} and
            role_ref.role.all_role_ref.detect{|rr| rr.join_node == next_node}
        end

        # The last reading we emitted ended with the object type name for next_node.
        # Choose a step and a reading that can be contracted against that name
        def contractable_step(next_steps, next_node)
          next_reading = nil
          next_step =
            next_steps.detect do |js|
              next false if js.is_objectification_step
              # If we find a reading here, it can be contracted against the previous one
              next_reading =
                js.fact_type.all_reading.detect do |reading|
                  # This step is contractable iff the FactType has a reading that starts with the role of next_node (no preceding text)
                  reading_starts_with_node(reading, next_node)
                end
              next_reading
            end
          return [next_step, next_reading]
        end

        def objectification_verbalisation(concept)
          objectified_node = nil
          unless concept.is_a?(Metamodel::EntityType) and
            concept.fact_type and            # Not objectified
            objectification_step = @join_steps.
              detect do |js|
                # The objectifying entity type should always ne the input_join_node here, but be safe:
                js.is_objectification_step and
                  (objectified_node = js.input_join_node).concept == concept ||
                  (objectified_node = js.output_join_node).concept == concept
              end
            return ''
          end

          step_completed(objectification_step)
          while other_step =
            @join_steps.
              detect{|js|
                js.is_objectification_step and
                  js.input_join_node.concept == concept || js.output_join_node.concept == concept
              }
            debug :join, "Emitting objectification allows deleting #{other_step.describe}"
            step_completed(other_step)
          end

          reading = concept.fact_type.preferred_reading
          " (where #{expand_reading_text(objectification_step, reading.text, reading.role_sequence)})" 
        end

        def elided_objectification(next_step, fact_type, last_is_contractable, next_node)
          if last_is_contractable
            # Choose a reading that's contractable against the previous step, if possible
            reading = fact_type.all_reading.
              detect do |reading|
                reading_starts_with_node(reading, next_node)
              end
          end
          reading ||= fact_type.preferred_reading

          # Find which role occurs last in the reading, and which Join Node is attached
          reading.text =~ /\{(\d)\}[^{]*\Z/
          last_role_ref = reading.role_sequence.all_role_ref_in_order[$1.to_i]
          exit_node = @join_nodes.detect{|jn| jn.all_role_ref.detect{|rr| rr.role == last_role_ref.role}}
          exit_step = nil

          while other_step =
            @join_steps.
              detect{|js|
                next unless js.is_objectification_step
                next unless js.input_join_node.concept == fact_type.entity_type || js.output_join_node.concept == fact_type.entity_type
                exit_step = js if js.output_join_node == exit_node
                true
              }
            debug :join, "Emitting objectification allows deleting #{other_step.describe}"
            step_completed(other_step)
          end
          [ reading, exit_step ? exit_step.input_join_node : exit_node, exit_step]
        end

        # Expand this reading (or partial reading, during contraction)
        def expand_reading_text(step, text, role_sequence)
          rrs = role_sequence.all_role_ref_in_order
          text.gsub(/\{(\d)\}/) do
            role_ref = rrs[$1.to_i]
            # REVISIT: We need to use the step's role_refs to expand the role players here, not the reading's one
            concept = role_ref.role.concept
            [
              role_ref.leading_adjective,
              concept.name,
              role_ref.trailing_adjective,
            ].compact*' ' +
              objectification_verbalisation(concept)
          end
        end

        def expand_contracted_text(step, reading)
          ' that ' +
            expand_reading_text(step, reading.text.sub(/\A\{\d\} /,''), reading.role_sequence)
        end

        def verbalise
          readings = ''
          next_node = @role_refs[0].join_node   # Choose a place to start
          last_is_contractable = false
          debug :join, "Join Nodes are #{@join_nodes.map{|jn| jn.describe }.inspect}, Join Steps are #{@join_steps.map{|js| js.describe }.inspect}" do
            until @join_steps.empty?
              next_reading = nil
              # Choose amonst all remaining steps we can take from the next node, if any
              next_steps = @join_steps_by_join_node[next_node]
              debug :join, "Next Steps from #{next_node.describe} are #{(next_steps||[]).map{|js| js.describe }.inspect}"

              # See if we can find a next step that contracts against the last (if any):
              next_step = nil
              if last_is_contractable && next_steps
                next_step, next_reading = *contractable_step(next_steps, next_node)
              end

              if next_step
                debug :join, "Chose #{next_step.describe} because it's contractable against last node #{next_node.all_role_ref.to_a[0].role.concept.name} using #{next_reading.expand}"
                readings += expand_contracted_text(next_step, next_reading)
                step_completed(next_step)
              else
                next_step = choose_step(next_node) if !next_step

                if next_step.is_unary_step
                  # Objectified unaries get emitted as unaries, not as objectifications:
                  # REVISIT: There must be a simpler way of finding the preferred reading here:
                  rr = next_step.input_join_node.all_role_ref.detect{|rr| rr.role.fact_type.is_a?(ImplicitFactType) }
                  next_reading = rr.role.fact_type.role.fact_type.preferred_reading
                  readings += " and " unless readings.empty?
                  readings += expand_reading_text(next_step, next_reading.text, next_reading.role_sequence)
                  step_completed(next_step)
                elsif next_step.is_objectification_step
                  fact_type = next_step.fact_type.role.fact_type
                  if last_is_contractable && next_node.concept.fact_type == fact_type
                    readings += objectification_verbalisation(fact_type.entity_type)
                    debugger unless next_step.input_join_node
                  else
                    # This objectified fact type does not need to be made explicit.
                    # Need to step_completed the other steps in this OFT.
                    next_reading, next_node, next_step = *elided_objectification(next_step, fact_type, last_is_contractable, next_node)
                    if last_is_contractable
                      readings += expand_contracted_text(next_step, next_reading)
                    else
                      readings += " and " unless readings.empty?
                      readings += expand_reading_text(next_step, next_reading.text, next_reading.role_sequence)
                    end
                    # No need to continue; we might have just deleted the last step
                    break if @join_steps.empty?
                  end
                else
                  fact_type = next_step.fact_type
                  # Prefer a reading that starts with the player of next_node
                  next_reading = fact_type.all_reading.
                    detect do |reading|
                      reading.text =~ /^\{([0-9])\}/ and
                        role_ref = reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i} and
                        role_ref.role.all_role_ref.detect{|rr| rr.join_node == next_node}
                    end || fact_type.preferred_reading
                  # REVISIT: If this join step and reading has role references with adjectives, we need to expand using those
                  readings += " and " unless readings.empty?
                  readings += expand_reading_text(next_step, next_reading.text, next_reading.role_sequence)
                  step_completed(next_step)
                end
              end

              # Try to continue on the same join path:
              next_node = next_step.input_join_node != next_node ? next_step.input_join_node : next_step.output_join_node
              # Prepare for possible contraction following:
              last_is_contractable = next_reading && node_contractable_against_reading(next_node, next_reading)

            end
          end
          readings
        end
      end

    end
  end
end
