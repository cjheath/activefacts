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
        camel = name.to_s.camelcase(true)
        if (c = @concept[camel])
          __bind(camel)
          return c
        end
        return (const_get(camel) rescue nil)
      end

      def add_concept(klass)  #:nodoc:
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
        if (@delayed && @delayed.include?(concept_name))
          # $stderr.puts "#{concept_name} was delayed, binding now"
          d = @delayed[concept_name]
          d.each{|(a,b)|
              b.call(concept, *a)
            }
          @delayed.delete(concept_name)
        end
      end

      def verbalise
        "Vocabulary #{name}:\n\t" +
          @concept.keys.sort.map{|concept|
              c = @concept[concept]
              __bind(c.basename)
              c.verbalise + "\n\t\t// Roles played: " + c.roles.verbalise
            }*"\n\t"
      end

=begin
      # Create or find an instance of klass in constellation using value to identify it
      def adopt(klass, constellation, value)  #:nodoc:
        puts "Adopting #{ value.verbalise rescue value.class.to_s+' '+value.inspect} as #{klass} into constellation #{constellation.object_id}"

        path = "unknown"
        # Create a value instance we can hack if the value isn't already in this constellation
        if (c = constellation)
          if value.is_a?(klass)            # Right class?
            value = value.__getobj__ if RoleProxy === value
            vc = value.constellation rescue nil
            if (c == vc)                # Right constellation?
              # Already right class, in the right constellation
              path = "right constellation, right class, just use it"
            else
              # We need a new object from our constellation, so copy the value.
              if klass.is_entity_type
                # Make a new entity having only the identifying roles set.
                # Someone will complain that this is wrong, and all functional role values should also
                # be cloned, and I'm listening... but not there yet. Why just those?
                cloned = c.send(
                    :"#{klass.basename}",
                    *klass.identifying_role_names.map{|role| value.send(role) }
                  )
                path = "wrong constellation, right class, cloned entity"
              else
                # Just copy a value:
                cloned = c.send(:"#{klass.basename}", *value)
                path = "wrong constellation, right class, copied value"
              end
              value.constellation = c
            end
          else
            # Wrong class, assume it's a valid constructor arg. Get our constellation to find/make it:
            value = [ value ] unless Array === value
            value = c.send(:"#{klass.basename}", *value)
            path = "right constellation but wrong class, constructed from args"
          end
        else
          # This object's not in a constellation
          if value.is_a?(klass)            # Right class?
            value = value.__getobj__ if RoleProxy === value
            if vc = value.constellation rescue nil
              raise "REVISIT: Assigning to #{self.class.basename}.#{role_name} with constellation=#{c.inspect}: Can't dis-associate object from its constellation #{vc.object_id} yet"
            end
            # Right class, no constellation, just use it
            path = "no constellation, correct class"
          else
            # Wrong class, construct one
            value = klass.send(:new, *value)
            path = "no constellation, constructed from wrong class"
          end
        end
        # print "#{path}"; puts ", adopted as #{value.verbalise rescue value.inspect}"
        value
      end
=end

    end
  end
end
