module ActiveFacts
  module Vocabulary; end

  module Concept
    # Verbalise this concept
    def verbalise
      # This method should always be overridden in subclasses
      raise "REVISIT: #{self} Concept verbalisation needed here"
    end

    def vocabulary
      modspace	# The module that contains this concept.
    end

    # Each Concept maintains a list of the names of roles it plays:
    def role(number = nil)
      @roles ||= []
      number ? @roles[number] : @roles
    end

    # When a Concept plays a certain role at most once, single() is used:
    def single(*args)
      role_name = args.shift.to_s
      role << role_name.to_sym

      # The related class might be forward-referenced, so handle a Symbol instead of a Class.
      related = args.detect{|a| Class === a || Symbol === a }

      #puts "looking for adjectives for #{related.to_s} in #{role_name}" if related

      # Detect adjectives in the role_name
      if (related && (related_name = related.basename).length != role_name.to_s.length)
	if role_name[-related_name.length..-1].downcase == related_name.downcase
	  # role_name has related_name as a suffix
	  leading_adjective = role_name[0..-related_name.length-1]
	  leading_adjective.chop! if leading_adjective[-1,1] == "_"
	  puts "REVISIT: Role #{role_name} is #{leading_adjective}-#{related_name}; store adjectives"
	elsif role_name[0, related_name.length]
	  trailing_adjective = role_name[related_name.length..-1]
	  trailing_adjective.shift if trailing_adjective[0,1] == '_'
	  puts "REVISIT: Role #{role_name} is #{related_name}-#{trailing_adjective}; store adjectives"
	elsif (role_name.downcase != related_name.downcase)
	  if @vocabulary.concept[role_name.camelcase(true)]
	    raise "Role name #{role_name} may be name of existing concept unless that concept plays that role"
	  end
	end
      end

      related ||= role_name

      #reading = args.detect{|a| String === a } || ":#{self.class} has :#{role_name.to_s.camelcase(true)}"

      # Define accessor methods on the class:
      class_def "#{role_name}=" do |value|
	# REVISIT: Modify the fact population on this constellation
	#puts "Assigning #{self}.#{role_name} to #{value}"
	instance_variable_set("@#{role_name}", value)
      end

      class_def role_name do
	# REVISIT: Return a FactProxy instead?
	instance_variable_get("@#{role_name}")
      end
    end

    # When a Concept may play a certain role more than once, multi() is used:
    def multi(*args)
      role_name = args[0]
      role << role_name.to_sym

      puts "#{self.inspect}#multi: #{args.inspect}"
    end

    # An objectified fact type supports readings, which may contain:
    # "/", separating multiple alternate readings
    # ":concept", indicating that the Concept plays this role
    def reading(*args)
      puts "#{self.inspect}#reading: #{args.inspect}"
    end
  end
end
