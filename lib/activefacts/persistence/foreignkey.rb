#
#       ActiveFacts Relational mapping and persistence.
#       A ForeignKey exists for every Reference from a ObjectType to another ObjectType that's a table.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Persistence
    class ForeignKey
      # What table (ObjectType) is the FK from?
      def from; @from; end

      # What table (ObjectType) is the FK to?
      def to; @to; end

      # What reference created the FK?
      def references; @references; end

      # What columns in the *from* table form the FK
      def from_columns; @from_columns; end

      # What columns in the *to* table form the identifier
      def to_columns; @to_columns; end

      def initialize(from, to, references, from_columns, to_columns) #:nodoc:
        @from, @to, @references, @from_columns, @to_columns =
          from, to, references, from_columns, to_columns
      end

      def describe
	"foreign key from #{from.name}(#{from_columns.map{|c| c.name}*', '}) to #{to.name}(#{to_columns.map{|c| c.name}*', '})"
      end
    end
  end

  module Metamodel    #:nodoc:
    class ObjectType
      # When an EntityType is fully absorbed, its foreign keys are too.
      # Return an Array of Reference paths for such absorbed FKs
      def all_absorbed_foreign_key_reference_path
        references_from.inject([]) do |array, ref|
          if ref.is_simple_reference
            if TypeInheritance === ref.fact_type
              # Ignore references to secondary supertypes, when absorption is through primary.
              next array if absorbed_via && TypeInheritance === absorbed_via.fact_type
              # Ignore the case where a subtype is absorbed elsewhere:
              # REVISIT: Disabled, as this should never happen.
              # next array if ref.to.absorbed_via != ref.fact_type
            end
            array << [ref]
          elsif ref.is_absorbing or (ref.to && !ref.to.is_table)
            ref.to.all_absorbed_foreign_key_reference_path.each{|aref|
              array << aref.insert(0, ref)
            }
          end
          array
        end
      end

      def foreign_keys_to
	@foreign_keys_to ||= []
      end

      # Return an array of all the foreign keys from this table
      def foreign_keys

        # Get the ForeignKey object for each absorbed reference path
	@foreign_keys ||= 
	  begin
	    fk_ref_paths = all_absorbed_foreign_key_reference_path
	    fk_ref_paths.map do |fk_ref_path|
	      debug :fk, "\nFK: " + fk_ref_path.map{|fk_ref| fk_ref.reading }*" and " do

		from_columns = (columns||all_columns({})).select{|column|
		  column.references[0...fk_ref_path.size] == fk_ref_path
		}
		debug :fk, "from_columns = #{from_columns.map { |column| column.name }*", "}"

		# Figure out absorption on the target end:
		to = fk_ref_path.last.to
		if to.absorbed_via
		  debug :fk, "Reference target #{fk_ref_path.last.to.name} is absorbed via:" do
		    while (r = to.absorbed_via)
		      m = r.mirror
		      debug :fk, "#{m.reading}"
		      fk_ref_path << m
		      to = m.from == to ? m.to : m.from
		    end
		    debug :fk, "Absorption ends at #{to.name}"
		  end
		end

		# REVISIT: This test may no longer be necessary
		raise "REVISIT: #{fk_ref_path.inspect} is bad" unless to and to.columns

		# REVISIT: This fails for absorbed subtypes having their own identification.
		# Check the CompanyDirectorEmployee model for example, EmployeeManagerNr -> Person (should reference EmployeeNr)
		# Need to use the absorbed identifier_columns of the subtype,
		# not the columns of the supertype that absorbs it.
		# But in general, that isn't going to work because in most DBMS
		# there's no suitable uniquen index on the subtype's identifier_columns

		to_columns = fk_ref_path[-1].to.identifier_columns

		# Put the column pairs in the correct order. They MUST be in the order they appear in the primary key
		froms, tos = from_columns.zip(to_columns).sort_by { |pair|
		  to_columns.index(pair[1])
		}.transpose

		fk = ActiveFacts::Persistence::ForeignKey.new(self, to, fk_ref_path, froms, tos)
		to.foreign_keys_to << fk
		fk
	      end
	    end.
	    sort_by do |fk|
	      # Put the foreign keys in a defined order:
	      [ fk.to.name,
		fk.to_columns.map{|col| col.name(nil).sort},
		fk.from_columns.map{|col| col.name(nil).sort}
	      ]
	    end
	  end

      end
    end
  end
end
