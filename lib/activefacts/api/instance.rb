#
# The ActiveFacts Runtime API Instance extension module.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
# Instance methods are extended into all instances, whether of value or entity types.
#
module ActiveFacts
  module API
    module Instance
      attr_accessor :constellation

      # Instance methods:
      def initialize(args = [])
        unless (self.class.respond_to?(:identifying_roles))
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
      def delete
        # Delete from the constellation first, so it can remember our identifying role values
        @constellation.delete(self) if @constellation
        self.class.roles.each{|role_name, role|
            next unless role.unary?
            send "#{role.name}=", nil
          }
      end

      module ClassMethods
        include Concept
        # Add Instance class methods here
      end

      def Instance.included other
        other.send :extend, ClassMethods
      end
    end
  end
end
