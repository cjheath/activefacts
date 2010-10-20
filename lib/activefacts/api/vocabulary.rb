#
#       ActiveFacts Runtime API
#       Vocabulary module (mixin for any Module that contains classes having ObjectType mixed in)
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# The methods of this module are extended into any module that contains
# a ObjectType class (Entity type or Value type).
#
module ActiveFacts
  module API
    # Vocabulary is a mixin that adds methods to any Module which has any ObjectType classes (ValueType or EntityType).
    # A Vocabulary knows all the ObjectType classes including forward-referenced ones,
    # and can resolve the forward references when the class is finally defined.
    # Construction of a Constellation requires a Vocabuary as argument.
    module Vocabulary
      # With a parameter, look up a object_type class by name.
      # Without, return the hash (keyed by the class' basename) of all object_types in this vocabulary
      def object_type(name = nil)
        @object_type ||= {}
        return @object_type unless name

        return name if name.is_a? Class

        # puts "Looking up object_type #{name} in #{self.name}"
        camel = name.to_s.camelcase
        if (c = @object_type[camel])
          __bind(camel)
          return c
        end
        return (const_get("#{name}::#{camel}") rescue nil)
      end

      # Create a new constellation over this vocabulary
      def constellation
        Constellation.new(self)
      end

      def populate &b
        constellation.populate &b
      end

      def verbalise
        "Vocabulary #{name}:\n\t" +
          @object_type.keys.sort.map{|object_type|
              c = @object_type[object_type]
              __bind(c.basename)
              c.verbalise + "\n\t\t// Roles played: " + c.roles.verbalise
            }*"\n\t"
      end

      def __add_object_type(klass)  #:nodoc:
        name = klass.basename
        __bind(name)
        # puts "Adding object_type #{name} to #{self.name}"
        @object_type ||= {}
        @object_type[klass.basename] = klass
      end

      def __delay(object_type_name, args, &block) #:nodoc:
        # puts "Arranging for delayed binding on #{object_type_name.inspect}"
        @delayed ||= Hash.new { |h,k| h[k] = [] }
        @delayed[object_type_name] << [args, block]
      end

      # __bind raises an error if the named class doesn't exist yet.
      def __bind(object_type_name)  #:nodoc:
        object_type = const_get(object_type_name)
        # puts "#{name}.__bind #{object_type_name} -> #{object_type.name}" if object_type
        if (@delayed && @delayed.include?(object_type_name))
          # $stderr.puts "#{object_type_name} was delayed, binding now"
          d = @delayed[object_type_name]
          d.each{|(a,b)|
              b.call(object_type, *a)
            }
          @delayed.delete(object_type_name)
        end
      end

    end
  end
end
