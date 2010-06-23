#
#       ActiveFacts Vocabulary Metamodel.
#       Extensions to the ActiveFacts Vocabulary classes (which are generated from the Metamodel)
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Metamodel

    class FactType
      def all_reading_by_ordinal
        all_reading.sort_by{|reading| reading.ordinal}
      end

      def preferred_reading
        p = all_reading_by_ordinal[0]
        raise "No reading for (#{all_role.map{|r| r.concept.name}*", "})" unless p
        p
      end

      def describe(highlight = nil)
        (entity_type ? entity_type.name : "")+
        '('+all_role.map{|role| role.describe(highlight) }*", "+')'
      end

      def default_reading(frequency_constraints = [], define_role_names = false)
        preferred_reading.expand(frequency_constraints, define_role_names)
      end

      def internal_presence_constraints
        all_role.map do |r|
          r.all_role_ref.map do |rr|
            !rr.role_sequence.all_role_ref.detect{|rr1| rr1.role.fact_type != self } ?
              rr.role_sequence.all_presence_constraint.to_a :
              []
          end
        end.flatten.compact.uniq
      end

      # This entity type has just objectified a fact type. Create the necessary ImplicitFactTypes with phantom roles
      def create_implicit_fact_type_for_unary
        role = all_role.single
        next if role.implicit_fact_type     # Already exists
        # NORMA doesn't create an implicit fact type here, rather the fact type has an implicit extra role, so looks like a binary
        # We only do it when the unary fact type is not objectified
        implicit_fact_type = @constellation.ImplicitFactType(:new, :role => role)
        entity_type = @entity_type || @constellation.ImplicitBooleanValueType(role.concept.vocabulary, "_ImplicitBooleanValueType")
        phantom_role = @constellation.Role(implicit_fact_type, 0, :concept => entity_type)
      end
    end

    class Role
      def describe(highlight = nil)
        concept.name + (self == highlight ? "*" : "")
      end

      # Is there are internal uniqueness constraint on this role only?
      def unique
        all_role_ref.detect{|rr|
          rs = rr.role_sequence
          rs.all_role_ref.size == 1 and
          rs.all_presence_constraint.detect{|pc|
            pc.max_frequency == 1
          }
        } ? true : false
      end

      def is_mandatory
        all_role_ref.detect{|rr|
          rs = rr.role_sequence
          rs.all_role_ref.size == 1 and
          rs.all_presence_constraint.detect{|pc|
            pc.min_frequency and pc.min_frequency >= 1 and pc.is_mandatory
          }
        } ? true : false
      end

      # Return the RoleRef to this role from its fact type's preferred_reading
      def preferred_reference
        fact_type.preferred_reading.role_sequence.all_role_ref.detect{|rr| rr.role == self }
      end
    end

    class Join
      def column_name(joiner = '-')
        concept == input_role.concept ? input_role.preferred_reference.role_name(joiner) : Array(concept.name)
      end

      def describe
        "#{input_role.fact_type.describe(input_role)}->" +
          concept.name +
          (output_role ? "->#{output_role.fact_type.describe(output_role)}":"")
      end
    end

    class RoleRef
      def describe
        role_name
      end

      def role_name(joiner = "-")
        name_array =
          if role.fact_type.all_role.size == 1
            role.fact_type.preferred_reading.text.gsub(/\{[0-9]\}/,'').strip.split(/\s/)
          else
            role.role_name || [leading_adjective, role.concept.name, trailing_adjective].compact.map{|w| w.split(/\s/)}.flatten
          end
        return joiner ? Array(name_array)*joiner : Array(name_array)
      end

      # Two RoleRefs are equal if they have the same role and Joins with matching roles
      def ==(role_ref)
        role_ref.is_a?(ActiveFacts::Metamodel::RoleRef) &&
        role_ref.role == role
      end
    end

    class RoleSequence
      def describe
        "("+
          all_role_ref.sort_by{|rr| rr.ordinal}.map{|rr| rr.describe }*", "+
        ")"
      end
    end

    class ValueType
      def supertypes_transitive
        [self] + (supertype ? supertype.supertypes_transitive : [])
      end

      def subtypes
        all_value_type_as_supertype
      end

      def subtypes_transitive
        [self] + subtypes.map{|st| st.subtypes_transitive}.flatten
      end
    end

    class EntityType
      def preferred_identifier
        if fact_type

          # For a nested fact type, the PI is a unique constraint over N or N-1 roles
          fact_roles = Array(fact_type.all_role)
          debug :pi, "Looking for PI on nested fact type #{name}" do
            pi = catch :pi do
                fact_roles[0,2].each{|r|                  # Try the first two roles of the fact type, that's enough
                    r.all_role_ref.map{|rr|               # All role sequences that reference this role
                        role_sequence = rr.role_sequence

                        # The role sequence is only interesting if it cover only this fact's roles
                        # or roles of the objectification
                        next if role_sequence.all_role_ref.size < fact_roles.size-1 # Not enough roles
                        next if role_sequence.all_role_ref.size > fact_roles.size   # Too many roles
                        next if role_sequence.all_role_ref.detect do |rsr|
                            if (of = rsr.role.fact_type) != fact_type
                              case of.all_role.size
                              when 1    # A unary FT must be played by the objectification of this fact type
                                next rsr.role.concept != fact_type.entity_type
                              when 2    # A binary FT must have the objectification of this FT as the other player
                                other_role = (of.all_role-[rsr.role])[0]
                                next other_role.concept != fact_type.entity_type
                              else
                                next true # A role in a ternary (or higher) cannot be usd in our identifier
                              end
                            end
                            rsr.role.fact_type != fact_type
                          end

                        # This role sequence is a candidate
                        pc = role_sequence.all_presence_constraint.detect{|c|
                            c.max_frequency == 1 && c.is_preferred_identifier
                          }
                        throw :pi, pc if pc
                      }
                  }
                throw :pi, nil
              end
            debug :pi, "Got PI #{pi.name||pi.object_id} for nested #{name}" if pi
            debug :pi, "Looking for PI on entity that nests this fact" unless pi
            raise "Oops, pi for nested fact is #{pi.class}" unless !pi || pi.is_a?(ActiveFacts::Metamodel::PresenceConstraint)
            return pi if pi
          end
        end

        debug :pi, "Looking for PI for ordinary entity #{name} with #{all_role.size} roles:" do
          debug :pi, "Roles are in fact types #{all_role.map{|r| r.fact_type.describe(r)}*", "}"
          pi = catch :pi do
              all_supertypes = supertypes_transitive
              debug :pi, "PI roles must be played by one of #{all_supertypes.map(&:name)*", "}" if all_supertypes.size > 1
              all_role.each{|role|
                  next unless role.unique || fact_type
                  ftroles = Array(role.fact_type.all_role)

                  # Skip roles in ternary and higher fact types, they're objectified, and in unaries, they can't identify us.
                  next if ftroles.size != 2

                  debug :pi, "Considering role in #{role.fact_type.describe(role)}"

                  # Find the related role which must be included in any PI:
                  # Note this works with unary fact types:
                  pi_role = ftroles[ftroles[0] != role ? 0 : -1]

                  next if ftroles.size == 2 && pi_role.concept == self
                  debug :pi, "  Considering #{pi_role.concept.name} as a PI role"

                  # If this is an identifying role, the PI is a PC whose role_sequence spans the role.
                  # Walk through all role_sequences that span this role, and test each:
                  pi_role.all_role_ref.each{|rr|
                      role_sequence = rr.role_sequence  # A role sequence that includes a possible role

                      debug :pi, "    Considering role sequence #{role_sequence.describe}"

                      # All roles in this role_sequence must be in fact types which
                      # (apart from that role) only have roles played by the original
                      # entity type or a supertype.
                      #debug :pi, "      All supertypes #{all_supertypes.map{|st| "#{st.object_id}=>#{st.name}"}*", "}"
                      if role_sequence.all_role_ref.detect{|rsr|
                          fact_type = rsr.role.fact_type
                          debug :pi, "      Role Sequence touches #{fact_type.describe(pi_role)}"

                          fact_type_roles = fact_type.all_role
                          debug :pi, "      residual is #{fact_type_roles.map{|r| r.concept.name}.inspect} minus #{rsr.role.concept.name}"
                          residual_roles = fact_type_roles-[rsr.role]
                          residual_roles.detect{|rfr|
                              debug :pi, "        Checking residual role #{rfr.concept.object_id}=>#{rfr.concept.name}"
# This next line looks right, but breaks things. Find out what and why:
#                              !rfr.unique or
                                !all_supertypes.include?(rfr.concept)
                            }
                        }
                        debug :pi, "      Discounting this role_sequence because it includes alien roles"
                        next
                      end

                      # Any presence constraint over this role sequence is a candidate
                      rr.role_sequence.all_presence_constraint.detect{|pc|
                          # Found it!
                          if pc.is_preferred_identifier
                            debug :pi, "found PI #{pc.name||pc.object_id}, is_preferred_identifier=#{pc.is_preferred_identifier.inspect} over #{pc.role_sequence.describe}"
                            throw :pi, pc
                          end
                        }
                    }
                }
              throw :pi, nil
            end
          raise "Oops, pi for entity is #{pi.class}" if pi && !pi.is_a?(ActiveFacts::Metamodel::PresenceConstraint)
          debug :pi, "Got PI #{pi.name||pi.object_id} for #{name}" if pi

          if !pi
            if (supertype = identifying_supertype)
              # This shouldn't happen now, as an identifying supertype is connected by a fact type
              # that has a uniqueness constraint marked as the preferred identifier.
              #debug :pi, "PI not found for #{name}, looking in supertype #{supertype.name}"
              #pi = supertype.preferred_identifier
              #return nil
            elsif fact_type
              fact_type.all_role.each{|role|
                role.all_role_ref.each{|role_ref|
                  # Discount role sequences that contain roles not in this fact type:
                  next if role_ref.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type != fact_type }
                  role_ref.role_sequence.all_presence_constraint.each{|pc|
                    next unless pc.is_preferred_identifier and pc.max_frequency == 1
                    pi = pc
                    break
                  }
                  break if pi
                }
                break if pi
              }
            else
              debug :pi, "No PI found for #{name}"
            end
          end
          raise "No PI found for #{name}" unless pi
          pi
        end
      end

      # An array of all direct subtypes:
      def subtypes
        # REVISIT: There's no sorting here. Should there be?
        all_type_inheritance_as_supertype.map{|ti| ti.subtype }
      end

      def subtypes_transitive
        [self] + subtypes.map{|st| st.subtypes_transitive}.flatten.uniq
      end

      def all_supertype_inheritance
        all_type_inheritance_as_subtype.sort_by{|ti|
            [ti.provides_identification ? 0 : 1, ti.supertype.name]
          }
      end

      # An array all direct supertypes
      def supertypes
        all_supertype_inheritance.map{|ti|
            ti.supertype
          }
      end

      # An array of self followed by all supertypes in order:
      def supertypes_transitive
        ([self] + all_type_inheritance_as_subtype.map{|ti|
            ti.supertype.supertypes_transitive
          }).flatten.uniq
      end

      # A subtype does not have a identifying_supertype if it defines its own identifier
      def identifying_supertype
        debug "Looking for identifying_supertype of #{name}"
        all_type_inheritance_as_subtype.detect{|ti|
            debug "considering supertype #{ti.supertype.name}"
            next unless ti.provides_identification
            debug "found identifying supertype of #{name}, it's #{ti.supertype.name}"
            return ti.supertype
          }
        debug "Failed to find identifying supertype of #{name}"
        return nil
      end

      # This entity type has just objectified a fact type. Create the necessary ImplicitFactTypes with phantom roles
      def create_implicit_fact_types
        fact_type.all_role.each do |role|
          next if role.implicit_fact_type     # Already exists
          implicit_fact_type = @constellation.ImplicitFactType(:new, :role => role)
          phantom_role = @constellation.Role(implicit_fact_type, 0, :concept => self)
          # We could create a copy of the visible external role here, but there's no need yet...
          # Nor is there a need for a presence constraint, readings, etc.
        end
      end
    end

    class Reading
      # The frequency_constraints array here, if supplied, may provide for each role either:
      # * a PresenceConstraint to be verbalised against the relevant role, or
      # * a String, used as a definite or indefinite article on the relevant role, or
      # * an array containing two strings (an article and a super-type name)
      # The order in the array is the same as the reading's role-sequence.
      # REVISIT: This should probably be changed to be the fact role sequence.
      #
      # define_role_names here is false (use defined names), true (define names) or nil (neither)
      def expand(frequency_constraints = [], define_role_names = false, literals = [])
        expanded = "#{text}"
        role_refs = role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}
        (0...role_refs.size).each{|i|
            role_ref = role_refs[i]
            role = role_ref.role
            la = "#{role_ref.leading_adjective}"
            la.sub!(/(.\b|.\Z)/, '\1-')
            la.sub!(/- /,'-  ')
            la = nil if la == ""
            ta = "#{role_ref.trailing_adjective}"
            ta.sub!(/(\b.|\A.)/, '-\1')
            ta.sub!(/ -/,'  -')   # Double the space to compensate for space removed below
            ta = nil if ta == ""

            expanded.gsub!(/\{#{i}\}/) {
                player = role_refs[i].role.concept
                role_name = role.role_name
                role_name = nil if role_name == ""
                if role_name && define_role_names == false
                  la = ta = nil   # When using role names, don't add adjectives
                end
                fc = frequency_constraints[i]
                fc = fc.frequency if fc && fc.is_a?(ActiveFacts::Metamodel::PresenceConstraint)
                if fc.is_a?(Array)
                  fc, player_name = *fc
                else
                  player_name = player.name
                end
                literal = literals[i]
                [
                  fc ? fc : nil,
                  la,
                  define_role_names == false && role_name ? role_name : player_name,
                  ta,
                  define_role_names && role_name && player.name != role_name ? "(as #{role_name})" : nil,
                  # Can't have both a literal and a value constraint, but we don't enforce that here:
                  literal ? literal : nil
                ].compact*" "
            }
        }
        expanded.gsub!(/ ?- ?/, '-')        # Remove single spaces around adjectives
        #debug "Expanded '#{expanded}' using #{frequency_constraints.inspect}"
        expanded
      end

      def words_and_role_refs
        text.
        scan(/(?: |\{[0-9]+\}|[^{} ]+)/).   # split up the text into words
        reject{|s| s==' '}.                 # Remove white space
        map do |frag|                       # and go through the bits
          if frag =~ /\{([0-9]+)\}/
            role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i}
          else
            frag
          end
        end
      end
    end

    class ValueConstraint
      def describe
        "restricted to {"+
          all_allowed_range_sorted.map{|ar| ar.to_s(false) }*", "+
          "}"
      end

      def all_allowed_range_sorted
        all_allowed_range.sort_by{|ar|
            ((min = ar.value_range.minimum_bound) && min.value.literal) ||
              ((max = ar.value_range.maximum_bound) && max.value.literal)
          }
      end

      def to_s
        if all_allowed_range.size > 1
        "[" +
          all_allowed_range.sorted.map { |ar| ar.to_s(true) }*", " +
        "]"
        else
          all_allowed_range.single.to_s
        end
      end
    end

    class AllowedRange
      def to_s(infinity = true)
        min = value_range.minimum_bound
        max = value_range.maximum_bound
        # Open-ended string ranges will fail in Ruby

        if min = value_range.minimum_bound
          min = min.value
          if min.is_a_string
            min_literal = min.literal.inspect.gsub(/\A"|"\Z/,"'")   # Escape string characters
          else
            min_literal = min.literal
          end
        else
          min_literal = infinity ? "INFINITY" : ""
        end
        if max = value_range.maximum_bound
          max = max.value
          if max.is_a_string
            max_literal = max.literal.inspect.gsub(/\A"|"\Z/,"'")   # Escape string characters
          else
            max_literal = max.literal
          end
        else
          max_literal = infinity ? "INFINITY" : ""
        end

        min_literal +
          (min_literal != (max&&max_literal) ? (".." + max_literal) : "")
      end
    end

    class Value
      def to_s
        (is_a_string ? literal.inspect.gsub(/\A"|"\Z/,"'") : literal) + (unit ? " " + unit.name : "")
      end
      def inspect
        to_s
      end
    end

    class PresenceConstraint
      def frequency
        min = min_frequency
        max = max_frequency
        [
            ((min && min > 0 && min != max) ? "at least #{min == 1 ? "one" : min.to_s}" : nil),
            ((max && min != max) ? "at most #{max == 1 ? "one" : max.to_s}" : nil),
            ((max && min == max) ? "#{max == 1 ? "one" : max.to_s}" : nil)
        ].compact * " and"
      end

      def describe
        min = min_frequency
        max = max_frequency
        role_sequence.describe + " occurs " + frequency + " time#{(min&&min>1)||(max&&max>1) ? 's' : ''}"
      end
    end

    class TypeInheritance
      def describe(role = nil)
        "#{subtype.name} is a kind of #{supertype.name}"
      end
    end

    class JoinStep
      def describe
        "#{input_join_node.describe}<->#{output_join_node.describe}"
      end

      def is_unary_step
        # Preserve this in case we have to use a real join_node for the phantom
        # input_join_node.all_role_ref.detect{|rr| rr.role.fact_type.is_a?(ImplicitFactType) && rr.role.fact_type.role.fact_type.all_role.size == 1 }
        input_join_node == output_join_node
      end

      def is_objectification_step
        fact_type.is_a?(ImplicitFactType) &&
          (fact_type.role.implicit_fact_type == fact_type ? true : (puts "!!! ImplicitFactType not self !!!"; false))
      end
    end

    class JoinNode
      def describe
        concept.name
      end
    end

    class Join
      def contractable_step(next_steps, next_node)
        next_reading = nil
        next_step =
          next_steps.detect do |js|
            next false if js.is_objectification_step
            fact_types =    # REVISIT: Store the FactType on the JoinStep to avoid this search?
              js.input_join_node.all_role_ref.map{|rr| rr.role.fact_type} &
              js.output_join_node.all_role_ref.map{|rr| rr.role.fact_type}
            # There can and must be only one fact type involved in this join step
            raise "Ambiguous or incorrect join step" if fact_types.size != 1
            fact_type = fact_types[0]

            # If we find a reading here, it can be contracted against the previous one
            next_reading =
              fact_type.all_reading.detect do |reading|
                # This step is contractable iff the FactType has a reading that starts with the role of next_node (no preceding text)
                reading.text =~ /^\{([0-9])\}/ and
                  role_ref = reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i} and
                  role_ref.role.all_role_ref.detect{|rr| rr.join_node == next_node}
              end
            next_reading
          end
        return [next_step, next_reading]
      end

      def verbalise_over_role_refs role_refs
        join_nodes = all_join_node.sort_by{|jn| jn.ordinal}

        # Each join step must be emitted once.
        join_steps_by_join_node = join_nodes.
          inject({}) do |h, jn|
            jn.all_join_step_as_input_join_node.each{|js| (h[jn] ||= []) << js}
            jn.all_join_step_as_output_join_node.each{|js| (h[jn] ||= []) << js}
            h
          end

        join_steps = join_nodes.map{|jn| jn.all_join_step_as_input_join_node.to_a + jn.all_join_step_as_output_join_node.to_a }.flatten.uniq
        readings = ''
        next_node = role_refs[0].join_node
        last_is_contractable = false
        debug :join, "Join Nodes are #{join_nodes.map{|jn| jn.describe }.inspect}, Join Steps are #{join_steps.map{|js| js.describe }.inspect}" do
          until join_steps.empty?
            next_reading = nil
            # Choose amonst all remaining steps we can take from the next node, if any
            next_steps = join_steps_by_join_node[next_node]
            debug :join, "Next Steps from #{next_node.describe} are #{(next_steps||[]).map{|js| js.describe }.inspect}"

            # See if we can find a next step that contracts against the last (if any):
            next_step = nil
            if last_is_contractable && next_steps
              next_step, next_reading = *contractable_step(next_steps, next_node)
            end
            debug :join, "Chose #{next_step.describe} because it's contractable against last node #{next_node.all_role_ref.to_a[0].role.concept.name} using #{next_reading.expand}" if next_step

            # If we don't have a next_node against which we can contract,
            # so just use any join step involving this node, or just any step.
            if !next_step && next_steps
              ok_next = next_steps.detect { |ns| (readings != '' || !ns.is_objectification_step) }
              debug :join, "Chose new prefixed or non-objectification step: #{ok_next.describe}" if ok_next
              next_step = ok_next
            end

            if !next_step && !join_steps.empty?
              # debug :join, "looking for random prefixed step with readings=#{readings.inspect}"
              ok_next = join_steps.detect { |ns| (readings != '' || !ns.is_objectification_step) }
              debug :join, "Chose random prefixed or non-objectification step: #{ok_next.describe}" if ok_next
              next_step = ok_next
            end

            if !next_step
              next_step = join_steps[0]
              debug :join, "Chose new random step from #{join_steps.size}: #{next_step.describe}" if next_step
            end

            raise "Internal error: There are more join steps here, but we failed to choose one" unless next_step

            if !next_reading
              if next_step.is_unary_step
                rr = next_step.input_join_node.all_role_ref.detect{|rr| rr.role.fact_type.is_a?(ImplicitFactType) }
                next_reading = rr.role.fact_type.role.fact_type.preferred_reading
              elsif next_step.is_objectification_step
                # REVISIT: This objectification join should have been appended to a player in an earlier reading
                # This requires this whole function to be rewritten recursively, with a shared list of outstanding join steps.
                # Do I feel a JoinVerbaliser class coming on?
                fact_type = next_step.fact_type.role.fact_type
                # The objectifying entity type is always the input_join_node here.

                if !last_is_contractable || next_node != next_step.input_join_node
                  readings += " and " unless readings.empty?
                  readings += "/* REVISIT: should have already emitted this objectification */ #{next_step.input_join_node.concept.name}" 
                end
                # REVISIT: We need to use the join role_refs to expand the role players here:
                readings += " (where #{fact_type.default_reading})" 
                # REVISIT: We need to delete the join step (if any) for each role of the objectified fact type, not just this step
              else
                fact_type = next_step.fact_type
                raise "Mildly surprised here... is this a unary?" if fact_type.is_a?(ImplicitFactType)
                fact_type = fact_type.role.fact_type if fact_type.is_a?(ImplicitFactType)
                # REVISIT: this fact type might be an ImplicitFactType in an objectification join, and this will fail.
                # REVISIT: Prefer a reading that starts with the player of next_node
                #next_reading = fact_type.preferred_reading
                next_reading = fact_type.all_reading.
                  detect do |reading|
                    reading.text =~ /^\{([0-9])\}/ and
                      role_ref = reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i} and
                      role_ref.role.all_role_ref.detect{|rr| rr.join_node == next_node}
                  end || fact_type.preferred_reading
                # REVISIT: If this join step and reading has role references with adjectives, we need to expand using those
              end
            else
              readings += " /*REVISIT: contract here*/"
            end
            if next_reading
              readings += " and " unless readings.empty?
              readings += next_reading.expand
            end

            # Prepare for contraction following:
            # The join step we just took is contractable iff
            # iff the reading we just emitted has the next_node's role player as the final text
            next_node = next_step.input_join_node != next_node ? next_step.input_join_node : next_step.output_join_node
            last_is_contractable =
              next_reading &&
              (next_reading.text =~ /\{([0-9])\}$/) &&          # Find whether last role has no following text, and its ordinal
              (role_ref = next_reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i}) &&   # This reading's RoleRef for that role
              role_ref.role.all_role_ref.detect{|rr| rr.join_node == next_node}

            # Remove this step now that we've processed it:
            join_steps.delete(next_step)
            input_node = next_step.input_join_node
            output_node = next_step.output_join_node
            steps = join_steps_by_join_node[input_node]
            steps.delete(next_step)
            join_steps_by_join_node.delete(input_node) if steps.empty?
            if (input_node != output_node)
              steps = join_steps_by_join_node[output_node]
              steps.delete(next_step)
              join_steps_by_join_node.delete(output_node) if steps.empty?
            end
          end
        end
        readings
      end

    end

    class JoinStep
      def describe
        input_role_ref = input_join_node.all_role_ref.detect{|rr| rr.role.fact_type == fact_type}
        output_role_ref = output_join_node.all_role_ref.detect{|rr| rr.role.fact_type == fact_type}
        # REVISIT: Use expand(literals) here to mark input and output roles
        "from #{input_role_ref ? input_role_ref.role.concept.name : input_join_node.concept.name}"+
        " to #{output_role_ref ? output_role_ref.role.concept.name : output_join_node.concept.name}"+
        ": #{is_anti && 'not '}#{is_outer && 'maybe '}#{fact_type.default_reading}"
      end
    end

    class ImplicitFactType
      def default_reading
        # There are two cases, where role is in a unary fact type, and where the fact type is objectified
        # If a unary fact type is objectified, only the ImplicitFactType for the objectification is asserted
        if objectification = role.fact_type.entity_type
          "#{objectification.name} involves #{role.concept.name}"
        else
          role.fact_type.default_reading  # Must be a unary FT
        end
      end
    end

  end
end
