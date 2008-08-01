#
# Extensions to the ActiveFacts Vocabulary API (which is generated from the Metamodel)
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Metamodel

    class FactType
      def all_reading_by_ordinal
        all_reading.sort_by{|reading| reading.ordinal}
      end

      def preferred_reading
        all_reading_by_ordinal[0]
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
        }
      end
    end

    class RoleSequence
      def describe
#        fact_types = all_role_ref.map(&:role).map(&:fact_type).uniq
#        fact_types.size.to_s+" FTs, "+
        "("+
        all_role_ref.map{|rr| [ rr.leading_adjective, rr.role.concept.name, rr.trailing_adjective ].compact*" " }*", "+
        ")"
      end
    end

    class EntityType
      include ActiveFacts
      def preferred_identifier
        if fact_type

          # For a nested fact type, the PI is a unique constraint over N or N-1 roles
          fact_roles = fact_type.all_role
          debug "Looking for PI on nested fact type #{name}" do
            pi = catch :pi do
                fact_roles[0,2].each{|r|                  # Try the first two roles of the fact type, that's enough
                    r.all_role_ref.map{|rr|               # All role sequences that reference this role
                        role_sequence = rr.role_sequence

                        # The role sequence is only interesting if it cover only this fact's roles
                        next if role_sequence.all_role_ref.size < fact_roles.size-1 # Not enough roles
                        next if role_sequence.all_role_ref.size > fact_roles.size   # Too many roles
                        next if role_sequence.all_role_ref.detect{|rsr| ft = rsr.role.fact_type; ft != fact_type }

                        # This role sequence is a candidate
                        pc = role_sequence.all_presence_constraint.detect{|c|
                            c.max_frequency == 1 && c.is_preferred_identifier
                          }
                        throw :pi, pc if pc
                      }
                  }
                throw :pi, nil
              end
            debug "Got PI #{pi.name||pi.object_id} for nested #{name}" if pi
            debug "Looking for PI on entity that nests this fact" unless pi
            raise "Oops, pi for nested fact is #{pi.class}" unless !pi || PresenceConstraint === pi
            return pi if pi
          end
        end

        debug "Looking for PI for ordinary entity #{name} with #{all_role.size} roles:" do
          debug "Roles are in fact types #{all_role.map{|r| r.fact_type.describe(r)}*", "}"
          pi = catch :pi do
              all_supertypes = supertypes_transitive
              debug "PI roles must be played by one of #{all_supertypes.map(&:name)*", "}" if all_supertypes.size > 1
              all_role.each{|role|
                  next unless role.unique || fact_type
                  ftroles = role.fact_type.all_role

                  # Skip roles in ternary and higher fact types, they're objectified
                  next if ftroles.size > 2

                  debug "Considering role in #{role.fact_type.describe(role)}"

                  # Find the related role which must be included in any PI:
                  # Note this works with unary fact types:
                  pi_role = ftroles[ftroles[0] != role ? 0 : -1]

                  next if ftroles.size == 2 && pi_role.concept == self
                  debug "  Considering #{pi_role.concept.name} as a PI role"

                  # If this is an identifying role, the PI is a PC whose role_sequence spans the role.
                  # Walk through all role_sequences that span this role, and test each:
                  pi_role.all_role_ref.each{|rr|
                      role_sequence = rr.role_sequence  # A role sequence that includes a possible role

                      debug "    Considering role sequence #{role_sequence.describe}"

                      # All roles in this role_sequence must be in fact types which
                      # (apart from that role) only have roles played by the original
                      # entity type or a supertype.
                      #debug "      All supertypes #{all_supertypes.map{|st| "#{st.object_id}=>#{st.name}"}*", "}"
                      if role_sequence.all_role_ref.detect{|rsr|
                          fact_type = rsr.role.fact_type
                          debug "      Role Sequence touches #{fact_type.describe(pi_role)}"

                          fact_type_roles = fact_type.all_role
                          debug "      residual is #{fact_type_roles.map{|r| r.concept.name}.inspect} minus #{rsr.role.concept.name}"
                          residual_roles = fact_type_roles-[rsr.role]
                          residual_roles.detect{|rfr|
                              debug "        Checking residual role #{rfr.concept.object_id}=>#{rfr.concept.name}"
# This next line looks right, but breaks things. Find out what and why:
#                              !rfr.unique or
                                !all_supertypes.include?(rfr.concept)
                            }
                        }
                        debug "      Discounting this role_sequence because it includes alien roles"
                        next
                      end

                      # Any presence constraint over this role sequence is a candidate
                      rr.role_sequence.all_presence_constraint.detect{|pc|
                          # Found it!
                          if pc.is_preferred_identifier
                            debug "found PI #{pc.name||pc.object_id}, is_preferred_identifier=#{pc.is_preferred_identifier.inspect} over #{pc.role_sequence.describe}"
                            throw :pi, pc
                          end
                        }
                    }
                }
              throw :pi, nil
            end
          raise "Oops, pi for entity is #{pi.class}" if pi && !(PresenceConstraint === pi)
          debug "Got PI #{pi.name||pi.object_id} for #{name}" if pi

          if !pi
            if (supertype = identifying_supertype)
              debug "PI not found for #{name}, looking in supertype #{supertype.name}"
              pi = supertype.preferred_identifier
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
              debug "No PI found for #{name}"
            end
          end
          raise "No PI found for #{name}" unless pi
          pi
        end
      end

      # An array all direct supertypes
      def supertypes
        all_type_inheritance_by_subtype.map{|ti|
            ti.supertype
          }
      end

      # An array of self followed by all supertypes in order:
      def supertypes_transitive
          ([self] + all_type_inheritance_by_subtype.map{|ti|
              # debug ti.class.roles.verbalise; exit
              ti.supertype.supertypes_transitive
            }).flatten.uniq
      end

      # A subtype does not have a identifying_supertype if it defines its own identifier
      def identifying_supertype
        debug "Looking for identifying_supertype of #{name}"
        all_type_inheritance_by_subtype.detect{|ti|
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
      def expand(frequency_constraints = [], define_role_names = false)
        expanded = "#{reading_text}"
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
                fc = fc.frequency if fc && PresenceConstraint === fc
                if Array === fc
                  fc, player_name = *fc
                else
                  player_name = player.name
                end
                [
                  fc ? fc : nil,
                  la,
                  define_role_names == false && role_name ? role_name : player_name,
                  ta,
                  define_role_names && role_name && player.name != role_name ? "(as #{role_name})" : nil
                ].compact*" "
            }
        }
        expanded.gsub!(/ *- */, '-')      # Remove spaces around adjectives
        #debug "Expanded '#{expanded}' using #{frequency_constraints.inspect}"
        expanded
      end
    end

    class PresenceConstraint
      def frequency
        min = min_frequency
        max = max_frequency
        [
            ((min && min > 0 && min != max) ? "at least #{min == 1 ? "one" : min.to_s}" : nil),
            ((max && min != max) ? "at most #{max == 1 ? "one" : max.to_s}" : nil),
            ((max && min == max) ? "exactly #{max == 1 ? "one" : max.to_s}" : nil)
        ].compact * " and"
      end
    end

  end
end
