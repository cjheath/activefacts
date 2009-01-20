#
# The ActiveFacts Runtime API Constellation class
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  module API
    class InstanceIndex
      def []=(key, val)
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

      def delete_if(&b)
        h.delete_if &b
      end

      def values
        h.values
      end

      def keys
        h.keys
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
