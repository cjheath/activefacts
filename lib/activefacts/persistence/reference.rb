#
#       ActiveFacts Relational mapping and persistence.
#       Reference from one ObjectType to another, used to decide the relational mapping.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# A Reference from one ObjectType to another is created for each many-1 or 1-1 relationship
# (including subtyping), and also for a unary role (implicitly to Boolean object_type).
# A 1-1 or subtyping reference should be created in only one direction, and may be flipped
# if needed.
#
# A reference to a object_type that's a table or is fully absorbed into a table will
# become a foreign key, otherwise it will absorb all that object_type's references.
#
# Reference objects update each object_type's list of the references *to* and *from* that object_type.
#
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  module Persistence

    # This class contains the core data structure used in composing a relational schema.
    #
    # A Reference is *from* one ObjectType *to* another ObjectType, and relates to the *from_role* and the *to_role*.
    # When either ObjectType is an objectified fact type, the corresponding role is nil.
    # When the Reference from_role is of a unary fact type, there's no to_role or to ObjectType.
    # The final kind of Reference is a self-reference which is added to a ValueType that becomes a table.
    #
    # When the underlying fact type is a one-to-one (including an inheritance fact type), the Reference may be flipped.
    #
    # Each Reference has a name; an array of names in fact, in case of adjectives, etc.
    # Each Refererence can produce the reading of the underlying fact type.
    #
    # A Reference is indexed in the player's *references_from* and *references_to*, and flipping updates those.
    # Finally, a Reference may be marked as absorbing the whole referenced object, and that can flip too.
    #
    class Reference
      attr_reader :from, :to            # A "from" instance is related to one "to" instance
      attr_reader :from_role, :to_role  # For objectified facts, one role will be nil (a phantom)
      attr_reader :fact_type

      # A Reference is created from a object_type in regard to a role it plays
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
          @to = @to_role.object_type
        else
          @from_role = role
          @to = role.fact_type.entity_type      # If set, to_role is a phantom
          unless @to
            raise "Illegal reference through >binary fact type" if @fact_type.all_role.size >2
            @to_role = (role.fact_type.all_role-[role])[0]
            @to = @to_role.object_type
          end
        end
      end

      # What type of Role did this Reference arise from?
      def role_type
        role = @from_role||@to_role
        role && role.role_type
      end

      # Is this Reference covered by a mandatory constraint (implicitly or explicitly)
      def is_mandatory
        !@from_role ||        # All phantom roles of fact types are mandatory
        is_unary ||           # Unary fact types become booleans, which must be true or false
        @from_role.is_mandatory
      end

      # Is this Reference from a unary Role?
      def is_unary
        @to_role && @to_role.fact_type.all_role.size == 1
      end

      # If this Reference is to an objectified FactType, there is no *to_role*
      def is_to_objectified_fact
        # This case is the only one that cannot be used in the preferred identifier of @from
        @to && !@to_role && @from_role
      end

      # If this Reference is from an objectified FactType, there is no *from_role*
      def is_from_objectified_fact
        @to && @to_role && !@from_role
      end

      # Is this reference an injected role as a result a ValueType being a table?
      def is_self_value
        !@to && !@to_role
      end

      # Is the *to* object_type fully absorbed through this reference?
      def is_absorbing
        @to && @to.absorbed_via == self
      end

      # Is this a simple reference?
      def is_simple_reference
        # It's a simple reference to a thing if that thing is a table,
        # or is fully absorbed into another table but not via this reference.
        @to && (@to.is_table or @to.absorbed_via && !is_absorbing)
      end

      # Return the array of names for the (perhaps implicit) *to_role* of this Reference
      def to_names
        case
        when is_unary
          if @to && @to.fact_type
            @to.name.camelwords
          else
            @to_role.fact_type.preferred_reading.text.gsub(/\{[0-9]\}/,'').strip.camelwords
          end
        when @to && !@to_role           # @to is an objectified fact type so @to_role is a phantom
          @to.name.camelwords
        when !@to_role                  # Self-value role of an independent ValueType
          @from.name.camelwords + ["Value"]
        when @to_role.role_name         # Named role
          @to_role.role_name.camelwords
        else                            # Use the name from the preferred reading
          role_ref = @to_role.preferred_reference
          [role_ref.leading_adjective, @to_role.object_type.name, role_ref.trailing_adjective].compact.map{|w| w.camelwords}.flatten.reject{|s| s == ''}
        end
      end

      # Return the array of names for the (perhaps implicit) *from_role* of this Reference
      def from_names
        case
        when is_unary
          if @from && @from.fact_type
            @from.name.camelwords
          else
            @from_role.fact_type.preferred_reading.text.gsub(/\{[0-9]\}/,'').strip.camelwords
          end
        when @from && !@from_role           # @from is an objectified fact type so @from_role is a phantom
          @from.name.camelwords
        when !@from_role                  # Self-value role of an independent ValueType
          @from.name.camelwords + ["Value"]
        when @from_role.role_name         # Named role
          @from_role.role_name.camelwords
        else                            # Use the name from the preferred reading
          role_ref = @from_role.preferred_reference
          [role_ref.leading_adjective, @from_role.object_type.name, role_ref.trailing_adjective].compact.map{|w| w.camelwords}.flatten.reject{|s| s == ''}
        end
      end

      # For a one-to-one (or a subtyping fact type), reverse the direction.
      def flip                          #:nodoc:
        raise "Illegal flip of #{self}" unless @to and [:one_one, :subtype, :supertype].include?(role_type)

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

      def tabulate        #:nodoc:
        # Add to @to and @from's reference lists
        @from.references_from << self
        @to.references_to << self if @to        # Guard against self-values

        debug :references, "Adding #{to_s}"
        self
      end

      def detabulate        #:nodoc:
        # Remove from @to and @from's reference lists if present
        return unless @from.references_from.delete(self)
        @to.references_to.delete self if @to    # Guard against self-values
        debug :references, "Dropping #{to_s}"
        self
      end

      def to_s              #:nodoc:
        "reference from #{@from.name}#{@to ? " to #{@to.name}" : ""}" + (@fact_type ? " in '#{@fact_type.default_reading}'" : "")
      end

      # The reading for the fact type underlying this Reference
      def reading
        is_self_value ? "#{from.name} has value" : @fact_type.default_reading
      end

      def inspect #:nodoc:
        to_s
      end
    end
  end

  module Metamodel          #:nodoc:
    class ObjectType < Concept
      # Say whether the independence of this object is still under consideration
      # This is used in detecting dependency cycles, such as occurs in the Metamodel
      attr_accessor :tentative          #:nodoc:
      attr_writer :is_table             # The two ObjectType subclasses provide the attr_reader method

      def show_tabular                  #:nodoc:
        (tentative ? "tentatively " : "") +
        (is_table ? "" : "not ")+"a table"
      end

      def definitely_table              #:nodoc:
        @is_table = true
        @tentative = false
      end

      def definitely_not_table          #:nodoc:
        @is_table = false
        @tentative = false
      end

      def probably_table                #:nodoc:
        @is_table = true
        @tentative = true
      end

      def probably_not_table            #:nodoc:
        @is_table = false
        @tentative = true
      end

      # References from this ObjectType
      def references_from
        @references_from ||= []
      end

      # References to this ObjectType
      def references_to
        @references_to ||= []
      end

      # True if this ObjectType has any References (to or from)
      def has_references                #:nodoc:
        @references_from || @references_to
      end

      def clear_references              #:nodoc:
        # Clear any previous references:
        @references_to = nil
        @references_from = nil
      end

      def populate_references           #:nodoc:
        all_role.each do |role|
          # It's possible that this role is in an implicit or derived fact type. Skip it if so.
          next if role.fact_type.is_a?(ImplicitFactType) or
            role.fact_type.preferred_reading.role_sequence.all_role_ref.to_a[0].play
          
          populate_reference role
        end
      end

      def populate_reference role       #:nodoc:
        role_type = role.role_type
        debug :references, "#{name} has #{role_type} role in '#{role.fact_type.describe}'"
        case role_type
        when :many_one
          ActiveFacts::Persistence::Reference.new(self, role).tabulate      # A simple reference

        when :one_many
          if role.fact_type.entity_type == self   # A Role of this objectified FactType
            ActiveFacts::Persistence::Reference.new(self, role).tabulate    # A simple reference; check that
          else
            # Can't absorb many of these into one of those
            #debug :references, "Ignoring #{role_type} reference from #{name} to #{Reference.new(self, role).to.name}"
          end

        when :unary
          ActiveFacts::Persistence::Reference.new(self, role).tabulate      # A simple reference

        when :supertype   # A subtype absorbs a reference to its supertype when separate, or all when partitioned
          # REVISIT: Or when partitioned
          raise hell unless role.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
          if role.fact_type.assimilation  # assimilation == 'separate' or assimilation == 'partitioned'
            debug :references, "supertype #{name} doesn't absorb a reference to separate subtype #{role.fact_type.subtype.name}"
          else
            r = ActiveFacts::Persistence::Reference.new(self, role)
            r.to.absorbed_via = r
            debug :references, "supertype #{name} absorbs subtype #{r.to.name}"
            r.tabulate
          end

        when :subtype    # This object is a supertype, which can absorb the subtype unless that's independent
          raise hell unless role.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
          if role.fact_type.assimilation
            ActiveFacts::Persistence::Reference.new(self, role).tabulate
            # If partitioned, the supertype is absorbed into *each* subtype; a reference to the supertype needs to know which
          else
            # debug :references, "subtype #{name} is absorbed into #{role.fact_type.supertype.name}"
          end

        when :one_one
          r = ActiveFacts::Persistence::Reference.new(self, role)

          # Decide which way the one-to-one is likely to go; it will be flipped later if necessary.
          # Force the decision if just one is independent:
          # REVISIT: Decide whether supertype assimilation can affect this
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
              # We can't be absorbed into our supertype!
              # REVISIT: We might need to flip all one-to-ones as well
              r.to.references_to.clone.map{|q|q.flip if q.to_role.role_type == :subtype }
              r.tabulate
              return
            end
          end

          # Either both EntityTypes, or both ValueTypes.
          # Make an arbitrary (but stable) decision which way to go. We might flip it later,
          # but not frivolously; the Ruby API column name generation duplicates this logic.
          unless r.from.name.downcase < r.to.name.downcase or
            (r.from == r.to && references_to.detect{|ref| ref.to_role == role}) # one-to-one self reference, done already
            r.tabulate
          end
        else
          raise "Role #{role.object_type.name} in '#{role.fact_type.default_reading}' lacks a uniqueness constraint"
        end
      end
    end

    class EntityType < ObjectType
      def populate_references          #:nodoc:
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
      def populate_all_references #:nodoc:
        debug :references, "Populating all object_type references" do
          all_object_type.each do |object_type|
            object_type.clear_references
            object_type.is_table = nil      # Undecided; force an attempt to decide
            object_type.tentative = true    # Uncertain
          end
          all_object_type.each do |object_type|
            debug :references, "Populating references for #{object_type.name}" do
              object_type.populate_references
            end
          end
        end
        debug :references, "Finished object_type references" do
          all_object_type.each do |object_type|
            next unless object_type.references_from.size > 0
            debug :references, "#{object_type.name}:" do
              object_type.references_from.each do |ref|
                debug :references, "#{ref}"
              end
            end
          end
        end
      end
    end

  end
end
