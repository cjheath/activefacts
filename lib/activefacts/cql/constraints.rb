#       Compile a CQL string into an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      RingTypes = %w{acyclic intransitive symmetric asymmetric transitive antisymmetric irreflexive reflexive}
      RingPairs = {
        :intransitive => [:acyclic, :asymmetric, :symmetric],
        :irreflexive => [:symmetric]
      }

      private

      def constraint *value
        case type = value.shift
        when :presence
          presence_constraint *value
        when :set
          set_constraint *value
        when :subset
          subset_constraint *value
        when :equality
          equality_constraint *value
        else
          $stderr.puts "REVISIT: external #{type} constraints aren't yet handled:\n\t"+value.map{|a| a.inspect }*"\n\t"
        end
      end

      def find_pc_over_roles(roles)
        return nil if roles.size == 0 # Safeguard; this would chuck an exception otherwise
        roles[0].all_role_ref.each do |role_ref|
          next if role_ref.role_sequence.all_role_ref.map(&:role) != roles
          pc = role_ref.role_sequence.all_presence_constraint.single  # Will return nil if there's more than one.
          #puts "Existing PresenceConstraint matches those roles!" if pc
          return pc if pc
        end
        nil
      end

      def apply_enforcement(constraint, enforcement)
        action, agent = *enforcement
        constraint.enforcement = action
        constraint.enforcement.agent = agent if agent
      end

      def value_restriction(ranges, enforcement)
        vr = @constellation.ValueRestriction(:new)
        ranges.each do |range|
          min, max = Array === range ? range : [range, range]
          v_range = @constellation.ValueRange(
            min ? [[String === min ? eval(min) : min.to_s, String === min, nil], true] : nil,
            max ? [[String === max ? eval(max) : max.to_s, String === max, nil], true] : nil
          )
          ar = @constellation.AllowedRange(vr, v_range)
        end
        apply_enforcement(vr, enforcement) if enforcement
        vr
      end

      # For each fact reading there may be embedded mandatory, uniqueness or frequency constraints:
      def make_embedded_presence_constraints(fact_type, clause)
        kind, qualifiers, phrases, context = *clause
        role_phrases = phrases.select{|p| p.is_a?(Hash)}
        debug :constraint, "making embedded presence constraints from #{show_phrases(phrases)}"
        embedded_presence_constraints = []
        roles = role_phrases.map { |p| p[:role] || p[:role_ref].role }
        role_phrases.each_with_index do |role_phrase, index|
          role = role_phrase[:role] || role_phrase[:role_ref].role
          raise "No Role for embedded_presence_constraint; use role_ref?" unless role

          next unless quantifier = role_phrase[:quantifier]

          debug :constraint, "Processing embedded constraint #{quantifier.inspect} on #{role.concept.name} in #{fact_type.describe}" do
            constrained_roles = roles.clone
            constrained_roles.delete_at(index)
            constraint = find_pc_over_roles(constrained_roles)
            if constraint
              debug :constraint, "Setting max frequency to #{quantifier[1]} for existing constraint #{constraint.object_id} over #{constraint.role_sequence.describe} in #{fact_type.describe}"
              raise "Conflicting maximum frequency for constraint" if constraint.max_frequency && constraint.max_frequency != quantifier[1]
              constraint.max_frequency = quantifier[1]
            else
              role_sequence = @constellation.RoleSequence(:new)
              constrained_roles.each_with_index do |constrained_role, i|
                role_ref = @constellation.RoleRef(role_sequence, i, :role => constrained_role)
              end
              constraint = @constellation.PresenceConstraint(
                  :new,
                  :vocabulary => @vocabulary,
                  :role_sequence => role_sequence,
                  :is_mandatory => quantifier[0] && quantifier[0] > 0,  # REVISIT: Check "maybe" qualifier?
                  :max_frequency => quantifier[1],
                  :min_frequency => quantifier[0]
                )
              embedded_presence_constraints << constraint
              debug :constraint, "Made new PC min=#{quantifier[0].inspect} max=#{quantifier[1].inspect} constraint #{constraint.object_id} over #{(e = fact_type.entity_type) ? e.name : role_sequence.describe} in #{fact_type.describe}"
              enforcement = role_phrase[:quantifier_restriction]
              apply_enforcement(constraint, enforcement) if enforcement
            end
          end
        end
      end

      def presence_constraint(constrained_role_names, quantifier, phrases_list, context, enforcement)
        raise "REVISIT: Join presence constraints not supported yet" if phrases_list[0].size > 1
        phrases_list = phrases_list.map{|r| r[0] }
        #p phrases_list

        @symbols = SymbolTable.new(@constellation, @vocabulary)

        # Find players for all constrained_role_names. These may use leading or trailing adjective forms...
        constrained_players = []
        constrained_bindings = []
        constrained_role_names.each do |role_name|
          player, binding = @symbols.bind(role_name)
          constrained_players << player
          constrained_bindings << binding
        end
        #puts "Constrained bindings are #{constrained_bindings.inspect}"
        #puts "Constrained bindings object_id's are #{constrained_bindings.map{|b|b.object_id.to_s}*","}"

        # Find players for all the concepts in all phrases_list:
        @symbols.bind_roles_in_phrases_list(phrases_list)

        constrained_roles = []
        unmatched_roles = constrained_role_names.clone
        phrases_list.each do |phrases|
          # puts phrases.inspect

          # If this succeeds, the phrases found matches the roles in our phrases
          fact_roles = invoked_fact_roles(phrases)
          raise "Fact type reading not found for #{phrases.inspect}" unless fact_roles

          # Look for the constrained role(s); the bindings will be the same
          matched_bindings = phrases.select{|p| Hash === p}.map{|p| p[:binding]}
          #puts "matched_bindings = #{matched_bindings.inspect}"
          #puts "matched_bindings object_id's are #{matched_bindings.map{|b|b.object_id.to_s}*","}}"
          matched_bindings.each_with_index{|b, pos|
            i = constrained_bindings.index(b)
            next unless i
            unmatched_roles[i] = nil
            #puts "found #{constrained_bindings[i].inspect} found as #{b.inspect} in position #{i.inspect}"
            role = fact_roles[pos]
            constrained_roles << role unless constrained_roles.include?(role)
          }
        end

        # Check that all constrained roles were matched at least once:
        unmatched_roles.compact!
        raise "Constrained roles #{unmatched_roles.map{|ur| ur*"-"}*", "} not found in fact types" if unmatched_roles.size != 0

        rs = @constellation.RoleSequence(:new)
        #puts "constrained_roles: #{constrained_roles.map{|r| r.concept.name}.inspect}"
        constrained_roles.each_with_index do |role, index|
          raise "Constrained role #{constrained_role_names[index]} not found" unless role
          rr = @constellation.RoleRef(rs, index)
          rr.role = role
        end
        #puts "New external PresenceConstraint with quantifier = #{quantifier.inspect} over #{rs.describe}"

        # REVISIT: Check that no existing PC spans the same roles (nor a superset nor subset?)

        constraint = @constellation.PresenceConstraint(
            :new,
            :name => '',
            :vocabulary => @vocabulary,
            :role_sequence => rs,
            :min_frequency => quantifier[0],
            :max_frequency => quantifier[1],
            :is_preferred_identifier => false,
            :is_mandatory => quantifier[0] && quantifier[0] > 0
          )
        apply_enforcement(constraint, enforcement) if enforcement
      end

      def set_constraint(constrained_roles, quantifier, joins_list, context, enforcement)
        role_sequences = bind_joins_as_role_sequences(joins_list)

        if quantifier[1] == nil
          # create a presence constraint instead if we get quantifier = [N,nil] (at least N)
          # We massage the bound role sequences to make this work.
          raise "either/or constraint must have one common role" if role_sequences.size != 2 || role_sequences[0].all_role_ref.size != 1
          second_role = role_sequences[1].all_role_ref.single.role
          second_role_ref = @constellation.RoleRef(:role_sequence => role_sequences[0], :ordinal => 1, :role => second_role)
          @constellation.deny(role_sequences[1].all_role_ref.single)
          @constellation.deny(role_sequences[1])
          constraint = @constellation.PresenceConstraint(
              :new,
              :name => '',
              :vocabulary => @vocabulary,
              :role_sequence => role_sequences[0],
              :min_frequency => quantifier[0],
              :max_frequency => nil,
              :is_preferred_identifier => false,
              :is_mandatory => true
            )
          apply_enforcement(constraint, enforcement) if enforcement
        else
          # Create a normal (mandatory) exclusion constraint:
          constraint = @constellation.SetExclusionConstraint(:new)
          constraint.vocabulary = @vocabulary
          role_sequences.each_with_index do |rs, i|
            @constellation.SetComparisonRoles(constraint, i, :role_sequence => rs)
          end
          apply_enforcement(constraint, enforcement) if enforcement
          constraint.is_mandatory = quantifier[0] == 1
        end
      end

      def subset_constraint(joins_list, context, enforcement)
        role_sequences = bind_joins_as_role_sequences(joins_list)

        #puts "subset_constraint:\n\t#{subset_readings.inspect}\n\t#{superset_readings.inspect}"
        #puts "\t#{role_sequences.map{|rs| rs.describe}.inspect}"
        #puts "subset_role_sequence = #{role_sequences[0].describe}"
        #puts "superset_role_sequence = #{role_sequences[1].describe}"

        # create the constraint:
        constraint = @constellation.SubsetConstraint(:new)
        constraint.vocabulary = @vocabulary
        #constraint.name = nil
        #constraint.enforcement = 
        constraint.subset_role_sequence = role_sequences[0]
        constraint.superset_role_sequence = role_sequences[1]
        apply_enforcement(constraint, enforcement) if enforcement
      end

      def equality_constraint(joins_list, context, enforcement)
        #puts "equality\n\t#{joins_list.map{|rl| rl.inspect}*"\n\tif and only if\n\t"}"

        role_sequences = bind_joins_as_role_sequences(joins_list)

        # Create the constraint:
        constraint = @constellation.SetEqualityConstraint(:new)
        constraint.vocabulary = @vocabulary
        role_sequences.each_with_index do |rs, i|
          @constellation.SetComparisonRoles(constraint, i, :role_sequence => rs)
        end
        apply_enforcement(constraint, enforcement) if enforcement
      end


    end
  end
end
