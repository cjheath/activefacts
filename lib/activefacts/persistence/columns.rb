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
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  module Metamodel

    class Column
      attr_reader :references

      def references
        @references ||= []
      end

      def initialize(reference = nil)
        references << reference if reference
      end

      def prepend reference
        references.insert 0, reference
        self
      end

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
              role_refs[0].role == ref.from_role
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
            role_refs[0].role == @references.last.to_role and
            names.last[0...et.name.size].downcase == et.name.downcase
          names[-1] = names.last[et.name.size..-1]
          names.pop if names.last == ''
        end

        name_array = names.map{|n| n.sub(/^[a-z]/){|s| s.upcase}}
        joiner ? name_array * joiner : name_array
      end

      def is_mandatory
        !@references.detect{|ref| !ref.is_mandatory}
      end

      def is_auto_assigned
        (to = references[-1].to) && to.is_auto_assigned
      end

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

      def to_s
        "#{@references[0].from.name} column #{name('.')}"
      end
    end

    class Reference
      def columns(excluded_supertypes)
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

    class Concept
      attr_accessor :columns

      def populate_columns
        @columns = all_columns({})
      end
    end

    class ValueType
      def identifier_columns
        debug :columns, "Identifier Columns for #{name}" do
          raise "Illegal call to identifier_columns for absorbed ValueType #{name}" unless is_table
          columns.select{|column| column.references[0] == self_value_reference}
        end
      end

      def reference_columns(excluded_supertypes)
        debug :columns, "Reference Columns for #{name}" do
          if is_table
            [Column.new(self_value_reference)]
          else
            [Column.new]
          end
        end
      end

      def all_columns(excluded_supertypes)
        columns = []
        debug :columns, "All Columns for #{name}" do
          if is_table
            self_value_reference
          else
            columns << Column.new
          end
          references_from.each do |ref|
            debug :columns, "Columns absorbed via #{ref}" do
              columns += ref.columns({})
            end
          end
        end
        columns
      end

      def self_value_reference
        # Make a reference for the self-value column
        @self_value_reference ||= Reference.new(self, nil).tabulate
      end
    end

    class EntityType
      def identifier_columns
        debug :columns, "Identifier Columns for #{name}" do
          if absorbed_via and
            # If this is a subtype that has its own identification, use that.
            (all_type_inheritance_by_subtype.size == 0 ||
              all_type_inheritance_by_subtype.detect{|ti| ti.provides_identification })
            return absorbed_via.from.identifier_columns
          end

          preferred_identifier.role_sequence.all_role_ref.map do |role_ref|
            ref = references_from.detect {|ref| ref.to_role == role_ref.role}

            columns.select{|column| column.references[0] == ref}
          end.flatten
        end
      end

      def reference_columns(excluded_supertypes)
        debug :columns, "Reference Columns for #{name}" do

          if absorbed_via and
            # If this is a subtype that has its own identification, use that.
            (all_type_inheritance_by_subtype.size == 0 ||
              all_type_inheritance_by_subtype.detect{|ti| ti.provides_identification })
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

      def all_columns(excluded_supertypes)
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

    class Vocabulary
      # Do things like adding ID fields and ValueType self-value columns
      def finish_schema
        all_feature.each do |feature|
          feature.self_value_reference if feature.is_a?(ValueType) && feature.is_table
        end
      end

      def populate_all_columns
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
