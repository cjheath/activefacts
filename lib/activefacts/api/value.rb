#
#       ActiveFacts Runtime API
#       Value module (mixins for ValueType classes and instances)
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# The methods of this module are added to Value type classes.
#
module ActiveFacts
  module API

    # All Value instances include the methods defined here
    module Value
      include Instance

      # Value instance methods:
      def initialize(*args) #:nodoc:
        args[0] = args[0].__getobj__ if RoleProxy === args[0]
        super(args)
      end

      # verbalise this Value
      def verbalise(role_name = nil)
        "#{role_name || self.class.basename} '#{to_s}'"
      end

      # A value is its own key
      def identifying_role_values #:nodoc:
        self
      end

      # All ValueType classes include the methods defined here
      module ClassMethods
        include Instance::ClassMethods

        def initialise_value_type *args, &block #:nodoc:
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

        class_eval do
          define_method :restrict do |*value_ranges|
            @value_ranges = *value_ranges
          end
        end

        # verbalise this ValueType
        def verbalise
          # REVISIT: Add length and scale here, if set
          # REVISIT: Set vocabulary name of superclass if not same as this
          "#{basename} = #{superclass.basename}();"
        end

        def identifying_role_values(*args)  #:nodoc:
          # If the single arg is the correct class or a subclass, use it directly
          #puts "#{basename}.identifying_role_values#{args.inspect}"
          if (args.size == 1 and (arg = args[0]).is_a?(self.class))   # No secondary supertypes allowed for value types
            arg = arg.__getobj__ if RoleProxy === arg
            return arg
          end
          new(*args)
        end

        def assert_instance(constellation, args)  #:nodoc:
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

          instance.constellation = constellation
          return *index_instance(instance)
        end

        def index_instance(instance, key = nil) #:nodoc:
          instances = instance.constellation.instances[self]
          key = instance.identifying_role_values
          instances[key] = instance
          # DEBUG: puts "indexing value #{basename} using #{key.inspect} in #{constellation.object_id}"

          # Index the instance for each supertype:
          supertypes.each do |supertype|
            supertype.index_instance(instance, key)
          end

          return instance, key
        end

        def inherited(other)  #:nodoc:
          #puts "REVISIT: ValueType #{self} < #{self.superclass} was inherited by #{other}; not implemented" #+"from #{caller*"\n\t"}"
          # Copy the type parameters here, etc?
          other.send :realise_supertypes, self
          vocabulary.__add_object_type(other)
          super
        end
      end

      def self.included other #:nodoc:
        other.send :extend, ClassMethods

        #puts "ValueType included in #{other.basename} from #{caller*"\n\t"}"

        # Register ourselves with the parent module, which has become a Vocabulary:
        vocabulary = other.modspace
        # puts "ValueType.included(#{other.inspect})"
        unless vocabulary.respond_to? :object_type  # Extend module with Vocabulary if necessary
          vocabulary.send :extend, Vocabulary
        end
        vocabulary.__add_object_type(other)
      end
    end
  end
end
