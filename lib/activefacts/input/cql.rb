#       Compile a CQL file into an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/cql/parser'
#require 'activefacts/cql/compiler'

module ActiveFacts
  module Input #:nodoc:
    # Compile CQL to an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --<generator> <file>.cql
    class CQL
    private
      include ActiveFacts
      include ActiveFacts::Metamodel

      class SymbolTable; end #:nodoc:

      RingTypes = %w{acyclic intransitive symmetric asymmetric transitive antisymmetric irreflexive reflexive}
      RingPairs = {
          :intransitive => [:acyclic, :asymmetric, :symmetric],
          :irreflexive => [:symmetric]
        }

      def initialize(file, filename = "stdin")
        @file = file
        @filename = filename
      end

    public
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
        readstring(file.read, filename)
      end 

      # Read the specified input stream:
      def self.readstring(str, filename = "string")
        CQL.new(str, filename).read
      end 

      # Read the input, returning a new Vocabulary:
      def read  #:nodoc:
        @constellation = ActiveFacts::API::Constellation.new(ActiveFacts::Metamodel)

        @parser = ActiveFacts::CQL::Parser.new

        # The syntax tree created from each parsed CQL statement gets passed to the block.
        # parse_all returns an array of the block's non-nil return values.
        result = @parser.parse_all(@file, :definition) do |node|
            begin
              kind, *value = d = @parser.definition(node)
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

    private
      def value_type(name, base_type_name, parameters, unit, ranges, mapping_pragmas)
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
          vt.value_restriction = value_restriction ranges
        end
      end

      def value_restriction(ranges)
        vr = @constellation.ValueRestriction(:new)
        ranges.each do |range|
          min, max = Array === range ? range : [range, range]
          v_range = @constellation.ValueRange(
            min ? [min.to_s, true] : nil,
            max ? [max.to_s, true] : nil
            )
          ar = @constellation.AllowedRange(vr, v_range)
        end
        vr
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
            #  vt.value_restriction = value_restriction(ranges)
            #end
          end

          # Use a two-pass algorithm for entity fact types...
          # The first step is to find all role references and definitions in the clauses
          # After bind_roles, each phrase in each clause is either:
          # * a string, which is a linking word, or
          # * the phrase hash augmented with a :binding=>Binding
          @symbols = SymbolTable.new(@constellation, @vocabulary)
          @symbols.bind_roles_in_clauses(clauses, identification ? identification[:roles] : nil)

          # Next arrange the clauses according to what fact they belong to,
          # then process each fact type using normal fact type processing.
          # That way if we find a fact type here having none of the players being the
          # entity type, we know it's an objectified fact type. The CQL syntax might make
          # us come here with such a case when the fact type is a subtype of some entity type,
          # such as occurs in the Metamodel with TypeInheritance.

          # N.B. This doesn't allow forward identification by roles with adjectives (see the i[0]):
          @symbols.allowed_forward = (ir = identification && identification[:roles]) ? ir.inject({}){|h, i| h[i[0]] = true; h} : {}

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
            raise "#{role.concept.name} may only play one role in each identifying fact type" if player_roles.size > 1
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
                  value_role.role_value_restriction = value_restriction(ranges)
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
                  @constellation.PresenceConstraint(
                    :new,
                    :name => '',
                    :enforcement => '',
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
                  @constellation.PresenceConstraint(
                    :new,
                    :name => '',
                    :enforcement => '',
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
              #:is_ephemeral => ephemeral,
              :vocabulary => @vocabulary
            )
          base_units.each do |base_unit, exponent|
            base = @constellation.Unit.values.detect{|u| u.name == base_unit}
            debug :units, "Base unit #{base_unit}^#{exponent} #{base ? "" : "(implicitly fundamental)"}"
            base ||= @constellation.Unit(:new, :name => base_unit, :is_fundamental => true, :vocabulary => @vocabulary)
            @constellation.Derivation(:derived_unit => unit, :base_unit => base, :exponent => exponent)
          end
        end
      end

      # If one of the words is the name of the entity type, and the other
      # words consist of a unary fact type reading, return the role it plays.
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

      def fact_type(name, clauses, conditions) 
        debug "Processing clauses for fact type" do
          fact_type = nil

          #
          # The first step is to find all role references and definitions in the phrases
          # This also:
          # * deletes any adjectives that were used but not hyphenated
          # * changes each linking word phrase into a simple String
          # * adds a :binding key to each bound role
          #
          @symbols = SymbolTable.new(@constellation, @vocabulary)
          @symbols.bind_roles_in_clauses(clauses)

          clauses.each do |clause|
            kind, qualifiers, phrases, context = *clause

            fact_type, r = *bind_fact_reading(fact_type, qualifiers, phrases)
          end

          # The fact type has a name iff it's objectified as an entity type
          #puts "============= Creating entity type #{name} to nominalize fact type #{fact_type.default_reading} ======================" if name
          fact_type.entity_type = @constellation.EntityType(@vocabulary, name) if name

          # Add the identifying PresenceConstraint for this fact type:
          if fact_type.all_role.size == 1 && !fact_type.entity_type
            # All is well, unaries don't need an identifying PC unless objectified
          else
            fact_type_identification(fact_type, name, true)
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
                  (e = binding.concept).is_a?(EntityType) &&
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
          incomplete = facts.select{|ft| !ft.is_a?(Instance) && !ft.is_a?(Fact)}
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
        if concept.is_a?(EntityType)
          entity_identified_by_literal(population, concept, literal)
        else
          debug :instance, "Making ValueType #{concept.name} #{literal.inspect} #{population.name.size>0 ? " in "+population.name.inspect : ''}" do
            instance = concept.all_instance.detect { |instance|
              instance.population == population && instance.value == literal
            }
            debug :instance, "This #{concept.name} value already exists" if instance
            unless instance
              instance = @constellation.Instance(:new, :concept => concept, :population => population, :value => literal)
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
        @symbols = SymbolTable.new(@constellation, @vocabulary)
        fact_roles_list = []
        bindings_list = []
        joins_list.each_with_index do |joins, index|
          # joins is an array of phrase arrays, each for one reading
          @symbols.bind_roles_in_phrases_list(joins)

          fact_roles_list << joins.map do |phrases|
            ifr = invoked_fact_roles(phrases)
            raise "Fact type reading not found for #{phrases.inspect}" unless ifr
            ifr
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

      def presence_constraint(constrained_role_names, quantifier, phrases_list, context)
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

      def set_constraint(constrained_roles, quantifier, joins_list, context)
        role_sequences = bind_joins_as_role_sequences(joins_list)

        if quantifier[1] == nil
          # create a presence constraint instead if we get quantifier = [N,nil] (at least N)
          # We massage the bound role sequences to make this work.
          raise "either/or constraint must have one common role" if role_sequences.size != 2 || role_sequences[0].all_role_ref.size != 1
          second_role = role_sequences[1].all_role_ref.single.role
          second_role_ref = @constellation.RoleRef(:role_sequence => role_sequences[0], :ordinal => 1, :role => second_role)
          @constellation.deny(role_sequences[1].all_role_ref.single)
          @constellation.deny(role_sequences[1])
          @constellation.PresenceConstraint(
              :new,
              :name => '',
              :enforcement => '',
              :vocabulary => @vocabulary,
              :role_sequence => role_sequences[0],
              :min_frequency => quantifier[0],
              :max_frequency => nil,
              :is_preferred_identifier => false,
              :is_mandatory => true
            )
        else
          # Create a normal (mandatory) exclusion constraint:
          constraint = @constellation.SetExclusionConstraint(:new)
          constraint.vocabulary = @vocabulary
          role_sequences.each_with_index do |rs, i|
            @constellation.SetComparisonRoles(constraint, i, :role_sequence => rs)
          end
          constraint.is_mandatory = quantifier[0] == 1
        end
      end

      def subset_constraint(joins_list, context)
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
      end

      def equality_constraint(joins_list, context)
        #puts "REVISIT: equality\n\t#{joins_list.map{|rl| rl.inspect}*"\n\tif and only if\n\t"}"

        role_sequences = bind_joins_as_role_sequences(joins_list)

        # Create the constraint:
        constraint = @constellation.SetEqualityConstraint(:new)
        constraint.vocabulary = @vocabulary
        role_sequences.each_with_index do |rs, i|
          @constellation.SetComparisonRoles(constraint, i, :role_sequence => rs)
        end
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

      # For a given phrase array from the parser, find the matching declared reading, and return
      # the array of Role object in the same order as they occur in the reading.
      def invoked_fact_roles(phrases)
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

      def invoked_fact_roles_by_players(phrases, players)
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
                  if (wrr.is_a?(RoleRef))
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
              role.role_value_restriction = value_restriction(ranges)
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
              concept.is_a?(EntityType) ? supertypes(concept) : [concept]
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
          pc = role_ref.role_sequence.all_presence_constraint.single  # Will return nil if there's more than one.
          #puts "Existing PresenceConstraint matches those roles!" if pc
          return pc if pc
        end
        nil
      end

      def add_reading(fact_type, role_sequence, phrases)
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

      def concept_by_name(name)
        player = @constellation.Concept[[@vocabulary.identifying_role_values, name]]

        # REVISIT: Hack to allow facts to refer to standard types that will be imported from standard vocabulary:
        if !player && %w{Date DateAndTime Time}.include?(name)
          player = @constellation.ValueType(@vocabulary.identifying_role_values, name)
        end

        if (!player && @symbols.allowed_forward[name])
          player = @constellation.EntityType(@vocabulary, name)
        end
        player
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
          player = @constellation.Concept[[virv = @vocabulary.identifying_role_values, name]]

          # REVISIT: Hack to allow facts to refer to standard types that will be imported from standard vocabulary:
          if !player && %w{Date DateAndTime Time}.include?(name)
            player = @constellation.ValueType(virv, name)
          end

          if !player && allowed_forward
            player = @constellation.EntityType(@vocabulary, name)
          end

          player
        end

        def bind_roles_in_clauses(clauses, identification = [])
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
          disallow_loose_binding = allowed_forwards.inject({}) { |h, v| h[v] = true; h }
          phrases_list.each do |phrases|
            debug :bind, "Binding phrases"

            phrase_numbers_used_speculatively = []
            disallow_loose_binding_this_reading = disallow_loose_binding.clone
            phrases.each_with_index do |phrase, index|
              la = phrase[:leading_adjective]
              player_name = phrase[:word]
              ta = phrase[:trailing_adjective]
              role_name = phrase[:role_name]

              # We use the preceeding phrase and/or following phrase speculatively if they're simple words:
              preceeding_phrase = nil
              following_phrase = nil
              if !la && index > 0 && (preceeding_phrase = phrases[index-1])
                preceeding_phrase = nil unless String === preceeding_phrase || preceeding_phrase.keys == [:word]
                la = preceeding_phrase[:word] if Hash === preceeding_phrase
              end
              if !ta && (following_phrase = phrases[index+1])
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
                  phrases == phrases_list[0] ? nil : disallow_loose_binding_this_reading  # Never allow loose binding on the first reading
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
                phrases[index] = phrase[:word]
              end
              debug :bind, "Bound phrase: #{phrase.inspect}" + " -> " + (player ? player.name+", "+binding.inspect : phrase[:word].inspect)

            end
            phrase_numbers_used_speculatively.each do |index|
              phrases.delete_at(index)
            end
            debug :bind, "Bound phrases: #{phrases.inspect}"
          end
        end
      end # of SymbolTable class

    end
  end
end
