#
# Generate CQL from an ActiveFacts vocabulary.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/generate/ordered'

module ActiveFacts
  class Constellation; end

  module Generate
    class CQL < OrderedDumper
      include Metamodel

      def vocabulary_start(vocabulary)
        puts "vocabulary #{vocabulary.name};\n\n"
      end

      def vocabulary_end
      end

      def value_type_banner
        puts "/*\n * Value Types\n */"
      end

      def value_type_end
        puts "\n"
      end

      def value_type_dump(o)
        return unless o.supertype    # An imported type
        if o.name == o.supertype.name
            # In ActiveFacts, parameterising a ValueType will create a new datatype
            # throw Can't handle parameterized value type of same name as its datatype" if ...
        end

        parameters =
          [ o.length != 0 || o.scale != 0 ? o.length : nil,
            o.scale != 0 ? o.scale : nil
          ].compact
        parameters = parameters.length > 0 ? "("+parameters.join(",")+")" : "()"

                  #" restricted to {#{(allowed_values.map{|r| r.inspect}*", ").gsub('"',"'")}}")

        puts "#{o.name} is defined as #{o.supertype.name}#{ parameters }#{
            o.value_restriction ? " restricted to {#{
              o.value_restriction.all_allowed_range.map{|ar|
                  # REVISIT: Need to display as string or numeric according to type here...
                  min = ar.value_range.minimum_bound
                  max = ar.value_range.maximum_bound

                  (min ? min.value : "") +
                  (min.value != (max&&max.value) ? (".." + (max ? max.value : "")) : "")
                }*", "
            }}" : ""
          };"
      end

      def append_ring_to_reading(reading, ring)
        reading << " [#{(ring.ring_type.scan(/[A-Z][a-z]*/)*", ").downcase}]"
      end

      def identified_by_roles_and_facts(identifying_roles, identifying_facts, preferred_readings)
        identifying_role_names = identifying_roles.map{|role|
            preferred_role_ref = preferred_readings[role.fact_type].role_sequence.all_role_ref.detect{|reading_rr|
                reading_rr.role == role
              }
            role_words = []
            # REVISIT: Consider whether NOT to use the adjective if it's a prefix of the role_name

            role_name = role.role_name
            role_name = nil if role_name == ""
            # debug "concept.name=#{preferred_role_ref.role.concept.name}, role_name=#{role_name.inspect}, preferred_role_name=#{preferred_role_ref.role.role_name.inspect}"

            if (role_name)
              role_name
            else
              role_words << preferred_role_ref.leading_adjective if preferred_role_ref.leading_adjective != ""
              role_words << preferred_role_ref.role.concept.name
              role_words << preferred_role_ref.trailing_adjective if preferred_role_ref.trailing_adjective != ""
              role_words.compact*"-"
            end
          }

        # REVISIT: Consider emitting extra fact types here, instead of in entity_type_dump?
        # Just beware that readings having the same players will be considered to be of the same fact type, even if they're not.

        " identified by #{ identifying_role_names*" and " }:\n\t" +
            identifying_facts.map{|f|
                fact_readings_with_constraints(f)
            }.flatten*",\n\t"
      end

      def entity_type_banner
        puts "/*\n * Entity Types\n */"
      end

      def entity_type_group_end
        puts "\n"
      end

      def fact_readings(fact_type)
        constrained_fact_readings = fact_readings_with_constraints(fact_type)
        constrained_fact_readings*",\n\t"
      end

      def subtype_dump(o, supertypes, pi)
        print "#{o.name} is a kind of #{ o.supertypes.map(&:name)*", " }"
        print identified_by(o, pi) if pi
        # If there's a preferred_identifier for this subtype, identifying readings were emitted
        print((pi ? "," : " where") + "\n\t" + fact_readings(o.fact_type)) if o.fact_type
        puts ";\n"
      end

      def non_subtype_dump(o, pi)
        print "#{o.name} is" + identified_by(o, pi)
        print(",\n\t"+ fact_readings(o.fact_type)) if o.fact_type
        puts ";\n"
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

      def fact_type_dump(fact_type, name)
        # REVISIT: Handle alternate identification of objectified fact type

        if (o = fact_type.entity_type)
          if !o.all_type_inheritance_by_subtype.empty?
            print "#{o.name} is a kind of #{ o.supertypes.map(&:name)*", " } where\n\t"
          else
            print(name ? name+" is where\n\t" : "")
          end
        end

        puts(fact_readings(fact_type)+";")
      end

      def fact_type_banner
        puts "/*\n * Fact Types\n */"
      end

      def fact_type_end
        puts "\n"
      end

      def constraint_banner
        puts "/*\nConstraints:"
      end

      def constraint_end
        puts " */"
      end

      # Of the players of a set of roles, return the one that's a subclass of (or same as) all others, else nil
      def roleplayer_subclass(roles)
        roles[1..-1].inject(roles[0].concept){|subclass, role|
          next nil unless subclass and EntityType === role.concept
          role.concept.supertypes_transitive.include?(subclass) ? role.concept : nil
        }
      end

      def constraint_dump(c)
        puts "\tREVISIT: " +
          case c
          when PresenceConstraint
            roles = c.role_sequence.all_role_ref.map{|rr| rr.role }
            if (roles.map{|r| r.fact_type}.uniq.size == 1)
              # All roles pertain to one fact type, an internal constraint:
              "each #{c.role_sequence.describe} occurs #{c.frequency} time"+
              #c.frequency + ' ' + c.role_sequence.describe +
              " in '#{c.role_sequence.all_role_ref[0].role.fact_type.default_reading}'"
            else
              # More than one fact type involved, an external constraint.
              # Either all roles must be played by the same concept (or a supertype) [not uniqueness!],
              # or all facts are binary and the counterparts of the roles are.
              if (player = roleplayer_subclass(roles))
                "#{player.name} must play #{c.frequency} of "
              else
                counterparts = roles.map{|r|
                    r.fact_type.all_role[r.fact_type.all_role[0] != r ? 0 : -1]
                  }
                player = roleplayer_subclass(counterparts)
                "#{c.frequency} #{player ? player.name : "UNKNOWN" } exists for each "
              end +
              "#{
                  c.role_sequence.all_role_ref.map{|rr|
                    "'#{rr.role.fact_type.default_reading}'"
                  }*", "
                }"
            end
          when RingConstraint
            "#{c.ring_type} ring over #{c.role.fact_type.default_reading}"
          when SetExclusionConstraint, SetEqualityConstraint
            # REVISIT exclusion: every <player-list> must<?> either reading1, reading2, ...
            (SetExclusionConstraint === c ? (c.is_mandatory ? "mandatory " : "")+"exclusion" : "equality") +
            " over #{
                c.all_set_comparison_roles.map{|scr|
                  scr.role_sequence.describe +
                    (scr.role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq.size == 1 ?
                      " in '#{scr.role_sequence.all_role_ref[0].role.fact_type.default_reading}'" : "")
                }*", "
              }"
          when SubsetConstraint
            # If the role players are identical and not duplicated, we can simply say "reading1 only if reading2"
            subset_players = c.subset_role_sequence.all_role_ref.map{|rr| rr.role.concept}
            superset_players = c.superset_role_sequence.all_role_ref.map{|rr| rr.role.concept}
            if subset_players == superset_players && subset_players.uniq == subset_players
              "'#{c.subset_role_sequence.all_role_ref[0].role.fact_type.default_reading}'" +
              " only if " +
              "'#{c.superset_role_sequence.all_role_ref[0].role.fact_type.default_reading}'"
            else
              "#{c.subset_role_sequence.describe
                }" +
                (c.subset_role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq.size == 1 ?
                  " in '#{c.subset_role_sequence.all_role_ref[0].role.fact_type.default_reading}'" : "")+
                " is a subset of #{
                  c.superset_role_sequence.describe
                }" +
                (c.superset_role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq.size == 1 ?
                  " in '#{c.superset_role_sequence.all_role_ref[0].role.fact_type.default_reading}'" : "")
            end
          else
            "#{c.class.basename} #{c.name}: unhandled constraint type"
          end
      end

      def role_sequence_names(rs)
        "("+rs.all_role_ref.map{|rr| rr.role.role_name || rr.role.concept.name }*", "+")"
      end
    end
  end
end
