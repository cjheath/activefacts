module ActiveFacts
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

      class_def :length do |*args|
	@length = args[0] if args.length > 0
	@length
      end

      class_def :scale do |*args|
	@scale = args[0] if args.length > 0
	@scale
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
      vocabulary.concept[other.basename] = other
    end
  end
end
