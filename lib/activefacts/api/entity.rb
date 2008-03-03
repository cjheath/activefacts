module ActiveFacts
  module API
    module Entity
      include Instance

      # Entity instance methods:

      def initialize(*args)
	super(args)
	raise "Wrong number of parameters to #{self.class}.new, " +
	    "expect (#{self.class.identifying_roles*","}) " +
	    "got (#{args.map{|a| a.to_s.inspect}*", "})" if args.size != self.class.identifying_roles.size

	# Assign the identifying roles in order
	self.class.identifying_roles.zip(args).each{|pair|
	    role, value = *pair
	    send("#{role}=", value)
	  }
      end

      # verbalise this entity
      def verbalise(role_name = nil)
	# REVISIT: Should be able to pass role name to role.verbalise here:
	"#{role_name || self.class.basename}(#{self.class.identifying_roles.map{|r| send(r).verbalise(r.to_s.camelcase(true)) }*", "})"
      end

      module ClassMethods
	include Instance::ClassMethods

	# Entity class methods:
	def identifying_roles
	  @identifying_roles ||= []
	end

	# A concept that isn't a ValueType must have an identification scheme,
	# which is a list of roles it plays. The identification scheme may be
	# inherited from a superclass.
	def initialise_entity_type(*args)
	  # puts "Initialising entity type #{self}"
	  @identifying_roles = superclass.identifying_roles if superclass.respond_to?(:identifying_roles)
	  @identifying_roles = args if args.size > 0 || !@identifying_roles
=begin
	  # REVISIT: Is any processing of the role names needed here?
	  args.each{|role|
	    if concept = vocabulary.concept[role.to_s.camelcase(true)]
	      #REVISIT: puts "#{role} identifies existing concept #{concept.name}, good"
	    else
	      #REVISIT: puts "#{role} identifies no existing concept"
	    end
	  }
=end
	end

	def inherited(other)
	  other.entity_type #identifying_roles
	end

	# verbalise this concept
	def verbalise
	  "#{basename} = entity type known by #{identifying_roles.map{|r| r.to_s.camelcase(true)}*" and "};"
	end
      end

      def Entity.included other
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
end
