#
#       ActiveFacts Runtime API
#       RoleValues, manages the set of instances involved in a many_to_one relationship.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# There are two implementations here, one using an array and one using a hash.
# The hash one has problems with keys being changed during object deletion, so
# cannot be used yet; a fix is upcoming and will improve performance of large sets.
#
module ActiveFacts
  module API

    class RoleValues  #:nodoc:
      include Enumerable

#=begin
      def initialize
        @a = []
      end

      def each &b
        # REVISIT: Provide a configuration variable to enable this heckling during testing:
        #@a.sort_by{rand}.each &b
        @a.each &b
      end

      def size
        @a.size
      end

      def empty?
        @a.size == 0
      end

      def +(a)
        @a.+(a.is_a?(RoleValues) ? Array(a) : a)
      end

      def -(a)
        @a - a
      end

      def single
        @a.size > 1 ? nil : @a[0]
      end

      def update(old, value)
        @a.delete(old) if old
        @a << value if value
        raise "Adding RoleProxy to RoleValues collection" if value && RoleProxy === value
      end

      def verbalise
        "["+@a.to_a.map{|e| e.verbalise}*", "+"]"
      end
#=end

=begin
      def initialize
        @h = {}
      end

      def each &b
        @h.keys.each &b
      end

      def size
        @h.size
      end

      def empty?
        @h.size == 0
      end

      def +(a)
        @h.keys.+(a.is_a?(RoleValues) ? Array(a) : a)
      end

      def -(a)
        @h.keys - a
      end

      def single
        @h.size > 1 ? nil : @h.keys[0]
      end

      def update(old, value)
        if old
          unless @h.delete(old)
            @h.each { |k, v|
              next if k != old
              puts "#{@h.object_id}: Didn't delete #{k.verbalise} (hash=#{k.hash}) matching #{old.verbalise} (hash=#{old.hash})"
              puts "They are #{k.eql?(old) ? "" : "not "}eql?"
              found = @h[k]
              puts "found #{found.inspect}" if found
              debugger
              x = k.eql?(old)
              y = old.eql?(k)
              p y
            }
            raise "failed to delete #{old.verbalise}, have #{map{|e| e.verbalise}.inspect}"
          end
        end
        puts "#{@h.object_id}: Adding #{value.inspect}" if value && (value.name == 'Meetingisboardmeeting' rescue false)
        @h[value] = true if value
      end

      def verbalise
        "["+@h.keys.map{|e| e.verbalise}*", "+"]"
      end
=end

    end

  end
end
