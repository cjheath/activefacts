module ActiveFacts
  class Constellation
    attr_reader :vocabulary
    attr_reader :query
    attr_reader :instances	# Can say c.instances[MyClass].each{|k, v| ... }
				# REVISIT: Protect instances from modification?

    def initialize(vocabulary, query = nil)
      @vocabulary = vocabulary
      @query = query
      @instances = Hash.new{|h,k| h[k] = {} }
    end

    def method_missing(m, *args)
      if c = @vocabulary.const_get(m)
	# REVISIT: create the constructor method here instead?

	# If the same object already exists in this constellation, re-use it.
	key = args.size > 1 ? args : args[0]
	unless instance = @instances[c][key]
	  instance = c.send :new, *args
	  instance.constellation = self
	  # Register the new object in the hash of similar instances
	  @instances[c][key] = instance
	end
	instance
      end
    end
  end
end

