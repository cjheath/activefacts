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
              columns += subtype.__absorb(sn, self) # Pass self, not a role here, standing for the supertype role
              # puts "subtype #{subtype.name} contributed #{columns.inspect}"
              columns
            }
          ).map{|col_names| col_names.uniq.map{|name| name.sub(/^[a-z]/){|c| c.upcase}}*"."}
      end

      def is_table_subtype
        klass = superclass
        while klass.is_entity_type
          return true if klass.is_table
          klass = klass.superclass
        end
        return false
      end

      # Return an array of the absorbed columns, using prefix for name truncation
      def __absorb(prefix, except_role = nil)
        if !@is_table && 
          # also considered a table if the superclass isn't excluded and is (transitively) a table
          (except_role == superclass || !is_table_subtype)
          if is_entity_type
            if role = fully_absorbed
              # If this non-table is fully absorbed into another table
              # (another table plays its single identifying role), then
              # absorb that role only
              return [] if role == except_role
              role.counterpart_concept.__absorb(prefix + role.name.to_s.split(/_/), role.counterpart)
            else
              # Not a table -> all roles are absorbed
              roles.
                  values.
                  select{|role| role.unique && role.counterpart != except_role }.
                  inject([]) do |columns, role|
                columns += role.counterpart_concept.__absorb(prefix + role.name.to_s.split(/_/), role)
              end
            end
          else
            [prefix]
          end
        else
        #puts "#{@is_table ? "referencing" : "absorbing"} #{is_entity_type ? "entity" : "value"} #{basename} using #{prefix.inspect}"
          if is_entity_type
            identifying_role_names.map{|role_name| prefix+role_name.to_s.split(/_/)}
          else
            # Reference to value type which is a table
            [prefix + ["Value"]]
          end
        end
      end
    end

    module Entity
      module ClassMethods
        def fully_absorbed
          return false unless (ir = identifying_role_names) && ir.size == 1
          role = roles(ir[0])
          return role if ((cp = role.counterpart_concept).is_table ||
              (cp.is_entity_type && cp.fully_absorbed))
          nil
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
