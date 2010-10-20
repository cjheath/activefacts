#
#       ActiveFacts Runtime API
#       Instance (mixin module for instances of a ObjectType - a class with ObjectType mixed in)
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# Instance methods are extended into all instances, whether of value or entity types.
#
module ActiveFacts
  module API
    # Every Instance of a ObjectType (A Value type or an Entity type) includes the methods of this module:
    module Instance
      # What constellation does this Instance belong to (if any):
      attr_accessor :constellation

      def initialize(args = []) #:nodoc:
        unless (self.class.is_entity_type)
        #if (self.class.superclass != Object)
          # puts "constructing #{self.class.superclass} with #{args.inspect}"
          super(*args)
        end
      end

      # Verbalise this instance
      def verbalise
        # This method should always be overridden in subclasses
        raise "#{self.class} Instance verbalisation needed"
      end

      # De-assign all functional roles and remove from constellation, if any.
      def retract
        # Delete from the constellation first, so it can remember our identifying role values
        @constellation.__retract(self) if @constellation

        # Now, for all roles (from this class and all supertypes), assign nil to all functional roles
        # The counterpart roles get cleared automatically.
        ([self.class]+self.class.supertypes_transitive).each do |klass|
          klass.roles.each do |role_name, role|
            next if role.unary?
            next if !role.unique

            counterpart = role.counterpart
            puts "Nullifying mandatory role #{role.name} of #{role.owner.name}" if counterpart.mandatory

            send "#{role.name}=", nil
          end
        end
      end

      module ClassMethods #:nodoc:
        include ObjectType
        # Add Instance class methods here
      end

      def Instance.included other #:nodoc:
        other.send :extend, ClassMethods
      end
    end
  end
end
