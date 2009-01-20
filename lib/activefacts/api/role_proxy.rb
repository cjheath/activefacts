#
# The ActiveFacts Runtime API RoleProxy class; experimental
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'delegate'

module ActiveFacts
  module API
    class RoleProxy < SimpleDelegator   #:nodoc:
=begin
      def initialize(o = nil)
        __setobj__(o)
      end

      def method_missing(m, *a, &b)
        begin
          r = super   # Delegate first
          # puts "Delegating #{m} to #{__getobj__.class} worked"
          r
        rescue NoMethodError => e
          puts "Delegating #{m} to #{__getobj__.class} failed, trying its mm"
          r = __getobj__.method_missing(m, *a, &b)
          puts "#{m}#method_missing worked"
          r
        rescue => e
          puts "Delegating #{m} to #{__getobj__.class} failed with #{e.class}: #{e}"
          raise
        end
      end

      def class
        __getobj__.class
      end

      def is_a? klass
        __getobj__.is_a? klass
      end

      def to_s
        __getobj__.to_s
      end

      def hash
        __getobj__.hash ^ self.class.hash
      end

      def object_id
        __getobj__.object_id
      end

      def eql?(o)
        # self.class == o.class and self.eql?(o) || __getobj__.eql?(o)
        self.class == o.class and __getobj__.eql?(o)
      end

      def ==(o)
        __getobj__.==(o)
      end

      def inspect
        "Proxy:#{__getobj__.inspect}"
      end
=end
    end
  end
end

