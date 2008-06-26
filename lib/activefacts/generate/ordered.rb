#
# Generator superclass for ActiveFacts vocabularies that performs sequencing to avoid forward references.
#
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  class Constellation; end

  class OrderedDumper
    include Metamodel

    def initialize(vocabulary)
      @vocabulary = vocabulary
    end

    def puts(*a)
      @out.puts *a
    end

    def generate(out = $>)
      @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::Constellation === @vocabulary
      @out = out
      vocabulary_start(@vocabulary)

      build_indices
      @concept_types_dumped = {}
      @fact_types_dumped = {}
      value_types_dump()
      entity_types_dump()
      fact_types_dump()
      constraints_dump(@constraints_used)
      vocabulary_end
    end

    def build_indices
      @presence_constraints_by_fact = Hash.new{ |h, k| h[k] = [] }
      @ring_constraints_by_fact = Hash.new{ |h, k| h[k] = [] }

      @vocabulary.all_constraint.each { |c|
          case c
          when PresenceConstraint
            fact_types = c.role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq  # All fact types spanned by this constraint
            if fact_types.size == 1     # There's only one, save it:
              # debug "Single-fact constraint on #{fact_types[0].fact_type_id}: #{c.name}"
              (@presence_constraints_by_fact[fact_types[0]] ||= []) << c
            end
          when RingConstraint
            (@ring_constraints_by_fact[c.role.fact_type] ||= []) << c
          else
            # debug "Found unhandled constraint #{c.class} #{c.name}"
          end
        }
      @constraints_used = {}
      @fact_set_constraints_exhausted = {}
    end

    def value_types_dump
      done_banner = false
      @vocabulary.all_feature.sort_by{|o| o.name}.each{|o|
          next unless ValueType === o

          value_type_banner unless done_banner
          done_banner = true

          value_type_dump(o)
          @concept_types_dumped[o] = true
        }
      value_type_end if done_banner
    end

    # Try to dump entity types in order of name, but we need
    # to dump ETs before they're referenced in preferred ids
    # if possible (it's not always, there may be loops!)
    def entity_types_dump
      # Build hash tables of precursors and followers to use:
      precursors, followers = *build_entity_dependencies

      done_banner = false
      sorted = @vocabulary.all_feature.select{|o| EntityType === o and !o.fact_type }.sort_by{|o| o.name}
      panic = nil
      while true do
        count_this_pass = 0
        skipped_this_pass = 0
        sorted.each{|o|
            next if @concept_types_dumped[o]    # Already done

            # Can we do this yet?
            if (o != panic and                  # We don't *have* to do it (panic mode)
                (p = precursors[o]) and         # There might be...
                p.size > 0)                     # precursors - still blocked
              skipped_this_pass += 1
              next
            end

            entity_type_banner unless done_banner
            done_banner = true

            # We're going to emit o - remove it from precursors of others:
            (followers[o]||[]).each{|f|
                precursors[f] -= [o]
              }
            count_this_pass += 1
            panic = nil

            entity_type_dump(o)
            released_fact_types_dump(o)

            entity_type_group_end
          }

          # Check that we made progress if there's any to make:
          if count_this_pass == 0 && skipped_this_pass > 0
            if panic        # We were already panicing... what to do now?
              # This won't happen again unless the above code is changed to decide it can't dump "panic".
              raise "Unresolvable cycle of forward references: " +
                (bad = sorted.select{|o| EntityType === o && !@concept_types_dumped[o]}).map{|o| o.name }.inspect +
                ":\n\t" + bad.map{|o|
                  o.name +
                  ": " +
                  precursors[o].map{|p| p.name}.uniq.inspect
                } * "\n\t" + "\n"
            else
              # Find the object that has the most followers and no fwd-ref'd supertypes:
              # This selection might be better if we allow PI roles to be fwd-ref'd...
              panic = sorted.
                select{|o| !@concept_types_dumped[o] }.
                sort_by{|o|
                    f = followers[o] || []; 
                    o.supertypes.detect{|s| !@concept_types_dumped[s] } ? 0 : -f.size
                  }[0]
              # debug "Panic mode, selected #{panic.name} next"
            end
          end

          break if skipped_this_pass == 0       # All done.

      end
    end

    def entity_type_dump(o)
      @concept_types_dumped[o] = true
      pi = o.preferred_identifier

      #debug "#{o.name} is a subtype!!!" if o.all_type_inheritance_by_subtype.size > 0

      supers = o.supertypes
      if (supers.size > 0)
        supertype = o.identifying_supertype || supers[0]
        #debug "#{supertype.name} is identifying_supertype of #{o.name}"
        spi = supertype.preferred_identifier
        subtype_dump(o, supers, pi != spi ? pi : nil)
      else
        non_subtype_dump(o, pi)
      end
      @constraints_used[pi] = true
    end

    def identified_by(o, pi)
      # Different adjectives might be used for different readings.
      # Here, we must find the role_ref containing the adjectives that we need for each identifier,
      # which will be attached to the uniqueness constraint on this object in the binary FT that
      # attaches that identifying role.
      role_refs = pi.role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}

      # We need to get the adjectives for the roles from the identifying fact's preferred readings:
      identifying_facts = role_refs.map{|rr| rr.role.fact_type }.uniq
      preferred_readings = identifying_facts.inject({}){|reading_hash, fact_type|
          pr = fact_type.preferred_reading
          reading_hash[fact_type] = pr
          reading_hash
        }
      #p identifying_facts.map{|f| f.preferred_reading }

      identifying_roles = role_refs.map(&:role)
      identification = identified_by_roles_and_facts(identifying_roles, identifying_facts, preferred_readings)
      identifying_facts.each{|f| @fact_types_dumped[f] = true }

      # REVISIT: Consider emitting extra fact types here, instead of in entity_type_dump?
      # Just beware that readings having the same players will be considered to be of the same fact type, even if they're not.
      identification
    end

    def fact_readings_with_constraints(fact_type)
      define_role_names = true
      fact_constraints = @presence_constraints_by_fact[fact_type]
      used_constraints = []
      readings = fact_type.all_reading_by_ordinal.inject([]){|reading_array, reading|
          # Find all role numbers in order of occurrence in this reading:
          role_refs = reading.role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}
          role_numbers = reading.reading_text.scan(/\{(\d)\}/).flatten.map{|m| Integer(m) }
          roles = role_numbers.map{|m| role_refs[m].role }
          # debug "Considering #{reading.reading_text} having #{role_numbers.inspect}"

          # Find the constraints that constrain frequency over each role we can verbalise:
          frequency_constraints = []
          role_mandatory_but_not_unique = []
          roles.each {|role|
              # Find a mandatory constraint that's *not* unique; this will need an extra reading
              role_is_first_in = fact_type.all_reading.detect{|r|
                  role == r.role_sequence.all_role_ref.sort_by{|role_ref|
                      role_ref.ordinal
                    }[0].role
                }

              role_mandatory_but_not_unique <<
                (
                  (!role_is_first_in || role_is_first_in == reading) &&
                  fact_constraints.find{|c|
                      PresenceConstraint === c &&
                      c.is_mandatory &&
                      (!c.max_frequency || c.max_frequency > 1) &&
                      c.role_sequence == [role] &&
                      !@constraints_used[c]     # Already verbalised
                    }
                )

              if (role != roles[0])   # First role of the reading?
                # REVISIT: With a ternary, doing this on other than the last role can be ambiguous,
                # in case both the 2nd and 3rd roles have frequencies. Think some more!

                constraint = fact_constraints.find{|c|  # Find a UC that spans all other Roles
                    # internal uniqueness constraints span all roles but one, the residual:
                    PresenceConstraint === c &&
                      !@constraints_used[c] &&  # Already verbalised
                      roles-c.role_sequence.all_role_ref.map(&:role) == [role]
                  }
                # Index the frequency implied by the constraint under the role position in the reading
                if constraint     # Mark this constraint as "verbalised" so we don't do it again:
                  @constraints_used[constraint] = true
                  used_constraints << constraint
                end
                frequency_constraints << constraint
              else
                frequency_constraints << nil
              end
            }

          reading_array << expand_reading(reading, frequency_constraints, define_role_names)

          if (ft_rings = @ring_constraints_by_fact[fact_type]) &&
             (ring = ft_rings.detect{|rc| !@constraints_used[rc]})
            @constraints_used[ring] = true
            used_constraints << ring
            append_ring_to_reading(reading_array[-1], ring)
          end

          define_role_names = false     # No need to define role names in subsequent readings

          # REVISIT: This section doesn't seem to be firing:
          # If the first Role is mandatory but not unique, and we haven't absorbed this
          # mandation into a uniqueness constraint, we need to re-iterate this reading by
          # saying "each X has some Y for some Z"
          role_mandatory_but_not_unique.each_with_index{|mc, i|
              next unless mc
              frequencies = [ "some" ]*i + [ "each" ] + [ "some" ]*(roles.size-i-1)
              raise "REVISIT: Not yet reimplemented"
              reading_array << reading.expand(frequencies, false)

              # REVISIT: If min > 1 (a frequency constraint), this constraint isn't fully verbalised
#             if first_role_mandatory.min == 1
                @constraints_used[mc] = true
                used_constraints << mc
#             end
            }

          reading_array
        }
      # debug "Used #{fact_constraints_used} of #{used_constraints.uniq.size} constraints over #{fact_type.name}"
      if (fact_constraints-used_constraints).size == 0
        # We've exhausted the set constraints on this fact type.
        @fact_set_constraints_exhausted[fact_type] = true
      end
      readings
    end

    def describe_fact_type(fact_type, highlight = nil)
      (fact_type.entity_type ? fact_type.entity_type.name : "")+
      describe_roles(fact_type.all_role, highlight)
    end

    def describe_roles(roles, highlight = nil)
      "("+
      roles.map{|role| role.concept.name + (role == highlight ? "*" : "")}*", "+
      ")"
    end

    def describe_role_sequence(role_sequence)
      "("+
      role_sequence.all_role_ref.map{|role_ref| role_ref.role.concept.name }*", "+
      ")"
    end

    # This returns an array of two hash tables each keyed by an EntityType.
    # The values of each hash entry are the precursors and followers (respectively) of that entity.
    def build_entity_dependencies
      @vocabulary.all_feature.inject([{},{}]) { |a, o|
          if EntityType === o && !o.fact_type
            precursor = a[0]
            follower = a[1]
            blocked = false
            pi = o.preferred_identifier
            if pi
              pi.role_sequence.all_role_ref.each{|rr|
                  role = rr.role
                  player = role.concept
                  next unless EntityType === player
                  # player is a precursor of o
                  (precursor[o] ||= []) << player if (player != o)
                  (follower[player] ||= []) << o if (player != o)
                }
            end
            # Supertypes are precursors too:
            subtyping = o.all_type_inheritance_by_supertype
            next a if subtyping.size == 0
            subtyping.each{|ti|
                # debug ti.class.roles.verbalise; debug "all_type_inheritance_by_supertype"; exit
                s = ti.subtype
                (precursor[s] ||= []) << o
                (follower[o] ||= []) << s
              }
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
            !@fact_types_dumped[fact_type] &&
              !fact_type.all_role.detect{|r| !@concept_types_dumped[r.concept] }
          }.each{|fact_type|
              fact_type_dump_with_dependents(fact_type)
              # Objectified Fact Types may release additional fact types
              roles += fact_type.entity_type.all_role if fact_type.entity_type
              progress = true
            }
      end while progress
    end

    def skip_fact_type(f)
      # REVISIT: There might be constraints we have to merge into the nested entity or subtype. 
      # These will come up as un-handled constraints:
      @fact_set_constraints_exhausted[f] ||
        TypeInheritance === f
    end

    # Dump one fact type.
    # Include as many as possible internal constraints in the fact type readings.
    def fact_type_dump_with_dependents(fact_type)
      @fact_types_dumped[fact_type] = true
      # debug "Trying to dump FT again" if @fact_types_dumped[fact_type]
      return if skip_fact_type(fact_type)

      if (et = fact_type.entity_type) &&
          (pi = et.preferred_identifier) &&
          pi.role_sequence.all_role_ref[0].role.fact_type != fact_type
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

      fact_type_dump(fact_type, name, fact_readings_with_constraints(fact_type))

      # REVISIT: Go through the residual constraints and re-process appropriate readings to show them

      @fact_types_dumped[fact_type] = true
      @concept_types_dumped[fact_type.entity_type] = true if fact_type.entity_type
    end

    # Dump fact types.
    def fact_types_dump
      # REVISIT: Uniqueness on the LHS of a binary can be coded using "distinct"

      # The only fact types tht can be remaining are those involving only value types,
      # since we dumped every fact type as soon as all relevant entities were dumped.
      # Iterate over all fact types of all value types, looking for these strays.

      done_banner = false
      fact_collection = @vocabulary.constellation.FactType
      fact_collection.keys.select{|fact_id|
              fact_type = fact_collection[fact_id]
              !(TypeInheritance === fact_type) and
              !@fact_types_dumped[fact_type] and
              !skip_fact_type(fact_type) and
              !fact_type.all_role.detect{|r| EntityType === r.concept }
          }.sort_by{|fact_id|
              fact_type = fact_collection[fact_id]
              (fact_type.entity_type ? [fact_type.entity_type.name] : nil) ||
                  fact_type.all_role.map{|role| role.concept.name }
          }.each{|fact_id|
              fact_type = fact_collection[fact_id]

              fact_type_banner unless done_banner
              done_banner = true
              fact_type_dump_with_dependents(fact_type)
        }

      # REVISIT: Find out why some fact types are missed during entity dumping:
      @vocabulary.constellation.FactType.values.select{|fact_type| !(TypeInheritance === fact_type)}.sort_by{|fact_type|
          # Any sort key, as long as the result is stable. That means unique too!
          [ (pr = fact_type.preferred_reading).
              role_sequence.
              all_role_ref.
              sort_by{|role_ref| role_ref.ordinal}.
              map{|role_ref| [ role_ref.role.concept.name, role_ref.leading_adjective||"", role_ref.trailing_adjective||"" ] },
            pr.reading_text
          ]
        }.each{|fact_type|
          next if @fact_types_dumped[fact_type]
          # debug "Not dumped #{fact_type.verbalise}(#{fact_type.all_role.map{|r| r.concept.name}*", "})"
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

    def constraints_dump(except = {})
      heading = false
      @vocabulary.all_constraint.sort_by{|c| c.name || ""}.each{|c|
          next if except[c]

          # Skip some PresenceConstraints:
          if PresenceConstraint === c
            # Skip uniqueness constraints that cover all roles of a fact type, they're implicit
            role_refs = c.role_sequence.all_role_ref
            if role_refs.size == 0
              constraint_banner unless heading
              heading = true
              puts "PresenceConstraint without roles!" 
              next
            end
            fact_type0 = role_refs[0].role.fact_type
            next if c.max_frequency == 1 &&         # Uniqueness
              role_refs.size == fact_type0.all_role.size &&     # Same number of roles
              fact_type0.all_role.all?{|r| role_refs.map(&:role).include? r}    # All present

            # Skip internal PresenceConstraints over TypeInheritances:
            next if TypeInheritance === fact_type0 &&
              !c.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type != fact_type0 }
          end

          constraint_banner unless heading
          heading = true

          # Skip presence constraints on value types:
          # next if ActiveFacts::PresenceConstraint === c &&
          #     ActiveFacts::ValueType === c.concept
          constraint_dump(c)
        }
      constraint_end if heading
    end

    def vocabulary_start(vocabulary)
      debug "Should override vocabulary_start"
    end

    def vocabulary_end
      debug "Should override vocabulary_end"
    end

    def value_type_banner
      debug "Should override value_type_banner"
    end

    def value_type_end
      debug "Should override value_type_end"
    end

    def value_type_dump(o)
      debug "Should override value_type_dump"
    end

    def entity_type_banner
      debug "Should override entity_type_banner"
    end

    def entity_type_group_end
      debug "Should override entity_type_group_end"
    end

    def non_subtype_dump(o, pi)
      debug "Should override non_subtype_dump"
    end

    def subtype_dump(o, supertypes, pi = nil)
      debug "Should override subtype_dump"
    end

    def expand_reading(reading, frequency_constraints, define_role_names)
      debug "Should override expand_reading"
    end

    def append_ring_to_reading(reading, ring)
      debug "Should override append_ring_to_reading"
    end

    def fact_type_banner
      debug "Should override fact_type_banner"
    end

    def fact_type_end
      debug "Should override fact_type_end"
    end

    def fact_type_dump(fact_type, name, readings)
      debug "Should override fact_type_dump"
    end

    def constraint_banner
      debug "Should override constraint_banner"
    end

    def constraint_end
      debug "Should override constraint_end"
    end

    def constraint_dump(c)
      debug "Should override constraint_dump"
    end

  end

  def dump(vocabulary, out = $>)
    OrderedDumper.new(vocabulary).dump(out)
  end
end
