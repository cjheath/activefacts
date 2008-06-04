#
# The ActiveFacts Runtime API Value extension module
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
# The methods of this module are added to Value type classes.
#
module ActiveFacts
  module API
    module Value
      include Instance

      # Value instance methods:
      def initialize(*args)
        super(args)
      end

      # verbalise this Value
      def verbalise(role_name = nil)
        "#{role_name || self.class.basename} '#{to_s}'"
      end

      # A value is its own key
      def identifying_role_values
        self
      end

      module ClassMethods
        include Instance::ClassMethods

        def initialise_value_type *args, &block
          # REVISIT: args could be a hash, with keys :length, :scale, :unit, :allow
          #raise "value_type args unexpected" if args.size > 0
        end

        class_eval do
          define_method :length do |*args|
            @length = args[0] if args.length > 0
            @length
          end
        end

        class_eval do
          define_method :scale do |*args|
            @scale = args[0] if args.length > 0
            @scale
          end
        end

        # verbalise this ValueType
        def verbalise
          # REVISIT: Add length and scale here, if set
          "#{basename} = #{superclass.name}();"
        end

        def identifying_role_values(*args)
          # If the single arg is the correct class or a subclass, use it directly
          #puts "#{basename}.identifying_role_values#{args.inspect}"
          return args[0] if (args.size == 1 and self.class === args[0])   # No secondary supertypes allowed for value types
          new(*args)
        end

        def assert_instance(constellation, args)
          # Build the key for this instance from the args
          # The key of an instance is the value or array of keys of the identifying values.
          # The key values aren't necessarily present in the constellation, even after this.
          key = identifying_role_values(*args)
          #puts "#{klass} key is #{key.inspect}"

          # Find and return an existing instance matching this key
          instances = constellation.instances[self]   # All instances of this class in this constellation
          instance = instances[key]
          # DEBUG: puts "assert #{self.basename} #{key.inspect} #{instance ? "exists" : "new"}"
          return instance, key if instance      # A matching instance of this class

          instance = new(*args)
          key = instance.identifying_role_values
          # REVISIT: Replace with proper indexing:
          instance.constellation = constellation
          # DEBUG: puts "indexing value #{instance.class.basename} on #{key.inspect}" if key == :new or key == [:new] or key == [[:new]]
          instances[key] = instance
          return instance, key
        end

        def inherited(other)
          #puts "REVISIT: ValueType #{self} < #{self.superclass} was inherited by #{other}; not implemented" #+"from #{caller*"\n\t"}"
          # Copy the type parameters here, etc?
          other.send :realise_supertypes, self
          vocabulary.add_concept(other)
          super
        end
      end

      def self.included other
        other.send :extend, ClassMethods

        #puts "ValueType included in #{other.basename} from #{caller*"\n\t"}"

        # Register ourselves with the parent module, which has become a Vocabulary:
        vocabulary = other.modspace
        unless vocabulary.respond_to? :concept  # Extend module with Vocabulary if necessary
          vocabulary.send :extend, Vocabulary
        end
        vocabulary.add_concept(other)
      end
    end
  end
end
