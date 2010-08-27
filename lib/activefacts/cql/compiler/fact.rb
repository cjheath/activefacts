module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class Fact < Definition
        def initialize readings, population_name = ''
          @readings = readings
          @population_name = population_name
        end

        def compile
          @population = @constellation.Population(@vocabulary, @population_name)

          @context = CompilationContext.new(@vocabulary)
          @readings.each{ |reading| reading.identify_players_with_role_name(@context) }
          @readings.each{ |reading| reading.identify_other_players(@context) }
          @readings.each{ |reading| reading.bind_roles @context }
          @readings.each{ |reading| reading.match_existing_fact_type @context }

          # Figure out the simple existential facts and find fact types:
          @bound_instances = {}  # Instances indexed by binding
          @bound_fact_types = []
          @bound_facts = []
          @unbound_readings = @readings.
            map do |reading|
              bind_literal_or_fact_type reading
            end.
            compact

          # Because the fact types may include forward references, we must
          # process the list repeatedly until we make no further progress.
          @pass = 0 # Repeat until we make no more progress:
          true while bind_more_facts

          # Any remaining unbound facts are a problem we can bitch about:
          complain_incomplete unless @unbound_readings.empty?

          @bound_facts.uniq # N.B. this includes Instance objects (existential facts)
        end

        def bind_literal_or_fact_type reading
          # Every bound word (term) in the phrases must have a literal
          # OR be bound to an entity type identified by the phrases

          # Any clause that has one binding and no other word is
          # either a value instance or a simply-identified entity.
          reading.role_refs.map do |role_ref|
            next role_ref unless l = role_ref.literal
            player = role_ref.binding.player
            # raise "A literal may not be an objectification" if role_ref.role_ref.objectification_join
            # raise "Not processing facts involving objectification joins yet" if role_ref.role_ref
            debug :instance, "Making #{player.class.basename} #{player.name} using #{l.inspect}" do
              @bound_instances[role_ref.binding] =
                role_ref.binding.instance =
                instance_identified_by_literal(player, l)
            end
            role_ref
          end

          if reading.phrases.size == 1 and (role_ref = reading.phrases[0]).is_a?(Compiler::RoleRef)
            if role_ref.objectification_join
              # Assign the objectified fact type as this reading's fact type?
              reading.fact_type = role_ref.player.fact_type
              reading
            else
              # This is an existential fact (like "Name 'foo'", or "Company 'Microsoft'")
              # @bound_instances[role_ref.binding]
              nil # Nothing to see here, move along
            end
          else
            bound_fact_type = reading.fact_type || reading.match_existing_fact_type(@context)
            raise "Fact Type not found: '#{reading.display}'" unless bound_fact_type
            # This instance will be associated with its binding by our caller
            @bound_fact_types << bound_fact_type
            reading
          end
        end

        #
        # Try to bind this reading, and return:
        # :complete if it can be completed
        # :partial if we made progress
        # nil otherwise
        #
        def bind_reading reading
          # Find the roles of this reading that do not yet have an entry in @bound_instances:
          bare_roles = reading.role_refs.
            select do |role_ref|
              next false if @bound_instances[role_ref.binding]
              next false if role_ref.literal and
                @bound_instances[role_ref.binding] =
                  role_ref.binding.instance =
                  instance_identified_by_literal(role_ref.binding.player, role_ref.literal)
              true
            end

          debug :instance, "Considering '#{reading.display}' with "+
            (bare_roles.empty? ? "no bare roles" : "bare roles: #{bare_roles.map{|role_ref| role_ref.player.name}*", "}") do

            # If all the roles are in place, we can bind the rest of this reading:
            return :complete if bare_roles.size == 0 && bind_complete_fact(reading)

            progress = false
            if bare_roles.size == 1 &&
                (binding = bare_roles[0].binding) &&
                (et = binding.player).is_a?(ActiveFacts::Metamodel::EntityType)
              if et.preferred_identifier.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type == reading.fact_type} &&
                bind_entity_if_identifier_ready(reading, et, binding)
                progress = true
              end
            end

            complete = true
            bare_roles.each do |br|
              if !br.objectification_join
                complete = false                     # This is a role with no join but no bound value either; incomplete
                next
              end

              br.objectification_join.each do |o_reading|
                action = bind_reading(o_reading)      # REVISIT: Shortcut if we've already bound this reading
                progress = true if action
                if action == :complete
                  # The entity instance that objectifies this fact has already been created, but I don't know that it will be available where needed
                  instance = o_reading.fact.instance
                  if instance.concept == br.binding.player
                    br.binding.instance = instance
                  else
                    raise "REVISIT: Can it be any other way?"
                    complete = false if reading.role_refs.size > 1
                  end
                else
                  complete = false                  # We aren't done with this bare_role yet
                end
              end
            end

            return :complete if progress && complete
            return :partial if progress
            debug :instance, "Can't make progress on '#{reading.display}'"
            nil
          end
        end

        # Take one pass through the @unbound_readings, processing (and removing) any that have all pre-requisites
        def bind_more_facts
          @pass += 1

          progress = false
          debug :instance, "Pass #{@pass} with #{@unbound_readings.size} readings to consider" do
            @unbound_readings =
              @unbound_readings.select do |reading|
                action = bind_reading(reading)
                progress = true if action
                action != :complete
              end
            debug :instance, "end of pass, unbound readings are #{@unbound_readings.map(&:display)*', '}"
          end # debug
          progress
        end

        def bind_complete_fact reading
          return true unless reading.fact_type  # An bare objectification
          debug :instance, "All bindings in '#{reading.display}' contain instances; create the fact type"
          instances = reading.role_refs.map{|rr| @bound_instances[rr.binding]}
          debug :instance, "Instances are #{instances.map{|i| "#{i.concept.name} #{i.value.inspect}"}*", "}"

          # Check that this fact doesn't already exist
          fact = reading.fact_type.all_fact.detect{|f|
            # Get the role values of this fact in the order of the reading we just bound
            role_values_in_reading_order = f.all_role_value.sort_by do |rv|
              reading.reading.role_sequence.all_role_ref.detect{|rr| rr.role == rv.role}.ordinal
            end
            # If all this fact's role values are played by the bound instances, it's the same fact
            !role_values_in_reading_order.zip(instances).detect{|rv, i| rv.instance != i }
          }
          if fact
            reading.fact = fact
            debug :instance, "Found existing fact type instance"
          else
            fact =
              reading.fact =
              @constellation.Fact(:new, :fact_type => reading.fact_type, :population => @population)
            @bound_facts << fact

            reading.reading.role_sequence.all_role_ref_in_order.zip(instances).each do |rr, instance|
              debug :instance, "New fact has #{instance.concept.name} role #{instance.value.inspect}"
              # REVISIT: Any residual adjectives after the fact type matching are lost here.
              @constellation.RoleValue(:fact => fact, :instance => instance, :role => rr.role, :population => @population)
            end
          end

          if !fact.instance && reading.fact_type.entity_type
            # Objectified fact type; create the instance
            # Create the instance that objectifies this fact. We don't have the binding to assign it to though; that'll happen in our caller
            debug :instance, "Objectifying fact as #{reading.fact_type.entity_type.name}"
            instance =
              @constellation.Instance(:new, :concept => reading.fact_type.entity_type, :fact => fact, :population => @population)
            @bound_facts << instance
          end
          true
        end

        # If we have one bare role (no literal or instance) played by an entity type,
        # and the bound fact type participates in the identifier, we might now be able
        # to create the entity instance.
        def bind_entity_if_identifier_ready reading, entity_type, binding
          # Check this instance doesn't already exist already:
          identifying_binding = (reading.role_refs.map{|rr| rr.binding}-[binding])[0]
          return false unless identifying_binding # This happens when we have a bare objectification
          identifying_instance = @bound_instances[identifying_binding]
          preferred_identifier = entity_type.preferred_identifier

          debug :instance, "This clause associates a new #{binding.player.name} with a #{identifying_binding.player.name}#{identifying_instance ? " which exists" : ""}"

          identifying_role_ref = preferred_identifier.role_sequence.all_role_ref.detect { |rr|
              rr.role.fact_type == reading.fact_type && rr.role.concept == identifying_binding.player
            }
          unless identifying_role_ref
            # This shold never happen; we already bound all role_refs
            debug :instance, "Failed to find a #{identifying_instance.concept.name}"
            return false # We can't do this yet
          end
          role_value = identifying_instance.all_role_value.detect do |rv|
            rv.fact.fact_type == identifying_role_ref.role.fact_type
          end
          if role_value
            instance = (role_value.fact.all_role_value.to_a-[role_value])[0].instance
            debug :instance, "Found an existing instance (of #{instance.concept.name}) from a previous definition"
            @bound_instances[binding] =
              binding.instance =
              instance
            return true  # Done with this reading
          end

          pi_role_refs = preferred_identifier.role_sequence.all_role_ref
          # For each pi role, we have to find the fact clause, which contains the binding we need.
          # Then we have to create an instance of each fact
          identifiers =
            pi_role_refs.map do |rr|
              identifying_reading = @readings.detect{|reading| rr.role.fact_type == reading.fact_type}
              identifying_role_ref = identifying_reading.role_refs.select{|role_ref| role_ref.binding != binding}[0]
              identifying_binding = identifying_role_ref ? identifying_role_ref.binding : nil
              identifying_instance = @bound_instances[identifying_binding]

              [rr, identifying_reading, identifying_binding, identifying_instance]
            end
          if identifiers.detect{ |i| !i[3] }  # Not all required facts are bound yet
            debug :instance, "Can't go through with creating #{binding.player.name}; not all the identifying facts are in"
            return false
          end

          debug :instance, "Going ahead with creating #{binding.player.name} using #{identifiers.size} roles" do
            instance = @constellation.Instance(:new, :concept => entity_type, :population => @population)
            @bound_instances[binding] =
              binding.instance =
              instance
            @bound_facts << instance
            identifiers.each do |rr, identifying_reading, identifying_binding, identifying_instance|
              # This reading provides the identifying literal for the entity_type
              id_fact =
                identifying_reading.fact =
                @constellation.Fact(:new, :fact_type => rr.role.fact_type, :population => @population)
              @bound_facts << id_fact
              role = (rr.role.fact_type.all_role.to_a-[rr.role])[0]
              @constellation.RoleValue(:instance => instance, :fact => id_fact, :population => @population, :role => role)
              @constellation.RoleValue(:instance => identifying_instance, :fact => id_fact, :role => rr.role, :population => @population)
            end
          end

          true  # Done with this reading
        end

        def instance_identified_by_literal concept, literal
          if concept.is_a?(ActiveFacts::Metamodel::EntityType)
            entity_identified_by_literal concept, literal
          else
            debug :instance, "Making ValueType #{concept.name} #{literal.inspect} #{@population.name.size>0 ? " in "+@population.name.inspect : ''}" do

              is_a_string = String === literal
              instance = @constellation.Instance.detect do |key, i|
                  # REVISIT: And same unit
                  i.population == @population &&
                    i.value &&
                    i.value.literal == literal &&
                    i.value.is_a_string == is_a_string
                end
              #instance = concept.all_instance.detect { |instance|
              #  instance.population == @population && instance.value == literal
              #}
              debug :instance, "This #{concept.name} value already exists" if instance
              unless instance
                instance = @constellation.Instance(
                    :new,
                    :concept => concept,
                    :population => @population,
                    :value => [literal.to_s, is_a_string, nil]
                  )
                @bound_facts << instance
              end
              instance
            end
          end
        end

        def entity_identified_by_literal concept, literal
          # A literal that identifies an entity type means the entity type has only one identifying role
          # That role is played either by a value type, or by another similarly single-identified entity type
          debug "Making EntityType #{concept.name} identified by '#{literal}' #{@population.name.size>0 ? " in "+@population.name.inspect : ''}" do
            identifying_role_refs = concept.preferred_identifier.role_sequence.all_role_ref
            raise "Single literal cannot satisfy multiple identifying roles for #{concept.name}" if identifying_role_refs.size > 1
            role = identifying_role_refs.single.role
            # This instance has no binding; the binding is of the entity type not the identifying value type
            identifying_instance = instance_identified_by_literal role.concept, literal
            existing_instance = nil
            instance_rv = identifying_instance.all_role_value.detect { |rv|
              next false unless rv.population == @population         # Not this population
              next false unless rv.fact.fact_type == role.fact_type # Not this fact type
              other_role_value = (rv.fact.all_role_value-[rv])[0]
              existing_instance = other_role_value.instance
              other_role_value.instance.concept == concept          # Is it this concept?
            }
            if instance_rv
              instance = existing_instance
              debug :instance, "This #{concept.name} entity already exists"
            else
              # This fact has no reading.
              fact = @constellation.Fact(:new, :fact_type => role.fact_type, :population => @population)
              @bound_facts << fact
              # This instance will be associated with its binding by our caller
              instance = @constellation.Instance(:new, :concept => concept, :population => @population)
              @bound_facts << instance
              # The identifying fact type has two roles; create both role instances:
              @constellation.RoleValue(:instance => identifying_instance, :fact => fact, :population => @population, :role => role)
              @constellation.RoleValue(:instance => instance, :fact => fact, :population => @population, :role => (role.fact_type.all_role-[role])[0])
            end
            instance
          end
        end

        def complain_incomplete
          if @unbound_readings.size > 0
            # Provide a readable description of the problem here, by showing each binding with no instance
            missing_bindings = @unbound_readings.
              map do |reading|
                reading.role_refs.
                  select do |rr|
                    !@bound_instances[rr.binding]
                  end.
                  map do |role_ref|
                    role_ref.binding
                  end
              end.
              flatten.
              uniq

            raise "Not enough facts are given to identify #{
                missing_bindings.
                  sort_by{|b| b.key}.
                  map do |b|
                    player_identifier =
                      if b.player.is_a?(ActiveFacts::Metamodel::EntityType)
                        "lacking " +
                          b.player.preferred_identifier.role_sequence.all_role_ref.map do |rr|
                            [ rr.leading_adjective, rr.role.role_name || rr.role.concept.name, rr.trailing_adjective ].compact*" "
                          end*", "
                      else
                        "needs a value"
                      end
                    [
                      b.refs[0].leading_adjective, b.player.name, b.refs[0].trailing_adjective
                    ].compact*" " +
                      " (#{player_identifier})"
                  end*" or "
              }"
          end
        end

      end
    end
  end
end
