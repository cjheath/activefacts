#
#       ActiveFacts Relational mapping and persistence.
#       Tables; Calculate the relational composition of a given Vocabulary.
#       The composition consists of decisions about which ObjectTypes are tables,
#       and what columns (absorbed roled) those tables will have.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# This module has the following known problems:
#
# * When a subtype has no mandatory roles, we should support an optional schema transformation step
#   that introduces a boolean (is_subtype) to indicate it's that subtype.
#

require 'activefacts/persistence/reference'

module ActiveFacts
  module Metamodel

    class ValueType < DomainObjectType
      def absorbed_via  #:nodoc:
        # ValueTypes aren't absorbed in the way EntityTypes are
        nil
      end

      # Returns true if this ValueType is a table
      def is_table
        return @is_table if @is_table != nil

        # Always a table if marked so:
        if is_independent
          trace :absorption, "ValueType #{name} is declared independent"
          @tentative = false
          return @is_table = true
        end

        # Only a table if it has references (to another ValueType)
        if !references_from.empty? && !is_auto_assigned
          trace :absorption, "#{name} is a table because it has #{references_from.size} references to it"
          @is_table = true
        else
          @is_table = false
        end
        @tentative = false

        @is_table
      end

      # Is this ValueType auto-assigned either at assert or on first save to the database?
      def is_auto_assigned
        type = self
	while type
	  return true if type.name =~ /^Auto/ || type.transaction_phase
	  type = type.supertype
	end
      end
      false
    end

    class EntityType < DomainObjectType
      # A Reference from an entity type that fully absorbs this one
      attr_accessor :absorbed_via #:nodoc:
      attr_accessor :absorbed_mirror #:nodoc:

      def is_auto_assigned  #:nodoc:
        false
      end

      # Returns true if this EntityType is a table
      def is_table
        return @is_table if @is_table != nil  # We already make a guess or decision

        @tentative = false

        # Always a table if marked so
        if is_independent
          trace :absorption, "EntityType #{name} is declared independent"
          return @is_table = true
        end

        # Always a table if nowhere else to go, and has no one-to-ones that might flip:
        if references_to.empty? and
            !references_from.detect{|ref| ref.role_type == :one_one }
          trace :absorption, "EntityType #{name} is presumed independent as it has nowhere to go"
          return @is_table = true
        end

        # Subtypes may be partitioned or separate, in which case they're definitely tables.
        # Otherwise, if their identification is inherited from a supertype, they're definitely absorbed.
        # If theey have separate identification, it might absorb them.
        if (!supertypes.empty?)
          as_ti = all_supertype_inheritance.detect{|ti| ti.assimilation}
          @is_table = as_ti != nil
          if @is_table
            trace :absorption, "EntityType #{name} is #{as_ti.assimilation} from supertype #{as_ti.supertype}"
          else
            identifying_fact_type = preferred_identifier.role_sequence.all_role_ref.to_a[0].role.fact_type
            if identifying_fact_type.is_a?(TypeInheritance)
              trace :absorption, "EntityType #{name} is absorbed into supertype #{supertypes[0].name}"
              @is_table = false
            else
              # Possibly absorbed, we'll have to see how that pans out
              @tentative = true
            end
          end
          return @is_table
        end

        # If the preferred_identifier includes an auto_assigned ValueType
        # and this object is absorbed in more than one place, we need a table
        # to manage the auto-assignment.
        if references_to.size > 1 and
          preferred_identifier.role_sequence.all_role_ref.detect {|rr|
            next false unless rr.role.object_type.is_a? ValueType
            rr.role.object_type.is_auto_assigned
          }
          trace :absorption, "#{name} has an auto-assigned counter in its ID, so must be a table"
          @tentative = false
          return @is_table = true
        end

        @tentative = true
        @is_table = true
      end
    end # EntityType class

    class Role    #:nodoc:
      def role_type
        # TypeInheritance roles are always 1:1
        if TypeInheritance === fact_type
          return object_type == fact_type.supertype ? :supertype : :subtype
        end

        # Always N:1 if unary:
        return :unary if fact_type.all_role.size == 1

        # List the UCs on this fact type:
        all_uniqueness_constraints =
          fact_type.all_role.map do |fact_role|
            fact_role.all_role_ref.map do |rr|
              rr.role_sequence.all_presence_constraint.select do |pc|
                pc.max_frequency == 1
              end
            end
          end.flatten.uniq

        to_1 =
          all_uniqueness_constraints.
            detect do |c|
                (rr = c.role_sequence.all_role_ref.single) and
                rr.role == self
            end

        if fact_type.entity_type
          # This is a role in an objectified fact type
          from_1 = true
        else
          # It's to-1 if a UC exists over roles of this FT that doesn't cover this role:
          from_1 = all_uniqueness_constraints.detect{|uc|
            !uc.role_sequence.all_role_ref.detect{|rr| rr.role == self || rr.role.fact_type != fact_type}
          }
        end

        if from_1
          return to_1 ? :one_one : :one_many
        else
          return to_1 ? :many_one : :many_many
        end
      end

    end

    class Vocabulary
      @@relational_transforms = []

      # return an Array of ObjectTypes that will have their own tables
      def tables
        decide_tables if !@tables
        @@relational_transforms.each{|tr| tr.call(self)}
        @tables
      end

      def self.relational_transform &block
        # Add this block to the additional transformations which will be applied
        # to the relational schema after the initial absorption.
        # For example, to perform injection of surrogate keys to replace composite keys...
        @@relational_transforms << block
      end

      def wipe_existing_mapping
        all_object_type.each do |object_type|
          object_type.clear_references
          object_type.is_table = nil      # Undecided; force an attempt to decide
          object_type.tentative = true    # Uncertain
        end
      end

      def decide_tables #:nodoc:
        # Strategy:
        # 1) Populate references for all ObjectTypes
        # 2) Decide which ObjectTypes must be and must not be tables
        #  a. ObjectTypes labelled is_independent are tables (See the is_table methods above)
        #  b. Entity types having no references to them must be tables
        #  c. subtypes are not tables unless marked with assimilation = separate or partitioned
        #  d. ValueTypes are never tables unless they independent or can have references (to other ValueTypes)
        #  e. An EntityType having an identifying AutoInc field must be a table unless it has exactly one reference
        #  f. An EntityType whose only reference is through its single preferred_identifier role gets absorbed
        #  g. An EntityType that must has references other than its PI must be a table (unless it has exactly one reference to it)
        #  h. supertypes are elided if all roles are absorbed into subtypes:
        #    - partitioned subtype exhaustion
        #    - subtype extension where supertype has only PI roles and no AutoInc
        # 3) any ValueType that has references from it must become a table if not already

        wipe_existing_mapping

        populate_all_references

        trace :absorption, "Calculating relational composition" do
          # Evaluate the possible independence of each object_type, building an array of object_types of indeterminate status:
          undecided =
            all_object_type.select do |object_type|
              object_type.is_table          # Ask it whether it thinks it should be a table
              object_type.tentative         # Selection criterion
            end

          if trace :absorption, "Generating tables, #{undecided.size} undecided, already decided ones are"
            (all_object_type-undecided).each {|object_type|
              next if ValueType === object_type && !object_type.is_table  # Skip unremarkable cases
              trace :absorption do
                trace :absorption, "#{object_type.name} is #{object_type.is_table ? "" : "not "}a table#{object_type.tentative ? ", tentatively" : ""}"
              end
            }
          end

          pass = 0
          begin                         # Loop while we continue to make progress
            pass += 1
            trace :absorption, "Starting composition pass #{pass} with #{undecided.size} undecided tables"
            possible_flips = {}         # A hash by table containing an array of references that can be flipped
            finalised =                 # Make an array of things we finalised during this pass
              undecided.select do |object_type|
                trace :absorption, "Considering #{object_type.name}:" do
                  trace :absorption, "refs to #{object_type.name} are from #{object_type.references_to.map{|ref| ref.from.name}*", "}" if object_type.references_to.size > 0
                  trace :absorption, "refs from #{object_type.name} are to #{object_type.references_from.map{|ref| ref.to ? ref.to.name : ref.fact_type.default_reading}*", "}" if object_type.references_from.size > 0

                  # Always absorb an objectified unary into its role player:
                  if object_type.fact_type && object_type.fact_type.all_role.size == 1
                    trace :absorption, "Absorb objectified unary #{object_type.name} into #{object_type.fact_type.entity_type.name}"
                    object_type.definitely_not_table
                    next object_type
                  end

                  # If the PI contains one role only, played by an entity type that can absorb us, do that.
                  pi_roles = object_type.preferred_identifier.role_sequence.all_role_ref.map(&:role)
                  trace :absorption, "pi_roles are played by #{pi_roles.map{|role| role.object_type.name}*", "}"
                  first_pi_role = pi_roles[0]
                  pi_ref = nil
                  if pi_roles.size == 1 and
                    object_type.references_to.detect do |ref|
		      if ref.from_role == first_pi_role and ref.from.is_a?(EntityType) # and ref.is_mandatory # REVISIT
			pi_ref = ref
		      end
		    end

                    trace :absorption, "#{object_type.name} is fully absorbed along its sole reference path into entity type #{pi_ref.from.name}"
                    object_type.definitely_not_table
                    next object_type
                  end

                  # If there's more than one absorption path and any functional dependencies that can't absorb us, it's a table
                  non_identifying_refs_from =
                    object_type.references_from.reject{|ref|
                      pi_roles.include?(ref.to_role)
                    }
                  trace :absorption, "#{object_type.name} has #{non_identifying_refs_from.size} non-identifying functional roles"

=begin
                  # This is kinda arbitrary. We need a policy for evaluating optional flips, so we can decide if they "improve" things.
                  # The flipping that occurs below always eliminates a table by absorption, but this doesn't.

                  # If all non-identifying functional roles are one-to-ones that can be flipped, do that:
                  if non_identifying_refs_from.all? { |ref| ref.role_type == :one_one && (ref.to.is_table || ref.to.tentative) }
                    trace :absorption, "Flipping references from #{object_type.name}" do
                      non_identifying_refs_from.each do |ref|
                        trace :absorption, "Flipping #{ref}"
                        ref.flip
                      end
                    end
                    non_identifying_refs_from = []
                  end
=end

                  if object_type.references_to.size > 1 and
                      non_identifying_refs_from.size > 0
                    trace :absorption, "#{object_type.name} has non-identifying functional dependencies so 3NF requires it be a table"
                    object_type.definitely_table
                    next object_type
                  end

                  absorption_paths =
                    (
                      non_identifying_refs_from.reject do |ref|
                        !ref.to or ref.to.absorbed_via == ref
                      end+object_type.references_to
                    ).reject do |ref|
                      next true if !ref.to.is_table or !ref.is_one_to_one

                      # Don't absorb an object along a non-mandatory role (otherwise if it doesn't play that role, it can't exist either)
                      from_is_mandatory = !!ref.is_mandatory
                      to_is_mandatory = !ref.to_role || !!ref.to_role.is_mandatory

                      bad = !(ref.from == object_type ? from_is_mandatory : to_is_mandatory)
                      trace :absorption, "Not absorbing #{object_type.name} through non-mandatory #{ref}" if bad
                      bad
                    end

                  # If this object can be fully absorbed, do that (might require flipping some references)
                  if absorption_paths.size > 0
                    trace :absorption, "#{object_type.name} is fully absorbed through #{absorption_paths.inspect}"
                    absorption_paths.each do |ref|
                      trace :absorption, "Flipping #{ref} so #{object_type.name} can be absorbed"
                      ref.flip if object_type == ref.from
                    end
                    object_type.definitely_not_table
                    next object_type
                  end

                  if non_identifying_refs_from.size == 0
		    # REVISIT: This allows absorption along a non-mandatory role of a objectified fact type
		    # and object_type.references_to.all?{|ref| ref.is_mandatory }
#                    and (!object_type.is_a?(EntityType) ||
#                      # REVISIT: The roles may be collectively but not individually mandatory.
#                      object_type.references_to.detect { |ref| !ref.from_role || ref.from_role.is_mandatory })
                    trace :absorption, "#{object_type.name} is fully absorbed in #{object_type.references_to.size} places: #{object_type.references_to.map{|ref| ref.from.name}*", "}"
                    object_type.definitely_not_table
                    next object_type
                  end

                  false   # Failed to decide about this entity_type this time around
                end
              end

            undecided -= finalised
            trace :absorption, "Finalised #{finalised.size} this pass: #{finalised.map{|f| f.name}*", "}"
          end while !finalised.empty?

          # A ValueType that isn't explicitly a table and isn't needed anywhere doesn't matter,
          # unless it should absorb something else (another ValueType is all it could be):
          all_object_type.each do |object_type|
            if (!object_type.is_table and object_type.references_to.size == 0 and object_type.references_from.size > 0)
              if !object_type.references_from.detect{|r| !r.is_one_to_one || !r.to.is_table}
                trace :absorption, "Flipping references from #{object_type.name}; they're all to tables"
                object_type.references_from.map(&:flip)
              else
                trace :absorption, "Making #{object_type.name} a table; it has nowhere else to go and needs to absorb things"
                object_type.probably_table
              end
            end
          end

          # Now, evaluate all possibilities of the tentative assignments
          # Incomplete. Apparently unnecessary as well... so far. We'll see.
          if trace :absorption
            undecided.each do |object_type|
              trace :absorption, "Unable to decide independence of #{object_type.name}, going with #{object_type.show_tabular}"
            end
          end
        end

        @tables =
          all_object_type.
          select { |f| f.is_table }.
          sort_by { |table| table.name }
      end
    end

  end
end
