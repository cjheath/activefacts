#
#       ActiveFacts Generators.
#       Generate HTML-highlighted CQL from an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# The text generated here is pre-formatted, and it spans haing the following styles:
# keyword: ORM2 standard colour is #00C (blue)
# object_type: ORM2 standard object_type is #808 (purple)
# copula: ORM2 standard object_type is #060 (green)
#
require 'activefacts/vocabulary'
require 'activefacts/api'
require 'activefacts/generate/cql'

module ActiveFacts
  module Generate
    class CQL
      # Generate CQL with HTML syntax-highlighting for an ActiveFacts vocabulary.
      # Invoke as
      #   afgen --cql/html <file>.cql
      class HTML < CQL
      private

        def initialize(vocabulary, *options)
          super
        end

        def puts s
          super(s.gsub(/[,;]/) do |p| keyword p; end)
        end

        def keyword(str)
          "<span class='keyword'>#{str}</span>"
        end

        def object_type(str)
          "<span class='object_type'>#{str}</span>"
        end

        def copula(str)
          "<span class='copula'>#{str}</span>"
        end

        def vocabulary_start(vocabulary)
          puts %q{<head>
            <link rel="stylesheet" href="css/orm2.css" type="text/css"/>
            </head>
            <pre class="copula">}
          puts "#{keyword "vocabulary"} #{object_type(vocabulary.name)};\n\n"
        end

        def vocabulary_end
          puts %q{</pre>}
        end

        def value_type_banner
          puts "/*\n * Value Types\n */"
        end

        def value_type_dump(o)
          return unless o.supertype    # An imported type
          if o.name == o.supertype.name
              # In ActiveFacts, parameterising a ValueType will create a new ValueType
              # throw Can't handle parameterized value type of same name as its ValueType" if ...
          end

          parameters =
            [ o.length != 0 || o.scale != 0 ? o.length : nil,
              o.scale != 0 ? o.scale : nil
            ].compact
          parameters = parameters.length > 0 ? "("+parameters.join(",")+")" : "()"

          puts "#{object_type o.name} #{keyword "is written as"} #{object_type o.supertype.name + parameters }#{
              if (o.value_constraint)
                keyword("restricted to")+
                o.value_constraint.all_allowed_range.map{|ar|
                    # REVISIT: Need to display as string or numeric according to type here...
                    min = ar.value_range.minimum_bound
                    max = ar.value_range.maximum_bound

                    range = (min ? min.value : "") +
                      (min.value != (max&&max.value) ? (".." + (max ? max.value : "")) : "")
                    keyword range
                  }*", "
              else
                ""
              end
            };"
        end

        def append_ring_to_reading(reading, ring)
          reading << keyword(" [#{(ring.ring_type.scan(/[A-Z][a-z]*/)*", ").downcase}]")
        end

        def identified_by_roles_and_facts(entity_type, identifying_roles, identifying_facts, preferred_readings)
          identifying_role_names = identifying_roles.map{|role|
              preferred_role_ref = preferred_readings[role.fact_type].role_sequence.all_role_ref.detect{|reading_rr|
                  reading_rr.role == role
                }
              role_words = []
              # REVISIT: Consider whether NOT to use the adjective if it's a prefix of the role_name

              role_name = role.role_name
              role_name = nil if role_name == ""
              # debug "object_type.name=#{preferred_role_ref.role.object_type.name}, role_name=#{role_name.inspect}, preferred_role_name=#{preferred_role_ref.role.role_name.inspect}"

              if (role.fact_type.all_role.size == 1)
                # REVISIT: Guard against unary reading containing the illegal words "and" and "where".
                role.fact_type.default_reading    # Need whole reading for a unary.
              elsif (role_name)
                role_name
              else
                role_words << preferred_role_ref.leading_adjective if preferred_role_ref.leading_adjective != ""
                role_words << preferred_role_ref.role.object_type.name
                role_words << preferred_role_ref.trailing_adjective if preferred_role_ref.trailing_adjective != ""
                role_words.compact*"-"
              end
            }

          # REVISIT: Consider emitting extra fact types here, instead of in entity_type_dump?
          # Just beware that readings having the same players will be considered to be of the same fact type, even if they're not.

          # Detect standard reference-mode scenarios
          ft = identifying_facts[0]
          fact_constraints = nil
          if identifying_facts.size == 1 and
            entity_role = ft.all_role[n = (ft.all_role[0].object_type == entity_type ? 0 : 1)] and
            value_role = ft.all_role[1-n] and
            value_name = value_role.object_type.name and
            residual = value_name.gsub(%r{#{entity_role.object_type.name}},'') and
            residual != '' and
            residual != value_name

            # The EntityType is identified by its association with a single ValueType
            # whose name is an extension (the residual) of the EntityType's name.

            # Detect standard reference-mode readings:
            forward_reading = reverse_reading = nil
            ft.all_reading.each do |reading|
              if reading.text =~ /^\{(\d)\} has \{\d\}$/
                if reading.role_sequence.all_role_ref[$1.to_i].role == entity_role
                  forward_reading = reading
                else
                  reverse_reading = reading
                end
              elsif reading.text =~ /^\{(\d)\} is of \{\d\}$/
                if reading.role_sequence.all_role_ref[$1.to_i].role == value_role
                  reverse_reading = reading
                else
                  forward_reading = reading
                end
              end
            end

            debug :mode, "------------------- Didn't find standard forward reading" unless forward_reading
            debug :mode, "------------------- Didn't find standard reverse reading" unless reverse_reading

            # If we didn't find at least one of the standard readings, don't use a refmode:
            if (forward_reading || reverse_reading)
              # Elide the constraints that would have been emitted on those readings.
              # If there is a UC that's not in the standard form for a reference mode,
              # we have to emit the standard reading anyhow.
              fact_constraints = @presence_constraints_by_fact[ft]
              fact_constraints.each do |pc|
                if (pc.role_sequence.all_role_ref.size == 1 and pc.max_frequency == 1)
                  # It's a uniqueness constraint, and will be regenerated
                  @constraints_used[pc] = true
                end
              end

              @fact_types_dumped[ft] = true

              # Figure out whether any non-standard readings exist:
              other_readings = ft.all_reading - [forward_reading] - [reverse_reading]
              debug :mode, "--- other_readings.size now = #{other_readings.size}" if other_readings.size > 0

              fact_text = other_readings.map do |reading|
                expanded_reading(reading, fact_constraints, true)
              end*",\n\t"
              return keyword(" identified by its ") +
                object_type(residual) +
                (fact_text != "" ? keyword(" where\n\t") + fact_text : "")
            end
          end

          identifying_facts.each{|f| @fact_types_dumped[f] = true }
          @identifying_fact_text = 
              identifying_facts.map{|f|
                  fact_readings_with_constraints(f, fact_constraints)
              }.flatten*",\n\t"

          keyword(" identified by ") +
            identifying_role_names.map{|n| object_type n} * keyword(" and ") +
            keyword(" where\n\t") +
            @identifying_fact_text
        end

        def entity_type_banner
          puts(keyword("/*\n * Entity Types\n */"))
        end

        def fact_readings(fact_type)
          constrained_fact_readings = fact_readings_with_constraints(fact_type)
          constrained_fact_readings*",\n\t"
        end

        def subtype_dump(o, supertypes, pi)
          print "#{object_type o.name} #{keyword "is a kind of"} #{ o.supertypes.map(&:name).map{|n| object_type n}*keyword(", ") }"
          if pi
            print identified_by(o, pi)
          end
          # If there's a preferred_identifier for this subtype, identifying readings were emitted
          if o.fact_type
            print(
              (pi ? "," : keyword(" where")) +
              "\n\t" +
              fact_readings(o.fact_type)
            )
          end
          puts ";\n"
        end

        def non_subtype_dump(o, pi)
          print "#{object_type(o.name)} #{keyword "is"}" +
            identified_by(o, pi)
          print(keyword(" where\n\t") + fact_readings(o.fact_type)) if o.fact_type
          puts ";\n"
        end

        def fact_type_dump(fact_type, name)

          @identifying_fact_text = nil
          if (o = fact_type.entity_type)
            print "#{object_type o.name} #{keyword "is"}"
            if !o.all_type_inheritance_as_subtype.empty?
              print(keyword(" a kind of ") + o.supertypes.map(&:name).map{|n| object_type n}*", ")
            end

            # Alternate identification of objectified fact type?
            primary_supertype = o.supertypes[0]
            pi = fact_type.entity_type.preferred_identifier
            if pi && primary_supertype && primary_supertype.preferred_identifier != pi
              print identified_by(o, pi)
              print ";\n"
            end
          end

          unless @identifying_fact_text
            print(keyword(" where\n\t")) if o
            puts(fact_readings(fact_type)+";")
          end
        end

        def fact_type_banner
          puts keyword("/*\n * Fact Types\n */")
        end

        def constraint_banner
          puts keyword("/*\n * Constraints:\n */")
        end

        def dump_presence_constraint(c)
          roles = c.role_sequence.all_role_ref.map{|rr| rr.role }

          # REVISIT: If only one role is covered and it's mandatory >=1 constraint, use SOME/THAT form:
          # each Bug SOME Tester logged THAT Bug;
          players = c.role_sequence.all_role_ref.map{|rr| rr.role.object_type.name}.uniq

          fact_types = c.role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq
          puts \
            "#{keyword "each #{players.size > 1 ? "combination " : ""}"}"+
            "#{players.map{|n| object_type n}*", "} "+
            "#{keyword "occurs #{c.frequency} time in"}\n\t"+
            "#{fact_types.map{|ft| ft.default_reading([], nil)}*",\n\t"}" +
              ";"
        end

        def dump_set_constraint(c)
          # REVISIT exclusion: every <player-list> must<?> either reading1, reading2, ...

          # Each constraint involves two or more occurrences of one or more players.
          # For each player, a subtype may be involved in the occurrences.
          # Find the common supertype of each player.
          scrs = c.all_set_comparison_roles
          player_count = scrs[0].role_sequence.all_role_ref.size
          role_seq_count = scrs.size

          #raise "Can't verbalise constraint over many players and facts" if player_count > 1 and role_seq_count > 1

          players_differ = []   # Record which players are also played by subclasses
          players = (0...player_count).map do |pi|
            # Find the common supertype of the players of the pi'th role in each sequence
            object_types = scrs.map{|r| r.role_sequence.all_role_ref[pi].role.object_type }
            player, players_differ[pi] = common_supertype(object_types)
            raise "Role sequences of #{c.class.basename} must have object_types matching #{c.name} in position #{pi}" unless player
            player
          end
          #puts "#{c.class.basename} has players #{players.map{|p| p.name}*", "}"

          if (SetEqualityConstraint === c)
            # REVISIT: Need a proper approach to some/that and adjective disambiguation:
            puts \
              scrs.map{|scr|
                scr.role_sequence.all_role_ref.map{|rr|
                  rr.role.fact_type.default_reading([], nil)
                }*keyword(" and ")
              } * keyword("\n\tif and only if\n\t") + ";"
            return
          end

          mode = c.is_mandatory ? "exactly one" : "at most one"
          puts "#{keyword "for each"} #{players.map{|p| object_type p.name}*", "} #{keyword(mode + " of these holds")}:\n\t" +
            (scrs.map do |scr|
              constrained_roles = scr.role_sequence.all_role_ref.map{|rr| rr.role }
              fact_types = constrained_roles.map{|r| r.fact_type }.uniq

              fact_types.map do |fact_type|
                # REVISIT: future: Use "THAT" and "SOME" only when:
                # - the role player occurs twice in the reading, or
                # - is a subclass of the constrained object_type, or
                reading = fact_type.preferred_reading
                expand_constrained(reading, constrained_roles, players, players_differ)
              end * keyword(" and ")

            end*",\n\t"
            )+';'
        end

        # Expand this reading using (in)definite articles where needed
        # Handle any roles in constrained_roles specially.
        def expand_constrained(reading, constrained_roles, players, players_differ)
          frequency_constraints = reading.role_sequence.all_role_ref.map {|role_ref|
              i = constrained_roles.index(role_ref.role)
              if !i
                v = [ "some", role_ref.role.object_type.name]
              elsif players_differ[i]
                v = [ "that", players[i].name ]   # Make sure to use the superclass name
              else
                if reading.fact_type.all_role.select{|r| r.object_type == role_ref.role.object_type }.size > 1
                  v = [ "that", role_ref.role.object_type.name ]
                else
                  v = [ "some", role_ref.role.object_type.name ]
                end
              end

              v[0] = keyword(v[0])
              v[1] = object_type(v[1])
              v
            }
          frequency_constraints = [] unless frequency_constraints.detect{|fc| fc[0] =~ /some/ }

          #$stderr.puts "fact_type roles (#{fact_type.all_role.map{|r| r.object_type.name}*","}) default_reading '#{fact_type.preferred_reading.text}' roles (#{fact_type.preferred_reading.role_sequence.all_role_ref.map{|rr| rr.role.object_type.name}*","}) #{frequency_constraints.inspect}"

          # REVISIT: Make sure that we refer to the constrained players by their common supertype

          reading.expand(frequency_constraints, nil)
        end

        def dump_subset_constraint(c)
          # If the role players are identical and not duplicated, we can simply say "reading1 only if reading2"
          subset_roles = c.subset_role_sequence.all_role_ref.map{|rr| rr.role}
          superset_roles = c.superset_role_sequence.all_role_ref.map{|rr| rr.role}

          subset_players = subset_roles.map(&:object_type)
          superset_players = superset_roles.map(&:object_type)

          subset_fact_types = c.subset_role_sequence.all_role_ref.map{|rr| rr.role.fact_type }.uniq
          superset_fact_types = c.superset_role_sequence.all_role_ref.map{|rr| rr.role.fact_type }.uniq

          # We need to ensure that if the player of any constrained role also exists
          # as the player of a role that's not a constrained role, there are different
          # adjectives or other qualifiers qualifier applied to distinguish that role.
          fact_type_roles = (subset_fact_types+superset_fact_types).map{|ft| ft.all_role }.flatten
          non_constrained_roles = fact_type_roles - subset_roles - superset_roles
          if (r = non_constrained_roles.detect{|r| (subset_roles+superset_roles).include?(r) })
            # REVISIT: Find a way to deal with this problem, should it arise.

            # It would help, but not entirely fix it, to use SOME/THAT to identify the constrained roles.
            # See ServiceDirector's DataStore<->Client fact types for example
            # Use SOME on the subset, THAT on the superset.
            raise "Critical ambiguity, #{r.object_type.name} occurs both constrained and unconstrained in #{c.name}"
          end

          puts \
            "#{subset_fact_types.map{|ft| ft.default_reading([], nil)}*" and "}" +
            "\n\t#{keyword "only if"} " +
            "#{superset_fact_types.map{|ft| ft.default_reading([], nil)}*" and "}" +
            ";"
        end

      end
      end
    end
  end
end

