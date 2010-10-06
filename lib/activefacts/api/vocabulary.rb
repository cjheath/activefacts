#
#       ActiveFacts Runtime API
#       Vocabulary module (mixin for any Module that contains classes having Concept mixed in)
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# The methods of this module are extended into any module that contains
# a Concept class (Entity type or Value type).
#
module ActiveFacts
  module API
    # Vocabulary is a mixin that adds methods to any Module which has any Concept classes (ValueType or EntityType).
    # A Vocabulary knows all the Concept classes including forward-referenced ones,
    # and can resolve the forward references when the class is finally defined.
    # Construction of a Constellation requires a Vocabuary as argument.
    module Vocabulary
      # With a parameter, look up a concept class by name.
      # Without, return the hash (keyed by the class' basename) of all concepts in this vocabulary
      def concept(name = nil)
        @concept ||= {}
        return @concept unless name

        return name if name.is_a? Class

        # puts "Looking up concept #{name} in #{self.name}"
        camel = name.to_s.camelcase
        if (c = @concept[camel])
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
          @concept.keys.sort.map{|concept|
              c = @concept[concept]
              __bind(c.basename)
              c.verbalise + "\n\t\t// Roles played: " + c.roles.verbalise
            }*"\n\t"
      end

      def __add_concept(klass)  #:nodoc:
        name = klass.basename
        __bind(name)
        # puts "Adding concept #{name} to #{self.name}"
        @concept ||= {}
        @concept[klass.basename] = klass
      end

      def __delay(concept_name, args, &block) #:nodoc:
        # puts "Arranging for delayed binding on #{concept_name.inspect}"
        @delayed ||= Hash.new { |h,k| h[k] = [] }
        @delayed[concept_name] << [args, block]
      end

      # __bind raises an error if the named class doesn't exist yet.
      def __bind(concept_name)  #:nodoc:
        concept = const_get(concept_name)
        # puts "#{name}.__bind #{concept_name} -> #{concept.name}" if concept
        if (@delayed && @delayed.include?(concept_name))
          # $stderr.puts "#{concept_name} was delayed, binding now"
          d = @delayed[concept_name]
          d.each{|(a,b)|
              b.call(concept, *a)
            }
          @delayed.delete(concept_name)
        end
      end

    end
  end
end
