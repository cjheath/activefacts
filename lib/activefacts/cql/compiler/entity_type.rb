module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class ReferenceMode
        attr_reader :name, :value_constraint, :parameters

        def initialize name, value_constraint, parameters
          @name = name
          @value_constraint = value_constraint
          @parameters = parameters
        end

        def to_s
          "identified by its #{name}" +
            ((p = @parameters).size > 0 ? '('+p*', '+')' : '') +
            ((v = @value_constraint) ? v.to_s : '')
        end
      end

      class EntityType < ObjectType
        def initialize name, supertypes, identification, pragmas, clauses, context_note
          super name
          @supertypes = supertypes
          @identification = identification
          @pragmas = pragmas
          @clauses = clauses || []
	  @context_note = context_note
        end

        def compile
          @entity_type = @vocabulary.valid_entity_type_name(@name) ||
	    @constellation.EntityType(@vocabulary, @name, :concept => :new)
          @entity_type.is_independent = true if @pragmas.delete('independent')

          # REVISIT: CQL needs a way to indicate whether subtype migration can occur.
          # For example by saying "Xyz is a role of Abc".
          @supertypes.each_with_index do |supertype_name, i|
            add_supertype(supertype_name, @identification || i > 0)
          end
	  @pragmas.each do |p|
	    @constellation.ConceptAnnotation(:concept => @entity_type.concept, :mapping_annotation => p)
	  end if @pragmas

          context = CompilationContext.new(@vocabulary)

          # Identification may be via a mode (create it) or by forward-referenced entity types (allow those):
          prepare_identifier context

          context.bind @clauses, @identification.is_a?(Array) ? @identification : []

          # Create the fact types that define the identifying roles:
          fact_types = create_identifying_fact_types context

          # At this point, @identification is an array of References and/or Clauses (for unary fact types)
          # Have to do this after creating the necessary fact types
          complete_reference_mode_fact_type fact_types

          # Find the roles to use if we have to create an identifying uniqueness constraint:
          identifying_roles = bind_identifying_roles context

          make_preferred_identifier_over_roles identifying_roles

	  if @context_note
	    @context_note.compile(@constellation, @entity_type)
	  end

          @clauses.each do |clause|
            next unless clause.context_note
            clause.context_note.compile(@constellation, @entity_type)
          end

          @entity_type
        end

        def prepare_identifier context
          # Figure out the identification mode or roles, if any:
          if @identification
            if @identification.is_a? ReferenceMode
              make_entity_type_refmode_valuetypes(name, @identification.name, @identification.parameters)
              vt_name = @reference_mode_value_type.name
              @identification = [Compiler::Reference.new(vt_name, nil, nil, nil, nil, nil, @identification.value_constraint, nil)]
            else
              context.allowed_forward_terms = legal_forward_references(@identification)
            end
          end
        end

        # Names used in the identifying roles list may be forward referenced:
        def legal_forward_references(identification_phrases)
          identification_phrases.map do |phrase|
            phrase.is_a?(Reference) ? phrase.term : nil
          end.compact.uniq
        end

        def bind_identifying_roles context
          return unless @identification
          @identification.map do |id|
            if id.is_a?(Reference)
              binding = id.binding
              roles = binding.refs.map{|r|r.role || (rr=r.role_ref and rr.role)}.compact.uniq
              raise "Looking for an occurrence of identifying role #{id.inspect}, but found #{roles.size == 0 ? "none" : roles.size}" if roles.size != 1
              roles[0]
            else
              # id is a clause of a unary fact type.
              id.identify_other_players context
              id.bind context
              matching_clause =
                @clauses.detect { |clause| clause.phrases_match id.phrases }
              raise "Unary identifying role '#{id.inspect}' is not found in the defined fact types" unless matching_clause
              matching_clause.fact_type.all_role.single
            end
          end
        end

        def make_preferred_identifier_over_roles identifying_roles
          return unless identifying_roles && identifying_roles.size > 0
          role_sequence = @constellation.RoleSequence(:new)
          identifying_roles.each_with_index do |identifying_role, index|
            @constellation.RoleRef(role_sequence, index, :role => identifying_role)
          end

          # Find a uniqueness constraint as PI, or make one
          pc = find_pc_over_roles(identifying_roles)
          if (pc)
            pc.is_preferred_identifier = true
            pc.name = "#{@entity_type.name}PK" unless pc.name
            trace :constraint, "Existing PC #{pc.verbalise} is now PK for #{@entity_type.name}"
          else
            # Add a unique constraint over all identifying roles
            pc = @constellation.PresenceConstraint(
                :new,
                :vocabulary => @vocabulary,
                :name => "#{@entity_type.name}PK",            # Is this a useful name?
                :role_sequence => role_sequence,
                :is_preferred_identifier => true,
                :max_frequency => 1              # Unique
                #:is_mandatory => true,
                #:min_frequency => 1,
              )
	    trace :constraint, "Made new preferred PC GUID=#{pc.concept.guid} min=nil max=1 over #{role_sequence.describe}"
          end
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

        def create_identifying_fact_types context
          fact_types = []
          # Categorise the clauses into fact types according to the roles they play.
          @clauses.inject({}) do |hash, clause|
            players_key = clause.refs.map{|vr| vr.key.compact}.sort
            (hash[players_key] ||= []) << clause
            hash
          end.each do |players_key, clauses|
            # REVISIT: Loose binding goes here; it might merge some Compiler#Roles

            fact_type = create_identifying_fact_type(context, clauses)
            fact_types << fact_type if fact_type
	    unless fact_type.all_role.detect{|r| r.object_type == @entity_type}
	      objectify_existing_fact_type(fact_type)
	    end
          end
          fact_types
        end

        def create_identifying_fact_type context, clauses
          # See if any fact type already exists (this ET cannot be a player, but might objectify it)
          existing_clauses = clauses.select{ |clause| clause.match_existing_fact_type context }
	  if negation = existing_clauses.detect{|c| c.certainty == false }
	    raise "#{@name} cannot be identified by negated fact type #{negation.inspect}"
	  end
          any_matched = existing_clauses.size > 0

          operation = any_matched ? 'Objectifying' : 'Creating'
          player_names = clauses[0].refs.map{|vr| vr.key.compact*'-'}
          trace :matching, "#{operation} fact type for #{clauses.size} clauses over (#{player_names*', '})" do
            if any_matched  # There's an existing fact type we must be objectifying
              fact_type = objectify_existing_fact_type(existing_clauses[0].fact_type)
            end

            unless fact_type
              fact_type = clauses[0].make_fact_type(@vocabulary)
              clauses[0].make_reading(@vocabulary, fact_type)
              clauses[0].make_embedded_constraints vocabulary
              existing_clauses = [clauses[0]]
            end

            (clauses - existing_clauses).each do |clause|
              clause.make_reading(@vocabulary, fact_type)
              clause.make_embedded_constraints vocabulary
            end

            fact_type
          end
        end

        def objectify_existing_fact_type fact_type
          raise "#{@name} cannot objectify fact type '#{fact_type.entity_type.name}' that's already objectified" if fact_type.entity_type
	  if @fact_type
	    raise "#{@name} cannot objectify '#{fact_type.default_reading}', it already objectifies '#{@fact_type.default_reading}'"
	  end

          if fact_type.internal_presence_constraints.select{|pc| pc.max_frequency == 1}.size == 0
            # If there's no existing uniqueness constraint over this fact type, make a spanning one.
            pc = @constellation.PresenceConstraint(
              :new,
              :vocabulary => @vocabulary,
              :name => @entity_type.name+"UQ",
              :role_sequence => fact_type.preferred_reading.role_sequence,
              :is_preferred_identifier => false,  # We only get here when there is a reference mode on the entity type
              :max_frequency => 1
            )
	    trace :constraint, "Made new objectification PC GUID=#{pc.concept.guid} min=nil max=1 over #{fact_type.preferred_reading.role_sequence.describe}"
          end

          @fact_type = @entity_type.fact_type = fact_type
          @entity_type.create_implicit_fact_types # REVISIT: Could there be readings for the implicit fact types here?
          @fact_type
        end

        def add_supertype(supertype_name, not_identifying)
          trace :supertype, "Adding #{not_identifying ? '' : 'identifying '}supertype #{supertype_name} to #{@entity_type.name}" do
            supertype = @vocabulary.valid_entity_type_name(supertype_name) ||
	      @constellation.EntityType(@vocabulary, supertype_name, :concept => :new) # Should always already exist

            # Did we already know about this supertyping?
            return if @entity_type.all_type_inheritance_as_subtype.detect{|ti| ti.supertype == supertype}

            # By default, the first supertype identifies this entity type
            is_identifying_supertype = !not_identifying && @entity_type.all_type_inheritance_as_subtype.size == 0

            inheritance_fact = @constellation.TypeInheritance(@entity_type, supertype, :concept => :new)

	    assimilation_pragmas = ['absorbed', 'separate', 'partitioned']
            assimilations = @pragmas.select { |p| assimilation_pragmas.include? p}
	    @pragmas -= assimilation_pragmas
            raise "Conflicting assimilation pragmas #{assimilations*', '}" if assimilations.size > 1
            inheritance_fact.assimilation = assimilations[0]

            # Create a reading:
            sub_role = @constellation.Role(inheritance_fact, 0, :object_type => @entity_type, :concept => :new)
            super_role = @constellation.Role(inheritance_fact, 1, :object_type => supertype, :concept => :new)

            rs = @constellation.RoleSequence(:new)
            @constellation.RoleRef(rs, 0, :role => sub_role)
            @constellation.RoleRef(rs, 1, :role => super_role)
            @constellation.Reading(inheritance_fact, 0, :role_sequence => rs, :text => "{0} is a kind of {1}", :is_negative => false)

            rs2 = @constellation.RoleSequence(:new)
            @constellation.RoleRef(rs2, 0, :role => super_role)
            @constellation.RoleRef(rs2, 1, :role => sub_role)
            # Decide in which order to include is a/is an. Provide both, but in order.
            n = 'aeioh'.include?(sub_role.object_type.name.downcase[0]) ? 'n' : ''
            @constellation.Reading(inheritance_fact, 2, :role_sequence => rs2, :text => "{0} is a#{n} {1}", :is_negative => false)

            if is_identifying_supertype
              inheritance_fact.provides_identification = true
            end

            # Create uniqueness constraints over the subtyping fact type.
            p1rs = @constellation.RoleSequence(:new)
            @constellation.RoleRef(p1rs, 0).role = sub_role
            pc1 = @constellation.PresenceConstraint(:new, :vocabulary => @vocabulary)
            pc1.name = "#{@entity_type.name}MustHaveSupertype#{supertype.name}"
            pc1.role_sequence = p1rs
            pc1.is_mandatory = true   # A subtype instance must have a supertype instance
            pc1.min_frequency = 1
            pc1.max_frequency = 1
            pc1.is_preferred_identifier = false
	    trace :constraint, "Made new subtype PC GUID=#{pc1.concept.guid} min=1 max=1 over #{p1rs.describe}"

            p2rs = @constellation.RoleSequence(:new)
            constellation.RoleRef(p2rs, 0).role = super_role
            pc2 = constellation.PresenceConstraint(:new, :vocabulary => @vocabulary)
            pc2.name = "#{supertype.name}MayBeA#{@entity_type.name}"
            pc2.role_sequence = p2rs
            pc2.is_mandatory = false
            pc2.min_frequency = 0
            pc2.max_frequency = 1
            # The supertype role often identifies the subtype:
            pc2.is_preferred_identifier = inheritance_fact.provides_identification
	    trace :supertype, "identification of #{@entity_type.name} via supertype #{supertype.name} was #{inheritance_fact.provides_identification ? '' : 'not '}added"
	    trace :constraint, "Made new supertype PC GUID=#{pc2.concept.guid} min=1 max=1 over #{p2rs.describe}"
          end
        end

        def make_entity_type_refmode_valuetypes(name, mode, parameters)
          vt_name = "#{name}#{mode}"
          vt = nil
          trace :entity, "Preparing value type #{vt_name} for reference mode" do
            # Find an existing ValueType called 'vt_name' or 'name vtname'
	    # or find/create the supertype '#{mode}' and the subtype
            unless vt = @vocabulary.valid_object_type_name(vt_name) or
		   vt = @vocabulary.valid_object_type_name(vt_name = "#{name} #{mode}")
              base_vt = @vocabulary.valid_value_type_name(mode) ||
		  @constellation.ValueType(@vocabulary, mode, :concept => :new)
              vt = @constellation.ValueType(@vocabulary, vt_name, :supertype => base_vt, :concept => :new)
              if parameters
                length, scale = *parameters
                vt.length = length if length
                vt.scale = scale if scale
              end
            else
              trace :entity, "Value type #{vt_name} already exists"
            end
          end

          # REVISIT: If we do this, it gets emitted twice when we generate CQL.
          # The generator should detect that the value_constraint is the same and not emit it.
          #if (ranges = identification[:value_constraint])
          #  vt.value_constraint = value_constraint(ranges, identification[:enforcement])
          #end
          @reference_mode_value_type = vt
        end

        def complete_reference_mode_fact_type(fact_types)
          return unless identifying_type = @reference_mode_value_type

          # Find an existing fact type, if any:
          entity_role = identifying_role = nil
          fact_type = fact_types.detect do |ft|
            identifying_role = ft.all_role.detect{|r| r.object_type == identifying_type } and
            entity_role = ft.all_role.detect{|r| r.object_type == @entity_type }
          end

          # Create an identifying fact type if needed:
          unless fact_type
            fact_type = @constellation.FactType(:new)
            fact_types << fact_type
            entity_role = @constellation.Role(fact_type, 0, :object_type => @entity_type, :concept => :new)
            identifying_role = @constellation.Role(fact_type, 1, :object_type => identifying_type, :concept => :new)
          end
          @identification[0].role = identifying_role

          if (value_constraint = @identification[0].value_constraint)
            # The value_constraint applies only to the value role, not to the underlying value type
            # Decide whether this puts the value_constraint in the right place:
            value_constraint.constellation = fact_type.constellation
            identifying_role.role_value_constraint = value_constraint.compile
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
            @constellation.Reading(fact_type, fact_type.all_reading.size, :role_sequence => rs01, :text => "{0} has {1}", :is_negative => false)
            trace :mode, "Creating new forward reading '#{entity_role.object_type.name} has #{identifying_type.name}'"
          else
            trace :mode, "Using existing forward reading"
          end

          # Make a reverse reading if none exists
          rs10 = rss.select{|rs| rs.all_role_ref.sort_by{|rr| rr.ordinal}.map(&:role) == [identifying_role, entity_role] }[0]
          if !rs10
            rs10 = @constellation.RoleSequence(:new)
            @constellation.RoleRef(rs10, 0, :role => identifying_role)
            @constellation.RoleRef(rs10, 1, :role => entity_role)
          end
          if rs10.all_reading.empty?
            @constellation.Reading(fact_type, fact_type.all_reading.size, :role_sequence => rs10, :text => "{0} is of {1}", :is_negative => false)
            trace :mode, "Creating new reverse reading '#{identifying_type.name} is of #{entity_role.object_type.name}'"
          else
            trace :mode, "Using existing reverse reading"
          end

          # Entity must have one identifying instance. Find or create the role sequence, then create a PC if necessary
          rs0 = entity_role.all_role_ref.select{|rr| rr.role_sequence.all_role_ref.size == 1}[0]
          if rs0
            rs0 = rs0.role_sequence
            trace :mode, "Using existing EntityType role sequence"
          else
            rs0 = @constellation.RoleSequence(:new)
            @constellation.RoleRef(rs0, 0, :role => entity_role)
            trace :mode, "Creating new EntityType role sequence"
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
	    trace :constraint, "Made new refmode PC GUID=#{constraint.concept.guid} min=1 max=1 over #{rs0.describe}"
          else
            trace :mode, "Using existing EntityType PresenceConstraint"
          end

          # Value Type must have a value type. Find or create the role sequence, then create a PC if necessary
          trace :mode, "identifying_role has #{identifying_role.all_role_ref.size} attached sequences"
          trace :mode, "identifying_role has #{identifying_role.all_role_ref.select{|rr| rr.role_sequence.all_role_ref.size == 1}.size} unary sequences"
          rs1 = identifying_role.all_role_ref.select{|rr| rr.role_sequence.all_role_ref.size == 1 ? rr.role_sequence : nil }.compact[0]
          if (!rs1)
            rs1 = @constellation.RoleSequence(:new)
            @constellation.RoleRef(rs1, 0, :role => identifying_role)
            trace :mode, "Creating new ValueType role sequence"
          else
            rs1 = rs1.role_sequence
            trace :mode, "Using existing ValueType role sequence"
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
	    trace :constraint, "Made new refmode ValueType PC GUID=#{constraint.concept.guid} min=0 max=1 over #{rs1.describe}"
          else
            trace :mode, "Marking existing ValueType PresenceConstraint as preferred"
            rs1.all_presence_constraint.single.is_preferred_identifier = true
          end
        end

        def to_s
          "EntityType: #{super} #{
            @supertypes.size > 0 ? "< #{@supertypes*','} " : ''
          }#{
            @identification.is_a?(ReferenceMode) ? @identification.to_s : @identification.inspect
          }#{
            @clauses.size > 0 ? " where #{@clauses.inspect}" : ''
          }#{
            @pragmas.size > 0 ? ", pragmas [#{@pragmas*','}]" : ''
          };"
        end
      end

    end
  end
end
