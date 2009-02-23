require 'activefacts/support'

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
        return @columns if @columns
        debug :persistence, "Calculating columns for #{basename}" do
          @columns = (
            if superclass.is_entity_type
              # REVISIT: Need keys to secondary supertypes as well, but no duplicates.
              debug :persistence, "Separate subtype has a foreign key to its supertype" do
                superclass.__absorb([[superclass.basename]], self)
              end
            else
              []
            end +
            # Then absorb all normal roles:
            roles.values.select{|role| role.unique}.inject([]) do |columns, role|
              rn = role.name.to_s.split(/_/)
              debug :persistence, "Role #{rn*'.'}" do
                columns += role.counterpart_concept.__absorb([rn], role.counterpart)
              end
            end +
            # And finally all absorbed subtypes:
            subtypes.
              select{|subtype| !subtype.is_table}.    # Don't absorb separate subtypes
              inject([]) do |columns, subtype|
                # Pass self as 2nd param here, not a role, standing for the supertype role
                debug :persistence, "Absorbing subtype #{subtype.basename}" do
                  columns += subtype.__absorb([[subtype.basename]], self)
                end
              end
            ).map do |col_names|
              last = nil
              col_names.flatten.map do |name|
                name.downcase.sub(/^[a-z]/){|c| c.upcase}
              end.
              reject do |n|
                # Remove sequential duplicates:
                dup = last == n
                last = n
                dup
              end*"."
            end
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
              # counterpart_concept = role.counterpart_concept
              # This omission matches the one in columns.rb, see EntityType#reference_columns
              # new_prefix = prefix + [role.name.to_s.split(/_/)]
              debug :persistence, "Reference to #{role.name} (absorbed elsewhere)" do
                role.counterpart_concept.__absorb(prefix, role.counterpart)
              end
            else
              # Not a table -> all roles are absorbed
              roles.
                  values.
                  select{|role| role.unique && role != except_role }.
                  inject([]) do |columns, role|
                columns += __absorb_role(prefix, role)
              end +
              subtypes.          # Absorb subtype roles too!
                select{|subtype| !subtype.is_table}.    # Don't absorb separate subtypes
                inject([]) do |columns, subtype|
                  # Pass self as 2nd param here, not a role, standing for the supertype role
                  new_prefix = prefix[0..-2] + [[subtype.basename]]
                  debug :persistence, "Absorbed subtype #{subtype.basename}" do
                    columns += subtype.__absorb(new_prefix, self)
                  end
                end
            end
          else
            [prefix]
          end
        else
          # Create a foreign key to the table
          if is_entity_type
            ir = identifying_role_names.map{|role_name| roles(role_name) }
            debug :persistence, "Reference to #{basename} with #{prefix.inspect}" do
              ic = identifying_role_names.map{|role_name| role_name.to_s.split(/_/)}
              ir.inject([]) do |columns, role|
                columns += __absorb_role(prefix, role)
              end
            end
          else
            # Reference to value type which is a table
            col = prefix.clone
            debug :persistence, "Self-value #{col[-1]}.Value"
            col[-1] += ["Value"]
            col
          end
        end
      end

      def __absorb_role(prefix, role)
        if prefix.size > 0 and
            (c = role.owner).is_entity_type and
            (irn = c.identifying_role_names).size == 1 and
            (n = irn[0].to_s.split(/_/)).size > 1 and
            (owner = role.owner.basename.snakecase.split(/_/)) and
            n[0...owner.size] == owner
          #debug :persistence, "truncating transitive identifying role #{n.inspect}"
#          REVISIT: This might be closer to what we want, except it doesn't deal with owner as an array
#          n.include?(ro_name = role.owner.basename.downcase)
#          new_prefix = prefix + [n.reject{|p| p == ro_name}]
          owner.size.times { n.shift }
          new_prefix = prefix + [n]
        elsif (c = role.counterpart_concept).is_entity_type and
            (irn = c.identifying_role_names).size == 1 and
            #irn[0].to_s.split(/_/)[0] == role.owner.basename.downcase
            irn[0] == role.counterpart.name
          #debug :persistence, "=== #{irn[0].to_s.split(/_/)[0]} elided ==="
          new_prefix = prefix
        elsif (fa_role = fully_absorbed) && fa_role == role
          new_prefix = prefix
        else
          new_prefix = prefix + [role.name.to_s.split(/_/)]
        end
        #debug :persistence, "new_prefix is #{new_prefix*"."}"

        debug :persistence, "Absorbed role #{role.name} as #{new_prefix[prefix.size..-1]*"."}" do
          role.counterpart_concept.__absorb(new_prefix, role.counterpart)
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
