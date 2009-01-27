#
#       ActiveFacts Relational mapping and persistence.
#       A ForeignKey exists for every Reference from a Concept to another Concept that's a table.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Persistence
    class ForeignKey
      # What table (Concept) is the FK from?
      def from; @from; end

      # What table (Concept) is the FK to?
      def to; @to; end

      # What reference created the FK?
      def reference; @reference; end

      # What columns in the *from* table form the FK
      def from_columns; @from_columns; end

      # What columns in the *to* table form the identifier
      def to_columns; @to_columns; end

      def initialize(from, to, fk_ref, from_columns, to_columns) #:nodoc:
        @from, @to, @fk_ref, @from_columns, @to_columns =
          from, to, fk_ref, from_columns, to_columns
      end
    end
  end

  module Metamodel    #:nodoc:
    class Concept
      # When an EntityType is fully absorbed, its foreign keys are too.
      # Return an Array of Reference paths for such absorbed FKs
      def all_absorbed_foreign_key_reference_path
        references_from.inject([]) do |array, ref|

          if ref.is_simple_reference
            # This catches references that would be created to secondary supertypes, when absorption is through primary.
            # There might be other cases where an exclusion like this is needed, but I can't reason it out.
            next array if TypeInheritance === ref.fact_type && absorbed_via && TypeInheritance === absorbed_via.fact_type
            array << [ref]
          elsif ref.is_absorbing
            ref.to.all_absorbed_foreign_key_reference_path.each{|aref|
              array << aref.insert(0, ref)
            }
          end
          array
        end
      end

      # Return an array of all the foreign keys from this table
      def foreign_keys
        fk_ref_paths = all_absorbed_foreign_key_reference_path

        # Get the ForeignKey object for each absorbed reference path
        fk_ref_paths.map do |fk_ref_path|
          debug :fk, "\nFK: " + fk_ref_path.map{|fk_ref| fk_ref.reading }*" and " do

            from_columns = columns.select{|column|
              column.references[0...fk_ref_path.size] == fk_ref_path
            }
            debug :fk, "from_columns = #{from_columns.map { |column| column.name }*", "}"

            absorption_path = []
            to = fk_ref_path.last.to
            # REVISIT: There should be a better way to find where it's absorbed (especially since this fails for absorbed subtypes having their own identification!)
            while (r = to.absorbed_via)
              absorption_path << r
              to = r.to == to ? r.from : r.to
            end
            raise "REVISIT: #{fk_ref_path.inspect} is bad" unless to and to.columns

            unless absorption_path.empty?
              debug :fk, "Reference target #{fk_ref_path.last.to.name} is absorbed into #{to.name} via:" do
                debug :fk, "#{absorption_path.map(&:reading)*" and "}"
              end
            end

            debug :fk, "Looking at absorption depth of #{absorption_path.size} in #{to.name} for to_columns for #{from_columns.map(&:name)*", "}:"
            to_supertypes = to.supertypes_transitive
            to_columns = from_columns.map do |from_column|
              debug :fk, "\tLooking for counterpart of #{from_column.name}: #{from_column.comment}" do
                target_path = absorption_path + from_column.references[fk_ref_path.size..-1]
                debug :fk, "\tcounterpart MUST MATCH #{target_path.map(&:reading)*" and "}"
                c = to.columns.detect do |column|
                  debug :fk, "Considering #{column.references.map(&:reading) * " and "}"
                  debug :fk, "exact match: #{column.name}: #{column.comment}" if column.references == target_path
                  # Column may be inherited into "to", in which case target_path is too long.
                  cr = column.references
                  allowed_type = fk_ref_path.last.to
                  #debug :fk, "Check for absorption, need #{allowed_type.name}" if cr != target_path
                  cr == target_path or
                    cr == target_path[-cr.size..-1] &&
                    !target_path[0...-cr.size].detect do |ref|
                      ft = ref.fact_type
                      next true if allowed_type.absorbed_via != ref   # Problems if it doesn't match
                      allowed_type = ref.from
                      false
                    end
                end
                raise "REVISIT: Failed to find conterpart column for #{from_column.name}" unless c
                c
              end
            end
            debug :fk, "to_columns in #{to.name}: #{to_columns.map { |column| column ? column.name : "OOPS!" }*", "}"

            ActiveFacts::Persistence::ForeignKey.new(self, to, fk_ref_path[-1], from_columns, to_columns)
          end
        end
      end
    end
  end
end
