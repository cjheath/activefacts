module CompileHelpers
  def baseline
    @base_facts = @constellation.FactType.values - @constellation.ImplicitFactType.values
    @base_objects = @constellation.ObjectType.values
    @base_joins = @constellation.Join.values
    @base_join_steps = @constellation.JoinStep.values
    @base_join_nodes = @constellation.JoinNode.values
  end

  def fact_types
    @constellation.FactType.values - @constellation.ImplicitFactType.values - @base_facts
  end

  def object_types
    @constellation.ObjectType.values - @base_objects
  end

  def fact_readings fact_type
    fact_type.all_reading.to_a
  end

  def fact_pcs fact_type
    fact_type.all_role.map{|r| r.all_role_ref.map{|rr| rr.role_sequence.all_presence_constraint.to_a}}.flatten.uniq
  end

  def joins
    @constellation.Join.values - @base_joins
  end

  def join_steps
    @constellation.JoinStep.values - @base_join_steps
  end

  def join_nodes
    @constellation.JoinNode.values - @base_join_nodes
  end

  def parse string
    lambda {
      @asts = @compiler.parse_all(string, :definition).map{ |tree|
        debug :parse, "Parsed '#{tree.text_value.gsub(/\s+/,' ').strip}'"
        ast = tree.ast
        ast.vocabulary = @compiler.vocabulary
        ast.constellation = @compiler.vocabulary.constellation
        ast
      }
    }.should_not raise_error
    @asts
  end

  def match_readings fact_type_ast
    fact_type_ast.prepare_roles(fact_type_ast.readings)
    fact_type_ast.readings.map { |r|
      r.match_existing_fact_type(fact_type_ast.context)
    }
  end

  def match_readings_to_existing fact_type_ast, clause
    fact_type_ast.prepare_roles(fact_type_ast.clauses)
    fact_type_ast.clauses.map { |r|
      r.clause_matches(clause.fact_type, clause)
    }
  end

  def compile string
    lambda {
      begin
        @compiler.compile string
      rescue Exception => e
        puts e.message+": \n\t"+e.backtrace.reject{|l| l =~ /\brspec\b/}*"\n\t"
        raise
      end
    }.should_not raise_error
  end
end
