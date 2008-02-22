module ActiveFacts
  module Instance
    # Instance methods:
    def initialize(args = [])
      if Constellation === (c = args[0])
	# puts "Making #{self.class.basename} with #{args.size} params, first is Constellation"
	self.constellation = c
	args.shift
      end

      super(*args) if (self.class.superclass != Object)
    end

    # Verbalise this instance
    def verbalise
      # This method should always be overridden in subclasses
      raise "REVISIT: #{self.class} Instance verbalisation needed"
    end

    attr_accessor :query
    attr_accessor :constellation

    module ClassMethods
      include Concept
      # REVISIT: Add Instance class methods here
    end

    def Instance.included other
      other.send :extend, ClassMethods
    end
  end
end
