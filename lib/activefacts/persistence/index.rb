#
# An Index on a Concept is used to represent a unique constraint across roles absorbed
# into that concept's table.
#
# Reference objects update each concept's list of the references *to* and *from* that concept.
#
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  module Metamodel
    class Index
      attr_reader :uniqueness_constraint, :on, :over, :columns, :is_primary, :is_unique

      # An Index arises from a uniqueness constraint and applies to a table,
      # but because the UC may actually be over an object absorbed into the table,
      # we must record that object also.
      # We record the columns it's over, whether it's primary (for 'over'),
      # and whether it's unique (always, at present)
      def initialize(uc, on, over, columns, is_primary, is_unique = true)
        @uniqueness_constraint, @on, @over, @columns, @is_primary, @is_unique =
          uc, on, over, columns, is_primary, is_unique
      end

      def real_name
        @uniqueness_constraint.name && @uniqueness_constraint.name != '' ? @uniqueness_constraint.name : nil
      end

      def name
        uc = @uniqueness_constraint
        r = real_name
        return r if r && r !~ /^(Ex|In)ternalUniquenessConstraint[0-9]+$/
        (uc.is_preferred_identifier ? "PK_" : "IX_") +
          view_name +
          (uc.is_preferred_identifier ? "" : "By"+column_names*"")
      end

      def abbreviated_column_names
        columns.map{|column| column.name.sub(/^#{over.name}/,'')}
      end

      def column_names
        columns.map{|column| column.name}
      end

      def view_name
        "#{over.name}#{on == over ? "" : "In"+on.name}"
      end

      def to_s
        name = @uniqueness_constraint.name
        colnames = @columns.map(&:name)*", "
        preferred = @uniqueness_constraint.is_preferred_identifier ? " (preferred)" : ""
        "Index #{name} on #{@on.name} over #{@over.name}(#{colnames})#{preferred}"
      end
    end

    class Concept
      attr_reader :indices

      def clear_indices
        # Clear any previous indices
        @indices = nil
      end

      def populate_indices
        # The absorption path of a column indicates how it came to be in this table.
        # It might be a direct many:one valuetype relationship, or it might be in such
        # a relationship to an entity that was absorbed into this table (and so on).
        # The reference path is the set of absorption references and one past it.
        # Stopping here means we don't dig into the definitions of FK column counterparts.
        # Note that many columns of an object may have the same ref_path.
        all_column_by_ref_path =
          debug :index2, "Indexing columns by ref_path" do
            columns.inject({}) do |hash, column|
              debug :index2, "References in column #{name}#{column.name}" do
                ref_path = column.absorption_references
                raise "No absorption_references for #{column.name} from #{column.references.map(&:to_s)*" and "}" if !ref_path || ref_path.empty?
                (hash[ref_path] ||= []) << column
                debug :index2, "#{column.name} involves #{ref_path.map(&:to_s)*" and "}"
              end
              hash
            end
          end

        columns_by_unique_constraint = {}
        all_column_by_role_ref =
          all_column_by_ref_path.
            keys.                       # Go through all refpaths and find uniqueness constraints
            inject({}) do |hash, ref_path|
              ref_path.each do |ref|
                next unless ref.to_role
                ref.to_role.all_role_ref.each do |role_ref|
                  pcs = role_ref.role_sequence.all_presence_constraint.
                    reject do |pc|
                      !pc.max_frequency or      # No maximum freq; cannot be a uniqueness constraint
                      pc.max_frequency != 1 or  # maximum is not 1
                      pc.role_sequence.all_role_ref.size == 1 &&        # UniquenessConstraint is over one role
                        (pc.role_sequence.all_role_ref[0].role.fact_type.is_a?(TypeInheritance) ||      # Inheritance
                        pc.role_sequence.all_role_ref[0].role.fact_type.all_role.size == 1)             # Unary
                        # The preceeeding two restrictions exclude the internal UCs created within NORMA.
                    end
                  next unless pcs.size > 0
                  # The columns for this ref_path support the UCs in "pcs".
                  pcs.each do |pc|
                    ref_columns = all_column_by_ref_path[ref_path]
                    ordinal = role_ref.ordinal  # Position in priority order
                    ref_columns.each_with_index do |column, index|
                      #puts "Adding index column #{column.name} in rank[#{ordinal},#{index}]"
                      # REVISIT: the "index" here might be a duplicate in some cases: change sort_by below to just sort and run the SeparateSubtypes CQL model for example.
                      (columns_by_unique_constraint[pc] ||= []) << [ordinal, index, column]
                    end
                  end
                  hash[role_ref] = all_column_by_ref_path[ref_path]
                end
              end
              hash
            end

        debug :index, "All Indices in #{name}:" do
          @indices = columns_by_unique_constraint.map do |uc, columns_with_ordinal|
            #puts "Index on #{name} over (#{columns_with_ordinal.sort.map{|ca| [ca[0], ca[1], ca[2].name].inspect}})"
            columns = columns_with_ordinal.sort_by{|ca| [ca[0,2], ca[2].name]}.map{|ca| ca[2]}
            absorption_level = columns.map(&:absorption_level).min
            over = columns[0].references[absorption_level].from

            # Absorption through a one-to-one forms a UC that we don't need to enforce using an index:
            next nil if over != self and
              over.absorbed_via == columns[0].references[absorption_level-1] and
              (rrs = uc.role_sequence.all_role_ref).size == 1 and
              over.absorbed_via.fact_type.all_role.include?(rrs[0].role)

            index = Index.new(
              uc,
              self,
              over,
              columns,
              uc.is_preferred_identifier
            )
            debug :index, index
            index
          end.compact
        end
      end

    end

    class Vocabulary
      def populate_all_indices
        debug :index, "Populating all concept indices" do
          all_feature.each do |feature|
            next unless feature.is_a? Concept
            feature.clear_indices
          end
          all_feature.each do |feature|
            next unless feature.is_a? Concept
            next unless feature.is_table
            debug :index, "Populating indices for #{feature.name}" do
              feature.populate_indices
            end
          end
        end
        debug :index, "Finished concept indices" do
          all_feature.each do |feature|
            next unless feature.is_a? Concept
            next unless feature.is_table
            next unless feature.indices.size > 0
            debug :index, "#{feature.name}:" do
              feature.indices.each do |index|
                debug :index, index
              end
            end
          end
        end
      end
    end

  end
end
