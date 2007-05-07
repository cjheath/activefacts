=begin rdoc
# Builder for ActiveFacts models; a Ruby DSL implementation
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
=end
require 'rubygems'
require 'activefacts'

class PropagatedException < Exception
    attr_accessor :original

    def initialize(original, *args)
	@original = original
	super(*args)
    end
end

module ActiveFacts
    class Builder
	attr_accessor :model

	def REVISIT(a)
	    puts "INCOMPLETE: '#{a}'"
	    nil
	end

	def initialize(*args, &block)
	    @context = []
	    @data_types = {}
	    @object_types = {}
	    @fact_types = {}
	    @delayed = []
	    eval(@model = Model.new(*args), &block)

	    while (n = @delayed.shift)
		@context = [n.shift]
		method = n.shift
		block = n.shift
		puts "Running Delayed block: #{method.inspect}"
		send(method, *n, &block)
	    end
	end

	def i
	    "\t"*@context.size
	end

	def eval(obj, &block)
	    print i
	    puts Feature === obj ? "#{obj.name} -> #{obj}" : " -> #{obj.class}"
	    @context.push(obj)
	    begin
		puts "CONTINUING contents of incomplete object" if !obj
		instance_eval(&block) if block
	    rescue PropagatedException => e
		puts "\twhile processing #{obj.class} #{Feature === obj ? obj.name : obj.class}"
		raise e
	    rescue => e
		puts "#{e.class} '#{e.exception}' at #{e.backtrace[0]}\n" +
		    "\twhile processing #{obj.class} #{Feature === obj ? obj.name : obj.class}"
		raise PropagatedException.new($!)
	    end
	    @context.pop
	end

	def entity(*args, &block)
	    puts i+"#{@context.last.class}.entity#{args.inspect}"
	    case c = @context.last
	    when Model
		name = args.shift.to_s
		entity =
		    @object_types[name] =
		    EntityType.new(@model, name)
		eval(entity, &block)
	    else
		REVISIT "Unhandled #{@context.last.class}.entity"
	    end
	end

	def value(*args, &block)
	    puts i+"#{@context.last.class}.value#{args.inspect}"
	    case c = @context.last
	    when Model
		v = make_value(args)
		eval(v, &block)
	    when EntityType
		# Extract one reading that might come first:
		reading = String === args[0] ? args.shift : nil

		v = make_value(args)

		# Process any further readings, and default:
		readings = (reading ? process_reading(reading, [c, v]) : []) +
		    extract_readings(args, c, v)
		readings << "{0} has {1}" if readings.size == 0

		fact_name = Reading.expand(readings[0], c.name, v.name).
				split(/\s+/).map{|w|
				    w[0,1].upcase+w[1..-1]
				}*""

		fact_type = make_binary_fact(fact_name, c, v)
		c_role, v_role = *fact_type.roles
		rs = RoleSequence.new([c_role, v_role])
		readings.each{|r|
		    fact_type.readings << Reading.new(r, rs)
		}

		primary = has_primary_symbol(args)
		mandatory = has_mandatory_symbol(args)
		unique = has_unique_symbol(args)

		make_simple_binary_presence_constraints(fact_type, mandatory, primary, unique)

		REVISIT "Residual args: #{args.inspect}" if args.size > 0

		# REVISIT: The context object here must include:
		# - the ValueType (for restriction etc)
		# - the entity type's PresenceConstraint (for mandatory)
		# - the FactType (for Readings)
		# - value Role (for unique)
		eval(v, &block)
	    else
		REVISIT "Unhandled #{@c.class}.value"
	    end
	end

	def binary(*args, &block)
	    puts i+"#{@context.last.class}.value#{args.inspect}"
	    case c = @context.last
	    when Model
		# A Binary Relationship between two objects given as parameters
		eval(REVISIT("Model.binary"), &block)
	    when EntityType	# A Binary Relationship from the context object to another
		# Extract one reading that might come first:
		reading = String === args[0] ? args.shift : nil

		v = find_object(args.shift)
		if Symbol === v
		    @delayed << [ c, :binary, block, *((reading ? [reading, v] : [v])+args)]
		else
		    # Process any further readings, and default:
		    readings = (reading ? process_reading(reading, [c, v]) : []) +
			extract_readings(args, c, v)
		    readings << "{0} has {1}" if readings.size == 0

		    fact_name = Reading.expand(readings[0], c.name, v.name).
				    split(/\s+/).map{|w|
					w[0,1].upcase+w[1..-1]
				    }*""
		    fact_type = make_binary_fact(fact_name, c, v)
		    c_role, v_role = *fact_type.roles
		    rs = RoleSequence.new([c_role, v_role])
		    readings.each{|r|
			fact_type.readings << Reading.new(r, rs)
		    }

		    primary = has_primary_symbol(args)
		    mandatory = has_mandatory_symbol(args)
		    unique = has_unique_symbol(args)

		    make_simple_binary_presence_constraints(fact_type, mandatory, primary, unique)

		    REVISIT "Residual args: #{args.inspect}" if args.size > 0

		    eval(REVISIT("EntityType(#{c.name}).binary"), &block)
		end
	    else
		REVISIT "Unhandled #{@context.last.class}.binary"
	    end
	end

	def ternary(*args, &block)
	    puts i+"#{@context.last.class}.ternary#{args.inspect}"
	    case c = @context.last
	    when Model
		# A ternary relationship between three objects given as parameters
		eval(REVISIT("Model.ternary"), &block)
	    when EntityType
		# A ternary relationship from the context object to two parameters
		eval(REVISIT("EntityType.ternary"), &block)
	    else
		REVISIT "Unhandled #{@context.last.class}.ternary"
	    end
	end

	def unique(*args, &block)
	    puts i+"#{@context.last.class}.unique#{args.inspect}"
	    case c = @context.last
	    when FactType
		eval(REVISIT("FactType.unique"), &block)
	    when ObjectType
		# This ObjectType must be nested inside another
		# and its role in the implied fact is unique.
		p = @context[-2].name

		REVISIT "#{c.name} is unique within its relationship to #{p.name}"
		# Need to find this object's Role within the FactType,
		# and look for an existing mandatory/primary constraint as well.
#		c_role = ...
#		PresenceConstraint.new(
#			@model,			# In Model,
#			args[0] || "#{c.name}IsOfOne#{p.name}",# this constraint
#			RoleSequence.new([c_role]),	# requires that this Role
#			false,			# default not mandatory
#			1, 1,			# occurs at most once
#			false			# Default not primary
#		    )
		eval(REVISIT("ObjectType.unique"), &block)
	    else
		REVISIT "Unhandled #{@context.last.class}.unique"
	    end
	end

	def mandatory(*args, &block)
	    puts i+"#{@context.last.class}.mandatory#{args.inspect}"
	    case c = @context.last
	    when ObjectType
		eval(REVISIT("ObjectType.mandatory"), &block)
	    else
		REVISIT "Unhandled #{@context.last.class}.mandatory"
	    end
	end

	def primary(*args, &block)
	    puts i+"#{@context.last.class}.primary#{args.inspect}"
	    case c = @context.last
	    when FactType
		eval(REVISIT("FactType.primary"), &block)
	    else
		REVISIT "Unhandled #{@context.last.class}.primary"
	    end
	end

	def restrict(*args, &block)
	    puts i+"#{@context.last.class}.restrict#{args.inspect}"
	    case c = @context.last
	    when ObjectType
		eval(REVISIT("ObjectType.restrict"), &block)
	    else
		REVISIT "Unhandled #{@context.last.class}.restrict"
	    end
	end

	def frequency(*args, &block)
	    puts i+"#{@context.last.class}.frequency#{args.inspect}"
	    case c = @context.last
	    when ObjectType
		eval(REVISIT("ObjectType.frequency"), &block)
	    else
		REVISIT "Unhandled #{@context.last.class}.frequency"
	    end
	end

	def nests(*args, &block)
	    puts i+"#{@context.last.class}.nests#{args.inspect}"
	    facttype = args.shift
	    eval(facttype, &block)
	end

	def find_object(arg)
	    case arg
	    when ObjectType
		# Do nothing, we were passed the object
	    when Symbol
		@object_types[arg.to_s] || arg
	    else
		nil	# Can't turn this into an object
	    end
	end

	def make_value(args)
	    # A new binary facttype with a unique relationship on the role of context
	    v = args.shift

	    return v if !(Symbol === (v = find_object(v)))

	    case v
	    when Symbol
		# p args
		typename = args.shift
		params = []	    # Strip off leading Integers from args:
		while args.size > 0 && Integer === args[0]; params << args.shift; end

		# Get the base type:
		if Symbol === typename
		    unless base_type = @data_types[typename.to_s]
			base_type =
			    @data_types[typename.to_s] =
			    DataType.new(@model, typename.to_s)
		    end
		end

		# Get the refined type:
		data_type_name = "#{typename}(#{params*","})"
		unless data_type = @data_types[data_type_name]
		    data_type =
			@data_types[data_type_name] =
			DataType.new(@model, base_type, data_type_name, *params)
		end

		# args may still contain :unique, "fact reading", etc, for caller

		v = ValueType.new(@model, v.to_s, data_type)
		@object_types[v.name] = v
	    else
		REVISIT "Can't construct or find Value from: #{v.class}#{args.inspect}"
	    end
	    v
	end

	def extract_readings(args, *players)
	    readings = []
	    args = args.delete_if{|a|
		next unless String === a
		process_reading(a, players)

		true
	    }
	    readings
	end

	def process_reading(a, players)
	    l, r, o = *a.split(/\W*\/\W*/)
	    raise 'Only binary fact readings may use the "has/is of" syntax' if o
	    if l && r
		[ make_reading(l, players),
		  make_reading(r, players, true) ]
	    else
		[ make_reading(a, players) ]
	    end
	end

	def make_reading(s, players, reverse = nil)
	    if s !~ /\{\d\}/
		players.each_index{|i|
		    s.gsub!(/#{players[i].name}/, "{${i}}")
		}
	    end
	    if (s !~ /\{\d\}/ && players.size == 2)
		unless reverse
		    s = "{0} #{s} {1}"
		else
		    s = "{1} #{s} {0}"
		end
	    end
	    s
	end

	def make_binary_fact(fact_name, left, right)
	    fact_type = FactType.new(@model, fact_name)
	    fact_type.add_role(left_role = Role.new(@model, left.name, left))
	    fact_type.add_role(right_role = Role.new(@model, right.name, right))
	    fact_type
	end

	def has_primary_symbol(args)
	    # Detect :primary in the remaining args:
	    primary = false
	    args = args.delete_if{|a| primary ||= a == :primary; a == :primary }
	    primary
	end

	def has_mandatory_symbol(args)
	    # Detect :mandatory in the remaining args:
	    mandatory = false
	    args = args.delete_if{|a| mandatory ||= a == :mandatory; a == :mandatory }
	    mandatory
	end

	def has_unique_symbol(args)
	    unique = false
	    args = args.delete_if{|a| unique ||= a == :unique; a == :unique }
	    unique
	end

	def make_simple_binary_presence_constraints(fact_type, mandatory, primary, unique)

	    reading = fact_type.readings[0]
	    reading = reading ? reading.name : "{0} has {1}"
	    pc_name = reading.sub(/\{1\}/, "one {1}")
	    pc_name = Reading.expand(pc_name, fact_type.roles[0].object_type.name, fact_type.roles[1].object_type.name).
			    split(/\s+/).map{|w|
				w[0,1].upcase+w[1..-1]
			    }*""

	    pc = PresenceConstraint.new(
		    @model,			# In Model
		    pc_name,			# this constraint
		    RoleSequence.new([fact_type.roles[0]]),	# requires that this Role
		    mandatory || primary,	# default is non-mandatory
		    1, 1,			# occurs at most once
		    primary			# Default not primary
		)

	    if (primary || unique)
		pc2_name = reading.sub(/\{0\}/, "only one {0}").sub(/\{1\}/, "each {1}")
		pc2_name = Reading.expand(pc2_name, fact_type.roles[0].object_type.name, fact_type.roles[1].object_type.name).
				split(/\s+/).map{|w|
				    w[0,1].upcase+w[1..-1]
				}*""

		PresenceConstraint.new(
			@model,			# In Model,
			pc2_name,		# this constraint
			RoleSequence.new([fact_type.roles[1]]),	# requires that this Role
			false,			# default not mandatory
			1, 1,			# occurs at most once
			false			# Default not primary
		    )
	    end
	end
    end

    class Model
	def self.Builder(*args, &block)
	    b = Builder.new(*args, &block)
	    b.model
	end
    end
end
