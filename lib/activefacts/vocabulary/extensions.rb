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
        pr = all_reading_by_ordinal[0]
        raise "No reading for (#{all_role.map{|r| r.object_type.name}*", "})" unless pr
        pr
      end

      def describe(highlight = nil)
        (entity_type ? entity_type.name : "")+
        '('+all_role.map{|role| role.describe(highlight) }*", "+')'
      end

      def default_reading(frequency_constraints = [], define_role_names = nil)
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
        return if role.implicit_fact_type     # Already exists
        # NORMA doesn't create an implicit fact type here, rather the fact type has an implicit extra role, so looks like a binary
        # We only do it when the unary fact type is not objectified
        implicit_fact_type = @constellation.ImplicitFactType(:new, :implying_role => role)
        entity_type = @entity_type || @constellation.ImplicitBooleanValueType(role.object_type.vocabulary, "_ImplicitBooleanValueType", :guid => :new)
        phantom_role = @constellation.Role(implicit_fact_type, 0, :object_type => entity_type, :guid => :new)
      end

      def reading_preferably_starting_with_role role
        all_reading_by_ordinal.detect do |reading|
          reading.text =~ /\{\d\}/ and reading.role_sequence.all_role_ref_in_order[$1.to_i].role == role
        end || preferred_reading
      end

      def all_role_in_order
        all_role.sort_by{|r| r.ordinal}
      end
    end

    class Role
      def describe(highlight = nil)
        object_type.name + (self == highlight ? "*" : "")
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

      # Return true if this role is functional (has only one instance wrt its player)
      # A role in an objectified fact type is deemed to refer to the implicit role of the objectification.
      def is_functional
        fact_type.entity_type or
        fact_type.all_role.size != 2 or
          all_role_ref.detect do |rr|
            rr.role_sequence.all_role_ref.size == 1 and
              rr.role_sequence.all_presence_constraint.detect do |pc|
                pc.max_frequency == 1 and !pc.enforcement   # Alethic uniqueness constraint
              end
          end
      end

      def role_method
        if fact_type.all_role.size == 1
          # The object of an objectified unary has no boolean; the existence of the object is the fact
          return nil if fact_type.entity_type
          return preferred_role_name(role)
        end
        if fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
          # No method is available to indicate that the object is the specified subtype
          # In future, this might be implemented using the type discriminator
          return nil
        end
      end

    end

    class RoleRef
      def describe
        role_name
      end

      def preferred_role_ref
        role.fact_type.preferred_reading.role_sequence.all_role_ref.detect{|rr| rr.role == role}
      end

      def role_name(separator = "-")
        name_array =
          if role.fact_type.all_role.size == 1
            if role.fact_type.is_a?(ImplicitFactType)
              "#{role.object_type.name} phantom for #{role.fact_type.role.object_type.name}"
            else
              role.fact_type.preferred_reading.text.gsub(/\{[0-9]\}/,'').strip.split(/\s/)
            end
          else
            role.role_name || [leading_adjective, role.object_type.name, trailing_adjective].compact.map{|w| w.split(/\s/)}.flatten
          end
        return separator ? Array(name_array)*separator : Array(name_array)
      end

      def cql_name
        if role.fact_type.all_role.size == 1
          role_name
        elsif role.role_name
          role.role_name
        else
          # Where an adjective has multiple words, the hyphen is inserted outside the outermost space, leaving the space
          (leading_adjective ? leading_adjective.strip.sub(/ |$/, '-\0').sub(/[^-]$/,'\0 ') : '') +
            role.object_type.name+
            (trailing_adjective ? ' '+trailing_adjective.strip.sub(/.* |^/, '\0-').sub(/^[^-]/,' \0') : '')
        end
      end
    end

    class RoleSequence
      def describe(highlighted_role_ref = nil)
        "("+
          all_role_ref.sort_by{|rr| rr.ordinal}.map{|rr| rr.describe + (highlighted_role_ref == rr ? '*' : '') }*", "+
        ")"
      end

      def all_role_ref_in_order
        all_role_ref.sort_by{|rr| rr.ordinal}
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
        return @preferred_identifier if @preferred_identifier
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
                                next rsr.role.object_type != fact_type.entity_type
                              when 2    # A binary FT must have the objectification of this FT as the other player
                                other_role = (of.all_role-[rsr.role])[0]
                                next other_role.object_type != fact_type.entity_type
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
            return @preferred_identifier = pi if pi
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

                  next if ftroles.size == 2 && pi_role.object_type == self
                  debug :pi, "  Considering #{pi_role.object_type.name} as a PI role"

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
                          debug :pi, "      residual is #{fact_type_roles.map{|r| r.object_type.name}.inspect} minus #{rsr.role.object_type.name}"
                          residual_roles = fact_type_roles-[rsr.role]
                          residual_roles.detect{|rfr|
                              debug :pi, "        Checking residual role #{rfr.object_type.object_id}=>#{rfr.object_type.name}"
# This next line looks right, but breaks things. Find out what and why:
#                              !rfr.unique or
                                !all_supertypes.include?(rfr.object_type)
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
          @preferred_identifier = pi
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
          implicit_fact_type = @constellation.ImplicitFactType(:new, :implying_role => role)
          phantom_role = @constellation.Role(implicit_fact_type, 0, :object_type => self, :guid => :new)
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
      def expand(frequency_constraints = [], define_role_names = nil, literals = [], &subscript_block)
        expanded = "#{text}"
        role_refs = role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}
        (0...role_refs.size).each{|i|
            role_ref = role_refs[i]
            role = role_ref.role
            l_adj = "#{role_ref.leading_adjective}".sub(/(\b-\b|.\b|.\Z)/, '\1-').sub(/\b--\b/,'-- ').sub(/- /,'-  ')
            l_adj = nil if l_adj == ""
            # Double the space to compensate for space removed below
            # REVISIT: hyphenated trailing adjectives are not correctly represented here
            t_adj = "#{role_ref.trailing_adjective}".sub(/(\b.|\A.)/, '-\1').sub(/ -/,'  -')
            t_adj = nil if t_adj == ""

            expanded.gsub!(/\{#{i}\}/) do
                role_ref = role_refs[i]
                player = role_ref.role.object_type
                role_name = role.role_name
                role_name = nil if role_name == ""
                if role_name && define_role_names == false
                  l_adj = t_adj = nil   # When using role names, don't add adjectives
                end
                freq_con = frequency_constraints[i]
                freq_con = freq_con.frequency if freq_con && freq_con.is_a?(ActiveFacts::Metamodel::PresenceConstraint)
                if freq_con.is_a?(Array)
                  freq_con, player_name = *freq_con
                else
                  player_name = player.name
                end
                literal = literals[i]
                words = [
                  freq_con ? freq_con : nil,
                  l_adj,
                  define_role_names == false && role_name ? role_name : player_name,
                  t_adj,
                  define_role_names && role_name && player.name != role_name ? "(as #{role_name})" : nil,
                  # Can't have both a literal and a value constraint, but we don't enforce that here:
                  literal ? literal : nil
                ]
                if (subscript_block)
                  words = subscript_block.call(role_ref, *words)
                end
                words.compact*" "
            end
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

      # Return the array of the numbers of the RoleRefs inserted into this reading from the role_sequence
      def role_numbers
        text.scan(/\{(\d)\}/).flatten.map{|m| Integer(m) }
      end

      def expand_with_final_presence_constraint &b
        # Arrange the roles in order they occur in this reading:
        role_refs = role_sequence.all_role_ref_in_order
        role_numbers = text.scan(/\{(\d)\}/).flatten.map{|m| Integer(m) }
        roles = role_numbers.map{|m| role_refs[m].role }
        fact_constraints = fact_type.internal_presence_constraints

        # Find the constraints that constrain frequency over each role we can verbalise:
        frequency_constraints = []
        roles.each do |role|
          frequency_constraints <<
            if (role == roles.last)   # On the last role of the reading, emit any presence constraint
              constraint = fact_constraints.
                detect do |c|  # Find a UC that spans all other Roles
                  c.is_a?(ActiveFacts::Metamodel::PresenceConstraint) &&
                    roles-c.role_sequence.all_role_ref.map(&:role) == [role]
                end
              constraint && constraint.frequency
            else
              nil
            end
        end

        expand(frequency_constraints) { |*a| b && b.call(*a) }
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
          min_literal = infinity ? "-Infinity" : ""
        end
        if max = value_range.maximum_bound
          max = max.value
          if max.is_a_string
            max_literal = max.literal.inspect.gsub(/\A"|"\Z/,"'")   # Escape string characters
          else
            max_literal = max.literal
          end
        else
          max_literal = infinity ? "Infinity" : ""
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
            ((max && min == max) ? "#{max == 1 ? "one" : "exactly "+max.to_s}" : nil)
        ].compact * " and "
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

      def supertype_role
        (roles = all_role.to_a)[0].object_type == supertype ? roles[0] : roles[1]
      end

      def subtype_role
        (roles = all_role.to_a)[0].object_type == subtype ? roles[0] : roles[1]
      end
    end

    class Step
      def describe
        "Step " +
          "#{is_optional && 'maybe '}" +
          (is_unary_step ? " (unary) " : "from #{input_play.describe} ") +
          "#{is_disallowed && 'not '}" +
          "to #{output_play.describe} " +
          "over " +
          (is_objectification_step ? 'objectification ' : '') +
          "'#{fact_type.default_reading}'"
      end

      def is_unary_step
        # Preserve this in case we have to use a real variable for the phantom
        input_play == output_play
      end

      def is_objectification_step
        fact_type.is_a?(ImplicitFactType)
      end

      def all_play
        [input_play, output_play].uniq + all_incidental_play.to_a
      end

      def external_fact_type
        fact_type.is_a?(ImplicitFactType) ? fact_type.role.fact_type : fact_type
      end
    end

    class Variable
      def describe
        object_type.name +
          (subscript ? "(#{subscript})" : '') +
          " JN#{ordinal}" +
          (value ? ' = '+value.to_s : '')
      end

      def all_step
        all_play.map do |jr|
          jr.all_step_as_input_play.to_a +
            jr.all_step_as_output_play.to_a
        end.
          flatten.
          uniq
      end
    end

    class Play
      def describe
        "#{role.object_type.name} JN#{variable.ordinal}" +
          (role_ref ? " (projected)" : "")
      end

      def all_step
        (all_step_as_input_play.to_a +
          all_step_as_output_play.to_a +
          [step]).flatten.compact.uniq
      end
    end

    class Query
      def show
        steps_shown = {}
        debug :query, "Displaying full contents of Query #{guid}" do
          all_variable.sort_by{|jn| jn.ordinal}.each do |variable|
            debug :query, "#{variable.describe}" do
              variable.all_step.
                each do |step|
                  next if steps_shown[step]
                  steps_shown[step] = true
                  debug :query, "#{step.describe}"
                end
              variable.all_play.each do |play|
                debug :query, "role of #{play.describe} in '#{play.role.fact_type.default_reading}'"
              end
            end
          end
        end
      end

      def all_step
        all_variable.map{|jn| jn.all_step.to_a}.flatten.uniq
      end

      # Check all parts of this query for validity
      def validate
        show
        return

        # Check the variables:
        steps = []
        variables = all_variable.sort_by{|jn| jn.ordinal}
        variables.each_with_index do |variable, i|
          raise "Variable #{i} should have ordinal #{variable.ordinal}" unless variable.ordinal == i
          raise "Variable #{i} has missing object_type" unless variable.object_type
          variable.all_play do |play|
            raise "Variable for #{object_type.name} includes role played by #{play.object_type.name}" unless play.object_type == object_type
          end
          steps += variable.all_step
        end
        steps.uniq!

        # Check the steps:
        steps.each do |step|
          raise "Step has missing fact type" unless step.fact_type
          raise "Step has missing input node" unless step.input_play
          raise "Step has missing output node" unless step.output_play
          if (role = input_play).role.fact_type != fact_type or
            (role = output_play).role.fact_type != fact_type
            raise "Step has role #{role.describe} which doesn't belong to the fact type '#{fact_type.default_reading}' it traverses"
          end
        end

        # REVISIT: Do a connectivity check
      end
    end

    class ImplicitFactType
      def default_reading
        # There are two cases, where role is in a unary fact type, and where the fact type is objectified
        # If a unary fact type is objectified, only the ImplicitFactType for the objectification is asserted
        if objectification = implying_role.fact_type.entity_type
          "#{objectification.name} involves #{implying_role.object_type.name}"
        else
          implying_role.fact_type.default_reading+" Boolean"  # Must be a unary FT
        end
      end

      # This is only used for debugging, from RoleRef#describe
      class ImplicitReading
        attr_accessor :fact_type, :text

        def initialize(fact_type, text)
          @fact_type = fact_type
          @text = text
        end

        class ImplicitReadingRoleSequence
          class ImplicitReadingRoleRef
            attr_reader :role
            attr_reader :role_sequence
            def initialize(role, role_sequence)
              @role = role
              @role_sequence = role_sequence
            end
            def variable; nil; end
            def play; nil; end
            def leading_adjective; nil; end
            def trailing_adjective; nil; end
            def describe
              @role.object_type.name
            end
          end

          def initialize roles
            @role_refs = roles.map{|role| ImplicitReadingRoleRef.new(role, self) }
          end

          def all_role_ref
            @role_refs
          end
          def describe
            '('+@role_refs.map(&:describe)*', '+')'
          end
          def all_reading
            []
          end
        end

        def role_sequence
          ImplicitReadingRoleSequence.new([@fact_type.implying_role, @fact_type.all_role.single])
        end

        def ordinal; 0; end

        def expand
          @fact_type.default_reading
        end
      end

      def all_reading
        [@reading ||= ImplicitReading.new(
          self,
          implying_role.fact_type.entity_type ? "{0} involves {1}" : implying_role.fact_type.default_reading+" Boolean"
        )]
      end
    end

    # Some queries must be over the proximate roles, some over the counterpart roles.
    # Return the common superclass of the appropriate roles, and the actual roles
    def self.plays_over roles, options = :both   # Or :proximate, :counterpart
      # If we can stay inside this objectified FT, there's no query:
      roles = Array(roles)  # To be safe, in case we get a role collection proxy
      return nil if roles.size == 1 or
        options != :counterpart && roles.map{|role| role.fact_type}.uniq.size == 1
      proximate_sups, counterpart_sups, obj_sups, counterpart_roles, objectification_roles =
        *roles.inject(nil) do |d_c_o, role|
          object_type = role.object_type
          fact_type = role.fact_type

          proximate_role_supertypes = object_type.supertypes_transitive

          # A role in an objectified fact type may indicate either the objectification or the counterpart player.
          # This could be ambiguous. Figure out both and prefer the counterpart over the objectification.
          counterpart_role_supertypes =
            if fact_type.all_role.size > 2
              possible_roles = fact_type.all_role.select{|r| d_c_o && d_c_o[1].include?(r.object_type) }
              if possible_roles.size == 1 # Only one candidate matches the types of the possible variables
                counterpart_role = possible_roles[0]
                d_c_o[1]  # No change
              else
                # puts "#{constraint_type} #{name}: Awkward, try counterpart-role query on a >2ary '#{fact_type.default_reading}'"
                # Try all roles; hopefully we don't have two roles with a matching candidate here:
                # Find which role is compatible with the existing supertypes, if any
                if d_c_o
                  st = nil
                  counterpart_role =
                    fact_type.all_role.detect{|r| ((st = r.object_type.supertypes_transitive) & d_c_o[1]).size > 0}
                  st
                else
                  counterpart_role = nil  # This can't work, we don't have any basis for a decision (must be objectification)
                  []
                end
                #fact_type.all_role.map{|r| r.object_type.supertypes_transitive}.flatten.uniq
              end
            else
              # Get the supertypes of the counterpart role (care with unaries):
              ftr = role.fact_type.all_role.to_a
              (counterpart_role = ftr[0] == role ? ftr[-1] : ftr[0]).object_type.supertypes_transitive
            end

          if fact_type.entity_type
            objectification_role_supertypes =
              fact_type.entity_type.supertypes_transitive+object_type.supertypes_transitive
            objectification_role = role.implicit_fact_type.all_role.single # Find the phantom role here
          else
            objectification_role_supertypes = counterpart_role_supertypes
            objectification_role = counterpart_role
          end

          if !d_c_o
            d_c_o = [proximate_role_supertypes, counterpart_role_supertypes, objectification_role_supertypes, [counterpart_role], [objectification_role]]
            #puts "role player supertypes starts #{d_c_o.map{|dco| dco.map(&:name).inspect}*' or '}"
          else
            #puts "continues #{[proximate_role_supertypes, counterpart_role_supertypes, objectification_role_supertypes]map{|dco| dco.map(&:name).inspect}*' or '}"
            d_c_o[0] &= proximate_role_supertypes
            d_c_o[1] &= counterpart_role_supertypes
            d_c_o[2] &= objectification_role_supertypes
            d_c_o[3] << (counterpart_role || objectification_role)
            d_c_o[4] << (objectification_role || counterpart_role)
          end
          d_c_o
        end # inject

      # Discount a subtype step over an object type that's not a player here,
      # if we can use an objectification step to an object type that is:
      if counterpart_sups.size > 0 && obj_sups.size > 0 && counterpart_sups[0] != obj_sups[0]
        debug :query, "ambiguous query, could be over #{counterpart_sups[0].name} or #{obj_sups[0].name}"
        if !roles.detect{|r| r.object_type == counterpart_sups[0]} and roles.detect{|r| r.object_type == obj_sups[0]}
          debug :query, "discounting #{counterpart_sups[0].name} in favour of direct objectification"
          counterpart_sups = []
        end
      end

      # Choose the first entry in the first non-empty supertypes list:
      if options != :counterpart && proximate_sups[0]
        [ proximate_sups[0], roles ]
      elsif !counterpart_sups.empty?
        [ counterpart_sups[0], counterpart_roles ]
      else
        [ obj_sups[0], objectification_roles ]
      end
    end

    class Fact
      def verbalise(context = nil)
        reading = fact_type.preferred_reading
        reading_roles = reading.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}.map{|rr| rr.role }
        role_values_in_reading_order = all_role_value.sort_by{|rv| reading_roles.index(rv.role) }
        instance_verbalisations = role_values_in_reading_order.map do |rv|
          if rv.instance.value
            v = rv.instance.verbalise
          else
            if (c = rv.instance.object_type).is_a?(EntityType)
              if !c.preferred_identifier.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type == fact_type}
                v = rv.instance.verbalise
              end
            end
          end
          next nil unless v
          v.to_s.sub(/(#{rv.instance.object_type.name}|\S*)\s/,'')
        end
        reading.expand([], false, instance_verbalisations)
      end
    end

    class Instance
      def verbalise(context = nil)
        return "#{object_type.name} #{value}" if object_type.is_a?(ValueType)

        return "#{object_type.name} where #{fact.verbalise(context)}" if object_type.fact_type

        # It's an entity that's not an objectified fact type
        # REVISIT: If it has a simple identifier, there's no need to fully verbalise the identifying facts
        pi = object_type.preferred_identifier
        identifying_role_refs = pi.role_sequence.all_role_ref_in_order
        "#{object_type.name}" +
          " is identified by " +      # REVISIT: Where the single fact type is TypeInheritance, we can shrink this
          if identifying_role_refs.size == 1 &&
            (role = identifying_role_refs[0].role) &&
            (my_role = (role.fact_type.all_role.to_a-[role])[0]) &&
            (identifying_fact = my_role.all_role_value.detect{|rv| rv.instance == self}.fact) &&
            (identifying_instance = identifying_fact.all_role_value.detect{|rv| rv.role == role}.instance)

              "its #{identifying_instance.verbalise(context)}"
          else
            identifying_role_refs.map do |rr|
              rr = rr.preferred_role_ref
              [ (l = rr.leading_adjective) ? l+"-" : nil,
                rr.role.role_name || rr.role.object_type.name,
                (t = rr.trailing_adjective) ? l+"-" : nil
              ].compact*""
            end * " and " +
            " where " +
            identifying_role_refs.map do |rr|  # Go through the identifying roles and emit the facts that define them
              instance_role = object_type.all_role.detect{|r| r.fact_type == rr.role.fact_type}
              identifying_fact = all_role_value.detect{|rv| rv.fact.fact_type == rr.role.fact_type}.fact
              #counterpart_role = (rr.role.fact_type.all_role.to_a-[instance_role])[0]
              #identifying_instance = counterpart_role.all_role_value.detect{|rv| rv.fact == identifying_fact}.instance
              identifying_fact.verbalise(context)
            end*", "
          end

      end
    end

  end
end
