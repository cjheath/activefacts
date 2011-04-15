#
#       ActiveFacts Runtime API
#       InstanceIndex class
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module API
    #
    # Each Constellation maintains an InstanceIndex for each ObjectType in its Vocabulary.
    # The InstanceIndex object is returned when you call @constellation.ObjectType with no
    # arguments (where ObjectType is the object_type name you're interested in)
    #
    class InstanceIndex
      def []=(key, value)   #:nodoc:
        h[key] = value
      end

      def [](*args)
        h[*args]
      end

      def size
        h.size
      end

      def empty?
        h.size == 0
      end

      def each &b
        h.each &b
      end

      def map &b
        h.map &b
      end

      def detect &b
        r = h.detect &b
        r ? r[1] : nil
      end

      # Return an array of all the instances of this object_type
      def values
        h.values
      end

      # Return an array of the identifying role values arrays for all the instances of this object_type
      def keys
        h.keys
      end

      def delete_if(&b)   #:nodoc:
        h.delete_if &b
      end

    private
      def h
        @hash ||= {}
      end

      def naked(o)
        case o
        when Array
          o.map{|e| naked(e) }
        else
          o
        end
      end
    end
  end
end
