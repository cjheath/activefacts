module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class ReferenceMode
        attr_reader :name, :restriction, :parameters

        def initialize name, restriction, parameters
          @name = name
          @restriction = restriction
          @parameters = parameters
        end
      end

      class EntityType < Concept
        def initialize name, supertypes, identification, pragmas, readings
          super name
          @supertypes = supertypes
          @identification = identification
          @pragmas = pragmas
          @readings = readings || []
        end

        def compile
          @entity_type = @constellation.EntityType(@vocabulary, @name)
          @entity_type.is_independent = true if (@pragmas.include? 'independent')

          # REVISIT: CQL needs a way to indicate whether subtype migration can occur.
          # For example by saying "Xyz is a role of Abc".
          @supertypes.each_with_index do |supertype_name, i|
            add_supertype(supertype_name, @identification || i > 0)
          end

          context = CompilationContext.new(@vocabulary)

          # Identification may be via a mode (create it) or by forward-referenced entity types (allow those):
          prepare_identifier context

          # Create the fact types that define the identifying roles:
          fact_types = create_identifying_fact_types context

          # At this point, @identification is an array of RoleRefs and/or Readings (for unary fact types)
          # Have to do this after creating the necessary fact types
          complete_reference_mode_fact_type fact_types

          # Find the roles to use if we have to create an identifying uniqueness constraint:
          identifying_roles = bind_identifying_roles context

          make_preferred_identifier_over_roles identifying_roles

        end

        def prepare_identifier context
          # Figure out the identification mode or roles, if any:
          if @identification
            if @identification.is_a? ReferenceMode
              make_entity_type_refmode_valuetypes(name, @identification.name, @identification.parameters)
              vt_name = @reference_mode_value_type.name
              @identification = [Compiler::RoleRef.new(vt_name, nil, nil, nil, nil, nil, @identification.restriction, nil)]
            else
              context.allowed_forward_terms = legal_forward_references(@identification)
            end
          end
        end

        # Names used in the identifying roles list may be forward referenced:
        def legal_forward_references(identification_roles)
          identification_roles.map do |phrase|
            phrase.is_a?(RoleRef) ? phrase.term : nil
          end.compact.uniq
        end

        def bind_identifying_roles context
          return unless @identification
          @identification.map do |id|
            if id.is_a?(RoleRef)
              id.identify_player(context)
              binding = id.bind(context)
              roles = binding.refs.map{|r| r.role}.compact.uniq
              raise "Internal error in identifying roles" if roles.size != 1
              roles[0]
            else
              # id is a reading of a unary fact type.
              id.identify_other_players context
              id.bind_roles context
              matching_reading =
                @readings.detect { |reading| reading.phrases_match id.phrases }
              raise "Unary identifying role 'id.inspect' is not found in the defined fact types" unless matching_reading
              matching_reading.fact_type.all_role.single
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
            debug "Existing PC #{pc.verbalise} is now PK for #{@entity_type.name} #{pc.class.roles.keys.map{|k|"#{k} => "+pc.send(k).verbalise}*", "}"
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
          # Categorise the readings into fact types according to the roles they play.
          @readings.each{ |reading| reading.identify_players_with_role_name(context) }
          @readings.each{ |reading| reading.identify_other_players(context) }
          @readings.inject({}) do |hash, reading|
            players_key = reading.role_refs.map{|rr| rr.key.compact}.sort
            (hash[players_key] ||= []) << reading
            hash
          end.each do |players_key, readings|
            readings.each{ |reading| reading.bind_roles context }  # Create the Compiler::Bindings

            # REVISIT: Loose binding goes here; it might merge some Compiler#Roles

            fact_type = create_identifying_fact_type(context, readings)
            fact_types << fact_type if fact_type
          end
          fact_types
        end

        def create_identifying_fact_type context, readings
          # Remove uninteresting assertions:
          readings.reject!{|reading| reading.is_existential_type }
          return nil unless readings.size > 0    # Nothing interesting was said.

          # See if any fact type already exists (this ET cannot be a player, but might objectify it)
          existing_readings = readings.select{ |reading| reading.match_existing_fact_type context }
          any_matched = existing_readings.size > 0

          operation = any_matched ? 'Objectifying' : 'Creating'
          player_names = readings[0].role_refs.map{|rr| rr.key.compact*'-'}
          debug :matching, "#{operation} fact type for #{readings.size} readings over (#{player_names*', '})" do
            if any_matched  # There's an existing fact type we must be objectifying
              fact_type = objectify_existing_fact_type(existing_readings[0].fact_type)
            end

            unless fact_type
              fact_type = readings[0].make_fact_type(@vocabulary)
              readings[0].make_reading(@vocabulary, fact_type)
              readings[0].make_embedded_presence_constraints vocabulary
              existing_readings = [readings[0]]
            end

            (readings - existing_readings).each do |reading|
              reading.make_reading(@vocabulary, fact_type)
              reading.make_embedded_presence_constraints vocabulary
            end

            fact_type
          end
        end

        def objectify_existing_fact_type fact_type
          raise "#{@name} cannot objectify a fact type that's already objectified" if fact_type.entity_type
          raise "#{@name} must only objectofy one fact type" if @fact_type
          @fact_type = entity_type.fact_type = fact_type
        end

        def add_supertype(supertype_name, not_identifying)
          debug :supertype, "Adding supertype #{supertype_name}" do
            supertype = @constellation.EntityType(@vocabulary, supertype_name)

            # Did we already know about this supertype?
            return if @entity_type.all_type_inheritance_as_subtype.detect{|ti| ti.supertype == supertype}

            # By default, the first supertype identifies this entity type
            is_identifying_supertype = !not_identifying && @entity_type.all_type_inheritance_as_subtype.size == 0

            inheritance_fact = @constellation.TypeInheritance(@entity_type, supertype, :fact_type_id => :new)

            assimilations = @pragmas.select { |p| ['absorbed', 'separate', 'partitioned'].include? p}
            raise "Conflicting assimilation pragmas #{assimilations*', '}" if assimilations.size > 1
            inheritance_fact.assimilation = assimilations[0]

            # Create a reading:
            sub_role = @constellation.Role(inheritance_fact, 0, :concept => @entity_type)
            super_role = @constellation.Role(inheritance_fact, 1, :concept => supertype)

            rs = @constellation.RoleSequence(:new)
            @constellation.RoleRef(rs, 0, :role => sub_role)
            @constellation.RoleRef(rs, 1, :role => super_role)
            @constellation.Reading(inheritance_fact, 0, :role_sequence => rs, :text => "{0} is a kind of {1}")
            @constellation.Reading(inheritance_fact, 1, :role_sequence => rs, :text => "{0} is a subtype of {1}")

            rs2 = @constellation.RoleSequence(:new)
            @constellation.RoleRef(rs2, 0, :role => super_role)
            @constellation.RoleRef(rs2, 1, :role => sub_role)
            # Decide in which order to include is a/is an. Provide both, but in order.
            n = 'aeiouh'.include?(sub_role.concept.name.downcase[0]) ? 1 : 0
            @constellation.Reading(inheritance_fact, 2+n, :role_sequence => rs2, :text => "{0} is a {1}")
            @constellation.Reading(inheritance_fact, 3-n, :role_sequence => rs2, :text => "{0} is an {1}")

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
          end
        end

        def make_entity_type_refmode_valuetypes(name, mode, parameters)
          vt_name = "#{name}#{mode}"
          vt = nil
          debug :entity, "Preparing value type #{vt_name} for reference mode" do
            # Find or Create an appropriate ValueType called '#{vt_name}', of the supertype '#{mode}'
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
          @reference_mode_value_type = vt
        end

        def complete_reference_mode_fact_type(fact_types)
          return unless identifying_type = @reference_mode_value_type

          # Find an existing fact type, if any:
          entity_role = identifying_role = nil
          fact_type = fact_types.detect do |ft|
            identifying_role = ft.all_role.detect{|r| r.concept == identifying_type } and
            entity_role = ft.all_role.detect{|r| r.concept == @entity_type }
          end

          # Create an identifying fact type if needed:
          unless fact_type
            fact_type = @constellation.FactType(:new)
            fact_types << fact_type
            entity_role = @constellation.Role(fact_type, 0, :concept => @entity_type)
            identifying_role = @constellation.Role(fact_type, 1, :concept => identifying_type)
          end
          @identification[0].role = identifying_role

          if (restriction = @identification[0].restriction)
            # The restriction applies only to the value role, not to the underlying value type
            # REVISIT: Decide whether this puts the restriction in the right place:
            identifying_role.role_value_restriction = restriction.compile fact_type.constellation
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

      end

    end
  end
end

