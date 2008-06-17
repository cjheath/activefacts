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
        raise parser.failure_reason unless result
        @vocabulary
      end

      def value_type(name, base_type_name, parameters, unit, ranges)
        length, scale = *parameters

        # Create the base type:
        unless base_type = @constellation.ValueType[[@constellation.Name(base_type_name), @vocabulary]]
          puts "REVISIT: Creating base ValueType #{base_type_name} in #{@vocabulary.inspect}"
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
        puts "Defining Entity Type #{name}"

        # Assert the entity:
        # REVISIT: If this entity was forward referenced, this new object subsumes its roles
        et = @constellation.EntityType(name, @vocabulary)

        # Set up its supertypes:
        supertypes.each do |supertype|
          puts "\tsupertype #{supertype}"
          supertype = @constellation.EntityType(supertype, @vocabulary)
          inheritance_fact = @constellation.TypeInheritance(et, supertype)
          inheritance_fact.provides_identification = true if !identification && supertype == supertypes[0]
        end

        # Process the entity type clauses (fact type readings)
        defined_facts_by_role_players = {}
        identifying_roles = []  # In whatever order they're constructed
        clauses.each do |clause|
          type, qualifiers, phrases = *clause
          print "\tclause: "; p clause
          role_phrases = phrases.map do |phrase|
            Hash === phrase ? phrase : nil
          end.compact
          print "\t\tRoles(#{role_phrases.size}): "; p role_phrases

          player_names = role_phrases.map do |role_phrase|
            role_phrase[:player]
          end
          
          # Look for an existing fact type involving these players, or make one:
          fact_type = defined_facts_by_role_players[player_names.sort]
          is_new_fact_type = false
          unless fact_type
            is_new_fact_type = true
            defined_facts_by_role_players[player_names.sort] =
              fact_type = @constellation.FactType(:new)

            # Add the FactType's Roles:
            non_player_roles = []
            role_phrases.each do |role_phrase|
              player_name = role_phrase[:player]
              player = @constellation.Concept[[player_name, @vocabulary.identifying_role_values]]

              # REVISIT: This prevents forward referencing. We'll need to create an abstract Concept here, and replace it with the concrete concept later:
              raise "Concept #{player_name} not found" unless player

              role = @constellation.Role(:new, :fact_type => fact_type, :concept => player)
              role_name = role_phrase[:role_name]
              role.role_name = role_name if role_name

              non_player_roles << role unless player == et

              # REVISIT: Create PresenceConstraints here when role_phrase[:quantifier] is set
            end

            if non_player_roles.size == role_phrases.size-1
              raise "#{name} cannot be identified by a role in a non-binary fact type" if non_player_roles.size > 1
              identifying_roles << non_player_roles[0]
            else non_player_roles.size == role_phrases.size
              raise "Irrelevant fact in identification of '#{name}'"
            end

          end

          # Create the role references and role sequence:
          # REVISIT: Find an existing RoleSequence if sequence and adjectives match, don't make a new one:
          role_sequence = @constellation.RoleSequence(:new)
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

            roles = fact_type.all_role.select{|r| r.concept.name == player_name }
            if roles.size > 1 && !is_new_fact_type
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
              role = roles[0]
            end

            role_ref = @constellation.RoleRef(role_sequence, index, :role => role)
            role_ref.leading_adjective = leading_adjective if leading_adjective
            role_ref.trailing_adjective = trailing_adjective if trailing_adjective
          end

          # Add the reading:
          ordinal = (fact_type.all_reading.map(&:ordinal).max||-1) + 1  # Use the next unused ordinal
          reading = @constellation.Reading(fact_type, ordinal, :role_sequence => role_sequence)
          role_num = -1
          reading.reading_text = phrases.map {|phrase|
              Hash === phrase ? "{#{role_num += 1}}" : phrase
            }*" "
        end

        # The identifying roles must have been defined in the clauses.
        # Some identifying roles may be played by concepts as yet undefined - create abstract Features
        if identification
          if id_role_names = identification[:roles]  # A list of identifying roles
            id_role_names.each do |id_role_name|
              # Each identifying role is an array of words (adjectives and concept names)
              print "identifying_role: "; p id_role_name
            end

            # Add a unique constraint over all identifying roles
            pc = @constellation.PresenceConstraint(
                :new,
                :vocabulary => @vocabulary,
                :name => "#{name}PK",            # Is this a useful name?
                :role_sequence => @constellation.RoleSequence(:new),
                :is_preferred_identifier => true,
                :max_frequency => 1              # Unique
                #:is_mandatory => true,
                #:min_frequency => 1,
              )
            # REVISIT: Need to sort the identifying_roles to match the identification parameter array
            puts "\tAdding PK using #{identifying_roles.map{|r| r.concept.name}.inspect}"
            identifying_roles.each_with_index do |identifying_role, index|
              @constellation.RoleRef(pc.role_sequence, index, :role => identifying_role)
            end

          elsif identification[:mode]
            mode = identification[:mode]        # An identification mode
            raise "Identification modes aren't yet implemented"
          end
        else
          # identification must be inherited.
        end

      end

      def fact_type(name, readings, clauses) 
        return  # REVISIT: Implement
        ft = @constellation.FactType(:new)

        # The fact type has a name iff it's objectified as an entity type
        ft.entity_type = @constellation.EntityType(name, @vocabulary) if name

        readings.each do |reading|
          kind, qualifiers, phrases = *reading
          player_names = phrases.map{|w| Hash === w ? w[:player] : nil }.compact.sort
          #p @constellation.EntityType; exit
          puts "Fact type player_names are: "+ player_names.inspect
          players = player_names.map{|name|
              name_value = @constellation.Name(name)
              key = [name_value, @vocabulary]
              #print "key for feature #{name} is: "; p key
              # REVISIT: Constellation should index in superclasses so we can use Feature[key]
              player = @constellation.EntityType[key] || @constellation.ValueType[key]
              # REVISIT: player might not be found here if it's a rolename defined in another reading of this definition
            }
          puts "Fact type players are: "+players.map{|p| p ? p.name : "not found" }*", "
          print "REVISIT Fact readings: "; p [ qualifiers, phrases ]
        end

        # REVISIT: Process the fact derivation clauses, if any
      end

    end
  end
end
