module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      class Definition
        # Make a JoinNode for every variable present in these clauses
        def build_join_nodes(clauses_list)
          debug :join, "Building join nodes" do
            join = @constellation.Join(:new)
            all_variables_in_clauses(clauses_list).
              each do |variable|
                debug :join, "Creating join node #{join.all_join_node.size} for #{variable.inspect}"
                variable.join_node = @constellation.JoinNode(join, join.all_join_node.size, :object_type => variable.player)
                if literal = variable.refs.detect{|r| r.literal}
                  unit = @constellation.Unit.detect{|k, v| [v.name, v.plural_name].include? literal.unit} if literal.unit
                  variable.join_node.value = [literal.literal.to_s, literal.is_a?(String), unit]
                end
              end
            join
          end
        end

        def build_all_join_steps(clauses_list)
          roles_by_variable = {}
          debug :join, "Building join steps" do
            clauses_list.each do |clause|
              next if clause.is_naked_object_type
              build_join_steps(clause, roles_by_variable)
            end
          end
          roles_by_variable
        end

        def build_join_steps clause, roles_by_variable = {}, objectification_node = nil
          join_roles = []
          incidental_roles = []
          debug :join, "Creating join Role Sequence for #{clause.inspect} with #{clause.var_refs.size} role refs" do
            objectification_step = nil
            clause.var_refs.each do |var_ref|
              # These var_refs are the Compiler::VarRefs, which have associated Metamodel::RoleRefs,
              # but we need to create JoinRoles for those roles.
              # REVISIT: JoinRoles may need to save residual_adjectives
              variable = var_ref.variable
              role = (var_ref && var_ref.role) || var_ref.role_ref.role
              join_role = nil

              if (clause.fact_type.entity_type)
                # This clause is of an objectified fact type.
                # We need a join step from this role to the phantom role, but not
                # for a role that has only one var_ref (this one) in their variable.
                # Create the JoinNode and JoinRole in any case though.
                refs_count = variable.refs.size
                objectification_ref_count = 0
                if var_ref.nested_clauses
                  var_ref.nested_clauses.each do |ojc|
                    objectification_ref_count += ojc.var_refs.select{|var_ref| var_ref.variable.refs.size > 1}.size
                  end
                end
                refs_count += objectification_ref_count

                debug :join, "Creating Join Node #{var_ref.inspect} (counts #{refs_count}/#{objectification_ref_count}) and objectification Join Step for #{var_ref.inspect}" do

                  raise "Internal error: Trying to add role of #{role.object_type.name} to join node for #{variable.join_node.object_type.name}" unless variable.join_node.object_type == role.object_type
                  join_role = @constellation.JoinRole(variable.join_node, role)

                  if (refs_count <= 1)   # Our work here is done if there are no other refs
                    if objectification_step
                      join_role.join_step = objectification_step
                    else
                      incidental_roles << join_role
                    end
                    next
                  end

                  join_roles << join_role
                  unless objectification_node
                    # This is an implicit objectification, just the FT clause, not ET(where ...clause...)
                    # We need to create a JoinNode for this object, even though it has no VarRefs
                    join = variable.join_node.join
                    debug :join, "Creating JN#{join.all_join_node.size} for #{clause.fact_type.entity_type.name} in objectification"
                    objectification_node = @constellation.JoinNode(join, join.all_join_node.size, :object_type => clause.fact_type.entity_type)
                  end
                  raise "Internal error: Trying to add role of #{role.implicit_fact_type.all_role.single.object_type.name} to join node for #{objectification_node.object_type.name}" unless objectification_node.object_type == role.implicit_fact_type.all_role.single.object_type

                  irole = role.implicit_fact_type.all_role.single
                  raise "Internal error: Trying to add role of #{irole.object_type.name} to join node for #{objectification_node.object_type.name}" unless objectification_node.object_type == irole.object_type
                  objectification_role = @constellation.JoinRole(objectification_node, role.implicit_fact_type.all_role.single)
                  objectification_step = @constellation.JoinStep(objectification_role, join_role, :fact_type => role.implicit_fact_type)
                  debug :join, "New #{objectification_step.describe}"
                  debug :join, "Associating #{incidental_roles.map(&:describe)*', '} incidental roles with #{objectification_step.describe}" if incidental_roles.size > 0
                  incidental_roles.each { |jr| jr.join_step = objectification_step }
                  incidental_roles = []
                  join_roles = []
                end
              else
                debug :join, "Creating VarRef for #{var_ref.inspect}" do
                    # REVISIT: If there's an implicit subtyping join here, create it; then always raise the error here.
                    # I don't want to do this for now because the verbaliser will always verbalise all join steps.
                  if variable.join_node.object_type != role.object_type and
                    0 == (variable.join_node.object_type.supertypes_transitive & role.object_type.supertypes_transitive).size
                    raise "Internal error: Trying to add role of #{role.object_type.name} to join node #{variable.join_node.ordinal} for #{variable.join_node.object_type.name} in '#{clause.fact_type.default_reading}'"
                  end
                  raise "Internal error: Trying to add role of #{role.object_type.name} to join node #{variable.join_node.ordinal} for #{variable.join_node.object_type.name}" unless variable.join_node.object_type == role.object_type
                  join_role = @constellation.JoinRole(variable.join_node, role)
                  join_roles << join_role
                end
              end

              if var_ref.nested_clauses
                # We are looking at a role whose player is an objectification of a fact type,
                # which will have ImplicitFactTypes for each role.
                # Each of these ImplicitFactTypes has a single phantom role played by the objectifying entity type
                # One of these phantom roles is likely to be the subject of an objectification join step.
                var_ref.nested_clauses.each do |r|
                  debug :join, "Building objectification join for #{var_ref.nested_clauses.inspect}" do
                    build_join_steps r, roles_by_variable, variable.join_node
                  end
                end
              end
              roles_by_variable[variable] = [role, join_role]
            end
          end

          if join_roles.size > 0
            end_node = join_roles[-1].join_node
            if !clause.fact_type.entity_type and role = clause.fact_type.all_role.single
              # Don't give the ImplicitBoolean a join_node. We can live without one, for now.
              # The Join Step will have a duplicate node, and the fact type will tell us what's happening
              join_roles << join_roles[0]
            end
            # We aren't talking about objectification here, so there must be exactly two roles.
            raise "REVISIT: Internal error constructing join for #{clause.inspect}" if join_roles.size != 2
            js = @constellation.JoinStep(join_roles[0], join_roles[1], :fact_type => clause.fact_type)
            debug :join, "New Join Step #{js.describe}"
            debug :join, "Associating #{incidental_roles.map(&:describe)*', '} incidental roles with #{js.describe}" if incidental_roles.size > 0
            incidental_roles.each { |jr| jr.join_step = js }
          end
          roles_by_variable
        end

        # Return the unique array of all variables in these clauses, including in objectification joins
        def all_variables_in_clauses clauses
          clauses.map do |clause|
            clause.var_refs.map do |var_ref|
              [var_ref.variable] + (var_ref.nested_clauses ? all_variables_in_clauses(var_ref.nested_clauses) : [])
            end
          end.
            flatten.
            uniq
        end
      end
    end
  end
end
