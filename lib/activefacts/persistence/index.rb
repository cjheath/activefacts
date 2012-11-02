#
#       ActiveFacts Relational mapping and persistence.
#       An Index on a ObjectType is used to represent a unique constraint across roles absorbed
#       into that object_type's table.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  module Persistence
    class Index
      # The UniquenessConstraint that created this index
      def uniqueness_constraint; @uniqueness_constraint; end

      # The table that the index is on
      def on; @on; end

      # If a non-mandatory reference was absorbed, only the non-nil instances are unique.
      # Return the ObjectType that was absorbed, which might differ from this Index's table.
      def over; @over; end

      # Return the array of columns in this index
      def columns; @columns; end

      # Is this index the primary key for this table?
      def is_primary; @is_primary; end

      # Is this index unique?
      def is_unique; @is_unique; end

      # An Index arises from a uniqueness constraint and applies to a table,
      # but because the UC may actually be over an object absorbed into the table,
      # we must record that object also.
      # We record the columns it's over, whether it's primary (for 'over'),
      # and whether it's unique (always, at present)
      def initialize(uc, on, over, columns, is_primary, is_unique = true)   #:nodoc:
        @uniqueness_constraint, @on, @over, @columns, @is_primary, @is_unique =
          uc, on, over, columns, is_primary, is_unique
      end

      # The name that was assigned (perhaps implicitly by NORMA)
      def real_name
        @uniqueness_constraint.name && @uniqueness_constraint.name != '' ? @uniqueness_constraint.name.gsub(' ','') : nil
      end

      # This name is either the name explicitly assigned (if any) or is constructed to form a unique index name.
      def name
        uc = @uniqueness_constraint
        r = real_name
        return r if r && r !~ /^(Ex|In)ternalUniquenessConstraint[0-9]+$/
        (uc.is_preferred_identifier ? "PK_" : "IX_") +
          view_name +
          (uc.is_preferred_identifier ? "" : "By"+column_names*"")
      end

      # An array of the names of the columns this index covers
      def column_names(separator = "")
        columns.map{|column| column.name(separator)}
      end

      # An array of the names of the columns this index covers, with some lexical truncations.
      def abbreviated_column_names(separator = "")
        columns.map{|column| column.name(separator).sub(/^#{over.name}/,'')}
      end

      # The name of a view that can be created to enforce uniqueness over non-null key values
      def view_name
        "#{over.name.gsub(' ','')}#{on == over ? "" : "In"+on.name.gsub(' ','')}"
      end

      def to_s  #:nodoc:
        name = @uniqueness_constraint.name
        colnames = @columns.map(&:name)*", "
        preferred = @uniqueness_constraint.is_preferred_identifier ? " (preferred)" : ""
        "Index #{name} on #{@on.name} over #{@over.name}(#{colnames})#{preferred}"
      end
    end
  end

  module Metamodel    #:nodoc:
    class ObjectType
      # An array of each Index for this table
      def indices; @indices; end

      def clear_indices     #:nodoc:
        # Clear any previous indices
        @indices = nil
      end

      def populate_indices     #:nodoc:
        # The absorption path of a column indicates how it came to be in this table.
        # It might be a direct many:one valuetype relationship, or it might be in such
        # a relationship to an entity that was absorbed into this table (and so on).
        # The reference path is the set of absorption references and one past it.
        # Stopping here means we don't dig into the definitions of FK column counterparts.
        # Note that many columns of an object may have the same ref_path.
        #
        # REVISIT:
        # Note also that this produces columns ordered for each refpath the same as the
        # order of the columns, not the same as the columns in the PK for which they might be an FK.
        all_column_by_ref_path =
          debug :index2, "Indexing columns by ref_path" do
            @columns.inject({}) do |hash, column|
              debug :index2, "References in column #{name}.#{column.name}" do
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
                #debug :index2, "Considering #{ref_path.map(&:to_s)*" and "} yielding columns #{all_column_by_ref_path[ref_path].map{|c| c.name(".")}*", "}"
                ref.to_role.all_role_ref.each do |role_ref|
                  all_pcs = role_ref.role_sequence.all_presence_constraint
    #puts "pcs over #{ref_path.map{|r| r.to_names}.flatten*"."}: #{role_ref.role_sequence.all_presence_constraint.map(&:describe)*"; "}" if all_pcs.size > 0
                  pcs = all_pcs.
                    reject do |pc|
                      !pc.max_frequency or      # No maximum freq; cannot be a uniqueness constraint
                      pc.max_frequency != 1 or  # maximum is not 1
                                                # Constraint is not over a unary fact type role (NORMA does this)
                      pc.role_sequence.all_role_ref.size == 1 && ref_path[-1].to_role.fact_type.all_role.size == 1
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
              (rr = uc.role_sequence.all_role_ref.single) and
              over.absorbed_via.fact_type.all_role.include?(rr.role)

            index = ActiveFacts::Persistence::Index.new(
              uc,
              self,
              over,
              columns,
              uc.is_preferred_identifier
            )
            debug :index, index
            index
          end.
          compact.
          sort_by do |index|
            # Put the indices in a defined order:
            index.columns.map(&:name)+['', index.over.name]
          end
        end
      end

    end

    class Vocabulary
      def populate_all_indices  #:nodoc:
        debug :index, "Populating all object_type indices" do
          all_object_type.each do |object_type|
            object_type.clear_indices
          end
          all_object_type.each do |object_type|
            next unless object_type.is_table
            debug :index, "Populating indices for #{object_type.name}" do
              object_type.populate_indices
            end
          end
        end
        debug :index, "Finished object_type indices" do
          all_object_type.each do |object_type|
            next unless object_type.is_table
            next unless object_type.indices.size > 0
            debug :index, "#{object_type.name}:" do
              object_type.indices.each do |index|
                debug :index, index
              end
            end
          end
        end
      end
    end

  end
end
