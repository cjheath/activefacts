module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      class Definition
        # Make a Variable for every binding present in these clauses
        def build_variables(clauses_list)
          trace :query, "Building variables" do
            query = @constellation.Query(:new)
            all_bindings_in_clauses(clauses_list).
              each do |binding|
                trace :query, "Creating variable #{query.all_variable.size} for #{binding.inspect}"
                binding.variable = @constellation.Variable(query, query.all_variable.size, :object_type => binding.player)
		if literal = binding.refs.detect{|r| r.literal}
		  if literal.kind_of?(ActiveFacts::CQL::Compiler::Reference)
		    # REVISIT: Fix this crappy ad-hoc polymorphism hack
		    literal = literal.literal
		  end
                  unit = @constellation.Unit.detect{|k, v| [v.name, v.plural_name].include? literal.unit} if literal.unit
                  binding.variable.value = [literal.literal.to_s, literal.literal.is_a?(String), unit]
                end
              end
            query
          end
        end

        def build_all_steps(clauses_list)
          roles_by_binding = {}
          trace :query, "Building steps" do
            clauses_list.each do |clause|
              build_step(clause, roles_by_binding)
            end
          end
          roles_by_binding
        end

        def build_step clause, roles_by_binding = {}, parent_variable = nil
	  return unless clause.refs.size > 0  # Empty clause... really?

	  step = @constellation.Step(
	      :guid => :new,
	      :fact_type => clause.fact_type,
	      :alternative_set => nil,
	      :is_disallowed => clause.certainty == false,
	      :is_optional => clause.certainty == nil
	    )

	  trace :query, "Creating Plays for #{clause.inspect} with #{clause.refs.size} refs" do
	    is_input = true
	    clause.refs.each do |ref|
	      # These refs are the Compiler::References, which have associated Metamodel::RoleRefs,
	      # but we need to create Plays for those roles.
	      # REVISIT: Plays may need to save residual_adjectives
	      binding = ref.binding
	      role = (ref && ref.role) || (ref.role_ref && ref.role_ref.role)

	      objectification_step = nil
	      if ref.nested_clauses
		ref.nested_clauses.each do |nested_clause|
		  objectification_step = build_step nested_clause, roles_by_binding
		  if ref.binding.player.is_a?(ActiveFacts::Metamodel::EntityType) and
		      ref.binding.player.fact_type == nested_clause.fact_type
		    objectification_step.objectification_variable = binding.variable
		  end
		end
	      end
	      if clause.is_naked_object_type
		raise "#{self} lacks a proper objectification" if clause.refs[0].nested_clauses and !objectification_step
		return objectification_step
	      end

	      if binding.variable.object_type != role.object_type	  # Type mismatch
		if binding.variable.object_type.common_supertype(role.object_type)
		  # REVISIT: there's an implicit subtyping step here, create it; then always raise the error here.
		  # I don't want to do this for now because the verbaliser will always verbalise all steps.
		  raise "Disallowing implicit subtyping step from #{role.object_type.name} to #{binding.variable.object_type.name} in #{clause.fact_type.default_reading.inspect}"
		end
		raise "A #{role.object_type.name} cannot satisfy #{binding.variable.object_type.name} in #{clause.fact_type.default_reading.inspect}"
	      end

	      trace :query, "Creating Play for #{ref.inspect}"
	      play = @constellation.Play(:step => step, :role => role, :variable => binding.variable)
	      play.is_input = is_input
	      is_input = false

	      roles_by_binding[binding] = [role, play]
	    end
	  end

	  step
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
