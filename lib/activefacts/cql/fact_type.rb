#       Compile a CQL string into an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      private

      def make_fact_type_for_clause(clause)
        fact_type = @constellation.FactType(:new)
        kind, qualifiers, phrases, context = *clause
        debug :matching, "Making new fact type for #{show_phrases(phrases)}" do
          phrases.each do |phrase|
            next unless phrase.is_a?(Hash)
            role = @constellation.Role(fact_type, fact_type.all_role.size, :concept => phrase[:player])
            phrase[:role] = role
          end
        end
        fact_type
      end

      def make_reading_for_fact_type(fact_type, clause)
        role_sequence = @constellation.RoleSequence(:new)
        reading_words = []
        kind, qualifiers, phrases, context = *clause
        debug :matching, "Making new reading for #{show_phrases(phrases)}" do
          phrases.each do |phrase|
            if phrase.is_a?(Hash)
              index = role_sequence.all_role_ref.size
              role = phrase[:role]
              raise "Role player #{phrase[:player].name} not found for reading: REVISIT Phrase is #{phrase.inspect}" unless role
              rr = @constellation.RoleRef(role_sequence, index, :role => role)
              phrase[:role_ref] = rr
              if la = phrase[:leading_adjective]
                # If we have used one or more adjective to match an existing reading, that has already been removed.
                rr.leading_adjective = la
              end
              if ta = phrase[:trailing_adjective]
                rr.trailing_adjective = ta
              end
              reading_words << "{#{index}}"
            else
              reading_words << phrase
            end
          end
          @constellation.Reading(fact_type, fact_type.all_reading.size, :role_sequence => role_sequence, :text => reading_words*" ")
        end
      end

      def fact_type(name, clauses, conditions) 
        debug :matching, "Processing clauses for fact type" do
          fact_type = nil

          # REVISIT: Any role names defined in the conditions aren't handled here, only those in the clauses

          # Find and set [:player] to the concept (object type) that plays each role
          resolve_players(phrases_list_from_clauses(clauses))

          # Arrange the clauses according to the players (the hash key is the sorted array of player's names)
          cbp = clauses_by_players(clauses)
          terms = cbp.keys[0]

          # For a fact type, all clauses must have the same players:
          raise "Subsequent fact type clauses must involve the same players as the first (#{terms*', '})" unless cbp.size == 1

          # Find whether any clause matches an existing fact type.
          # Ensure that any matched clauses all match the same fact type.
          # Massage any unmarked adjectives into the role phrase hash if needed.
          matched_clauses, unmatched_clauses =
            *clauses.partition do |clause|
              ft = find_existing_fact_type(clause)
              next false unless ft
              raise "Clauses match different existing fact types" if fact_type && ft != fact_type
              fact_type = ft
            end

          # Make a new fact type if we didn't match any reading
          fact_type = make_fact_type_for_clause(unmatched_clauses[0]) unless fact_type

          # We know the role players are the same in all clauses, but we haven't matched them up.

          # If we have no matched clause, make a fact type and reading for the first clause.
          # Treat this new reading as a matched clause.
          first_clause = nil
          if matched_clauses.size == 0
            matched_clauses << (first_clause = unmatched_clauses.shift)
            make_reading_for_fact_type(fact_type, first_clause)
          end

          # Then, for each remaining unmatched clause, try to match the roles against those of any matched clause.
          match_progress = []
          unmatched_clauses.each do |clause|
            # REVISIT: Any duplicated unmatched_clauses aren't detected here.
            match_clause_against_clauses(clause, matched_clauses+match_progress)
            make_reading_for_fact_type(fact_type, clause)
            match_progress << clause
          end

          (matched_clauses-[first_clause]).each do |clause|
            # This might create a new reading and a new role sequence if needed, or use the matched one
            role_sequence_for_matched_reading(fact_type, clause)
          end

          # REVISIT: Create ring constraints here

          debug :constraint, "making embedded presence constraints" do
            (matched_clauses + unmatched_clauses).each do |clause|
              make_embedded_presence_constraints(fact_type, clause)
            end
          end

          @constellation.EntityType(@vocabulary, name, :fact_type => fact_type) if name

          # If there's no alethic uniqueness constraint over the fact type yet, create one
          unless fact_type.all_role.detect{|r| r.all_role_ref.detect{|rr| rr.role_sequence.all_presence_constraint.detect{|pc| pc.max_frequency == 1 && !pc.enforcement}} }
            # REVISIT: This isn't the thing to do long term; it needs to be added later only if we find no other constraint
            make_default_identifier_for_fact_type(fact_type)
          end

          # REVISIT: Process the fact derivation conditions, if any
        end
      end

      def role_sequence_for_matched_reading(fact_type, clause)
        # When we have existing clauses that match, we might have matched using additional adjectives.
        # These adjectives have been removed from the phrases. If there are any remaining adjectives,
        # we need to make a new RoleSequence, otherwise we can use the existing one.
        kind, qualifiers, phrases, context = clause
        role_phrases = []
        role_sequence = nil
        reading_words = []
        new_role_sequence_needed = false
        phrases.each do |phrase|
          if phrase.is_a?(Hash)
            role_phrases << phrase
            reading_words << "{#{phrase[:role_ref].ordinal}}"
            if phrase[:leading_adjective] ||
              phrase[:trailing_adjective] ||
              phrase[:role_name]
              debug :matching, "phrase in matched reading has residual adjectives or role name, so needs a new role_sequence" if fact_type.all_reading.size > 0
              new_role_sequence_needed = true
            end
          else
            reading_words << phrase
            false
          end
        end

        reading_text = reading_words*" "
        if new_role_sequence_needed
          role_sequence = @constellation.RoleSequence(:new)
          extra_adjectives = []
          role_phrases.each_with_index do |rp, i|
            role_ref = @constellation.RoleRef(role_sequence, i, :role => rp[:role_ref].role)
            if a = rp[:leading_adjective]
              role_ref.leading_adjective = a
              extra_adjectives << a+"-"
            end
            if a = rp[:trailing_adjective]
              role_ref.trailing_adjective = a
              extra_adjectives << "-"+a
            end
            if a = rp[:role_name]
              extra_adjectives << "(as #{a})"
            end
          end
          debug :matching, "Making new role sequence for new reading #{reading_words*" "} due to #{extra_adjectives.inspect}"
        else
          # Use existing RoleSequence
          role_sequence = role_phrases[0][:role_ref].role_sequence
          if role_sequence.all_reading.detect{|r| r.text == reading_text }
            debug :matching, "No need to re-create identical reading for #{reading_words*" "}"
            return role_sequence
          else
            debug :matching, "Using existing role sequence for new reading '#{reading_words*" "}'"
          end
        end
        @constellation.Reading(fact_type, fact_type.all_reading.size, :role_sequence => role_sequence, :text => reading_words*" ")
        role_sequence
      end

      def make_default_identifier_for_fact_type(fact_type, prefer = true)
        @constellation.PresenceConstraint(
            :new,
            :vocabulary => @vocabulary,
            :name => fact_type.entity_type ? fact_type.entity_type.name+"PK" : '',
            :role_sequence => fact_type.preferred_reading.role_sequence,
            :is_preferred_identifier => true,
            :max_frequency => 1,
            :is_preferred_identifier => prefer
          )
      end

      def show_phrases(phrases)
        phrases.map do |phrase|
          if phrase.is_a?(Hash)
            ((l = phrase[:leading_adjective]) ? l+"- " : "") +
              phrase[:term] +
              ((t = phrase[:trailing_adjective]) ? " -"+t : "") +
              ((r = phrase[:role_name]) ? (r.is_a?(Integer) ? " (#{r})" : " (as #{r})") : "")
          else
            phrase
          end
        end*" "
      end

      # Decide if any existing fact type matches this clause.
      # The roles must have been resolved already (see resolve_players above)
      # Check each existing fact type that has the same players, and check
      # each reading having them in the same order.
      def find_existing_fact_type(clause)
        kind, qualifiers, phrases, context = *clause
        player_phrases = phrases.select{|phrase| phrase.is_a?(Hash)}
        players = player_phrases.map{|phrase| phrase[:player]}
        players_sorted_by_name = players.sort_by{|p| p.name}
        player_having_fewest_roles = players.sort_by{|p| p.all_role.size}[0]
        # REVISIT: Note: we will need to handle implicit subtyping joins here.
        debug :matching, "Looking for existing fact type to match '#{show_phrases(phrases)}'" do
          player_having_fewest_roles.all_role.each do |role|
            next unless role.fact_type.all_role.size == players.size
            next unless role.fact_type.all_role.map{|r| r.concept}.sort_by{|p| p.name} == players_sorted_by_name
            # role.fact_type has the same players. See if there's a matching reading
            role.fact_type.all_reading.each do |reading|
              return role.fact_type if reading_matches_phrases(reading, phrases)
            end
          end
        end
        nil
      end

      # Twisty curves. This is a complex bit of code!
      # Find whether the phrases of this clause match the fact type reading,
      # which may require absorbing unmarked adjectives.
      #
      # If it does match, make the required changes and set [:role_ref] to the matching role.
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
      #     a word that matches the clause's
      #
      def reading_matches_phrases(reading, phrases)
        phrase_num = 0
        player_details = []    # An array of items for each role, describing any side-effects of the match.
        debug :matching, "Does '#{show_phrases(phrases)}' match '#{reading.expand}'" do
          reading.text.split(/\s+/).each do |element|
            if element !~ /\{(\d+)\}/
              # Just a word; it must match
              unless phrases[phrase_num] == element
                debug :matching, "Mismatched ordinary word #{element} (wanted #{element})"
                return nil
              end
              phrase_num += 1
            else
              role_ref = reading.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}[$1.to_i]

              # Figure out what's next in this phrase (the next player and the words leading up to it)
              next_player_phrase = nil
              intervening_words = []
              while (phrase = phrases[phrase_num])
                phrase_num += 1
                if phrase.is_a?(Hash)
                  next_player_phrase = phrase
                  next_player_phrase_num = phrase_num-1
                  break
                else
                  intervening_words << phrase
                end
              end

              # The next player must match:
              # REVISIT: Note: we will need to handle implicit subtyping joins here.
              player = role_ref.role.concept
              return nil unless next_player_phrase and next_player_phrase[:player] == player

              # It's the right player. Do the adjectives match?

              absorbed_precursors = 0
              if la = role_ref.leading_adjective and !la.empty?
                # The leading adjectives must match, one way or another
                la = la.split(/\s+/)
                return nil unless la[0,intervening_words.size] == intervening_words
                # Any intervening_words matched, see what remains
                la.slice!(0, intervening_words.size)

                # If there were intervening_words, the remaining reading adjectives must match the phrase's leading_adjective exactly.
                phrase_la = (next_player_phrase[:leading_adjective]||'').split(/\s+/)
                return nil if !intervening_words.empty? && la != phrase_la
                # If not, the phrase's leading_adjectives must *end* with the reading's
                return nil if phrase_la[-la.size..-1] != la
                # The leading adjectives and the player matched! Check the trailing adjectives.
                absorbed_precursors = intervening_words.size
              end

              absorbed_followers = 0
              if ta = role_ref.trailing_adjective and !ta.empty?
                ta = ta.split(/\s+/)  # These are the trailing adjectives to match

                phrase_ta = (next_player_phrase[:trailing_adjective]||'').split(/\s+/)
                i = 0   # Pad the phrases up to the size of the trailing_adjectives
                while phrase_ta.size < ta.size
                  break unless (word = phrases[phrase_num+i]).is_a?(String)
                  phrase_ta << word
                  i += 1
                end
                return nil if ta != phrase_ta[0,ta.size]
                absorbed_followers = i
                phrase_num += i # Skip following words that were consumed as trailing adjectives
              end

              # The phrases matched this reading's next role_ref, save data to apply the side-effects:
              debug :matching, "Saving matched player #{next_player_phrase[:term]} with #{role_ref ? "a" : "no" } role_ref"
              player_details << [next_player_phrase, role_ref, next_player_phrase_num, absorbed_precursors, absorbed_followers]
            end
          end

          # Enact the side-effects of this match (delete the consumed adjectives):
          debug :matching, "It does match, apply side-effects" do
            player_details.reverse.each do |phrase, role_ref, num, precursors, followers|
              phrase[:role_ref] = role_ref    # Used if no extra adjectives were used

              # Where this phrase has leading or trailing adjectives that are in excess of those of
              # the role_ref, those must be local, and we'll need to extract them.

              if rra = role_ref.trailing_adjective
                debug :matching, "Deleting matched trailing adjective '#{rra}'#{followers>0 ? "in #{followers} followers" : ""}"

                # These adjective(s) matched either an adjective here, or a follower word, or both.
                if a = phrase[:trailing_adjective]
                  if a.size >= rra.size
                    a.slice!(0, rra.size+1) # Remove the matched adjectives and the space (if any)
                    phrase.delete(:trailing_adjective) if a.empty?
                  end
                elsif followers > 0
                  phrase.delete(:trailing_adjective)
                  phrases.slice!(num+1, followers)
                end
              end

              if rra = role_ref.leading_adjective
                debug :matching, "Deleting matched leading adjective '#{rra}'#{precursors>0 ? "in #{precursors} precursors" : ""}}"

                # These adjective(s) matched either an adjective here, or a precursor word, or both.
                if a = phrase[:leading_adjective]
                  if a.size >= rra.size
                    a.slice!(-rra.size, 1000) # Remove the matched adjectives and the space
                    a.slice!(0,1) if a[0,1] == ' '
                    phrase.delete(:leading_adjective) if a.empty?
                  end
                elsif precursors > 0
                  phrase.delete(:leading_adjective)
                  phrases.slice!(num-precursors, precursors)
                end
              end
            end
          end
        end
        debug :matching, "Matched reading '#{reading.expand}'"

        true
      end

      # We have a clause that doesn't match any existing fact reading, and one or more
      # clauses that match the fact it's a reading for.
      # Try to match the roles against those of any matched clause.
      # The role matching must be exact for all (or all but one) role of each player.
      # An exact role match occurs where a subscript matches (must be the same player!)
      # If the role has no subscript but does have a role name, the role name matches.
      # If the role has neither, the adjectives must match.
      # Finally, a role is an inexact match if the player matches and no other role of this player is inexact.
      def match_clause_against_clauses(clause, matched_clauses)
        kind, qualifiers, phrases, context = *clause
        role_phrases = phrases.select{|p|p.is_a?(Hash)}
        debug :matching, "Looking for match for roles of '#{show_phrases(phrases)}'" do
          matched_clauses.detect do |matched_clause|
            m_kind, m_qualifiers, m_phrases, m_context = *matched_clause
            mr_phrases = m_phrases.select{|p|p.is_a?(Hash)}
            inexact_phrases = []
            debug :matching, "Looking in roles of '#{show_phrases(m_phrases)}'" do
              matched = nil
              role_phrases.each do |phrase|
                debug :matching, "Looking for match for #{phrase[:player].name}" do
                  kind = nil
                  if (role_name = phrase[:role_name]).is_a?(Integer) and
                    matched = mr_phrases.detect {|mrp| mrp[:role_name] == role_name }
                    kind = "subscript" # Matched on same subscript
                  elsif role_name and (matched = mr_phrases.detect {|mrp| mrp[:term] == role_name })
                    kind = "role definition"  # Matched on a role name that the unmatchd clause defined
                  elsif (matched = mr_phrases.detect {|mrp| mrp[:role_name] == phrase[:term] })
                    kind = "role reference" # Matched on a role name that the matchd clause defined
                  elsif matched = mr_phrases.detect do |mrp|
                        m_role_ref = mrp[:role_ref]
                        #t = phrase[:trailing_adjective]
                        #l = phrase[:leading_adjective]
                        #w = "#{l ? l+'- ' : ''}#{phrase[:term]}#{t ? ' -'+t : ''}"
                        #debug :matching, "Trying adjective of '#{w}' against '#{m_role_ref.leading_adjective}- #{m_role_ref.role.concept.name} -#{m_role_ref.trailing_adjective}'"
                        m_role_ref.leading_adjective == phrase[:leading_adjective] and
                        m_role_ref.trailing_adjective == phrase[:trailing_adjective] and
                        m_role_ref.role.concept.name == phrase[:term]
                      end
                    kind = "adjectives" # Matched on all adjectives
                  else
                    inexact_phrases << phrase
                    next    # We have to leave this until all exact matches are consumed
                  end
                  debug :matching, "Matched role #{phrase[:player].name} using #{kind} against #{matched.inspect}"
                  mr_phrases.delete(matched)  # We can't use this phrase for another match
          # REVISIT: we shouldn't do this until we know the whole thing matches; and then we should remove the adjectives so we re-use the same reading
                  phrase[:role] = matched[:role] || matched[:role_ref].role
                end
              end
            end

            debug :matching, "Need to try inexact match for #{inexact_phrases.inspect}" if inexact_phrases.size > 0
            inexact_players = inexact_phrases.map{|p| p[:player]}
            if (iep = inexact_players.uniq).size < inexact_players.size
              raise "Ambiguous role match for #{iep.map{|p| p.name}*', '}"
            end
            inexact_phrases.each do |phrase|
              matched = mr_phrases.detect {|mrp| mrp[:player] == phrase[:player] }
              raise "Role for #{phrase[:player].name} does not match" unless matched
              mr_phrases.delete(matched)  # We can't use this phrase for another match
              phrase[:role] = matched[:role] || matched[:role_ref].role
            end
            raise "Not enough roles to match, only #{role_phrases.map{|p| p[:player].name}*', '}" if mr_phrases.size > 0
          end
        end
      end


    end
  end
end
