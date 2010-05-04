#
# Bind terms as role references, and role references to fact types.
# The same term may participate in more then one binding.
#
# There is a number of different situations, vis:
# * Binding the identifying roles of an entity type (we know these are binary and involve the entity type)
# * Creating a fact type from the first reading of a group
# * Creating a secondary reading for a fact type
# * Referencing a fact type from a constraint with a role list (for each X, Y ...)
# * Referencing a fact type in other cases.
#
# In most cases, a role reference may contain additional adjectives not in the invoked fact type.
# Where a role reference contains a subscript, that trumps all adjectives for that object type.
# Subscripts come through as a :role_name with an Integer value.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/cql/parser'

module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      # If one of the words is the name of the entity type, and the other
      # words consist of a unary fact type reading, return the role it plays.
      # REVISIT: This probably won't handle an adjective on the entity type.
      def bind_unary_fact_type(entity_type, words)
        return nil unless i = words.index(entity_type.name)

        to_match = words.clone
        to_match[i] = '{0}'
        to_match = to_match*' '

        # See if any unary fact type of this or any supertype matches these words:
        entity_type.supertypes_transitive.each do |supertype|
          supertype.all_role.each do |role|
            role.fact_type.all_role.size == 1 &&
            role.fact_type.all_reading.each do |reading|
              if reading.text == to_match
                debug :identification, "Bound identification to unary role '#{to_match.sub(/\{0\}/, entity_type.name)}'"
                return role
              end
            end
          end
        end
        nil
      end

      # The joins list is an array of an array of fact types.
      # The fact types contain roles played by concepts, where each
      # concept plays more than one role. In fact, a concept may
      # occur in more than one binding, and each binding plays more
      # than one role. The bindings that are common to all fact types
      # in each array in the joins list form the constrained role
      # sequences. Each binding that isn't common at this top level
      # must occur more than once in each group of fact types where
      # it appears, and it forms a join between those fact types.
      def bind_joins_as_role_sequences(joins_list)
    #raise "REVISIT: bind_joins_as_role_sequences is old code, untested in multiword"
        @symbols = SymbolTable.new(@constellation, @vocabulary)
        fact_roles_list = []
        bindings_list = []
        joins_list.each_with_index do |joins, index|
          # joins is an array of phrase arrays, each for one reading
          @symbols.bind_roles_in_phrases_list(joins)

          fact_roles_list << joins.map do |phrases|
            invoked_fact_roles(phrases) or raise "Fact type reading not found for #{phrases.inspect}"
          end
          bindings_list << joins.map do |phrases|
            phrases.map{ |phrase| Hash === phrase ? phrase[:binding] : nil}.compact
          end
        end

        # Each set of binding arrays in the list must share at least one common binding
        bindings_by_join = bindings_list.map{|join| join.flatten}
        common_bindings = bindings_by_join[1..-1].inject(bindings_by_join[0]) { |c, b| c & b }
        # Was:
        # common_bindings = bindings_list.inject(bindings_list[0]) { |common, bindings| common & bindings }
        raise "Set constraints must have at least one common role between the sets" unless common_bindings.size > 0

        # REVISIT: Do we need to constrain things such that each join path only includes *one* instance of each common binding?

        # For each set of binding arrays, if there's more than one binding array in the set,
        # it represents a join path. Here we check that each join path is complete, i.e. linked up.
        # Each element of a join path is the array of bindings for a fact type invocation.
        # Each invocation must share a binding (not one of the globally common ones) with
        # another invocation in that join path.
        bindings_list.each_with_index do |join, jpnum|
          # Check that this bindings array creates a complete join path:
          join.each_with_index do |bindings, i|
            fact_type_roles = fact_roles_list[jpnum][i]
            fact_type = fact_type_roles[0].fact_type

            # The bindings are for one fact type invocation.
            # These bindings must be joined to some later fact type by a common binding that isn't a globally-common one:
            local_bindings = bindings-common_bindings
            next if local_bindings.size == 0  # No join path is required, as only one fact type is invoked.
            next if i == join.size-1   # We already checked that the last fact type invocation is joined
            ok = local_bindings.detect do |local_binding|
              j = i+1
              join[j..-1].detect do |other_bindings|
                other_fact_type_roles = fact_roles_list[jpnum][j]
                other_fact_type = other_fact_type_roles[0].fact_type
                j += 1
                # These next two lines allow joining from/to an objectified fact type:
                fact_type_roles.detect{|r| r.concept == other_fact_type.entity_type } ||
                other_fact_type_roles.detect{|r| r.concept == fact_type.entity_type } ||
                other_bindings.include?(local_binding)
              end
            end
            raise "Incomplete join path; one of the bindings #{local_bindings.inspect} must re-occur to establish a join" unless ok
          end
        end

        # Create the role sequences and their role references.
        # Each role sequence contain one RoleRef for each common binding
        # REVISIT: This results in ordering all RoleRefs according to the order of the common_bindings.
        # This for example means that a set constraint having joins might have the join order changed so they all match.
        # When you create e.g. a subset constraint in NORMA, make sure that the subset roles are created in the order of the preferred readings.
        role_sequences = joins_list.map{|r| @constellation.RoleSequence(:new) }
        common_bindings.each_with_index do |binding, index|
          role_sequences.each_with_index do |rs, rsi|
            join = bindings_list[rsi]
            fact_pos = nil
            join_pos = (0...join.size).detect do |i|
              fact_pos = join[i].index(binding)
            end
            @constellation.RoleRef(rs, index).role = fact_roles_list[rsi][join_pos][fact_pos]
          end
        end

        role_sequences
      end

      # For a given phrase array from the parser, find the matching declared reading, and return
      # the array of Role object in the same order as they occur in the reading.
      def invoked_fact_roles(phrases)
    raise "REVISIT: invoked_fact_roles is old code, untested in multiword"
        # REVISIT: Possibly this special reading from the parser can be removed now?
        if (phrases[0] == "!SUBTYPE!")
          subtype = phrases[1][:binding].concept
          supertype = phrases[2][:binding].concept
          raise "#{subtype.name} is not a subtype of #{supertype.name}" unless subtype.supertypes_transitive.include?(supertype)
          ip = inheritance_path(subtype, supertype)
          return [
            ip[-1].all_role.detect{|r| r.concept == subtype},
            ip[0].all_role.detect{|r| r.concept == supertype}
          ]
        end

        bindings = phrases.select{|p| Hash === p}
        players = bindings.map{|p| p[:binding].concept }
        invoked_fact_roles_by_players(phrases, players)
      end

      # Search the supertypes of 'subtype' looking for an inheritance path to 'supertype',
      # and returning the array of TypeInheritance fact types from supertype to subtype.
      def inheritance_path(subtype, supertype)
        direct_inheritance = subtype.all_supertype_inheritance.select{|ti| ti.supertype == supertype}
        return direct_inheritance if (direct_inheritance[0])
        subtype.all_supertype_inheritance.each{|ti|
          ip = inheritance_path(ti.supertype, supertype)
          return ip+[ti] if (ip)
        }
        return nil
      end

      def invoked_fact_roles_by_players(phrases, players)
    raise "REVISIT: invoked_fact_roles_by_players is old code, untested in multiword"
        players[0].all_role.each do |role|
          # Does this fact type have the right number of roles?
          next if role.fact_type.all_role.size != players.size

          # Does this fact type include the correct other players?
          # REVISIT: Might need subtype/supertype matching here, with an implied subtyping join invocation
          next if role.fact_type.all_role.detect{|r| !players.include?(r.concept)}

          # Oooh, a real candidate. Check the reading words.
          debug "Considering "+role.fact_type.describe do
            next unless role.fact_type.all_reading.detect do |candidate_reading|
              debug "Considering reading"+candidate_reading.text do
                to_match = phrases.clone
                players_to_match = players.clone
                candidate_reading.words_and_role_refs.each do |wrr|
                  if (wrr.is_a?(ActiveFacts::Metamodel::RoleRef))
                    break unless Hash === to_match.first
                    break unless binding = to_match[0][:binding]
                    # REVISIT: May need to match super- or sub-types here too!
                    break unless players_to_match[0] == wrr.role.concept
                    break if wrr.leading_adjective && binding.leading_adjective != wrr.leading_adjective
                    break if wrr.trailing_adjective && binding.trailing_adjective != wrr.trailing_adjective

                    # All matched.
                    to_match.shift
                    players_to_match.shift
                  # elsif # REVISIT: Match "not" and "none" here as negating the fact type invocation
                  else
                    break unless String === to_match[0]
                    break unless to_match[0] == wrr
                    to_match.shift
                  end
                end

                # This is the first matching candidate.
                # REVISIT: Since we do sub/supertype matching (and will do more!),
                # we need to accumulate all possible matches to be sure
                # there's only one, or the match is exact, or risk ambiguity.
                debug "Reading match was #{to_match.size == 0 ? "ok" : "bad"}"
                return candidate_reading.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}.map{|rr| rr.role} if to_match.size == 0
              end
            end
          end
        end

        # Hmm, that didn't work, try the subtypes of the first player.
        # When a fact type matches like this, there is an implied join to the subtype.
        players[0].subtypes.each do |subtype|
          players[0] = subtype
          fr = invoked_fact_roles_by_players(phrases, players)
          return fr if fr
        end

        # REVISIT: Do we need to do this again for the supertypes of the first player?

        nil
      end

      def bind_fact_reading(fact_type, qualifiers, phrases)
    raise "REVISIT: bind_fact_reading is old code, untested in multiword"
        reading = debug :reading, "Processing reading #{phrases.inspect}" do
          role_phrases = phrases.select do |phrase|
            Hash === phrase && phrase[:binding]
          end

          # All readings for a fact type must have the same number of roles.
          # This might be relaxed later for fact clauses, where readings might
          # be concatenated if the adjacent items are the same concept.
          if (fact_type && fact_type.all_reading.size > 0 && role_phrases.size != fact_type.all_role.size)
            raise "#{
                role_phrases.size > fact_type.all_role.size ? "Too many" : "Not all"
              } roles found for non-initial reading of #{fact_type.describe}"
          end

          # If the reading is the first and is an invocation of an existing fact type,
          # find and return the existing fact type and reading.
          if !fact_type
            bindings = role_phrases.map{|phrase| phrase[:binding]}
            bindings_by_name = bindings.sort_by{|b| [b.concept.name, b.leading_adjective||'', b.trailing_adjective||'']}
            bound_concepts_by_name = bindings_by_name.map{|b| b.concept}
            reading = nil
            first_role = nil
            debug :reading, "Looking for existing fact type to match #{phrases.inspect}" do
              first_role =
                bindings[0].concept.all_role.detect do |role|
                  next if role.fact_type.all_role.size != bindings.size       # Wrong arity
                  concepts = role.fact_type.all_role.map{|r| r.concept }
                  next unless bound_concepts_by_name == concepts.sort_by{|c| c.name}  # Wrong players
                  matching_reading =
                    role.fact_type.all_reading.detect do |reading|
                    debug :reading, "Considering #{reading.expand}"
                      reading_role_refs = reading.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}
                      reading_concepts = reading_role_refs.map{|rr| rr.role.concept}
                      elements = reading.text.scan(/\{[0-9]+\}|\w+/)
                      next false if elements.zip(phrases).detect do |element, phrase|
                        if element =~ /\A\{([0-9]+)\}\Z/    # Must be a role player; need a matching binding
                          !phrase.is_a?(Hash) or
                            !(binding = phrase[:binding]) or
                            !(role_ref = reading_role_refs[$1.to_i]) or   # If we fail here, it's an error!
                            role_ref.role.concept != binding.concept or
=begin
                            # REVISIT: This loose matching fails on the Metamodel with RingConstraints.
                            # Need "best match" semantics, or some way to know that these adjectives are "extra" to the readings.
                            (la = role_ref.leading_adjective) && binding[:leading_adjective] != la or
                            (ta = role_ref.trailing_adjective) && binding[:trailing_adjective] != ta
=end
                            role_ref.leading_adjective != binding[:leading_adjective] or
                            role_ref.trailing_adjective != binding[:trailing_adjective]
                        else
                          element != phrase
                        end
                      end
                      debug :reading, "'#{reading.expand}' matches!"
                      true     # There was no mismatch
                    end
                  matching_reading # This role was in a matching fact type!
                end
            end

            if first_role
              fact_type = first_role.fact_type

              # Remember the roles for each binding, for subsequent readings:
              reading.role_sequence.all_role_ref.each_with_index do |rr, index|
                @symbols.roles_by_binding[bindings[index]] = rr.role
              end

              return [fact_type, reading]
            end
          end

          fact_type ||= @constellation.FactType(:new)

          # Create the roles on the first reading, or look them up on subsequent readings.
          # If the player occurs twice, we must find one with matching adjectives.

          role_sequence = @constellation.RoleSequence(:new)   # RoleSequence for RoleRefs of this reading
          roles = []
          role_phrases.each_with_index do |role_phrase, index|
            binding = role_phrase[:binding]
            role_name = role_phrase[:role_name]
            player = binding.concept
            role = nil
            if (fact_type.all_reading.size == 0)           # First reading
              # Assert this role of the fact type:
              role = @constellation.Role(fact_type, fact_type.all_role.size, :concept => player)
              role.role_name = role_name if role_name
              debug "Concept #{player.name} found, created role #{role.describe} by binding #{binding.inspect}"
              @symbols.roles_by_binding[binding] = role
            else                                # Subsequent readings
              #debug "Looking for role #{binding.inspect} in bindings #{@symbols.roles_by_binding.inspect}"
              role = @symbols.roles_by_binding[binding]
              raise "Role #{binding.inspect} not found in prior readings" if !role
              player = role.concept
            end

            # Save a role value restriction
            if (ranges = role_phrase[:restriction])
              role.role_value_restriction = value_restriction(ranges, role_phrase[:restriction_enforcement])
            end

            roles << role

            # Create the RoleRefs for the RoleSequence

            role_ref = @constellation.RoleRef(role_sequence, index, :role => roles[index])
            leading_adjective = role_phrase[:leading_adjective]
            role_ref.leading_adjective = leading_adjective if leading_adjective
            trailing_adjective = role_phrase[:trailing_adjective]
            role_ref.trailing_adjective = trailing_adjective if trailing_adjective
          end

          # Create any embedded constraints:
          debug "Creating embedded presence constraints for #{fact_type.describe}" do
            create_embedded_presence_constraints(fact_type, role_phrases, roles)
          end

          process_qualifiers(role_sequence, qualifiers)

          # Save the first role sequence to be used for a default PresenceConstraint
          add_reading(fact_type, role_sequence, phrases)
        end
        [fact_type, reading]
      end

      # For each fact reading there may be embedded mandatory, uniqueness or frequency constraints:
      def create_embedded_presence_constraints(fact_type, role_phrases, roles)
    raise "REVISIT: create_embedded_presence_constraints is old code, untested in multiword"
        embedded_presence_constraints = []
        role_phrases.zip(roles).each_with_index do |role_pair, index|
          role_phrase, role = *role_pair

          next unless quantifier = role_phrase[:quantifier]

          debug "Processing embedded constraint #{quantifier.inspect} on #{role.concept.name} in #{fact_type.describe}" do
            constrained_roles = roles.clone
            constrained_roles.delete_at(index)
            constraint = find_pc_over_roles(constrained_roles)
            if constraint
              debug "Setting max frequency to #{quantifier[1]} for existing constraint #{constraint.object_id} over #{constraint.role_sequence.describe} in #{fact_type.describe}"
              raise "Conflicting maximum frequency for constraint" if constraint.max_frequency && constraint.max_frequency != quantifier[1]
              constraint.max_frequency = quantifier[1]
            else
              role_sequence = @constellation.RoleSequence(:new)
              constrained_roles.each_with_index do |constrained_role, i|
                role_ref = @constellation.RoleRef(role_sequence, i, :role => constrained_role)
              end
              constraint = @constellation.PresenceConstraint(
                  :new,
                  :vocabulary => @vocabulary,
                  :role_sequence => role_sequence,
                  :is_mandatory => quantifier[0] && quantifier[0] > 0,  # REVISIT: Check "maybe" qualifier?
                  :max_frequency => quantifier[1],
                  :min_frequency => quantifier[0]
                )
              embedded_presence_constraints << constraint
              debug "Made new PC min=#{quantifier[0].inspect} max=#{quantifier[1].inspect} constraint #{constraint.object_id} over #{(e = fact_type.entity_type) ? e.name : role_sequence.describe} in #{fact_type.describe}"
            end
          end
        end
        @symbols.embedded_presence_constraints += embedded_presence_constraints
      end

      def process_qualifiers(role_sequence, qualifiers)
    raise "REVISIT: process_qualifiers is old code, untested in multiword"
        return unless qualifiers.size > 0
        qualifiers.sort!

        # Process the ring constraints:
        ring_constraints, qualifiers = qualifiers.partition{|q| RingTypes.include?(q) }
        unless ring_constraints.empty?
          # A Ring may be over a supertype/subtype pair, and this won't find that.
          role_refs = Array(role_sequence.all_role_ref)
          role_pairs = []
          player_supertypes_by_role = role_refs.map{|rr|
              concept = rr.role.concept
              concept.is_a?(ActiveFacts::Metamodel::EntityType) ? supertypes(concept) : [concept]
            }
          role_refs.each_with_index{|rr1, i|
            player1 = rr1.role.concept
            (i+1...role_refs.size).each{|j|
              rr2 = role_refs[j]
              player2 = rr2.role.concept
              if player_supertypes_by_role[i] - player_supertypes_by_role[j] != player_supertypes_by_role[i]
                role_pairs << [rr1.role, rr2.role]
              end
            }
          }
          raise "ring constraint (#{ring_constraints*" "}) role pair not found" if role_pairs.size == 0
          raise "ring constraint (#{ring_constraints*" "}) is ambiguous over roles of #{role_pairs.map{|rp| rp.map{|r| r.concept.name}}.inspect}" if role_pairs.size > 1
          roles = role_pairs[0]

          # Ensure that the keys in RingPairs follow others:
          ring_constraints = ring_constraints.partition{|rc| !RingPairs.keys.include?(rc.downcase.to_sym) }.flatten

          if ring_constraints.size > 1 and !RingPairs[ring_constraints[-1].to_sym].include?(ring_constraints[0].to_sym)
            raise "incompatible ring constraint types (#{ring_constraints*", "})"
          end
          ring_type = ring_constraints.map{|c| c.capitalize}*""

          ring = @constellation.RingConstraint(
              :new,
              :vocabulary => @vocabulary,
          #   :name => name,              # REVISIT: Create a name for Ring Constraints?
              :role => roles[0],
              :other_role => roles[1],
              :ring_type => ring_type
            )

          debug "Added #{ring.verbalise} #{ring.class.roles.keys.map{|k|"#{k} => "+ring.send(k).verbalise}*", "}"
        end

        return unless qualifiers.size > 0

        # Process the remaining qualifiers:
        puts "REVISIT: Qualifiers #{qualifiers.inspect} over #{role_sequence.describe}"
      end

      def add_reading(fact_type, role_sequence, phrases)
    raise "REVISIT: add_reading is old code, untested in multiword"
        ordinal = (fact_type.all_reading.map(&:ordinal).max||-1) + 1  # Use the next unused ordinal
        reading = @constellation.Reading(fact_type, ordinal, :role_sequence => role_sequence)
        role_num = -1
        reading.text = phrases.map {|phrase|
            Hash === phrase ? "{#{role_num += 1}}" : phrase
          }*" "
        raise "Wrong number of players (#{role_num+1}) found in reading #{reading.text} over #{fact_type.describe}" if role_num+1 != fact_type.all_role.size
        debug "Added reading #{reading.text}"
        reading
      end

      # Return an array of this entity type and all its supertypes, transitively:
      def supertypes(o)
        ([o] + o.all_supertype_inheritance.map{|ti| supertypes(ti.supertype)}.flatten).uniq
      end

      class SymbolTable #:nodoc:all
        # Externally built tables used in this binding context:
        attr_reader :roles_by_binding
        attr_accessor :embedded_presence_constraints
        attr_accessor :allowed_forward
        attr_reader :constellation
        attr_reader :vocabulary
        attr_reader :bindings_by_concept
        attr_reader :role_names

        # A Binding here is a form of reference to a concept, being a name and optional adjectives, possibly designated by a role name:
        Binding = Struct.new("Binding", :concept, :name, :leading_adjective, :trailing_adjective, :role_name)
        class Binding
          def inspect
            "Binding(#{concept.class.basename} #{concept.name}, #{[leading_adjective, name, trailing_adjective].compact*"-"}#{role_name ? " (as #{role_name})" : ""})"
          end

          # Any ordering works to allow a hash to be keyed by a set (unordered array) of Bindings:
          def <=>(other)
            object_id <=> other.object_id
          end
        end

        def initialize(constellation, vocabulary)
          @constellation = constellation
          @vocabulary = vocabulary
          @bindings_by_concept = Hash.new {|h, k| h[k] = [] }  # Indexed by Binding#name, maybe multiple entries for each name
          @bindings = {}  # Indexed by term with adjectives

          @embedded_presence_constraints = []
          @roles_by_binding = {}   # Build a hash of allowed bindings on first reading (check against it on subsequent ones)
          @allowed_forward = {} # No roles may be forward-referenced
        end

        # return the EntityType or ValueType this name refers to:
        def concept(name)
          # See if the name is a defined concept in this vocabulary:
          player = @constellation.Concept[[virv = @vocabulary.identifying_role_values, name]]

          # REVISIT: Hack to allow facts to refer to standard types that will be imported from standard vocabulary:
          if !player && %w{Date DateAndTime Time}.include?(name)
            player = @constellation.ValueType(virv, name)
          end

          if !player && @allowed_forward[name] 
            player = @constellation.EntityType(@vocabulary, name)
          end

          player
        end

        def bind_roles_in_clauses(clauses, identification = [])
    raise "REVISIT: bind_roles_in_clauses is old code, untested in multiword"
          identification ||= []
          bind_roles_in_phrases_list(
              clauses.map{|clause| clause[2]},    # Extract the phrases
              single_word_identifiers = identification.map{|i| i.size == 1 ? i[0] : nil}.compact.uniq
            )
        end

        #
        # Walk through all phrases identifying role players.
        # Each role player phrase gets a :binding key added to it.
        #
        # Any adjectives that the parser didn't recognise are merged with their players here,
        # as long as they're indicated as adjectives of that player somewhere in the readings.
        #
        # Other words are turned from phrases (hashes) into simple strings.
        #
        def bind_roles_in_phrases_list(phrases_list, allowed_forwards = [])
    raise "REVISIT: bind_roles_in_phrases_list is old code, untested in multiword"
          phrases_list.each do |phrases|
            debug :bind, "Binding phrases"

            # Bind role name phrases first, so we can identify them later:
            phrases.each do |phrase|
              next unless phrase.is_a?(Hash) and rn = phrase[:role_name]
              w = phrase[:word]
              raise "Definition of role name #{rn} isn't allowed to have adjectives: #{w}" if w != phrase[:term]
              player = concept(w)

              @bindings_by_concept[w] <<
                @bindings[rn] = Binding.new(player, w, nil, nil, rn)
            end

            phrases.each do |phrase|
              next if !phrase.is_a?(Hash) or phrase[:binding]
              term = phrase[:term]      # This is the name of the object type
              word = phrase[:word]      # This is the term with any adjectives

              if b = (@bindings[term] || @bindings[word])
                # This term is already bound
                phrase[:binding] = b
                next
              end

              la = phrase[:leading_adjective]
              ta = phrase[:trailing_adjective]
              allowed_forward = allowed_forwards.include?(term)

              # all_players = @constellation.Name[[term]] # This contains all concepts having this name (from other vocabularies)
              player = concept(term)
              unless player
                debugger
                raise "REVISIT: Something went wrong"
              end

              @bindings_by_concept[term] <<
                @bindings[term] =
                phrase[:binding] = Binding.new(player, term, la, ta, phrase[:role_name])
            end
            debug :bind, "Bound phrases: #{phrases.inspect}"
          end
        end

        def bind(phrase)  # Phrase is an array of words constituting a role reference
    raise "REVISIT: bind is old code, untested in multiword"
          # Normal case: The phrase is already bound
          if binding = @bindings[phrase*" "]
            return [binding.concept, binding]
          end

          if phrase.size == 1
            term = phrase[0]
            player = concept(term)
            @bindings_by_concept[term] <<
              @bindings[term] =
              phrase[:binding] =
              binding = Binding.new(player, term)
            return [player, binding]
          end

          debugger
          p phrase  # bind called but incompletely implemented
          raise "REVISIT: Not implemented; binding by multiple words"
        end

      end # of SymbolTable class

    end
  end
end
