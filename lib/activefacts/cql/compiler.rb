#       Compile a CQL string into an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/cql/parser'
require 'activefacts/cql/binding'

module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      attr_reader :vocabulary

      RingTypes = %w{acyclic intransitive symmetric asymmetric transitive antisymmetric irreflexive reflexive}
      RingPairs = {
        :intransitive => [:acyclic, :asymmetric, :symmetric],
        :irreflexive => [:symmetric]
      }

      def initialize(input, filename = "stdin")
        @filename = filename
        @constellation = ActiveFacts::API::Constellation.new(ActiveFacts::Metamodel)

        compile(input)
      end

      def compile(input)
        @string = input

        # The syntax tree created from each parsed CQL statement gets passed to the block.
        # parse_all returns an array of the block's non-nil return values.
        result = parse_all(@string, :definition) do |node|
          begin
            kind, *value = d = definition(node)
            #print "Parsed '#{node.text_value}' (#{kind.inspect})"
            #print " to "; p value
            raise "Definition of #{kind} must be in a vocabulary" if kind != :vocabulary and !@vocabulary
            case kind
            when :vocabulary
              @vocabulary = @constellation.Vocabulary(value[0])
            when :value_type
              value_type *value
            when :entity_type
              entity_type *value
            when :fact_type
              fact_type *value
            when :constraint
              constraint *value
            when :fact
              fact *value
            when :unit
              unit *value
            else
              print "="*20+" unhandled declaration type: "; p kind, value
            end
          rescue => e
            puts e.message+"\n\t"+e.backtrace*"\n\t" if debug :exception
            start_line = @string.line_of(node.interval.first)
            end_line = @string.line_of(node.interval.last-1)
            lines = start_line != end_line ? "s #{start_line}-#{end_line}" : " #{start_line.to_s}"
            raise "at line#{lines} #{e.message.strip}"
          end

          nil
        end
        raise failure_reason unless result
        @vocabulary
      end

    private
      def value_type(name, base_type_name, parameters, unit, ranges, mapping_pragmas, enforcement)
        length, scale = *parameters

        # Create the base type:
        base_type = nil
        if (base_type_name != name)
          unless base_type = @constellation.ValueType[[@vocabulary, @constellation.Name(base_type_name)]]
            #puts "REVISIT: Creating base ValueType #{base_type_name} in #{@vocabulary.inspect}"
            base_type = @constellation.ValueType(@vocabulary, base_type_name)
            return if base_type_name == name
          end
        end

        # Create and initialise the ValueType:
        vt = @constellation.ValueType(@vocabulary, name)
        vt.supertype = base_type if base_type
        vt.length = length if length
        vt.scale = scale if scale

        # REVISIT: Find and apply the units

        if ranges.size != 0
          vt.value_restriction = value_restriction(ranges, enforcement)
        end
      end

      def value_restriction(ranges, enforcement)
        vr = @constellation.ValueRestriction(:new)
        ranges.each do |range|
          min, max = Array === range ? range : [range, range]
          v_range = @constellation.ValueRange(
            min ? [[String === min ? eval(min) : min.to_s, String === min, nil], true] : nil,
            max ? [[String === max ? eval(max) : max.to_s, String === max, nil], true] : nil
          )
          ar = @constellation.AllowedRange(vr, v_range)
        end
        apply_enforcement(vr, enforcement) if enforcement
        vr
      end

      def apply_enforcement(constraint, enforcement)
        action, agent = *enforcement
        constraint.enforcement = action
        constraint.enforcement.agent = agent if agent
      end

      def entity_type(name, supertypes, identification, mapping_pragmas, clauses)
        #puts "Entity Type #{name}, supertypes #{supertypes.inspect}, id #{identification.inspect}, clauses = #{clauses.inspect}"
        debug :entity, "Defining Entity Type #{name}" do
          # Assert the entity:
          # If this entity was forward referenced, this won't be a new object, and will subsume its roles
          entity_type = @constellation.EntityType(@vocabulary, name)
          entity_type.is_independent = true if (mapping_pragmas.include? 'independent')

          # Set up its supertypes:
          supertypes.each do |supertype_name|
            add_supertype(entity_type, supertype_name, !identification && supertype_name == supertypes[0], mapping_pragmas)
          end

          # If we're using a common identification mode, find or create the necessary ValueTypes first:
          vt_name = vt = nil
          if identification && identification[:mode]
            mode = identification[:mode]        # An identification mode

            # Find or Create an appropriate ValueType called "#{name}#{mode}", of the supertype "#{mode}"
            vt_name = "#{name}#{mode}"
            unless vt = @constellation.ValueType[[@vocabulary, vt_name]]
              base_vt = @constellation.ValueType(@vocabulary, mode)
              vt = @constellation.ValueType(@vocabulary, vt_name, :supertype => base_vt)
              if parameters = identification[:parameters]
                length, scale = *parameters
                vt.length = length if length
                vt.scale = scale if scale
              end
            end
            # REVISIT: If we do this, it gets emitted twice when we generate CQL. The generator should detect that the restriction is the same and not emit it.
            #if (ranges = identification[:restriction])
            #  vt.value_restriction = value_restriction(ranges, identification[:enforcement])
            #end
          end

          # Use a two-pass algorithm for entity fact types...
          # The first step is to find all role references and definitions in the clauses
          # After bind_roles, each phrase in each clause is either:
          # * a string, which is a linking word, or
          # * the phrase hash augmented with a :binding=>Binding
          @symbols = SymbolTable.new(@constellation, @vocabulary)

          # Enumerate the identifying roles that may be forward referenced.
          # Forward identification isn't allowed by roles with adjectives.
          # We can't tell which is the adjective (possible to fix, but not done yet):
          if (ir = identification && identification[:roles])
            @symbols.allowed_forward = ir.inject({}){|h, i| h[i[0]] = true; h}
          end
          @symbols.bind_roles_in_clauses(clauses, identification ? identification[:roles] : nil)

          # Next arrange the clauses according to what fact they belong to,
          # then process each fact type using normal fact type processing.
          # That way if we find a fact type here having none of the players being the
          # entity type, we know it's an objectified fact type. The CQL syntax might make
          # us come here with such a case when the fact type is a subtype of some entity type,
          # such as occurs in the Metamodel with TypeInheritance.

          identifying_fact_types = {}
          clauses_by_fact_type(clauses).each do |clauses_for_fact_type|
            fact_type = nil
            @symbols.embedded_presence_constraints = [] # Clear embedded_presence_constraints for each fact type
            debug :entity, "New Fact Type for entity #{name}" do
              clauses_for_fact_type.each do |clause|
                type, qualifiers, phrases, context = *clause
                debug :reading, "Clause: #{clause.inspect}" do
                  f, r = *bind_fact_reading(fact_type, qualifiers, phrases)
                  identifying_fact_types[f] = true
                  fact_type ||= f
                end
              end
            end

            # Find the role that this entity type plays in the fact type, if any:
            debug :reading, "Roles are: #{fact_type.all_role.map{|role| (role.concept == entity_type ? "*" : "") + role.concept.name }*", "}"
            player_roles = fact_type.all_role.select{|role| role.concept == entity_type }
            raise "#{player_roles[0].concept.name} may only play one role in each of its identifying fact types" if player_roles.size > 1
            if player_role = player_roles[0]
              non_player_roles = fact_type.all_role-[player_role]

              raise "#{name} cannot be identified by a role in a non-binary fact type" if non_player_roles.size > 1
            elsif identification
              # This situation occurs when an objectified fact type has an entity identifier
              #raise "Entity type #{name} cannot objectify fact type #{fact_type.describe}, it already objectifies #{entity_type.fact_type.describe}" if entity_type.fact_type
              raise "Entity type #{name} cannot objectify fact type #{identification.inspect}, it already objectifies #{entity_type.fact_type.describe}" if entity_type.fact_type
              debug :entity, "Entity type #{name} objectifies fact type #{fact_type.describe} with distinct identifier"

              entity_type.fact_type = fact_type
              fact_type_identification(fact_type, name, false)
            else
              debug :entity, "Entity type #{name} objectifies fact type #{fact_type.describe}"
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
                # not the order the fact types were defined:
                identifying_roles = id_role_names.map do |names|
                  unless (role = bind_unary_fact_type(entity_type, names))
                    player, binding = @symbols.bind(names)
                    role = @symbols.roles_by_binding[binding] 
                    raise "identifying role #{names*"-"} not found in fact types for #{name}" unless role
                  end
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

                raise "Entity definition using reference mode may only have one identifying fact type" if identifying_fact_types.size > 1
                mode_fact_type = identifying_fact_types.keys[0]

                # If the entity type is an objectified fact type, don't use the objectified fact type!
                mode_fact_type = nil if mode_fact_type && mode_fact_type.entity_type == entity_type

                debug :mode, "Processing Reference Mode for #{name}#{mode_fact_type ? " with existing '#{mode_fact_type.default_reading}'" : ""}"

                # Fact Type:
                if (ft = mode_fact_type)
                  entity_role, value_role = ft.all_role.partition{|role| role.concept == entity_type}.flatten
                else
                  ft = @constellation.FactType(:new)
                  entity_role = @constellation.Role(ft, 0, :concept => entity_type)
                  value_role = @constellation.Role(ft, 1, :concept => vt)
                  debug :mode, "Creating new fact type to identify #{name}"
                end

                # REVISIT: The restriction applies only to the value role. There is good reason to apply it above to the value type as well.
                if (ranges = identification[:restriction])
                  value_role.role_value_restriction = value_restriction(ranges, identification[:enforcement])
                end

                # Forward reading, if it doesn't already exist:
                rss = entity_role.all_role_ref.map{|rr| rr.role_sequence.all_role_ref.size == 2 ? rr.role_sequence : nil }.compact
                # Find or create RoleSequences for the forward and reverse readings:
                rs01 = rss.select{|rs| rs.all_role_ref.sort_by{|rr| rr.ordinal}.map(&:role) == [entity_role, value_role] }[0]
                if !rs01
                  rs01 = @constellation.RoleSequence(:new)
                  @constellation.RoleRef(rs01, 0, :role => entity_role)
                  @constellation.RoleRef(rs01, 1, :role => value_role)
                end
                if rs01.all_reading.empty?
                  @constellation.Reading(ft, ft.all_reading.size, :role_sequence => rs01, :text => "{0} has {1}")
                  debug :mode, "Creating new forward reading '#{name} has #{vt.name}'"
                else
                  debug :mode, "Using existing forward reading"
                end

                # Reverse reading:
                rs10 = rss.select{|rs| rs.all_role_ref.sort_by{|rr| rr.ordinal}.map(&:role) == [value_role, entity_role] }[0]
                if !rs10
                  rs10 = @constellation.RoleSequence(:new)
                  @constellation.RoleRef(rs10, 0, :role => value_role)
                  @constellation.RoleRef(rs10, 1, :role => entity_role)
                end
                if rs10.all_reading.empty?
                  @constellation.Reading(ft, ft.all_reading.size, :role_sequence => rs10, :text => "{0} is of {1}")
                  debug :mode, "Creating new reverse reading '#{vt.name} is of #{name}'"
                else
                  debug :mode, "Using existing reverse reading"
                end

                # Entity Type must have a value type. Find or create the role sequence, then create a PC if necessary
                debug :mode, "entity_role has #{entity_role.all_role_ref.size} attached sequences"
                debug :mode, "entity_role has #{entity_role.all_role_ref.select{|rr| rr.role_sequence.all_role_ref.size == 1}.size} unary sequences"
                rs0 = entity_role.all_role_ref.select{|rr| rr.role_sequence.all_role_ref.size == 1 ? rr.role_sequence : nil }.compact[0]
                if !rs0
                  rs0 = @constellation.RoleSequence(:new)
                  @constellation.RoleRef(rs0, 0, :role => entity_role)
                  debug :mode, "Creating new EntityType role sequence"
                else
                  rs0 = rs0.role_sequence
                  debug :mode, "Using existing EntityType role sequence"
                end
                if (rs0.all_presence_constraint.size == 0)
                  constraint = @constellation.PresenceConstraint(
                    :new,
                    :name => '',
                    :vocabulary => @vocabulary,
                    :role_sequence => rs0,
                    :min_frequency => 1,
                    :max_frequency => 1,
                    :is_preferred_identifier => false,
                    :is_mandatory => true
                  )
                  debug :mode, "Creating new EntityType PresenceConstraint"
                else
                  debug :mode, "Using existing EntityType PresenceConstraint"
                end

                # Value Type must have a value type. Find or create the role sequence, then create a PC if necessary
                debug :mode, "value_role has #{value_role.all_role_ref.size} attached sequences"
                debug :mode, "value_role has #{value_role.all_role_ref.select{|rr| rr.role_sequence.all_role_ref.size == 1}.size} unary sequences"
                rs1 = value_role.all_role_ref.select{|rr| rr.role_sequence.all_role_ref.size == 1 ? rr.role_sequence : nil }.compact[0]
                if (!rs1)
                  rs1 = @constellation.RoleSequence(:new)
                  @constellation.RoleRef(rs1, 0, :role => value_role)
                  debug :mode, "Creating new ValueType role sequence"
                else
                  rs1 = rs1.role_sequence
                  debug :mode, "Using existing ValueType role sequence"
                end
                if (rs1.all_presence_constraint.size == 0)
                  constraint = @constellation.PresenceConstraint(
                    :new,
                    :name => '',
                    :vocabulary => @vocabulary,
                    :role_sequence => rs1,
                    :min_frequency => 0,
                    :max_frequency => 1,
                    :is_preferred_identifier => true,
                    :is_mandatory => false
                  )
                  debug :mode, "Creating new ValueType PresenceConstraint"
                else
                  debug :mode, "Marking existing ValueType PresenceConstraint as preferred"
                  rs1.all_presence_constraint[0].is_preferred_identifier = true
                end
              end
            end
          else
            # identification must be inherited.
            debug "Identification is inherited"
          end
        end
      end

      def add_supertype(entity_type, supertype_name, identifying_supertype, mapping_pragmas)
        debug :supertype, "Supertype #{supertype_name}"
        supertype = @constellation.EntityType(@vocabulary, supertype_name)
        inheritance_fact = @constellation.TypeInheritance(entity_type, supertype, :fact_type_id => :new)

        assimilations = mapping_pragmas.select { |p| ['absorbed', 'separate', 'partitioned'].include? p}
        raise "Conflicting assimilation pragmas #{assimilations*", "}" if assimilations.size > 1
        inheritance_fact.assimilation = assimilations[0]

        # Create a reading:
        sub_role = @constellation.Role(inheritance_fact, 0, :concept => entity_type)
        super_role = @constellation.Role(inheritance_fact, 1, :concept => supertype)

        rs = @constellation.RoleSequence(:new)
        @constellation.RoleRef(rs, 0, :role => sub_role)
        @constellation.RoleRef(rs, 1, :role => super_role)
        @constellation.Reading(inheritance_fact, 0, :role_sequence => rs, :text => "{0} is a kind of {1}")
        @constellation.Reading(inheritance_fact, 1, :role_sequence => rs, :text => "{0} is a subtype of {1}")

        rs2 = @constellation.RoleSequence(:new)
        @constellation.RoleRef(rs2, 0, :role => super_role)
        @constellation.RoleRef(rs2, 1, :role => sub_role)
        n = 'aeiouh'.include?(sub_role.concept.name.downcase[0]) ? 1 : 0
        @constellation.Reading(inheritance_fact, 2+n, :role_sequence => rs2, :text => "{0} is a {1}")
        @constellation.Reading(inheritance_fact, 3-n, :role_sequence => rs2, :text => "{0} is an {1}")

        if identifying_supertype
          inheritance_fact.provides_identification = true
        end

        # Create uniqueness constraints over the subtyping fact type
        p1rs = @constellation.RoleSequence(:new)
        @constellation.RoleRef(p1rs, 0).role = sub_role
        pc1 = @constellation.PresenceConstraint(:new)
        pc1.name = "#{entity_type.name}MustHaveSupertype#{supertype.name}"
        pc1.vocabulary = @vocabulary
        pc1.role_sequence = p1rs
        pc1.is_mandatory = true   # A subtype instance must have a supertype instance
        pc1.min_frequency = 1
        pc1.max_frequency = 1
        pc1.is_preferred_identifier = false

        # The supertype role often identifies the subtype:
        p2rs = @constellation.RoleSequence(:new)
        @constellation.RoleRef(p2rs, 0).role = super_role
        pc2 = @constellation.PresenceConstraint(:new)
        pc2.name = "#{supertype.name}MayBeA#{entity_type.name}"
        pc2.vocabulary = @vocabulary
        pc2.role_sequence = p2rs
        pc2.is_mandatory = false
        pc2.min_frequency = 0
        pc2.max_frequency = 1
        pc2.is_preferred_identifier = inheritance_fact.provides_identification
      end

      def unit params
        singular = params[:singular]
        plural = params[:plural]
        base_units = params[:base]
        denominator = params[:coefficient][:denominator]
        numerator = params[:coefficient][:numerator]
        offset = params[:offset]
        approximately = params[:approximately]
        ephemeral = params[:ephemeral]

        if (numerator.to_f / denominator.to_i != 1.0)
          coefficient = @constellation.Coefficient(
              :numerator => numerator.to_f,
              :denominator => denominator.to_i,
              :is_precise => !approximately
            )
        else
          coefficient = nil
        end
        offset = offset.to_f
        offset = nil if offset == 0
        debug :units, "Defining new unit #{singular}#{plural ? "/"+plural : ""}" do
          debug :units, "Coefficient is #{coefficient.numerator}#{coefficient.denominator != 1 ? "/#{coefficient.denominator}" : ""} #{coefficient.is_precise ? "exactly" : "approximately"}" if coefficient
          debug :units, "Offset is #{offset}" if offset
          raise "Redefinition of unit #{singular}" if @constellation.Unit.values.detect{|u| u.name == singular}
          raise "Redefinition of unit #{plural}" if @constellation.Unit.values.detect{|u| u.name == plural}
          unit = @constellation.Unit(:new,
              :name => singular,
              # :plural => plural,
              :coefficient => coefficient,
              :offset => offset,
              :is_fundamental => base_units.empty?,
              :is_ephemeral => ephemeral,
              :vocabulary => @vocabulary
            )
          base_units.each do |base_unit, exponent|
            base = @constellation.Unit.values.detect{|u| u.name == base_unit}
            debug :units, "Base unit #{base_unit}^#{exponent} #{base ? "" : "(implicitly fundamental)"}"
            base ||= @constellation.Unit(:new, :name => base_unit, :is_fundamental => true, :vocabulary => @vocabulary)
            @constellation.Derivation(:derived_unit => unit, :base_unit => base, :exponent => exponent)
          end
          if plural
            plural_unit = @constellation.Unit(:new,
                :name => plural,
                :is_fundamental => false,
                :vocabulary => @vocabulary
              )
            @constellation.Derivation(:derived_unit => plural_unit, :base_unit => unit, :exponent => 1)
          end
        end
      end

      # Record the concepts that play a role in these clauses
      # After this, each phrase will have [:player] member that refers to the Concept
      def resolve_players(clauses)
        # Find the term for each role name:
        terms_by_role_names = {}
        clauses.each do |clause|
          kind, qualifiers, phrases, context = *clause
          phrases.each do |phrase|
            next unless phrase.is_a?(Hash)
            role_name = phrase[:role_name]
            next unless role_name.is_a?(String)   # Skip subscripts for now
            terms_by_role_names[role_name] = phrase[:term] if role_name
          end
        end

        clauses.each do |clause|
          kind, qualifiers, phrases, context = *clause
          phrases.each do |phrase|
            next unless phrase.is_a?(Hash)
            concept_name = phrase[:term]
            real_term = terms_by_role_names[concept_name] 
            concept_name = real_term if real_term
            concept = concept_by_name(concept_name)
            phrase[:player] = concept
          end
        end
      end

      # Arrange the clauses of one or more fact types into groups having the same role players
      def clauses_by_players(clauses)
        cbp = {}
        clauses.each do |clause|
          kind, qualifiers, phrases, context = *clause
          players = []
          phrases.each do |phrase|
            next unless phrase.is_a?(Hash)
            players << phrase[:player]
          end
          (cbp[players.map{|p| p.name}.sort] ||= []) << clause
        end
        cbp
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

      # For each fact reading there may be embedded mandatory, uniqueness or frequency constraints:
      def make_embedded_presence_constraints(fact_type, role_phrases)
        embedded_presence_constraints = []
        roles = role_phrases.map { |p| p[:role_ref].role }
        role_phrases.each_with_index do |role_phrase, index|
          role = role_phrase[:role_ref].role
          raise "No Role for embedded_presence_constraint; use role_ref?" unless role

          next unless quantifier = role_phrase[:quantifier]

          debug :constraint, "Processing embedded constraint #{quantifier.inspect} on #{role.concept.name} in #{fact_type.describe}" do
            constrained_roles = roles.clone
            constrained_roles.delete_at(index)
            constraint = find_pc_over_roles(constrained_roles)
            if constraint
              debug :constraint, "Setting max frequency to #{quantifier[1]} for existing constraint #{constraint.object_id} over #{constraint.role_sequence.describe} in #{fact_type.describe}"
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
              debug :constraint, "Made new PC min=#{quantifier[0].inspect} max=#{quantifier[1].inspect} constraint #{constraint.object_id} over #{(e = fact_type.entity_type) ? e.name : role_sequence.describe} in #{fact_type.describe}"
              enforcement = role_phrase[:quantifier_restriction]
              apply_enforcement(constraint, enforcement) if enforcement
            end
          end
        end
      end

      def fact_type(name, clauses, conditions) 
        debug :matching, "Processing clauses for fact type" do
          fact_type = nil

          # REVISIT: Any role names defined in the conditions aren't handled here, only those in the clauses

          # Find and set [:player] to the concept (object type) that plays each role
          resolve_players(clauses)

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
          if !fact_type
            fact_type = @constellation.FactType(:new)
            kind, qualifiers, phrases, context = *unmatched_clauses[0]
            debug :matching, "Making new fact type for #{show_phrases(phrases)}" do
              phrases.each do |phrase|
                next unless phrase.is_a?(Hash)
                role = @constellation.Role(fact_type, fact_type.all_role.size, :concept => phrase[:player])
                phrase[:role] = role
              end
            end
          end

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
              kind, qualifiers, phrases, context = *clause
              role_phrases = phrases.select{|p| p.is_a?(Hash)}
              debug :constraint, "making embedded presence constraints from #{show_phrases(phrases)}"
              make_embedded_presence_constraints(fact_type, role_phrases)
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

      def fact(population_name, clauses) 
        debug "Processing clauses for fact" do
          population_name ||= ''
          population = @constellation.Population(@vocabulary, population_name)
          @symbols = SymbolTable.new(@constellation, @vocabulary)
          @symbols.bind_roles_in_clauses(clauses)

          bound_instances = {}  # Instances indexed by binding
          facts =
            clauses.map do |clause|
              kind, qualifiers, phrases, context = *clause
              # Every bound word (term) in the phrases must have a literal
              # OR be bound to an entity type identified by the phrases
              # Any clause that has one binding and no other word is a value instance or simply-identified entity type
              phrases.map! do |phrase|
                next phrase unless l = phrase[:literal]
                binding = phrase[:binding]
                debug :instance, "Making #{binding.concept.class.basename} #{binding.concept.name} using #{l.inspect}" do
                  bound_instances[binding] =
                    instance_identified_by_literal(population, binding.concept, l)
                end
                phrase
              end

              if phrases.size == 1 && Hash === (phrase = phrases[0])
                binding = phrase[:binding]
                l = phrase[:literal]
                debug :instance, "Making(2) #{binding.concept.class.basename} #{binding.concept.name} using #{l.inspect}" do
                  bound_instances[binding] =
                    instance_identified_by_literal(population, binding.concept, l)
                end
              else
                [phrases, *bind_fact_reading(nil, qualifiers, phrases)]
              end
            end

          # Because the fact types may include forward references, we must process the list repeatedly
          # until we make no further progress. Any remaining
          progress = true
          pass = 0
          while progress
            progress = false
            pass += 1
            debug :instance, "Pass #{pass}" do
              facts.map! do |fact|
                next fact unless fact.is_a?(Array)
                phrases, fact_type, reading = *fact

                # This is a fact type we bound; see if we can create the fact instance yet

                bare_roles = phrases.select{|w| w.is_a?(Hash) && !w[:literal] && !bound_instances[w[:binding]]}
                # REVISIT: Bare bindings might be bound to instances we created

                debug :instance, "Considering '#{fact_type.preferred_reading.expand}' with bare roles: #{bare_roles.map{|role| role[:binding].concept.name}*", "} "

                case
                when bare_roles.size == 0
                  debug :instance, "All bindings in '#{fact_type.preferred_reading.expand}' contain instances; create the fact type"
                  instances = phrases.select{|p| p.is_a?(Hash)}.map{|p| bound_instances[p[:binding]]}
                  debug :instance, "Instances are #{instances.map{|i| "#{i.concept.name} #{i.value.inspect}"}*", "}"

                  # Check that this fact doesn't already exist
                  fact = fact_type.all_fact.detect{|f|
                    # Get the role values of this fact in the order of the reading we just bound
                    role_values_in_reading_order = f.all_role_value.sort_by do |rv|
                      reading.role_sequence.all_role_ref.detect{|rr| rr.role == rv.role}.ordinal
                    end
                    # If all this fact's role values are played by the bound instances, it's the same fact
                    !role_values_in_reading_order.zip(instances).detect{|rv, i| rv.instance != i }
                  }
                  unless fact
                    fact = @constellation.Fact(:new, :fact_type => fact_type, :population => population)
                    @constellation.Instance(:new, :concept => fact_type.entity_type, :fact => fact, :population => population)
                    reading.role_sequence.all_role_ref.zip(instances).each do |rr, instance|
                      debug :instance, "New fact has #{instance.concept.name} role #{instance.value.inspect}"
                      @constellation.RoleValue(:fact => fact, :instance => instance, :role => rr.role, :population => population)
                    end
                  else
                    debug :instance, "Found existing fact type instance"
                  end
                  progress = true
                  next fact

                # If we have one bare role (no literal or instance) played by an entity type,
                # and the bound fact type participates in the identifier, we might now be able
                # to create the entity instance.
                when bare_roles.size == 1 &&
                  (binding = bare_roles[0][:binding]) &&
                  (e = binding.concept).is_a?(ActiveFacts::Metamodel::EntityType) &&
                  e.preferred_identifier.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type == fact_type}

                  # Check this instance doesn't already exist already:
                  identifying_binding = (phrases.select{|p| Hash === p}.map{|p|p[:binding]}-[binding])[0]
                  identifying_instance = bound_instances[identifying_binding]

                  debug :instance, "This clause associates a new #{binding.concept.name} with a #{identifying_binding.concept.name}#{identifying_instance ? " which exists" : ""}"

                  identifying_role_ref = e.preferred_identifier.role_sequence.all_role_ref.detect { |rr|
                      rr.role.fact_type == fact_type && rr.role.concept == identifying_binding.concept
                    }
                  unless identifying_role_ref
                    debug :instance, "Failed to find a #{identifying_instance.concept.name}"
                    next fact # We can't do this yet
                  end
                  role_value = identifying_instance.all_role_value.detect do |rv|
                    rv.fact.fact_type == identifying_role_ref.role.fact_type
                  end
                  if role_value
                    instance = (role_value.fact.all_role_value.to_a-[role_value])[0].instance
                    debug :instance, "Found existing instance (of #{instance.concept.name}) from a previous definition"
                    bound_instances[binding] = instance
                    progress = true
                    next role_value.instance
                  end

                  pi_role_refs = e.preferred_identifier.role_sequence.all_role_ref
                  # For each pi role, we have to find the fact clause, which contains the binding we need.
                  # Then we have to create an instance of each fact
                  identifiers =
                    pi_role_refs.map do |rr|
                      fact_a = facts.detect{|f| f.is_a?(Array) && f[1] == rr.role.fact_type}
                      identifying_binding = fact_a[0].detect{|phrase| phrase.is_a?(Hash) && phrase[:binding] != binding}[:binding]
                      identifying_instance = bound_instances[identifying_binding]

                      [rr, fact_a, identifying_binding, identifying_instance]
                    end
                  if identifiers.detect{ |i| !i[3] }  # Not all required facts are bound yet
                    debug :instance, "Can't go through with creating #{binding.concept.name}; not all the facts are in"
                    next fact
                  end

                  debug :instance, "Going ahead with creating #{binding.concept.name} using #{identifiers.size} roles"
                  instance = @constellation.Instance(:new, :concept => e, :population => population)
                  bound_instances[binding] = instance
                  identifiers.each do |rr, fact_a, identifying_binding, identifying_instance|
                    # This reading provides the identifying literal for the EntityType e
                    id_fact = @constellation.Fact(:new, :fact_type => rr.role.fact_type, :population => population)
                    role = (rr.role.fact_type.all_role.to_a-[rr.role])[0]
                    @constellation.RoleValue(:instance => instance, :fact => id_fact, :population => population, :role => role)
                    @constellation.RoleValue(:instance => identifying_instance, :fact => id_fact, :role => rr.role, :population => population)
                    true
                  end

                  progress = true
                end
                fact
              end
            end
          end
          incomplete = facts.select{|ft| !ft.is_a?(ActiveFacts::Metamodel::Instance) && !ft.is_a?(ActiveFacts::Metamodel::Fact)}
          if incomplete.size > 0
            # Provide a readable description of the problem here, by showing each binding with no instance
            missing_bindings = incomplete.map do |f|
              phrases = f[0]
              phrases.select{|p|
                p.is_a?(Hash) and binding = p[:binding] and !bound_instances[binding]
              }.map{|phrase| phrase[:binding]}
            end.flatten.uniq
            raise "Not enough facts are given to identify #{
                missing_bindings.map do |b|
                  [ b.leading_adjective, b.concept.name, b.trailing_adjective ].compact*" " +
                  " (need #{b.concept.preferred_identifier.role_sequence.all_role_ref.map do |rr|
                      [ rr.leading_adjective, rr.role.role_name || rr.role.concept.name, rr.trailing_adjective ].compact*" "
                    end*", "
                  })"
                end*", "
              }"
          end
        end
      end

      def entity_identified_by_literal(population, concept, literal)
        # A literal that identifies an entity type means the entity type has only one identifying role
        # That role is played either by a value type, or by another similarly single-identified entity type
        debug "Making EntityType #{concept.name} identified by '#{literal}' #{population.name.size>0 ? " in "+population.name.inspect : ''}" do
          identifying_role_refs = concept.preferred_identifier.role_sequence.all_role_ref
          raise "Single literal cannot satisfy multiple identifying roles for #{concept.name}" if identifying_role_refs.size > 1
          role = identifying_role_refs.single.role
          identifying_instance = instance_identified_by_literal(population, role.concept, literal)
          existing_instance = nil
          instance_rv = identifying_instance.all_role_value.detect { |rv|
            next false unless rv.population == population         # Not this population
            next false unless rv.fact.fact_type == role.fact_type # Not this fact type
            other_role_value = (rv.fact.all_role_value-[rv])[0]
            existing_instance = other_role_value.instance
            other_role_value.instance.concept == concept          # Is it this concept?
          }
          if instance_rv
            instance = existing_instance
            debug :instance, "This #{concept.name} entity already exists"
          else
            fact = @constellation.Fact(:new, :fact_type => role.fact_type, :population => population)
            instance = @constellation.Instance(:new, :concept => concept, :population => population)
            # The identifying fact type has two roles; create both role instances:
            @constellation.RoleValue(:instance => identifying_instance, :fact => fact, :population => population, :role => role)
            @constellation.RoleValue(:instance => instance, :fact => fact, :population => population, :role => (role.fact_type.all_role-[role])[0])
          end
          instance
        end
      end

      def instance_identified_by_literal(population, concept, literal)
        if concept.is_a?(ActiveFacts::Metamodel::EntityType)
          entity_identified_by_literal(population, concept, literal)
        else
          debug :instance, "Making ValueType #{concept.name} #{literal.inspect} #{population.name.size>0 ? " in "+population.name.inspect : ''}" do

            is_a_string = String === literal
            instance = @constellation.Instance.detect do |key, i|
                # REVISIT: And same unit
                i.population == population &&
                  i.value &&
                  i.value.literal == literal &&
                  i.value.is_a_string == is_a_string
              end
            #instance = concept.all_instance.detect { |instance|
            #  instance.population == population && instance.value == literal
            #}
            debug :instance, "This #{concept.name} value already exists" if instance
            unless instance
              instance = @constellation.Instance(
                  :new,
                  :concept => concept,
                  :population => population,
                  :value => [literal.to_s, is_a_string, nil]
                )
            end
            instance
          end
        end
      end

      def constraint *value
        case type = value.shift
        when :presence
          presence_constraint *value
        when :set
          set_constraint *value
        when :subset
          subset_constraint *value
        when :equality
          equality_constraint *value
        else
          $stderr.puts "REVISIT: external #{type} constraints aren't yet handled:\n\t"+value.map{|a| a.inspect }*"\n\t"
        end
      end

      def presence_constraint(constrained_role_names, quantifier, phrases_list, context, enforcement)
        raise "REVISIT: Join presence constraints not supported yet" if phrases_list[0].size > 1
        phrases_list = phrases_list.map{|r| r[0] }
        #p phrases_list

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

        # Find players for all the concepts in all phrases_list:
        @symbols.bind_roles_in_phrases_list(phrases_list)

        constrained_roles = []
        unmatched_roles = constrained_role_names.clone
        phrases_list.each do |phrases|
          # puts phrases.inspect

          # If this succeeds, the phrases found matches the roles in our phrases
          fact_roles = invoked_fact_roles(phrases)
          raise "Fact type reading not found for #{phrases.inspect}" unless fact_roles

          # Look for the constrained role(s); the bindings will be the same
          matched_bindings = phrases.select{|p| Hash === p}.map{|p| p[:binding]}
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

        # REVISIT: Check that no existing PC spans the same roles (nor a superset nor subset?)

        constraint = @constellation.PresenceConstraint(
            :new,
            :name => '',
            :vocabulary => @vocabulary,
            :role_sequence => rs,
            :min_frequency => quantifier[0],
            :max_frequency => quantifier[1],
            :is_preferred_identifier => false,
            :is_mandatory => quantifier[0] && quantifier[0] > 0
          )
        apply_enforcement(constraint, enforcement) if enforcement
      end

      def set_constraint(constrained_roles, quantifier, joins_list, context, enforcement)
        role_sequences = bind_joins_as_role_sequences(joins_list)

        if quantifier[1] == nil
          # create a presence constraint instead if we get quantifier = [N,nil] (at least N)
          # We massage the bound role sequences to make this work.
          raise "either/or constraint must have one common role" if role_sequences.size != 2 || role_sequences[0].all_role_ref.size != 1
          second_role = role_sequences[1].all_role_ref.single.role
          second_role_ref = @constellation.RoleRef(:role_sequence => role_sequences[0], :ordinal => 1, :role => second_role)
          @constellation.deny(role_sequences[1].all_role_ref.single)
          @constellation.deny(role_sequences[1])
          constraint = @constellation.PresenceConstraint(
              :new,
              :name => '',
              :vocabulary => @vocabulary,
              :role_sequence => role_sequences[0],
              :min_frequency => quantifier[0],
              :max_frequency => nil,
              :is_preferred_identifier => false,
              :is_mandatory => true
            )
          apply_enforcement(constraint, enforcement) if enforcement
        else
          # Create a normal (mandatory) exclusion constraint:
          constraint = @constellation.SetExclusionConstraint(:new)
          constraint.vocabulary = @vocabulary
          role_sequences.each_with_index do |rs, i|
            @constellation.SetComparisonRoles(constraint, i, :role_sequence => rs)
          end
          apply_enforcement(constraint, enforcement) if enforcement
          constraint.is_mandatory = quantifier[0] == 1
        end
      end

      def subset_constraint(joins_list, context, enforcement)
        role_sequences = bind_joins_as_role_sequences(joins_list)

        #puts "subset_constraint:\n\t#{subset_readings.inspect}\n\t#{superset_readings.inspect}"
        #puts "\t#{role_sequences.map{|rs| rs.describe}.inspect}"
        #puts "subset_role_sequence = #{role_sequences[0].describe}"
        #puts "superset_role_sequence = #{role_sequences[1].describe}"

        # create the constraint:
        constraint = @constellation.SubsetConstraint(:new)
        constraint.vocabulary = @vocabulary
        #constraint.name = nil
        #constraint.enforcement = 
        constraint.subset_role_sequence = role_sequences[0]
        constraint.superset_role_sequence = role_sequences[1]
        apply_enforcement(constraint, enforcement) if enforcement
      end

      def equality_constraint(joins_list, context, enforcement)
        #puts "equality\n\t#{joins_list.map{|rl| rl.inspect}*"\n\tif and only if\n\t"}"

        role_sequences = bind_joins_as_role_sequences(joins_list)

        # Create the constraint:
        constraint = @constellation.SetEqualityConstraint(:new)
        constraint.vocabulary = @vocabulary
        role_sequences.each_with_index do |rs, i|
          @constellation.SetComparisonRoles(constraint, i, :role_sequence => rs)
        end
        apply_enforcement(constraint, enforcement) if enforcement
      end

      def fact_type_identification(fact_type, name, prefer)
        if !@symbols.embedded_presence_constraints.detect{|pc| pc.max_frequency == 1}
          # Provide a default identifier for a fact type that's lacking one (over all roles):
          first_role_sequence = fact_type.preferred_reading.role_sequence
          #puts "Creating PC for #{name}: #{fact_type.describe}"
          identifier = @constellation.PresenceConstraint(
              :new,
              :vocabulary => @vocabulary,
              :name => "#{name}PK",            # Is this a useful name?
              :role_sequence => first_role_sequence,
              :is_preferred_identifier => prefer,
              :max_frequency => 1              # Unique
            )
          # REVISIT: The UC might be provided later as an external constraint, relax this rule:
          #raise "'#{fact_type.default_reading}': non-unary fact types having no uniqueness constraints must be objectified (named)" unless fact_type.entity_type
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
          type, qualifiers, phrases, context = *clause

          debug "Clause: #{clause.inspect}"
          roles = phrases.map do |phrase|
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

    end
  end
end
