module ActiveFacts
  module API
    module Vocabulary
      def concept(name = nil)
	@concept ||= {}
	return @concept unless name
	camel = name.to_s.camelcase(true)
	if (c = @concept[camel])
	  return c
	end
	begin
	  return const_get(camel)
	rescue
	  return nil
	end
      end

      def __delay(concept_sym, args, &block)
	# puts "Arranging for delayed binding on #{concept_sym}"
	@delayed ||= Hash.new { |h,k| h[k] = [] }
	@delayed[concept_sym] << [args, block]
      end

      def verbalise
	"Vocabulary #{name}:\n\t" +
	  @concept.keys.sort.map{|concept|
	      c = @concept[concept]
	      c.verbalise + "\n\t\t// Roles played: " + c.roles.verbalise
	    }*"\n\t"
      end

      # Create or find an instance of klass in constellation using value to identify it
      def adopt(klass, constellation, value)
	# puts "Adopting #{value.inspect} as #{klass} in #{constellation.object_id}"
	# Create a value instance we can hack if the value isn't already in this constellation
	if (c = constellation)
	  if klass === value		# Right class?
	    vc = value.respond_to?(:constellation) && value.constellation
	    if (c != vc)		# Wrong constellation?
	      # The new object *must* come from our constellation, because it might already exist there.
	      raise "REVISIT: Can't clone objects from outside this constellation yet"
	      value.constellation = c
	    else
	      # Already right class, in the right cnstellation
	    end
	  else
	    # Wrong class, assume it's a valid constructor arg. Get our constellation to find/make it:
	    value = c.send(:"#{klass.basename}", *value)
	  end
	else
	  # This object's not in a constellation
	  if klass === value		# Right class?
	    vc = value.respond_to?(:constellation) && value.constellation
	    if vc
	      raise "REVISIT: Assigning to #{self.class.basename}.#{role_name} with constellation=#{c.inspect}: Can't dis-associate object from its constellation #{vc.object_id} yet"
	    end
	    # Right class, no constellation, just use it
	  else
	    # Wrong class, construct one
	    value = klass.send(:new, *value)
	  end
	end
	# puts "Adopted as #{value.inspect}"
	value
      end

    end
  end
end
