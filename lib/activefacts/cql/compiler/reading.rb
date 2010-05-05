module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class Reading
        attr_reader :phrases
        attr_accessor :qualifiers, :context_note
        attr_reader :fact_type, :reading, :role_sequence    # These are the Metamodel objects

        def initialize role_refs_and_words, qualifiers = [], context_note = nil
          @phrases = role_refs_and_words
          role_refs.each { |role_ref| role_ref.reading = self }
          @qualifiers = qualifiers
          @context_note = context_note
        end

        def role_refs
          @phrases.select{|r| r.is_a?(RoleRef)}
        end

        # A reading that contains only the name of a Concept and no literal or reading text
        # refers only to the existence of that Concept (as opposed to an instance of the concept).
        def is_existential_type
          @phrases.size == 1 and
            @phrases[0].is_a?(RoleRef) and
            !@phrases[0].literal
        end

        def inspect
          "#{@qualifiers && @qualifiers.size > 0 ? @qualifiers.inspect+' ' : nil}#{@phrases.map{|p|p.inspect}*" "}#{@context_note && ' '+@context_note.inspect}"
        end

        def identify_players_with_role_name context
          role_refs.each do |role_ref|
            role_ref.identify_player(context) if role_ref.role_name
          end
        end

        def identify_other_players context
          role_refs.each do |role_ref|
            role_ref.identify_player(context) unless role_ref.player
          end
        end

        def includes_literals
          role_refs.detect{|role_ref| role_ref.literal }
        end

        def bind_roles context
          role_names = role_refs.map{ |role_ref| role_ref.role_name }.compact

          # Check uniqueness of role names and subscripts within this reading:
          role_names.each do |rn|
            next if role_names.select{|rn2| rn2 == rn}.size == 1
            raise "Duplicate role #{rn.is_a?(Integer) ? "subscript" : "name"} '#{rn}' in reading"
          end

          role_refs.each { |role_ref| role_ref.bind context }
        end

        def phrases_match(phrases)
          @phrases.zip(phrases).each do |mine, theirs|
            return false if mine.is_a?(RoleRef) != theirs.is_a?(RoleRef)
            if mine.is_a?(RoleRef)
              return false unless mine.key == theirs.key
            else
              return false unless mine == theirs
            end
          end
          true
        end

        # This method chooses the existing fact type which matches most closely.
        # It returns nil if there is none, or a ReadingMatchSideEffects object if matched.
        #
        # As this match may not necessarily be used (depending on the side effects),
        # no change is made to this Reading object - those will be done later.
        #
        # REVISIT: In future, there may be more than one match, and this method will return
        # them all, for the caller to select the best.
        def match_existing_fact_type context
          rrs = role_refs
          players = rrs.map{|rr| rr.player}
          raise "Must identify players before matching fact types" if players.include? nil

          # For each role player, find the compatible types (the set of all subtypes and supertypes).
          player_related_types =
            players.map do |player|
              (player.supertypes_transitive+player.subtypes_transitive).uniq
            end

          # The candidate fact types have the right number of role players of related types.
          # If any role is played by a supertype or subtype of the required type, there's an implicit subtyping join.
          candidate_fact_types =
            player_related_types[0].map do |related_type|
              related_type.all_role.select do |role|
                all_roles = role.fact_type.all_role
                next if all_roles.size != players.size      # Wrong number of players

                if players.size == 2 and
                  role.fact_type.is_a?(Metamodel::TypeInheritance) and
                  [players[0].name, players[1].name].sort != all_roles.map{|r| r.concept.name}.sort
                  # REVISIT: Perhaps this match can be made transitive in future:
                  debug :matching, "Requiring exact match for TypeInheritance invocation"
                  next
                end

                all_players = all_roles.map{|r| r.concept}  # All the players of this candidate fact type

                next if player_related_types[1..-1].        # We know the first player is compatible, check the rest
                  detect do |player_types|                  # Make sure that there remains a compatible player
                    # player_types is an array of the types compatible with the Nth player
                    compatible_player = nil
                    all_players.each_with_index do |p, i|
                      if player_types.include?(p)
                        compatible_player = p
                        all_players.delete_at(i)
                        break
                      end
                    end
                    !compatible_player
                  end

                true
              end.
                map{ |role| role.fact_type}
            end.flatten.uniq

          # If there is more than one possible exact match (same adjectives) with different subyping, the implicit join is ambiguous and is not allowed

          debug :matching, "Looking amongst #{candidate_fact_types.size} existing fact types for one matching '#{rrs.inspect}'" do
            matches = {}
            candidate_fact_types.map do |fact_type|
              fact_type.all_reading.map do |reading|
                next unless side_effects = reading_matches(fact_type, reading)
                matches[reading] = side_effects if side_effects
              end
            end

            # REVISIT: Side effects that leave extra adjectives should only be allowed if the
            # same extra adjectives exist in some other reading in the same declaration.
            # The extra adjectives are then necessary to associate the two role players
            # when consumed adjectives were required to bind to the underlying fact types.
            # This requires the final decision on fact type matching to be postponed until
            # the whole declaration has been processed and the extra adjectives can be matched.

            best_matches = matches.keys.sort_by{|match| matches[match].cost}

            if matches.size > 1 and matches[best_matches[0]].cost > 0
              # Complain if there's more than one inexact match:
              raise "#{@phrases.inspect} could match any of the following:\n\t"+
                best_matches.map { |reading| reading.expand + " with " + matches[reading].describe } * "\n\t"
            end

            if matches.size >= 1
              @reading = best_matches[0]
              side_effects = matches[@reading]
              apply_side_effects(context, side_effects)
              return @fact_type = side_effects.fact_type
            end

          end
          @fact_type = nil
        end

        # The ActiveFacts::Metamodel::Reading passed has the same players as this Compiler::Reading. Does it match?
        # Twisty curves. This is a complex bit of code!
        # Find whether the phrases of this reading match the fact type reading,
        # which may require absorbing unmarked adjectives.
        #
        # If it does match, make the required changes and set @role_ref to the matching role.
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
        def reading_matches(fact_type, reading)
          side_effects = []    # An array of items for each role, describing any side-effects of the match.
          residual_adjectives = false
          debug :matching_fails, "Does '#{@phrases.inspect}' match '#{reading.expand}'" do
            phrase_num = 0
            reading_parts = reading.text.split(/\s+/)
            # Check that the number of roles matches (skipped, the caller should have done it):
            # return nil unless reading_parts.select{|p| p =~ /\{(\d+)\}/}.size == role_refs.size
            reading_parts.each do |element|
              if element !~ /\{(\d+)\}/
                # Just a word; it must match
                unless @phrases[phrase_num] == element
                  debug :matching_fails, "Mismatched ordinary word #{@phrases[phrase_num]} (wanted #{element})"
                  return nil
                end
                phrase_num += 1
                next
              else
                role_ref = reading.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}[$1.to_i]
              end

              # Figure out what's next in this phrase (the next player and the words leading up to it)
              next_player_phrase = nil
              intervening_words = []
              while (phrase = @phrases[phrase_num])
                phrase_num += 1
                if phrase.is_a?(RoleRef)
                  next_player_phrase = phrase
                  next_player_phrase_num = phrase_num-1
                  break
                else
                  intervening_words << phrase
                end
              end

              player = role_ref.role.concept
              return nil unless next_player_phrase  # reading has more players than we do.

              # The next player must match:
              common_supertype = nil
              if next_player_phrase.player != player
                # This relies on the supertypes being in breadth-first order:
                common_supertype = (next_player_phrase.player.supertypes_transitive & player.supertypes_transitive)[0]
                if !common_supertype
                  debug :matching_fails, "Reading discounted because next player #{player.name} doesn't match #{next_player_phrase.player.name}"
                  return nil
                end
                debug :matching, "Subtype join is required between #{player.name} and #{next_player_phrase.player.name} via common supertype #{common_supertype.name}"
                # REVISIT: Remember the subtype join as a side-effect
              end

              # It's the right player. Do the adjectives match? This must include the intervening_words, if any.

              absorbed_precursors = 0
              if la = role_ref.leading_adjective and !la.empty?
                # The leading adjectives must match, one way or another
                la = la.split(/\s+/)
                return nil unless la[0,intervening_words.size] == intervening_words
                # Any intervening_words matched, see what remains
                la.slice!(0, intervening_words.size)

                # If there were intervening_words, the remaining reading adjectives must match the phrase's leading_adjective exactly.
                phrase_la = (next_player_phrase.leading_adjective||'').split(/\s+/)
                return nil if !intervening_words.empty? && la != phrase_la
                # If not, the phrase's leading_adjectives must *end* with the reading's
                return nil if phrase_la[-la.size..-1] != la
                residual_adjectives = true if phrase_la.size > la.size
                # The leading adjectives and the player matched! Check the trailing adjectives.
                absorbed_precursors = intervening_words.size
              end

              absorbed_followers = 0
              if ta = role_ref.trailing_adjective and !ta.empty?
                ta = ta.split(/\s+/)  # These are the trailing adjectives to match

                phrase_ta = (next_player_phrase.trailing_adjective||'').split(/\s+/)
                i = 0   # Pad the phrases up to the size of the trailing_adjectives
                while phrase_ta.size < ta.size
                  break unless (word = @phrases[phrase_num+i]).is_a?(String)
                  phrase_ta << word
                  i += 1
                end
                return nil if ta != phrase_ta[0,ta.size]
                residual_adjectives = true if phrase_ta.size > ta.size || i < ta.size
                absorbed_followers = i
                phrase_num += i # Skip following words that were consumed as trailing adjectives
              end

              # The phrases matched this reading's next role_ref, save data to apply the side-effects:
              debug :matching, "Saving side effects for #{next_player_phrase.term}, absorbs #{absorbed_precursors}/#{absorbed_followers}#{common_supertype ? ', join over supertype '+ common_supertype.name : ''}" if absorbed_precursors+absorbed_followers+(common_supertype ? 1 : 0) > 0
              side_effects << [next_player_phrase, role_ref, next_player_phrase_num, absorbed_precursors, absorbed_followers, common_supertype]
            end

            unless phrase_num == @phrases.size
              debug :matching_fails, "Extra words #{@phrases[phrase_num..-1].inspect}"
              return nil
            end
            debug :matching, "Matched reading '#{reading.expand}' with #{side_effects.map{|(phrase, role_ref, num, absorbed_precursors, absorbed_followers, common_supertype)| absorbed_precursors+absorbed_followers + (common_supertype ? 1 : 0)}.inspect} side effects#{residual_adjectives ? ' and residual adjectives' : ''}"
          end
          # There will be one side_effects for each role player
          ReadingMatchSideEffects.new(fact_type, self, residual_adjectives, side_effects)
        end

        def apply_side_effects(context, side_effects)
          @applied_side_effects = side_effects
          # Enact the side-effects of this match (delete the consumed adjectives):
          # Since this deletes words from the phrases, we do it in reverse order.
          debug :matching, "Apply side-effects" do
            side_effects.apply_all do |phrase, role_ref, num, absorbed_precursors, absorbed_followers, common_supertype|
              phrase.role_ref = role_ref    # re-used if possible (no extra adjectives were used, no rolename or join, etc).
              changed = false

              # Where this phrase has leading or trailing adjectives that are in excess of those of
              # the role_ref, those must be local, and we'll need to extract them.

              if rra = role_ref.trailing_adjective
                debug :matching, "Deleting matched trailing adjective '#{rra}'#{absorbed_followers>0 ? "in #{absorbed_followers} followers" : ""}"

                # These adjective(s) matched either an adjective here, or a follower word, or both.
                if a = phrase.trailing_adjective
                  if a.size >= rra.size
                    a.slice!(0, rra.size+1) # Remove the matched adjectives and the space (if any)
                    phrase.wipe_trailing_adjective if a.empty?
                    changed = true
                  end
                elsif absorbed_followers > 0
                  phrase.wipe_trailing_adjective
                  @phrases.slice!(num+1, absorbed_followers)
                  changed = true
                end
              end

              if rra = role_ref.leading_adjective
                debug :matching, "Deleting matched leading adjective '#{rra}'#{absorbed_precursors>0 ? "in #{absorbed_precursors} precursors" : ""}}"

                # These adjective(s) matched either an adjective here, or a precursor word, or both.
                if a = phrase.leading_adjective
                  if a.size >= rra.size
                    a.slice!(-rra.size, 1000) # Remove the matched adjectives and the space
                    a.chop!
                    phrase.wipe_leading_adjective if a.empty?
                    changed = true
                  end
                elsif absorbed_precursors > 0
                  phrase.wipe_leading_adjective
                  @phrases.slice!(num-absorbed_precursors, absorbed_precursors)
                  changed = true
                end
              end

              phrase.rebind(context) if changed

            end
          end
        end

        # Make a new fact type with roles for this reading.
        # Don't assign @fact_type; that will happen when the reading is added
        def make_fact_type vocabulary
          fact_type = vocabulary.constellation.FactType(:new)
          debug :matching, "Making new fact type for #{@phrases.inspect}" do
            @phrases.each do |phrase|
              next unless phrase.is_a?(RoleRef)
              phrase.role = vocabulary.constellation.Role(fact_type, fact_type.all_role.size, :concept => phrase.player)
              phrase.role.role_name = phrase.role_name if phrase.role_name
            end
          end
          fact_type
        end

        def make_reading vocabulary, fact_type
          @fact_type = fact_type
          constellation = vocabulary.constellation
          @role_sequence = constellation.RoleSequence(:new)
          reading_words = []
          debug :matching, "Making new reading for #{@phrases.inspect}" do
            @phrases.each do |phrase|
              if phrase.is_a?(RoleRef)
                index = @role_sequence.all_role_ref.size
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
                if phrase.restriction
                  raise "The role #{rr.inspect} already has a value constraint" if rr.role.role_value_restriction
                  rr.role.role_value_restriction = phrase.restriction.compile fact_type.constellation
                end
                reading_words << "{#{index}}"
              else
                reading_words << phrase
              end
            end
            constellation.Reading(@fact_type, @fact_type.all_reading.size, :role_sequence => @role_sequence, :text => reading_words*" ")
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
            if phrase.is_a?(RoleRef)
              role_phrases << phrase
              reading_words << "{#{phrase.role_ref.ordinal}}"
              if phrase.role_name # ||
#                  phrase.leading_adjective ||
#                  phrase.trailing_adjective
                debug :matching, "phrase in matched reading has residual adjectives or role name, so needs a new role_sequence" if @fact_type.all_reading.size > 0
                new_role_sequence_needed = true
              end
            else
              reading_words << phrase
              false
            end
          end

          debug :matching, "Reading '#{reading_words*' '}' #{new_role_sequence_needed ? 'requires' : 'does not require'} a new Role Sequence"

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
              if a = rp.role_name
                extra_adjectives << "(as #{a})"
              end
            end
            debug :matching, "Making new role sequence for new reading #{reading_words*" "} due to #{extra_adjectives.inspect}"
          else
            # Use existing RoleSequence
            @role_sequence = role_phrases[0].role_ref.role_sequence
            if @role_sequence.all_reading.detect{|r| r.text == reading_text }
              debug :matching, "No need to re-create identical reading for #{reading_words*" "}"
              return @role_sequence
            else
              debug :matching, "Using existing role sequence for new reading '#{reading_words*" "}'"
            end
          end
          constellation.Reading(@fact_type, @fact_type.all_reading.size, :role_sequence => @role_sequence, :text => reading_words*" ")
          @role_sequence
        end

        def make_embedded_constraints vocabulary
          role_refs.each do |role_ref|
            next unless role_ref.quantifier
            # puts "Quantifier #{role_ref.inspect} not implemented as a presence constraint"
            role_ref.make_embedded_presence_constraint vocabulary
          end

          if @qualifiers && @qualifiers.size > 0

            rc = RingConstraint.new(@role_sequence, @qualifiers)
            rc.vocabulary = vocabulary
            rc.constellation = vocabulary.constellation
            rc.compile

            # REVISIT: Check maybe and other qualifiers:
            debug :constraint, "Need to make constraints for #{@qualifiers*', '}" if @qualifiers.size > 0
          end
        end

      end

      class ReadingMatchSideEffects
        attr_reader :residual_adjectives
        attr_reader :fact_type

        def initialize fact_type, reading, residual_adjectives, side_effects
          @fact_type = fact_type
          @reading = reading
          @residual_adjectives = residual_adjectives
          @side_effects = side_effects
        end

        def apply_all &b
          @side_effects.reverse.each{ |side_effect| b.call(*side_effect) }
        end

        def cost
          c = 0
          @side_effects.each do |phrase, role_ref, num, absorbed_precursors, absorbed_followers, common_supertype|
            c += absorbed_precursors + absorbed_followers + (common_supertype ? 1 : 0)
          end
          c
        end

        def describe
          actual_effects =
            @side_effects.map do |phrase, role_ref, num, absorbed_precursors, absorbed_followers, common_supertype|
              ( [common_supertype ? "supertype join over #{common_supertype.name}" : nil] +
                [absorbed_precursors > 0 ? "absorbs #{absorbed_precursors} preceding words" : nil] +
                [absorbed_followers > 0 ? "absorbs #{absorbed_followers} following words" : nil]
              )
            end.flatten.compact*','
          actual_effects.empty? ? "no side effects" : actual_effects
        end
      end

      class RoleRef
        attr_reader :term, :leading_adjective, :trailing_adjective, :quantifier, :function_call, :role_name, :restriction, :literal
        attr_reader :player
        attr_accessor :binding
        attr_accessor :reading    # The reading that this RoleRef is part of
        attr_accessor :role       # This refers to the ActiveFacts::Metamodel::Role
        attr_accessor :role_ref   # This refers to the ActiveFacts::Metamodel::RoleRef
        attr_reader :embedded_presence_constraint   # This refers to the ActiveFacts::Metamodel::PresenceConstraint

        def initialize term, leading_adjective, trailing_adjective, quantifier, function_call, role_name, restriction, literal
          @term = term
          @leading_adjective = leading_adjective
          @trailing_adjective = trailing_adjective
          @quantifier = quantifier
          # @function_call = function_call # REVISIT: Not used or implemented
          @role_name = role_name
          @restriction = restriction
          @literal = literal
        end

        def inspect
          "RoleRef<#{
            @quantifier && @quantifier.inspect+' ' }#{
            @leading_adjective && @leading_adjective.sub(/ |$/,'- ').sub(/ *$/,' ') }#{
            @term }#{
            @trailing_adjective && ' '+@trailing_adjective.sub(/(.* |^)/, '\1-') }#{
            @role_name and @role_name.is_a?(Integer) ? "(#{@role_name})" : " (as #{@role_name})" }#{
            @literal && ' '+@literal.inspect }#{
            @restriction && ' '+@restriction.inspect
          }>"
        end

        def <=>(other)
          ( 4*(@term <=> other.term) +
            2*((@leading_adjective||'') <=> (other.leading_adjective||'')) +
            1*((@trailing_adjective||'') <=> (other.trailing_adjective||''))
          ) <=> 0
        end

        def identify_player context
          @player = context.concept @term
          raise "Concept #{@term} unrecognised" unless @player
          context.player_by_role_name[@role_name] = player if @role_name
          @player
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
            key = [@leading_adjective, @term, @trailing_adjective]
          end
        end

        def bind context
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
          @binding = (context.bindings[key] ||= Binding.new(@player, role_name))
          @binding.refs << self
          @binding
        end

        def unbind context
          # The key has changed.
          @binding.refs.delete(self)
          @binding = nil
        end

        def rebind(context)
          unbind context
          bind context
        end

        def rebind_to(context, other_role_ref)
          debug :binding, "Rebinding #{inspect} to #{other_role_ref.inspect}"

          old_binding = binding   # Remember to move all refs across
          unbind(context)

          new_binding = other_role_ref.binding
          [self, *old_binding.refs].each do |ref|
            ref.binding = new_binding
            new_binding.refs << ref
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

          debug :constraint, "Processing embedded constraint #{@quantifier.inspect} on #{@role_ref.role.concept.name} in #{fact_type.describe}" do
            constrained_roles = fact_type.all_role.to_a.clone
            constrained_roles.delete(@role_ref.role)
            if constrained_roles.empty?
              debug :constraint, "Quantifier over unary role has no effect"
              return
            end
            constraint = find_pc_over_roles(constrained_roles)
            if constraint
              debug :constraint, "Setting max frequency to #{@quantifier.max} for existing constraint #{constraint.object_id} over #{constraint.role_sequence.describe} in #{fact_type.describe}"
              raise "Conflicting maximum frequency for constraint" if constraint.max_frequency && constraint.max_frequency != @quantifier.max
              constraint.max_frequency = @quantifier.max
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
              debug :constraint, "Made new PC min=#{@quantifier.min.inspect} max=#{@quantifier.max.inspect} constraint #{constraint.object_id} over #{(e = fact_type.entity_type) ? e.name : role_sequence.describe} in #{fact_type.describe}"
              if @quantifier.enforcement && @quantifier.enforcement != []
                # apply_enforcement(constraint, @quantifier.enforcement)
                puts "Can't apply enforcement to presence constraints yet"
              end
              @embedded_presence_constraint = constraint
            end
            constraint
          end

        end
      end

      class Quantifier
        attr_accessor :enforcement
        attr_reader :min, :max

        def initialize min, max, enforcement = nil
          @min = min
          @max = max
          @enforcement = enforcement
        end

        def inspect
          "[#{@min}..#{@max}]"
        end
      end

    end
  end
end
