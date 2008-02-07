module ActiveFacts
  module Entity
    include Instance

    # Entity instance methods:
    # REVISIT

    # verbalise this Value
    def verbalise
      "#{self.class.basename}(REVISIT: use role values: #{self.class.identifying_roles*", "})"
    end

    module ClassMethods
      include Instance::ClassMethods

      # Entity class methods:
      def identifying_roles
	@identifying_roles ||= []
      end

      # A concept that isn't a ValueType must have an identification scheme,
      # which is a list of roles it plays:
      def known_by(*args)
	# REVISIT: Process the role names passed now, or later if necessary
	@identifying_roles = args
	args.each{|role|
	  if concept = vocabulary.concept[role.to_s.camelcase(true)]
	    #REVISIT: puts "#{role} identifies existing concept #{concept.name}, good"
	  else
	    #REVISIT: puts "#{role} identifies no existing concept"
	  end
	}

	# puts "#{self.inspect}#known_by: #{args.inspect}"
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
