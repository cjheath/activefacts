#
#       ActiveFacts CQL Parser.
#       The parser turns CQL strings into abstract syntax trees ready for semantic analysis.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'treetop'

# These are Treetop files, which Polyglot will compile on the fly if precompiled ones aren't found:
require 'activefacts/cql/LexicalRules'
require 'activefacts/cql/Language/English'
require 'activefacts/cql/Expressions'
require 'activefacts/cql/Terms'
require 'activefacts/cql/Concepts'
require 'activefacts/cql/ValueTypes'
require 'activefacts/cql/FactTypes'
require 'activefacts/cql/Context'
require 'activefacts/cql/CQLParser'

module ActiveFacts
  module CQL
    module Terms
      class SavedContext < Treetop::Runtime::SyntaxNode
        attr_accessor :context
      end
    end

    # Extend the generated parser:
    class Parser < CQLParser
      include ActiveFacts

      # The Context manages some key information revealed or needed during parsing
      # These methods are semantic predicates; if they return false this parse rule will fail.
      class Context
        attr_reader :term, :global_term

        def initialize(parser)
          @parser = parser
          @terms = {}
          @role_names = {}
          @allowed_forward_terms = []
        end

        def object_type(name, kind)
          index_name(@terms, name) && debug(:context, "new #{kind} '#{name}'")
          true
        end

        def reset_role_names
          debug :context, "\tresetting role names #{@role_names.keys.sort*", "}" if @role_names && @role_names.size > 0
          @role_names = {}
        end

        def allowed_forward_terms(terms)
          @allowed_forward_terms = terms
        end

        def new_leading_adjective_term(adj, term)
          index_name(@role_names, "#{adj} #{term}", term) && debug(:context, "new role '#{adj}- #{term}'")
          true
        end

        def new_trailing_adjective_term(adj, term)
          index_name(@role_names, n = "#{term} #{adj}", term) && debug(:context, "new role '#{term} -#{adj}'")
          true
        end

        def role_name(name)
          index_name(@role_names, name) && debug(:context, "new role '#{name}'")
          true
        end

        def term_starts?(s, context_saver)
          @term_part = s
          @context_saver = context_saver
          t = @terms[s] || @role_names[s] || system_term(s)
          if t
            # s is a prefix of the keys of t.
            if t[s]
              @global_term = @term = @term_part
              @context_saver.context = {:term => @term, :global_term => @global_term }
            end
            debug :context, "Term #{t[s] ? "is" : "starts"} '#{@term_part}'"
          elsif @allowed_forward_terms.include?(@term_part)
            @term = @term_part
            @context_saver.context = {:term => @term, :global_term => @term }
            debug :context, "Term #{s} is an allowed forward"
            return true
          end
          t
        end

        def term_continues?(s)
          @term_part = "#{@term_part} #{s}"
          if t = @terms[@term_part]
            w = "term"
          else
            t = @role_names[@term_part]
            w = "role_name"
          end
          if t
            debug :context, "Multi-word #{w} #{t[@term_part] ? 'ends at' : 'continues to'} #{@term_part.inspect}"

            # Record the name of the full term and the underlying global term:
            if t[@term_part]
              @term = @term_part if t[@term_part]
              @global_term = (t = t[@term_part]) == true ? @term_part : t
              debug :context, "saving context #{@term}/{@global_term}"
              @context_saver.context = {:term => @term, :global_term => @global_term }
            end
          end
          t
        end

        def term_complete?
          @allowed_forward_terms.include?(@term) or
          system_term(@term) or
            ((t = @terms[@term] or t = @role_names[@term]) and t[@term])
        end

        def system_term(s)
          false
        end

      private
        # Index the name by all prefixes
        def index_name(index, name, value = true)
          added = false
          words = name.scan(/\w+/)
          words.inject("") do |n, w|
            # Index all prefixes up to the full term
            n = n.empty? ? w : "#{n} #{w}"
            index[n] ||= {}
            added = true unless index[n][name]
            index[n][name] = value    # Save all possible completions of this prefix
            n
          end
          added
        end
      end

      class InputProxy < Object
        attr_reader :context

        def initialize(input, context)
          @input = input
          @context = context
        end

        def length
          @input.length
        end

        def size
          length
        end

        def [](*a)
          @input[*a]
        end

        def index(*a)
          @input.index(*a)
        end

        def line_of(x)
          @input.line_of(x)
        end

        def column_of(x)
          @input.column_of(x)
        end
      end

      def context
        @context ||= Context.new(self)
      end

      def parse(input, options = {})
        input = InputProxy.new(input, context) unless input.respond_to?(:context)
        super(input, options)
      end

      # Repeatedly parse rule_name until all input is consumed,
      # returning an array of syntax trees for each definition.
      def parse_all(input, rule_name = nil, &block)
        self.root = rule_name if rule_name

        @index = 0  # Byte offset to start next parse
        self.consume_all_input = false
        results = []
        begin
          node = parse(InputProxy.new(input, context), :index => @index)
          return nil unless node
          node = block.call(node) if block
          results << node if node
        end until self.index == @input_length
        results
      end

      def definition(node)
        name, ast =
          *begin
            node.value
          rescue => e
            debugger
            p e
          end
        kind, *value = *ast

        begin
          debug :ast, "CQL: Processing definition #{[kind, name].compact*" "}: #{value.inspect}" do
            case kind
            when :vocabulary
              [kind, name]
            when :value_type
              value_type_ast(name, value)
            when :entity_type
              supertypes = value.shift
              entity_type_ast(name, supertypes, value)
            when :fact_type
              f = fact_type_ast(name, value)
            when :unit
              ast
            when :constraint
              ast
            else
              debugger
              raise "CQL: internal error, unknown definition kind"
            end
          end
        end
      rescue => e
        raise "in #{kind.to_s.camelcase(true)} definition, #{e.message}:\n\t#{node.text_value}" +
          (ENV['DEBUG'] =~ /\bexception\b/ ? "\nfrom\t"+e.backtrace*"\n\t" : "")
      end

      def value_type_ast(name, value)
        # REVISIT: Massage/check value type here?
        [:value_type, name, *value]
      end

      def entity_type_ast(name, supertypes, value)
        #print "entity_type parameters for #{name}: "; p value
        identification, mapping_pragmas, clauses = *value
        clauses ||= []

        # raise "Entity type clauses must all be fact types" if clauses.detect{|c| c[0] != :fact_clause }

        [:entity_type, name, supertypes, identification, mapping_pragmas, clauses]
      end

      def fact_type_ast(name, value)
        clauses, conditions = value

        if conditions.empty? && includes_literals(clauses)
          [:fact, nil, clauses]
        elsif clauses.size == 1 &&
            (popname = clauses[0][2]).size == 1 &&  # A single "clause" of one item
            popname[0].is_a?(Hash) &&               # which is a term
            popname[0].keys == [:word] &&           # No adjectives
            includes_literals(conditions)           # But has a literal
          [:fact, popname[0][:word], conditions]    # It's a fact, not a fact type
        else
          [:fact_type, name, clauses, conditions]
        end
      end

      def includes_literals(clauses)
        clauses.detect do |clause|
          raise "alternate clauses are not yet supported" if clause[0] == :"||"
          fc, qualifiers, phrases, context_note = *clause
          phrases.detect{|w| w[:literal]}
        end
      end

    end

  end

  Polyglot.register('cql', CQL::Parser)
end
