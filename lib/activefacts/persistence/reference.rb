#
# A Reference from one Concept to another is created for each many-1 or 1-1 relationship
# (including subtyping), and also for a unary role (implicitly to Boolean concept).
# A 1-1 or subtyping reference should be created in only one direction, and may be flipped
# if needed.
#
# A reference to a concept that's a table or is fully absorbed into a table will
# become a foreign key, otherwise it will absorb all that concept's references.
#
# Reference objects update each concept's list of the references *to* and *from* that concept.
#
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
# REVISIT: References need is_mandatory
# REVISIT: Need to index References by to_role, to help in finding PK references etc.

module ActiveFacts
  module Metamodel

    class Reference
      attr_reader :from, :to            # A "from" instance is related to one "to" instance
      attr_reader :from_role, :to_role  # For objectified facts, one role will be nil (a phantom)
      attr_reader :fact_type

      # A Reference is created from a concept in regard to a role it plays
      def initialize(from, role)
        @from = from
        return unless role              # All done if it's a self-value reference for a ValueType
        @fact_type = role.fact_type
        if @fact_type.all_role.size == 1
          # @from_role is nil for a unary
          @to_role = role
          @to = role.fact_type.entity_type      # nil unless the unary is objectified
        elsif (role.fact_type.entity_type == @from)  # role is in "from", an objectified fact type
          @from_role = nil                      # Phantom role
          @to_role = role
          @to = @to_role.concept
        else
          @from_role = role
          @to = role.fact_type.entity_type      # If set, to_role is a phantom
          unless @to
            raise "Illegal reference through >binary fact type" if @fact_type.all_role.size >2
            @to_role = (role.fact_type.all_role-[role])[0]
            @to = @to_role.concept
          end
        end
      end

      def role_type
        role = @from_role||@to_role
        role && role.role_type
      end

      def is_unary
        !@to && @to_role && @to_role.fact_type.all_role.size == 1
      end

      # This case is the only one that cannot be used in the preferred identifier of @from
      def is_to_objectified_fact
        @to && !@to_role && @from_role
      end

      def is_from_objectified_fact
        @to && @to_role && !@from_role
      end

      def is_self_value
        !@to && !@to_role
      end

      def is_absorbing
        @to.absorbed_via == self
      end

      def is_simple_reference
        # It's a simple reference to a thing if that thing is a table,
        # or is fully absorbed into another table REVISIT: but not via this reference.
        @to && (@to.is_table or @to.absorbed_via && !is_absorbing)
      end

      def to_names
        case
        when is_unary
          @to_role.fact_type.preferred_reading.reading_text.gsub(/\{[0-9]\}/,'').strip.split(/\s/)
        when @to && !@to_role           # @to is an objectified fact type so @to_role is a phantom
          [@to.name]
        when !@to_role                  # Self-value role of an independent ValueType
          ["#{@from.name}Value"]
        when @to_role.role_name         # Named role
          [@to_role.role_name]
        else                            # Use the name from the preferred reading
          role_ref = @to_role.preferred_reference
          [role_ref.leading_adjective, @to_role.concept.name, role_ref.trailing_adjective].compact.map{|w| w.split(/\s/)}.flatten.reject{|s| s == ''}
        end
      end

      # For a one-to-one (or a subtyping fact type), reverse the direction:
      def flip
        raise "Illegal reference flip" unless @to and [:one_one, :subtype, :supertype].include?(role_type)

        detabulate

        if @to.absorbed_via == self
          @to.absorbed_via = nil
          @from.absorbed_via = self
        end

        # Flip the reference
        @to, @from = @from, @to
        @to_role, @from_role = @from_role, @to_role

        tabulate
      end

      def tabulate
        # Add to @to and @from's reference lists
        @from.references_from << self
        @to.references_to << self if @to        # Guard against self-values

        debug :references, "Adding #{to_s}"
        self
      end

      def detabulate
        # Remove from @to and @from's reference lists if present
        return unless @from.references_from.delete(self)
        @to.references_to.delete self if @to    # Guard against self-values
        debug :references, "Dropping #{to_s}"
        self
      end

      def to_s
        "reference from #{@from.name}#{@to ? " to #{@to.name}" : ""}" + (@fact_type ? " in '#{@fact_type.default_reading}'" : "")
      end

      def inspect; to_s; end
    end

    class Concept
      # Say whether the independence of this object is still under consideration
      # This is used in detecting dependency cycles, such as occurs in the Metamodel
      attr_accessor :tentative
      attr_writer :is_table     # The two Concept subclasses provide the reader

      def show_tabular
        (tentative ? "tentatively " : "") +
        (is_table ? "" : "not ")+"a table"
      end

      def definitely_table
        @is_table = true
        @tentative = false
      end

      def definitely_not_table
        @is_table = false
        @tentative = false
      end

      def probably_table
        @is_table = true
        @tentative = true
      end

      def probably_not_table
        @is_table = false
        @tentative = true
      end

      def references_from
        @references_from ||= []
      end

      def references_to
        @references_to ||= []
      end

      def has_references
        @references_from || @references_to
      end

      def clear_references
        # Clear any previous references:
        @references_to = nil
        @references_from = nil
      end

      def populate_references
        all_role.each do |role|
          populate_reference role
        end
      end

      def populate_reference role
        role_type = role.role_type
        debug :references, "#{name} has #{role_type} role in '#{role.fact_type.describe}'"
        case role_type
        when :many_one
          Reference.new(self, role).tabulate      # A simple reference

        when :one_many
          if role.fact_type.entity_type == self   # A Role of this objectified FactType
            Reference.new(self, role).tabulate    # A simple reference; check that
          else
            # Can't absorb many of these into one of those
            #debug :references, "Ignoring #{role_type} reference from #{name} to #{Reference.new(self, role).to.name}"
          end

        when :unary
          Reference.new(self, role).tabulate      # A simple reference

        when :supertype   # A subtype absorbs a reference to its supertype when separate, or all when partitioned
          # REVISIT: Or when partitioned
          if role.fact_type.subtype.is_independent
            debug :references, "supertype #{name} doesn't absorb a reference to separate subtype #{role.fact_type.subtype.name}"
          else
            r = Reference.new(self, role)
            r.to.absorbed_via = r
            debug :references, "supertype #{name} absorbs subtype #{r.to.name}"
            r.tabulate
          end

        when :subtype    # This object is a supertype, which can absorb the subtype unless that's independent
          if is_independent    # REVISIT: Or when partitioned
            Reference.new(self, role).tabulate
            # If partitioned, the supertype is absorbed into *each* subtype; a reference to the supertype needs to know which
          else
            # debug :references, "subtype #{name} is absorbed into #{role.fact_type.supertype.name}"
          end

        when :one_one
          r = Reference.new(self, role)

          # Decide which way the one-to-one is likely to go; it will be flipped later if necessary.
          # Force the decision if just one is independent:
          r.tabulate and return if is_independent and !r.to.is_independent
          return if !is_independent and r.to.is_independent

          if is_a?(ValueType)
            # Never absorb an entity type into a value type
            return if r.to.is_a?(EntityType)  # Don't tabulate it
          else
            if r.to.is_a?(ValueType)
              r.tabulate  # Always absorb a value type into an entity type
              return 
            end

            # Force the decision if one EntityType identifies another:
            if preferred_identifier.role_sequence.all_role_ref.detect{|rr| rr.role == r.to_role}
              debug :references, "EntityType #{name} is identified by EntityType #{r.to.name}, so gets absorbed elsewhere"
              return
            end
            if r.to.preferred_identifier.role_sequence.all_role_ref.detect{|rr| rr.role == role}
              debug :references, "EntityType #{name} identifies EntityType #{r.to.name}, so absorbs it"
              r.to.absorbed_via = r
              r.tabulate
              return
            end
          end

          # Either both EntityTypes, or both ValueTypes.
          # Make an arbitrary (but stable) decision which way to go. We might flip it later.
          unless r.from.name < r.to.name or
            (r.from == r.to && references_to.detect{|ref| ref.to_role == role}) # one-to-one self reference, done already
            r.tabulate
          end
        else
          raise "Illegal role type, #{role.fact_type.describe(role)} no uniqueness constraint"
        end
      end
    end

    class EntityType
      def populate_references
        if fact_type && fact_type.all_role.size > 1
          # NOT: fact_type.all_role.each do |role|  # Place roles in the preferred order instead:
          fact_type.preferred_reading.role_sequence.all_role_ref.map(&:role).each do |role|
            populate_reference role     # Objectified fact role, handled specially
          end
        end
        super
      end
    end

    class Vocabulary
      def populate_concept_references
        debug :references, "Populating all concept references" do
          all_feature.each do |feature|
            next unless feature.is_a? Concept
            feature.clear_references
            feature.is_table = nil      # Undecided; force an attempt to decide
            feature.tentative = true    # Uncertain
          end
          all_feature.each do |feature|
            next unless feature.is_a? Concept
            debug :references, "Populating references for #{feature.name}" do
              feature.populate_references
            end
          end
        end
        debug :references, "Finished concept references" do
          all_feature.each do |feature|
            next unless feature.is_a? Concept
            next unless feature.references_from.size > 0
            debug :references, "#{feature.name}:" do
              feature.references_from.each do |ref|
                debug :references, "#{ref}"
              end
            end
          end
        end
      end
    end

  end
end
