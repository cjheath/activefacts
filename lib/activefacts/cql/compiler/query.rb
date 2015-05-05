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

          plays =
	    trace :query, "Creating Plays for #{clause.inspect} with #{clause.refs.size} refs" do
	      clause.refs.map do |ref|
		# These refs are the Compiler::References, which have associated Metamodel::RoleRefs,
		# but we need to create Plays for those roles.
		# REVISIT: Plays may need to save residual_adjectives
		binding = ref.binding
		role = (ref && ref.role) || (ref.role_ref && ref.role_ref.role)

		objectification_step = nil
		if ref.nested_clauses
		  ref.nested_clauses.each do |nest|
		    step = build_step nest, roles_by_binding
		    if ActiveFacts::Metamodel::EntityType === ref.binding.player and
			ref.binding.player.fact_type == nest.fact_type
		      # Add an objectification step to the new step
		      objectification_step = step = build_objectification_step ref, step
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
		play = @constellation.Play(binding.variable, role)

		roles_by_binding[binding] = [role, play]

		play
	      end
	    end

	  if !clause.fact_type.entity_type and role = clause.fact_type.all_role.single
	    # Don't give the ImplicitBoolean a variable. We can live without one, for now.
	    # The Step will have a duplicate Play, and the fact type will tell us what's happening
	    plays << plays[0]
	  end

	  incidental_plays = plays.size > 2 ? plays[2..-1] : []
	  step = @constellation.Step(
	      plays[0],
	      plays[1],
	      :fact_type => clause.fact_type,
	      :is_disallowed => clause.certainty == false,
	      :is_optional => clause.certainty == nil
	    )

	  trace :query, "New #{step.describe}" do
	    if incidental_plays.size > 0
	      trace :query, "Associating #{incidental_plays.map(&:describe)*', '} incidental roles"
	      incidental_plays.each { |i_play| i_play.step = step }
	    end
	  end
	  step
	end

	# The variable in the binding of ref is objectified by the fact type in step
	# Create a step over the LinkFactType to hook it up
	def build_objectification_step ref, step
	  # This is the fact type objectified as ref.binding.player.
	  # REVISIT: Make sure it's not ambiguous!
	  # raise "Ambiguous duplicate objectification #{nest}, already have #{ref.objectification_of.default_reading}" if ref.objectification_of

	  mirror_role = step.input_play.role
	  link_fact_type = mirror_role.link_fact_type
	  phantom_role = link_fact_type.all_role.single

	  phantom_play = @constellation.Play(ref.binding.variable, phantom_role)
	  mirror_play = @constellation.Play(step.input_play.variable, mirror_role)

	  objectification_step = @constellation.Step(
	    phantom_play,
	    mirror_play,
	    :fact_type => link_fact_type,
	    :is_disallowed => false,
	    :is_optional => false
	  )
	  return objectification_step
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
