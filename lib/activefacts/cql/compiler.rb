#       Compile a CQL string into an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/cql/parser'

require 'activefacts/cql/compiler/shared'
require 'activefacts/cql/compiler/value_type'
require 'activefacts/cql/compiler/entity_type'
require 'activefacts/cql/compiler/reading'
require 'activefacts/cql/compiler/fact_type'
require 'activefacts/cql/compiler/fact'
require 'activefacts/cql/compiler/constraint'

# The following files are from the old implementation, moving into the above:
require 'activefacts/cql/binding'
require 'activefacts/cql/value_type'
require 'activefacts/cql/constraints'
require 'activefacts/cql/entity_type'
require 'activefacts/cql/fact_type'
require 'activefacts/cql/fact'

module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      attr_reader :vocabulary

      def initialize(input, filename = "stdin")
        @filename = filename
        @constellation = ActiveFacts::API::Constellation.new(ActiveFacts::Metamodel)

        compile(input)
      end

      def compile(input)
        @string = input

        # The syntax tree created from each parsed CQL statement gets passed to the block.
        # parse_all returns an array of the block's non-nil return values.
        result = parse_all(@string, :definition) do |node|
          debug :parse, "Parsed '#{node.text_value.gsub(/\s+/,' ').strip}'" do
            begin
              ast = node.ast
              debug :ast, ast.inspect
              value = ast.compile(@constellation, @vocabulary)
              @vocabulary = value if ast.is_a?(Compiler::Vocabulary)
#              compile_definition node
            rescue => e
              puts e.message+"\n\t"+e.backtrace*"\n\t" if debug :exception
              start_line = @string.line_of(node.interval.first)
              end_line = @string.line_of(node.interval.last-1)
              lines = start_line != end_line ? "s #{start_line}-#{end_line}" : " #{start_line.to_s}"
              raise "at line#{lines} #{e.message.strip}"
            end
          end

          nil
        end
        raise failure_reason unless result
        vocabulary
      end

      def compile_definition(node)
        kind, *value = d = definition(node)

        #print " to "; p value
        raise "Definition of #{kind} must be in a vocabulary" if kind != :vocabulary and !@vocabulary

        if [:vocabulary, :value_type, :entity_type, :fact_type, :constraint, :fact, :unit].include?(kind)
          send(kind, *value)
        else
          print "="*20+" unhandled declaration type: "; p kind, value
        end
      end

#      def vocabulary(name)
#        @vocabulary = @constellation.Vocabulary(name)
#      end

    private
      def concept_by_name(name)
        player = @constellation.Concept[[@vocabulary.identifying_role_values, name]]

        # REVISIT: Hack to allow facts to refer to standard types that will be imported from standard vocabulary:
        if !player && %w{Date DateAndTime Time}.include?(name)
          player = @constellation.ValueType(@vocabulary.identifying_role_values, name)
        end

        if (!player && @allowed_forward_terms.include?(name))
          player = @constellation.EntityType(@vocabulary, name)
        end
        player
      end

      def phrases_list_from_clauses(clauses)
        clauses.map do |clause|
          kind, qualifiers, phrases, context = *clause
          phrases
        end
      end

      # Record the concepts that play a role in these clauses
      # After this, each phrase will have [:player] member that refers to the Concept
      def resolve_players(phrases_list)
        # Find the term for each role name:
        terms_by_role_names = {}
        phrases_list.each do |phrases|
          phrases.each do |phrase|
            next unless phrase.is_a?(Hash)
            role_name = phrase[:role_name]
            next unless role_name.is_a?(String)   # Skip subscripts for now
            terms_by_role_names[role_name] = phrase[:term] if role_name
          end
        end

        phrases_list.each do |phrases|
          phrases.each do |phrase|
            next unless phrase.is_a?(Hash)
            concept_name = phrase[:term]
            real_term = terms_by_role_names[concept_name] 
            concept_name = real_term if real_term
            concept = concept_by_name(concept_name)
            phrase[:player] = concept
          end
        end
      end

      # Arrange the clauses of one or more fact types into groups having the same role players
      def clauses_by_players(clauses)
        cbp = {}
        clauses.each do |clause|
          kind, qualifiers, phrases, context = *clause
          players = []
          phrases.each do |phrase|
            next unless phrase.is_a?(Hash)
            players << phrase[:player]
          end
          (cbp[players.map{|p| p.name}.sort] ||= []) << clause
        end
        cbp
      end

=begin
      def fact_type_identification(fact_type, name, prefer)
        if !@symbols.embedded_presence_constraints.detect{|pc| pc.max_frequency == 1}
          # Provide a default identifier for a fact type that's lacking one (over all roles):
          first_role_sequence = fact_type.preferred_reading.role_sequence
          #puts "Creating PC for #{name}: #{fact_type.describe}"
          identifier = @constellation.PresenceConstraint(
              :new,
              :vocabulary => @vocabulary,
              :name => "#{name}PK",            # Is this a useful name?
              :role_sequence => first_role_sequence,
              :is_preferred_identifier => prefer,
              :max_frequency => 1              # Unique
            )
          # REVISIT: The UC might be provided later as an external constraint, relax this rule:
          #raise "'#{fact_type.default_reading}': non-unary fact types having no uniqueness constraints must be objectified (named)" unless fact_type.entity_type
          debug "Made default fact type identifier #{identifier.object_id} over #{first_role_sequence.describe} in #{fact_type.describe}"
        elsif prefer
          #debug "Made fact type identifier #{identifier.object_id} preferred over #{@symbols.embedded_presence_constraints[0].role_sequence.describe} in #{fact_type.describe}"
          @symbols.embedded_presence_constraints[0].is_preferred_identifier = true
        end
      end

      # Categorise the fact type clauses according to the set of role player names
      # Return an array where each element is an array of clauses, the clauses having
      # matching players, and otherwise preserving the order of definition.
      def clauses_by_fact_type(clauses)
        clause_group_by_role_players = {}
        clauses.inject([]) do |clause_groups, clause|
          type, qualifiers, phrases, context = *clause

          debug "Clause: #{clause.inspect}"
          roles = phrases.map do |phrase|
            Hash === phrase ? phrase[:binding] : nil
          end.compact

          # Look for an existing clause group involving these players, or make one:
          clause_group = clause_group_by_role_players[key = roles.sort]
          if clause_group     # Another clause for an existing clause group
            clause_group << clause
          else                # A new clause group
            clause_groups << (clause_group_by_role_players[key] = [clause])
          end
          clause_groups
        end
      end
=end

    end
  end
end
