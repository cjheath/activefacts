module ActiveFacts
  class Constellation
    attr_reader :vocabulary
    attr_reader :query
    attr_reader :instances	# Can say c.instances[MyClass].each{|k, v| ... }
				# REVISIT: Protect instances from modification?
    #attr_reader :session	# REVISIT: add persistence support
    #attr_reader :transaction	# REVISIT: add persistence support
    #def save; ... end		# REVISIT: add persistence support
    #def digest; ... end	# REVISIT: add digest capability
    #def validate_internal; ... end	# REVISIT: add constraints

    def initialize(vocabulary, query = nil)
      @vocabulary = vocabulary
      @query = query
      @instances = Hash.new{|h,k| h[k] = {} }
    end

    def method_missing(m, *args)
      if c = @vocabulary.const_get(m)
	if args.size == 0
	  @instances[c].values
	else
	  # REVISIT: create the constructor method here instead?

	  # If the same object already exists in this constellation, re-use it.
	  key = args.size > 1 ? args : args[0]
	  unless instance = @instances[c][key]
	    instance = c.send :new, self, *args
	    # Register the new object in the hash of similar instances
	    #print "Adding new instance "; p instance
	    instance.constellation = self
	    @instances[c][key] = instance
	  end
	  instance
	end
      end
    end
  end
end

