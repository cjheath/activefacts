module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class Fact < Definition
        def initialize clauses, population_name = ''
          @clauses = clauses
          @population_name = population_name
        end

        def compile
          @population = @constellation.Population(@vocabulary, @population_name, :guid => :new)

          @context = CompilationContext.new(@vocabulary)
          @context.bind @clauses
          @context.left_contraction_allowed = true
          @clauses.each{ |clause| clause.match_existing_fact_type @context }

          # Figure out the simple existential facts and find fact types:
          @bound_facts = []
          @unbound_clauses = all_clauses.
            map do |clause|
              bind_literal_or_fact_type clause
            end.
            compact

          # Because the fact types may include forward references, we must
          # process the list repeatedly until we make no further progress.
          @pass = 0 # Repeat until we make no more progress:
          true while bind_more_facts

          # Any remaining unbound facts are a problem we can bitch about:
          complain_incomplete unless @unbound_clauses.empty?

          @bound_facts.uniq # N.B. this includes Instance objects (existential facts)
        end

        def bind_literal_or_fact_type clause
          # Every bound word (term) in the phrases must have a literal
          # OR be bound to an entity type identified by the phrases

          # Any clause that has one binding and no other word is
          # either a value instance or a simply-identified entity.
          clause.refs.each do |ref|
            next unless l = ref.literal    # No literal
            next if ref.binding.instance   # Already bound
            player = ref.binding.player
            # raise "A literal may not be an objectification" if ref.role_ref.nested_clauses
            # raise "Not processing facts involving nested clauses yet" if ref.role_ref
            debug :instance, "Making #{player.class.basename} #{player.name} using #{l.inspect}" do
              ref.binding.instance = instance_identified_by_literal(player, l)
            end
            ref
          end

          if clause.phrases.size == 1 and (ref = clause.phrases[0]).is_a?(Compiler::Reference)
            if ref.nested_clauses
              # Assign the objectified fact type as this clause's fact type?
              clause.fact_type = ref.player.fact_type
              clause
            else
              # This is an existential fact (like "Name 'foo'", or "Company 'Microsoft'")
              nil # Nothing to see here, move along
            end
          else
            raise "Fact Type not found: '#{clause.display}'" unless clause.fact_type
            # This instance will be associated with its binding by our caller
            clause
          end
        end

        #
        # Try to bind this clause, and return true if it can be completed
        #
        def bind_clause clause
          return true if clause.fact

          # Find the roles of this clause that do not yet have an instance
          bare_roles = clause.refs.
            select do |ref|
              next false if ref.binding.instance
              next false if ref.literal and
                ref.binding.instance = instance_identified_by_literal(ref.binding.player, ref.literal)
              true
            end

          debug :instance, "Considering '#{clause.display}' with "+
            (bare_roles.empty? ? "no bare roles" : "bare roles: #{bare_roles.map{|ref| ref.player.name}*", "}") do

            # If all the roles are in place, we can bind the rest of this clause:
            return true if bare_roles.size == 0 && bind_complete_fact(clause)

            progress = false
            if bare_roles.size == 1 &&
                (binding = bare_roles[0].binding) &&
                (et = binding.player).is_a?(ActiveFacts::Metamodel::EntityType)
              if et.preferred_identifier.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type == clause.fact_type} &&
                bind_entity_if_identifier_ready(clause, et, binding)
                progress = true
              end
            end

            return true if progress
            debug :instance, "Can't make progress on '#{clause.display}'"
            nil
          end
        end

        # Take one pass through the @unbound_clauses, processing (and removing) any that have all pre-requisites
        def bind_more_facts
          return false unless @unbound_clauses.size > 0
          @pass += 1

          progress = false
          debug :instance, "Pass #{@pass} with #{@unbound_clauses.size} clauses to consider" do
            @unbound_clauses =
              @unbound_clauses.select do |clause|
                action = bind_clause(clause)
                progress = true if action
                !action
              end
            debug :instance, "end of pass, unbound clauses are #{@unbound_clauses.map(&:display)*', '}"
          end # debug
          progress
        end

        # Occasionally we need to search through all the clauses:
        def all_clauses
          @clauses.map do |clause|
            [clause] + clause.refs.map{|vr| vr.nested_clauses}
          end.flatten.compact
        end

        def bind_complete_fact clause
          return true unless clause.fact_type  # An bare objectification
          debug :instance, "All bindings in '#{clause.display}' contain instances; create the fact type"
          instances = clause.refs.map{|vr| vr.binding.instance}
          debug :instance, "Instances are #{instances.map{|i| "#{i.object_type.name} #{i.value.inspect}"}*", "}"

          if e = clause.fact_type.entity_type and
            clause.refs[0].binding.instance.object_type == e
            fact = clause.refs[0].binding.instance.fact
          else
            # Check that this fact doesn't already exist
            fact = clause.fact_type.all_fact.detect do |f|
              # Get the role values of this fact in the order of the clause we just bound
              role_values_in_clause_order = f.all_role_value.sort_by do |rv|
                clause.reading.role_sequence.all_role_ref.detect{|rr| rr.role == rv.role}.ordinal
              end
              # If all this fact's role values are played by the bound instances, it's the same fact
              !role_values_in_clause_order.zip(instances).detect{|rv, i| rv.instance != i }
            end
          end
          if fact
            clause.fact = fact
            debug :instance, "Found existing fact type instance"
          else
            fact =
              clause.fact =
              @constellation.Fact(:new, :fact_type => clause.fact_type, :population => @population)
            @bound_facts << fact

            clause.reading.role_sequence.all_role_ref_in_order.zip(instances).each do |rr, instance|
              debug :instance, "New fact has #{instance.object_type.name} role #{instance.value.inspect}"
              # REVISIT: Any residual adjectives after the fact type matching are lost here.
              @constellation.RoleValue(:fact => fact, :instance => instance, :role => rr.role, :population => @population)
            end
          end

          if !fact.instance && clause.fact_type.entity_type
            # Objectified fact type; create the instance
            # Create the instance that objectifies this fact. We don't have the binding to assign it to though; that'll happen in our caller
            debug :instance, "Objectifying fact as #{clause.fact_type.entity_type.name}"
            instance =
              @constellation.Instance(:new, :object_type => clause.fact_type.entity_type, :fact => fact, :population => @population)
            @bound_facts << instance
          end

          if clause.fact and
            clause.objectified_as and
            instance = clause.fact.instance and
            instance.object_type == clause.objectified_as.binding.player
            clause.objectified_as.binding.instance = instance
          end

          true
        end

        # If we have one bare role (no literal or instance) played by an entity type,
        # and the bound fact type participates in the identifier, we might now be able
        # to create the entity instance.
        def bind_entity_if_identifier_ready clause, entity_type, binding
          # Check this instance doesn't already exist already:
          identifying_binding = (clause.refs.map{|vr| vr.binding}-[binding])[0]
          return false unless identifying_binding # This happens when we have a bare objectification
          identifying_instance = identifying_binding.instance
          preferred_identifier = entity_type.preferred_identifier

          debug :instance, "This clause associates a new #{binding.player.name} with a #{identifying_binding.player.name}#{identifying_instance ? " which exists" : ""}"

          identifying_role_ref = preferred_identifier.role_sequence.all_role_ref.detect { |rr|
              rr.role.fact_type == clause.fact_type && rr.role.object_type == identifying_binding.player
            }
          unless identifying_role_ref
            # This shold never happen; we already bound all refs
            debug :instance, "Failed to find a #{identifying_instance.object_type.name}"
            return false # We can't do this yet
          end
          role_value = identifying_instance.all_role_value.detect do |rv|
            rv.fact.fact_type == identifying_role_ref.role.fact_type
          end
          if role_value
            instance = (role_value.fact.all_role_value.to_a-[role_value])[0].instance
            debug :instance, "Found an existing instance (of #{instance.object_type.name}) from a previous definition"
            binding.instance = instance
            return true  # Done with this clause
          end

          pi_role_refs = preferred_identifier.role_sequence.all_role_ref
          # For each pi role, we have to find the fact clause, which contains the binding we need.
          # Then we have to create an instance of each fact
          identifiers =
            pi_role_refs.map do |rr|
              # Find a clause that provides the identifying_ref for this player:
              identifying_clause = all_clauses.detect do |clause|
                rr.role.fact_type == clause.fact_type &&
                  clause.refs.detect{|vr| vr.binding == binding}
              end
              return false unless identifying_clause
              identifying_ref = identifying_clause.refs.select{|ref| ref.binding != binding}[0]
              identifying_binding = identifying_ref ? identifying_ref.binding : nil
              identifying_instance = identifying_binding.instance

              [rr, identifying_clause, identifying_binding, identifying_instance]
            end
          if identifiers.detect{ |i| !i[3] }  # Not all required facts are bound yet
            debug :instance, "Can't go through with creating #{binding.player.name}; not all the identifying facts are in"
            return false
          end

          debug :instance, "Going ahead with creating #{binding.player.name} using #{identifiers.size} roles" do
            instance = @constellation.Instance(:new, :object_type => entity_type, :population => @population)
            binding.instance = instance
            @bound_facts << instance
            identifiers.each do |rr, identifying_clause, identifying_binding, identifying_instance|
              # This clause provides the identifying literal for the entity_type
              id_fact =
                identifying_clause.fact =
                @constellation.Fact(:new, :fact_type => rr.role.fact_type, :population => @population)
              @bound_facts << id_fact
              role = (rr.role.fact_type.all_role.to_a-[rr.role])[0]
              @constellation.RoleValue(:instance => instance, :fact => id_fact, :population => @population, :role => role)
              @constellation.RoleValue(:instance => identifying_instance, :fact => id_fact, :role => rr.role, :population => @population)
            end
          end

          true  # Done with this clause
        end

        def instance_identified_by_literal object_type, literal
          if object_type.is_a?(ActiveFacts::Metamodel::EntityType)
            entity_identified_by_literal object_type, literal
          else
            debug :instance, "Making ValueType #{object_type.name} #{literal.inspect} #{@population.name.size>0 ? " in "+@population.name.inspect : ''}" do

              is_a_string = String === literal
              instance = @constellation.Instance.detect do |key, i|
                  # REVISIT: And same unit
                  i.population == @population &&
                    i.value &&
                    i.value.literal == literal &&
                    i.value.is_a_string == is_a_string
                end
              #instance = object_type.all_instance.detect { |instance|
              #  instance.population == @population && instance.value == literal
              #}
              debug :instance, "This #{object_type.name} value already exists" if instance
              unless instance
                instance = @constellation.Instance(:new)
                instance.object_type = object_type
                instance.population = @population
                instance.value = [literal.to_s, is_a_string, nil]
                @bound_facts << instance
              end
              instance
            end
          end
        end

        def entity_identified_by_literal object_type, literal
          # A literal that identifies an entity type means the entity type has only one identifying role
          # That role is played either by a value type, or by another similarly single-identified entity type
          debug "Making EntityType #{object_type.name} identified by '#{literal}' #{@population.name.size>0 ? " in "+@population.name.inspect : ''}" do
            identifying_role_refs = object_type.preferred_identifier.role_sequence.all_role_ref
            raise "Single literal cannot satisfy multiple identifying roles for #{object_type.name}" if identifying_role_refs.size > 1
            role = identifying_role_refs.single.role
            # This instance has no binding; the binding is of the entity type not the identifying value type
            identifying_instance = instance_identified_by_literal role.object_type, literal
            existing_instance = nil
            instance_rv = identifying_instance.all_role_value.detect { |rv|
              next false unless rv.population == @population         # Not this population
              next false unless rv.fact.fact_type == role.fact_type # Not this fact type
              other_role_value = (rv.fact.all_role_value-[rv])[0]
              existing_instance = other_role_value.instance
              other_role_value.instance.object_type == object_type          # Is it this object_type?
            }
            if instance_rv
              instance = existing_instance
              debug :instance, "This #{object_type.name} entity already exists"
            else
              # This fact has no clause.
              fact = @constellation.Fact(:new, :fact_type => role.fact_type, :population => @population)
              @bound_facts << fact
              # This instance will be associated with its binding by our caller
              instance = @constellation.Instance(:new, :object_type => object_type, :population => @population)
              @bound_facts << instance
              # The identifying fact type has two roles; create both role instances:
              @constellation.RoleValue(:instance => identifying_instance, :fact => fact, :population => @population, :role => role)
              @constellation.RoleValue(:instance => instance, :fact => fact, :population => @population, :role => (role.fact_type.all_role-[role])[0])
            end
            instance
          end
        end

        def complain_incomplete
          if @unbound_clauses.size > 0
            # Provide a readable description of the problem here, by showing each binding with no instance
            missing_bindings = @unbound_clauses.
              map do |clause|
                clause.refs.
                  select do |refs|
                    !refs.binding.instance
                  end.
                  map do |ref|
                    ref.binding
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
                            [ rr.leading_adjective, rr.role.role_name || rr.role.object_type.name, rr.trailing_adjective ].compact*" "
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

        def to_s
          super+@clauses.map(&:to_s)*', '
        end

      end
    end
  end
end
