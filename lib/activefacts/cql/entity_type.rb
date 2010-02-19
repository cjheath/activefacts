#       Compile a CQL string into an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      def entity_type(name, supertypes, identification, mapping_pragmas, clauses)
        #puts "Entity Type #{name}, supertypes #{supertypes.inspect}, id #{identification.inspect}, clauses = #{clauses.inspect}"
        debug :entity, "Defining Entity Type #{name}" do
          # If this entity had been forward referenced, this won't be a new object, and will subsume its roles
          entity_type = @constellation.EntityType(@vocabulary, name)
          entity_type.is_independent = true if (mapping_pragmas.include? 'independent')

          # REVISIT: CQL needs a way to indicate whether subtype migration can occur.
          # For example by saying "Xyz is a role of Abc".
          supertypes.each do |supertype_name|
            add_supertype(entity_type, supertype_name, identification, mapping_pragmas)
          end

          # If we're using a common identification mode, find or create the necessary ValueTypes first:
          vt = vt_name = nil
          identifying_phrases = []
          if identification
            identifying_phrases = identification[:roles]
            context.allowed_forward_terms(legal_forward_references(identifying_phrases)) if identifying_phrases

            if identification[:mode]
              vt_name, vt = make_entity_type_refmode_valuetypes(name, identification[:mode], identification[:parameters])
              identifying_phrases = [[{:term => vt_name, :player => vt}]]
            end
          end

          # Find and set [:player] to the concept (object type) that plays each role:
          resolve_players(phrases_list_from_clauses(clauses) + identifying_phrases)

          # Create all fact types as appropriate:
          fact_types = create_identifying_fact_types(clauses)

          # Create or complete the fact types for the identification mode:
          if identification && identification[:mode]
            complete_reference_mode_fact_type(entity_type, fact_types, vt, identification)
          end

          # Find whether this entity type objectifies some fact type:
          objectified_fact_types = fact_types.select do |fact_type|
              !fact_type.all_role.detect{|r| r.concept == entity_type}
            end
          raise "#{name} can only objectify one fact type" if objectified_fact_types.size > 1
          entity_type.fact_type = objectified_fact_types[0]

          # Find the identifying roles to make the preferred identifier (a unique constraint)
          identifying_roles = find_identifying_roles(entity_type, identifying_phrases, fact_types)

          validate_identifying_fact_types(entity_type, identifying_roles, fact_types-objectified_fact_types)

          make_preferred_identifier_over_roles(entity_type, identifying_roles)
        end
      end


      def create_identifying_fact_types(clauses)
        # Arrange the clauses according to the players (the hash key is the sorted array of player's names)
        cbp = clauses_by_players(clauses)

        # Create all the required fact types
        fact_types = []
        debug :entity, "Entity type contains #{cbp.keys.size} fact types:" do
          cbp.each do |terms, clauses|
            fact_type = nil
            debug :entity, "Fact type over #{terms*', '}" do
              clauses.each_with_index do |clause, index|
                ft = find_existing_fact_type(clause)
                debug :entity, "Fact reading over #{show_phrases(clause[2])}"
                if (ft && ft != fact_type)
                  # We might relax this later, allowing objectification of an existing FT.
                  raise "Cannot use existing fact type #{show_phrases(clause[2])} in entity type definition"
                end
                fact_type ||= ft
                if !fact_type
                  fact_type = make_fact_type_for_clause(clause)
                  make_reading_for_fact_type(fact_type, clause)
                  fact_types << fact_type
                else
                  # Bind against existing readings to extract the required roles:
                  type, qualifiers, phrases, context = *clause
                  match_clause_against_clauses(clause, clauses[0...index])

                  # REVISIT: Any duplicated clauses aren't detected here, we just make a reading for each.
                  make_reading_for_fact_type(fact_type, clause)
                end

                #if clause[2].detect{|p|p.is_a?(Hash) and !p[:role_ref]}
                #  p show_phrases(clause[2])
                #  debugger
                #  puts "Need :role_ref before continueing to embedded constraints"
                #end

                # This relies on the role phrases having been decorated with [:role_ref] values
                make_embedded_presence_constraints(fact_type, clause)
              end
            end
          end
        end

        fact_types
      end

      # Names used in the identifying roles list may be forward referenced:
      def legal_forward_references(identification_roles)
        (identification_roles||[]).map do |phrase|
          phrase.size == 1 && phrase[0].is_a?(Hash) ? phrase[0][:term] : nil
        end.compact.uniq
      end

      # Make sure that the fact types conform to the rules for identifying fact types
      def validate_identifying_fact_types(entity_type, identifying_roles, fact_types)
        fact_types.each do |fact_type|
          entity_role =  fact_type.all_role.detect{|r| r.concept == entity_type}
          raise "#{name} must play a role in all identifying fact types" unless entity_role
          remaining_roles = fact_type.all_role.to_a-[entity_role]
          if remaining_roles.size == 1 and !identifying_roles.include?(remaining_roles[0])
            raise "Definition of #{entity_type.name} may not include non-identifyng fact types: '#{fact_type.preferred_reading.expand}'"
          end
        end
      end

      def find_identifying_roles(entity_type, identifying_phrases, fact_types)
        identifying_phrases.map do |identifying_phrase|
          # We're looking for a role of a fact type that has the same player, same term, same adjectives
          unary_reading = identifying_phrase.size > 1 ? identifying_phrase.map{|p| p.is_a?(Hash) ? "{0}" : p}*" " : nil
          term = identifying_phrase.size == 1 ? identifying_phrase[0] : nil
          role = nil
          fact_types.each do |fact_type|
            # Find the role that this entity type plays
            et_role = fact_type.all_role.detect{|r| r.concept == entity_type}
            next unless et_role

            # If the phrase we're looking for is a unary, the reading must match:
            if unary_reading
              if fact_type.all_role.size == 1 and fact_type.preferred_reading.text == unary_reading
                role = et_role
                break
              end
              next
            end

            unless fact_type.all_role.size == 1 or
              et_role.all_role_ref.detect do |rr|
                rr.role_sequence.all_role_ref.size == 1 and
                  rr.role_sequence.all_presence_constraint.detect do |pc|
                    pc.max_frequency == 1 and pc.enforcement == nil
                  end
              end
              raise "#{entity_type.name} needs uniqueness constraint in '#{et_role.fact_type.preferred_reading.expand}'"
            end

            # Otherwise, the other role must be used in a reading with the same adjectives as this term:
            other_role = (fact_type.all_role.to_a-[et_role])[0]
            next unless other_role
            next if other_role.concept != term[:player]
            if fact_type.all_reading.detect do |reading|
                reading.role_sequence.all_role_ref.detect do |role_ref|
                  role_ref.role == other_role and
                    role_ref.leading_adjective == term[:leading_adjective] and
                    role_ref.trailing_adjective == term[:trailing_adjective]
                end
              end
              role = other_role
              break
            end
          end
          debug :entity, "#{entity_type.name} has identifying role in '#{role.fact_type.preferred_reading.expand}'"
          raise "No identifying role found for #{entity_type.name} #{identifying_phrases[:term]}" unless role
          role
        end
      end

      def complete_reference_mode_fact_type(entity_type, fact_types, identifying_type, identification)
        # Find an existing fact type, if any:
        entity_role = identifying_role = nil
        fact_type = fact_types.detect do |ft|
          identifying_role = ft.all_role.detect{|r| r.concept == identifying_type } and
          entity_role = ft.all_role.detect{|r| r.concept == entity_type }
        end

        # Create an identifying fact type if needed:
        unless fact_type
          fact_type = @constellation.FactType(:new)
          fact_types << fact_type
          entity_role = @constellation.Role(fact_type, 0, :concept => entity_type)
          identifying_role = @constellation.Role(fact_type, 1, :concept => identifying_type)
        end

        if (ranges = identification[:restriction])
          # The restriction applies only to the value role
          identifying_role.role_value_restriction = value_restriction(ranges, identification[:enforcement])
        end

        # Find all role sequences over the fact type's two roles
        rss = entity_role.all_role_ref.select do |rr|
          rr.role_sequence.all_role_ref.size == 2 &&
            (rr.role_sequence.all_role_ref.to_a-[rr])[0].role == identifying_role
        end.map{|rr| rr.role_sequence}

        # Make a forward reading, if there is none already:
        # Find or create RoleSequences for the forward and reverse readings:
        rs01 = rss.select{|rs| rs.all_role_ref.sort_by{|rr| rr.ordinal}.map(&:role) == [entity_role, identifying_role] }[0]
        if !rs01
          rs01 = @constellation.RoleSequence(:new)
          @constellation.RoleRef(rs01, 0, :role => entity_role)
          @constellation.RoleRef(rs01, 1, :role => identifying_role)
        end
        if rs01.all_reading.empty?
          @constellation.Reading(fact_type, fact_type.all_reading.size, :role_sequence => rs01, :text => "{0} has {1}")
          debug :mode, "Creating new forward reading '#{entity_role.concept.name} has #{identifying_type.name}'"
        else
          debug :mode, "Using existing forward reading"
        end

        # Make a reverse reading if none exists
        rs10 = rss.select{|rs| rs.all_role_ref.sort_by{|rr| rr.ordinal}.map(&:role) == [identifying_role, entity_role] }[0]
        if !rs10
          rs10 = @constellation.RoleSequence(:new)
          @constellation.RoleRef(rs10, 0, :role => identifying_role)
          @constellation.RoleRef(rs10, 1, :role => entity_role)
        end
        if rs10.all_reading.empty?
          @constellation.Reading(fact_type, fact_type.all_reading.size, :role_sequence => rs10, :text => "{0} is of {1}")
          debug :mode, "Creating new reverse reading '#{identifying_type.name} is of #{entity_role.concept.name}'"
        else
          debug :mode, "Using existing reverse reading"
        end

        # Entity must have one identifying instance. Find or create the role sequence, then create a PC if necessary
        rs0 = entity_role.all_role_ref.select{|rr| rr.role_sequence.all_role_ref.size == 1}[0]
        if rs0
          rs0 = rs0.role_sequence
          debug :mode, "Using existing EntityType role sequence"
        else
          rs0 = @constellation.RoleSequence(:new)
          @constellation.RoleRef(rs0, 0, :role => entity_role)
          debug :mode, "Creating new EntityType role sequence"
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
        debug :mode, "identifying_role has #{identifying_role.all_role_ref.size} attached sequences"
        debug :mode, "identifying_role has #{identifying_role.all_role_ref.select{|rr| rr.role_sequence.all_role_ref.size == 1}.size} unary sequences"
        rs1 = identifying_role.all_role_ref.select{|rr| rr.role_sequence.all_role_ref.size == 1 ? rr.role_sequence : nil }.compact[0]
        if (!rs1)
          rs1 = @constellation.RoleSequence(:new)
          @constellation.RoleRef(rs1, 0, :role => identifying_role)
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

      def make_entity_type_refmode_valuetypes(name, mode, parameters)
        vt_name = "#{name}#{mode}"
        vt = nil
        debug :entity, "Preparing value type #{vt_name} for reference mode" do
          # Find or Create an appropriate ValueType called "#{vt_name}", of the supertype "#{mode}"
          unless vt = @constellation.Concept[[@vocabulary.identifying_role_values, vt_name]]
            base_vt = @constellation.ValueType(@vocabulary, mode)
            vt = @constellation.ValueType(@vocabulary, vt_name, :supertype => base_vt)
            if parameters
              length, scale = *parameters
              vt.length = length if length
              vt.scale = scale if scale
            end
          else
            debug :entity, "Value type #{vt_name} already exists"
          end
        end

        # REVISIT: If we do this, it gets emitted twice when we generate CQL.
        # The generator should detect that the restriction is the same and not emit it.
        #if (ranges = identification[:restriction])
        #  vt.value_restriction = value_restriction(ranges, identification[:enforcement])
        #end

        [ vt_name, vt ]
      end

      def make_preferred_identifier_over_roles(entity_type, identifying_roles)
        return unless identifying_roles.size > 0
        role_sequence = @constellation.RoleSequence(:new)
        identifying_roles.each_with_index do |identifying_role, index|
          @constellation.RoleRef(role_sequence, index, :role => identifying_role)
        end

        # Find a uniqueness constraint as PI, or make one
        pc = find_pc_over_roles(identifying_roles)
        if (pc)
          pc.is_preferred_identifier = true
          pc.name = "#{entity_type.name}PK" unless pc.name
          debug "Existing PC #{pc.verbalise} is now PK for #{entity_type.name} #{pc.class.roles.keys.map{|k|"#{k} => "+pc.send(k).verbalise}*", "}"
        else
          # Add a unique constraint over all identifying roles
          pc = @constellation.PresenceConstraint(
              :new,
              :vocabulary => @vocabulary,
              :name => "#{entity_type.name}PK",            # Is this a useful name?
              :role_sequence => role_sequence,
              :is_preferred_identifier => true,
              :max_frequency => 1              # Unique
              #:is_mandatory => true,
              #:min_frequency => 1,
            )
        end
      end

      def add_supertype(entity_type, supertype_name, not_identifying, mapping_pragmas)
        debug :supertype, "Adding supertype #{supertype_name}" do
          identifying_supertype = !not_identifying && entity_type.all_type_inheritance_as_subtype.size == 0
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
      end

    end
  end
end
