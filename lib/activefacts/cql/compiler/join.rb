module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      class Definition
        # Make a JoinNode for every binding present in these readings
        def build_join_nodes(readings_list)
          debug :join, "Building join nodes" do
            join = @constellation.Join(:new)
            all_bindings_in_readings(readings_list).
              each do |binding|
                debug :join, "Creating join node #{join.all_join_node.size} for #{binding.inspect}"
                binding.join_node = @constellation.JoinNode(join, join.all_join_node.size, :object_type => binding.player)
              end
            join
          end
        end

        def build_all_join_steps(readings_list)
          roles_by_binding = {}
          debug :join, "Building join steps" do
            readings_list.each do |reading|
              next if reading.phrases.size == 1 && reading.role_refs.size == 1
              build_join_steps(reading, roles_by_binding)
            end
          end
          roles_by_binding
        end

        def build_join_steps reading, roles_by_binding = {}, objectification_node = nil
          join_roles = []
          incidental_roles = []
          debug :join, "Creating join Role Sequence for #{reading.inspect} with #{reading.role_refs.size} role refs" do
            objectification_step = nil
            reading.role_refs.each do |role_ref|
              # These role_refs are the Compiler::RoleRefs. These have associated Metamodel::RoleRefs,
              # but we need to create JoinRoles for those roles.  # REVISIT: JoinRoles may need to save residual_adjectives
              binding = role_ref.binding
              role = role_ref.role || role_ref.role_ref.role
              join_role = nil

              if (reading.fact_type.entity_type)
                # This reading is of an objectified fact type.
                # We need a join step from this role to the phantom role, but not
                # for a role that has only one role_ref (this one) in their binding.
                # Create the JoinNode and JoinRole in any case though.
                refs_count = binding.refs.size
                objectification_ref_count = 0
                if role_ref.objectification_join
                  role_ref.objectification_join.each do |r|
                    objectification_ref_count += r.role_refs.select{|rr| rr.binding.refs.size > 1}.size
                  end
                end
                refs_count += objectification_ref_count

                debug :join, "Creating Join Node #{role_ref.inspect} (counts #{refs_count}/#{objectification_ref_count}) and objectification Join Step for #{role_ref.inspect}" do

                  raise "Internal error: Trying to add role of #{role.object_type.name} to join node for #{binding.join_node.object_type.name}" unless binding.join_node.object_type == role.object_type
                  join_role = @constellation.JoinRole(binding.join_node, role)

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
                    # This is an implicit objectification, just the FT reading, not ET(where ...reading...)
                    # We need to create a JoinNode for this object, even though it has no RoleRefs
                    join = binding.join_node.join
                    debug :join, "Creating JN#{join.all_join_node.size} for #{reading.fact_type.entity_type.name} in objectification"
                    objectification_node = @constellation.JoinNode(join, join.all_join_node.size, :object_type => reading.fact_type.entity_type)
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
                debug :join, "Creating Role Ref for #{role_ref.inspect}" do
                    # REVISIT: If there's an implicit subtyping join here, create it; then always raise the error here.
                    # I don't want to do this for now because the verbaliser will always verbalise all join steps.
                  if binding.join_node.object_type != role.object_type and
                    0 == (binding.join_node.object_type.supertypes_transitive & role.object_type.supertypes_transitive).size
                    raise "Internal error: Trying to add role of #{role.object_type.name} to join node for #{binding.join_node.object_type.name} in '#{reading.fact_type.default_reading}'"
                  end
                  raise "Internal error: Trying to add role of #{role.object_type.name} to join node for #{binding.join_node.object_type.name}" unless binding.join_node.object_type == role.object_type
                  join_role = @constellation.JoinRole(binding.join_node, role)
                  join_roles << join_role
                end
              end

              if role_ref.objectification_join
                # We are looking at a role whose player is an objectification of a fact type,
                # which will have ImplicitFactTypes for each role.
                # Each of these ImplicitFactTypes has a single phantom role played by the objectifying entity type
                # One of these phantom roles is likely to be the subject of an objectification join step.
                role_ref.objectification_join.each do |r|
                  debug :join, "Building objectification join for #{role_ref.objectification_join.inspect}" do
                    build_join_steps r, roles_by_binding, binding.join_node
                  end
                end
              end
              roles_by_binding[binding] = [role, join_role]
            end
          end

          if join_roles.size > 0
            end_node = join_roles[-1].join_node
            if !reading.fact_type.entity_type and role = reading.fact_type.all_role.single
              # Don't give the ImplicitBoolean a join_node. We can live without one, for now.
              # The Join Step will have a duplicate node, and the fact type will tell us what's happening
              join_roles << join_roles[0]
            end
            # We aren't talking about objectification here, so there must be exactly two roles.
            raise "REVISIT: Internal error constructing join for #{reading.inspect}" if join_roles.size != 2
            js = @constellation.JoinStep(join_roles[0], join_roles[1], :fact_type => reading.fact_type)
            debug :join, "New Join Step #{js.describe}"
            debug :join, "Associating #{incidental_roles.map(&:describe)*', '} incidental roles with #{js.describe}" if incidental_roles.size > 0
            incidental_roles.each { |jr| jr.join_step = js }
          end
          roles_by_binding
        end

        # Return the unique array of all bindings in these readings, including in objectification joins
        def all_bindings_in_readings readings
          readings.map do |reading|
            reading.role_refs.map do |rr|
              [rr.binding] + (rr.objectification_join ? all_bindings_in_readings(rr.objectification_join) : [])
            end
          end.
            flatten.
            uniq
        end
      end
    end
  end
end
