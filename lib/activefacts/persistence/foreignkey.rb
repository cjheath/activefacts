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

      def verbalised_path
	# REVISIT: This should be a proper join path verbalisation:
	references.map do |r|
	  (r.fact_type.entity_type ? r.fact_type.entity_type.name + ' (in which ' : '') +
	    r.fact_type.default_reading +
	    (r.fact_type.entity_type ? ')' : '')
	end * ' and '
      end

      # Which references are absorbed into the "from" table?
      def precursor_references
	fk_jump = @references.detect(&:fk_jump)
	jump_index = @references.index(fk_jump)
	@references[0, jump_index]
      end

      # Which references are absorbed into the "to" table?
      def following_references
	fk_jump = @references.detect(&:fk_jump)
	jump_index = @references.index(fk_jump)
	fk_jump != @references.last ? @references[jump_index+1..-1] : []
      end

      def jump_reference
	@references.detect(&:fk_jump)
      end

      def to_name
	p = precursor_references
	f = following_references
	j = jump_reference

	@references.last.to_names +
	  (p.empty? && f.empty? ? [] : ['via'] + p.map{|r| r.to_names}.flatten + f.map{|r| r.from_names}.flatten)
      end

      # The from_name is the role name of the table with the FK, viewed from the other end
      # When there are no precursor_references or following_references, it's the jump_reference.from_names
      # REVISIT: I'm still working out what to do with precursor_references and following_references
      def from_name
	p = precursor_references
	f = following_references
	j = jump_reference

	# pluralise unless j.is_one_to_one

	# REVISIT: references[0].from_names is where the FK lives; but the object of interest may be an absorbed subclass which we should use here instead:
	# REVISIT: Should crunch superclasses in subtype traversals
	# REVISIT: Need to add "_as_rolename" where rolename is not to.name

	[
	  @references[0].from_names,
	  (p.empty? && f.empty? ? [] : ['via'] + p.map{|r| r.to_names}.flatten + f.map{|r| r.from_names}.flatten)
	]
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
	    ref.fk_jump = true
            array << [ref]
          elsif ref.is_absorbing or (ref.to && !ref.to.is_table)
	    debug :fk, "getting fks absorbed into #{name} via #{ref}" do
	      ref.to.all_absorbed_foreign_key_reference_path.each do |aref|
		array << aref.insert(0, ref)
	      end
	    end
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
		      m = r.reversed
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
#	      debugger if !fk.to_columns || fk.to_columns.include?(nil) || !fk.from_columns || fk.from_columns.include?(nil)
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
