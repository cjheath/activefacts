#
#       ActiveFacts Generators.
#       Generation support superclass that sequences entity types to avoid forward references.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/api'
require 'activefacts/generate/helpers/inject'
require 'activefacts/generate/traits/ordered'

module ActiveFacts
  module Generate #:nodoc:
    module Helpers #:nodoc:
      class OrderedDumper #:nodoc:
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
          units_dump
          value_types_dump
          entity_types_dump
          fact_types_dump
          constraints_dump
          vocabulary_end
        end

        def units_dump
          done_banner = false
          units = @vocabulary.all_unit.to_a.sort_by{|u| u.name.gsub(/ /,'')}
          while units.size > 0
            i = 0
            while i < units.size
              unit = units[i]
              i += 1

              # Skip this one if the precursors haven't yet been dumped:
              next if unit.all_derivation_as_derived_unit.detect{|d| units.include?(d.base_unit) }

              # Even if we skip, we're done with this unit
              units.delete(unit)
              i -= 1

              # Skip value-type derived units
              next if unit.name =~ /\^/

              if !done_banner
                done_banner = true
                units_banner
              end
              unit_dump(unit)
            end
          end
          units_end if done_banner
        end

        def value_type_fork(o)
	  if o.name == "_ImplicitBooleanValueType"
	    # do nothing
	  elsif
	      !o.supertype                      # No supertype, i.e. a base type
	      o.all_role.size == 0 &&           # No roles
	      !o.is_independent &&              # not independent
	      !o.value_constraint &&		# No value constraints
	      o.concept.all_context_note_as_relevant_concept.size == 0 &&	# No context notes
	      o.all_instance.size == 0          # No instances
	    data_type_dump(o)
	  else
	    super_type_name = o.supertype ? o.supertype.name : o.name
	    length = (l = o.length) && l > 0 ? "#{l}" : nil
	    scale = (s = o.scale) && s > 0 ? "#{s}" : nil
	    facets = { :length => length, :scale => scale }
	    value_type_dump(o, super_type_name, facets)
	  end
	end

        def value_types_dump
          done_banner = false
          @vocabulary.all_object_type.sort_by{|o| o.name.gsub(/ /,'')}.each{|o|
              next unless o.is_a?(ActiveFacts::Metamodel::ValueType)

              value_type_banner unless done_banner
              done_banner = true

              value_type_chain_dump(o)
#              @object_types_dumped[o] = true
	      o.ordered_dumped!
            }
          value_type_end if done_banner
        end

        # Ensure that supertype gets dumped first
        def value_type_chain_dump(o)
          return if o.ordered_dumped
          value_type_chain_dump(o.supertype) if (o.supertype && !o.supertype.ordered_dumped)
          value_type_fork(o)
          o.ordered_dumped!
        end

        # Try to dump entity types in order of name, but we need
        # to dump ETs before they're referenced in preferred ids
        # if possible (it's not always, there may be loops!)
        def entity_types_dump
          # Build hash tables of precursors and followers to use:
          @precursors, @followers = *build_entity_dependencies

          done_banner = false
          sorted = @vocabulary.all_object_type.select{|o|
            o.is_a?(ActiveFacts::Metamodel::EntityType) # and !o.fact_type
          }.sort_by{|o| o.name.gsub(/ /,'')}
          panic = nil
          while true do
            count_this_pass = 0
            skipped_this_pass = 0
            sorted.each{|o|
		next if o.ordered_dumped	    # Already done

		trace :ordered, "Panicing to dump #{panic.name}" if panic
                # Can we do this yet?
		remaining_precursors = Array(@precursors[o])-[o]
                if (o != panic and                  # We don't *have* to do it (panic mode)
                    remaining_precursors.size > 0)  # precursors - still blocked
		  trace :ordered, "Can't dump #{o.name} despite panic for #{panic.name}, it still needs #{remaining_precursors.map(&:name)*', '}" if panic
                  skipped_this_pass += 1
                  next
                end
		trace :ordered, "Dumping #{o.name} in panic mode, even though it still needs #{remaining_precursors.map(&:name)*', '}" if panic

                entity_type_banner unless done_banner
                done_banner = true

                # We're going to emit o - remove it from precursors of others:
                (@followers[o]||[]).each{|f|
                    @precursors[f] -= [o]
                  }
                count_this_pass += 1
                panic = nil

                if (o.fact_type)
                  fact_type_dump_with_dependents(o.fact_type)
                  released_fact_types_dump(o)
                else
                  entity_type_dump(o)
                  released_fact_types_dump(o)
                end

                entity_type_group_end
              }

              # Check that we made progress if there's any to make:
              if count_this_pass == 0 && skipped_this_pass > 0
=begin
                if panic        # We were already panicing... what to do now?
                  # This won't happen again unless the above code is changed to decide it can't dump "panic".
		  bad = sorted.select do |o|
		      o.is_a?(ActiveFacts::Metamodel::EntityType) &&
		      !o.ordered_dumped &&
		      (Array(@precursors[o])-[o]).size > 0 &&
		      (Array(@followers[o])-[o]).size > 0
		    end

                  raise "Unresolvable cycle of forward references: " +
                    bad.map { |o| o.name }*', ' +
                    ":\n\t" +
		    (
		      bad.map do |o|
			o.name +
			  " depends on " +
			  (@precursors[o].uniq.map{|p| p.name}.sort*', ')
		      end
		    ) * "\n\t" +
		    "\n"
=end
#                else
                  # Find the object that has the most followers and no fwd-ref'd supertypes:
                  # This selection might be better if we allow PI roles to be fwd-ref'd...
                  panic = sorted.
                    select{|o| !o.ordered_dumped }.
                    sort_by{|o|
                        f = (@followers[o] || []) - [o];
                        o.supertypes.detect{|s| !s.ordered_dumped } ? 0 : -f.size
                      }[0]
                  trace :ordered, "Panic mode, selected #{panic.name} next"
#                end
              end

              break if skipped_this_pass == 0       # All done.

          end
        end

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
                    # debug ti.class.roles.verbalise; trace "all_type_inheritance_as_supertype"; exit
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

        # Dump all fact types for which all precursors (of which "o" is one) have been emitted:
        def released_fact_types_dump(o)
          roles = o.all_role
          begin
            progress = false
            roles.map(&:fact_type).uniq.select{|fact_type|
                # The fact type hasn't already been dumped but all its role players have
                !fact_type.ordered_dumped &&
                  !fact_type.is_a?(ActiveFacts::Metamodel::LinkFactType) &&
                  !fact_type.all_role.detect{|r| !r.object_type.ordered_dumped } &&
                  !fact_type.entity_type &&
                  derivation_precursors_complete(fact_type)
                # REVISIT: A derived fact type must not be dumped before its dependent fact types have
              }.sort_by{|fact_type|
                fact_type_key(fact_type)
              }.each{|fact_type|
                fact_type_dump_with_dependents(fact_type)
                # Objectified Fact Types may release additional fact types
                roles += fact_type.entity_type.all_role.sort_by{|role| role.ordinal} if fact_type.entity_type
                progress = true
              }
          end while progress
        end

        def derivation_precursors_complete(fact_type)
          pr = fact_type.preferred_reading
          return true unless jr = pr.role_sequence.all_role_ref.to_a[0].play
          query = jr.variable.query
          return false if query.all_step.detect{|js| !js.fact_type.ordered_dumped }
          return false if query.all_variable.detect{|jn| !jn.object_type.ordered_dumped }
          true
        end

        def skip_fact_type(f)
          return true if f.is_a?(ActiveFacts::Metamodel::TypeInheritance)
          return false if f.entity_type && !f.entity_type.ordered_dumped

          # REVISIT: There might be constraints we have to merge into the nested entity or subtype. 
          # These will come up as un-handled constraints:
	  # Dump this fact type only if it contains a presence constraint we've missed:
          pcs = @presence_constraints_by_fact[f]
          pcs && pcs.size > 0 && !pcs.detect{|c| !c.ordered_dumped }
        end

        # Dump one fact type.
        # Include as many as possible internal constraints in the fact type readings.
        def fact_type_dump_with_dependents(fact_type)
          fact_type.ordered_dumped!
          return if skip_fact_type(fact_type)

          if (et = fact_type.entity_type) &&
              (pi = et.preferred_identifier) &&
              pi.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type != fact_type }
            # trace "Dumping objectified FT #{et.name} as an entity, non-fact PI"
            entity_type_dump(et)
            released_fact_types_dump(et)
            return
          end

          # trace "#{fact_type.name} has readings:\n\t#{fact_type.readings.map(&:name)*"\n\t"}"
          # trace "Dumping #{fact_type.concept.guid} as a fact type"

          # Fact types that aren't nested have no names
          name = fact_type.entity_type && fact_type.entity_type.name

          fact_type_dump(fact_type, name)

          # REVISIT: Go through the residual constraints and re-process appropriate readings to show them

#CJH: Necessary?
          fact_type.ordered_dumped!
          fact_type.entity_type.ordered_dumped! if fact_type.entity_type
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
                  !fact_type.is_a?(ActiveFacts::Metamodel::LinkFactType) and
                  !fact_type.ordered_dumped and
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
                !fact_type.is_a?(ActiveFacts::Metamodel::LinkFactType)
            }.sort_by{|fact_type|
              fact_type_key(fact_type)
            }.each{|fact_type|
              next if fact_type.ordered_dumped
              # trace "Not dumped #{fact_type.verbalise}(#{fact_type.all_role.map{|r| r.object_type.name}*", "})"
              fact_type_banner unless done_banner
              done_banner = true
              fact_type_dump_with_dependents(fact_type)
            }

          fact_type_end if done_banner
        end

        def fact_instances_dump
          @vocabulary.fact_types.each{|f|
              # Dump the instances:
              f.facts.each{|i|
                raise "REVISIT: Not dumping fact instances"
                trace "\t\t"+i.to_s
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

        def constraints_dump
          heading = false
          @vocabulary.
	      all_constraint.
	      reject{|c| c.ordered_dumped}.
	      sort_by{ |c| constraint_sort_key(c) }.
	      each do |c|
            # Skip some PresenceConstraints:
            if c.is_a?(ActiveFacts::Metamodel::PresenceConstraint)
              # Skip uniqueness constraints that cover all roles of a fact type, they're implicit
              fact_types = c.role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq
              if fact_types.size == 1 &&
                !c.role_sequence.all_role_ref.detect{|rr| rr.play } &&
                c.max_frequency == 1 &&         # Uniqueness
                fact_types[0].all_role.size == c.role_sequence.all_role_ref.size
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

        def vocabulary_start
          trace "Should override vocabulary_start"
        end

        def vocabulary_end
          trace "Should override vocabulary_end"
        end

        def units_banner
        end

        def units_end
        end

        def unit_dump unit
        end

        def value_type_banner
          trace "Should override value_type_banner"
        end

        def value_type_end
          trace "Should override value_type_end"
        end

        def data_type_dump(o)
          trace "Should override data_type_dump"
        end

	def value_type_dump(o, super_type_name, facets)
          trace "Should override value_type_dump"
        end

        def entity_type_banner
          trace "Should override entity_type_banner"
        end

        def entity_type_group_end
          trace "Should override entity_type_group_end"
        end

        def non_subtype_dump(o, pi)
          trace "Should override non_subtype_dump"
        end

        def subtype_dump(o, supertypes, pi = nil)
          trace "Should override subtype_dump"
        end

        def append_ring_to_reading(reading, ring)
          trace "Should override append_ring_to_reading"
        end

        def fact_type_banner
          trace "Should override fact_type_banner"
        end

        def fact_type_end
          trace "Should override fact_type_end"
        end

        def fact_type_dump(fact_type, name)
          trace "Should override fact_type_dump"
        end

        def constraint_banner
          trace "Should override constraint_banner"
        end

        def constraint_end
          trace "Should override constraint_end"
        end

        def constraint_dump(c)
          trace "Should override constraint_dump"
        end

      end

      def dump(vocabulary, out = $>)
        OrderedDumper.new(vocabulary).dump(out)
      end
    end
  end
end
