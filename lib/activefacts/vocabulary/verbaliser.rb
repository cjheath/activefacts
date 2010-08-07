#
#       ActiveFacts Vocabulary Metamodel.
#       Verbaliser for the ActiveFacts Vocabulary
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Metamodel
    #
    # The Verbaliser fulfils two roles:
    # * Maintains verbalisation context to expand readings using subscripting where needed
    # * Verbalises Joins by iteratively choosing a Join Step and expanding readings
    #
    # The verbalisation context consists of a set of Players, each for one Concept.
    # There may be more than one Player for the same Concept. If adjectives or role
    # names don't make such duplicates unambiguous, subscripts will be generated.
    # Thus, the verbalisation context must be completely populated before subscript
    # generation, which must be before any verbalisation occurs.
    #
    # When a Player occurs in a Join, it corresponds to one Join Node of that Join.
    # Each Player has one or more RoleRefs, which refer to Roles of that Concept.
    #
    # When expanding Reading text however, the RoleRefs in the reading's RoleSequence
    # may be expected not to be attached to the Players for that reading. Instead,
    # the set of one or more RoleRefs which caused that reading to be expanded must
    # be passed in, and the corresponding roles matched with Players to determine
    # the need to emit a subscript.
    #
    class Verbaliser
      # Verbalisation context:
      attr_reader :players
      attr_reader :player_by_role_ref
      attr_reader :player_by_join_node

      # The projected role references over which we're verbalising
      attr_reader :role_refs

      # Join Verbaliser context:
      attr_reader :join
      attr_reader :join_nodes                 # All Join Nodes
      attr_reader :join_steps                 # All remaining unemitted Join Steps
      attr_reader :join_steps_by_join_node    # A Hash by Join Node containing an array of remaining steps

      def initialize role_refs = nil
        @role_refs = role_refs

        # Verbalisation context:
        @players = []
        @player_by_role_ref = {}
        @player_by_join_node = {}

        # Join Verbaliser context:
        @join = nil
        @join_nodes = []
        @join_steps = []
        @join_steps_by_join_node = {}

        add_role_refs role_refs if role_refs
      end

      class Player
        attr_accessor :concept, :join_nodes_by_join, :subscript, :role_refs
        def initialize concept
          @concept = concept
          @join_nodes_by_join = {}
          @subscript = nil
          @role_refs = []
        end

        # What words are used (across all roles) for disambiguating the references to this player?
        # If more than one set of adjectives was used, this player must have been subject to loose binding.
        # This method is used to decide when subscripts aren't needed.
        def role_adjuncts
          adjuncts = @role_refs.map{|rr| [rr.leading_adjective, rr.role.role_name, rr.trailing_adjective].compact}.uniq.sort
          adjuncts.flatten*"_"
        end
      end

      # Find or create a Player to which we can add this role_ref
      def player(role_ref)
        # REVISIT: This doesn't work when there are two joins over the underlying role, say each side of a Subset Constraint (see for example Supervision):
        jn = (rrj = role_ref.role.all_role_ref.detect{|rr| rr.join_node}) && rrj.join_node
        @player_by_role_ref[role_ref] or
          @player_by_join_node[jn] or
          @players.push(p = Player.new(role_ref.role.concept)) && p
      end

      # Add a RoleRef to an existing Player
      def add_role_player player, role_ref
        #debug :subscript, "Adding role_ref #{role_ref.object_id} to player #{player.object_id}"
        if jn = role_ref.join_node
          if jn1 = player.join_nodes_by_join[jn.join] and jn1 != jn
            raise "Player for #{player.concept.name} may only have one join node per join, not #{jn1.concept.name} and #{jn.concept.name}"
          end
          player.join_nodes_by_join[jn.join] = jn
          @player_by_join_node[jn] = player
        end

        if !player.role_refs.include?(role_ref)
          debug :subscript, "Adding reference to player #{player.object_id} for #{role_ref.role.concept.name} in #{role_ref.role_sequence.describe} with #{role_ref.role_sequence.all_reading.size} readings"
          player.role_refs.push(role_ref)
          @player_by_role_ref[role_ref] = player
        end
      end

      def add_role_ref role_ref
        add_role_player(player(role_ref), role_ref)
      end

      # Add RoleRefs to one or more Players, creating players where needed
      def add_role_refs role_refs
        role_refs.each{|rr| add_role_ref(rr) }
      end

      # Return an array of the names of these identifying_roles.
      def identifying_role_names identifying_role_refs
        identifying_role_refs.map do |role_ref|
          preferred_role_ref = role_ref.role.fact_type.preferred_reading.role_sequence.all_role_ref.detect{|reading_rr|
            reading_rr.role == role_ref.role
          }

          if (role_ref.role.fact_type.all_role.size == 1)
            role_ref.role.fact_type.default_reading    # Need whole reading for a unary.
          elsif role_name = role_ref.role.role_name and role_name != ''
            role_name
          else
            role_words = []
            role_words << preferred_role_ref.leading_adjective if preferred_role_ref.leading_adjective != ""
            role_words << preferred_role_ref.role.concept.name
            role_words << preferred_role_ref.trailing_adjective if preferred_role_ref.trailing_adjective != ""
            role_name = role_words.compact*"-"
            if p = player(preferred_role_ref) and p.subscript
              role_name += "(#{p.subscript})"
            end
            role_name
          end
        end
      end

      # All these readings are for the same fact type, and all will be emitted, so the roles cover the same players
      # This is used when verbalising fact types and entity types.
      def alternate_readings readings
        readings.map do |reading|
          reading.role_sequence.all_role_ref.sort_by{|rr| rr.role.ordinal}
        end.transpose.each do |role_refs|
          role_refs_have_same_player role_refs
        end
      end

      # These RoleRefs are all for the same player. Find whether any of them has a player already
      def role_refs_have_same_player role_refs
        role_refs = role_refs.is_a?(Array) ? role_refs : role_refs.all_role_ref.to_a
        return if role_refs.empty?
        # If any of these role_refs are for a known player, use that, else make a new player.
        existing_players =
          role_refs.map{|rr| @player_by_role_ref[rr] || @player_by_join_node[rr.join_node] }.compact.uniq
        if existing_players.size > 1
          raise "Can't join these role_refs to more than one existing player: #{existing_players.map{|p|p.concept.name}*', '}!"
        end
        p = existing_players[0] || player(role_refs[0])
        debug :subscript, "#{existing_players[0] ? 'Adding to existing' : 'Creating new'} player for #{role_refs.map{|rr| rr.role.concept.name}.uniq*', '}" do
          role_refs.each do |rr|
            add_role_player(p, rr)
          end
        end
      end

      def create_subscripts
        # Create subscripts, where necessary
        @players.
          map{|p| [p, p.concept] }.
          each do |player, concept|
            dups = @players.select{|p| p.concept == concept && p.role_adjuncts == player.role_adjuncts }
            if dups.size == 1
              debug :subscript, "No subscript needed for #{concept.name}"
              next
            end
            debug :subscript, "Applying subscripts to #{dups.size} occurrences of #{concept.name}" do
              dups.each_with_index do |player, index|
                player.subscript = index+1
              end
            end
          end
      end

      # Expand a reading for an entity type or fact type definition. Unlike expansions in constraints,
      # these expansions include frequency constraints, role names and value constraints as passed-in,
      # and also define adjectives by using the hyphenated form (on at least the first occurrence).
      def expand_reading(reading, frequency_constraints = [], define_role_names = nil, value_constraints = [], &subscript_block)
        reading.expand(frequency_constraints, define_role_names, value_constraints) do |role_ref|
          (p = player(role_ref) and p.subscript) ? "(#{p.subscript})" : ""
        end
      end

      # Where no explicit Join has been created, a join is still sometimes present (e.g. in a constraint from NORMA)
      # REVISIT: This probably doesn't produce the required result. Need to fix the NORMA importer to create the join.
      def role_refs_are_subtype_joined roles
        role_refs = roles.is_a?(Array) ? roles : roles.all_role_ref.to_a
        role_refs_by_concept = role_refs.inject({}) { |h, r| (h[r.role.concept] ||= []) << r; h }
        # debugger if role_refs_by_concept.size > 1
        role_refs_by_concept.values.each { |rrs|  role_refs_have_same_player(rrs) }
      end

      # These roles are the players in an implicit counterpart join in a Presence Constraint.
      # REVISIT: It's not clear that we can safely use the preferred_reading's RoleRefs here.
      # Fix the CQL compiler to create proper joins for these presence constraints instead.
      def roles_have_same_player roles
        role_refs = roles.map do |role|
          pr = role.fact_type.preferred_reading
          pr.role_sequence.all_role_ref.detect{|rr| rr.role == role}
        end
        role_refs_have_same_player(role_refs)
      end

      def prepare_role_sequence role_sequence
        @role_refs = role_sequence.is_a?(Array) ? role_sequence : role_sequence.all_role_ref.to_a

        if jrr = @role_refs.detect{|rr| rr.join_node}
          return prepare_join_players(jrr.join_node.join)
        end

        # Ensure that all the joined-over role_refs are indexed for subscript generation.
        role_refs_by_fact_type =
          @role_refs.inject({}) { |hash, rr| (hash[rr.role.fact_type] ||= []) << rr; hash }
        role_refs_by_fact_type.each do |fact_type, role_refs|
          role_refs.each { |rr| role_refs_have_same_player([rr]) }

          # Register the role_refs in the preferred reading which refer to roles not covered in the role sequence.
          prrs = fact_type.preferred_reading.role_sequence.all_role_ref
          residual_roles = fact_type.all_role.select{|r| !@role_refs.detect{|rr| rr.role == r} }
          residual_roles.each do |role|
            debug :subscript, "Adding residual role for #{role.concept.name} not covered in role sequence"
            preferred_role_ref = prrs.detect{|rr| rr.role == role}
            if p = @player_by_role_ref[preferred_role_ref] and !p.role_refs.include?(preferred_role_ref)
              raise "Adding DUPLICATE residual role for #{role.concept.name}"
            end
            role_refs_have_same_player([prrs.detect{|rr| rr.role == role}])
          end
        end
      end

      def prepare_join_players join
        debug :subscript, "Indexing roles of fact types in #{@join_steps.size} join steps" do
          join_steps = []
          # Register all references to each join node as being for the same player:
          join.all_join_node.sort_by{|jn| jn.ordinal}.each do |join_node|
            role_refs_have_same_player(join_node.all_role_ref.to_a)
            join_steps += join_node.all_join_step_as_input_join_node.to_a + join_node.all_join_step_as_output_join_node.to_a 
          end
          # For each fact type traversed, register a player for each role *not* linked to this join
          # REVISIT: Using the preferred_reading role_ref is wrong here; the same preferred_reading might occur twice,
          # so the respective concept will need more than one Player and will be subscripted to keep them from being joined.
          # Accordingly, there must be a join step for each such role, and to enforce that, I raise an exception here on duplication.
          join_steps.map{|js|js.fact_type}.uniq.each do |fact_type|
            next if fact_type.is_a?(ActiveFacts::Metamodel::ImplicitFactType)
            prrs = fact_type.preferred_reading.role_sequence.all_role_ref
            residual_roles = fact_type.all_role.select{|r| !r.all_role_ref.detect{|rr| rr.join_node && rr.join_node.join == join} }
            residual_roles.each do |r|
              debug :subscript, "Adding residual role for #{r.concept.name} not covered in join"
              preferred_role_ref = prrs.detect{|rr| rr.role == r}
              if p = @player_by_role_ref[preferred_role_ref] and !p.role_refs.include?(preferred_role_ref)
                raise "Adding DUPLICATE residual role for #{r.concept.name} not covered in join"
              end
              role_refs_have_same_player([preferred_role_ref])
            end
          end
        end
      end

      def verbalise_over_role_sequence role_sequence, joiner = ' and ', role_proximity = :both
        @role_refs = role_sequence.is_a?(Array) ? role_sequence : role_sequence.all_role_ref.to_a

        if jrr = role_refs.detect{|rr| rr.join_node}
          return verbalise_join(jrr.join_node.join)
        end

        # First, figure out whether there's a join:
        join_over, joined_roles = *Metamodel.join_roles_over(role_sequence.all_role_ref.map{|rr|rr.role}, role_proximity)

        fact_types = @role_refs.map{|rr| rr.role.fact_type}.uniq
        readings = fact_types.map do |fact_type|
          name_substitutions = []
          reading = fact_type.preferred_reading
          if join_over and      # Find a reading preferably starting with the joined_over role:
            joined_role = fact_type.all_role.select{|r| join_over.subtypes_transitive.include?(r.concept)}[0]
            reading = fact_type.reading_preferably_starting_with_role joined_role

            # Use the name of the joined_over object, not the role player, in case of a subtype join:
            rrrs = reading.role_sequence.all_role_ref_in_order
            role_index = (0..rrrs.size).detect{|i| rrrs[i].role == joined_role }
            name_substitutions[role_index] = [nil, join_over.name]
          end
          reading.role_sequence.all_role_ref.each do |rr|
            next unless player = @player_by_role_ref[rr]
            next unless subscript = player.subscript
            debug :subscript, "Need to apply subscript #{subscript} to #{rr.role.concept.name}"
          end
          role_refs = @player_by_role_ref.keys.select{|rr| rr.role.fact_type == fact_type}
          expand_reading_text(nil, reading.text, reading.role_sequence, role_refs)
          #reading.expand(name_substitutions)
        end
        joiner ? readings*joiner : readings
      end

      # Expand this reading (or partial reading, during contraction)
      def expand_reading_text(step, text, role_sequence, role_refs = [])
        rrs = role_sequence.all_role_ref_in_order
        debug :subscript, "expanding #{text} with #{role_sequence.describe}" do
          text.gsub(/\{(\d)\}/) do
            role_ref = rrs[$1.to_i]
            # REVISIT: We may need to use the step's role_refs to expand the role players here, not the reading's one (extra adjectives?)
            # REVISIT: There's no way to get literals to be emitted here (value join step?)

            rr = role_refs.detect{|rr| rr.role == role_ref.role} || role_ref

            player = @player_by_role_ref[rr] and subscript = player.subscript
            if !subscript and
              pp = @players.select{|p|p.concept == rr.role.concept} and
              pp.detect{|p|p.subscript}
              raise "Internal error: Subscripted players (of the same concept #{p.concept.name}) when this player isn't subscripted"
            end

            subscripted_player(rr, role_ref) +
              objectification_verbalisation(role_ref.role.concept)
          end
        end
      end

      def subscripted_player role_ref, reading_role_ref = nil
        if player = @player_by_role_ref[role_ref] and subscript = player.subscript
          debug :subscript, "Need to apply subscript #{subscript} to #{role_ref.role.concept.name}"
        end
        concept = role_ref.role.concept
        [
          (reading_role_ref || role_ref).leading_adjective,
          concept.name,
          (reading_role_ref || role_ref).trailing_adjective
        ].compact*' ' +
          (subscript ? "(#{subscript})" : '')
      end

      def expand_contracted_text(step, reading, role_refs = [])
        ' that ' +
          expand_reading_text(step, reading.text.sub(/\A\{\d\} /,''), reading.role_sequence, role_refs)
      end

      # Each join we wish to verbalise must first have had its players prepared.
      # Then, this prepares the join for verbalising:
      def prepare_join join
        @join = join
        return unless join

        @join_nodes = join.all_join_node.sort_by{|jn| jn.ordinal}

        @join_steps = @join_nodes.map{|jn| jn.all_join_step_as_input_join_node.to_a + jn.all_join_step_as_output_join_node.to_a }.flatten.uniq
        @join_steps_by_join_node = @join_nodes.
          inject({}) do |h, jn|
            jn.all_join_step_as_input_join_node.each{|js| (h[jn] ||= []) << js}
            jn.all_join_step_as_output_join_node.each{|js| (h[jn] ||= []) << js}
            h
          end
      end

      # Remove this step now that we've processed it:
      def step_completed(step)
        @join_steps.delete(step)

        input_node = step.input_join_node
        steps = @join_steps_by_join_node[input_node]
        steps.delete(step)
        @join_steps_by_join_node.delete(input_node) if steps.empty?

        output_node = step.output_join_node
        if (input_node != output_node)
          steps = @join_steps_by_join_node[output_node]
          steps.delete(step)
          @join_steps_by_join_node.delete(output_node) if steps.empty?
        end
      end

      def choose_step(next_node)
        next_steps = @join_steps_by_join_node[next_node]

        # If we don't have a next_node against which we can contract,
        # so just use any join step involving this node, or just any step.
        if next_steps
          if next_step = next_steps.detect { |ns| !ns.is_objectification_step }
            debug :join, "Chose new non-objectification step: #{next_step.describe}"
            return next_step
          end
        end

        if next_step = @join_steps.detect { |ns| !ns.is_objectification_step }
          debug :join, "Chose random non-objectification step: #{next_step.describe}"
          return next_step
        end

        next_step = @join_steps[0]
        if next_step
          debug :join, "Chose new random step from #{join_steps.size}: #{next_step.describe}"
          if next_step.is_objectification_step
            # if this objectification plays any roles (other than its FT roles) in remaining steps, use one of those first:
            fact_type = next_step.fact_type.role.fact_type
            jn = [next_step.input_join_node, next_step.output_join_node].detect{|jn| jn.concept == fact_type.entity_type}
            sr = @join_steps_by_join_node[jn].reject{|t| t.fact_type.role and t.fact_type.role.fact_type == fact_type}
            next_step = sr[0] if sr.size > 0 
          end
          return next_step
        end
        raise "Internal error: There are more join steps here, but we failed to choose one"
      end

      # The join step we just emitted (using the reading given) is contractable iff
      # the reading has the next_node's role player as the final text
      def node_contractable_against_reading(next_node, reading)
        reading &&
          # Find whether last role has no following text, and its ordinal
        (reading.text =~ /\{([0-9])\}$/) &&
          # This reading's RoleRef for that role:
        (role_ref = reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i}) &&
          # was that RoleRef for the upcoming node?
        role_ref.role.all_role_ref.detect{|rr| rr.join_node == next_node}
      end

      def reading_starts_with_node(reading, next_node)
        reading.text =~ /^\{([0-9])\}/ and
          role_ref = reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i} and
          role_ref.role.all_role_ref.detect{|rr| rr.join_node == next_node}
      end

      # The last reading we emitted ended with the object type name for next_node.
      # Choose a step and a reading that can be contracted against that name
      def contractable_step(next_steps, next_node)
        next_reading = nil
        next_step =
          next_steps.detect do |js|
            next false if js.is_objectification_step
            # If we find a reading here, it can be contracted against the previous one
            next_reading =
              js.fact_type.all_reading_by_ordinal.detect do |reading|
                # This step is contractable iff the FactType has a reading that starts with the role of next_node (no preceding text)
                reading_starts_with_node(reading, next_node)
              end
            next_reading
          end
        debug :join, "#{next_reading ? "'"+next_reading.expand+"'" : "No reading"} contracts against last node '#{next_node.concept.name}'"
        return [next_step, next_reading]
      end

      # REVISIT: There might be more than one objectification_verbalisation for a given concept. Need to get the Join Node here and emit an objectification step involving that node.
      def objectification_verbalisation(concept)
        objectified_node = nil
        unless concept.is_a?(Metamodel::EntityType) and
          concept.fact_type and            # Not objectified
          objectification_step = @join_steps.
            detect do |js|
              # The objectifying entity type should always be the input_join_node here, but be safe:
              js.is_objectification_step and
                (objectified_node = js.input_join_node).concept == concept ||
                (objectified_node = js.output_join_node).concept == concept
            end
          return ''
        end

        # REVISIT: We need to be working from the role_ref here - pass it in
        # if objectification_step.join_node != role_ref.join_node

        steps = [objectification_step]
        step_completed(objectification_step)
        while other_step =
          @join_steps.
            detect{|js|
              js.is_objectification_step and
                js.input_join_node.concept == concept || js.output_join_node.concept == concept
            }
          steps << other_step
          debug :join, "Emitting objectification step allows deleting #{other_step.describe}"
          step_completed(other_step)
        end

        # Find all references to roles in this objectified fact type which are relevant to the join nodes of these steps:
        role_refs = steps.map{|step| [step.input_join_node, step.output_join_node].map{|jn| jn.all_role_ref.detect{|rr| rr.role.fact_type == concept.fact_type}}}.flatten.compact.uniq

        reading = concept.fact_type.preferred_reading
        " (where #{expand_reading_text(objectification_step, reading.text, reading.role_sequence, role_refs)})" 
      end

      def elided_objectification(next_step, fact_type, last_is_contractable, next_node)
        if last_is_contractable
          # Choose a reading that's contractable against the previous step, if possible
          reading = fact_type.all_reading_by_ordinal.
            detect do |reading|
              reading_starts_with_node(reading, next_node)
            end
        end
        last_is_contractable = false unless reading
        reading ||= fact_type.preferred_reading

        # Find which role occurs last in the reading, and which Join Node is attached
        reading.text =~ /\{(\d)\}[^{]*\Z/
        last_role_ref = reading.role_sequence.all_role_ref_in_order[$1.to_i]
        exit_node = @join_nodes.detect{|jn| jn.all_role_ref.detect{|rr| rr.role == last_role_ref.role}}
        exit_step = nil

        while other_step =
          @join_steps.
            detect{|js|
              next unless js.is_objectification_step
              next unless js.input_join_node.concept == fact_type.entity_type || js.output_join_node.concept == fact_type.entity_type
              exit_step = js if js.output_join_node == exit_node
              true
            }
          debug :join, "Emitting objectified FT allows deleting #{other_step.describe}"
          step_completed(other_step)
        end
        [ reading, exit_step ? exit_step.input_join_node : exit_node, exit_step, last_is_contractable]
      end

      def verbalise_join join
        prepare_join join
        readings = ''
        next_node = @role_refs[0].join_node   # Choose a place to start
        last_is_contractable = false
        debug :join, "Join Nodes are #{@join_nodes.map{|jn| jn.describe }.inspect}, Join Steps are #{@join_steps.map{|js| js.describe }.inspect}" do
          until @join_steps.empty?
            next_reading = nil
            # Choose amonst all remaining steps we can take from the next node, if any
            next_steps = @join_steps_by_join_node[next_node]
            debug :join, "Next Steps from #{next_node.describe} are #{(next_steps||[]).map{|js| js.describe }.inspect}"

            # See if we can find a next step that contracts against the last (if any):
            next_step = nil
            if last_is_contractable && next_steps
              next_step, next_reading = *contractable_step(next_steps, next_node)
                end

            if next_step
              debug :join, "Chose #{next_step.describe} because it's contractable against last node #{next_node.all_role_ref.to_a[0].role.concept.name} using #{next_reading.expand}"

              step_ft = next_step.fact_type.is_a?(ActiveFacts::Metamodel::ImplicitFactType) ? next_step.fact_type.role.fact_type : next_step.fact_type
              step_role_refs =   # for the two join nodes of this step, get the relevant role_refs for roles in this fact type
                [next_step.input_join_node, next_step.output_join_node].
                  uniq.
                  map{|jn| jn.all_role_ref.select{|rr| rr.role.fact_type == step_ft } }.
                  flatten.uniq
              readings += expand_contracted_text(next_step, next_reading, step_role_refs)
              step_completed(next_step)
            else
              next_step = choose_step(next_node) if !next_step

              step_ft = next_step.fact_type.is_a?(ActiveFacts::Metamodel::ImplicitFactType) ? next_step.fact_type.role.fact_type : next_step.fact_type
              step_role_refs =   # for the two join nodes of this step, get the relevant role_refs for roles in this fact type
                [next_step.input_join_node, next_step.output_join_node].
                  uniq.
                  map{|jn| jn.all_role_ref.select{|rr| rr.role.fact_type == step_ft } }.
                  flatten.uniq

              if next_step.is_unary_step
                # Objectified unaries get emitted as unaries, not as objectifications:
                # REVISIT: There must be a simpler way of finding the preferred reading here:
                rr = next_step.input_join_node.all_role_ref.detect{|rr| rr.role.fact_type.is_a?(ImplicitFactType) }
                next_reading = rr.role.fact_type.role.fact_type.preferred_reading
                readings += " and " unless readings.empty?
                readings += expand_reading_text(next_step, next_reading.text, next_reading.role_sequence, step_role_refs)
                step_completed(next_step)
              elsif next_step.is_objectification_step
                fact_type = next_step.fact_type.role.fact_type
                if last_is_contractable and next_node.concept.is_a?(EntityType) and next_node.concept.fact_type == fact_type
                  # The last reading we emitted ended with the name of the objectification of this fact type, so we can contract the objectification
#                  if (n = next_step.input_join_node).concept == fact_type.entity_type ||
#                    (n = next_step.output_join_node).concept == fact_type.entity_type
#                    debugger
#                    p n.concept.name  # This is the join_node which has the role_ref (and subscript!) we should use for the objectification_verbalisation
#                  end
                  # REVISIT: Do we need to use step_role_refs here (if this objectification is traversed twice and so is subscripted)
                  readings += objectification_verbalisation(fact_type.entity_type)
                else
                  # This objectified fact type does not need to be made explicit.
                  next_reading, next_node, next_step, last_is_contractable =
                    *elided_objectification(next_step, fact_type, last_is_contractable, next_node)
                  if last_is_contractable
                    readings += expand_contracted_text(next_step, next_reading, step_role_refs)
                  else
                    readings += " and " unless readings.empty?
                    readings += expand_reading_text(next_step, next_reading.text, next_reading.role_sequence, step_role_refs)
                  end
                  # No need to continue if we just deleted the last step
                  break if @join_steps.empty?

                end
              else
                fact_type = next_step.fact_type
                # Prefer a reading that starts with the player of next_node
                next_reading = fact_type.all_reading_by_ordinal.
                  detect do |reading|
                    reading.text =~ /^\{([0-9])\}/ and
                      role_ref = reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i} and
                      role_ref.role.all_role_ref.detect{|rr| rr.join_node == next_node}
                  end || fact_type.preferred_reading
                # REVISIT: If this join step and reading has role references with adjectives, we need to expand using those
                readings += " and " unless readings.empty?
                readings += expand_reading_text(next_step, next_reading.text, next_reading.role_sequence, step_role_refs)
                step_completed(next_step)
              end
            end

            # Continue from this step with the node having the most steps remaining
            input_steps = @join_steps_by_join_node[next_step.input_join_node] || []
            output_steps = @join_steps_by_join_node[next_step.output_join_node] || []
            next_node = input_steps.size > output_steps.size ? next_step.input_join_node : next_step.output_join_node
            # Prepare for possible contraction following:
            last_is_contractable = next_reading && node_contractable_against_reading(next_node, next_reading)

          end
        end
        readings
      end
    end

  end
end
