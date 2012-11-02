module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      class Definition
        # Make a Variable for every binding present in these clauses
        def build_variables(clauses_list)
          debug :query, "Building variables" do
            query = @constellation.Query(:new)
            all_bindings_in_clauses(clauses_list).
              each do |binding|
                debug :query, "Creating variable #{query.all_variable.size} for #{binding.inspect}"
                binding.variable = @constellation.Variable(query, query.all_variable.size, :object_type => binding.player)
                if literal = binding.refs.detect{|r| r.literal}
                  if literal.kind_of?(ActiveFacts::CQL::Compiler::Reference)
                    literal = literal.literal
                  end
                  unit = @constellation.Unit.detect{|k, v| [v.name, v.plural_name].include? literal.unit} if literal.unit
                  binding.variable.value = [literal.literal.to_s, literal.is_a?(String), unit]
                end
              end
            query
          end
        end

        def build_all_steps(clauses_list)
          roles_by_binding = {}
          debug :query, "Building steps" do
            clauses_list.each do |clause|
              next if clause.is_naked_object_type
              build_steps(clause, roles_by_binding)
            end
          end
          roles_by_binding
        end

        def build_steps clause, roles_by_binding = {}, objectification_node = nil
          plays = []
          incidental_roles = []
          debug :query, "Creating Role Sequence for #{clause.inspect} with #{clause.refs.size} role refs" do
            objectification_step = nil
            clause.refs.each do |ref|
              # These refs are the Compiler::References, which have associated Metamodel::RoleRefs,
              # but we need to create Plays for those roles.
              # REVISIT: Plays may need to save residual_adjectives
              binding = ref.binding
              role = (ref && ref.role) || (ref.role_ref && ref.role_ref.role)
              play = nil

              debugger unless clause.fact_type
              if (clause.fact_type.entity_type)
                # This clause is of an objectified fact type.
                # We need a step from this role to the phantom role, but not
                # for a role that has only one ref (this one) in their binding.
                # Create the Variable and Play in any case though.
                refs_count = binding.refs.size
                objectification_ref_count = 0
                if ref.nested_clauses
                  ref.nested_clauses.each do |ojc|
                    objectification_ref_count += ojc.refs.select{|ref| ref.binding.refs.size > 1}.size
                  end
                end
                refs_count += objectification_ref_count

                debug :query, "Creating Variable #{ref.inspect} (counts #{refs_count}/#{objectification_ref_count}) and objectification Step for #{ref.inspect}" do

                  raise "Internal error: Trying to add role of #{role.object_type.name} to variable for #{binding.variable.object_type.name}" unless binding.variable.object_type == role.object_type
                  play = @constellation.Play(binding.variable, role)

                  if (refs_count <= 1)   # Our work here is done if there are no other refs
                    if objectification_step
                      play.step = objectification_step
                    else
                      incidental_roles << play
                    end
                    next
                  end

                  plays << play
                  unless objectification_node
                    # This is an implicit objectification, just the FT clause, not ET(where ...clause...)
                    # We need to create a Variable for this object, even though it has no References
                    query = binding.variable.query
                    debug :query, "Creating JN#{query.all_variable.size} for #{clause.fact_type.entity_type.name} in objectification"
                    objectification_node = @constellation.Variable(query, query.all_variable.size, :object_type => clause.fact_type.entity_type)
                  end
                  raise "Internal error: Trying to add role of #{role.implicit_fact_type.all_role.single.object_type.name} to variable for #{objectification_node.object_type.name}" unless objectification_node.object_type == role.implicit_fact_type.all_role.single.object_type

                  irole = role.implicit_fact_type.all_role.single
                  raise "Internal error: Trying to add role of #{irole.object_type.name} to variable for #{objectification_node.object_type.name}" unless objectification_node.object_type == irole.object_type
                  objectification_role = @constellation.Play(objectification_node, role.implicit_fact_type.all_role.single)
                  objectification_step = @constellation.Step(objectification_role, play, :fact_type => role.implicit_fact_type)
                  debug :query, "New #{objectification_step.describe}"
                  debug :query, "Associating #{incidental_roles.map(&:describe)*', '} incidental roles with #{objectification_step.describe}" if incidental_roles.size > 0
                  incidental_roles.each { |jr| jr.step = objectification_step }
                  incidental_roles = []
                  plays = []
                end
              else
                debug :query, "Creating Reference for #{ref.inspect}" do
                    # REVISIT: If there's an implicit subtyping step here, create it; then always raise the error here.
                    # I don't want to do this for now because the verbaliser will always verbalise all steps.
                  if binding.variable.object_type != role.object_type and
                    0 == (binding.variable.object_type.supertypes_transitive & role.object_type.supertypes_transitive).size
                    raise "Internal error: Trying to add role of #{role.object_type.name} to variable #{binding.variable.ordinal} for #{binding.variable.object_type.name} in '#{clause.fact_type.default_reading}'"
                  end
                  raise "Internal error: Trying to add role of #{role.object_type.name} to variable #{binding.variable.ordinal} for #{binding.variable.object_type.name}" unless binding.variable.object_type == role.object_type
                  begin
                    play = @constellation.Play(binding.variable, role)
                  rescue ArgumentError => e
                    play = @constellation.Play(binding.variable, role)
                  end
                  plays << play
                end
              end

              if ref.nested_clauses
                # We are looking at a role whose player is an objectification of a fact type,
                # which will have ImplicitFactTypes for each role.
                # Each of these ImplicitFactTypes has a single phantom role played by the objectifying entity type
                # One of these phantom roles is likely to be the subject of an objectification step.
                ref.nested_clauses.each do |r|
                  debug :query, "Building objectification step for #{ref.nested_clauses.inspect}" do
                    build_steps r, roles_by_binding, binding.variable
                  end
                end
              end
              roles_by_binding[binding] = [role, play]
            end
          end

          if plays.size > 0
            end_node = plays[-1].variable
            if !clause.fact_type.entity_type and role = clause.fact_type.all_role.single
              # Don't give the ImplicitBoolean a variable. We can live without one, for now.
              # The Step will have a duplicate node, and the fact type will tell us what's happening
              plays << plays[0]
            end
            # We aren't talking about objectification here, so there must be exactly two roles.
            raise "REVISIT: Internal error constructing step for #{clause.inspect}" if plays.size != 2
            js = @constellation.Step(plays[0], plays[1], :fact_type => clause.fact_type)
            debug :query, "New Step #{js.describe}"
            debug :query, "Associating #{incidental_roles.map(&:describe)*', '} incidental roles with #{js.describe}" if incidental_roles.size > 0
            incidental_roles.each { |jr| jr.step = js }
          end
          roles_by_binding
        end

        # Return the unique array of all bindings in these clauses, including in objectification steps
        def all_bindings_in_clauses clauses
          clauses.map do |clause|
            clause.refs.map do |ref|
              raise "Binding reference #{ref.inspect} is not bound to a binding" unless ref.binding
              [ref.binding] + (ref.nested_clauses ? all_bindings_in_clauses(ref.nested_clauses) : [])
            end
          end.
            flatten.
            uniq
        end
      end
    end
  end
end
