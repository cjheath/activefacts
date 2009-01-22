#
#       ActiveFacts Runtime API
#       InstanceIndex class
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module API
    #
    # Each Constellation maintains an InstanceIndex for each Concept in its Vocabulary.
    # The InstanceIndex object is returned when you call @constellation.Concept with no
    # arguments (where Concept is the concept name you're interested in)
    #
    class InstanceIndex
      def []=(key, val)   #:nodoc:
        if RoleProxy === val
          debugger
        end
        h[key] = val
      end

      def [](*args)
        a = args
        #a = naked(args)
#        p "vvvv",
#          args,
#          a,
#          keys.map{|k| v=super(k); (RoleProxy === k ? "*" : "")+k.to_s+"=>"+(RoleProxy === v ? "*" : "")+v.to_s}*",",
#          "^^^^"
        h[*a]
        #super(*a)
      end

      def size
        h.size
      end

      def map &b
        h.map &b
      end

      # Return an array of all the instances of this concept
      def values
        h.values
      end

      # Return an array of the identifying role values arrays for all the instances of this concept
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
        when RoleProxy
          o.__getobj__
        else
          o
        end
      end
    end
  end
end
