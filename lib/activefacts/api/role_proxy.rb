#
#       ActiveFacts Runtime API
#       RoleProxy class, still somewhat experimental
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'delegate'

module ActiveFacts
  module API
    #
    # When you use the accessor method created by has_one, one_to_one, or maybe, you get a RoleProxy for the actual value.
    # This behaves almost exactly as the value, but it knows through which role you fetched it.
    # That will allow it to verbalise itself using the correct reading for that role.
    #
    # Don't use "SomeClass === role_value" to test the type, use "role_value.is_a?(SomeClass)" instead.
    #
    # In future, retrieving a value by indexing into a RoleValues array will do the same thing.
    #
    class RoleProxy < SimpleDelegator
      def initialize(role, o = nil)     #:nodoc:
        @role = role                    # REVISIT: Use this to implement verbalise()
        __setobj__(o)
      end

      def method_missing(m, *a, &b)     #:nodoc:
        begin
          super                         # Delegate first
        rescue NoMethodError => e
          __getobj__.method_missing(m, *a, &b)
        rescue => e
          raise
        end
      end

      def class                         #:nodoc:
        __getobj__.class
      end

      def is_a? klass                   #:nodoc:
        __getobj__.is_a? klass
      end

      def to_s                          #:nodoc:
        __getobj__.to_s
      end

      # This is strongly deprecated, and omitting it doesn't seem to hurt:
      #def object_id                     #:nodoc:
      #  __getobj__.object_id
      #end

      # REVISIT: Should Proxies hash and eql? the same as their wards?
      def hash                          #:nodoc:
        __getobj__.hash ^ self.class.hash
      end

      def eql?(o)                       #:nodoc:
        self.class == o.class and __getobj__.eql?(o)
      end

      def ==(o)                         #:nodoc:
        __getobj__.==(o)
      end

      def inspect                       #:nodoc:
        "Proxy:#{__getobj__.inspect}"
      end
    end
  end
end
