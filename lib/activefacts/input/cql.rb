#
# Compile a CQL file into an ActiveFacts vocabulary.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/cql/parser'

require 'ruby-debug'

module ActiveFacts
  module Input
    class CQL
      include ActiveFacts
      include ActiveFacts::Metamodel

      RingTypes = %w{acyclic intransitive symmetric asymmetric transitive antisymmetric irreflexive reflexive}
      RingPairs = {
          :intransitive => [:acyclic, :asymmetric, :symmetric],
          :irreflexive => [:symmetric]
        }

      # Open the specified file and read it:
      def self.readfile(filename)
        File.open(filename) {|file|
          self.read(file, filename)
        }
      rescue => e
        puts e.message+"\n\t"+e.backtrace*"\n\t" if debug :exception
        raise "In #{filename} #{e.message.strip}"
      end

      # Read the specified input stream:
      def self.read(file, filename = "stdin")
        CQL.new(file.read, filename).read
      end 

      def initialize(file, filename = "stdin")
        @file = file
        @filename = filename
      end

      # Read the input, returning a new Vocabulary:
      def read
        @constellation = Constellation.new(ActiveFacts::Metamodel)

        @parser = ActiveFacts::CQLParser.new

        # The syntax tree created from each parsed CQL statement gets passed to the block.
        # parse_all returns an array of the block's non-nil return values.
        result = @parser.parse_all(@file, :definition) do |node|
            begin
              kind, *value = @parser.definition(node)
              #print "Parsed '#{node.text_value}'"
              #print " to "; p value
              raise "Definitions must be in a vocabulary" if kind != :vocabulary and !@vocabulary
              case kind
              when :vocabulary
                @vocabulary = @constellation.Vocabulary(value[0], nil)
              when :data_type
                value_type *value
              when :entity_type
                entity_type *value
              when :fact_type
                fact_type *value
              else
                print "="*20+" unhandled declaration type: "; p kind
              end
            rescue => e
              puts e.message+"\n\t"+e.backtrace*"\n\t" if debug :exception
              start_line = @file.line_of(node.interval.first)
              end_line = @file.line_of(node.interval.last-1)
              lines = start_line != end_line ? "s #{start_line}-#{end_line}" : " #{start_line.to_s}"
              raise "at line#{lines} #{e.message.strip}"
            end

            nil
          end
        raise @parser.failure_reason unless result
        @vocabulary
      end

      def value_type(name, base_type_name, parameters, unit, ranges)
        length, scale = *parameters

        # Create the base type:
        base_type = nil
        if (base_type_name != name)
          unless base_type = @constellation.ValueType[[@constellation.Name(base_type_name), @vocabulary]]
            #puts "REVISIT: Creating base ValueType #{base_type_name} in #{@vocabulary.inspect}"
            base_type = @constellation.ValueType(base_type_name, @vocabulary)
            return if base_type_name == name
          end
        end

        # Create and initialise the ValueType:
        vt = @constellation.ValueType(name, @vocabulary)
        vt.supertype = base_type if base_type
        vt.length = length if length
        vt.scale = scale if scale

        # REVISIT: Find and apply the units

        if ranges.size != 0
          vt.value_restriction = @constellation.ValueRestriction(:new)
          ranges.each do |range|
            min, max = Array === range ? range : [range, range]
            v_range = @constellation.ValueRange(
              min ? [min.to_s, true] : nil,
              max ? [max.to_s, true] : nil
              )
            ar = @constellation.AllowedRange(v_range, vt.value_restriction)
          end
        end
      end

      def entity_type(name, supertypes, identification, clauses)
        #puts "Entity Type #{name}, supertypes #{supertypes.inspect}, id #{identification.inspect}, clauses = #{clauses.inspect}"
        debug :entity, "Defining Entity Type #{name}" do
          # Assert the entity:
          # If this entity was forward referenced, this new object subsumes its roles
          entity_type = @constellation.EntityType(name, @vocabulary)

          # Set up its supertypes:
          supertypes.each do |supertype_name|
            debug :supertype, "Supertype #{supertype_name}"
            supertype = @constellation.EntityType(supertype_name, @vocabulary)
            inheritance_fact = @constellation.TypeInheritance(entity_type, supertype, :fact_type_id => :new)
            if !identification && supertype_name == supertypes[0]
              inheritance_fact.provides_identification = true
            end
          end

          # Use a two-pass algorithm for entity fact types...
          # First sort all readings according to what fact they belong to,
          # then process each fact type using code for normal fact type processing.
          # That way if we find only one fact type here with none of the players being the
          # entity type, we know it's an objectified fact type. The CQL syntax might make
          # us come here with such a case when the fact type is a subtype of some entity type,
          # such as occurs in the Metamodel with TypeInheritance.

          # Process the entity type clauses (fact type readings)
          identifying_roles = []  # In whatever order they're constructed

          @roles_by_form = {}  # Build a hash of allowed forms on first reading (check against it on subsequent ones)
          @roles_by_role_name = {}  # Build a hash of defined role_names
          @role_name_definitions = {}
          # REVISIT: This doesn't allow identification by roles with adjectives (see the i[0]):
          @allowed_forward = identification ? identification[:roles].inject({}){|h, i| h[i[0]] = true; h} : {}
          clauses_by_fact_type(clauses).each do |clauses_for_fact_type|
            fact_type = nil
            @embedded_presence_constraints = []
            debug "New Fact Type for entity #{name}" do
              clauses_for_fact_type.each do |clause|
                type, qualifiers, phrases = *clause
                debug :reading, "Clause: #{clause.inspect}" do
                  f = process_fact_clause(fact_type, qualifiers, phrases)
                  fact_type ||= f
                end
              end
            end

            # Find the role that this entity type plays in the fact type:
            if player_role = fact_type.all_role.detect{|role| role.concept == entity_type }
              non_player_roles = fact_type.all_role-[player_role]

              raise "#{name} cannot be identified by a role in a non-binary fact type" if non_player_roles.size > 1
              # N.B. Append player_role here for a unary fact type, a special case
              identifying_role = (non_player_roles[0] || player_role)
              identifying_roles << identifying_role
            elsif identification
              # This situation occurs when an objectified fact type has an entity identifier
              raise "Entity type #{name} may only objectify a single fact type" if entity_type.fact_type

              # Associate the fact type with this entity
              entity_type.fact_type = fact_type
              fact_type_identification(fact_type, name, false)
            else
              # it's an objectified fact type, such as a subtype
              entity_type.fact_type = fact_type
            end
          end

          # Finally, create the identifying uniqueness constraint, or mark it as preferred
          # if it's already been created. The identifying roles have been defined already.
          if identification
            debug :identification, "Handling identification" do
              if id_role_names = identification[:roles]  # A list of identifying roles
                id_role_names.each do |id_role_name|
                  # Each identifying role is an array of words (adjectives and concept names)
                  debug "Identifying role: #{id_role_name.inspect}"
                end

                pc = find_pc_over_roles(identifying_roles)
                if (pc)
                  debug "Existing PC #{pc.verbalise} is now PK for #{name} #{pc.class.roles.keys.map{|k|"#{k} => "+pc.send(k).verbalise}*", "}"
                  pc.is_preferred_identifier = true
                  pc.name = "#{name}PK" unless pc.name
                else
                  debug "Adding PK for #{name} using #{identifying_roles.map{|r| r.concept.name}.inspect}"

                  role_sequence = @constellation.RoleSequence(:new)
                  # REVISIT: Need to sort the identifying_roles to match the identification parameter array
                  identifying_roles.each_with_index do |identifying_role, index|
                    @constellation.RoleRef(role_sequence, index, :role => identifying_role)
                  end

                  # Add a unique constraint over all identifying roles
                  pc = @constellation.PresenceConstraint(
                      :new,
                      :vocabulary => @vocabulary,
                      :name => "#{name}PK",            # Is this a useful name?
                      :role_sequence => role_sequence,
                      :is_preferred_identifier => true,
                      :max_frequency => 1              # Unique
                      #:is_mandatory => true,
                      #:min_frequency => 1,
                    )
                end

              elsif identification[:mode]
                mode = identification[:mode]        # An identification mode
                raise "Identification modes aren't yet implemented"
              end
            end
          else
            # identification must be inherited.
            debug "Identification is inherited"
          end
        end
      end

      def fact_type(name, readings, clauses) 
        debug "Processing readings for fact type" do
          fact_type = nil
          @embedded_presence_constraints = []
          @roles_by_form = {}  # Build a hash of allowed forms on first reading (check against it on subsequent ones)
          @roles_by_role_name = {}  # Build a hash of defined role_names
          @role_name_definitions = {}
          @allowed_forward = {}
          readings.each do |reading|
            kind, qualifiers, phrases = *reading

            fact_type = process_fact_clause(fact_type, qualifiers, phrases)
          end

          # The fact type has a name iff it's objectified as an entity type
          fact_type.entity_type = @constellation.EntityType(name, @vocabulary) if name

          # Add the identifying PresenceConstraint for this fact type:
          if fact_type.all_role.size == 1
            # All is well, unaries don't need an identifying PC even if objectified
          else
            fact_type_identification(fact_type, name, true)
          end

          # REVISIT: Process the fact derivation clauses, if any
        end
      end

      def process_fact_clause(fact_type, qualifiers, phrases)
        debug "="*80
        debug :reading, "Processing reading #{phrases.inspect}" do
          # Index the role name definitions:
          phrases.each do |phrase|
            next unless role_name = phrase[:role_name]
            @role_name_definitions[role_name] = phrase
          end

          # Extract the phrases that contain role players:
          role_phrases = phrases.map do |phrase|
            player_name = phrase[:player]
            concept_by_name(player_name) ? phrase : nil
          end.compact
          debug "Role phrases(#{role_phrases.size}): #{role_phrases.inspect}"

          if (fact_type && fact_type.all_reading.size > 0 && role_phrases.size != fact_type.all_role.size)
            raise "Not all roles found for non-initial reading of #{fact_type.describe}"
          end

          # Extract the names of the role players from the role_phrases
          player_names = role_phrases.map do |role_phrase|
            role_phrase[:player]
          end

          # Extract the adjectival forms used with each player:
          player_forms = role_phrases.map do |role_phrase|
            [role_phrase[:leading_adjective], role_phrase[:player], role_phrase[:trailing_adjective]]
          end

          # REVISIT: If the first reading is a re-iteration of an existing fact type, use the existing one

          fact_type ||= @constellation.FactType(:new)

          # Create the roles on the first reading, or look them up on subsequent readings.
          # If the player occurs twice, we must find one with matching adjectives.

          duplicate_player_names = player_names.inject({}){|h,e| h[e]||=0; h[e] += 1; h}.reject{|k,v| v == 1}.keys

          players = []        # Concept objects by position in this reading
          roles = []          # Roles objects by position in this reading
          role_sequence = @constellation.RoleSequence(:new)   # RoleSequence for RoleRefs of this reading
          player_names.each_with_index do |player_name, index|
            role_phrase = role_phrases[index]   # The input phrase object from the parser
            player_form = player_forms[index]   # The adjectival form for this phrase
            role_name = role_phrase[:role_name]

            debug "Processing phrase #{index} '#{role_phrase.inspect}' form '#{player_form.inspect}' #{role_name.inspect}" do
              player = concept_by_name(player_name)

              if (fact_type.all_reading.size == 0)           # First reading
                raise "Concept '#{player_name}' is not yet defined" unless player

                # Assert this role of the fact type:
                debug "Concept #{player.name} found, creating role"
                role = @constellation.Role(:new, :fact_type => fact_type, :concept => player)
                role.role_name = role_name if role_name
                debug "Role is: "+role.describe
                @roles_by_form[player_form] = role
              else                                # Subsequent readings
                role = @roles_by_form[player_form] || @roles_by_role_name[player_name]
                if !role
                  # Ensure that there is no ambiguity with players and adjectives.
                  # A player that occurs more than once in the same reading must
                  # have the same adjectives in all readings.
                  # REVISIT: Possibly relax this if the other duplicates are all matched exactly.
                  if duplicate_player_names.include?(player_name)    # a duplicated player?
                    debug "Duplicate player using an unknown adjectival form"
                    raise "Role '#{player_form.compact*'-'}' is ambiguous amongst #{@roles_by_form.keys.map{|k| k.compact*"-"}*", "}}"
                  else
                    # Second try; just match the player
                    debug "Looking for #{player_name.inspect} in #{roles.map(&:concept).map(&:name).inspect}"
                    role = fact_type.all_role.detect{|r| r.concept == player }
                    raise "Role '#{player_form.compact*' '}' doesn't exist in primary reading" unless role
                  end
                  player = role.concept
                #else
                #  debug "Got role by form #{@roles_by_form[player_form].inspect} || #{@roles_by_role_name[player_name].inspect}"
                end
              end
              players << player
              roles << role
              @roles_by_role_name[role_name] = role if role_name

              # Create the RoleRefs for the RoleSequence
              leading_adjective = role_phrase[:leading_adjective]
              trailing_adjective = role_phrase[:trailing_adjective]

              role_ref = @constellation.RoleRef(role_sequence, index, :role => roles[index])
              role_ref.leading_adjective = leading_adjective if leading_adjective
              role_ref.trailing_adjective = trailing_adjective if trailing_adjective
            end
          end

          # Create any embedded constraints:
          debug "Creating embedded presence constraints for #{fact_type.describe}" do
            create_embedded_presence_constraints(fact_type, role_phrases, roles)
          end

          process_qualifiers(role_sequence, qualifiers)

          # Save the first role sequence to be used for a default PresenceConstraint
          add_reading(fact_type, role_sequence, phrases)
        end
        fact_type
      end

      def fact_type_identification(fact_type, name, prefer)
        if @embedded_presence_constraints.empty?
          first_role_sequence = fact_type.all_reading[0].role_sequence
          identifier = @constellation.PresenceConstraint(
              :new,
              :vocabulary => @vocabulary,
              :name => "#{name}PK",            # Is this a useful name?
              :role_sequence => first_role_sequence,
              :is_preferred_identifier => prefer,
              :max_frequency => 1              # Unique
            )
          debug "Made default fact type identifier #{identifier.object_id} over #{first_role_sequence.describe} in #{fact_type.describe}"
        elsif prefer
          #debug "Made fact type identifier #{identifier.object_id} preferred over #{@embedded_presence_constraints[0].role_sequence.describe} in #{fact_type.describe}"
          @embedded_presence_constraints[0].is_preferred_identifier = true
        end
      end

      # Categorise the fact type clauses according to the set of role player names
      # Return an array where each element is an array of clauses, the clauses having
      # matching players, and otherwise preserving the order of definition.
      def clauses_by_fact_type(clauses)
        clause_group_by_role_players = {}
        clauses.inject([]) do |clause_groups, clause|
          type, qualifiers, phrases = *clause

          debug "Clause: #{clause.inspect}"
          role_phrases = phrases.map do |phrase|
            concept_by_name(phrase[:player]) ? phrase : nil
          end.compact
          debug "Role phrases(#{role_phrases.size}): #{role_phrases.inspect}"

          player_forms = role_phrases.map do |role_phrase|
            [role_phrase[:leading_adjective], role_phrase[:player], role_phrase[:trailing_adjective]].compact
          end

          # Look for an existing clause group involving these players, or make one:
          clause_group = clause_group_by_role_players[player_forms.sort]
          if clause_group     # Another clause for an existing clause group
            clause_group << clause
          else                # A new clause group
            clause_groups << clause_group_by_role_players[player_forms.sort] = [clause]
          end
          clause_groups
        end
      end

      # For each fact reading there may be embedded mandatory, uniqueness or frequency constraints:
      def create_embedded_presence_constraints(fact_type, role_phrases, roles)
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
                  :is_mandatory => quantifier[0] && quantifier[0] > 0,
                  :max_frequency => quantifier[1],
                  :min_frequency => quantifier[0]
                )
              embedded_presence_constraints << constraint
              debug "Made new PC min=#{quantifier[0].inspect} max=#{quantifier[1].inspect} constraint #{constraint.object_id} over #{(e = fact_type.entity_type) ? e.name : role_sequence.describe} in #{fact_type.describe}"
            end
          end
        end
        @embedded_presence_constraints ||= []
        @embedded_presence_constraints += embedded_presence_constraints
      end

      def find_pc_over_roles(roles)
        return nil if roles.size == 0 # Safeguard; this would create a Role with a nil role_id
        @constellation.Role(roles[0]).all_role_ref.each do |role_ref|
          next if role_ref.role_sequence.all_role_ref.map(&:role) != roles
          pc = role_ref.role_sequence.all_presence_constraint[0]
          #puts "Existing PresenceConstraint matches those roles!" if pc
          return pc if pc
        end
        nil
      end

      def add_reading(fact_type, role_sequence, phrases)
        ordinal = (fact_type.all_reading.map(&:ordinal).max||-1) + 1  # Use the next unused ordinal
        reading = @constellation.Reading(fact_type, ordinal, :role_sequence => role_sequence)
        role_num = -1
        reading.reading_text = phrases.map {|phrase|
            player_name = phrase[:player]
            concept_by_name(player_name) ? "{#{role_num += 1}}" : player_name
          }*" "
        debug "Added reading #{reading.reading_text}"
      end

=begin
      def is_supertype(sup, sub)
        # puts "Deciding whether #{sup.name} < #{sub.name}"
        return true if sup == sub
        sup.all_type_inheritance_by_supertype.each {|ti|
            return true if is_supertype(ti.subtype, sub)
          }
        false
      end
=end

      # Return an array of this entity type and all its supertypes, transitively:
      def supertypes(o)
        ([o] + o.all_type_inheritance_by_subtype.map{|ti| supertypes(ti.supertype)}.flatten).uniq
      end

      def concept_by_name(name)
        if (d = @role_name_definitions[name] and
            !d[:leading_adjective] and !d[:trailing_adjective]) # Adjectives not allowed on role names
          name = d[:player]
        end
        player = @constellation.Concept[[name, @vocabulary.identifying_role_values]]

        # REVISIT: Hack to allow facts to refer to standard types that will be imported from standard vocabulary:
        if !player && %w{Date DateAndTime}.include?(name)
          player = @constellation.ValueType(name, @vocabulary.identifying_role_values)
        end

        if (!player && @allowed_forward[name])
          player = @constellation.EntityType(name, @vocabulary)
        end
        player
      end

      def process_qualifiers(role_sequence, qualifiers)
        return unless qualifiers.size > 0
        qualifiers.sort!

        # Process the ring constraints:
        ring_constraints, qualifiers = qualifiers.partition{|q| RingTypes.include?(q) }
        unless ring_constraints.empty?
          # A Ring may be over a supertype/subtype pair, and this won't find that.
          role_refs = role_sequence.all_role_ref
          role_pairs = []
          player_supertypes_by_role = role_refs.map{|rr|
              concept = rr.role.concept
              EntityType === concept ? supertypes(concept) : [concept]
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

    end
  end
end
