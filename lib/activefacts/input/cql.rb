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
      include ActiveFacts::Metamodel

      # Open the specified file and read it:
      def self.readfile(filename)
        File.open(filename) {|file|
          self.read(file, filename)
        }
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
        result = @parser.parse_all(@file, :definition) { |node|
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

            nil
          }
        raise @parser.failure_reason unless result
        @vocabulary
      end

      def value_type(name, base_type_name, parameters, unit, ranges)
        length, scale = *parameters

        # Create the base type:
        unless base_type = @constellation.ValueType[[@constellation.Name(base_type_name), @vocabulary]]
          #puts "REVISIT: Creating base ValueType #{base_type_name} in #{@vocabulary.inspect}"
          base_type = @constellation.ValueType(base_type_name, @vocabulary)
          return if base_type_name == name
        end

        # Create and initialise the ValueType:
        vt = @constellation.ValueType(name, @vocabulary)
        vt.supertype = base_type
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
        debug "Defining Entity Type #{name}" do
          # Assert the entity:
          # REVISIT: If this entity was forward referenced, this new object subsumes its roles
          et = @constellation.EntityType(name, @vocabulary)

          # Set up its supertypes:
          supertypes.each do |supertype_name|
            debug "Supertype #{supertype_name}"
            supertype = @constellation.EntityType(supertype_name, @vocabulary)
            inheritance_fact = @constellation.TypeInheritance(et, supertype, :fact_type_id => :new)
            if !identification && supertype_name == supertypes[0]
              inheritance_fact.provides_identification = true
            end
          end

          # Process the entity type clauses (fact type readings)
          defined_facts_by_role_players = {}
          identifying_roles = []  # In whatever order they're constructed
          clauses.each do |clause|
            type, qualifiers, phrases = *clause
            debug "Clause: #{clause.inspect}"
            role_phrases = phrases.map do |phrase|
              Hash === phrase ? phrase : nil
            end.compact
            debug "Role phrases(#{role_phrases.size}): #{role_phrases.inspect}"

            player_forms = role_phrases.map do |role_phrase|
              [role_phrase[:leading_adjective], role_phrase[:player], role_phrase[:trailing_adjective]].flatten.compact
            end

            # Look for an existing fact type involving these players, or make one:
            fact_type = defined_facts_by_role_players[player_forms.sort]
            is_new_fact_type = false
            unless fact_type
              is_new_fact_type = true
              debug "Making new fact type for (#{player_forms.sort*", "})" do
                fact_type = @constellation.FactType(:new)
                defined_facts_by_role_players[player_forms.sort] = fact_type

                # Add the FactType's Roles:
                player_role = nil
                non_player_roles = []
                role_phrases.each do |role_phrase|
                  player_name = role_phrase[:player]
                  player = @constellation.Concept[[player_name, @vocabulary.identifying_role_values]]

                  # Handle a forward-referenced entity type as an identifying role:
                  player = @constellation.EntityType(player_name, @vocabulary) unless player

                  role = @constellation.Role(:new, :fact_type => fact_type, :concept => player)
                  role_name = role_phrase[:role_name]
                  role.role_name = role_name if role_name

                  debug "Added #{role.verbalise} #{role.class.roles.keys.map{|k|"#{k} => "+role.send(k).verbalise}*", "}"

                  if player == et
                    player_role = role
                  else
                    non_player_roles << role
                  end
                end

                if non_player_roles.size == role_phrases.size-1
                  raise "#{name} cannot be identified by a role in a non-binary fact type" if non_player_roles.size > 1
                  # N.B. We append player_role here for a unary fact type, a special case
                  identifying_role = (non_player_roles[0] || player_role)
                  identifying_roles << identifying_role
                else non_player_roles.size == role_phrases.size
                  raise "Irrelevant fact in identification of '#{name}'"
                end
              end
            else
              debug "Proceeding with existing fact type for (#{player_forms.sort*", "})"
            end
            # End of the entity fact types

            # Create the role references and a role sequence:
            # REVISIT: Find an existing RoleSequence if sequence and adjectives match, don't make a new one:
            role_sequence = @constellation.RoleSequence(:new)
            roles = []
            role_phrases.each_with_index do |role_phrase, index|
              player_name = role_phrase[:player]
              leading_adjective = role_phrase[:leading_adjective]
              leading_adjective = leading_adjective*" " if leading_adjective
              trailing_adjective = role_phrase[:trailing_adjective]
              trailing_adjective = trailing_adjective*" " if trailing_adjective

              # REVISIT: This doesn't cope when player_name is a role name.
              # However I think that should be resolved in the CQLParser, since it
              # builds a list of all role names defined in this definition, and can
              # traverse it to assign actual player names on the references.

              candidate_roles = fact_type.all_role.select{|r| r.concept.name == player_name }
              if candidate_roles.size > 1 && !is_new_fact_type
                # The same player plays more than one role in this fact type.
                # Match them up with an existing role by adjectives on a role
                # in any role sequence (except this) of a reading of that fact type.
                role = nil
                role_refs = fact_type.all_reading.map{|reading|
                    reading.role_sequence.all_role_ref
                  }.flatten.select{|rr|
                    rr.role.concept.name == player_name
                  }
                role_refs.each{|rr|
                    break (role = rr.role) if leading_adjective == rr.leading_adjective && trailing_adjective == rr.trailing_adjective
                  }
                raise "Role '#{[leading_adjective, player_name, trailing_adjective].compact*" "}' doesn't match any existing role" unless role
              else
                role = candidate_roles[0]
              end
              roles << role

              role_ref = @constellation.RoleRef(role_sequence, index, :role => role)
              role_ref.leading_adjective = leading_adjective if leading_adjective
              role_ref.trailing_adjective = trailing_adjective if trailing_adjective
            end

            create_embedded_presence_constraints(fact_type, role_phrases, roles)

            # Add the reading:
            add_reading(fact_type, role_sequence, phrases)
          end

          # Finally, create the identifying uniqueness constraint, or mark it as preferred
          # if it's already been created. The identifying roles have been defined already.
          if identification
            debug "Handling identification" do
              if id_role_names = identification[:roles]  # A list of identifying roles
                id_role_names.each do |id_role_name|
                  # Each identifying role is an array of words (adjectives and concept names)
                  debug "Identifying role: #{id_role_name.inspect}"
                end

                pc = find_pc_over_roles(identifying_roles)
                if (pc)
                  debug "Existing PC is now PK #{pc.verbalise} #{pc.class.roles.keys.map{|k|"#{k} => "+pc.send(k).verbalise}*", "}"
                  pc.is_preferred_identifier = true
                  pc.name = "#{name}PK" unless pc.name
                else
                  debug "Adding PK using #{identifying_roles.map{|r| r.concept.name}.inspect}"

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

      # For each fact reading there may be embedded mandatory, uniqueness or frequency constraints:
      def create_embedded_presence_constraints(fact_type, role_phrases, roles)
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
              debug "Made new UC/FC=#{quantifier.inspect} constraint #{constraint.object_id} over #{role_sequence.describe} in #{fact_type.describe}"
            end
          end
        end
      end

      def find_pc_over_roles(roles)
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
            Hash === phrase ? "{#{role_num += 1}}" : phrase
          }*" "
        debug "Added reading #{reading.reading_text}"
      end

      def fact_type(name, readings, clauses) 
        fact_type = @constellation.FactType(:new)

        # The fact type has a name iff it's objectified as an entity type
        fact_type.entity_type = @constellation.EntityType(name, @vocabulary) if name

        debug "Processing readings for new fact type" do
          fact_type_forms = nil
          readings.each do |reading|
            kind, qualifiers, phrases = *reading

            debug "Processing reading #{phrases.inspect}" do
              # Extract the phrases that contain role players:
              role_phrases = phrases.map do |phrase|
                Hash === phrase ? phrase : nil
              end.compact
              debug "Role phrases(#{role_phrases.size}): #{role_phrases.inspect}"

              # Extract the names of the role players from the role_phrases
              player_names = role_phrases.map do |role_phrase|
                role_phrase[:player]
              end

              # Extract the adjectival forms used with each player:
              player_forms = role_phrases.map do |role_phrase|
                [role_phrase[:leading_adjective], role_phrase[:player], role_phrase[:trailing_adjective]]
              end

              # Ensure that there is no ambiguity with players and adjectives.
              # A player that occurs more than once in the same reading must
              # have the same adjectives in all readings.
              if (up = player_names.uniq.size) < player_names.size
                duplicate_player_names = player_names.inject({}){|h,e| h[e]||=0; h[e] += 1; h}.reject{|k,v| v == 1}.keys
                forms = nil  # Build allowed forms
                player_names.each_with_index do |player_name, index|
                  next unless duplicate_player_names.include?(player_name)    # Not a duplicated player
                  form = player_forms[index]
                  if fact_type_forms    # A subsequent reading, check
                    raise "Role '#{form.compact*' '}' is ambiguous" unless fact_type_forms[form]
                  else                  # The first reading, create
                    (forms ||= {})[form] = true
                  end
                end
                fact_type_forms = forms if forms  # Record the allowed forms for subsequent readings
              end

              # Look up each concept that plays a role:
              players = player_names.map do |player_name|
                player = @constellation.Concept[[player_name, @vocabulary.identifying_role_values]]
                raise "Concept '#{player_name}' is not yet defined" unless player
                player
              end

              roles = []
              debug "Found all players for this reading, creating roles:" do
                # Assert the roles of this fact type, in the correct order for this reading
                players.each_with_index do |player, index|
                  role = @constellation.Role(:new, :fact_type => fact_type, :concept => player)
                  role_name = role_phrases[index][:role_name]
                  role.role_name = role_name if role_name
                  debug role.describe
                  roles << role
                end
              end

              # Create the RoleSequence and the reading:
              role_sequence = @constellation.RoleSequence(:new)
              role_phrases.each_with_index do |role_phrase, index|
                player_name = role_phrase[:player]
                leading_adjective = role_phrase[:leading_adjective]
                leading_adjective = leading_adjective*" " if leading_adjective
                trailing_adjective = role_phrase[:trailing_adjective]
                trailing_adjective = trailing_adjective*" " if trailing_adjective

                role_ref = @constellation.RoleRef(role_sequence, index, :role => roles[index])
                role_ref.leading_adjective = leading_adjective if leading_adjective
                role_ref.trailing_adjective = trailing_adjective if trailing_adjective
              end

              # Create any embedded constraints:
              debug "Creating embedded presence constraints" do
                create_embedded_presence_constraints(fact_type, role_phrases, roles)
              end

              # Add the identifying PresenceConstraint for this fact type:
              if fact_type.all_reading.size == 0
                identifier = @constellation.PresenceConstraint(
                    :new,
                    :vocabulary => @vocabulary,
                    :name => "#{name}PK",            # Is this a useful name?
                    :role_sequence => role_sequence,
                    :is_preferred_identifier => true,
                    :max_frequency => 1              # Unique
                  )
              end

              add_reading(fact_type, role_sequence, phrases)
            end

            # REVISIT: Process the fact derivation clauses, if any
          end
        end
      end

    end
  end
end
