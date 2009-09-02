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
        # The reference traverses the Joins in sequence to the final role:
        all_join.sort_by{|jp| jp.join_step}.map{ |jp| jp.describe + "." }*"" + role_name
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
        role_ref.role == role &&
        all_join.size == role_ref.all_join.size &&
        !all_join.sort_by{|j|j.join_step}.
          zip(role_ref.all_join.sort_by{|j|j.join_step}).
          detect{|j1,j2|
            j1.input_role != j2.input_role ||
            j1.output_role != j2.output_role
          }
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
            # debug ti.class.roles.verbalise; exit
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
            la = nil if la == ""
            ta = "#{role_ref.trailing_adjective}"
            ta.sub!(/(\b.|\A.)/, '-\1')
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
                  # Can't have both a literal and a restriction, but we don't enforce that here:
                  (vr = role.role_value_restriction) ? vr.describe : nil,
                  literal ? literal : nil
                ].compact*" "
            }
        }
        expanded.gsub!(/ *- */, '-')      # Remove spaces around adjectives
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

    class ValueRestriction
      def describe
        "restricted to {"+
          all_allowed_range.sort_by{|ar|
              ((min = ar.value_range.minimum_bound) && min.value) ||
                ((max = ar.value_range.maximum_bound) && max.value)
            }.map{|ar|
            # REVISIT: Need to display as string or numeric according to type here...
            min = ar.value_range.minimum_bound
            max = ar.value_range.maximum_bound

            (min ? min.value : "") +
              (min.value != (max&&max.value) ? (".." + (max ? max.value : "")) : "")
          }*", "+
          "}"
      end

      def to_s
        if all_allowed_range.size > 1
        "[" +
          all_allowed_range.sort_by do |ar|
              ((min = ar.value_range.minimum_bound) && min.value) ||
                ((max = ar.value_range.maximum_bound) && max.value)
          end.map do |ar|
            ar.to_s
          end*", " +
        "]"
        else
          all_allowed_range.single.to_s
        end
      end
    end

    class AllowedRange
      def to_s
        min = value_range.minimum_bound
        max = value_range.maximum_bound
        # REVISIT: The result here is meant to work in Ruby, but open-ended ranges will fail.
        # Can handle numeric ones using INFINITY (1.0/0, -1.0/0), but strings???
        (min ? min.value : "") +
          (min.value != (max&&max.value) ? (".." + (max ? max.value : "")) : "")
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
        role_sequence.describe + " occurs " + frequency + " time"
      end
    end

    class TypeInheritance
      def describe(role = nil)
        "#{subtype.name} is a kind of #{supertype.name}"
      end
    end

  end
end
