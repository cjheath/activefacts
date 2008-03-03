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
      if klass = @vocabulary.const_get(m)
	if args.size == 0
	  @instances[klass].values
	else
	  # REVISIT: create the constructor method here instead?

	  # If the same object already exists in this constellation, re-use it.
	  key = args.size > 1 ? args : args[0]
	  instance = @instances[klass][key]
	  # puts "Looked for #{klass} using #{key.inspect}, found #{instance.inspect}"
	  unless instance
	    #puts "Making new #{klass}(#{args.map(&:inspect)*", "})"
	    args = [self]+args unless klass.respond_to?(:__Is_A_Date)
	    begin
	      instance = klass.send :new, *args
	    rescue ArgumentError => e
	      raise "Can't instantiate #{klass} using #{args.map(&:class)*", "}: #{e}"
	    end

	    # Register the new object in the hash of similar instances
	    # print "Adding new instance #{instance.inspect} by #{key.inspect}"
	    instance.constellation = self
	    @instances[klass][key] = instance
	  end
	  instance
	end
      end
    end

    # Constellations verbalise all members of all classes in alphabetical order, showing non-identifying roles as well
    def verbalise
      "Constellation over #{vocabulary.name}:\n" +
      vocabulary.concept.keys.sort.map{|concept|
	  klass = vocabulary.const_get(concept)

	  # REVISIT: It would be better not to rely on the role name pattern here:
	  single_roles, multiple_roles = klass.roles.keys.sort_by(&:to_s).partition{|r| r.to_s !~ /\Aall_/ }
	  single_roles -= klass.identifying_roles if (klass.respond_to?(:identifying_roles))

	  "\tEvery #{concept}:\n" +
	    send(concept.to_sym).map{|instance|
		s = "\t\t" + instance.verbalise
		if (single_roles.size > 0)
		  s += ": " +
		    single_roles.map{|r|
			value = instance.send(r)
			"#{r} = #{value ? value.verbalise : "nil"}"
		      }*", "
		end
		s
	      } * "\n"
	}*"\n"
    end
  end
end
