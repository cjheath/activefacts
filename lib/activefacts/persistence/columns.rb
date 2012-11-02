#
#       ActiveFacts Relational mapping and persistence.
#       Columns in a relational table; each is derived from a sequence of References.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# Each Reference from a ObjectType creates one or more Columns.
# A reference to a simple valuetype creates a single column, as
# does a reference to a table entity identified by a single value.
#
# When referring to a object_type that doesn't have its own table,
# all references from that object_type are absorbed into this one.
#
# When multiple values identify an entity that does have its own
# table, a reference to that entity creates multiple columns,
# a multi-part foreign key.
#

module ActiveFacts
  module Persistence    #:nodoc:

    class Column
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
      # appended by a separator string (pass nil to get the original array of names)
      # The names to use is derived from the to_names of each Reference,
      # modified by these rules:
      # * A reference after the first one which is not a TypeInheritance but where the _from_ object plays the sole role in the preferred identifier of the _to_ entity is ignored,
      # * A reference (after a name has been retained) which is a TypeInheritance retains the names of the subtype,
      # * If the names retained so far end in XYZ and the to_names start with XYZ, remove the duplication
      # * If we have retained the name of an entity, and this reference is the sole identifying role of an entity, and the identifying object has a name that is prefixed by the name of the object it identifies, remove the prefix and use just the suffix.
      def name(separator = "")
        self.class.name(@references, separator)
      end

      def self.name(refs, separator = "")
        last_names = []
        names = refs.
          inject([]) do |a, ref|

            # Skip any object after the first which is identified by this reference
            if ref != refs[0] and
                !ref.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) and
                ref.to and
                ref.to.is_a?(ActiveFacts::Metamodel::EntityType) and
                (role_ref = ref.to.preferred_identifier.role_sequence.all_role_ref.single) and
                role_ref.role == ref.from_role
              debug :columns, "Skipping #{ref}, identifies non-initial object"
              next a
            end

            names = ref.to_names

            # When traversing type inheritances, keep the subtype name, not the supertype names as well:
            if a.size > 0 && ref.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
              if ref.to != ref.fact_type.subtype  # Did we already have the subtype?
                debug :columns, "Skipping supertype #{ref}"
                next a
              end
              debug :columns, "Eliding supertype in #{ref}"
              last_names.size.times { a.pop }   # Remove the last names added
            elsif last_names.last && last_names.last == names[0][0...last_names.last.size] 
              # When Xyz is followed by XyzID, truncate that to just ID
              debug :columns, "truncating repeated #{last_names.last} in #{names[0]}"
              names[0] = names[0][last_names.last.size..-1]
              names.shift if names[0] == ''
            elsif last_names.last == names[0]
              # Same, but where an underscore split up the words
              debug :columns, "truncating repeated name in #{names.inspect}"
              names.shift
            end

            # If the reference is to the single identifying role of the object_type making the reference,
            # strip the object_type name from the start of the reference role
            if a.size > 0 and
                (et = ref.from).is_a?(ActiveFacts::Metamodel::EntityType) and
                # This instead of the next 2 would apply to all identifying roles, but breaks some examples:
                # (role_ref = et.preferred_identifier.role_sequence.all_role_ref.detect{|rr| rr.role == ref.to_role}) and
                (role_ref = et.preferred_identifier.role_sequence.all_role_ref.single) and
                role_ref.role == ref.to_role and
                names[0][0...et.name.size].downcase == et.name.downcase

              debug :columns, "truncating transitive identifying role #{names.inspect}"
              names[0] = names[0][et.name.size..-1]
              names.shift if names[0] == ""
            end

            last_names = names

            a += names
            a
          end.elide_repeated_subsequences { |a, b|
            if a.is_a?(Array)
              a.map{|e| e.downcase} == b.map{|e| e.downcase}
            else
              a.downcase == b.downcase
            end
          }

        name_array = names.map{|n| n.sub(/^[a-z]/){|s| s.upcase}}
        separator ? name_array * separator : name_array
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
        constraints = []
        return ["BIT", params, constraints] if references[-1].is_unary   # It's a unary

        # Add a role value constraint
        # REVISIT: Can add join-role-value-constraints here, if we ever provide a way to define them
        if references[-1].to_role && references[-1].to_role.role_value_constraint
          constraints << references[-1].to_role.role_value_constraint
        end

        vt = references[-1].is_self_value ? references[-1].from : references[-1].to
        params[:length] ||= vt.length if vt.length.to_i != 0
        params[:scale] ||= vt.scale if vt.scale.to_i != 0
        while vt.supertype
          params[:length] ||= vt.length if vt.length.to_i != 0
          params[:scale] ||= vt.scale if vt.scale.to_i != 0
          constraints << vt.value_constraint if vt.value_constraint
          vt = vt.supertype
        end
        return [vt.name, params, constraints]
      end

      # The comment is the readings from the References expressed as a series of steps (not a full verbalisation)
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
          if is_unary && !(@to && @to.fact_type)
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
    # The ObjectType class is defined in the metamodel; full documentation is not generated.
    # This section shows the features relevant to relational Persistence.
    class ObjectType
      # The array of columns for this ObjectType's table
      def columns
        @columns
      end

      def populate_columns  #:nodoc:
        @columns =
          all_columns({})
      end
    end

    # The ValueType class is defined in the metamodel; full documentation is not generated.
    # This section shows the features relevant to relational Persistence.
    class ValueType < ObjectType
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
    class EntityType < ObjectType
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
            # If this is not a subtype, or is a subtype that has its own identification, use the id.
            (all_type_inheritance_as_subtype.size == 0 ||
              all_type_inheritance_as_subtype.detect{|ti| ti.provides_identification })
            rc = absorbed_via.from.reference_columns(excluded_supertypes)
            # The absorbed_via reference gets skipped here, ans also in object_type.rb
            debug :columns, "Skipping #{absorbed_via}"
            #rc.each{|col| col.prepend(absorbed_via)}
            return rc
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
          pi_roles = preferred_identifier.role_sequence.all_role_ref.map{|rr| rr.role}
          references_from.sort_by do |ref|
            # Put supertypes first, in order, then PI roles, non-subtype references by name, then subtypes by name:
            next [0, p] if p = sups.index(ref.to)
            if !ref.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
              next [1, p] if p = pi_roles.index(ref.to_role)
              next [2, ref.to_names]
            end
            [3, ref.to_names]
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
        all_object_type.each do |object_type|
          object_type.self_value_reference if object_type.is_a?(ActiveFacts::Metamodel::ValueType) && object_type.is_table
        end
      end

      def populate_all_columns  #:nodoc:
        # REVISIT: Is now a good time to apply schema transforms or should this be more explicit?
        finish_schema

        debug :columns, "Populating all columns" do
          all_object_type.each do |object_type|
            next if !object_type.is_table
            debug :columns, "Populating columns for table #{object_type.name}" do
              object_type.populate_columns
            end
          end
        end
        debug :columns, "Finished columns" do
          all_object_type.each do |object_type|
            next if !object_type.is_table
            debug :columns, "Finished columns for table #{object_type.name}" do
              object_type.columns.each do |column|
                debug :columns, "#{column}"
              end
            end
          end
        end
      end
    end

    end
  end
