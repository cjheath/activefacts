#       Compile a CQL string into an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      private

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


    end
  end
end
