#
#       ActiveFacts Generators.
#       Generate CQL from an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/generate/helpers/ordered'

module ActiveFacts
  module Generate #:nodoc:
    # Generate CQL for an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --cql <file>.cql
    class CQL < Helpers::OrderedDumper
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

      def units_end
        puts "\n"
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
              !(object_type = other_roles[0].object_type).is_a?(ActiveFacts::Metamodel::EntityType) ||  # Counterpart is not an ET
              (pi = object_type.preferred_identifier).role_sequence.all_role_ref.size != 1 ||   # Entity PI has > 1 roles
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

        puts "#{o.name
          } #{
            (o.is_independent ? '[independent] ' : '')
          }is written as #{
            (o.supertype || o).name
          }#{
            parameters
          }#{
            o.unit && " "+o.unit.name
          }#{
            o.value_constraint && " "+o.value_constraint.describe
          };"
      end

      def append_ring_to_reading(reading, ring)
        reading << " [#{(ring.ring_type.scan(/[A-Z][a-z]*/)*", ").downcase}]"
      end

      def mapping_pragma(entity_type, ignore_independence = false)
        ti = entity_type.all_type_inheritance_as_subtype
        assimilation = ti.map{|t| t.assimilation }.compact[0]
        return "" unless (entity_type.is_independent && !ignore_independence) || assimilation
        " [" +
          [
            entity_type.is_independent && !ignore_independence ? "independent" : nil,
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
            entity_role = ftr[n = (ftr[0].object_type == entity_type ? 0 : 1)] and
            value_role = ftr[1-n] and
            value_player = value_role.object_type and
            value_player.is_a?(ActiveFacts::Metamodel::ValueType) and
            value_name = value_player.name and
            value_residual = value_name.sub(%r{^#{entity_role.object_type.name} ?},'') and
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

      # If this entity_type is identified by a reference mode, return the verbalisation
      def identified_by_ref_mode(entity_type, identifying_facts)
        fact_type, entity_role, value_role, value_residual =
          *value_role_identification(entity_type, identifying_facts)
        return nil unless fact_type

        # This EntityType is identified by its association with a single ValueType
        # whose name is an extension (the value_residual) of the EntityType's name.
        # If we have at least one of the standard refmode readings, dump it that way,
        # else exit and use the long-hand verbalisation instead.

        forward_reading, reverse_reading =
          *detect_standard_refmode_readings(fact_type, entity_role, value_role)
        return nil unless (forward_reading || reverse_reading)

        # We can't subscript reference modes.
        # If an objectified fact type has a role played by its identifying player, go long-hand.
        return nil if entity_type.fact_type and
          entity_type.fact_type.all_role.detect{|role| role.object_type == value_role.object_type }

        @fact_types_dumped[fact_type] = true  # We've covered this fact type

        # Elide the constraints that would have been emitted on the standard readings.
        # If there is a UC that's not in the standard form for a reference mode,
        # we have to emit the standard reading anyhow.
        fact_constraints = @presence_constraints_by_fact[fact_type]
        fact_constraints.each do |pc|
          if (pc.role_sequence.all_role_ref.size == 1 and pc.max_frequency == 1)
            # It's a uniqueness constraint, and will be regenerated
            @constraints_used[pc] = true
          end
        end

        # Figure out which non-standard readings exist, if any:
        nonstandard_readings = fact_type.all_reading - [forward_reading, reverse_reading]
        debug :mode, "--- nonstandard_readings.size now = #{nonstandard_readings.size}" if nonstandard_readings.size > 0

        verbaliser = ActiveFacts::Metamodel::Verbaliser.new

        # The verbaliser needs to have a Player for the roles of entity_type, so it doesn't get subscripted.
        entity_roles =
          nonstandard_readings.map{|r| r.role_sequence.all_role_ref.detect{|rr| rr.role.object_type == entity_type}}.compact
        verbaliser.role_refs_have_same_player entity_roles

        verbaliser.alternate_readings nonstandard_readings
        if entity_type.fact_type
          verbaliser.alternate_readings entity_type.fact_type.all_reading
        end

        verbaliser.create_subscripts(:rolenames)      # Ok, the Verbaliser is ready to fly

        fact_readings =
          nonstandard_readings.map { |reading| expanded_reading(verbaliser, reading, fact_constraints, true) }
        fact_readings +=
          fact_readings_with_constraints(verbaliser, entity_type.fact_type) if entity_type.fact_type

        # If we emitted a reading for the refmode, it'll include any role_value_constraint already
        if nonstandard_readings.size == 0 and c = value_role.role_value_constraint
          constraint_text = " "+c.describe
        end
        (entity_type.is_independent ? ' independent' : '') +
          " identified by its #{value_residual}#{constraint_text}#{mapping_pragma(entity_type, true)}" +
          (fact_readings.size > 0 ? " where\n\t" : "") +
          fact_readings*",\n\t"
      end

      def identified_by_roles_and_facts(entity_type, identifying_role_refs, identifying_facts)
        # Detect standard reference-mode scenarios:
        if srm = identified_by_ref_mode(entity_type, identifying_facts)
          return srm
        end

        verbaliser = ActiveFacts::Metamodel::Verbaliser.new

        # Announce all the identifying fact roles to the verbaliser so it can decide on any necessary subscripting.
        # The verbaliser needs to have a Player for the roles of entity_type, so it doesn't get subscripted.
        entity_roles =
          identifying_facts.map{|ft| ft.preferred_reading.role_sequence.all_role_ref.detect{|rr| rr.role.object_type == entity_type}}.compact
        verbaliser.role_refs_have_same_player entity_roles
        identifying_facts.each do |fact_type|
          # The RoleRefs for corresponding roles across all readings are for the same player.
          verbaliser.alternate_readings fact_type.all_reading
          @fact_types_dumped[fact_type] = true unless fact_type.entity_type # Must dump objectification still!
        end
        verbaliser.create_subscripts(:rolenames)

        irn = verbaliser.identifying_role_names identifying_role_refs

        identifying_fact_text = 
            identifying_facts.map{|f|
                fact_readings_with_constraints(verbaliser, f)
            }.flatten*",\n\t"

        (entity_type.is_independent ? ' independent' : '') +
          " identified by #{ irn*" and " }" +
          mapping_pragma(entity_type, true) +
          " where\n\t"+identifying_fact_text
      end

      def entity_type_banner
        puts "/*\n * Entity Types\n */"
      end

      def entity_type_group_end
        puts "\n"
      end

      def subtype_dump(o, supertypes, pi)
        print "#{o.name} is a kind of #{
            o.is_independent ? 'independent ' : ''
          }#{ o.supertypes.map(&:name)*", " }"
        if pi
          puts identified_by(o, pi)+';'
          return
        end

        print mapping_pragma(o, true)

        if o.fact_type
          verbaliser = ActiveFacts::Metamodel::Verbaliser.new
          # Announce all the objectified fact roles to the verbaliser so it can decide on any necessary subscripting.
          # The RoleRefs for corresponding roles across all readings are for the same player.
          verbaliser.alternate_readings o.fact_type.all_reading
          verbaliser.create_subscripts(:rolenames)

          print " where\n\t" + fact_readings_with_constraints(verbaliser, o.fact_type)*",\n\t"
        end
        puts ";\n"
      end

      def non_subtype_dump(o, pi)
        puts "#{o.name} is" + identified_by(o, pi) + ';'
      end

      def naiive_expand(reading)
        role_refs = reading.role_sequence.all_role_ref_in_order
        reading.text.gsub(/\{(\d+)\}/) do
          role_refs[$1.to_i].role.object_type.name
        end
      end

      def fact_type_dump(fact_type, name)

        if (o = fact_type.entity_type)
          print "#{o.name} is"
          supertypes = o.supertypes
          if supertypes.empty?
            print ' independent' if o.is_independent
          else
            print " a kind of#{
                o.is_independent ? ' independent' : ''
              } #{ supertypes.map(&:name)*', ' }"
          end

          # Alternate identification of objectified fact type?
          primary_supertype = supertypes[0]
          pi = fact_type.entity_type.preferred_identifier
          if pi && primary_supertype && primary_supertype.preferred_identifier != pi
            puts identified_by(o, pi) + ';'
            return
          end
          print " where\n\t"
        end

        # Check whether this fact type has readings which could be confused for a previously-dumped one:
        reading_texts = fact_type.all_reading.map{|r| naiive_expand(r)}
        if reading_texts.size > 1
          ambiguity =
            fact_type.all_role.to_a[0].object_type.all_role.map{|r| r.fact_type}.
              select{|f| f != fact_type && @fact_types_dumped.include?(f) }.
              detect do |dft|
                ambiguous_readings =
                  reading_texts & dft.all_reading.map{|r| naiive_expand(r)}
                ambiguous_readings.size > 0
              end
          if ambiguity
            puts fact_type.default_reading([], true)+';  // Avoid ambiguity; this is a new fact type'
          end
        end

        # There can be no roles of the objectified fact type in the readings, so no need to tell the Verbaliser anything special
        verbaliser = ActiveFacts::Metamodel::Verbaliser.new
        verbaliser.alternate_readings fact_type.all_reading
        pr = fact_type.preferred_reading
        if (pr.role_sequence.all_role_ref.to_a[0].play)
          verbaliser.prepare_role_sequence pr.role_sequence
        end
        verbaliser.create_subscripts(:rolenames)

        print(fact_readings_with_constraints(verbaliser, fact_type)*",\n\t")
        if (pr.role_sequence.all_role_ref.to_a[0].play)
          print ":\n\t"+verbaliser.verbalise_over_role_sequence(pr.role_sequence)
        end
        puts(';')
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
        roles[1..-1].inject(roles[0].object_type){|subclass, role|
          next nil unless subclass and EntityType === role.object_type
          role.object_type.supertypes_transitive.include?(subclass) ? role.object_type : nil
        }
      end

      def dump_presence_constraint(c)
        # Loose binding in PresenceConstraints is limited to explicit role players (in an occurs list)
        # having no exact match, but having instead exactly one role of the same player in the readings.

        verbaliser = ActiveFacts::Metamodel::Verbaliser.new
        # For a mandatory constraint (min_frequency == 1, max == nil or 1) any subtyping step is over the proximate role player
        # For all other presence constraints any subtyping step is over the counterpart player
        role_proximity = c.min_frequency == 1 && [nil, 1].include?(c.max_frequency) ? :proximate : :counterpart
        if role_proximity == :proximate
          verbaliser.role_refs_have_subtype_steps(c.role_sequence)
        else
          join_over, joined_roles = ActiveFacts::Metamodel.plays_over(c.role_sequence.all_role_ref.map{|rr|rr.role}, role_proximity)
          verbaliser.roles_have_same_player(joined_roles) if join_over
        end

        verbaliser.prepare_role_sequence(c.role_sequence, join_over)
        # REVISIT: Need to discount role_adjuncts in here, since this constraint uses loose binding:
        verbaliser.create_subscripts :loose

        expanded_readings = verbaliser.verbalise_over_role_sequence(c.role_sequence, nil, role_proximity)
        if c.min_frequency == 1 && c.max_frequency == nil and c.role_sequence.all_role_ref.size == 2
          puts "either #{expanded_readings*' or '};"
        else
          roles = c.role_sequence.all_role_ref.map{|rr| rr.role }
          players = c.role_sequence.all_role_ref.map{|rr| verbaliser.subscripted_player(rr) }
          players.uniq! if role_proximity == :proximate
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
        transposed_role_refs = scrs.map{|scr| scr.role_sequence.all_role_ref_in_order.to_a}.transpose
        verbaliser = ActiveFacts::Metamodel::Verbaliser.new

        # Tell the verbaliser all we know, so it can figure out which players to subscript:
        players = []
        debug :subscript, "Preparing query across projected roles in set comparison constraint" do
          transposed_role_refs.each do |role_refs|
            verbaliser.role_refs_have_subtype_steps role_refs
            join_over, = ActiveFacts::Metamodel.plays_over(role_refs.map{|rr| rr.role})
            players << join_over
          end
        end
        debug :subscript, "Preparing query between roles in set comparison constraint" do
          role_sequences.each do |role_sequence|
            debug :subscript, "role sequence is #{role_sequence.describe}" do
              verbaliser.prepare_role_sequence role_sequence
            end
          end
        end
        verbaliser.create_subscripts :normal

        if role_sequences.detect{|scr| scr.all_role_ref.detect{|rr| rr.play}}
          # This set constraint has an explicit query. Verbalise it.

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

          # Internal check: We must have located the players here
          if i = players.index(nil)
            rrs = transposed_role_refs[i]
            raise "Internal error detecting constrained object types in query involving #{rrs.map{|rr| rr.role.fact_type.default_reading}.uniq*', '}"
          end

          # Loose binding will apply only to the constrained roles, not to all roles. Not handled here.
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

        # A constrained role may involve a subtyping step. We substitute the name of the supertype for all occurrences.
        players = transposed_role_refs.map{|role_refs| common_supertype(role_refs.map{|rr| rr.role.object_type})}
        raise "Constraint must cover matching roles" if players.compact.size < players.size

        readings_expanded = scrs.
          map do |scr|
            # verbaliser.verbalise_over_role_sequence(scr.role_sequence)
            # REVISIT: verbalise_over_role_sequence cannot do what we need here, because of the
            # possibility of subtyping steps in the constrained roles across the different scr's
            # The following code uses "players" and "constrained_roles" to create substitutions.
            # These should instead be passed to the verbaliser (one variable per index, role_refs for each).
            fact_types_processed = {}
            constrained_roles = scr.role_sequence.all_role_ref_in_order.map{|rr| rr.role}
            join_over, joined_roles = *Metamodel.plays_over(constrained_roles)
            constrained_roles.map do |constrained_role|
              fact_type = constrained_role.fact_type
              next nil if fact_types_processed[fact_type] # Don't emit the same fact type twice (in case of objectification step)
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
        transposed_role_refs = [c.subset_role_sequence, c.superset_role_sequence].map{|rs| rs.all_role_ref_in_order.to_a}.transpose

        verbaliser = ActiveFacts::Metamodel::Verbaliser.new
        transposed_role_refs.each { |role_refs| verbaliser.role_refs_have_subtype_steps role_refs }
        verbaliser.prepare_role_sequence c.subset_role_sequence
        verbaliser.prepare_role_sequence c.superset_role_sequence
        verbaliser.create_subscripts :normal

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

      # Find the common supertype of these object_types.
      def common_supertype(object_types)
        common = object_types[0].supertypes_transitive
        object_types[1..-1].each do |object_type|
          common &= object_type.supertypes_transitive
        end
        common[0]
      end

      #============================================================
      # Verbalisation functions for fact type and entity type definitions
      #============================================================

      def fact_readings_with_constraints(verbaliser, fact_type)
        fact_constraints = @presence_constraints_by_fact[fact_type]
        readings = []
        define_role_names = true
        fact_type.all_reading_by_ordinal.each do |reading|
          readings << expanded_reading(verbaliser, reading, fact_constraints, define_role_names)
          define_role_names = false     # No need to define role names in subsequent readings
        end
        readings
      end

      def expanded_reading(verbaliser, reading, fact_constraints, define_role_names)
        # Arrange the roles in order they occur in this reading:
        role_refs = reading.role_sequence.all_role_ref_in_order
        role_numbers = reading.text.scan(/\{(\d)\}/).flatten.map{|m| Integer(m) }
        roles = role_numbers.map{|m| role_refs[m].role }

        # Find the constraints that constrain frequency over each role we can verbalise:
        frequency_constraints = []
        value_constraints = []
        roles.each do |role|
          value_constraints <<
            if vc = role.role_value_constraint and !@constraints_used[vc]
              @constraints_used[vc] = true
              vc.describe
            else
              nil
            end

          frequency_constraints <<
            if (role == roles.last)   # On the last role of the reading, emit any presence constraint
              constraint = fact_constraints.
                detect do |c|  # Find a UC that spans all other Roles
                  c.is_a?(ActiveFacts::Metamodel::PresenceConstraint) &&
                    !@constraints_used[c] &&  # Already verbalised
                    roles-c.role_sequence.all_role_ref.map(&:role) == [role]
                end
              @constraints_used[constraint] = true if constraint
              constraint && constraint.frequency
            else
              nil
            end
        end

        expanded = verbaliser.expand_reading(reading, frequency_constraints, define_role_names, value_constraints)

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
            player = role_ref.role.object_type
            i = constrained_roles.index(role_ref.role)
            player = players[i] if i
            [ nil, player.name ]
          end
        frequency_constraints = [] unless frequency_constraints.detect{|fc| fc[0] != "some" }

        verbaliser.expand_reading(reading, frequency_constraints)
      end

    end
  end
end
