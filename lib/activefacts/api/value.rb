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
      end

      def Value.included other
        other.send :extend, ClassMethods

        # Register ourselves with the parent module, which has become a Vocabulary:
        vocabulary = other.modspace
        unless vocabulary.respond_to? :concept
          vocabulary.send :extend, Vocabulary
        end
        vocabulary.add_concept(other)
      end
    end
  end
end
