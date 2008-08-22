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

      class SymbolTable; end

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
              when :constraint
                constraint *value
              else
                print "="*20+" unhandled declaration type: "; p kind, value
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
          # If this entity was forward referenced, this won't be a new object, and will subsume its roles
          entity_type = @constellation.EntityType(name, @vocabulary)

          # Set up its supertypes:
          supertypes.each do |supertype_name|
            debug :supertype, "Supertype #{supertype_name}"
            supertype = @constellation.EntityType(supertype_name, @vocabulary)
            inheritance_fact = @constellation.TypeInheritance(entity_type, supertype, :fact_type_id => :new)

            # Create a reading:
            sub_role = @constellation.Role(inheritance_fact, 0, entity_type)
            super_role = @constellation.Role(inheritance_fact, 1, supertype)
            rs = @constellation.RoleSequence(:new)
            @constellation.RoleRef(rs, 0, :role => sub_role)
            @constellation.RoleRef(rs, 1, :role => super_role)
            @constellation.Reading(inheritance_fact, 0, :role_sequence => rs, :reading_text => "{0} is a subtype of {1}")

            if !identification && supertype_name == supertypes[0]
              inheritance_fact.provides_identification = true
            end
          end

          # Use a two-pass algorithm for entity fact types...
          # The first step is to find all role references and definitions in the clauses
          # After bind_roles, each item in the reading part of each clause is either:
          # * a string, which is a linking word, or
          # * the phrase hash augmented with a :binding=>Binding
          @symbols = SymbolTable.new(@constellation, @vocabulary)
          @symbols.bind_roles_in_clauses(clauses, identification ? identification[:roles] : nil)

          # Next arrange the readings according to what fact they belong to,
          # then process each fact type using normal fact type processing.
          # That way if we find a fact type here having none of the players being the
          # entity type, we know it's an objectified fact type. The CQL syntax might make
          # us come here with such a case when the fact type is a subtype of some entity type,
          # such as occurs in the Metamodel with TypeInheritance.

          # N.B. This doesn't allow forward identification by roles with adjectives (see the i[0]):
          @symbols.allowed_forward = identification ? identification[:roles].inject({}){|h, i| h[i[0]] = true; h} : {}

          clauses_by_fact_type(clauses).each do |clauses_for_fact_type|
            fact_type = nil
            @symbols.embedded_presence_constraints = [] # Clear embedded_presence_constraints for each fact type
            debug "New Fact Type for entity #{name}" do
              clauses_for_fact_type.each do |clause|
                type, qualifiers, reading = *clause
                debug :reading, "Clause: #{clause.inspect}" do
                  f = bind_fact_reading(fact_type, qualifiers, reading)
                  fact_type ||= f
                end
              end
            end

            # Find the role that this entity type plays in the fact type, if any:
            player_roles = fact_type.all_role.select{|role| role.concept == entity_type }
            raise "#{role.concept.name} may only play one role in each identifying fact type" if player_roles.size > 1
            if player_role = player_roles[0]
              non_player_roles = fact_type.all_role-[player_role]

              raise "#{name} cannot be identified by a role in a non-binary fact type" if non_player_roles.size > 1
            elsif identification
              # This situation occurs when an objectified fact type has an entity identifier
              raise "Entity type #{name} may only objectify a single fact type" if entity_type.fact_type

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
                debug "Identifying roles: #{id_role_names.inspect}"

                # Pick out the identifying_roles in the order they were declared,
                # not the order the fact tyoes were defined:
                identifying_roles = id_role_names.map do |names|
                  player, binding = @symbols.bind(names)
                  role = @symbols.roles_by_binding[binding] 
                  raise "identifying role #{names*"-"} not found in fact types for #{name}" unless role
                  role
                end

                # Find a uniqueness constraint as PI, or make one
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

      def fact_type(name, clauses, conditions) 
        debug "Processing clauses for fact type" do
          fact_type = nil

          #
          # The first step is to find all role references and definitions in the reading clauses.
          # This also:
          # * deletes any adjectives that were used but not hyphenated
          # * changes each linking word phrase into a simple String
          # * adds a :binding key to each bound role
          #
          @symbols = SymbolTable.new(@constellation, @vocabulary)
          @symbols.bind_roles_in_clauses(clauses)

          clauses.each do |clause|
            kind, qualifiers, reading = *clause

            fact_type = bind_fact_reading(fact_type, qualifiers, reading)
          end

          # The fact type has a name iff it's objectified as an entity type
          #puts "============= Creating entity #{name} to nominalize fact type #{fact_type.default_reading} ======================" if name
          fact_type.entity_type = @constellation.EntityType(name, @vocabulary) if name

          # Add the identifying PresenceConstraint for this fact type:
          if fact_type.all_role.size == 1 && !fact_type.entity_type
            # All is well, unaries don't need an identifying PC unless objectified
          else
            fact_type_identification(fact_type, name, true)
          end

          # REVISIT: Process the fact derivation conditions, if any
        end
      end

      def constraint *value
        case type = value.shift
        when :presence
          presence_constraint *value
        when :subset
          subset_constraint *value
        when :set
          set_constraint *value
        when :equality
          equality_constraint *value
        else
          $stderr.puts "REVISIT: external #{type} constraints aren't yet handled:\n\t"+value.map{|a| a.inspect }*"\n\t"
        end
      end

      def bind_reading_list_as_role_sequences(readings_list)
        @symbols = SymbolTable.new(@constellation, @vocabulary)
        fact_roles_list = []
        bindings_list = []
        readings_list.each_with_index do |readings, index|
          @symbols.bind_roles_in_readings(readings)
          fact_roles_list[index] = invoked_fact_roles(readings[0])
          raise "Fact type reading not found for #{readings[0].inspect}" unless fact_roles_list[index]
          bindings_list[index] = readings[0].map{|phrase| Hash === phrase ? phrase[:binding] : nil}.compact
        end
        common_bindings = bindings_list.inject(bindings_list[0]) { |common, bindings| common & bindings }
        raise "Set comparison constraints must have at least one common role between the sets" unless common_bindings.size > 0

        # Create the role sequences and their role references:
        role_sequences = readings_list.map{|r| @constellation.RoleSequence(:new) }
        common_bindings.each_with_index do |binding, index|
          role_sequences.each_with_index do |rs, rsi|
            position = bindings_list[rsi].index(binding)
            @constellation.RoleRef(rs, index).role = fact_roles_list[rsi][position]
          end
        end

        role_sequences
      end

      def subset_constraint(subset_readings, superset_readings)
        raise "REVISIT: Join subset constraints not supported yet" if subset_readings.size > 1 or superset_readings.size > 1

        role_sequences = bind_reading_list_as_role_sequences([subset_readings, superset_readings])

        # create the constraint:
        constraint = @constellation.SubsetConstraint(:new)
        constraint.vocabulary = @vocabulary
        #constraint.name = nil
        #constraint.enforcement = 
        constraint.subset_role_sequence = role_sequences[0]
        constraint.superset_role_sequence = role_sequences[1]
      end

      def set_constraint(constrained_roles, quantifier, *readings_list)
        #raise "REVISIT: Join set constraints not supported yet" if readings_list.detect{|rl| rl.size > 1 }
        # Exactly one or at most one, nothing else will do
        raise "Set comparison constraint must use 'at most' or 'exactly' one" if quantifier[1] != 1

        role_sequences = bind_reading_list_as_role_sequences(readings_list)

        # Create the constraint:
        constraint = @constellation.SetExclusionConstraint(:new)
        constraint.vocabulary = @vocabulary
        role_sequences.each do |rs|
          @constellation.SetComparisonRoles(constraint, rs)
        end
        constraint.is_mandatory = quantifier[0] == 1
      end

      def equality_constraint(*readings_list)
        raise "REVISIT: Join equality constraints not supported yet" if readings_list.detect{|rl| rl.size > 1 }
        #puts "REVISIT: equality\n\t#{readings_list.map{|rl| rl.inspect}*"\n\tif and only if\n\t"}"

        role_sequences = bind_reading_list_as_role_sequences(readings_list)

        # Create the constraint:
        constraint = @constellation.SetEqualityConstraint(:new)
        constraint.vocabulary = @vocabulary
        role_sequences.each do |rs|
          @constellation.SetComparisonRoles(constraint, rs)
        end
      end

      def presence_constraint(constrained_role_names, quantifier, readings)
        raise "REVISIT: Join presence constraints not supported yet" if readings[0].size > 1
        readings = readings.map{|r| r[0] }
        #p readings

        @symbols = SymbolTable.new(@constellation, @vocabulary)

        # Find players for all constrained_role_names. These may use leading or trailing adjective forms...
        constrained_players = []
        constrained_bindings = []
        constrained_role_names.each do |role_name|
          player, binding = @symbols.bind(role_name)
          constrained_players << player
          constrained_bindings << binding
        end
        #puts "Constrained bindings are #{constrained_bindings.inspect}"
        #puts "Constrained bindings object_id's are #{constrained_bindings.map{|b|b.object_id.to_s}*","}"

        # Find players for all the concepts in all readings:
        @symbols.bind_roles_in_readings(readings)

        constrained_roles = []
        unmatched_roles = constrained_role_names.clone
        readings.each do |reading|
          # puts reading.inspect

          # If this succeeds, the reading found matches the roles in our phrases
          fact_roles = invoked_fact_roles(reading)
          raise "Fact type reading not found for #{reading.inspect}" unless fact_roles

          # Look for the constrained role(s); the bindings will be the same
          matched_bindings = reading.select{|p| Hash === p}.map{|p| p[:binding]}
          #puts "matched_bindings = #{matched_bindings.inspect}"
          #puts "matched_bindings object_id's are #{matched_bindings.map{|b|b.object_id.to_s}*","}}"
          matched_bindings.each_with_index{|b, pos|
            i = constrained_bindings.index(b)
            next unless i
            unmatched_roles[i] = nil
            #puts "found #{constrained_bindings[i].inspect} found as #{b.inspect} in position #{i.inspect}"
            role = fact_roles[pos]
            constrained_roles << role unless constrained_roles.include?(role)
          }
        end

        # Check that all constrained roles were matched at least once:
        unmatched_roles.compact!
        raise "Constrained roles #{unmatched_roles.map{|ur| ur*"-"}*", "} not found in fact types" if unmatched_roles.size != 0

        rs = @constellation.RoleSequence(:new)
        #puts "constrained_roles: #{constrained_roles.map{|r| r.concept.name}.inspect}"
        constrained_roles.each_with_index do |role, index|
          raise "Constrained role #{constrained_role_names[index]} not found" unless role
          rr = @constellation.RoleRef(rs, index)
          rr.role = role
        end
        #puts "New external PresenceConstraint with quantifier = #{quantifier.inspect} over #{rs.describe}"
        @constellation.PresenceConstraint(
            :new,
            :name => '',
            :enforcement => '',
            :vocabulary => @vocabulary,
            :role_sequence => rs,
            :min_frequency => quantifier[0],
            :max_frequency => quantifier[1],
            :is_preferred_identifier => false,
            :is_mandatory => quantifier[0] && quantifier[0] > 0
          )
      end

      def inheritance_path(subtype, supertype)
        direct_inheritance = subtype.all_type_inheritance_by_subtype.select{|ti| ti.supertype == supertype}
        return direct_inheritance if (direct_inheritance[0])
        subtype.all_type_inheritance_by_subtype.each{|ti|
          ip = inheritance_path(ti.supertype, supertype)
          return ip+[ti] if (ip)
        }
        return nil
      end

      def invoked_fact_roles(reading)
        if (reading[0] == "!SUBTYPE!")
          subtype = reading[1][:binding].concept
          supertype = reading[2][:binding].concept
          raise "#{subtype.name} is not a subtype of #{supertype.name}" unless subtype.supertypes_transitive.include?(supertype)
          ip = inheritance_path(subtype, supertype)
          return [ip[0].all_role[0], ip[-1].all_role[1]]
        end

        players = reading.select{|p| Hash === p}.map{|p| p[:binding].concept }
        players[0].all_role.each do |role|
          # Does this fact type have the right number of roles?
          next if role.fact_type.all_role.size != players.size

          # Does this fact type include the correct other players?
          next if role.fact_type.all_role.detect{|r| !players.include?(r.concept)}

          # Oooh, a real candidate. Check the reading words.
          debug "Considering "+role.fact_type.describe do
            next unless role.fact_type.all_reading.detect do |candidate_reading|
              debug "Considering reading"+candidate_reading.reading_text do
                to_match = reading.clone
                candidate_reading.words_and_role_refs.each do |wrr|
                  if (RoleRef === wrr)
                    break unless Hash === to_match.first
                    break unless binding = to_match[0][:binding]
                    break unless binding.concept == wrr.role.concept
                    break if wrr.leading_adjective && binding.leading_adjective != wrr.leading_adjective
                    break if wrr.trailing_adjective && binding.trailing_adjective != wrr.trailing_adjective

                    # All matched.
                    to_match.shift
                  else
                    break unless String === to_match[0]
                    break unless to_match[0] == wrr
                    to_match.shift
                  end
                end
                debug "Reading match was #{to_match.size == 0 ? "ok" : "bad"}"
                return candidate_reading.role_sequence.all_role_ref.map{|rr| rr.role} if to_match.size == 0
              end
            end
          end
        end
        nil
      end

      def bind_fact_reading(fact_type, qualifiers, reading)
        debug :reading, "Processing reading #{reading.inspect}" do
          role_phrases = reading.select do |phrase|
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

          # REVISIT: If the first reading is a re-iteration of an existing fact type, find and use the existing fact type
          # This will require loading the @symbols.roles_by_binding using a SymbolTable

          fact_type ||= @constellation.FactType(:new)

          # Create the roles on the first reading, or look them up on subsequent readings.
          # If the player occurs twice, we must find one with matching adjectives.

          role_sequence = @constellation.RoleSequence(:new)   # RoleSequence for RoleRefs of this reading
          roles = []
          role_phrases.each_with_index do |role_phrase, index|
            binding = role_phrase[:binding]
            role_name = role_phrase[:role_name]
            player = binding.concept
            if (fact_type.all_reading.size == 0)           # First reading
              # Assert this role of the fact type:
              role = @constellation.Role(fact_type, fact_type.all_role.size, player)
              role.role_name = role_name if role_name
              debug "Concept #{player.name} found, created role #{role.describe} by binding #{binding.inspect}"
              @symbols.roles_by_binding[binding] = role
            else                                # Subsequent readings
              #debug "Looking for role #{binding.inspect} in bindings #{@symbols.roles_by_binding.inspect}"
              role = @symbols.roles_by_binding[binding]
              raise "Role #{binding.inspect} not found in prior readings" if !role
              player = role.concept
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
          add_reading(fact_type, role_sequence, reading)
        end
        fact_type
      end

      def fact_type_identification(fact_type, name, prefer)
        if !@symbols.embedded_presence_constraints.detect{|pc| pc.max_frequency == 1}
          first_role_sequence = fact_type.all_reading[0].role_sequence
          identifier = @constellation.PresenceConstraint(
              :new,
              :vocabulary => @vocabulary,
              :name => "#{name}PK",            # Is this a useful name?
              :role_sequence => first_role_sequence,
              :is_preferred_identifier => prefer,
              :max_frequency => 1              # Unique
            )
          # REVISIT: The UC might be provided later as an external constraint, relax this rule:
          raise "'#{fact_type.default_reading}': non-unary fact types having no uniqueness constraints must be objectified (named)" unless fact_type.entity_type
          debug "Made default fact type identifier #{identifier.object_id} over #{first_role_sequence.describe} in #{fact_type.describe}"
        elsif prefer
          #debug "Made fact type identifier #{identifier.object_id} preferred over #{@symbols.embedded_presence_constraints[0].role_sequence.describe} in #{fact_type.describe}"
          @symbols.embedded_presence_constraints[0].is_preferred_identifier = true
        end
      end

      # Categorise the fact type clauses according to the set of role player names
      # Return an array where each element is an array of clauses, the clauses having
      # matching players, and otherwise preserving the order of definition.
      def clauses_by_fact_type(clauses)
        clause_group_by_role_players = {}
        clauses.inject([]) do |clause_groups, clause|
          type, qualifiers, reading = *clause

          debug "Clause: #{clause.inspect}"
          roles = reading.map do |phrase|
            Hash === phrase ? phrase[:binding] : nil
          end.compact

          # Look for an existing clause group involving these players, or make one:
          clause_group = clause_group_by_role_players[key = roles.sort]
          if clause_group     # Another clause for an existing clause group
            clause_group << clause
          else                # A new clause group
            clause_groups << (clause_group_by_role_players[key] = [clause])
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

      def find_pc_over_roles(roles)
        return nil if roles.size == 0 # Safeguard; this would chuck an exception otherwise
        roles[0].all_role_ref.each do |role_ref|
          next if role_ref.role_sequence.all_role_ref.map(&:role) != roles
          pc = role_ref.role_sequence.all_presence_constraint[0]
          #puts "Existing PresenceConstraint matches those roles!" if pc
          return pc if pc
        end
        nil
      end

      def add_reading(fact_type, role_sequence, reading)
        ordinal = (fact_type.all_reading.map(&:ordinal).max||-1) + 1  # Use the next unused ordinal
        defined_reading = @constellation.Reading(fact_type, ordinal, :role_sequence => role_sequence)
        role_num = -1
        defined_reading.reading_text = reading.map {|phrase|
            Hash === phrase ? "{#{role_num += 1}}" : phrase
          }*" "
        raise "Wrong number of players (#{role_num+1}) found in reading #{defined_reading.reading_text} over #{fact_type.describe}" if role_num+1 != fact_type.all_role.size
        debug "Added reading #{defined_reading.reading_text}"
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
        player = @constellation.Concept[[name, @vocabulary.identifying_role_values]]

        # REVISIT: Hack to allow facts to refer to standard types that will be imported from standard vocabulary:
        if !player && %w{Date DateAndTime Time}.include?(name)
          player = @constellation.ValueType(name, @vocabulary.identifying_role_values)
        end

        if (!player && @symbols.allowed_forward[name])
          player = @constellation.EntityType(name, @vocabulary)
        end
        player
      end

      class SymbolTable
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
          @role_names = {}

          @embedded_presence_constraints = []
          @roles_by_binding = {}   # Build a hash of allowed bindings on first reading (check against it on subsequent ones)
          @allowed_forward = {} # No roles may be forward-referenced
        end

        #
        # This method is the guts of role matching.
        # "words" may be a single word (and then the adjectives may also be used) or two words.
        # In either case a word is expected to be a defined concept or role name.
        # If a role_name is provided here, that's a *definition* and will only be accepted if legal
        # If allowed_forward is true, words is a single word and is not defined, create a forward Entity
        # If leading_speculative or trailing_speculative is true, the adjectives may not apply. If they do apply, use them.
        # If loose_binding_except is true, it's a hash containing names that may *not* be loose-bound... else none may.
        #
        # Loose binding is when a word without an adjective matches a role with, or vice verse.
        #
        def bind(words, leading_adjective = nil, trailing_adjective = nil, role_name = nil, allowed_forward = false, leading_speculative = false, trailing_speculative = false, loose_binding_except = nil)
          words = Array(words)
          if (words.size > 2 or words.size == 2 && (leading_adjective or trailing_adjective or allowed_forward))
            raise "role has too many adjectives '#{[leading_adjective, words, trailing_adjective].flatten.compact*" "}'"
          end

          # Check for use of a role name, valid if they haven't used any adjectives or tried to define a role_name:
          binding = @role_names[words[0]]
          if binding && words.size == 1   # If ok, this is it.
            raise "May not use existing role name '#{words[0]}' to define a new role name" if role_name
            if (leading_adjective && !leading_speculative) || (trailing_adjective && !trailing_speculative)
              raise "May not use existing role name '#{words[0]}' with adjectives"
            end
            return binding.concept, binding
          end

          # Look for an existing definition
          # If we have more than one word that might be the concept name, find which it is:
          words.each do |w|
              # Find the existing defined binding that matches this one:
              bindings = @bindings_by_concept[w]
              best_match = nil
              matched_adjectives = 0
              bindings.each do |binding|
                # Adjectives defined on the binding must be matched unless loose binding is allowed.
                loose_ok = loose_binding_except and !loose_binding_except[binding.concept.name]

                # Don't allow binding a new role name to an existing one:
                next if role_name and role_name != binding.role_name

                quality = 0
                if binding.leading_adjective != leading_adjective
                  next if binding.leading_adjective && leading_adjective  # Both set, but different
                  next if !loose_ok && (!leading_speculative || !leading_adjective)
                  quality += 1
                end

                if binding.trailing_adjective != trailing_adjective
                  next if binding.trailing_adjective && trailing_adjective  # Both set, but different
                  next if !loose_ok && (!trailing_speculative || !trailing_adjective)
                  quality += 1
                end

                quality += 1 unless binding.role_name   # A role name that was not matched... better if there wasn't one

                if (quality > matched_adjectives || !best_match)
                  best_match = binding       # A better match than we had before
                  matched_adjectives = quality
                  break unless loose_ok || leading_speculative || trailing_speculative
                end
              end

              if best_match
                # We've found the best existing definition

                # Indicate which speculative adjectives were used so the clauses can be deleted:
                leading_adjective.replace("") if best_match.leading_adjective and leading_adjective and leading_speculative
                trailing_adjective.replace("") if best_match.trailing_adjective and trailing_adjective and trailing_speculative

                return best_match.concept, best_match
              end

              # No existing defined binding. Look up an existing concept of this name:
              player = concept(w, allowed_forward)
              next unless player

              # Found a new binding for this player, save it.

              # Check that a trailing adjective isn't an existing role name or concept:
              trailing_word = words[1] if w == words[0]
              if trailing_word
                raise "May not use existing role name '#{trailing_word}' with a new name or with adjectives" if @role_names[trailing_word]
                raise "ambiguous concept reference #{words*" '"}'" if concept(trailing_word)
              end
              leading_word = words[0] if w != words[0]

              raise "may not redefine existing concept '#{role_name}' as a role name" if role_name and concept(role_name)

              binding = Binding.new(
                  player,
                  w,
                  (!leading_speculative && leading_adjective) || leading_word,
                  (!trailing_speculative && trailing_adjective) || trailing_word,
                  role_name
                )
              @bindings_by_concept[binding.name] << binding
              @role_names[binding.role_name] = binding if role_name
              return binding.concept, binding
            end

            # Not found.
            return nil
        end

        # return the EntityType or ValueType this name refers to:
        def concept(name, allowed_forward = false)
          # See if the name is a defined concept in this vocabulary:
          player = @constellation.Concept[[name, virv = @vocabulary.identifying_role_values]]

          # REVISIT: Hack to allow facts to refer to standard types that will be imported from standard vocabulary:
          if !player && %w{Date DateAndTime Time}.include?(name)
            player = @constellation.ValueType(name, virv)
          end

          if !player && allowed_forward
            player = @constellation.EntityType(name, @vocabulary)
          end

          player
        end

        def bind_roles_in_clauses(clauses, identification = [])
          identification ||= []
          bind_roles_in_readings(
              clauses.map{|clause| clause[2]},    # Extract the readings
              single_word_identifiers = identification.map{|i| i.size == 1 ? i[0] : nil}.compact.uniq
            )
        end

        #
        # Walk through all phrases of all readings identifying role players.
        # Each role player phrase gets a :binding key added to it.
        #
        # Any adjectives that the parser didn't recognise are merged with their players here,
        # as long as they're indicated as adjectives of that player somewhere in the readings.
        #
        # Other words are turned from phrases (hashes) into simple strings.
        #
        def bind_roles_in_readings(readings, allowed_forwards = [])
          disallow_loose_binding = allowed_forwards.inject({}) { |h, v| h[v] = true; h }
          readings.each do |reading|
            debug :bind, "Binding a reading"

            if (reading.size == 1 && reading[0][:subtype])
              # REVISIT: Handle a subtype reading here
              subtype_name = reading[0][:subtype]
              supertype_name = reading[0][:supertype]
              subtype, subtype_binding = bind(subtype_name)
              supertype, supertype_binding = bind(supertype_name)
              reading.replace([
                  "!SUBTYPE!",
                  {:word => subtype, :binding => subtype_binding },
                  {:word => supertype, :binding => supertype_binding }
                ]
              )
              next
            end

            phrase_numbers_used_speculatively = []
            disallow_loose_binding_this_reading = disallow_loose_binding.clone
            reading.each_with_index do |phrase, index|
              la = phrase[:leading_adjective]
              player_name = phrase[:word]
              ta = phrase[:trailing_adjective]
              role_name = phrase[:role_name]

              # We use the preceeding phrase and/or following phrase speculatively if they're simple words:
              preceeding_phrase = nil
              following_phrase = nil
              if !la && index > 0 && (preceeding_phrase = reading[index-1])
                preceeding_phrase = nil unless String === preceeding_phrase || preceeding_phrase.keys == [:word]
                la = preceeding_phrase[:word] if Hash === preceeding_phrase
              end
              if !ta && (following_phrase = reading[index+1])
                following_phrase = nil unless following_phrase.keys == [:word]
                ta = following_phrase[:word] if following_phrase
              end

              # If the identification includes this player name as a single word, it's allowed to be forward referenced:
              allowed_forward = allowed_forwards.include?(player_name)

              debug :bind, "Binding a role: #{[player_name, la, ta, role_name, allowed_forward, !!preceeding_phrase, !!following_phrase].inspect}"
              player, binding = bind(
                  player_name,
                  la, ta,
                  role_name,
                  allowed_forward,
                  !!preceeding_phrase, !!following_phrase,
                  reading == readings[0] ? nil : disallow_loose_binding_this_reading  # Never allow loose binding on the first reading
                )
              disallow_loose_binding_this_reading[player.name] = true if player

              # Arrange to delete the speculative adjectives that were used:
              if preceeding_phrase && preceeding_phrase[:word] == ""
                debug :bind, "binding consumed a speculative leading_adjective #{la}"
                # The numbers are adjusted to allow for prior deletions.
                phrase_numbers_used_speculatively << index-1-phrase_numbers_used_speculatively.size
              end
              if following_phrase && following_phrase[:word] == ""
                debug :bind, "binding consumed a speculative trailing_adjective #{ta}"
                phrase_numbers_used_speculatively << index+1-phrase_numbers_used_speculatively.size
              end

              if player
                # Replace the words used to identify the role by a reference to the role itself,
                # leaving :quantifier, :function, :restriction and :literal intact
                phrase[:binding] = binding
                binding
              else
                raise "Internal error; role #{phrase.inspect} not matched" unless phrase.keys == [:word]
                # Just a linking word
                reading[index] = phrase[:word]
              end
              debug :bind, "Bound phrase: #{phrase.inspect}" + " -> " + (player ? player.name+", "+binding.inspect : phrase[:word].inspect)

            end
            phrase_numbers_used_speculatively.each do |index|
              reading.delete_at(index)
            end
            debug :bind, "Bound reading: #{reading.inspect}"
          end
        end
      end # of SymbolTable class

    end
  end
end
