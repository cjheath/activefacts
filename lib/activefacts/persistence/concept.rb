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
          # A separate subtype needs to have a foreign key to the supertype:
          # REVISIT: Need keys to secondary supertypes as well, but no duplicates.
          (superclass.is_entity_type ? superclass.__absorb([superclass.basename], self) : []) +
          # Then absorb all normal roles:
          roles.values.select{|role| role.unique}.inject([]) do |columns, role|
            rn = role.name.to_s.split(/_/)
            columns += role.counterpart_concept.__absorb([rn], role.counterpart)
          end +
          # And finally all absorbed subtypes:
          subtypes.
            select{|subtype| !subtype.is_table}.    # Don't absorb separate subtypes
            inject([]) do |columns, subtype|
              # Pass self as 2nd param here, not a role, standing for the supertype role
              columns += subtype.__absorb([[subtype.basename]], self)
            end
          ).map do |col_names|
            col_names.flatten!.uniq.map do |name|
              name.sub(/^[a-z]/){|c| c.upcase}
            end*"."
          end
      end

      # Return an array of the absorbed columns, using prefix for name truncation
      def __absorb(prefix, except_role = nil)
        # also considered a table if the superclass isn't excluded and is (transitively) a table
        if !@is_table && (except_role == superclass || !is_table_subtype)
          if is_entity_type
            if (role = fully_absorbed) && role != except_role
              # If this non-table is fully absorbed into another table (not our caller!)
              # (another table plays its single identifying role), then absorb that role only.
              new_prefix = prefix + [role.name.to_s.split(/_/)]
              role.counterpart_concept.__absorb(new_prefix, role.counterpart)
            else
              # Not a table -> all roles are absorbed
              roles.
                  values.
                  select{|role| role.unique && role != except_role }.
                  inject([]) do |columns, role|
                if (c = role.counterpart_concept).is_entity_type and
                    (irn = c.identifying_role_names).size == 1 and
                    irn[0] == role.counterpart.name
                  new_prefix = prefix
                else
                  new_prefix = prefix + [role.name.to_s.split(/_/)]
                end

                columns += role.counterpart_concept.__absorb(new_prefix, role.counterpart)
              end +
              subtypes.          # Absorb subtype roles too!
                select{|subtype| !subtype.is_table}.    # Don't absorb separate subtypes
                inject([]) { |columns, subtype|
                  # Pass self as 2nd param here, not a role, standing for the supertype role
                  new_prefix = prefix[0..-2] + [[subtype.basename]]
                  columns += subtype.__absorb(new_prefix, self)
                }
            end
          else
            [prefix]
          end
        else
        #puts "#{@is_table ? "referencing" : "absorbing"} #{is_entity_type ? "entity" : "value"} #{basename} using #{prefix.inspect}"
          if is_entity_type
            ic = identifying_role_names.map{|role_name| role_name.to_s.split(/_/)}
            if ic.size == 1 &&      # When you have e.g. Party.ID that identifies Party, just use ID.
                ic[0].size > 1 &&
                ic[0][0] == roles(identifying_role_names[0]).owner.basename.downcase
              ic[0].shift
            end
            ic.map{|column| prefix+[column]}
          else
            # Reference to value type which is a table
            prefix + [["Value"]]
          end
        end
      end

      def is_table_subtype
        klass = superclass
        while klass.is_entity_type
          return true if klass.is_table
          klass = klass.superclass
        end
        return false
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
