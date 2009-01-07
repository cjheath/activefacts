module ActiveFacts
  module Metamodel

    class ForeignKey
      attr_reader :from, :to, :reference, :from_columns, :to_columns
      def initialize(from, to, fk_ref, from_columns, to_columns)
        @from, @to, @fk_ref, @from_columns, @to_columns =
          from, to, fk_ref, from_columns, to_columns
      end
    end

    class Concept
      def foreign_keys
        fk_refs = references_from.select{|ref| ref.is_simple_reference }
        fk_columns = columns.select do |column|
          column.references[0].is_simple_reference
        end

        fk_refs.map do |fk_ref|
          from_columns = columns.select{|column| column.references[0] == fk_ref }

          to = fk_ref.to
          # REVISIT: There should be a better way to find where it's absorbed (especially since this fails for absorbed subtypes having their own identification!)
          while (r = to.absorbed_via)
            #puts "#{to.name} is absorbed into #{r.to.name}/#{r.from.name}"
            to = r.to == to ? r.from : r.to
          end
          raise "REVISIT: #{fk_ref} is bad" unless to and to.columns

          all_to_columns_by_roles = to.columns.inject({}) do |hash, column|
            hash[column.references.map{|ref| ref.to_role}] = column
            hash
          end
          to_columns = from_columns.map do |from_column|
            c ||= all_to_columns_by_roles[from_column.references[1..-1].map{|ref| ref.to_role}]
            raise "REVISIT: Failed to find target column for #{fk_ref} matching #{from_column.name}" unless c
            # p from_column.references
            # p from_column.references[1]
            # p from_column.references[1].from_role
            # p from_column.references[1].to_role
            c
          end
          ForeignKey.new(self, to, fk_ref, from_columns, to_columns)
        end
      end
    end
  end
end
