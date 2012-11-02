module ActiveFacts
  module CQL
    class Parser
      class TermNode < Treetop::Runtime::SyntaxNode
        def ast quantifier = nil, function_call = nil, role_name = nil, value_constraint = nil, literal = nil, nested_clauses = nil
          t = x.context[:term]
          gt = x.context[:global_term]
          if t.size > gt.size and t[-gt.size..-1] == gt
            leading_adjective = t[0...-gt.size-1]
            leading_adjective.sub!(/ /, '-') if !tail.elements[0].dbl.empty?
          end
          if t.size > gt.size and t[0...gt.size] == gt
            trailing_adjective = t[gt.size+1..-1]
            trailing_adjective.sub!(/ (\S*)\Z/, '-\1') if !tail.elements[-1].dbl.empty?
          end
          Compiler::Reference.new(gt, leading_adjective, trailing_adjective, quantifier, function_call, role_name, value_constraint, literal, nested_clauses)
        end

        def value             # Sometimes we just want the full term name
          x.context[:term]
        end

        def node_type
          :term
        end
      end

      class TermLANode < TermNode
        def ast quantifier = nil, function_call = nil, role_name = nil, value_constraint = nil, literal = nil, nested_clauses = nil
          ast = term.ast(quantifier, function_call, role_name, value_constraint, literal, nested_clauses)
          ast.leading_adjective = head.text_value
          ast
        end
      end

      class TermDefinitionNameNode < TermNode
        def value
          t.elements.inject([
            id.value
          ]){|a, e| a << e.id.value}*' '
        end

        def node_type
          :term
        end
      end
    end
  end
end
