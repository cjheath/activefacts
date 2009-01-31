module ActiveFacts
  module API
    module Concept
      def table
        @is_table = true
      end

      def is_table
        @is_table
      end

      def columns
        #puts "Calculating columns for #{basename}"
        return @columns if @columns
        @columns = (
          roles.
              values.
              select{|role| role.unique}.
              inject([]) do |columns, role|
            rn = role.name.to_s.split(/_/)
            columns += role.counterpart_concept.__absorb(rn, role.counterpart)
          end +
          # REVISIT: Need to use subtypes_transitive here:
          subtypes.
            select{|subtype| !subtype.is_table}.    # Don't absorb separate subtypes
            inject([]) { |columns, subtype|
              sn = [subtype.basename]
              columns += subtype.__absorb(sn)
              # puts "subtype #{subtype.name} contributed #{columns.inspect}"
              columns
            }
          ).map{|col_names| col_names.uniq.map{|name| name.sub(/^[a-z]/){|c| c.upcase}}*"."}
      end

      # Return an array of the absorbed columns, using prefix for name truncation
      def __absorb(prefix, except_role = nil)
        is_entity = respond_to?(:identifying_role_names)
        absorbed_into = nil
        if absorbed_into
          # REVISIT: if this concept is fully absorbed through one of its roles into another table, we absorb that tables identifying_roles
          absorbed_into.__absorb(prefix)
        elsif !@is_table
          # Not a table -> all roles are absorbed
          if is_entity
            roles.
                values.
                select{|role| role.unique && role.counterpart_concept != except_role }.
                inject([]) do |columns, role|
              columns += role.counterpart_concept.__absorb(prefix + role.name.to_s.split(/_/), self)
            end
          else
            [prefix]
          end
        else
        #puts "#{@is_table ? "referencing" : "absorbing"} #{is_entity ? "entity" : "value"} #{basename} using #{prefix.inspect}"
          if is_entity
            identifying_role_names.map{|role_name| prefix+role_name.to_s.split(/_/)}
          else
            # Reference to value type which is a table
            [prefix + ["Value"]]
          end
        end
      end
    end

  end
end

class TrueClass
  def self.__absorb(prefix, except_role = nil)
    [prefix]
  end
end
