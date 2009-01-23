#
#       ActiveFacts Relational mapping and persistence.
#       Columns in a relational table; each is derived from a sequence of References.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# Each Reference from a Concept creates one or more Columns.
# A reference to a simple valuetype creates a single column, as
# does a reference to a table entity identified by a single value.
#
# When referring to a concept that doesn't have its own table,
# all references from that concept are absorbed into this one.
#
# When multiple values identify an entity that does have its own
# table, a reference to that entity creates multiple columns,
# a multi-part foreign key.
#

module ActiveFacts
  module Persistence    #:nodoc:

    class Column
      include Metamodel

      def initialize(reference = nil) #:nodoc:
        references << reference if reference
      end

      # A Column is created from a path through an array of References to a ValueType
      def references
        @references ||= []
      end

      # All references up to and including the first non-absorbing reference
      def absorption_references
        @references.inject([]) do |array, ref|
          array << ref
          # puts "Column #{name} spans #{ref}, #{ref.is_absorbing ? "" : "not "} absorbing (#{ref.to.name} absorbs via #{ref.to.absorbed_via.inspect})"
          break array unless ref.is_absorbing
          array
        end
      end

      # How many of the initial references are involved in full absorption of an EntityType into this column's table
      def absorption_level
        l = 0
        @references.detect do |ref|
          l += 1 if ref.is_absorbing
          false
        end
        l
      end

      def prepend reference           #:nodoc:
        references.insert 0, reference
        self
      end

      # A Column name is a sequence of names (derived from the to_roles of the References)
      # joined by a joiner string (pass nil to get the original array of names)
      def name(joiner = "")
        last_name = ""
        names = @references.
          reject do |ref|
            # Skip any object after the first which is identified by this reference
            ref != @references[0] and
              !ref.fact_type.is_a?(TypeInheritance) and
              ref.to and
              ref.to.is_a?(EntityType) and
              (role_refs = ref.to.preferred_identifier.role_sequence.all_role_ref).size == 1 and
              role_refs.only.role == ref.from_role
          end.
          inject([]) do |a, ref|
            names = ref.to_names

            # When traversing type inheritances, keep the subtype name, not the supertype names as well:
            if a.size > 0 && ref.fact_type.is_a?(TypeInheritance)
              a[-1] = names[0] if ref.to == ref.fact_type.subtype   # Else we already had the subtype
              next a
            end

            # When Xyz is followed by XyzID, truncate that to just ID:
            names[0] = names[0][last_name.size..-1] if last_name == names[0][0...last_name.size] 
            last_name = names.last

            a += names
            a
          end

        # Where the last name is like a reference mode but the preceeding name isn't the identified concept,
        # strip it down (so turn Driver.PartyID into Driver.ID for example):
        if names.size > 1 and
            (et = @references.last.from).is_a?(EntityType) and
            (role_refs = et.preferred_identifier.role_sequence.all_role_ref).size == 1 and
            role_refs.only.role == @references.last.to_role and
            names.last[0...et.name.size].downcase == et.name.downcase
          names[-1] = names.last[et.name.size..-1]
          names.pop if names.last == ''
        end

        name_array = names.map{|n| n.sub(/^[a-z]/){|s| s.upcase}}
        joiner ? name_array * joiner : name_array
      end

      # Is this column mandatory or nullable?
      def is_mandatory
        !@references.detect{|ref| !ref.is_mandatory}
      end

      # Is this column an auto-assigned value type?
      def is_auto_assigned
        (to = references[-1].to) && to.is_auto_assigned
      end

      # What's the underlying SQL data type of this column?
      def type
        params = {}
        restrictions = []
        return ["BIT", params, restrictions] if references[-1].is_unary   # It's a unary

        # Add a role value restriction
        # REVISIT: Can add join-role-value-restrictions here, if we ever provide a way to define them
        if references[-1].to_role && references[-1].to_role.role_value_restriction
          restrictions << references[-1].to_role.role_value_restriction
        end

        vt = references[-1].is_self_value ? references[-1].from : references[-1].to
        params[:length] ||= vt.length if vt.length.to_i != 0
        params[:scale] ||= vt.scale if vt.scale.to_i != 0
        while vt.supertype
          params[:length] ||= vt.length if vt.length.to_i != 0
          params[:scale] ||= vt.scale if vt.scale.to_i != 0
          restrictions << vt.value_restriction if vt.value_restriction
          vt = vt.supertype
        end
        return [vt.name, params, restrictions]
      end

      # The comment is the readings from the References expressed as a join
      def comment
        @references.map do |ref|
          (ref.is_mandatory ? "" : "maybe ") +
          (ref.fact_type && ref.fact_type.entity_type ? ref.fact_type.entity_type.name+" is where " : "") +
          ref.reading
        end * " and "
      end

      def to_s  #:nodoc:
        "#{@references[0].from.name} column #{name('.')}"
      end
    end

    class Reference
      def columns(excluded_supertypes)  #:nodoc:
        kind = ""
        cols = 
          if is_unary
            kind = "unary "
            [Column.new()]
          elsif is_self_value
            kind = "self-role "
            [Column.new()]
          elsif is_simple_reference
            @to.reference_columns(excluded_supertypes)
          else
            kind = "absorbing "
            @to.all_columns(excluded_supertypes)
          end

        cols.each do |c|
          c.prepend self
        end

        debug :columns, "Columns from #{kind}#{self}" do
          cols.each {|c|
            debug :columns, "#{c}"
          }
        end
      end
    end
  end

  module Metamodel    #:nodoc:
    # The Concept class is defined in the metamodel; full documentation is not generated.
    # This section shows the features relevant to relational Persistence.
    class Concept
      # The array of columns for this Concept's table
      def columns; @columns; end

      def populate_columns  #:nodoc:
        @columns = all_columns({})
      end
    end

    # The ValueType class is defined in the metamodel; full documentation is not generated.
    # This section shows the features relevant to relational Persistence.
    class ValueType < Concept
      # The identifier_columns for a ValueType can only ever be the self-value role that was injected
      def identifier_columns
        debug :columns, "Identifier Columns for #{name}" do
          raise "Illegal call to identifier_columns for absorbed ValueType #{name}" unless is_table
          columns.select{|column| column.references[0] == self_value_reference}
        end
      end

      # When creating a foreign key to this ValueType, what columns must we include?
      # This must be a fresh copy, because the columns will have References prepended
      def reference_columns(excluded_supertypes)  #:nodoc:
        debug :columns, "Reference Columns for #{name}" do
          if is_table
            [ActiveFacts::Persistence::Column.new(self_value_reference)]
          else
            [ActiveFacts::Persistence::Column.new]
          end
        end
      end

      # When absorbing this ValueType, what columns must be absorbed?
      # This must be a fresh copy, because the columns will have References prepended.
      def all_columns(excluded_supertypes)    #:nodoc:
        columns = []
        debug :columns, "All Columns for #{name}" do
          if is_table
            self_value_reference
          else
            columns << ActiveFacts::Persistence::Column.new
          end
          references_from.each do |ref|
            debug :columns, "Columns absorbed via #{ref}" do
              columns += ref.columns({})
            end
          end
        end
        columns
      end

      # If someone asks for this, it's because it's needed, so create it.
      def self_value_reference  #:nodoc:
        # Make a reference for the self-value column
        @self_value_reference ||= ActiveFacts::Persistence::Reference.new(self, nil).tabulate
      end
    end

    # The EntityType class is defined in the metamodel; full documentation is not generated.
    # This section shows the features relevant to relational Persistence.
    class EntityType < Concept
      # The identifier_columns for an EntityType are the columns that result from the identifying roles
      def identifier_columns
        debug :columns, "Identifier Columns for #{name}" do
          if absorbed_via and
            # If this is a subtype that has its own identification, use that.
            (all_type_inheritance_as_subtype.size == 0 ||
              all_type_inheritance_as_subtype.detect{|ti| ti.provides_identification })
            return absorbed_via.from.identifier_columns
          end

          preferred_identifier.role_sequence.all_role_ref.map do |role_ref|
            ref = references_from.detect {|ref| ref.to_role == role_ref.role}

            columns.select{|column| column.references[0] == ref}
          end.flatten
        end
      end

      # When creating a foreign key to this EntityType, what columns must we include (the identifier columns)?
      # This must be a fresh copy, because the columns will have References prepended
      def reference_columns(excluded_supertypes)    #:nodoc:
        debug :columns, "Reference Columns for #{name}" do

          if absorbed_via and
            # If this is a subtype that has its own identification, use that.
            (all_type_inheritance_as_subtype.size == 0 ||
              all_type_inheritance_as_subtype.detect{|ti| ti.provides_identification })
            return absorbed_via.from.reference_columns(excluded_supertypes)
          end

          # REVISIT: Should have built preferred_identifier_references
          preferred_identifier.role_sequence.all_role_ref.map do |role_ref|
            # REVISIT: Should index references by to_role:
            ref = references_from.detect {|ref| ref.to_role == role_ref.role}

            raise "reference for role #{role.describe} not found on #{name} in #{references_from.size} references:\n\t#{references_from.map(&:to_s)*"\n\t"}" unless ref

            ref.columns({})
          end.flatten
        end
      end

      # When absorbing this EntityType, what columns must be absorbed?
      # This must be a fresh copy, because the columns will have References prepended.
      def all_columns(excluded_supertypes)    #:nodoc:
        debug :columns, "All Columns for #{name}" do
          columns = []
          sups = supertypes
          references_from.sort_by do |ref|
            # Put supertypes first, in order, then non-subtype references, then subtypes, otherwise retaining their order:
            sups.index(ref.to) ||
              (!ref.fact_type.is_a?(TypeInheritance) && references_from.size+references_from.index(ref)) ||
              references_from.size*2+references_from.index(ref)
          end.each do |ref|
            debug :columns, "Columns absorbed via #{ref}" do
              if (ref.role_type == :supertype)
                if excluded_supertypes[ref.to]
                  debug :columns, "Exclude #{ref.to.name}, we already inherited it"
                  next
                end

                next if (ref.to.absorbed_via != ref)
                excluded_supertypes[ref.to] = true
                columns += ref.columns(excluded_supertypes)
              else
                columns += ref.columns({})
              end
            end
          end
          columns
        end
      end
    end

    # The Vocabulary class is defined in the metamodel; full documentation is not generated.
    # This section shows the features relevant to relational Persistence.
    class Vocabulary
      # Make schema transformations like adding ValueType self-value columns (and later, Rails-friendly ID fields).
      # Override this method to change the transformations
      def finish_schema
        all_feature.each do |feature|
          feature.self_value_reference if feature.is_a?(ValueType) && feature.is_table
        end
      end

      def populate_all_columns  #:nodoc:
        # REVISIT: Is now a good time to apply schema transforms or should this be more explicit?
        finish_schema

        debug :columns, "Populating all columns" do
          all_feature.each do |feature|
            next if !feature.is_a?(Concept) || !feature.is_table
            debug :columns, "Populating columns for table #{feature.name}" do
              feature.populate_columns
            end
          end
        end
        debug :columns, "Finished columns" do
          all_feature.each do |feature|
            next if !feature.is_a?(Concept) || !feature.is_table
            debug :columns, "Finished columns for table #{feature.name}" do
              feature.columns.each do |column|
                debug :columns, "#{column}"
              end
            end
          end
        end
      end
    end

    end
  end
