module ActiveFacts
  module Vocabulary; end

  module Concept
    N = 1.0/0	    # Infinity, useful as a cardinality end marker (0..N)

    # Verbalise this concept
    def verbalise
      # This method should always be overridden in subclasses
      raise "REVISIT: #{self} Concept verbalisation needed here"
    end

    def vocabulary
      modspace	# The module that contains this concept.
    end

    # Each Concept maintains a list of the Roles it plays:
    def roles(name = nil)
      @roles ||= {}
      def @roles.verbalise
	keys.sort_by(&:to_s).inspect
      end
      case name
      when nil
	@roles
      when Numeric
	raise "Can't index roles by number"
      when Symbol, String
	r = @roles[name.to_sym]
	r.resolve_player(vocabulary) if Symbol === (player = r.player)
	r
      else
	nil
      end
    end

    # REVISIT: Should this be called fact, or fact_type, or binary_fact_type?
    def role(*args)
      role_name, related, mandatory, one_to_one, related_role_name, reading =
	role_params(args)

      puts "#{self}.#{role_name} is to #{related.inspect}, #{mandatory ? :mandatory : :optional}, related role is #{related_role_name}, reading=#{reading.inspect}"

      single(role_name, related, related_role_name, one_to_one)

      when_bound(related, self, role_name, related_role_name) do |target, definer, role_name, related_role_name|
	if (one_to_one)
	  target.single(related_role_name, definer, role_name, one_to_one)
	else
	  target.multiple(related_role_name, definer, role_name)
	end
      end
    end

    # An objectified fact type supports readings, which may contain:
    # "/", separating multiple alternate readings
    # ":concept", indicating that the Concept plays this role
    def reading(*args)
      puts "#{self.inspect}#reading: #{args.inspect}"
    end

    # Define accessor methods for this role name, which should be assigned an object of the indicated class
    def single(role_name, klass, related_role_name, one_to_one = false)
      raise "not sym" unless Symbol === role_name
      roles[role_name] = Role.new(klass, role_name)

      puts "Defining #{basename}.#{role_name} to #{klass.basename} (#{one_to_one ? "assigning" : "populating"} #{related_role_name})"
      class_def "#{role_name}=" do |value|
	#puts "Assigning #{self}.#{role_name} to #{value}, value will be added/assigned to #{related_role_name}"

	# Find what class the value should be:
	klass = self.class.roles(role_name).resolve_player(self.class.vocabulary)
	raise "Role #{role_name} does not resolve to any existing class (found #{klass.inspect} in #{roles.map{|r|r.name}.inspect})" unless Class === klass

	# Create a value instance we can hack if the value isn't already in this constellation
	if klass === value
	  if ((c = constellation) && c != value.constellation)
	    REVISIT
	    # value = c.adopt(value)
	  end
	else
	  value = (c = constellation) ? c.send(:"#{klass.basename}", *value) : value
	end
	instance_variable_set("@#{role_name}", value)
      end

      class_def role_name do
	# REVISIT: Return a FactProxy instead?
	instance_variable_get("@#{role_name}")
      end
    end

    def multiple(role_name, klass, single_role_name)
      raise "not sym" unless Symbol === role_name
      roles[role_name] = Role.new(klass, role_name)

      puts "Defining #{basename}.#{role_name} to array of #{klass.basename} (via #{single_role_name})"
      class_def "#{role_name}" do
	puts "REVISIT: Access to array of #{klass.to_s} from #{role_name}, matching single role is #{single_role_name}"
      end
    end


    private

    # Extract the parameters to a role definition and massage them into the right shape.
    #
    # This function returns an array:
    # [ role_name,
    #	related,
    #	mandatory,
    #	one_to_one,
    #	related_role_name,
    #	reading ]
    #
    # Role naming rule:
    #   "all_" if there may be more than one (only ever on related end)
    #   Role Name:
    #	If a role name is defined at this end:
    #	  Role Name
    #	else:
    #	  Leading Adjective
    #	  Role player name (not role name)
    #	  Trailing Adjective
    # "_by_<other_role_name>" if other_role_name != this role player's name, and not other_player_this_player
    def role_params(args)
      # Params:
      #   role_name (Symbol)
      #   other player (Symbol or Class)
      #   mandatory (:mandatory)
      #   0/1/N on other end
      #   other end role name if any (Symbol),
      #   reading
      role_name = nil
      related = nil
      mandatory = false
      one_to_one = false
      related_role_name = nil
      role_player = self.basename.snakecase

      # Get the role name first:
      case a = args.shift
      when Symbol, String
	role_name = a.to_sym
      when Class
	role_name = a.name.snakecase.to_sym
      else
	raise "Illegal first parameter to role: #{a.inspect}"
      end
      # puts "role_name = #{role_name.inspect}"

      # The related class might be forward-referenced, so handle a Symbol instead of a Class.
      unless related
	case related_name = a = args.shift
	when Class
	  related = a
	  related_name = a.basename
	when :mandatory
	  args.unshift(a)
	  related_name =
	  related = role_name
	when Symbol
	  related = a
	else
	  related = role_name
	end
      end
      related_name ||= role_name
      related_name = related_name.to_s.snakecase

      # resolve the Symbol to a Class now if possible:
      related = vocabulary.concept(related) if Symbol === related
      # puts "related = #{related.inspect}"

      if args[0] == :mandatory
	mandatory = true
	args.shift
      end

      if Numeric === args[0] && args[0] == 1
	one_to_one = true
	args.shift
      end

      if Symbol == args[0]
	related_role_name = args.shift
      end

      reading = args[0]

      # Avoid a confusing mismatch:
      # Note that if you have a role "supervisor" and a sub-class "Supervisor", this'll bitch.
      if (Class === related && (indicated = vocabulary.concept(role_name)) && indicated != related)
	raise "Role name #{role_name} indicates a different player #{indicated} than specified"
      end

      # puts "Calculating related method name for related_role_name=#{related_role_name.inspect}, related_name=#{related_name.inspect}, role_player=#{role_player.inspect}, role_name=#{role_name.inspect}:"

      related_role_name ||= (role_player || "")  # REVISIT: Add adjectives here
      unless one_to_one
	related_role_name = "all_#{role_player}" +
	  if related_name == role_name.to_s || role_name.to_s == "#{role_player}_#{related_name}"
	    ""
#	  elsif related_role_name == ""
#	    puts "Skipping _by_, related_role_name is empty"
#	    ""
#	  elsif role_name.to_s == related_role_name
#	    puts "Skipping _by_, role_name matches related_name"
#	    ""
#	  elsif related_role_name == "#{role_name}_#{related_name}"
#	    puts "Skipping _by_, related_role_name matches role_name_related_name"
#	    ""
	  else
	    "_by_#{role_name}"
	  end
      end

      [ role_name,
	related,
	mandatory,
	one_to_one,
	related_role_name.to_sym,
	reading
      ]

=begin
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
=end
    end
    def inherited(other)
      puts "REVISIT: Concept type #{self} was inherited by #{other}"
    end

    class Role
      attr_accessor :name
      attr_accessor :player		# May be a Symbol, which will be converted to a Class/Concept
      attr_accessor :value_restriction

      def initialize(player, name)
	@player = player
	@name = name
      end

      def resolve_player(vocabulary)
	return @player if Class === @player	# Done already
	klass = vocabulary.concept(@player)
	@player = klass if klass
	@player
      end
    end

    private

    def when_bound(concept, *args, &block)
      case concept
      when Class
	block.call(concept, *args)	# Execute block in the context of the concept
      when Symbol, String	# Arrange for this to happen later
	vocabulary.__delay(concept.to_sym, args, block)
      else
	raise "Delayed binding not possible for #{concept.inspect}"
      end
    end
  end
end
