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
          @supertypes.each do |supertype_name|
            add_supertype(supertype_name, !@identification && supertype_name == supertypes[0])
          end

          context = CompilationContext.new(@vocabulary)

          # Figure out the identification mode or roles, if any:
          if @identification
            if @identification.is_a? ReferenceMode
              vt_name, vt = make_entity_type_refmode_valuetypes(name, @identification.name, @identification.parameters)
              # REVISIT: Decide whether this puts the restriction in the right place:
              @identification = [Compiler::RoleRef.new(vt_name, nil, nil, nil, nil, nil, @identification.restriction, nil)]
            else
              context.allowed_forward_terms = legal_forward_references(@identification)
            end
            debugger
            p @identification
            # REVISIT: Need to bind the RoleRefs in @identifier to context here, so creating the fact type sets the .role
          end

          @readings.each{ |reading| reading.identify_players_with_role_name(context) }
          @readings.each{ |reading| reading.identify_other_players(context) }
          @readings.each{ |reading| reading.bind_roles context }  # Create the Compiler::Roles

          # REVISIT: Loose binding goes here; it might merge some Compiler#Roles

=begin
          # At this point, @identification is an array of RoleRefs and/or Readings (for unary fact types)
          # Have to do this after creating the necessary fact types
          identifying_roles = @identification.map do |identifier|
            if identifier.is_a?(RoleRef)
              # Normal role
            else
              # Unary fact type reference
            end
          end
=end

          debugger
          p @identifier
          puts "REVISIT: Incomplete"

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
            raise "Conflicting assimilation pragmas #{assimilations*", "}" if assimilations.size > 1
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

        # Names used in the identifying roles list may be forward referenced:
        def legal_forward_references(identification_roles)
          identification_roles.map do |phrase|
            phrase.is_a?(RoleRef) ? phrase.term : nil
          end.compact.uniq
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

      end

    end
  end
end

