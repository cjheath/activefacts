module CompileHelpers
  def baseline
    @base_facts = @constellation.FactType.values - @constellation.LinkFactType.values
    @base_objects = @constellation.ObjectType.values
    @base_queries = @constellation.Query.values
    @base_steps = @constellation.Step.values
    @base_variables = @constellation.Variable.values
  end

  def fact_types
    @constellation.FactType.values - @constellation.LinkFactType.values - @base_facts
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

  def derivation fact_type
    # PENDING: When the fact type's roles are projected, use this instead:
    # j = fact_type.all_role.map{|r| r.all_play.map{|play| play.query}}.flatten.uniq - @base_queries
    q = queries
    q.size.should == 1
    query = q[0]
    query
  end

  def queries
    @constellation.Query.values - @base_queries
  end

  def steps
    @constellation.Step.values - @base_steps
  end

  def variables
    @constellation.Variable.values - @base_variables
  end

  def parse string
    lambda {
      @asts = @compiler.parse_all(string, :definition).map{ |tree|
        trace :parse, "Parsed '#{tree.text_value.gsub(/\s+/,' ').strip}'"
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
