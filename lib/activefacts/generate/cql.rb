#
#       ActiveFacts Generators.
#       Generate CQL from an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/generate/ordered'

module ActiveFacts
  module Generate #:nodoc:
    # Generate CQL for an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --cql <file>.cql
    class CQL < OrderedDumper
    private
      def vocabulary_start(vocabulary)
        puts "vocabulary #{vocabulary.name};\n\n"
      end

      def vocabulary_end
      end

      def units_banner
        puts "/*\n * Units\n */"
      end

      def unit_dump unit
        if !unit.ephemera_url
          if unit.coefficient
            # REVISIT: Use a smarter algorithm to switch to exponential form when there'd be lots of zeroes.
            print unit.coefficient.numerator.to_s('F')
            if d = unit.coefficient.denominator and d != 1
              print "/#{d}"
            end
            print ' '
          else
            print '1 '
          end
        end

        print(unit.
          all_derivation_as_derived_unit.
          # REVISIT: Sort base units
          # REVISIT: convert negative powers to division?
          map do |der|
            base = der.base_unit
            "#{base.name}#{der.exponent and der.exponent != 1 ? "^#{der.exponent}" : ''} "
          end*''
        )
        if o = unit.offset and o != 0
          print "+ #{o.to_s('F')} "
        end
        print "converts to #{unit.name}#{unit.plural_name ? '/'+unit.plural_name : ''}"
        print " approximately" if unit.coefficient and !unit.coefficient.is_precise
        print " ephemera #{unit.ephemera_url}" if unit.ephemera_url
        puts ";"
      end

      def value_type_banner
        puts "/*\n * Value Types\n */"
      end

      def value_type_end
        puts "\n"
      end

      def value_type_dump(o)
        # Ignore Value Types that don't do anything:
        return if
          !o.supertype &&
          o.all_role.size == 0 &&
          !o.is_independent &&
          !o.value_constraint &&
          o.all_context_note.size == 0 &&
          o.all_instance.size == 0
        # No need to dump it if the only thing it does is be a supertype; it'll be created automatically
        # return if o.all_value_type_as_supertype.size == 0

=begin
        # Leave this out, pending a proper on-demand system for dumping VT's
        # A ValueType that is only used as a reference mode need not be emitted here.
        if o.all_value_type_as_supertype.size == 0 &&
          !o.all_role.
            detect do |role|
              (other_roles = role.fact_type.all_role.to_a-[role]).size != 1 ||      # Not a role in a binary FT
              !(concept = other_roles[0].concept).is_a?(ActiveFacts::Metamodel::EntityType) ||  # Counterpart is not an ET
              (pi = concept.preferred_identifier).role_sequence.all_role_ref.size != 1 ||   # Entity PI has > 1 roles
              pi.role_sequence.all_role_ref.single.role != role                     # This isn't the identifying role
            end
          puts "About to skip #{o.name}"
          debugger
          return
        end

        # We'll dump the subtypes before any roles, so we don't need to dump this here.
        # ... except that isn't true, we won't do that so we can't skip it now
        #return if
        #  o.all_value_type_as_supertype.size != 0 &&    # We have subtypes
        #  o.all_role.size != 0
=end

        parameters =
          [ o.length != 0 || o.scale != 0 ? o.length : nil,
            o.scale != 0 ? o.scale : nil
          ].compact
        parameters = parameters.length > 0 ? "("+parameters.join(",")+")" : ""

        puts "#{o.name} is written as #{(o.supertype || o).name}#{ parameters }#{
            o.value_constraint && " "+o.value_constraint.describe
          }#{o.is_independent ? ' [independent]' : ''
          };"
      end

      def append_ring_to_reading(reading, ring)
        reading << " [#{(ring.ring_type.scan(/[A-Z][a-z]*/)*", ").downcase}]"
      end

      def mapping_pragma(entity_type)
        ti = entity_type.all_type_inheritance_as_subtype
        assimilation = ti.map{|t| t.assimilation }.compact[0]
        return "" unless entity_type.is_independent || assimilation
        " [" +
          [
            entity_type.is_independent ? "independent" : nil,
            assimilation || nil
          ].compact*", " +
        "]"
      end

      # If this entity_type is identified by a single value, return four relevant objects:
      def value_role_identification(entity_type, identifying_facts)
        external_identifying_facts = identifying_facts - [entity_type.fact_type]
        fact_type = external_identifying_facts[0]
        ftr = fact_type && fact_type.all_role.sort_by{|role| role.ordinal}
        if external_identifying_facts.size == 1 and
            entity_role = ftr[n = (ftr[0].concept == entity_type ? 0 : 1)] and
            value_role = ftr[1-n] and
            value_player = value_role.concept and
            value_player.is_a?(ActiveFacts::Metamodel::ValueType) and
            value_name = value_player.name and
            value_residual = value_name.sub(%r{^#{entity_role.concept.name} ?},'') and
            value_residual != '' and
            value_residual != value_name
          [fact_type, entity_role, value_role, value_residual]
        else
          []
        end
      end

      # This entity is identified by a single value, so find whether standard refmode readings were used
      def detect_standard_refmode_readings fact_type, entity_role, value_role
        forward_reading = reverse_reading = nil
        fact_type.all_reading.each do |reading|
          if reading.text =~ /^\{(\d)\} has \{\d\}$/
            if reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i}.role == entity_role
              forward_reading = reading
            else
              reverse_reading = reading
            end
          elsif reading.text =~ /^\{(\d)\} is of \{\d\}$/
            if reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i}.role == value_role
              reverse_reading = reading
            else
              forward_reading = reading
            end
          end
        end
        debug :mode, "Didn't find standard forward reading" unless forward_reading
        debug :mode, "Didn't find standard reverse reading" unless reverse_reading
        [forward_reading, reverse_reading]
      end

      # This entity is identified by a refmode. Generate the identification and fact reading text.
      def identified_by_refmode(entity_type, value_residual, fact_type, value_role, nonstandard_readings)
        # Elide the constraints that would have been emitted on those readings.
        # If there is a UC that's not in the standard form for a reference mode,
        # we have to emit the standard reading anyhow.
        fact_constraints = @presence_constraints_by_fact[fact_type]
        fact_constraints.each do |pc|
          if (pc.role_sequence.all_role_ref.size == 1 and pc.max_frequency == 1)
            # It's a uniqueness constraint, and will be regenerated
            @constraints_used[pc] = true
          end
        end
        fact_constraints += Array(@presence_constraints_by_fact[entity_type.fact_type])

        @fact_types_dumped[fact_type] = true

        # Figure out whether any non-standard readings exist:
        debug :mode, "--- nonstandard_readings.size now = #{nonstandard_readings.size}" if nonstandard_readings.size > 0

        verbaliser = ActiveFacts::Metamodel::Verbaliser.new
#!!! Verbaliser
        # REVISIT: Announce? to the Verbaliser that we know about entity_type.name and value_role.concept.name
        # Verbalise only these constraints, and value constraints (there'll be no ring constraints)
        # verbaliser.constraints = fact_constraints
        # All role references played by these entity types must be unambiguous (loose binding helps!)
        fact_text = (
          nonstandard_readings.map do |reading|
            expanded_reading(verbaliser, reading, fact_constraints, true)
          end +
          (entity_type.fact_type ?
            fact_readings_with_constraints(verbaliser, entity_type.fact_type, fact_constraints) : []
          )
        )*",\n\t"

        # If we emitted a reading, it'll include the role_value_constraint already
        value_constraint = fact_text.empty? && value_role.role_value_constraint
        constraint_text = value_constraint ? " "+value_constraint.describe : ""
        return " identified by its #{value_residual}#{constraint_text}#{mapping_pragma(entity_type)}" +
          (fact_text != "" ? " where\n\t" + fact_text : "")
      end

      def identified_by_roles_and_facts(entity_type, identifying_roles, identifying_facts)
        verbaliser = ActiveFacts::Metamodel::Verbaliser.new
        irn = identifying_role_names verbaliser, identifying_roles

        # Detect standard reference-mode scenarios
        fact_type, entity_role, value_role, value_residual =
          *value_role_identification(entity_type, identifying_facts)
        if fact_type
          # The EntityType is identified by its association with a single ValueType
          # whose name is an extension (the value_residual) of the EntityType's name.
          # If we have at least one of the standard refmode readings, dump it that way.

          forward_reading, reverse_reading =
            *detect_standard_refmode_readings(fact_type, entity_role, value_role)

          if (forward_reading || reverse_reading)
            nonstandard_readings = fact_type.all_reading - [forward_reading, reverse_reading]

            return identified_by_refmode(entity_type, value_residual, fact_type, value_role, nonstandard_readings)
          end
        end

        identifying_facts.each{|f| @fact_types_dumped[f] = true }
        # REVISIT: The verbaliser must detect and fix ambiguities between the identifying roles.
        # The entity type itself cannot be ambiguous because it's being defined here (it might have various adjectives but those will be loose-bound)
        # but there may be more than one role played by the same other player, perhaps without adjectives or role names, which will need subscripts
        identifying_fact_text = 
            identifying_facts.map{|f|
                fact_readings_with_constraints(verbaliser, f)
            }.flatten*",\n\t"

        " identified by #{ irn*" and " }" +
          mapping_pragma(entity_type) +
          " where\n\t"+identifying_fact_text
      end

      def entity_type_banner
        puts "/*\n * Entity Types\n */"
      end

      def entity_type_group_end
        puts "\n"
      end

      def subtype_dump(o, supertypes, pi)
        print "#{o.name} is a kind of #{ o.supertypes.map(&:name)*", " }"
        if pi
          puts identified_by(o, pi)+';'
          return
        end

        print mapping_pragma(o)

        verbaliser = ActiveFacts::Metamodel::Verbaliser.new
        print " where\n\t" + fact_readings_with_constraints(verbaliser, o.fact_type)*",\n\t" if o.fact_type
        puts ";\n"
      end

      def non_subtype_dump(o, pi)
        puts "#{o.name} is" + identified_by(o, pi) + ';'
      end

      def fact_type_dump(fact_type, name)

        if (o = fact_type.entity_type)
          print "#{o.name} is"
          supertypes = o.supertypes
          print " a kind of #{ supertypes.map(&:name)*", " }" unless supertypes.empty?

          # Alternate identification of objectified fact type?
          primary_supertype = supertypes[0]
          pi = fact_type.entity_type.preferred_identifier
          if pi && primary_supertype && primary_supertype.preferred_identifier != pi
            puts identified_by(o, pi) + ';'
            return
          end
          print " where\n\t"
        end

        verbaliser = ActiveFacts::Metamodel::Verbaliser.new
        # There can be no roles of the objectified fact type in the readings, so no need to tell the Verbaliser anything special
        puts(fact_readings_with_constraints(verbaliser, fact_type)*",\n\t"+";")
      end

      def fact_type_banner
        puts "/*\n * Fact Types\n */"
      end

      def fact_type_end
        puts "\n"
      end

      def constraint_banner
        puts "/*\n * Constraints:"
        puts " */"
      end

      def constraint_end
      end

      # Of the players of a set of roles, return the one that's a subclass of (or same as) all others, else nil
      def roleplayer_subclass(roles)
        roles[1..-1].inject(roles[0].concept){|subclass, role|
          next nil unless subclass and EntityType === role.concept
          role.concept.supertypes_transitive.include?(subclass) ? role.concept : nil
        }
      end

      def dump_presence_constraint(c)
        # Loose binding in PresenceConstraints is limited to explicit role players (in an occurs list)
        # having no exact match, but having instead exactly one role of the same player in the readings.

        verbaliser = ActiveFacts::Metamodel::Verbaliser.new
        # For a mandatory constraint (min_frequency == 1, max == nil or 1) any subtyping join is over the proximate role player
        # For all other presence constraints any subtyping join is over the counterpart player
        role_proximity = c.min_frequency == 1 && [nil, 1].include?(c.max_frequency) ? :proximate : :counterpart
        expanded_readings = verbaliser.verbalise_over_role_sequence(c.role_sequence, nil, role_proximity)
        if c.min_frequency == 1 && c.max_frequency == nil and c.role_sequence.all_role_ref.size == 2
          puts "either #{expanded_readings*' or '};"
        else
          roles = c.role_sequence.all_role_ref.map{|rr| rr.role }
          # The uniq's are bad here; they mean there is more than one player of the same type and we should subscript
          # This list of players should come from the verbaliser:
          players = c.role_sequence.all_role_ref.map{|rr| rr.role.concept.name}.uniq
          fact_types = c.role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq
          min, max = c.min_frequency, c.max_frequency
          pl = (min&&min>1)||(max&&max>1) ? 's' : ''
          puts \
            "each #{players.size > 1 ? "combination " : ""}#{players*", "} occurs #{c.frequency} time#{pl} in\n\t"+
            "#{expanded_readings*",\n\t"};"
        end
      end

      def dump_set_comparison_constraint(c)
        scrs = c.all_set_comparison_roles.sort_by{|scr| scr.ordinal}
        role_sequences = scrs.map{|scr|scr.role_sequence}

        verbaliser = ActiveFacts::Metamodel::Verbaliser.new
        if role_sequences.detect{|scr| scr.all_role_ref.detect{|rr| rr.join_node}}
          # This set constraint has an explicit join. Verbalise it.
          readings_list = role_sequences.
            map do |rs|
              verbaliser.verbalise_over_role_sequence(rs) 
            end
          if c.is_a?(ActiveFacts::Metamodel::SetEqualityConstraint)
            puts readings_list.join("\n\tif and only if\n\t") + ';'
            return
          end
          if readings_list.size == 2 && c.is_mandatory  # XOR constraint
            puts "either " + readings_list.join(" or ") + " but not both;"
            return
          end
          mode = c.is_mandatory ? "exactly one" : "at most one"
          puts "for each #{players.map{|p| p.name}*", "} #{mode} of these holds:\n\t" +
            readings_list.join(",\n\t") +
            ';'
          return
        end

        if c.is_a?(ActiveFacts::Metamodel::SetEqualityConstraint)
          puts \
            scrs.map{|scr|
              verbaliser.verbalise_over_role_sequence(scr.role_sequence)
            } * "\n\tif and only if\n\t" + ";"
          return
        end

        # A constrained role may involve a subtyping join. We substitute the name of the supertype for all occurrences.
        transposed_role_refs = scrs.map{|scr| scr.role_sequence.all_role_ref_in_order.to_a}.transpose
        players = transposed_role_refs.map{|role_refs| common_supertype(role_refs.map{|rr| rr.role.concept})}
        raise "Constraint must cover matching roles" if players.compact.size < players.size

        readings_expanded = scrs.
          map do |scr|
            # verbaliser.verbalise_over_role_sequence(scr.role_sequence)
            # REVISIT: verbalise_over_role_sequence cannot do what we need here, because of the
            # possibility of subtyping joins in the constrained roles across the different scr's
            # The following code uses "players" and "constrained_roles" to create substitutions.
            # These should instead be passed to the verbaliser (one join node per index, role_refs for each).
            fact_types_processed = {}
            constrained_roles = scr.role_sequence.all_role_ref_in_order.map{|rr| rr.role}
            join_over = Metamodel.join_roles_over(constrained_roles)
            constrained_roles.map do |constrained_role|
              fact_type = constrained_role.fact_type
              next nil if fact_types_processed[fact_type] # Don't emit the same fact type twice (in case of objectification join)
              fact_types_processed[fact_type] = true
              reading = fact_type.reading_preferably_starting_with_role(constrained_role)
              expand_constrained(verbaliser, reading, constrained_roles, players)
            end.compact * " and "
          end

        if scrs.size == 2 && c.is_mandatory
          puts "either " + readings_expanded*" or " + " but not both;"
        else
          mode = c.is_mandatory ? "exactly one" : "at most one"
          puts "for each #{players.map{|p| p.name}*", "} #{mode} of these holds:\n\t" +
            readings_expanded*",\n\t" + ';'
        end
      end

      def dump_subset_constraint(c)
        # If the role players are identical and not duplicated, we can simply say "reading1 only if reading2"
        subset_roles, subset_fact_types =
          c.subset_role_sequence.all_role_ref_in_order.map{|rr| [rr.role, rr.role.fact_type]}.transpose
        superset_roles, superset_fact_types =
          c.superset_role_sequence.all_role_ref_in_order.map{|rr| [rr.role, rr.role.fact_type]}.transpose

        subset_fact_types.uniq!
        superset_fact_types.uniq!

        verbaliser = ActiveFacts::Metamodel::Verbaliser.new
        puts \
          verbaliser.verbalise_over_role_sequence(c.subset_role_sequence) +
          "\n\tonly if " +
          verbaliser.verbalise_over_role_sequence(c.superset_role_sequence) +
          ";"
      end

      def dump_ring_constraint(c)
        # At present, no ring constraint can be missed to be handled in this pass
        puts "// #{c.ring_type} ring over #{c.role.fact_type.default_reading}"
      end

      def constraint_dump(c)
          case c
          when ActiveFacts::Metamodel::PresenceConstraint
            dump_presence_constraint(c)
          when ActiveFacts::Metamodel::RingConstraint
            dump_ring_constraint(c)
          when ActiveFacts::Metamodel::SetComparisonConstraint # includes SetExclusionConstraint, SetEqualityConstraint
            dump_set_comparison_constraint(c)
          when ActiveFacts::Metamodel::SubsetConstraint
            dump_subset_constraint(c)
          else
            "#{c.class.basename} #{c.name}: unhandled constraint type"
          end
      end

      # Find the common supertype of these concepts.
      def common_supertype(concepts)
        common = concepts[0].supertypes_transitive
        concepts[1..-1].each do |concept|
          common &= concept.supertypes_transitive
        end
        common[0]
      end

      #============================================================
      # Verbalisation functions for fact type and entity type definitions
      #============================================================
      # Return an array of the names of these identifying_roles
      def identifying_role_names verbaliser, identifying_roles
        identifying_roles.map do |role|
          preferred_role_ref = role.fact_type.preferred_reading.role_sequence.all_role_ref.detect{|reading_rr|
              reading_rr.role == role
            }
          role_words = []
          # REVISIT: Consider whether NOT to use the adjective if it's a prefix of the role_name

          role_name = role.role_name
          role_name = nil if role_name == ""
          # debug "concept.name=#{preferred_role_ref.role.concept.name}, role_name=#{role_name.inspect}, preferred_role_name=#{preferred_role_ref.role.role_name.inspect}"

          if (role.fact_type.all_role.size == 1)
            # REVISIT: Guard against unary reading containing the illegal words "and" and "where".
            role.fact_type.default_reading    # Need whole reading for a unary.
          elsif (role_name)
            role_name
          else
            role_words << preferred_role_ref.leading_adjective if preferred_role_ref.leading_adjective != ""
            role_words << preferred_role_ref.role.concept.name
            role_words << preferred_role_ref.trailing_adjective if preferred_role_ref.trailing_adjective != ""
            role_words.compact*"-"
          end
        end
      end

      def fact_readings_with_constraints(verbaliser, fact_type, fact_constraints = nil)
        define_role_names = true
        fact_constraints ||= @presence_constraints_by_fact[fact_type]
        readings = fact_type.all_reading_by_ordinal.inject([]) do |reading_array, reading|
          reading_array << expanded_reading(verbaliser, reading, fact_constraints, define_role_names)

          define_role_names = false     # No need to define role names in subsequent readings

          reading_array
        end

        readings
      end

      def expanded_reading(verbaliser, reading, fact_constraints, define_role_names)
        # Find all role numbers in order of occurrence in this reading:
        role_refs = reading.role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}
        role_numbers = reading.text.scan(/\{(\d)\}/).flatten.map{|m| Integer(m) }
        roles = role_numbers.map{|m| role_refs[m].role }
        # debug "Considering #{reading.text} having #{role_numbers.inspect}"

        # Find the constraints that constrain frequency over each role we can verbalise:
        frequency_constraints = []
        value_constraints = []
        roles.each do |role|
          # Find a mandatory constraint that's *not* unique; this will need an extra reading
          role_is_first_in = reading.fact_type.all_reading.detect{|r|
              role == r.role_sequence.all_role_ref.sort_by{|role_ref|
                  role_ref.ordinal
                }[0].role
            }

          if vr = role.role_value_constraint
            if @constraints_used[vr]
              vr = nil
            else
              @constraints_used[vr] = true
              vr = vr.describe
            end
          end
          value_constraints << vr
          if (role == roles.last)   # First role of the reading?
            # REVISIT: With a ternary, doing this on other than the last role can be ambiguous,
            # in case both the 2nd and 3rd roles have frequencies. Think some more!

            constraint = fact_constraints.find{|c|  # Find a UC that spans all other Roles
                # internal uniqueness constraints span all roles but one, the residual:
                c.is_a?(ActiveFacts::Metamodel::PresenceConstraint) &&
                  !@constraints_used[c] &&  # Already verbalised
                  roles-c.role_sequence.all_role_ref.map(&:role) == [role]
              }
            # Index the frequency implied by the constraint under the role position in the reading
            if constraint     # Mark this constraint as "verbalised" so we don't do it again:
              @constraints_used[constraint] = true
            end
            frequency_constraints << show_frequency(role, constraint)
          else
            frequency_constraints << show_frequency(role, nil)
          end
        end

        expanded = reading.expand(frequency_constraints, define_role_names, value_constraints)

        if (ft_rings = @ring_constraints_by_fact[reading.fact_type]) &&
           (ring = ft_rings.detect{|rc| !@constraints_used[rc]})
          @constraints_used[ring] = true
          append_ring_to_reading(expanded, ring)
        end
        expanded
      end

      # Expand this reading, substituting players[i].name for the each role in the i'th position in constrained_roles
      def expand_constrained(verbaliser, reading, constrained_roles, players)
        # Make sure that we refer to the constrained players by their common supertype (as passed in)
        frequency_constraints = reading.role_sequence.all_role_ref.
          map do |role_ref|
            player = role_ref.role.concept
            i = constrained_roles.index(role_ref.role)
            player = players[i] if i
            [ nil, player.name ]
          end
        frequency_constraints = [] unless frequency_constraints.detect{|fc| fc[0] != "some" }

#!!! Verbaliser
        reading.expand(frequency_constraints, nil)
      end

    end
  end
end
