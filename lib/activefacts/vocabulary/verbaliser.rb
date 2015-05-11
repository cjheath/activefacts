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
    # * Verbalises Queries by iteratively choosing a Step and expanding readings
    #
    # The verbalisation context consists of a set of Players, each for one ObjectType.
    # There may be more than one Player for the same ObjectType. If adjectives or role
    # names don't make such duplicates unambiguous, subscripts will be generated.
    # Thus, the verbalisation context must be completely populated before subscript
    # generation, which must be before any Player name gets verbalised.
    #
    # When a Player occurs in a Query, it corresponds to one Variable of that Query.
    # Each such Player has one or more Plays, which refer to roles played by
    # that ObjectType. Where a query traverses two roles of a ternary fact type, there
    # will be a residual node that has only a single Play with no other meaning.
    # A Play must be for exactly one Player, so is used to identify a Player.
    #
    # When a Player occurs outside a Query, it's identified by a projected RoleRef.
    # REVISIT: This is untrue when a uniqueness constraint is imported from NORMA.
    # In this case no query will be constructed to project the roles of the constrained
    # object type (only the constrained roles will be projected) - this will be fixed.
    #
    # Each constraint (except Ring Constraints) has one or more RoleSequence containing
    # the projected RoleRefs. Each constrained RoleSequence may have an associated Query.
    # If it has a Query, each RoleRef is projected from a Play, otherwise none are.
    #
    # The only type of query possible in a Ring Constraint is a subtyping query, which
    # is always implicit and unambiguous, so is never instantiated.
    #
    # A constrained RoleSequence that has no explicit Query may have an implicit query,
    # as per ORM2, when the roles aren't in the same fact type.  These implicit queries
    # are over only one ObjectType, by traversing a single FactType (and possibly,
    # multiple TypeInheritance FactTypes) for each RoleRef. Note however that when
    # the ObjectType is an objectified Fact Type, the FactType traversed might be a
    # phantom of the objectification. In the case of implicit queries, each Player is
    # identified by the projected RoleRef, except for the joined-over ObjectType whose
    # Player is... well, read the next paragraph!
    #
    # REVISIT: I believe that the foregoing paragraph is out of date, except with
    # respect to PresenceConstraints imported from NORMA (both external mandatory
    # and external uniqueness constraints). The joined-over Player in a UC is
    # identified by its RoleRefs in the RoleSequence of the Fact Type's preferred
    # reading. Subtyping steps in a mandatory constraint will probably malfunction.
    # However, all other such queries are explicit, and these should be also.
    #
    # For a SetComparisonConstraint, there are two or more constrained RoleSequences.
    # The matching RoleRefs (by Ordinal position) are for joined players, that is,
    # one individual instance plays both roles. The RoleRefs must (now) be for the
    # same ObjectType (no implicit subtyping step is allowed). Instead, the input modules
    # find the closest common supertype and create explicit Steps so its roles
    # can be projected.
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
      attr_reader :player_by_play             # Used for each query
      attr_reader :player_joined_over         # Used when there's an implicit query
      attr_reader :player_by_role_ref         # Used when a constrained role sequence has no query

      # The projected role references over which we're verbalising
      attr_reader :role_refs

      # Query Verbaliser context:
      attr_reader :query
      attr_reader :variables                  # All Variables
      attr_reader :steps                      # All remaining unemitted Steps
      attr_reader :steps_by_variable          # A Hash by Variable containing an array of remaining steps

      def initialize role_refs = nil
        @role_refs = role_refs

        # Verbalisation context:
        @players = []
        @player_by_play = {}
        @player_by_role_ref = {}
        @player_joined_over = nil

        # Query Verbaliser context:
        @query = nil
        @variables = []
        @steps = []
        @steps_by_variable = {}

        add_role_refs role_refs if role_refs
      end

      class Player
        attr_accessor :object_type, :variables_by_query, :subscript, :plays, :role_refs
        def initialize object_type
          @object_type = object_type
          @variables_by_query = {}
          @subscript = nil
          @plays = []
          @role_refs = []
        end

        # What words are used (across all roles) for disambiguating the references to this player?
        # If more than one set of adjectives was used, this player must have been subject to loose binding.
        # This method is used to decide when subscripts aren't needed.
        def role_adjuncts matching
          if matching == :loose
            adjuncts = []
          else
            adjuncts = @role_refs.map{|rr|
              [
                rr.leading_adjective,
                matching == :rolenames ? rr.role.role_name : nil,
                rr.trailing_adjective
              ].compact}.uniq.sort
          end
          adjuncts += [@variables_by_query.values.map{|jn| jn.role_name}.compact[0]].compact
          adjuncts.flatten*"_"
        end

        def describe
          @object_type.name + (@variables_by_query.size > 0 ? " (in #{@variables_by_query.size} variables)" : "")
        end
      end

      # Find or create a Player to which we can add this role_ref
      def player(ref)
        existing_player = if ref.is_a?(ActiveFacts::Metamodel::Play)
            @player_by_play[ref]
          else
            @player_by_role_ref[ref] or ref.play && @player_by_play[ref.play]
          end
        if existing_player
          trace :player, "Using existing player for #{ref.role.object_type.name} #{ref.respond_to?(:role_sequence) && ref.role_sequence.all_reading.size > 0 ? ' in reading' : ''}in '#{ref.role.fact_type.default_reading}'"
          return existing_player
        else
          trace :player, "Adding new player for #{ref.role.object_type.name} #{ref.respond_to?(:role_sequence) && ref.role_sequence.all_reading.size > 0 ? ' in reading' : ''}in '#{ref.role.fact_type.default_reading}'"
          p = Player.new(ref.role.object_type)
          @players.push(p)
          p
        end
      end

      def add_play player, play
        return if player.plays.include?(play)
        jn = play.variable
        if jn1 = player.variables_by_query[jn.query] and jn1 != jn
          raise "Player for #{player.object_type.name} may only have one variable per query, not #{jn1.object_type.name} and #{jn.object_type.name}"
        end
        player.variables_by_query[jn.query] = jn
        @player_by_play[play] = player
        player.plays << play
      end

      # Add a RoleRef to an existing Player
      def add_role_player player, role_ref
        #trace :subscript, "Adding role_ref #{role_ref.object_id} to player #{player.object_id}"
        if play = role_ref.play
          add_play(player, play)
        elsif !player.role_refs.include?(role_ref)
          trace :subscript, "Adding reference to player #{player.object_id} for #{role_ref.role.object_type.name} in #{role_ref.role_sequence.describe} with #{role_ref.role_sequence.all_reading.size} readings"
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
            role_name = preferred_role_ref.cql_name
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

      def plays_have_same_player plays
        return if plays.empty?

        # If any of these plays are for a known player, use that, else make a new player.
        existing_players = plays.map{|play| @player_by_play[play] }.compact.uniq
        if existing_players.size > 1
          raise "At most one existing player can play these roles: #{existing_players.map{|p|p.object_type.name}*', '}!"
        end
        p = existing_players[0] || player(plays[0])
        trace :subscript, "roles are playes of #{p.describe}" do
          plays.each do |play|
            trace :subscript, "#{play.describe}" do
              add_play p, play
            end
          end
        end
      end

      # These RoleRefs are all for the same player. Find whether any of them has a player already
      def role_refs_have_same_player role_refs
        role_refs = role_refs.is_a?(Array) ? role_refs : role_refs.all_role_ref.to_a
        return if role_refs.empty?

        # If any of these role_refs are for a known player, use that, else make a new player.
        existing_players =
          role_refs.map{|rr| @player_by_role_ref[rr] || @player_by_play[rr.play] }.compact.uniq
        if existing_players.size > 1
          raise "At most one existing player can play these roles: #{existing_players.map{|p|p.object_type.name}*', '}!"
        end
        p = existing_players[0] || player(role_refs[0])

        trace :subscript, "#{existing_players[0] ? 'Adding to existing' : 'Creating new'} player for #{role_refs.map{|rr| rr.role.object_type.name}.uniq*', '}" do
          role_refs.each do |rr|
            unless p.object_type == rr.role.object_type
              # This happens in SubtypePI because uniqueness constraint is built without its implicit subtyping step.
              # For now, explode only if there's no common supertype:
              if 0 == (p.object_type.supertypes_transitive & rr.role.object_type.supertypes_transitive).size
                raise "REVISIT: Internal error, trying to add role of #{rr.role.object_type.name} to player #{p.object_type.name}"
              end
            end
            add_role_player(p, rr)
          end
        end
      end

      # REVISIT: include_rolenames is a bit of a hack. Role names generally serve to disambiguate players,
      # so subscripts wouldn't be needed, but where a constraint refers to a fact type which is defined with
      # role names, those are considered. We should instead consider only the role names that are defined
      # within the constraint, not in the underlying fact types. For now, this parameter is passed as true
      # from all the object type verbalisations, and not from constraints.
      def create_subscripts(matching = :normal)
        # Create subscripts, where necessary
        @players.each { |p| p.subscript = nil } # Wipe subscripts
        @players.
          map{|p| [p, p.object_type] }.
          each do |player, object_type|
            next if player.subscript  # Done previously
            dups = @players.select do |p|
              p.object_type == object_type &&
                p.role_adjuncts(matching) == player.role_adjuncts(matching)
              end
            if dups.size == 1
              trace :subscript, "No subscript needed for #{object_type.name}"
              next
            end
            trace :subscript, "Applying subscripts to #{dups.size} occurrences of #{object_type.name}" do
              s = 0
              dups.
                sort_by do |p|   # Guarantee stable numbering
                  p.role_adjuncts(:role_name) + ' ' +
                    # Tie-breaker:
                    p.role_refs.map{|rr| rr.role.fact_type.preferred_reading.text}.sort.to_s
                end.
                each do |player|
		  jrname = player.plays.map{|play| play.role_ref && play.role_ref.role.role_name}.compact[0]
		  rname = (rr = player.role_refs[0]) && rr.role.role_name
		  if jrname and !rname
		    # puts "Oops: rolename #{rname.inspect} != #{jrname.inspect}" if jrname != rname
		    player.variables_by_query.values.each{|jn| jn.role_name = jrname }
		  else
		    player.subscript = s+1
		    s += 1
		  end
		end
            end
          end
      end

      # Expand a reading for an entity type or fact type definition. Unlike expansions in constraints,
      # these expansions include frequency constraints, role names and value constraints as passed-in,
      # and also define adjectives by using the hyphenated form (on at least the first occurrence).
      def expand_reading(reading, frequency_constraints = [], define_role_names = nil, value_constraints = [], &subscript_block)
        reading.expand(frequency_constraints, define_role_names, value_constraints) do |role_ref, *parts|
          parts + [
            (!(role_ref.role.role_name and define_role_names != nil) and p = player(role_ref) and p.subscript) ? "(#{p.subscript})" : nil
          ]
        end
      end

      # Where no explicit Query has been created, a query is still sometimes present (e.g. in a constraint from NORMA)
      # REVISIT: This probably doesn't produce the required result. Need to fix the NORMA importer to create the query.
      def role_refs_have_subtype_steps roles
        role_refs = roles.is_a?(Array) ? roles : roles.all_role_ref.to_a
        role_refs_by_object_type = role_refs.inject({}) { |h, r| (h[r.role.object_type] ||= []) << r; h }
        role_refs_by_object_type.values.each { |rrs|  role_refs_have_same_player(rrs) }
      end

      # These roles are the players in an implicit counterpart join in a Presence Constraint.
      # REVISIT: It's not clear that we can safely use the preferred_reading's RoleRefs here.
      # Fix the CQL compiler to create proper queries for these presence constraints instead.
      def roles_have_same_player roles
        role_refs = roles.map do |role|
          role.fact_type.all_reading.map{|reading|
            reading.role_sequence.all_role_ref.detect{|rr| rr.role == role}
          } +
          role.all_role_ref.select{|rr| rr.role_sequence.all_reading.size == 0 }
        end.flatten.uniq
        role_refs_have_same_player(role_refs)
      end

      def prepare_role_sequence role_sequence, join_over = nil
        @role_refs = role_sequence.is_a?(Array) ? role_sequence : role_sequence.all_role_ref.to_a

        if jrr = @role_refs.detect{|rr| rr.play && rr.play.variable}
          return prepare_query_players(jrr.play.variable.query)
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
            trace :subscript, "Adding residual role for #{role.object_type.name} (in #{fact_type.default_reading}) not covered in role sequence"
            preferred_role_ref = prrs.detect{|rr| rr.role == role}
            if p = @player_by_role_ref[preferred_role_ref] and !p.role_refs.include?(preferred_role_ref)
              raise "Adding DUPLICATE residual role for #{role.object_type.name}"
            end
            role_refs_have_same_player([prrs.detect{|rr| rr.role == role}])
          end
        end
      end

      def prepare_query_players query
        trace :subscript, "Indexing roles of fact types in #{query.all_step.size} steps" do
          steps = []
          # Register all references to each variable as being for the same player:
          query.all_variable.to_a.sort_by(&:ordinal).each do |variable|
            trace :subscript, "Adding Roles of #{variable.describe}" do
              plays_have_same_player(variable.all_play.to_a)
              steps = steps | variable.all_step
            end
          end

=begin
          # For each fact type traversed, register a player for each role *not* linked to this query
          # REVISIT: Using the preferred_reading role_ref is wrong here; the same preferred_reading might occur twice,
          # so the respective object_type will need more than one Player and will be subscripted to keep them from being joined.
          # Accordingly, there must be a step for each such role, and to enforce that, I raise an exception here on duplication.
          # This isn't needed now all Variables have at least one Play

          steps.map do |js|
            if js.fact_type.is_a?(ActiveFacts::Metamodel::LinkFactType)
              js.fact_type.implying_role.fact_type
            else
              js.fact_type
            end
          end.uniq.each do |fact_type|
          #steps.map{|js|js.fact_type}.uniq.each do |fact_type|
            next if fact_type.is_a?(ActiveFacts::Metamodel::LinkFactType)

            trace :subscript, "Residual roles in '#{fact_type.default_reading}' are" do
              prrs = fact_type.preferred_reading.role_sequence.all_role_ref
              residual_roles = fact_type.all_role.select{|r| !r.all_role_ref.detect{|rr| rr.variable && rr.variable.query == query} }
              residual_roles.each do |r|
                trace :subscript, "Adding residual role for #{r.object_type.name} (in #{fact_type.default_reading}) not covered in query"
                preferred_role_ref = prrs.detect{|rr| rr.role == r}
                if p = @player_by_role_ref[preferred_role_ref] and !p.role_refs.include?(preferred_role_ref)
                  raise "Adding DUPLICATE residual role for #{r.object_type.name} not covered in query"
                end
                role_refs_have_same_player([preferred_role_ref])
              end
            end
          end
=end
        end
      end

      def verbalise_over_role_sequence role_sequence, conjunction = ' and ', role_proximity = :both
        @role_refs = role_sequence.is_a?(Array) ? role_sequence : role_sequence.all_role_ref.to_a

        if jrr = role_refs.detect{|rr| rr.play}
          return verbalise_query(jrr.play.variable.query)
        end

        # First, figure out whether there's a query:
        join_over, joined_roles = *Metamodel.plays_over(role_sequence.all_role_ref.map{|rr|rr.role}, role_proximity)

        role_by_fact_type = {}
        fact_types = @role_refs.map{|rr| ft = rr.role.fact_type; role_by_fact_type[ft] ||= rr.role; ft}.uniq
        readings = fact_types.map do |fact_type|
          name_substitutions = []
          # Choose a reading that start with the (first) role which caused us to emit this fact type:
          reading = fact_type.reading_preferably_starting_with_role(role_by_fact_type[fact_type])
          if join_over and      # Find a reading preferably starting with the joined_over role:
            joined_role = fact_type.all_role.select{|r| join_over.subtypes_transitive.include?(r.object_type)}[0]
            reading = fact_type.reading_preferably_starting_with_role joined_role

            # Use the name of the joined_over object, not the role player, in case of a subtype step:
            rrrs = reading.role_sequence.all_role_ref_in_order
            role_index = (0..rrrs.size).detect{|i| rrrs[i].role == joined_role }
            name_substitutions[role_index] = [nil, join_over.name]
          end
          reading.role_sequence.all_role_ref.each do |rr|
            next unless player = @player_by_role_ref[rr]
            next unless subscript = player.subscript
            trace :subscript, "Need to apply subscript #{subscript} to #{rr.role.object_type.name}"
          end
          player_by_role = {}
          @player_by_role_ref.keys.each{|rr| player_by_role[rr.role] = @player_by_role_ref[rr] if rr.role.fact_type == fact_type }
          expand_reading_text(nil, reading.text, reading.role_sequence, player_by_role)
        end
        conjunction ? readings*conjunction : readings
      end

      # Expand this reading (or partial reading, during contraction)
      def expand_reading_text(step, text, role_sequence, player_by_role = {})
        if !player_by_role.empty? and !player_by_role.is_a?(Hash) || player_by_role.keys.detect{|k| !k.is_a?(ActiveFacts::Metamodel::Role)}
          raise "Need to change this call to expand_reading_text to pass a role->variable hash"
        end
        rrs = role_sequence.all_role_ref_in_order
	variable_by_role = {}
	if step
	  plays = step.all_play
	  variable_by_role = plays.inject({}) { |h, play| h[play.role] = play.variable; h }
	end
        trace :subscript, "expanding '#{text}' with #{role_sequence.describe}" do
          text.gsub(/\{(\d)\}/) do
            role_ref = rrs[$1.to_i]
            # REVISIT: We may need to use the step's role_refs to expand the role players here, not the reading's one (extra adjectives?)
            player = player_by_role[role_ref.role]
	    variable = variable_by_role[role_ref.role]

            play_name = variable && variable.role_name
	    raise hell if player && player.is_a?(ActiveFacts::Metamodel::EntityType) && player.fact_type && !variable
            subscripted_player(role_ref, player && player.subscript, play_name, variable && variable.value) +
              objectification_verbalisation(variable)
          end
        end
      end

      def subscripted_player role_ref, subscript = nil, play_name = nil, value = nil
        prr = @player_by_role_ref[role_ref]
        subscript ||= prr.subscript if prr
        trace :subscript, "Need to apply subscript #{subscript} to #{role_ref.role.object_type.name}" if subscript
        object_type = role_ref.role.object_type
        (play_name ||
          [
            role_ref.leading_adjective,
            object_type.name,
            role_ref.trailing_adjective
          ].compact*' '
        ) +
	  (value ? ' '+value.inspect : '') +
          (subscript ? "(#{subscript})" : '')
      end

      def expand_contracted_text(step, reading, role_refs = [])
        ' that ' +
          expand_reading_text(step, reading.text.sub(/\A\{\d\} /,''), reading.role_sequence, role_refs)
      end

      # Each query we wish to verbalise must first have had its players prepared.
      # Then, this prepares the query for verbalising:
      def prepare_query query
        @query = query
        return unless query

        @variables = query.all_variable.to_a.sort_by(&:ordinal)

        @steps = @variables.map(&:all_step).flatten.uniq
        @steps_by_variable = @variables.
          inject({}) do |h, var|
            var.all_step.each{|step| (h[var] ||= []) << step}
            h
          end
      end

      # De-index this step now that we've processed it:
      def step_completed(step)
        @steps.delete(step)

	step.all_play.each do |play|
	  var = play.variable
          steps = @steps_by_variable[var]
          steps.delete(step)
	  @steps_by_variable.delete(var) if steps.empty?
        end
      end

      def choose_step(next_var)
        next_steps = @steps_by_variable[next_var]

        # We need to emit each objectification before mentioning an object that plays a role in one, if possible
        # so that we don't wind up with an objectification as the only way to mention its name.

        # If we don't have a next_var against which we can contract,
        # so just use any step involving this node, or just any step.
        if next_steps
          if next_step = next_steps.detect { |ns| !ns.is_objectification_step }
            trace :query, "Chose new non-objectification step: #{next_step.describe}"
            return next_step
          end
        end

        if next_step = @steps.detect { |ns| !ns.is_objectification_step }
          trace :query, "Chose random non-objectification step: #{next_step.describe}"
          return next_step
        end

        next_step = @steps[0]
        if next_step
          trace :query, "Chose new random step from #{steps.size}: #{next_step.describe}"
          if next_step.is_objectification_step
            # if this objectification plays any roles (other than its FT roles) in remaining steps, use one of those first:
            fact_type = next_step.fact_type.implying_role.fact_type
            jn = [next_step.input_play.variable, next_step.output_play.variable].detect{|jn| jn.object_type == fact_type.entity_type}
            sr = @steps_by_variable[jn].reject{|t| r = t.fact_type.implying_role and r.fact_type == fact_type}
            next_step = sr[0] if sr.size > 0 
          end
          return next_step
        end
        raise "Internal error: There are more steps here, but we failed to choose one"
      end

      # The step we just emitted (using the reading given) is contractable iff
      # the reading has the next_var's role player as the final text
      def node_contractable_against_reading(next_var, reading)
        reading &&
          # Find whether last role has no following text, and its ordinal
        (reading.text =~ /\{([0-9])\}$/) &&
          # This reading's RoleRef for that role:
        (role_ref = reading.role_sequence.all_role_ref_in_order[$1.to_i]) &&
          # was that RoleRef for the upcoming node?
        role_ref.role.object_type == next_var.object_type
      end

      def reading_starts_with_node(reading, next_var)
        reading.text =~ /^\{([0-9])\}/ and
          role_ref = reading.role_sequence.all_role_ref.detect{|rr| rr.ordinal == $1.to_i} and
          role_ref.role.object_type == next_var.object_type
      end

      # The last reading we emitted ended with the object type name for next_var.
      # Choose a step and a reading that can be contracted against that name
      def contractable_step(next_steps, next_var)
        next_reading = nil
        next_step =
          next_steps.detect do |js|
            next false if js.is_objectification_step or js.is_disallowed
            # If we find a reading here, it can be contracted against the previous one
            next_reading =
              js.fact_type.all_reading_by_ordinal.detect do |reading|
                # This step is contractable iff the FactType has a reading that starts with the role of next_var (no preceding text)
                reading_starts_with_node(reading, next_var)
              end
            next_reading
          end
        trace :query, "#{next_reading ? "'"+next_reading.expand+"'" : "No reading"} contracts against last node '#{next_var.object_type.name}'"
        return [next_step, next_reading]
      end

      def objectification_verbalisation(variable)
	return '' unless variable
	raise "Not fully re-implemented, should pass the variable instead of #{variable.inspect}" unless variable.is_a?(ActiveFacts::Metamodel::Variable)
        objectified_node = nil
	object_type = variable.object_type
        return '' unless object_type.is_a?(Metamodel::EntityType) # Not a entity type
	return '' unless object_type.fact_type			  # Not objectified

	objectification_step = variable.step
	return '' unless objectification_step

        steps = [objectification_step]
        step_completed(objectification_step)

=begin
        while other_step =
          @steps.
            detect{|step|
              step.is_objectification_step and
                step.input_play.variable.object_type == object_type || step.output_play.variable.object_type == object_type
            }
          steps << other_step
          trace :query, "Emitting objectification step allows deleting #{other_step.describe}"
          step_completed(other_step)
        end
=end

        # Find all references to roles in this objectified fact type which are relevant to the variables of these steps:
        player_by_role = {}
        steps.each do |step|
          step.all_play.to_a.map do |play|
            player_by_role[play.role] = @player_by_play[play]
          end
        end

        # role_refs = steps.map{|step| [step.input_play.variable, step.output_play.variable].map{|jn| jn.all_role_ref.detect{|rr| rr.role.fact_type == object_type.fact_type}}}.flatten.compact.uniq

        reading = object_type.fact_type.preferred_reading
        " (in which #{expand_reading_text(objectification_step, reading.text, reading.role_sequence, player_by_role)})" 
      end

      def elided_objectification(next_step, fact_type, last_is_contractable, next_var)
        if last_is_contractable
          # Choose a reading that's contractable against the previous step, if possible
          reading = fact_type.all_reading_by_ordinal.
            detect do |reading|
	      # Only contract a negative reading if we want one
	      (!next_step.is_disallowed || !reading.is_negative == !next_step.is_disallowed) and
		reading_starts_with_node(reading, next_var)
            end
        end
        last_is_contractable = false unless reading
        reading ||= fact_type.preferred_reading(next_step.is_disallowed) || fact_type.preferred_reading

        # Find which role occurs last in the reading, and which Variable is attached
        reading.text =~ /\{(\d)\}[^{]*\Z/
        last_role_ref = reading.role_sequence.all_role_ref_in_order[$1.to_i]
        exit_node = @variables.detect{|jn| jn.all_play.detect{|play| play.role == last_role_ref.role}}
        exit_step = nil

	trace :query, "Stepping over an objectification to #{exit_node.object_type.name} requires eliding the other implied steps" do
	  count = 0
	  while other_step =
	    @steps.
	      detect{|js|
		trace :query, "Considering step '#{js.fact_type.default_reading}'"
		next unless js.is_objectification_step

		# REVISIT: This test is too weak: We need to ensure that the same variables are involved, not just the same object types:
		next unless js.input_play.variable.object_type == fact_type.entity_type || js.output_play.variable.object_type == fact_type.entity_type
		exit_step = js if js.output_play.variable == exit_node
		true
	      }
	    trace :query, "Emitting objectified FT allows deleting #{other_step.describe}"
	    step_completed(other_step)
  #          raise "The objectification of '#{fact_type.default_reading}' should not cause the deletion of more than #{fact_type.all_role.size} other steps" if (count += 1) > fact_type.all_role.size
	  end
	end

	[ reading, exit_step ? exit_step.input_play.variable : exit_node, exit_step, last_is_contractable]
      end

      def verbalise_query query
        prepare_query query
        readings = ''
        next_var = @role_refs[0].play.variable   # Choose a place to start
        last_is_contractable = false

        trace :query, "Verbalising query" do
	  if trace(:query)
	    trace :query, "variables:" do
	      @variables.each do |var|
		trace :query, var.describe
	      end
	    end
	    trace :query, "steps:" do
	      @steps.each do |step|
		trace :query, step.describe
	      end
	    end
	  end

          until @steps.empty?
            next_reading = nil
            # Choose amongst all remaining steps we can take from the next node, if any
            next_steps = @steps_by_variable[next_var]
            trace :query, "Next Steps from #{next_var.describe} are #{(next_steps||[]).map{|js| js.describe }.inspect}"

            # See if we can find a next step that contracts against the last (if any):
            next_step = nil
            if last_is_contractable && next_steps
              next_step, next_reading = *contractable_step(next_steps, next_var)
                end

            if next_step
              trace :query, "Chose #{next_step.describe} because it's contractable against last node #{next_var.object_type.name} using #{next_reading.expand}"

              player_by_role =
                next_step.all_play.inject({}) {|h, play| h[play.role] = @player_by_play[play]; h }
	      raise "REVISIT: Needed a negated reading here" if !next_reading.is_negative != !next_step.is_disallowed
	      raise "REVISIT: Need to emit 'maybe' here" if next_step.is_optional
              readings += expand_contracted_text(next_step, next_reading, player_by_role)
              step_completed(next_step)
            else
              next_step = choose_step(next_var) if !next_step

              player_by_role =
                next_step.all_play.inject({}) {|h, play| h[play.role] = @player_by_play[play]; h }

              if next_step.is_unary_step
                # Objectified unaries get emitted as unaries, not as objectifications:
                role = next_step.input_play.role
                role = role.fact_type.implying_role if role.fact_type.is_a?(LinkFactType)
		next_reading = role.fact_type.preferred_reading(next_step.is_disallowed) || role.fact_type.preferred_reading
                readings += " and " unless readings.empty?
		readings += "it is not the case that " if !next_step.is_disallowed != !next_reading.is_negative
		raise "REVISIT: Need to emit 'maybe' here" if next_step.is_optional
                readings += expand_reading_text(next_step, next_reading.text, next_reading.role_sequence, player_by_role)
                step_completed(next_step)
              elsif next_step.is_objectification_step
                fact_type = next_step.fact_type.implying_role.fact_type

                # This objectification step is over an implicit fact type, so player_by_role won't have all the players
                # Add the players of other roles associated with steps from this objectified player.
                objectified_node = next_step.input_play.variable
                raise "Assumption violated that the objectification is the input play" unless objectified_node.object_type.fact_type
                objectified_node.all_step.map do |other_step|
		  other_step.all_play.map do |play|
                    player_by_role[play.role] = @player_by_play[play]
                  end
                end

                if last_is_contractable and next_var.object_type.is_a?(EntityType) and next_var.object_type.fact_type == fact_type
                  # The last reading we emitted ended with the name of the objectification of this fact type, so we can contract the objectification
                  # REVISIT: Do we need to use player_by_role here (if this objectification is traversed twice and so is subscripted)
                  readings += objectification_verbalisation(fact_type.entity_type)
                else
                  # This objectified fact type does not need to be made explicit.
		  negation = next_step.is_disallowed
                  next_reading, next_var, next_step, last_is_contractable =
                    *elided_objectification(next_step, fact_type, last_is_contractable, next_var)
                  if last_is_contractable
		    raise "REVISIT: Need to emit 'maybe' here" if next_step and next_step.is_optional
                    readings += expand_contracted_text(next_step, next_reading, player_by_role)
                  else
                    readings += " and " unless readings.empty?
		    readings += "it is not the case that " if !!negation != !!next_reading.is_negative
		    raise "REVISIT: Need to emit 'maybe' here" if next_step and next_step.is_optional
                    readings += expand_reading_text(next_step, next_reading.text, next_reading.role_sequence, player_by_role)
                  end
                  # No need to continue if we just deleted the last step
                  break if @steps.empty?

                end
              else
                fact_type = next_step.fact_type
                # Prefer a reading that starts with the player of next_var
                next_reading = fact_type.all_reading_by_ordinal.
                  detect do |reading|
		    (!next_step.is_disallowed || !reading.is_negative == !next_step.is_disallowed) and
		      reading_starts_with_node(reading, next_var)
                  end || fact_type.preferred_reading(next_step.is_disallowed)
                # REVISIT: If this step and reading has role references with adjectives, we need to expand using those
                readings += " and " unless readings.empty?
		readings += "it is not the case that " if !next_step.is_disallowed != !next_reading.is_negative
		raise "REVISIT: Need to emit 'maybe' here" if next_step and next_step.is_optional
                readings += expand_reading_text(next_step, next_reading.text, next_reading.role_sequence, player_by_role)
                step_completed(next_step)
              end
            end

	    if next_step
	      # Continue from this step with the node having the most steps remaining
	      input_steps = @steps_by_variable[input_var = next_step.input_play.variable] || []
	      output_play = next_step.output_plays.last
	      output_steps = (output_play && (output_var = output_play.variable) && @steps_by_variable[output_var]) || []

	      next_var = input_steps.size > output_steps.size ? input_var : output_var
	      # Prepare for possible contraction following:
	      last_is_contractable = next_reading && node_contractable_against_reading(next_var, next_reading)
	    else
	      # This shouldn't happen, but an elided objectification that had missing steps can cause it. Survive:
	      next_var = (steps[0].input_play || steps[0].output_plays.last).variable
	      last_is_contractable = false
	    end

          end
        end
        readings
      end
    end

  end
end
