#
#       ActiveFacts Generators.
#
#       Generate a glossary in HTML
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/api'

module ActiveFacts
  module Generate #:nodoc:
    class HTML #:nodoc:
      class GLOSSARY #:nodoc:
        # Base class for generators of object-oriented class libraries for an ActiveFacts vocabulary.
        def initialize(vocabulary, *options)
          @vocabulary = vocabulary
          @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
          options.each{|option| set_option(option) }
        end

        def set_option(option)
        end

        def puts(*a)
          @out.puts *a
        end

        def print(*a)
          @out.print *a
        end

        def generate(out = $>)
          @out = out
          vocabulary_start

          object_types_dump()

          vocabulary_end
        end

        def vocabulary_start
          puts "<link rel='stylesheet' href='css/orm2.css' media='screen' type='text/css'/>"
          puts "<h1>#{@vocabulary.name}</h1>"
          puts "<dl>"
        end

        def vocabulary_end
          puts "</dl>"
        end

        def object_types_dump
          @vocabulary.
            all_object_type.
            sort_by{|o| o.name.gsub(/ /,'').downcase}.
            each do |o|
              case o
              when ActiveFacts::Metamodel::TypeInheritance
                nil
              when ActiveFacts::Metamodel::ValueType
                value_type_dump(o)
              else
                if o.fact_type
                  objectified_fact_type_dump(o)
                else
                  entity_type_dump(o)
                end
              end
            end
        end

        def element(text, attrs, tag = 'span')
          "<#{tag}#{attrs.empty? ? '' : attrs.map{|k,v| " #{k}='#{v}'"}*''}>#{text}</#{tag}>"
        end

        # A definition of a term
        def termdef(name)
          element(name, {:name => name, :class => 'object_type'}, 'a')
        end

        # A reference to a defined term (excluding role adjectives)
        def termref(name)
          element(name, {:href=>'#'+name, :class=>:object_type}, 'a')
        end

        # Text that should appear as part of a term (including role adjectives)
        def term(name)
          element(name, :class=>:object_type)
        end

        def value_type_dump(o)
          return if o.all_role.size == 0  # Skip value types that are only used as supertypes
          puts "  <dt>" +
            "#{termdef(o.name)}" +
            " (Value Type" +
            (o.supertype ? ", written as #{termref(o.supertype.name)}" : "") +
            ")</dt>"

          puts "  <dd>"
          relevant_facts_and_constraints(o)
          puts "  </dd>"
        end

        def relevant_facts_and_constraints(o)
          puts(
            o.
              all_role.
              map{|r| r.fact_type}.
              uniq.
              reject{|ft| ft.is_a?(ActiveFacts::Metamodel::TypeInheritance) || ft.is_a?(ActiveFacts::Metamodel::ImplicitFactType) }.
              map { |ft| "    #{fact_type(ft, o)}</br>" }.
              sort * "\n"
          )
        end

        def expand_reading(r)
          element(
            r.expand do |role_ref, freq_con, l_adj, name, t_adj, role_name_def, literal|
              term_parts = [l_adj, termref(name), t_adj].compact
              [
                freq_con ? element(freq_con, :class=>:keyword) : nil,
                term_parts.size > 1 ? term([l_adj, termref(name), t_adj].compact*' ') : term_parts[0],
                role_name_def,
                literal
              ]
            end,
            {:class => 'copula'}
          )
        end

        def fact_type(ft, wrt = nil)
          role = ft.all_role.detect{|r| r.object_type == wrt}
          preferred_reading = ft.reading_preferably_starting_with_role(role)
          alternate_readings = ft.all_reading.reject{|r| r == preferred_reading}
          expand_reading(preferred_reading) +
            (alternate_readings.size > 0 ?
              ' (alternatively, ' +
              alternate_readings.map { |r| expand_reading(r)}*', ' +
              ')' : '')
        end

        def objectified_fact_type_dump(o)
          puts "  <dt>" +
            "#{termdef(o.name)}" +
            " (Objectification of #{fact_type(o.fact_type)})" +
            "</dt>"

          puts "  <dd>"
          # REVISIT: Output o.name "involves" "one" ... for o.fact_type.all_role_in_order
          relevant_facts_and_constraints(o)
          puts "  </dd>"
        end

        def entity_type_dump(o)
          pi = o.preferred_identifier
          supers = o.supertypes
          if (supers.size > 0) # Ignore identification by a supertype:
            pi = nil if pi && pi.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) }
          end

          puts "  <dt>" +
            "#{termdef(o.name)}" +
            " (" +
            (supers.size > 0 ? "Subtype of #{}" : "Entity Type") +
            (pi ? " identified by "+pi.role_sequence.describe : '') +
            ")" +
            "</dt>"

          puts "  <dd>"
          relevant_facts_and_constraints(o)
          puts "  </dd>"
        end

#======================================================================
=begin

        def identified_by(o, pi)
          # Different adjectives might be used for different readings.
          # Here, we must find the role_ref containing the adjectives that we need for each identifier,
          # which will be attached to the uniqueness constraint on this object in the binary FT that
          # attaches that identifying role.
          identifying_role_refs = pi.role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}

          # We need to get the adjectives for the roles from the identifying fact's preferred readings:
          identifying_facts = ([o.fact_type]+identifying_role_refs.map{|rr| rr.role.fact_type }).compact.uniq

          identification = identified_by_roles_and_facts(o, identifying_role_refs, identifying_facts)

          identification
        end

        def describe_fact_type(fact_type, highlight = nil)
          (fact_type.entity_type ? fact_type.entity_type.name : "")+
          describe_roles(fact_type.all_role, highlight)
        end

        def describe_roles(roles, highlight = nil)
          "("+
          roles.map{|role| role.object_type.name + (role == highlight ? "*" : "")}*", "+
          ")"
        end

        def describe_role_sequence(role_sequence)
          "("+
          role_sequence.all_role_ref.map{|role_ref| role_ref.role.object_type.name }*", "+
          ")"
        end

        # This returns an array of two hash tables each keyed by an EntityType.
        # The values of each hash entry are the precursors and followers (respectively) of that entity.
        def build_entity_dependencies
          @vocabulary.all_object_type.inject([{},{}]) { |a, o|
              if o.is_a?(ActiveFacts::Metamodel::EntityType)
                precursor = a[0]
                follower = a[1]
                blocked = false
                pi = o.preferred_identifier
                if pi
                  pi.role_sequence.all_role_ref.each{|rr|
                      role = rr.role
                      player = role.object_type
                      # REVISIT: If we decide to emit value types on demand, need to remove this:
                      next unless player.is_a?(ActiveFacts::Metamodel::EntityType)
                      # player is a precursor of o
                      (precursor[o] ||= []) << player if (player != o)
                      (follower[player] ||= []) << o if (player != o)
                    }
                end
                if o.fact_type
                  o.fact_type.all_role.each do |role|
                    next unless role.object_type.is_a?(ActiveFacts::Metamodel::EntityType)
                    (precursor[o] ||= []) << role.object_type
                    (follower[role.object_type] ||= []) << o
                  end
                end

                # Supertypes are precursors too:
                subtyping = o.all_type_inheritance_as_supertype
                next a if subtyping.size == 0
                subtyping.each{|ti|
                    # debug ti.class.roles.verbalise; debug "all_type_inheritance_as_supertype"; exit
                    s = ti.subtype
                    (precursor[s] ||= []) << o
                    (follower[o] ||= []) << s
                  }
  #            REVISIT: Need to use this to order ValueTypes after their supertypes
  #            else
  #              o.all_value_type_as_supertype.each { |s|
  #                (precursor[s] ||= []) << o
  #                (follower[o] ||= []) << s
  #              }
              end
              a
            }
        end

        def derivation_precursors_complete(fact_type)
          pr = fact_type.preferred_reading
          return true unless jr = pr.role_sequence.all_role_ref.to_a[0].join_role
          join = jr.join_node.join
          return false if join.all_join_step.detect{|js| !@fact_types_dumped[js.fact_type] }
          return false if join.all_join_node.detect{|jn| !@object_types_dumped[jn.object_type] }
          true
        end

        def skip_fact_type(f)
          # REVISIT: There might be constraints we have to merge into the nested entity or subtype. 
          # These will come up as un-handled constraints:
          pcs = @presence_constraints_by_fact[f]
          return true if f.is_a?(ActiveFacts::Metamodel::TypeInheritance)
          return false if f.entity_type && !@object_types_dumped[f.entity_type]
          pcs && pcs.size > 0 && !pcs.detect{|c| !@constraints_used[c] }
        end

        # Dump one fact type.
        # Include as many as possible internal constraints in the fact type readings.
        def fact_type_dump_with_dependents(fact_type)
          @fact_types_dumped[fact_type] = true
          # debug "Trying to dump FT again" if @fact_types_dumped[fact_type]
          return if skip_fact_type(fact_type)

          if (et = fact_type.entity_type) &&
              (pi = et.preferred_identifier) &&
              pi.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type != fact_type }
            # debug "Dumping objectified FT #{et.name} as an entity, non-fact PI"
            entity_type_dump(et)
            released_fact_types_dump(et)
            return
          end

          fact_constraints = @presence_constraints_by_fact[fact_type]

          # debug "for fact type #{fact_type.to_s}, considering\n\t#{fact_constraints.map(&:to_s)*",\n\t"}"
          # debug "#{fact_type.name} has readings:\n\t#{fact_type.readings.map(&:name)*"\n\t"}"
          # debug "Dumping #{fact_type.fact_type_id} as a fact type"

          # Fact types that aren't nested have no names
          name = fact_type.entity_type && fact_type.entity_type.name

          fact_type_dump(fact_type, name)

          # REVISIT: Go through the residual constraints and re-process appropriate readings to show them

          @fact_types_dumped[fact_type] = true
          @object_types_dumped[fact_type.entity_type] = true if fact_type.entity_type
        end

        # Dump fact types.
        def fact_types_dump
          # REVISIT: Uniqueness on the LHS of a binary can be coded using "distinct"

          # The only fact types that can be remaining are those involving only value types,
          # since we dumped every fact type as soon as all relevant entities were dumped.
          # Iterate over all fact types of all value types, looking for these strays.

          done_banner = false
          fact_collection = @vocabulary.constellation.FactType
          fact_collection.keys.select{|fact_id|
                  fact_type = fact_collection[fact_id] and
                  !fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) and
                  !fact_type.is_a?(ActiveFacts::Metamodel::ImplicitFactType) and
                  !@fact_types_dumped[fact_type] and
                  !skip_fact_type(fact_type) and
                  !fact_type.all_role.detect{|r| r.object_type.is_a?(ActiveFacts::Metamodel::EntityType) }
              }.sort_by{|fact_id|
                  fact_type = fact_collection[fact_id]
                  fact_type_key(fact_type)
              }.each{|fact_id|
                  fact_type = fact_collection[fact_id]

                  fact_type_banner unless done_banner
                  done_banner = true
                  fact_type_dump_with_dependents(fact_type)
            }

          # REVISIT: Find out why some fact types are missed during entity dumping:
          @vocabulary.constellation.FactType.values.select{|fact_type|
              !fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) &&
                !fact_type.is_a?(ActiveFacts::Metamodel::ImplicitFactType)
            }.sort_by{|fact_type|
              fact_type_key(fact_type)
            }.each{|fact_type|
              next if @fact_types_dumped[fact_type]
              # debug "Not dumped #{fact_type.verbalise}(#{fact_type.all_role.map{|r| r.object_type.name}*", "})"
              fact_type_banner unless done_banner
              done_banner = true
              fact_type_dump_with_dependents(fact_type)
            }

          fact_type_end if done_banner
          # unused = constraints - @constraints_used.keys
          # debug "residual constraints are\n\t#{unused.map(&:to_s)*",\n\t"}"

          @constraints_used
        end

        def fact_instances_dump
          @vocabulary.fact_types.each{|f|
              # Dump the instances:
              f.facts.each{|i|
                raise "REVISIT: Not dumping fact instances"
                debug "\t\t"+i.to_s
              }
          }
        end

        # Arrange for objectified fact types to appear in order of name, after other fact types.
        # Facts are ordered alphabetically by the names of their role players,
        # then by preferred_reading (subtyping fact types have no preferred_reading).
        def fact_type_key(fact_type)
          role_names =
            if (pr = fact_type.preferred_reading)
              pr.role_sequence.
                all_role_ref.
                sort_by{|role_ref| role_ref.ordinal}.
                map{|role_ref| [ role_ref.leading_adjective, role_ref.role.object_type.name, role_ref.trailing_adjective ].compact*"-" } +
                [pr.text]
            else
              fact_type.all_role.map{|role| role.object_type.name }
            end

          (fact_type.entity_type ? [fact_type.entity_type.name] : [""]) + role_names
        end

        def role_ref_key(role_ref)
          [ role_ref.leading_adjective, role_ref.role.object_type.name, role_ref.trailing_adjective ].compact*"-" +
          " in " +
          role_ref.role.fact_type.preferred_reading.expand
        end

        def constraint_sort_key(c)
          case c
          when ActiveFacts::Metamodel::RingConstraint
            [ 1,
              c.ring_type,
              c.role.object_type.name,
              c.other_role.object_type.name,
              c.name||""
            ]
          when ActiveFacts::Metamodel::SetExclusionConstraint
            [ 2+(c.is_mandatory ? 0 : 1),
              c.all_set_comparison_roles.map{|scrs|
                scrs.role_sequence.all_role_ref.map{|rr|
                  role_ref_key(rr)
                }
              },
              c.name||""
            ]
          when ActiveFacts::Metamodel::SetEqualityConstraint
            [ 4,
              c.all_set_comparison_roles.map{|scrs|
                scrs.role_sequence.all_role_ref.map{|rr|
                  role_ref_key(rr)
                }
              },
              c.name||""
            ]
          when ActiveFacts::Metamodel::SubsetConstraint
            [ 5,
              [c.superset_role_sequence, c.subset_role_sequence].map{|rs|
                rs.all_role_ref.map{|rr|
                  role_ref_key(rr)
                }
              },
              c.name||""
            ]
          when ActiveFacts::Metamodel::PresenceConstraint
            [ 6,
              c.role_sequence.all_role_ref.map{|rr|
                role_ref_key(rr)
              },
              c.name||""
            ]
          end
        end

        def constraints_dump(except = {})
          heading = false
          @vocabulary.all_constraint.reject{|c| except[c]}.sort_by{ |c| constraint_sort_key(c) }.each do|c|
            # Skip some PresenceConstraints:
            if c.is_a?(ActiveFacts::Metamodel::PresenceConstraint)
              # Skip uniqueness constraints that cover all roles of a fact type, they're implicit
              fact_types = c.role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq
              if fact_types.size == 1 &&
                !c.role_sequence.all_role_ref.detect{|rr| rr.join_role } &&
                c.max_frequency == 1 &&         # Uniqueness
                fact_types[0].all_role.size == c.role_sequence.all_role_ref.size
                # debugger if !$constraint_id || c.constraint_id.object_id == $foo
                # $constraint_id ||= 1
                next
              end

              # Skip internal PresenceConstraints over TypeInheritances:
              next if c.role_sequence.all_role_ref.size == 1 &&
                fact_types[0].is_a?(ActiveFacts::Metamodel::TypeInheritance)
            end

            constraint_banner unless heading
            heading = true

            # Skip presence constraints on value types:
            # next if ActiveFacts::PresenceConstraint === c &&
            #     ActiveFacts::ValueType === c.object_type
            constraint_dump(c)
          end
          constraint_end if heading
        end

        def units_end
        end

        def unit_dump unit
        end

        def fact_type_banner
          debug "Should override fact_type_banner"
        end

        def fact_type_end
          debug "Should override fact_type_end"
        end

        def fact_type_dump(fact_type, name)
          debug "Should override fact_type_dump"
        end

        def constraint_end
          debug "Should override constraint_end"
        end

        def constraint_dump(c)
          debug "Should override constraint_dump"
        end
=end

      end
    end
  end
end
