module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class Clause
        attr_reader :phrases
        attr_accessor :qualifiers, :context_note
        attr_accessor :certainty        # nil, true, false -> maybe, definitely, not
        attr_accessor :conjunction      # one of {nil, 'and', ',', 'or', 'where'}
        attr_accessor :fact_type
        attr_reader :reading, :role_sequence    # These are the Metamodel objects
        attr_reader :side_effects       # How to adjust the phrases if this fact_type match is accepted
        attr_accessor :fact             # When binding fact instances the fact goes here
        attr_accessor :objectified_as   # The Reference which objectified this fact type

        def initialize phrases, qualifiers = [], context_note = nil
          @phrases = phrases
          refs.each { |ref| ref.clause = self }
          @certainty = true
          @qualifiers = qualifiers
          @context_note = context_note
        end

        def refs
          @phrases.select{|r| r.respond_to?(:player)}
        end

        # A clause that contains only the name of a ObjectType and no literal or reading text
        # refers only to the existence of that ObjectType (as opposed to an instance of the object_type).
        def is_existential_type
          @phrases.size == 1 and
            @phrases[0].is_a?(Reference) and
            !@phrases[0].literal
        end

        def display
          to_s
        end

        def inspect
          to_s
        end

        def to_s phrases = nil
          phrases ||= @phrases
          "#{
            @qualifiers && @qualifiers.size > 0 ? @qualifiers.sort.inspect+' ' : nil
          }#{
            case @certainty
            when nil; 'maybe '
            when false; 'negated '
            # else 'definitely '
            end
          }#{
	    (
	      phrases.map do |phrase|
		case phrase
		when String
		  '"' + phrase.to_s + '"'
		when Reference
		  phrase.to_s +
		    if phrase.nested_clauses
		      ' (in which ' +
			phrase.nested_clauses.map do |c|
			  ((j = c.conjunction) ? j+' ' : '') +
			    c.to_s
			end*' ' +
		      ')'
		    else
		      ''
		    end
		when Operation
		  phrase.inspect
		when Literal
		  phrase.inspect
		#when FunctionCallChain		# REVISIT: Add something here when I re-add functions
		#  phrase.inspect
		else
		  raise "Unexpected phrase type in clause: #{phrase.class}"
		end
	      end * ' '
	    ).gsub(/" "/, ' ')
          }#{
            @context_note && ' ' + @context_note.inspect
          }"
        end

        def identify_players_with_role_name context
          refs.each do |ref|
            ref.identify_players_with_role_name(context)
          end
        end

        def identify_other_players context
          refs.each do |ref|
            ref.identify_other_players(context)
            # Include players in nested clauses, if any
            ref.nested_clauses.each{|clause| clause.identify_other_players(context)} if ref.nested_clauses
          end
        end

        def includes_literals
          refs.detect{|ref| ref.literal || (ja = ref.nested_clauses and ja.detect{|jr| jr.includes_literals })}
        end

        def is_equality_comparison
          false
        end

        def bind context
          role_names = refs.map{ |ref| ref.role_name }.compact

          # Check uniqueness of role names and subscripts within this clause:
          role_names.each do |rn|
            next if role_names.select{|rn2| rn2 == rn}.size == 1
            raise "Duplicate role #{rn.is_a?(Integer) ? "subscript" : "name"} '#{rn}' in clause"
          end

          refs.each do |ref|
            ref.bind context
          end
        end

	# This method is used in matching unary fact types in entity identification
	# It disregards literals, which are not allowed in this context.
        def phrases_match(phrases)
          @phrases.zip(phrases).each do |mine, theirs|
            return false if mine.is_a?(Reference) != theirs.is_a?(Reference)
            if mine.is_a?(Reference)
              return false unless mine.key == theirs.key
            else
              return false unless mine == theirs
            end
          end
          true
        end

        # This method chooses the existing fact type which matches most closely.
        # It returns nil if there is none, or a ClauseMatchSideEffects object if matched.
        #
        # As this match may not necessarily be used (depending on the side effects),
        # no change is made to this Clause object - those will be done later.
        #
        def match_existing_fact_type context, options = {}
          raise "Cannot match a clause that contains no object types" if refs.size == 0
          raise "Internal error, clause already matched, should not match again" if @fact_type

	  if is_naked_object_type
	    ref = refs[0]	# "There can be only one"
	    return true unless ref.nested_clauses
	    ref.nested_clauses.each do |nested|
	      ft = nested.match_existing_fact_type(context)
	      raise "Unrecognised fact type #{nested.display} nested under #{inspect}" unless ft
	      if (ft.entity_type == ref.player)
		ref.objectification_of = ft
		nested.objectified_as = ref
	      end
	    end
	    raise "#{ref.inspect} contains objectification steps that do not objectify it" unless ref.objectification_of
	    return true
	  end

          # If we fail to match, try a left contraction (or save this for a subsequent left contraction):
          left_contract_this_onto = context.left_contractable_clause
          new_conjunction = (conjunction == nil || conjunction == ',')
          changed_conjunction = (lcc = context.left_contraction_conjunction) && lcc != conjunction
          if context.left_contraction_allowed && (new_conjunction || changed_conjunction)
            # Conjunctions are that/who, where, comparison-operator, ','
            trace :matching, "A left contraction will be against #{self.inspect}, conjunction is #{conjunction.inspect}"
            context.left_contractable_clause = self
            left_contract_this_onto = nil # Can't left-contract this clause
          end
          context.left_contraction_conjunction = new_conjunction ? nil : @conjunction

          phrases = @phrases
          vrs = []+refs

          # A left contraction is where the first player in the previous clause continues as first player of this clause
          contracted_left = false
          can_contract_right = false
          left_insertion = nil
          right_insertion = nil
          supposed_roles = []   # Arrange to unbind incorrect references supposed due to contraction
          contract_left = proc do
            contracted_from = left_contract_this_onto.refs[0]
            contraction_player = contracted_from.player
            contracted_role = Reference.new(contraction_player.name)
            supposed_roles << contracted_role
            left_insertion = contracted_role.inspect+' '
            contracted_role.player = contracted_from.player
            contracted_role.role_name = contracted_from.role_name
            contracted_role.bind(context)
            vrs.unshift contracted_role
            contracted_left = true
            phrases = [contracted_role]+phrases
            trace :matching, "Failed to match #{inspect}. Trying again using left contraction onto #{contraction_player.name}"
          end

          contract_right = proc do
            contracted_from = left_contract_this_onto.refs[-1]
            contraction_player = contracted_from.player
            contracted_role = Reference.new(contraction_player.name)
            supposed_roles << contracted_role
            right_insertion = ' '+contracted_role.inspect
            contracted_role.player = contracted_from.player
            contracted_role.role_name = contracted_from.role_name
            contracted_role.bind(context)
            vrs.push contracted_role
            phrases = phrases+[contracted_role]
            trace :matching, "Failed to match #{inspect}. Trying again using right contraction onto #{contraction_player.name}"
          end

          begin
            players = vrs.map{|vr| vr.player}

            if players.size == 0
              can_contract_right = left_contract_this_onto.refs.size == 2
              contract_left.call
              redo
            end

            raise "Must identify players before matching fact types" if players.include? nil
            raise "A fact type must involve at least one object type, but there are none in '#{inspect}'" if players.size == 0 && !left_contract_this_onto

            player_names = players.map{|p| p.name}

            trace :matching, "Looking for existing #{players.size}-ary fact types matching '#{inspect}'" do
              trace :matching, "Players are '#{player_names.inspect}'"

              # Match existing fact types in nested clauses first:
              # (not for contractions) REVISIT: Why not?
              if !contracted_left
                vrs.each do |ref|
                  next if ref.is_a?(Operation)
                  next unless steps = ref.nested_clauses and !steps.empty?
                  ref.nested_clauses.each do |nested|
                    ft = nested.match_existing_fact_type(context)
                    raise "Unrecognised fact type #{nested.display}" unless ft
                    if (ft && ft.entity_type == ref.player)
                      ref.objectification_of = ft
                      nested.objectified_as = ref
                    end
                  end
                  raise "#{ref.inspect} contains objectification steps that do not objectify it" unless ref.objectification_of
                end
              end

              # For each role player, find the compatible types (the set of all subtypes and supertypes).
              # For a player that's an objectification, we don't allow implicit supertype steps
              player_related_types =
                vrs.zip(players).map do |ref, player|
                  disallow_subtyping = ref && ref.objectification_of || options[:exact_type]
                  ((disallow_subtyping ? [] : player.supertypes_transitive) +
                    player.subtypes_transitive).uniq
                end

              trace :matching, "Players must match '#{player_related_types.map{|pa| pa.map{|p|p.name}}.inspect}'"

              start_obj = player_related_types[0] || [left_contract_this_onto.refs[-1].player]
              # The candidate fact types have the right number of role players of related types.
              # If any role is played by a supertype or subtype of the required type, there's an implicit subtyping steps
              # REVISIT: A double contraction results in player_related_types being empty here
              candidate_fact_types =
                start_obj.map do |related_type|
                  related_type.all_role.select do |role|
                    # next if role.fact_type.all_reading.size == 0
                    next if role.fact_type.is_a?(ActiveFacts::Metamodel::LinkFactType)
                    next if role.fact_type.all_role.size != players.size      # Wrong number of players

		    compatible_readings = role.fact_type.compatible_readings(player_related_types)
		    next unless compatible_readings.size > 0
		    trace :matching_fails, "These readings are compatible: #{compatible_readings.map(&:expand).inspect}"
                    true
                  end.
                    map{ |role| role.fact_type}
                end.flatten.uniq

              # If there is more than one possible exact match (same adjectives) with different subyping, the implicit query is ambiguous and is not allowed

              trace :matching, "Looking amongst #{candidate_fact_types.size} existing fact types for one matching #{left_insertion}'#{inspect}'#{right_insertion}" do
                matches = {}
                candidate_fact_types.map do |fact_type|
                  fact_type.all_reading.map do |reading|
                    next unless side_effects = clause_matches(fact_type, reading, phrases)
                    matches[reading] = side_effects if side_effects
                  end
                end

                # REVISIT: Side effects that leave extra adjectives should only be allowed if the
                # same extra adjectives exist in some other clause in the same declaration.
                # The extra adjectives are then necessary to associate the two role players
                # when consumed adjectives were required to bind to the underlying fact types.
                # This requires the final decision on fact type matching to be postponed until
                # the whole declaration has been processed and the extra adjectives can be matched.

                best_matches = matches.keys.sort_by{|match|
                  # Between equivalents, prefer the one without steps on the first role
                  (m = matches[match]).cost*2 + ((!(e = m.role_side_effects[0]) || e.cost) == 0 ? 0 : 1)
                }
                trace :matching_fails, "Found #{matches.size} valid matches#{matches.size > 0 ? ', best is '+best_matches[0].expand : ''}"

                if matches.size > 1
                  first = matches[best_matches[0]]
                  cost = first.cost
                  equal_best = matches.select{|k,m| m.cost == cost}

                  if equal_best.size > 1 and equal_best.detect{|k,m| !m.fact_type.is_a?(Metamodel::TypeInheritance)}
                    # Complain if there's more than one equivalent cost match (unless all are TypeInheritance):
                    raise "#{@phrases.inspect} could match any of the following:\n\t"+
                      best_matches.map { |reading| reading.expand + " with " + matches[reading].describe } * "\n\t"
                  end
                end

                if matches.size >= 1
                  @reading = best_matches[0]
                  @side_effects = matches[@reading]
                  @fact_type = @side_effects.fact_type
                  trace :matching, "Matched '#{@fact_type.default_reading}'"
                  @phrases = phrases
                  apply_side_effects(context, @side_effects)
                  return @fact_type
                end

              end
              trace :matching, "No fact type matched, candidates were '#{candidate_fact_types.map{|ft| ft.default_reading}*"', '"}'"
            end
            if left_contract_this_onto
              if !contracted_left
                contract_left.call
                redo
              elsif can_contract_right
                contract_right.call
                can_contract_right = false
                redo
              end
            end
          end until true  # Once through, unless we hit a redo
          supposed_roles.each do |role|
            role.unbind context
          end
          @fact_type = nil
        end

        # The Reading passed has the same players as this Clause. Does it match?
        # Twisty curves. This is a complex bit of code!
        # Find whether the phrases of this clause match the fact type reading,
        # which may require absorbing unmarked adjectives.
        #
        # If it does match, make the required changes and set @ref to the matching role ref.
        # Adjectives that were used to match are removed (and leaving any additional adjectives intact).
        #
        # Approach:
        #   Match each element where element means:
        #     a role player phrase (perhaps with adjectives)
        #       Our phrase must either be
        #         a player that contains the same adjectives as in the reading.
        #         a word (unmarked leading adjective) that introduces a sequence
        #           of adjectives leading up to a matching player
        #       trailing adjectives, both marked and unmarked, are absorbed too.
        #     a word that matches the reading's
        #
        def clause_matches(fact_type, reading, phrases = @phrases)
          implicitly_negated = false
          side_effects = []    # An array of items for each role, describing any side-effects of the match.
          intervening_words = nil
          residual_adjectives = false

          # The following form of negation is, e.g., where "Person was invited to no Party",
          # as opposed to where "Person was not invited to that Party". Quite different meaning,
          # because a free Party variable is required, but the join step is still disallowed.
          # REVISIT: I'll create the free variable when I implement some/that binding
          # REVISIT: the verbaliser will need to know about a negated step to a free variable
          implicitly_negated = true if refs.detect{|ref| q = ref.quantifier and q.is_zero }

          trace :matching_fails, "Does '#{phrases.inspect}' match '#{reading.expand}'" do
            phrase_num = 0
            reading_parts = reading.text.split(/\s+/)
            reading_parts.each do |element|
              phrase = phrases[phrase_num]
              if phrase == 'not'
                raise "Stop playing games with your double negatives: #{phrases.inspect}" if implicitly_negated
                trace :matching, "Negation detected"
                implicitly_negated = true
                phrase = phrases[phrase_num += 1]
              end
              if element !~ /\{(\d+)\}/
                # Just a word; it must match
                unless phrase == element
                  trace :matching_fails, "Mismatched ordinary word #{phrases[phrase_num].inspect} (wanted #{element})"
                  return nil
                end
                phrase_num += 1
                next
              else
                role_ref = reading.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}[$1.to_i]
              end

              player = role_ref.role.object_type

              # Figure out what's next in this phrase (the next player and the words leading up to it)
              next_player_phrase = nil
              intervening_words = []
              while (phrase = phrases[phrase_num])
                phrase_num += 1
                if phrase.respond_to?(:player)
                  next_player_phrase = phrase
                  next_player_phrase_num = phrase_num-1
                  break
                else
                  intervening_words << phrase
                end
              end
              return nil unless next_player_phrase  # reading has more players than we do.
              next_player = next_player_phrase.player

              # The next player must match:
              common_supertype = nil
              if next_player != player
                # This relies on the supertypes being in breadth-first order:
                common_supertype = (next_player.supertypes_transitive & player.supertypes_transitive)[0]
                if !common_supertype
                  trace :matching_fails, "Reading discounted because next player #{player.name} doesn't match #{next_player.name}"
                  return nil
                end

                trace :matching_fails, "Subtype step is required between #{player.name} and #{next_player_phrase.player.name} via common supertype #{common_supertype.name}"
              else
                if !next_player_phrase
                  next    # Contraction succeeded so far
                end
              end

              # It's the right player. Do the adjectives match? This must include the intervening_words, if any.

              role_has_residual_adjectives = false
              absorbed_precursors = 0
              if la = role_ref.leading_adjective and !la.empty?
                # The leading adjectives must match, one way or another
                la = la.split(/\s+/)
		if (la[0, intervening_words.size] == intervening_words)		# Exact match
		  iw = intervening_words
		else
		  # We may have hyphenated adjectives. Break them up to check:
		  iw = intervening_words.map{|w| w.split(/-/)}.flatten
		  return nil unless la[0,iw.size] == iw
		end

                # Any intervening_words matched, see what remains
                la.slice!(0, iw.size)

                # If there were intervening_words, the remaining reading adjectives must match the phrase's leading_adjective exactly.
                phrase_la = (next_player_phrase.leading_adjective||'').split(/\s+/)
                return nil if !iw.empty? && la != phrase_la
                # If not, the phrase's leading_adjectives must *end* with the reading's
                return nil if phrase_la[-la.size..-1] != la
                role_has_residual_adjectives = true if phrase_la.size > la.size
                # The leading adjectives and the player matched! Check the trailing adjectives.
                absorbed_precursors = intervening_words.size
                intervening_words = []
              elsif intervening_words.size > 0 || next_player_phrase.leading_adjective
                role_has_residual_adjectives = true
              end

              absorbed_followers = 0
              if ta = role_ref.trailing_adjective and !ta.empty?
                ta = ta.split(/\s+/)  # These are the trailing adjectives to match

                phrase_ta = (next_player_phrase.trailing_adjective||'').split(/\s+/)
                i = 0   # Pad the phrases up to the size of the trailing_adjectives
                while phrase_ta.size < ta.size
                  break unless (word = phrases[phrase_num+i]).is_a?(String)
                  phrase_ta << word
                  i += 1
                end
                # ta is the adjectives in the fact type being matched
                # phrase_ta is the explicit adjectives augmented with implicit ones to the same size
                return nil if ta != phrase_ta[0,ta.size]
                role_has_residual_adjectives = true if phrase_ta.size > ta.size
                absorbed_followers = i
                phrase_num += i # Skip following words that were consumed as trailing adjectives
              elsif next_player_phrase.trailing_adjective
                role_has_residual_adjectives = true
              end

              # REVISIT: I'm not even sure I should be caring about role names here.
              # Role names are on roles, and are only useful within the fact type definition.
              # At some point, we need to worry about role names on clauses within fact type derivations,
              # which means they'll move to the Role Ref class; but even then they only match within the
              # definition that creates that Role Ref.
=begin
              if a = (!phrase.role_name.is_a?(Integer) && phrase.role_name) and
                  e = role_ref.role.role_name and
                  a != e
                trace :matching, "Role names #{e.inspect} for #{player.name} and #{a.inspect} for #{next_player_phrase.player.name} don't match"
                return nil
              end
=end

              residual_adjectives ||= role_has_residual_adjectives
              if residual_adjectives && next_player_phrase.binding.refs.size == 1
                # This makes matching order-dependent, because there may be no "other purpose"
                # until another reading has been matched and the roles rebound.
                trace :matching_fails, "Residual adjectives have no other purpose, so this match fails"
                return nil
              end

              # The phrases matched this reading's next role_ref, save data to apply the side-effects:
              side_effects << ClauseMatchSideEffect.new(next_player_phrase, role_ref, next_player_phrase_num, absorbed_precursors, absorbed_followers, common_supertype, role_has_residual_adjectives)
            end

            if phrase_num != phrases.size || !intervening_words.empty?
              trace :matching_fails, "Extra words #{(intervening_words + phrases[phrase_num..-1]).inspect}"
              return nil
            end

            if fact_type.is_a?(Metamodel::TypeInheritance)
              # There may be only one subtyping step on a TypeInheritance fact type.
              ti_steps = side_effects.select{|side_effect| side_effect.common_supertype}
              if ti_steps.size > 1   # Not allowed
                trace :matching_fails, "Can't have more than one subtyping step on a TypeInheritance fact type"
                return nil
              end

              if ti = ti_steps[0]
                # The Type Inheritance step must continue in the same direction as this reading.
                allowed = fact_type.supertype == ti.role_ref.role.object_type ?
                    fact_type.subtype.supertypes_transitive :
                    fact_type.supertype.subtypes_transitive
                if !allowed.include?(ti.common_supertype)
                  trace :matching_fails, "Implicit subtyping step extends in the wrong direction"
                  return nil
                end
              end
            end

            trace :matching, "Matched reading '#{reading.expand}' (with #{
                  side_effects.map{|side_effect|
                    side_effect.absorbed_precursors+side_effect.absorbed_followers + (side_effect.common_supertype ? 1 : 0)
                  }.inspect
                } side effects)#{residual_adjectives ? ' and residual adjectives' : ''}"
          end
          # There will be one side_effects for each role player
          @certainty = !@certainty if implicitly_negated
          @certainty = !@certainty if reading.is_negative
          ClauseMatchSideEffects.new(fact_type, self, residual_adjectives, side_effects, implicitly_negated)
        end

        def apply_side_effects(context, side_effects)
          @applied_side_effects = side_effects
          # Enact the side-effects of this match (delete the consumed adjectives):
          # Since this deletes words from the phrases, we do it in reverse order.
          trace :matching, "Apply side-effects" do
            side_effects.apply_all do |side_effect|
              phrase = side_effect.phrase

              # We re-use the role_ref if possible (no extra adjectives were used, no rolename or step, etc).
              trace :matching, "side-effect means binding #{phrase.inspect} matches role ref #{side_effect.role_ref.role.object_type.name}"
              phrase.role_ref = side_effect.role_ref

              changed = false

              # Where this phrase has leading or trailing adjectives that are in excess of those of
              # the role_ref, those must be local, and we'll need to extract them.

              if rra = side_effect.role_ref.trailing_adjective
                trace :matching, "Deleting matched trailing adjective '#{rra}'#{side_effect.absorbed_followers>0 ? " in #{side_effect.absorbed_followers} followers" : ""}, cost is #{side_effect.cost}"
                side_effect.cancel_cost side_effect.absorbed_followers

                # These adjective(s) matched either an adjective here, or a follower word, or both.
                if a = phrase.trailing_adjective
                  if a.size >= rra.size
                    a = a[rra.size+1..-1]
                    phrase.trailing_adjective = a == '' ? nil : a
                    changed = true
                  end
                elsif side_effect.absorbed_followers > 0
                  # The following statement is incorrect. The absorbed adjective is what caused the match.
                  # This phrase is absorbing non-hyphenated adjective(s), which changes its binding
                  # phrase.trailing_adjective =
                  @phrases.slice!(side_effect.num+1, side_effect.absorbed_followers)*' '
                  changed = true
                end
              end

              if rra = side_effect.role_ref.leading_adjective
                trace :matching, "Deleting matched leading adjective '#{rra}'#{side_effect.absorbed_precursors>0 ? " in #{side_effect.absorbed_precursors} precursors" : ""}, cost is #{side_effect.cost}"
                side_effect.cancel_cost side_effect.absorbed_precursors

                # These adjective(s) matched either an adjective here, or a precursor word, or both.
                if a = phrase.leading_adjective
                  if a.size >= rra.size
                    a = a[0...-rra.size]
                    phrase.leading_adjective = a == '' ? nil : a
                    changed = true
                  end
                elsif side_effect.absorbed_precursors > 0
                  # The following statement is incorrect. The absorbed adjective is what caused the match.
                  # This phrase is absorbing non-hyphenated adjective(s), which changes its binding
                  #phrase.leading_adjective =
                  @phrases.slice!(side_effect.num-side_effect.absorbed_precursors, side_effect.absorbed_precursors)*' '
                  changed = true
                end
              end
              if changed
                phrase.rebind context
              end

            end
          end
        end

        # Make a new fact type with roles for this clause.
        # Don't assign @fact_type; that will happen when the reading is added
        def make_fact_type vocabulary
          fact_type = vocabulary.constellation.FactType(:new)
          trace :matching, "Making new fact type for #{@phrases.inspect}" do
            @phrases.each do |phrase|
              next unless phrase.respond_to?(:player)
              phrase.role = vocabulary.constellation.Role(fact_type, fact_type.all_role.size, :object_type => phrase.player, :concept => :new)
              phrase.role.role_name = phrase.role_name if phrase.role_name && phrase.role_name.is_a?(String)
            end
          end
          fact_type
        end

        def make_reading vocabulary, fact_type
          @fact_type = fact_type
          constellation = vocabulary.constellation
          @role_sequence = constellation.RoleSequence(:new)
          reading_words = @phrases.clone
          index = 0
          trace :matching, "Making new reading for #{@phrases.inspect}" do
            reading_words.map! do |phrase|
              if phrase.respond_to?(:player)
                # phrase.role will be set if this reading was used to make_fact_type.
                # Otherwise we have to find the existing role via the Binding. This is pretty ugly.
                unless phrase.role
                  # Find another binding for this phrase which already has a role_ref to the same fact type:
                  ref = phrase.binding.refs.detect{|ref| ref.role_ref && ref.role_ref.role.fact_type == fact_type}
                  role_ref = ref.role_ref
                  phrase.role = role_ref.role
                end
                rr = constellation.RoleRef(@role_sequence, index, :role => phrase.role)
                phrase.role_ref = rr

                if la = phrase.leading_adjective
                  # If we have used one or more adjective to match an existing reading, that has already been removed.
                  rr.leading_adjective = la
                end
                if ta = phrase.trailing_adjective
                  rr.trailing_adjective = ta
                end

                if phrase.value_constraint
                  raise "The role #{rr.inspect} already has a value constraint" if rr.role.role_value_constraint
                  phrase.value_constraint.constellation = fact_type.constellation
                  rr.role.role_value_constraint = phrase.value_constraint.compile
                end

                index += 1
                "{#{index-1}}"
              else
                phrase
              end
            end
            if existing = @fact_type.all_reading.detect{|r|
                r.text == reading_words*' ' and
                  r.role_sequence.all_role_ref_in_order.map{|rr| rr.role.object_type} ==
                    role_sequence.all_role_ref_in_order.map{|rr| rr.role.object_type}
              }
              existing
              #raise "Reading '#{existing.expand}' already exists, so why are we creating a duplicate?"
            end
            r = constellation.Reading(@fact_type, @fact_type.all_reading.size, :role_sequence => @role_sequence, :text => reading_words*" ", :is_negative => (certainty == false))
            r
          end
        end

        # When we match an existing reading, we might have matched using additional adjectives.
        # These adjectives have been removed from the phrases. If there are any remaining adjectives,
        # we need to make a new RoleSequence, otherwise we can use the existing one.
        def adjust_for_match
          return unless @applied_side_effects
          new_role_sequence_needed = @applied_side_effects.residual_adjectives

          role_phrases = []
          reading_words = []
          new_role_sequence_needed = false
          @phrases.each do |phrase|
            if phrase.respond_to?(:player)
              role_phrases << phrase
              reading_words << "{#{phrase.role_ref.ordinal}}"
              if phrase.role_name != phrase.role_ref.role.role_name ||
                  phrase.leading_adjective ||
                  phrase.trailing_adjective
                trace :matching, "phrase in matched clause has residual adjectives or role name, so needs a new role_sequence" if @fact_type.all_reading.size > 0
                new_role_sequence_needed = true
              end
            else
              reading_words << phrase
              false
            end
          end

          trace :matching, "Clause '#{reading_words*' '}' #{new_role_sequence_needed ? 'requires' : 'does not require'} a new Role Sequence"

          constellation = @fact_type.constellation
          reading_text = reading_words*" "
          if new_role_sequence_needed
            @role_sequence = constellation.RoleSequence(:new)
            extra_adjectives = []
            role_phrases.each_with_index do |rp, i|
              role_ref = constellation.RoleRef(@role_sequence, i, :role => rp.role_ref.role)
              if a = rp.leading_adjective
                role_ref.leading_adjective = a
                extra_adjectives << a+"-"
              end
              if a = rp.trailing_adjective
                role_ref.trailing_adjective = a
                extra_adjectives << "-"+a
              end
              if (a = rp.role_name) && (e = rp.role_ref.role.role_name) && a != e
                raise "Can't create new reading '#{reading_text}' for '#{reading.expand}' with alternate role name #{a}"
                extra_adjectives << "(as #{a})"
              end
            end
            trace :matching, "Making new role sequence for new reading #{reading_text} due to #{extra_adjectives.inspect}"
          else
            # Use existing RoleSequence
            @role_sequence = role_phrases[0].role_ref.role_sequence
            if @role_sequence.all_reading.detect{|r| r.text == reading_text }
              trace :matching, "No need to re-create identical reading for #{reading_text}"
              return @role_sequence
            else
              trace :matching, "Using existing role sequence for new reading '#{reading_text}'"
            end
          end
          if @fact_type.all_reading.
            detect do |r|
              r.text == reading_text and
              r.role_sequence.all_role_ref_in_order.map{|rr| rr.role.object_type} ==
                @role_sequence.all_role_ref_in_order.map{|rr| rr.role.object_type}
            end
            # raise "Reading '#{@reading.expand}' already exists, so why are we creating a duplicate (with #{extra_adjectives.inspect})?"
          else
            constellation.Reading(@fact_type, @fact_type.all_reading.size, :role_sequence => @role_sequence, :text => reading_text, :is_negative => (certainty == false))
          end
          @role_sequence
        end

        def make_embedded_constraints vocabulary
          refs.each do |ref|
            next unless ref.quantifier
            # puts "Quantifier #{ref.inspect} not implemented as a presence constraint"
            ref.make_embedded_presence_constraint vocabulary
          end

          if @qualifiers && @qualifiers.size > 0
            # We shouldn't make a new ring constraint if there's already one over this ring.
            existing_rcs = 
              @role_sequence.all_role_ref.map{|rr| rr.role.all_ring_constraint.to_a }.flatten.uniq
            unless existing_rcs[0]
              rc = RingConstraint.new(@role_sequence, @qualifiers)
              rc.vocabulary = vocabulary
              rc.constellation = vocabulary.constellation
              rc.compile
            else
              # Ignore the fact that the ring might be of a different type.
            end

            # REVISIT: Check maybe and other qualifiers:
            trace :constraint, "Need to make constraints for #{@qualifiers.inspect}" if @qualifiers.size > 0 or @certainty != true
          end
        end

        def is_naked_object_type
          @phrases.size == 1 && refs.size == 1
        end

      end

      # An instance of ClauseMatchSideEffects is created when the compiler matches an existing fact type.
      # It captures the details that have to be adjusted for the match to be regarded a success.
      class ClauseMatchSideEffect
        attr_reader :phrase, :role_ref, :num, :absorbed_precursors, :absorbed_followers, :common_supertype, :residual_adjectives

        def initialize phrase, role_ref, num, absorbed_precursors, absorbed_followers, common_supertype, residual_adjectives
          @phrase = phrase
          @role_ref = role_ref
          @num = num
          @absorbed_precursors = absorbed_precursors
          @absorbed_followers = absorbed_followers
          @common_supertype = common_supertype
          @residual_adjectives = residual_adjectives
          @cancelled_cost = 0
          trace :matching_fails, "Saving side effects for #{@phrase.term}, absorbs #{@absorbed_precursors}/#{@absorbed_followers}#{@common_supertype ? ', step over supertype '+ @common_supertype.name : ''}" if @absorbed_precursors+@absorbed_followers+(@common_supertype ? 1 : 0) > 0
        end

        def cost
          absorbed_precursors + absorbed_followers + (common_supertype ? 1 : 0) - @cancelled_cost
        end

        def cancel_cost c
          @cancelled_cost += c
        end

        def to_s
          "#{@phrase.inspect} absorbs #{@absorbed_precursors||0}/#{@absorbed_followers||0} at #{@num}#{@common_supertype && ' super '+@common_supertype.name}#{@residual_adjectives ? ' with residual adjectives' : ''}"
        end
      end

      class ClauseMatchSideEffects
        attr_reader :residual_adjectives
        attr_reader :fact_type
        attr_reader :role_side_effects    # One array of values per Reference matched, in order
        attr_reader :negated
        attr_reader :optional

        def initialize fact_type, clause, residual_adjectives, role_side_effects, negated = false
          @fact_type = fact_type
          @clause = clause
          @residual_adjectives = residual_adjectives
          @role_side_effects = role_side_effects
          @negated = negated
        end

        def inspect
          'side-effects are [' +
            @role_side_effects.map{|r| r.to_s}*', ' +
            ']' +
            "#{@negated ? ' negated' : ''}" +
            "#{@residual_adjectives ? ' with residual adjectives' : ''}"
        end

        def apply_all &b
          @role_side_effects.reverse.each{ |role_side_effect| b.call(*role_side_effect) }
        end

        def cost
          c = 0
          @role_side_effects.each do |side_effect|
            c += side_effect.cost
          end
          c += 1 if @residual_adjectives
          c += 2 if @negated
          c
        end

        def describe
          actual_effects =
            @role_side_effects.map do |side_effect|
              ( [side_effect.common_supertype ? "supertype step over #{side_effect.common_supertype.name}" : nil] +
                [side_effect.absorbed_precursors > 0 ? "absorbs #{side_effect.absorbed_precursors} preceding words" : nil] +
                [side_effect.absorbed_followers > 0 ? "absorbs #{side_effect.absorbed_followers} following words" : nil] +
                [@negated ? 'implicitly negated' : nil]
              )
            end.flatten.compact*','
          actual_effects.empty? ? "no side effects" : actual_effects
        end
      end

      class Reference
        attr_reader :term, :quantifier, :function_call, :value_constraint, :literal, :nested_clauses
        attr_accessor :leading_adjective, :trailing_adjective, :role_name
        attr_accessor :player     # What ObjectType does the Binding denote
        attr_accessor :binding    # What Binding for that ObjectType
        attr_accessor :role       # Which Role of this ObjectType
        attr_accessor :role_ref   # Which RoleRef to that Role
        attr_accessor :clause     # The clause that this Reference is part of
        attr_accessor :objectification_of # If nested_clauses is set, this is the fact type it objectifies
        attr_reader :embedded_presence_constraint   # This refers to the ActiveFacts::Metamodel::PresenceConstraint

        def initialize term, leading_adjective = nil, trailing_adjective = nil, quantifier = nil, function_call = nil, role_name = nil, value_constraint = nil, literal = nil, nested_clauses = nil
          @term = term
          @leading_adjective = leading_adjective
          @trailing_adjective = trailing_adjective
          @quantifier = quantifier
          # @function_call = function_call # Not used or implemented
          @role_name = role_name
          @value_constraint = value_constraint
          @literal = literal
          @nested_clauses = nested_clauses
        end

        def inspect
          to_s
        end

        def to_s
          "{#{
            @quantifier && @quantifier.inspect+' '
          }#{
            @leading_adjective && @leading_adjective.sub(/ |$/,'- ').sub(/ *$/,' ')
          }#{
            @term
          }#{
            @trailing_adjective && ' '+@trailing_adjective.sub(/(.* |^)/, '\1-')
          }#{
            @role_name and @role_name.is_a?(Integer) ? "(#{@role_name})" : " (as #{@role_name})"
          }#{
            @literal && ' '+@literal.inspect
          }#{
            @value_constraint && ' '+@value_constraint.to_s
          }}"
        end

        def <=>(other)
          ( 4*(@term <=> other.term) +
            2*((@leading_adjective||'') <=> (other.leading_adjective||'')) +
            1*((@trailing_adjective||'') <=> (other.trailing_adjective||''))
          ) <=> 0
        end

        def includes_literals
          @nested_clauses && @nested_clauses.detect{|nested| nested.includes_literals}
        end

        # We create value types for the results of arithmetic expressions, and they get assigned here:
        def player=(player)
          @player = player
        end

        def identify_players_with_role_name(context)
          identify_player(context) if role_name
          # Include players in nested clauses, if any
          nested_clauses.each{|clause| clause.identify_players_with_role_name(context)} if nested_clauses
        end

        def identify_other_players context
          identify_player context
        end

        def identify_player context
          @player || begin
            @player = context.object_type @term
            raise "ObjectType #{@term} unrecognised" unless @player
            context.player_by_role_name[@role_name] = player if @role_name
            @player
          end
        end

        def uses_role_name?
          @term != @player.name
        end

        def key
          if @role_name
            key = [@term, @role_name]         # Defines a role name
          elsif uses_role_name?
            key = [@player.name, @term]       # Uses a role name
          else
            l = @leading_adjective
            t = @trailing_adjective
            key = [!l || l.empty? ? nil : l, @term, !t || t.empty? ? nil : t]
          end
	  key += [:literal, literal.literal] if @literal
	  key
        end

        def bind context
          @nested_clauses.each{|c| c.bind context} if @nested_clauses
          if role_name = @role_name
            # Omit these tests to see if anything evil eventuates:
            #if @leading_adjective || @trailing_adjective
            #  raise "Role reference may not have adjectives if it defines a role name or uses a subscript: #{inspect}"
            #end
          else
            if uses_role_name?
              if @leading_adjective || @trailing_adjective
                raise "Role reference may not have adjectives if it uses a role name: #{inspect}"
              end
              role_name = @term
            end
          end
	  k = key
	  @binding = context.bindings[k]
	  if !@binding
	    if !literal
	      # Find a binding that has a literal, and bind to it if it's the only one
	      candidates = context.bindings.map do |binding_key, binding|
		  binding_key[0...k.size] == k &&
		    binding_key[-2] == :literal ? binding : nil
		end.compact
	      raise "Uncertain binding reference for #{to_s}, could be any of #{candidates.inspect}" if candidates.size > 1
	      @binding = candidates[0]
	    else
	      # New binding has a literal, look for one without:
	      @binding = context.bindings[k[0...-2]]
	    end
	  end

	  if !@binding
	    @binding = Binding.new(@player, role_name)
	    context.bindings[k] = @binding
	  end
          @binding.add_ref self
          @binding
        end

        def unbind context
          # The key has changed.
          @binding.delete_ref self
          if @binding.refs.empty?
            # Remove the binding from the context if this was the last reference
            context.bindings.delete_if {|k,v| v == @binding }
          end
          @binding = nil
        end

        def rebind(context)
          unbind context
          bind context
        end

        def rebind_to(context, other_ref)
          trace :binding, "Rebinding #{inspect} to #{other_ref.inspect}"

          old_binding = binding   # Remember to move all refs across
          unbind(context)

          new_binding = other_ref.binding
          [self, *old_binding.refs].each do |ref|
            ref.binding = new_binding
            new_binding.add_ref ref
          end
          old_binding.rebound_to = new_binding
        end

        # These are called when we successfully match a fact type reading that has relevant adjectives:
        def wipe_leading_adjective
          @leading_adjective = nil
        end

        def wipe_trailing_adjective
          @trailing_adjective = nil
        end

        def find_pc_over_roles(roles)
          return nil if roles.size == 0 # Safeguard; this would chuck an exception otherwise
          roles[0].all_role_ref.each do |role_ref|
            next if role_ref.role_sequence.all_role_ref.map(&:role) != roles
            pc = role_ref.role_sequence.all_presence_constraint.single  # Will return nil if there's more than one.
            #puts "Existing PresenceConstraint matches those roles!" if pc
            return pc if pc
          end
          nil
        end

        def make_embedded_presence_constraint vocabulary
          raise "No Role for embedded_presence_constraint" unless @role_ref
          fact_type = @role_ref.role.fact_type
          constellation = vocabulary.constellation

          trace :constraint, "Processing embedded constraint #{@quantifier.inspect} on #{@role_ref.role.object_type.name} in #{fact_type.describe}" do
            # Preserve the role order of the clause, excluding this role:
            constrained_roles = (@clause.refs-[self]).map{|vr| vr.role_ref.role}
            if constrained_roles.empty?
              trace :constraint, "Quantifier over unary role has no effect"
              return
            end
            constraint = find_pc_over_roles(constrained_roles)
            if constraint
              raise "Conflicting maximum frequency for constraint" if constraint.max_frequency && constraint.max_frequency != @quantifier.max
              trace :constraint, "Setting max frequency to #{@quantifier.max} for existing constraint #{constraint.object_id} over #{constraint.role_sequence.describe} in #{fact_type.describe}" unless constraint.max_frequency
              constraint.max_frequency = @quantifier.max
              raise "Conflicting minimum frequency for constraint" if constraint.min_frequency && constraint.min_frequency != @quantifier.min
              trace :constraint, "Setting min frequency to #{@quantifier.min} for existing constraint #{constraint.object_id} over #{constraint.role_sequence.describe} in #{fact_type.describe}" unless constraint.min_frequency
              constraint.min_frequency = @quantifier.min
            else
              role_sequence = constellation.RoleSequence(:new)
              constrained_roles.each_with_index do |constrained_role, i|
                role_ref = constellation.RoleRef(role_sequence, i, :role => constrained_role)
              end
              constraint = constellation.PresenceConstraint(
                  :new,
                  :vocabulary => vocabulary,
                  :role_sequence => role_sequence,
                  :is_mandatory => @quantifier.min && @quantifier.min > 0,  # REVISIT: Check "maybe" qualifier?
                  :max_frequency => @quantifier.max,
                  :min_frequency => @quantifier.min
                )
	      if @quantifier.pragmas
		@quantifier.pragmas.each do |p|
		  constellation.ConceptAnnotation(:concept => constraint.concept, :mapping_annotation => p)
		end
	      end
              trace :constraint, "Made new embedded PC GUID=#{constraint.concept.guid} min=#{@quantifier.min.inspect} max=#{@quantifier.max.inspect} over #{(e = fact_type.entity_type) ? e.name : role_sequence.describe} in #{fact_type.describe}"
              @quantifier.enforcement.compile(constellation, constraint) if @quantifier.enforcement
              @embedded_presence_constraint = constraint
            end
            constraint
          end

        end

        def result(context = nil)
          self
        end
      end

      # REVISIT: This needs to handle annotations for some/that/which, etc.
      class Quantifier
        attr_accessor :enforcement
        attr_accessor :context_note
        attr_accessor :pragmas
        attr_reader :min, :max

        def initialize min, max, enforcement = nil, context_note = nil, pragmas = nil
          @min = min
          @max = max
          @enforcement = enforcement
          @context_note = context_note
	  @pragmas = pragmas
        end

        def is_unique
          @max and @max == 1
        end

        def is_mandatory
          @min and @min >= 1
        end

        def is_zero
          @min == 0 and @max == 0
        end

        def inspect
          "[#{@min}..#{@max}]#{
            @context_note && ' ' + @context_note.inspect
          }"
        end
      end

    end
  end
end
