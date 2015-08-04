#
#       ActiveFacts Vocabulary Metamodel.
#       Extensions to the ActiveFacts Vocabulary classes (which are generated from the Metamodel)
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Metamodel
    class Vocabulary
      def finalise
        constellation.FactType.values.each do |fact_type|
          if c = fact_type.check_and_add_spanning_uniqueness_constraint
            trace :constraint, "Checking for existence of at least one uniqueness constraint over the roles of #{fact_type.default_reading.inspect}"
            fact_type.check_and_add_spanning_uniqueness_constraint = nil
            c.call
          end
        end
      end

      # This name does not yet exist (at least not as we expect it to).
      # If it in fact does exist (but as the wrong type), complain.
      # If it doesn't exist, but its name would cause existing fact type
      # readings to be re-interpreted to a different meaning, complain.
      # Otherwise return nil.
      def check_valid_nonexistent_object_type_name name
        if ot = valid_object_type_name(name)
          raise "Cannot redefine #{ot.class.basename} #{name}"
        end
      end

      def valid_object_type_name name
        # Raise an exception if adding this name to the vocabulary would create anomalies
        anomaly = constellation.Reading.detect do |r_key, reading|
            expanded = reading.expand do |role_ref, *words|
                words.map! do |w|
                  case
                  when w == nil
                    w
                  when w[0...name.size] == name
                    '_ok_'+w
                  when w[-name.size..-1] == name
                    w[-1]+'_ok_'
                  else
                    w
                  end
                end

                words
              end
            expanded =~ %r{\b#{name}\b}
          end
        raise "Adding new term '#{name}' would create anomalous re-interpretation of '#{anomaly.expand}'" if anomaly
        @constellation.ObjectType[[identifying_role_values, name]]
      end

      # If this entity type exists, ok, otherwise check it's ok to add it
      def valid_entity_type_name name
        @constellation.EntityType[[identifying_role_values, name]] or
          check_valid_nonexistent_object_type_name name
      end

      # If this entity type exists, ok, otherwise check it's ok to add it
      def valid_value_type_name name
        @constellation.ValueType[[identifying_role_values, name]] or
          check_valid_nonexistent_object_type_name name
      end
    end

    class Concept
      def describe
        case
        when object_type; "#{object_type.class.basename} #{object_type.name.inspect}"
        when fact_type; "FactType #{fact_type.default_reading.inspect}"
        when role; "Role in #{role.fact_type.describe(role)}"
        when constraint; constraint.describe
        when instance; "Instance #{instance.verbalise}"
        when fact; "Fact #{fact.verbalise}"
        when query; query.describe
        when context_note; "ContextNote#{context_note.verbalise}"
        when unit; "Unit #{unit.describe}"
        when population; "Population: #{population.name}"
        else
          raise "ROGUE CONCEPT OF NO TYPE"
        end
      end

      def embodied_as
        case
        when object_type; object_type
        when fact_type; fact_type
        when role; role
        when constraint; constraint
        when instance; instance
        when fact; fact
        when query; query
        when context_note; context_note
        when unit; unit
        when population; population
        else
          raise "ROGUE CONCEPT OF NO TYPE"
        end
      end

      # Return an array of all Concepts that must be defined before this concept can be defined:
      def precursors
        case body = embodied_as
        when ActiveFacts::Metamodel::ValueType
          [ body.supertype, body.unit ] +
          body.all_facet.map{|f| f.facet_value_type } +
          body.all_facet_restriction.map{|vr| vr.value.unit}
        when ActiveFacts::Metamodel::EntityType
          # You can't define the preferred_identifier fact types until you define the entity type,
          # but the objects which play the identifying roles must be defined:
          body.preferred_identifier.role_sequence.all_role_ref.map {|rr| rr.role.object_type } +
          # You can't define the objectified fact type until you define the entity type:
          # [ body.fact_type ]  # If it's an objectification
          body.all_type_inheritance_as_subtype.map{|ti| ti.supertype}   # If it's a subtype
        when FactType
          body.all_role.map(&:object_type)
        when Role   # We don't consider roles as they cannot be separately defined
          []
        when ActiveFacts::Metamodel::PresenceConstraint
          body.role_sequence.all_role_ref.map do |rr|
            rr.role.fact_type
          end
        when ActiveFacts::Metamodel::ValueConstraint
          [ body.role ? body.role.fact_type : nil, body.value_type ] +
          body.all_allowed_range.map do |ar|
            [ ar.value_range.minimum_bound, ar.value_range.maximum_bound ].compact.map{|b| b.value.unit}
          end
        when ActiveFacts::Metamodel::SubsetConstraint
          body.subset_role_sequence.all_role_ref.map{|rr| rr.role.fact_type } +
          body.superset_role_sequence.all_role_ref.map{|rr| rr.role.fact_type }
        when ActiveFacts::Metamodel::SetComparisonConstraint
          body.all_set_comparison_roles.map{|scr| scr.role_sequence.all_role_ref.map{|rr| rr.role.fact_type } }
        when ActiveFacts::Metamodel::RingConstraint
          [ body.role.fact_type, body.other_role.fact_type ]
        when Instance
          [ body.population, body.object_type, body.value ? body.value.unit : nil ]
        when Fact
          [ body.population, body.fact_type ]
        when Query
          body.all_variable.map do |v|
            [ v.object_type,
              v.value ? v.value.unit : nil,
              v.step ? v.step.fact_type : nil
            ] +
            v.all_play.map{|p| p.role.fact_type }
          end
        when ContextNote
          []
        when Unit
          body.all_derivation_as_derived_unit.map{|d| d.base_unit }
        when Population
          []
        else
          raise "ROGUE CONCEPT OF NO TYPE"
        end.flatten.compact.uniq.map{|c| c.concept }
      end
    end

    class Topic
      def precursors
	# Precursors of a topic are the topics of all precursors of items in this topic
	all_concept.map{|c| c.precursors }.flatten.uniq.map{|c| c.topic}.uniq-[self]
      end
    end

    class Unit
      def describe
        'Unit' +
        name +
        (plural_name ? '/'+plural_name : '') +
        '=' +
        coefficient.to_s+'*' +
        all_derivation_as_derived_unit.map do |derivation|
          derivation.base_unit.name +
          (derivation.exponent != 1 ? derivation.exponent.to_s : '')
        end.join('') +
        (offset ? ' + '+offset.to_s : '')
      end
    end

    class Coefficient
      def to_s
        numerator.to_s +
        (denominator != 1 ? '/' + denominator.to_s : '')
      end
    end

    class FactType
      attr_accessor :check_and_add_spanning_uniqueness_constraint

      def all_reading_by_ordinal
        all_reading.sort_by{|reading| reading.ordinal}
      end

      def preferred_reading negated = false
        pr = all_reading_by_ordinal.detect{|r| !r.is_negative == !negated }
        raise "No reading for (#{all_role.map{|r| r.object_type.name}*", "})" unless pr || negated
        pr
      end

      def describe(highlight = nil)
        (entity_type ? entity_type.name : "")+
        '('+all_role.map{|role| role.describe(highlight) }*", "+')'
      end

      def default_reading(frequency_constraints = [], define_role_names = nil)
        preferred_reading.expand(frequency_constraints, define_role_names)
      end

      # Does any role of this fact type participate in a preferred identifier?
      def is_existential
        return false if all_role.size > 2
        all_role.detect do |role|
          role.all_role_ref.detect do |rr|
            rr.role_sequence.all_presence_constraint.detect do |pc|
              pc.is_preferred_identifier
            end
          end
        end
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

      def implicit_boolean_type vocabulary
        @constellation.ImplicitBooleanValueType[[vocabulary.identifying_role_values, "_ImplicitBooleanValueType"]] or
        @constellation.ImplicitBooleanValueType(vocabulary.identifying_role_values, "_ImplicitBooleanValueType", :concept => [:new, :implication_rule => 'unary'])
      end

      # This entity type has just objectified a fact type. Create the necessary ImplicitFactTypes with phantom roles
      def create_implicit_fact_type_for_unary
        role = all_role.single
        return if role.link_fact_type     # Already exists
        # NORMA doesn't create an implicit fact type here, rather the fact type has an implicit extra role, so looks like a binary
        # We only do it when the unary fact type is not objectified
        link_fact_type = @constellation.LinkFactType(:new, :implying_role => role)
        link_fact_type.concept.implication_rule = 'unary'
        entity_type = @entity_type || implicit_boolean_type(role.object_type.vocabulary)
        phantom_role = @constellation.Role(link_fact_type, 0, :object_type => entity_type, :concept => :new)
      end

      def reading_preferably_starting_with_role role, negated = false
        all_reading_by_ordinal.detect do |reading|
          reading.text =~ /\{\d\}/ and
            reading.role_sequence.all_role_ref_in_order[$1.to_i].role == role and
            reading.is_negative == !!negated
        end || preferred_reading(negated)
      end

      def all_role_in_order
        all_role.sort_by{|r| r.ordinal}
      end

      def compatible_readings types_array
        all_reading.select do |reading|
          ok = true
          reading.role_sequence.all_role_ref_in_order.each_with_index do |rr, i|
            ok = false unless types_array[i].include?(rr.role.object_type)
          end
          ok
        end
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
        return fact_type.implying_role.is_mandatory if fact_type.is_a?(LinkFactType)
        all_role_ref.detect{|rr|
          rs = rr.role_sequence
          rs.all_role_ref.size == 1 and
          rs.all_presence_constraint.detect{|pc|
            pc.min_frequency and pc.min_frequency >= 1 and pc.is_mandatory
          }
        } ? true : false
      end

      def preferred_reference
        fact_type.preferred_reading.role_sequence.all_role_ref.detect{|rr| rr.role == self }
      end

      # Return true if this role is functional (has only one instance wrt its player)
      # A role in an objectified fact type is deemed to refer to the implicit role of the objectification.
      def is_functional
        fact_type.entity_type or
        fact_type.all_role.size != 2 or
        is_unique
      end

      def is_unique
        all_role_ref.detect do |rr|
          rr.role_sequence.all_role_ref.size == 1 and
            rr.role_sequence.all_presence_constraint.detect do |pc|
              pc.max_frequency == 1 and !pc.enforcement   # Alethic uniqueness constraint
            end
        end
      end

      def name
        role_name || object_type.name
      end

    end

    class RoleRef
      def describe
        role_name
      end

      def preferred_reference
        role.preferred_reference
      end

      def role_name(separator = "-")
        return 'UNKNOWN' unless role
        name_array =
          if role.fact_type.all_role.size == 1
            if role.fact_type.is_a?(LinkFactType)
              "#{role.object_type.name} phantom for #{role.fact_type.role.object_type.name}"
            else
              role.fact_type.preferred_reading.text.gsub(/\{[0-9]\}/,'').strip.split(/\s/)
            end
          else
            role.role_name || [leading_adjective, role.object_type.name, trailing_adjective].compact.map{|w| w.split(/\s/)}.flatten
          end
        return separator ? Array(name_array)*separator : Array(name_array)
      end

      def cql_leading_adjective
	if leading_adjective
	  # 'foo' => "foo-"
	  # 'foo bar' => "foo- bar "
	  # 'foo-bar' => "foo-- bar "
	  # 'foo-bar baz' => "foo-- bar baz "
	  # 'bat foo-bar baz' => "bat- foo-bar baz "
	  leading_adjective.strip.
	    sub(/[- ]|$/, '-\0 ').sub(/  /, ' ').sub(/[^-]$/, '\0 ').sub(/-  $/,'-')
	else
	  ''
	end
      end

      def cql_trailing_adjective
	if trailing_adjective
	  # 'foo' => "-foo"
	  # 'foo bar' => " foo -bar"
	  # 'foo-bar' => " foo --bar"
	  # 'foo-bar baz' => " foo-bar -baz"
	  # 'bat foo-bar baz' => " bat foo-bar -baz"
	  trailing_adjective.
	    strip.
	    sub(/(?<a>.*) (?<b>[^- ]+$)|(?<a>.*)(?<b>-[^- ]*)$|(?<a>)(?<b>.*)/) {
	      " #{$~[:a]} -#{$~[:b]}"
	    }.
	    sub(/^ *-/, '-')  # A leading space is not needed if the hyphen is at the start
	else
	  ''
	end
      end

      def cql_name
        if role.fact_type.all_role.size == 1
          role_name
        elsif role.role_name
          role.role_name
        else
          # Where an adjective has multiple words, the hyphen is inserted outside the outermost space, leaving the space
	  cql_leading_adjective +
            role.object_type.name+
	    cql_trailing_adjective
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

    class ObjectType
      # Placeholder for the surrogate transform
      attr_reader :injected_surrogate_role

      def is_separate
	is_independent or concept.all_concept_annotation.detect{|ca| ca.mapping_annotation == 'separate'}
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

      def common_supertype(other)
        return nil unless other.is_?(ActiveFacts::Metamodel::ValueType)
        return self if other.supertypes_transitive.include?(self)
        return other if supertypes_transitive.include(other)
        nil
      end
    end

    class EntityType
      def identification_is_inherited
        preferred_identifier and
          preferred_identifier.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) }
      end

      def assimilation
        if rr = identification_is_inherited
          rr.role.fact_type.assimilation
        else
          nil
        end
      end

      def preferred_identifier
        return @preferred_identifier if @preferred_identifier
        if fact_type
          # When compiling a fact instance, the delayed creation of a preferred identifier might be necessary
          if c = fact_type.check_and_add_spanning_uniqueness_constraint
            fact_type.check_and_add_spanning_uniqueness_constraint = nil
            c.call
          end

          # For a nested fact type, the PI is a unique constraint over N or N-1 roles
          fact_roles = Array(fact_type.all_role)
          trace :pi, "Looking for PI on nested fact type #{name}" do
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
            trace :pi, "Got PI #{pi.name||pi.object_id} for nested #{name}" if pi
            trace :pi, "Looking for PI on entity that nests this fact" unless pi
            raise "Oops, pi for nested fact is #{pi.class}" unless !pi || pi.is_a?(ActiveFacts::Metamodel::PresenceConstraint)
            return @preferred_identifier = pi if pi
          end
        end

        trace :pi, "Looking for PI for ordinary entity #{name} with #{all_role.size} roles:" do
          trace :pi, "Roles are in fact types #{all_role.map{|r| r.fact_type.describe(r)}*", "}"
          pi = catch :pi do
              all_supertypes = supertypes_transitive
              trace :pi, "PI roles must be played by one of #{all_supertypes.map(&:name)*", "}" if all_supertypes.size > 1
              all_role.each{|role|
                  next unless role.unique || fact_type
                  ftroles = Array(role.fact_type.all_role)

                  # Skip roles in ternary and higher fact types, they're objectified, and in unaries, they can't identify us.
                  next if ftroles.size != 2

                  trace :pi, "Considering role in #{role.fact_type.describe(role)}"

                  # Find the related role which must be included in any PI:
                  # Note this works with unary fact types:
                  pi_role = ftroles[ftroles[0] != role ? 0 : -1]

                  next if ftroles.size == 2 && pi_role.object_type == self
                  trace :pi, "  Considering #{pi_role.object_type.name} as a PI role"

                  # If this is an identifying role, the PI is a PC whose role_sequence spans the role.
                  # Walk through all role_sequences that span this role, and test each:
                  pi_role.all_role_ref.each{|rr|
                      role_sequence = rr.role_sequence  # A role sequence that includes a possible role

                      trace :pi, "    Considering role sequence #{role_sequence.describe}"

                      # All roles in this role_sequence must be in fact types which
                      # (apart from that role) only have roles played by the original
                      # entity type or a supertype.
                      #trace :pi, "      All supertypes #{all_supertypes.map{|st| "#{st.object_id}=>#{st.name}"}*", "}"
                      if role_sequence.all_role_ref.detect{|rsr|
                          fact_type = rsr.role.fact_type
                          trace :pi, "      Role Sequence touches #{fact_type.describe(pi_role)}"

                          fact_type_roles = fact_type.all_role
                          trace :pi, "      residual is #{fact_type_roles.map{|r| r.object_type.name}.inspect} minus #{rsr.role.object_type.name}"
                          residual_roles = fact_type_roles-[rsr.role]
                          residual_roles.detect{|rfr|
                              trace :pi, "        Checking residual role #{rfr.object_type.object_id}=>#{rfr.object_type.name}"
# This next line looks right, but breaks things. Find out what and why:
#                              !rfr.unique or
                                !all_supertypes.include?(rfr.object_type)
                            }
                        }
                        trace :pi, "      Discounting this role_sequence because it includes alien roles"
                        next
                      end

                      # Any presence constraint over this role sequence is a candidate
                      rr.role_sequence.all_presence_constraint.detect{|pc|
                          # Found it!
                          if pc.is_preferred_identifier
                            trace :pi, "found PI #{pc.name||pc.object_id}, is_preferred_identifier=#{pc.is_preferred_identifier.inspect} over #{pc.role_sequence.describe}"
                            throw :pi, pc
                          end
                        }
                    }
                }
              throw :pi, nil
            end
          raise "Oops, pi for entity is #{pi.class}" if pi && !pi.is_a?(ActiveFacts::Metamodel::PresenceConstraint)
          trace :pi, "Got PI #{pi.name||pi.object_id} for #{name}" if pi

          if !pi
            if (supertype = identifying_supertype)
              # This shouldn't happen now, as an identifying supertype is connected by a fact type
              # that has a uniqueness constraint marked as the preferred identifier.
              #trace :pi, "PI not found for #{name}, looking in supertype #{supertype.name}"
              #pi = supertype.preferred_identifier
              #return nil
            elsif fact_type
              possible_pi = nil
              fact_type.all_role.each{|role|
                role.all_role_ref.each{|role_ref|
                  # Discount role sequences that contain roles not in this fact type:
                  next if role_ref.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type != fact_type }
                  role_ref.role_sequence.all_presence_constraint.each{|pc|
                    next unless pc.max_frequency == 1
                    possible_pi = pc
                    next unless pc.is_preferred_identifier
                    pi = pc
                    break
                  }
                  break if pi
                }
                break if pi
              }
              if !pi && possible_pi
                trace :pi, "Using existing PC as PI for #{name}"
                pi = possible_pi
              end
            else
              byebug
              trace :pi, "No PI found for #{name}"
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
        trace "Looking for identifying_supertype of #{name}"
        all_type_inheritance_as_subtype.detect{|ti|
            trace "considering supertype #{ti.supertype.name}"
            next unless ti.provides_identification
            trace "found identifying supertype of #{name}, it's #{ti.supertype.name}"
            return ti.supertype
          }
        trace "Failed to find identifying supertype of #{name}"
        return nil
      end

      def common_supertype(other)
        return nil unless other.is_?(ActiveFacts::Metamodel::EntityType)
        candidates = supertypes_transitive & other.supertypes_transitive
        return candidates[0] if candidates.size <= 1
        candidates[0] # REVISIT: This might not be the closest supertype
      end

      # This entity type has just objectified a fact type. Create the necessary ImplicitFactTypes with phantom roles
      def create_implicit_fact_types
        fact_type.all_role.map do |role|
          next if role.link_fact_type     # Already exists
          link_fact_type = @constellation.LinkFactType(:new, :implying_role => role)
          link_fact_type.concept.implication_rule = 'objectification'
          phantom_role = @constellation.Role(link_fact_type, 0, :object_type => self, :concept => :new)
          # We could create a copy of the visible external role here, but there's no need yet...
          # Nor is there a need for a presence constraint, readings, etc.
          link_fact_type
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
                if role_ref.role
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
                else
                  # We have an unknown role. The reading cannot be correctly expanded
                  player_name = "UNKNOWN"
                  role_name = nil
                  freq_con = nil
                end

                literal = literals[i]
                words = [
                  freq_con ? freq_con : nil,
                  l_adj,
                  define_role_names == false && role_name ? role_name : player_name,
                  t_adj,
                  define_role_names && role_name && player_name != role_name ? "(as #{role_name})" : nil,
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
        #trace "Expanded '#{expanded}' using #{frequency_constraints.inspect}"
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
        as_cql
      end

      def as_cql
        "restricted to "+
          ( if regular_expression
              '/' + regular_expression + '/'
            else
              '{' + all_allowed_range_sorted.map{|ar| ar.to_s(false) }*', ' + '}'
            end
          )
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
          all_allowed_range_sorted.map { |ar| ar.to_s(true) }*", " +
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
          if min.is_literal_string
            min_literal = min.literal.inspect.gsub(/\A"|"\Z/,"'")   # Escape string characters
          else
            min_literal = min.literal
          end
        else
          min_literal = infinity ? "-Infinity" : ""
        end
        if max = value_range.maximum_bound
          max = max.value
          if max.is_literal_string
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
        if is_literal_string
          "'"+
          literal.
            inspect.            # Use Ruby's inspect to generate necessary escapes
            gsub(/\A"|"\Z/,''). # Remove surrounding quotes
            gsub(/'/, "\\'") +  # Escape any single quotes
          "'"
        else
          literal
        end +
        (unit ? " " + unit.name : "")
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
        'PresenceConstraint over '+role_sequence.describe + " occurs " + frequency + " time#{(min&&min>1)||(max&&max>1) ? 's' : ''}"
      end
    end

    class SubsetConstraint
      def describe
        'SubsetConstraint(' +
        subset_role_sequence.describe 
        ' < ' +
        superset_role_sequence.describe +
        ')'
      end
    end

    class SetComparisonConstraint
      def describe
        self.class.basename+'(' +
        all_set_comparison_roles.map do |scr|
          scr.role_sequence.describe
        end*',' +
        ')'
      end
    end

    class RingConstraint
      def describe
        'RingConstraint(' +
        ring_type.to_s+': ' +
        role.describe+', ' +
        other_role.describe+' in ' +
        role.fact_type.default_reading +
        ')'
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
          "#{is_optional ? 'maybe ' : ''}" +
          (is_unary_step ? '(unary) ' : "from #{input_play.describe} ") +
          "#{is_disallowed ? 'not ' : ''}" +
          "to #{output_plays.map(&:describe)*', '}" +
          (objectification_variable ? ", objectified as #{objectification_variable.describe}" : '') +
          " '#{fact_type.default_reading}'"
      end

      def input_play
        all_play.detect{|p| p.is_input}
      end

      def output_plays
        all_play.reject{|p| p.is_input}
      end

      def is_unary_step
        # Preserve this in case we have to use a real variable for the phantom
        all_play.size == 1
      end

      def is_objectification_step
        !!objectification_variable
      end

      def external_fact_type
        fact_type.is_a?(LinkFactType) ? fact_type.role.fact_type : fact_type
      end
    end

    class Variable
      def describe
        object_type.name +
          (subscript ? "(#{subscript})" : '') +
          " Var#{ordinal}" +
          (value ? ' = '+value.to_s : '')
      end

      def all_step
        all_play.map(&:step).uniq
      end
    end

    class Play
      def describe
        "#{role.object_type.name} Var#{variable.ordinal}" +
          (role_ref ? " (projected)" : "")
      end
    end

    class Query
      def describe
        steps_shown = {}
        'Query(' +
          all_variable.sort_by{|var| var.ordinal}.map do |variable|
            variable.describe + ': ' +
            variable.all_step.map do |step|
              next if steps_shown[step]
              steps_shown[step] = true
              step.describe
            end.compact.join(',')
          end.join('; ') +
        ')'
      end

      def show
        steps_shown = {}
        trace :query, "Displaying full contents of Query #{concept.guid}" do
          all_variable.sort_by{|var| var.ordinal}.each do |variable|
            trace :query, "#{variable.describe}" do
              variable.all_step.
                each do |step|
                  next if steps_shown[step]
                  steps_shown[step] = true
                  trace :query, "#{step.describe}"
                end
              variable.all_play.each do |play|
                trace :query, "role of #{play.describe} in '#{play.role.fact_type.default_reading}'"
              end
            end
          end
        end
      end

      def all_step
        all_variable.map{|var| var.all_step.to_a}.flatten.uniq
      end

      # Check all parts of this query for validity
      def validate
        show
        return

        # Check the variables:
        steps = []
        variables = all_variable.sort_by{|var| var.ordinal}
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

    class LinkFactType
      def default_reading
        # There are two cases, where role is in a unary fact type, and where the fact type is objectified
        # If a unary fact type is objectified, only the LinkFactType for the objectification is asserted
        if objectification = implying_role.fact_type.entity_type
          "#{objectification.name} involves #{implying_role.object_type.name}"
        else
          implying_role.fact_type.default_reading+" Boolean"  # Must be a unary FT
        end
      end

      def add_reading implicit_reading
        @readings ||= []
        @readings << implicit_reading
      end

      def all_reading
        @readings ||=
          [ ImplicitReading.new(
              self,
              implying_role.fact_type.entity_type ? "{0} involves {1}" : implying_role.fact_type.default_reading+" Boolean"
            )
          ] +
          Array(implying_role.fact_type.entity_type ? ImplicitReading.new(self, "{1} is involved in {0}") : nil)
      end

      def reading_preferably_starting_with_role role, negated = false
        all_reading[role == implying_role ? 1 : 0]
      end

      # This is only used for debugging, from RoleRef#describe
      class ImplicitReading
        attr_accessor :fact_type, :text
        attr_reader :is_negative  # Never true

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
          def all_role_ref_in_order
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
          text.gsub(/\{([01])\}/) do
            if $1 == '0'
              fact_type.all_role[0].object_type.name
            else
              fact_type.implying_role.object_type.name
            end
          end
        end
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
            objectification_role = role.link_fact_type.all_role.single # Find the phantom role here
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
        trace :query, "ambiguous query, could be over #{counterpart_sups[0].name} or #{obj_sups[0].name}"
        if !roles.detect{|r| r.object_type == counterpart_sups[0]} and roles.detect{|r| r.object_type == obj_sups[0]}
          trace :query, "discounting #{counterpart_sups[0].name} in favour of direct objectification"
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

        return "#{object_type.name} (in which #{fact.verbalise(context)})" if object_type.fact_type

        # It's an entity that's not an objectified fact type

        # If it has a simple identifier, there's no need to fully verbalise the identifying facts.
        # This recursive block returns either the identifying value or nil
        simple_identifier = proc do |instance|
            if instance.object_type.is_a?(ActiveFacts::Metamodel::ValueType)
              instance
            else
              pi = instance.object_type.preferred_identifier
              identifying_role_refs = pi.role_sequence.all_role_ref_in_order
              if identifying_role_refs.size != 1
                nil
              else
                role = identifying_role_refs[0].role
                my_role = (role.fact_type.all_role.to_a-[role])[0]
                identifying_fact = my_role.all_role_value.detect{|rv| rv.instance == self}.fact
                irv = identifying_fact.all_role_value.detect{|rv| rv.role == role}
                identifying_instance = irv.instance
                simple_identifier.call(identifying_instance)
              end
            end
          end

        if (id = simple_identifier.call(self))
          "#{object_type.name} #{id.value}"
        else
          pi = object_type.preferred_identifier
          identifying_role_refs = pi.role_sequence.all_role_ref_in_order
          "#{object_type.name}" +
            " is identified by " +      # REVISIT: Where the single fact type is TypeInheritance, we can shrink this
            identifying_role_refs.map do |rr|
              rr = rr.preferred_reference
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

    class ContextNote
      def verbalise(context=nil)
        as_cql
      end

      def as_cql
        ' (' +
        ( if all_context_according_to
            'according to '
            all_context_according_to.map do |act|
              act.agent.agent_name+', '
            end.join('')
          end
        ) +
        context_note_kind.gsub(/_/, ' ') +
        ' ' +
        discussion +
        ( if agreement
            ', as agreed ' +
            (agreement.date ? ' on '+agreement.date.iso8601.inspect+' ' : '') +
            'by '
            agreement.all_context_agreed_by.map do |acab|
              acab.agent.agent_name+', '
            end.join('')
          else
            ''
          end
        ) +
        ')'
      end
    end

  end
end
