module ActiveFacts
  module Metamodel
    class QueryEvaluator
      AFMM = ActiveFacts::Metamodel

      def initialize query, population = nil
        @query = query

        raise "Query must be in the specified model" unless @query

        # In theory a query can span more than one vocabulary. I don't do that!
        @vocabulary = @query.all_variable.to_a.first.object_type.vocabulary

        set_population(population)
      end

      def set_population population
	if population.is_a?(String) || population == nil
	  @population = @constellation.Population[[[@vocabulary.name], population ||= '']]
	  raise "Population #{population.inspect} does not exist" unless @population
	elsif population.is_a?(AFMM::Population)
          raise "Population #{population.name} is not in the correct vocabulary #{@vocabulary.name}" unless population.vocabulary == @vocabulary
          @population = population
	else
	  raise "Population #{population.inspcct} must be a Population or a Population name"
        end
      end

      def all_variables
	@query.all_variable.to_a
      end

      attr_reader :free_variables

      def evaluate
	@result_projection = {}  # A set of {hash of Variable to Instance}
	@free_variables = all_variables
	hypothesis = trivial_bindings @free_variables
	trace :query, "Evaluating query with free variables #{@free_variables.map{|v|v.object_type.name}.inspect} and hypothesis #{hypothesis.inspect}" do
	  query_level(@free_variables, hypothesis)
	end
	@result_projection
      end

      # From the array of variables, delete those that are already bound and return the hypothesis hash
      def trivial_bindings variables
	hypothesis = {}

	variables.each do |var|
	  next if var.value == nil
	  # Look up the instances for this bound variables
	  instance = lookup_instance_by_value(var.object_type, var.value)
	  trace :result, "Binding was #{instance ? '' : 'un'}successful for #{var.object_type.name} #{var.value.inspect}"
	  hypothesis[var] = instance
	end

	hypothesis.each do |v, i|
	  variables.delete(v)
	end

	trace :result, "starting hypothesis: {#{hypothesis.map{|var, instance| [var.object_type.name, instance.verbalise] }*'=>'}}"
	trace :result, "free variables are #{variables.map{|v| v.object_type.name}.inspect}" 

	hypothesis
      end

      def lookup_instance_by_value(object_type, value)
	pi = object_type.is_a?(ActiveFacts::Metamodel::EntityType) && object_type.preferred_identifier

	# A multi-role identifier cannot be satisfied by a single value:
	return nil if pi && pi.role_sequence.all_role_ref.size > 1

	if pi
	  identifying_role = pi.role_sequence.all_role_ref.single.role
	  identifying_instance = lookup_instance_by_value(identifying_role.object_type, value)
	  return nil unless identifying_instance
	  identifying_role_values =
	    identifying_instance.all_role_value.select{|rv| rv.role == identifying_role }
	  raise "Faulty Population has duplicate #{object_type.name} instance #{value}" if identifying_role_values.size > 1
	  identifying_role_value = identifying_role_values[0]
	  return nil unless identifying_role_value	# The value exists, but doesn't identify an existing entity
	  identified_instance =
	    (identifying_role_value.fact.all_role_value.to_a-[identifying_role_values])[0].instance
	else
	  object_type.all_instance.detect do |instance|
	    instance.population == @population and instance.value == value
	  end
	end
      end

      def conforms_to_plays_and_steps(hypothesis, variable, instance)
	variable.all_play.to_a.map do |play|
	  # No play may fail (be in a step with/out a matching fact)
	  step = play.step

	  # REVISIT: We can skip steps that have been checked in an outer loop
	  # REVISIT: We need to check AlternateSets here.

	  # We cannot check a step that involves an unbound variable.
	  # Allow it for now (there will be nil instead of a matching fact)
	  next if step.all_play.to_a.any? do |other_play|
	    # REVISIT: Unless the step is optional
	    !(hypothesis.has_key?(other_play.variable) || other_play.variable == variable)
	  end

	  # Select all the RoleValues where this instance plays the required role.
	  # REVISIT: We've already selected instances in the correct population.
	  # Did RoleValues have to be further qualified? That might be redundant.
	  role_values = instance.all_role_value.select{|rv| rv.role == play.role }

	  satisfying_fact = nil

	  trace :result, "Trying #{role_values.size} values of #{play.role.object_type.name} to see whether #{instance.verbalise} participates in #{step.fact_type.default_reading} with bound variables #{hypothesis.map{|v,i| "#{v.object_type.name}=>#{i.verbalise}"}*', '}" do

	    role_values.any? do |rv|
	      fact = rv.fact
	      next false unless fact.population == @population

	      # If the step designates an objectification, this fact must be that objectification
	      if step.objectification_variable
		next false unless fact.instance && step.objectification_variable.object_type == fact.instance.object_type
		# REVISIT: fact.instance must be saved in the hypothesis under step.objectification_variable
	      end

	      # Succeed if this fact has all its role_values set to our bound variables
	      if fact.all_role_value.all? do |rv|
		  relevant_play = step.all_play.detect{|p| p.role == rv.role}
		  relevant_variable = relevant_play.variable
		  relevant_value = variable == relevant_variable ? instance : hypothesis[relevant_variable]
		  match = relevant_value == rv.instance
		  trace :result, "#{relevant_play.variable.object_type.name} (bound to #{hypothesis[relevant_play.variable].verbalise}) #{match ? 'MATCHES' : 'DOES NOT MATCH'} role value #{rv.instance.verbalise}" if match
		  match
		end	  # of fact.all_role_value.all?
		satisfying_fact = fact
		satisfying_objectification_variable = step.objectification_variable
	      end
	    end	# of role_values.any?
	  end   # of trace

	  if satisfying_fact
	    trace :result, "#{instance.verbalise} #{
		satisfying_fact ? 'participates' : 'does not participate'
	      } in #{step.is_disallowed ? 'disallowed ' : ''}step over #{step.fact_type.default_reading} "+
	      "with bound variables #{hypothesis.map{|v,i| "#{v.object_type.name}=>#{i.verbalise}"}*', '}"
	  end

	  if step.is_disallowed
	    satisfying_fact = !satisfying_fact	# yield true if no fact satisfied the step, as sought
	  end
	  return nil unless satisfying_fact	# This play fails the hypothesis

	  [ play, satisfying_fact ] +
	    Array(step.objectification_variable ? satisfying_fact.instance : nil)
	end   # of all_play
      end   # of conforms_to_plays_and_steps

      def query_level unbound_variables = [], hypothesis = {}
        # unbound_variables is an array of the remaining dimensions of the search
        # hypothesis is a hash of Variable to Instance containing the values we think will satisfy the query

        # Choose an unbound variable and test the instances of its object type
        # This is a dumb choice for now. We should choose a variable that's
        # closely connected to a bound variable, to narrow it down.
        variable = unbound_variables[0]
        return unless variable

	# Set candidate_instances to the instances of this variable:
	if hypothesis.has_key?(variable)
	  # REVISIT: I thought we were searching an unbound variable here? When does this happen:
	  candidate_instances = Array(hypothesis[variable])
	else
	  candidate_instances = variable.object_type.all_instance
	  # candidate_instances = find_candidate_sets variable, hypothesis
	end

	population_candidates = candidate_instances.reject do |instance|
	  instance.population != @population        # Wrong population
	end

	trace :result, "Query search through #{population_candidates.size} #{variable.role_name || variable.object_type.name}" do
	  population_candidates.each do |instance|
	    # filter by population:
	    trace :result, "Considering #{instance.verbalise}" do

	      # Check whether this instance satisfies the query steps of this play
	      played = conforms_to_plays_and_steps(hypothesis, variable, instance)
	      unless played
		trace :result, "Does not conform to all steps"
		next
	      else
		trace :result, "Conforms to steps #{played.inspect}" unless played.empty?
	      end

	      # If this variable is the result of an objectification, the objectified fact
	      # has role players that might fill some remaining variables:
	      implications = {variable => instance}
	      if variable.step
		objectification_plays = variable.step.all_play

		# Ensure that the objectified instances don't contradict some bound variable:
		next unless objectification_plays.to_a.all? do |play|
		  objectified_instance = instance.fact.all_role_value.select{|rv| rv.role == play.role}[0].instance
		  trace :result, "objectified instance includes #{play.variable.object_type.name}, checking it conforms" do
		    if hypothesis[play.variable]
		      unless hypothesis[play.variable] == objectified_instance
			trace :result, "Objectified player #{objectified_instance.verbalise.inspect} does not match our hypothesis"
			next false
		      end
		      true
		    else
		      implications[play.variable] = objectified_instance
		      conforms = conforms_to_plays_and_steps(hypothesis, play.variable, objectified_instance)
		      trace :result, "Objectified player #{objectified_instance.verbalise.inspect} does not conform to all steps" unless conforms
		      conforms
		    end
		  end
		end
	      end

	      # Some of the variable's Plays might be matched by objectified facts.
	      # Record these values of the objectification variables.
	      next unless played.compact.all? do |playing|
		play, fact, objectifying_variable = *playing
		next true unless objectifying_variable
		if i = hypothesis[objectifying_variable] and i != fact.instance
		  trace :result, "Objectification of #{fact.instance.verbalise.inspect} does not match our hypothesis"
		  next false
		end
		implications[objectifying_variable] = fact.instance
	      end

	      # accept the implications of this variable->instance assignment:
	      new_hypothesis = hypothesis.dup.merge(implications)
	      remaining_variables = unbound_variables - implications.keys

	      new_hypothesis.freeze
	      if remaining_variables.empty?
		# This is a complete result set (no unbound variables) so record it:
		@result_projection[new_hypothesis] = true
	      end
	      query_level(remaining_variables, new_hypothesis)
	    end	  # trace each instance
	  end	# each instance
        end   # trace search through instances
      end   # query_level

      # This method is an exploration into finding a smaller search space for the given variable.
      # It relies on the values of bindings being Instance objects.
      def find_candidate_sets variable, bindings
	trace :result, "Looking for a smaller candidate set by traversing from these bound variables: #{bindings.keys.map{|v| (v.object_type.name+v.ordinal.to_s).inspect }*', '}" do
	  # If this variable is connected via a single step to one or more bound variables,
	  # that's probably a better place to search than object_type.all_instance.
	  bindable_plays =
	    variable.all_play.map do |play|
	      steps =
		play.all_step_as_output_play.to_a + play.all_step_as_input_play.to_a + [play.step].compact
	      trace :result, "Considering steps over #{steps.map{|s|s.fact_type.default_reading.inspect}*', '}"
	      bound_steps =
		steps.reject{|s| (s.all_play-[play]).detect{|p|
		  # trace :result, "Rejecting steps over #{s.fact_type.default_reading.inspect} because #{p.variable.object_type.name}#{p.variable.ordinal} is not bound" unless bindings[p.variable]
		  !bindings[p.variable]}
		}
	      trace :result, "Bound steps are #{bound_steps.map{|s|s.fact_type.default_reading.inspect}*', '}"
	      counterpart_plays =
		bound_steps.map{|s| (s.all_play-[play]) }.flatten.uniq
	      trace :result, "bound_steps.size = #{bound_steps.size}, counterpart_plays.size = #{counterpart_plays.size}"

	      # Consider only counterpart_plays for bound variables:
	      #counterpart_plays.reject!{|cp| !bindings[cp.variable] }

	      counterpart_plays
	    end.flatten.uniq

	  trace :result, "Connections of #{variable.object_type.name}#{variable.ordinal}:" do
	    if bindable_plays.empty?
	      trace :result, "NONE"
	    else
	      # Show the candidate instances here:
	      if trace :result
		bindable_plays.each do |pl|
		  # We have bound instances of pl.variable, and the step(s) from this play reach the variable
		  trace :result, "Candidate facts which include this play are" do

		    bound_instance =
		      bindings[pl.variable]	      # This is the instance under consideration
		    bound_instance.
		      all_role_value.select{|rv|	      # Select its RoleValues for roles in this play's step
			pl.all_step.detect{|s| s.fact_type == rv.fact.fact_type }
		      }.
		      each{|rv|			      # Verbalise other role_values of this fact
			trace :result, "#{rv.fact.verbalise.inspect}"
		      }
		  end
		  trace :result, "-> Role of #{pl.variable.object_type.name}#{pl.variable.ordinal} in #{pl.role.fact_type.default_reading}"
		end
	      end
	    end
	  end
	end
      end

    end   # QueryEvaluator
  end   # Metamodel
end   # ActiveFacts
