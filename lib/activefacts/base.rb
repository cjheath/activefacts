=begin rdoc
# Base class hierarchy for representing ORM2 schemas and fact instances.
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
=end
require 'rubygems'
require 'rational'
require 'chattr'

module ActiveFacts
    #==============================================================
    # Forward declarations for all Base classes
    #==============================================================
    class Feature; end	# Belongs to Model, has name
    class Model < Feature; end
    class Session; end	# A connection to a database instance

    # Data Types forward declared
    #class AllowedValues; end   # No class, use Range, Integer, String
    class Unit < Feature; end
    class DataType < Feature; end

    # Fact Types forward declared
    class Role < Feature; end
    class FactType < Feature; end
    class SubtypeFactType < FactType; end		# Needed?
    class Reading < Feature; end

    # Object Types forward declared
    class ObjectType < Feature; end
    class ValueType < ObjectType; end
    class EntityType < ObjectType; end
    class NestedType < EntityType; end

    # Instances forward declared
    class Population < Feature; end
    class Fact; end
    class FactRole; end
    class Instance; end

    # Constraints forward declared
    RoleSequenceBase = Array(Role)			# Generated base class
    class RoleSequence < RoleSequenceBase; end	# One or more Roles
    class Constraint < Feature; end
    class SetConstraint < Constraint; end		# One RoleSequence
    class PresenceConstraint < SetConstraint; end	# Unique,Mandatory,Freq
    class RingConstraint < SetConstraint; end
    class SubsetConstraint < Constraint; end	# Compares two RoleSeq's
    class ExclusionConstraint < Constraint; end	# Many RoleSequences
    class EqualityConstraint < Constraint; end	# Many RoleSequences

    #==============================================================
    # Forward declarations finished; define the structural features
    #==============================================================

    class OpenRange
	attr_reader :first, :last
	include Enumerable
	def initialize(first = nil, last = nil)
	    @first, @last = first, last
	end

	def each
	    if (first)
		x = self.first
		loop do
		    yield x
		    x = x.succ
		    break if x == self.last
		end
	    elsif self.last
		x = self.last
		x.downto(-1.0/0) do |y|	  # Stop at -Infinity
		    yield y
		end
	    end
	    self
	end

	def ===(value)
	    (!self.first || value >= self.first) &&
	    (!self.last || value <= self.last)
	end

	def begin
	    self.start
	end

	def end
	    self.last
	end

	def length
	    self.first && self.last ? self.last - self.start : 1.0/0
	end

	def size
	    length
	end

	def inspect
	  to_s
	end

	def to_s
	    (@first && @first.inspect) + ".." + (@last && @last.inspect)
	end
    end

    # A Feature is a named item in a model
    class Feature
	typed_attr "", :name	    # Name, default empty string
	typed_attr Model, nil, :model   # Parent model or nil

	def initialize(*args)
	    @model ||= nil
	    @name ||= ""
	    args.delete_if{|a|
		case a
		when Model
		    self.model = a
		when String
		    self.name = (a && a.size > 0) ? a : ""
		else
		    next
		end
		true
	    }
	    raise "Unrecognised #{self.class} initialisers: #{args.inspect}" if args.size > 0
	end
    end

    class Model < Feature
	array_attr ObjectType, :object_types	# Array of ObjectType
	array_attr FactType, :fact_types	# Array of FactType
	array_attr Constraint, :constraints	# Array of Constraint
	array_attr DataType, :data_types	# Array of DataType
	array_attr RoleSequence, :role_sequences# Array of RoleSequences
	array_attr Population, :populations	# Array of Population
	# hash_attr Role, RoleSequence, :role_sequence_by_role # Role->RoleSequence

	def initialize(*args)
	    super(*args)	    # name and model only
	end

	def to_s
	    "Model #{@name}"
	end

	def get_role_sequence(rs)
	    role_sequences.each{|e| return e if e == rs }
	    role_sequences << rs
	    rs
	end

	def preferred_ids
	    constraints.select{|c|
		PresenceConstraint === c && c.is_preferred_id
	    }
	end
    end

    # A connection to a specified database
    class Session
	typed_attr Model, :model
    end

    class BaseUnit
	typed_attr Unit, :base_for
	typed_attr Unit, :base_unit
	typed_attr Integer, :exponent

	def initialize(*args)
	    args.delete_if{|a|
		case a
		when Integer
		    @exponent = a
		when Unit
		    @base_unit = a
		end
	    }
	    super(*args)
	end
    end

    class Unit
	typed_attr String, :name
	typed_attr Numeric, :coefficient
	typed_attr TrueClass, :is_precise
	array_attr BaseUnit, :base_units

	def initialize(*args)
	    args.delete_if{|a|
		case a
		when String
		    @name = a
		when BaseUnit
		    @base_units << a
		    a.base_for = self
		end
	    }
	    super(*args)
	end
    end

    class DataType < Feature
	typed_attr String, :base # Name of the base type of this Data Type
	typed_attr Integer, nil, :length
	typed_attr Integer, nil, :scale
	array_attr :allowed_values do |given|	# Array of AllowedValues
		    Range === given || Integer === given || String === given || OpenRange === given
		end

	def initialize(*args)
	    @base = nil
	    @length = nil
	    @scale = nil
	    args.delete_if{|a|
		case a
		when DataType
		    next if @base
		    @base = a.name
		when String
		    if !@name
			@name = a
		    elsif !@base
			@base = a
		    else
			next
		    end
		when Integer
		    if !@length
			@length = a
		    elsif !@scale
			@scale = a
		    else
			next
		    end
		else
		    next
		end
		true
	    }
	    super(*args)
	    model.data_types << self if (model)

	    throw "DataType should have name" if !name
	    throw "DataType #{name} should be part of Model" if !model
	    # REVISIT: We have no built-in types yet:
	    # puts "DataType #{name} should have base DateType" if !base || base == ""
	end

	def to_s
	    # REVISIT: Look up DataType base by name, recursively and report?
	    parameters = []
	    parameters << @length.to_s if (@length != 0 || @scale != 0)
	    parameters << @scale.to_s if (@scale != 0)
	    parameters = parameters.length > 0 ? "("+parameters.join(",")+")" : "()"
	    "#{@name}#{parameters}" +
	    (allowed_values.size == 0 ? "" :
		" restricted to {#{(allowed_values.map{|r| r.inspect}*", ").gsub('"',"'")}}")
	end
    end

    class Role < Feature
	typed_attr ObjectType, :object_type	# role player
	typed_attr FactType, :fact_type		# Fact it's a role of
	typed_attr DataType, :data_type		# subtype of object_type's DataT
	array_attr FactRole, :fact_roles	# Instances of this Role
	array_attr :allowed_values do |given|	# Array of AllowedValues
		    Range === given || Integer === given || String === given || OpenRange === given
		end

	def initialize(*args)
	    @object_type = nil
	    @fact_type = nil
	    @data_type = nil
	    args.delete_if{|a|
		case a
		when ObjectType
		    self.object_type = a
		when FactType, SubtypeFactType
		    self.fact_type = a
		when DataType	# Used only when Role ValueRestrictions apply
		    self.data_type = a
		else
		    next
		end
		true
	    }
	    super(*args)
	    name ||= @object_type.name
	    raise "Role must have an ObjectType" unless @object_type
	    #raise "Role must have a FactType" unless @fact_type

	    throw "Role #{self} should be part of Model" if !model
	    #puts "Role should have name" if !name
	    #puts "Role #{name} should have base DateType" if !base || base == ""
	end

	def player_name
	    if object_type.name && object_type.name != ''
		object_type.name
	    else
		object_type.data_type.name
	    end
	end

	def name
	    case
	    when hyphen_bound
		@name[0..-2]+" "+player_name
	    when @name && @name != ''
		@name
	    else
		player_name
	    end
	end

	# NORMA stores hyphen-binding in the reading text; ActiveFacts in the role name
	def hyphen_bound
	  @name && @name[-1] == ?-
	end

	def to_s(verbose = false)
	    player = object_type.name

	    # For Value Types, just show the Role name (if set) or ValueType name
	    if (ValueType === object_type)
		o_n = object_type.name
		case
		when @name && @name != ""
		    return @name + extra_s(verbose)
		when o_n && o_n != ""
		    return o_n + extra_s(verbose)
		else
		    # Otherwise for Value Types, show the data type, not the value type:
		    player = object_type.data_type.name
		end
	    end

	    # Otherwise, show role name only if set and different from Role Player's name:
	    (@name && @name != "" && @name != player ? "#{@name} of " : "") +
		player +
		extra_s(verbose)
	end

	def extra_s(verbose)
	    return "" if (!verbose || allowed_values.size == 0)
	    return " restricted to {#{(allowed_values.map{|r| r.inspect}*", ").gsub('"',"'")}}"
	end
    end

    class FactType < Feature
	typed_attr RoleSequence, :roles		# Array of Role
	array_attr Reading, :readings		# Array of Readings
	array_attr Fact, :facts			# Array of fact instance
	typed_attr NestedType, :nested_as	# NestedType

	# These things will go in "derive":
	#attr_accessor :notes
	#attr_accessor :internal_constraints	# Array of Uniqueness|Mandatory
	#attr_accessor :derivation_rule		# DerivationRule is omitted for now

	def initialize(*args)
	    model = args.detect{|a| Model === a }
	    @roles ||= RoleSequence.new
	    args.delete_if{|a|
		case a
		when Role
		    add_role(a)
		when ObjectType # Shorthand; create a role for ObjectType:
		    add_role(Role.new(model || a.model, a))
		else
		    next
		end
		true
	    }
	    super(*args)
	    # @nested_as will get set afterwards if needed
	    model.fact_types << self if (model)
	    fact_types = []

	    throw "FactType #{self} should be part of Model" if !model
	end

	def preferred_reading
	  return unless reading = readings[0]
	  reading.to_s
	end

	def add_role(role)
	    roles << role
	    role.fact_type = self;
	    role.object_type.roles << role
	end

	def role_by_name(name)
	    roles.detect{|r| r.name == name } ||    # Find the role directly, or
	    roles.detect{|r|
		EntityType === r.object_type &&	# Role is played by an EntityType
		(pi = r.object_type.preferred_identifier) && # Having a PI
		pi.role_sequence.size == 1 &&	    # With one role
		pi.role_sequence[0].name == name    # Named appropriately
	    }
	end

	def to_s
	    roles.to_s(true) +
		(nested_as ? " (nested as #{nested_as.name})" : "")
	end
    end

    class SubtypeFactType < FactType
	typed_attr EntityType, :supertype
	typed_attr EntityType, :subtype

	def initialize(*args)
	    # No Roles passed, just Super, Sub
	    model = args.detect{|a| Model === a }
	    @roles = RoleSequence.new
	    objects = []
	    args.delete_if{|a|
		case a
		when ObjectType
		    objects << a
		    self.roles << (r = Role.new(model, a, self))
		else
		    next
		end
		true
	    }
	    raise "Subtyping requires 2 objects" if (roles.size != 2)
	    @subtype, @supertype = *objects
	    @supertype.roles << roles[0]
	    @subtype.roles << roles[1]
	    super(*args)
	end

	def roles=
	    raise "Can't add roles to subtype fact type"
	end

	def readings
	    return super if super.size > 0
	    [Reading.new(self.roles, "{0} is a subtype of {1}")]
	end
    end

    class Reading < Feature
	typed_attr RoleSequence, :role_sequence

	def initialize(*args)
	    args.delete_if{|a|
		case a
		when RoleSequence
		    @role_sequence = a
		else
		    next
		end
		true
	    }
	    raise "Reading requires a RoleSequence" unless @role_sequence
	    super(*args)
	end

	def self.expand(t, names, constraint_hash = {})
	    expanded = "#{t}"
	    (0...names.size).each{|i|
		expanded.gsub!("{#{i}}") {
		    names[i]
		  }
	    }
	    expanded
	end

	def expand(constraint_hash = {})
	    expanded = "#{name}"
	    (0...@role_sequence.size).each{|i|
		role = @role_sequence[i]

		# REVISIT: Handle trailing hyphen-binding here:
		role_with_adjectives_re =
		    %r|(?:\b([A-Za-z][A-Za-z0-9_]*)- +(?:([A-Za-z0-9_][A-Za-z0-9_ ]*[A-Za-z0-9_]) +)?)?\{#{i}\}|

		expanded.gsub!(role_with_adjectives_re) {
		    constraint = constraint_hash[@role_sequence[i]]
		    constraint_text = constraint && PresenceConstraint === constraint && constraint.frequency
		    # Indicate that we've used this constraint
		    constraint_hash.delete(@role_sequence[i]) if (constraint_text)
		    player = @role_sequence[i].object_type
		    [
		      constraint_text,
		      $1 && $1 != "" && $1,
		      $2 && $2 != "" && $2,
		      player.name,
		      player.name != role.name ? "(as #{role.name})" : nil
		    ].compact*" "
		}
	    }
	    expanded
	end

	def to_s(constraint_hash = {})
	    expand(constraint_hash)
	end
    end

    # Object Types
    class ObjectType < Feature
	array_attr Role, :roles			# All Played Roles
	array_attr Instance, :instances		# Array of Instance
	attr_accessor :is_independent  		# Boolean, default false
	attr_accessor :is_personal		# Boolean, default false

	def initialize(*args)
	    super(*args)
	    model.object_types << self if (model)

	    throw "ObjectType #{self} should be part of Model" if !model
	end

	def delete
	    @roles && @roles.each(&:delete)
	    @model.object_types.delete(self) if (@model)
	end

	# All unique fact types in which this object plays a role
	def fact_types
	    roles.map{|r| r.fact_type }.uniq
	end

	# All role sequences in the model in which this object plays a role
	def role_sequences
	    model.role_sequences.reject{|rs|
		!rs.detect{|r| r.object_type == self }  # doesn't include this object
	    }
	end

	def preferred_identifier
	    throw "#{self.class} can not have a preferred_identifier"
	end
    end

    class EntityType < ObjectType
	# These things will go in "derive":
	#attr_accessor :preferred_identifier	# -> Constraint
	#attr_accessor :instances		# Array of EntityTypeInstance
	#attr_accessor :_reference_mode		# String, derived

	def to_s
	    "#{@name} = entity"
	end

	# REVISIT: Can have more than one supertype.
	def supertype
	    sup = nil
	    roles.find{|r|
		f = r.fact_type
		SubtypeFactType === f &&
		    f.roles.size == 2 &&
		    f.subtype == self &&
		    (sup = f.supertype)
	    }
	    sup
	end

	# An array of self followed by all supertypes in order:
	def supertypes
	    [ self ] + ((sup = supertype) ? sup.supertypes : [])
	end

	def subtypes
	    roles.inject([]){|a, r|
		f = r.fact_type
		if (f.roles.size == 2 &&
			SubtypeFactType === f &&
			f.supertype == self)
		    a << f.subtype
		end
		a
	    }
	end

	def preferred_identifier	# -> Constraint
	    # The preferred identifier is a unique constraint over roles in one
	    # or more fact types in which this object plays the other roles, or
	    # in the case of a nested type, over roles of the nested fact type.
	    # A nested type may NOT have a PI that spans both nested and
	    # non-nested roles (according to Terry H)
	    @model.preferred_ids.each{|pi|
		# Every fact type which this PI spans must have no non-PI roles
		# except for this object's:
		rs = pi.role_sequence
		fact_types = rs.map(&:fact_type).uniq

		if NestedType === self &&
		    fact_types.size == 1 &&    # PI must not span more than one fact type
		    fact_types[0] == self.fact_type
			return pi
		end

		if fact_types.detect{|ft|
			residual = ft.roles-rs
			residual.size > 1 ||    # Any residual must be self or a supertype:
			    (residual.size == 1 && !supertypes.include?(residual[0].object_type))
		    }
		    next
		end
		return pi
	    }
	    throw "No preferred identifier found for #{to_s}"
	end
	nil
    end

    # define anonymous DataType, instead of supporting ValueRestrictions
    class ValueType < ObjectType
	typed_attr DataType, :data_type		# DataType

	def initialize(*args)
	    @data_type = nil
	    args.delete_if{|a|
		case a
		when DataType
		    @data_type = a
		else
		    next
		end
		true
	    }
	    # REVISIT: If no data_type, look for one by @name in @model,
	    # Check for Integer args and make a subtype if needed
	    super(*args)
	end

	def to_s
	    "#{@name} = #{data_type.to_s}"
	end
    end

    class NestedType < EntityType
	typed_attr FactType, :fact_type

	def initialize(*args)
	    @data_type = nil
	    args.delete_if{|a|
		case a
		when FactType
		    @fact_type = a
		else
		    next
		end
		true
	    }
	    raise "NestedType requires FactType to nest!" if !fact_type
	    fact_type.nested_as = self
	    super(*args)
	end

	def to_s
	    "#{name} nests #{@fact_type.roles.to_s}"
	end

	def preferred_identifier	# -> Constraint
	    candidates =
		@model.constraints.select{|s|
		    PresenceConstraint === s &&	# The constraint must be a PC:
			# The PC must be mandatory and unique:
	      # REVISIT: sometimes these aren't marked mandatory, find out why.
#		    s.is_mandatory &&
		    s.max &&
		    s.max == 1 &&
			# The PC must only span roles in our nested facttype
		    !s.role_sequence.detect{|r| @fact_type != r.fact_type }
		}

	    # Chose the candidate that's marked as preferred, if any:
	    pi = candidates.detect{|s| s.is_preferred_id }
	    # puts "Candidate PIs are #{candidates.map(&:to_s)*"; "}" if candidates.size > 1
	    return pi if pi

	    # If no UC on nested fact, try superclass:
	    return super if !pi
	end
    end

    #==============================================================
    # Instance Populations:
    #==============================================================
    class Population
	array_attr Fact, :facts

	def initialize(*args)
	    super(*args)			# Handle name, model
	    @model.populations << self if @model
	end
    end

    class Fact
	typed_attr Population, :population	# Population it's a member of
	typed_attr FactType, :fact_type		# FactType it's an instance of
	array_attr FactRole, :fact_roles	# Array of FactRoles

	def initialize(*args)
	    @population = nil
	    args.delete_if{|a|
		case a
		when Population
		    self.population = a
		when FactType
		    self.fact_type = a
		when FactRole
		    self.fact_roles << a
		    a.fact = self
		else
		    next
		end
		true
	    }
	    @population.facts << self if @population
	    @fact_type.facts << self if @fact_type
	    # puts "Adding fact to fact_type #{@fact_type.name}" if @fact_type

	    # Make sure all FactRoles are from this fact type:
	    throw "All Fact Roles must be from one Fact Type" \
		if fact_roles.detect{|fr| !fact_type.roles.detect{|r| fr.role == r} }
	    throw "Wrong number of fact roles or duplicate role" \
		unless @fact_roles.map(&:role).uniq.size == @fact_type.roles.size
	end

	def to_s
	    # REVISIT: Verbalize fact instance?
	    "#{fact_type.name}(#{fact_roles.map(&:to_s).join(", ")})"
	end
    end

    class FactRole
	typed_attr Role, :role
	typed_attr Fact, :fact
	typed_attr Instance, :instance

	def initialize(*args)
	    args.delete_if{|a|
		case a
		when Role
		    self.role = a
		when Fact
		    self.fact = a
		when Instance
		    self.instance = a
		else
		    next
		end
		true
	    }
	end

	def to_s
	    "#{role.name} is #{instance.to_s}"
	end
    end

    # An Instance, either a Value of a ValueType or an Entity
    class Instance
	typed_attr ObjectType, :object_type
	typed_attr nil, :value do |v|
	    String === v || Integer === v
	end

	def initialize(*args)
	    args.delete_if{|a|
		case a
		when ObjectType
		    self.object_type = a
		when String, Integer	    # Revisit: DateTime, etc?
		    self.value = a
		else
		    next
		end
		true
	    }
	    raise "Instance lacks object type" \
		if (!self.object_type)
	    raise "Instance of ValueType #{@object_type.name} lacks value" \
		if (!self.value && ValueType === self.object_type)
	    @object_type.instances << self
	end

	def to_s
	    case object_type
	    when ValueType
		"'#{value}'"
	    when EntityType
		pi = object_type.preferred_identifier
		rs = pi.role_sequence	    # Gather PI FactRole values
		# puts "Instance of #{object_type.name} with PI #{rs}"
		fact_types = object_type.roles.map{|r|
			r.fact_type
		    }.uniq.select{|ft|
			(ft.roles-rs).size == 1
		    }
		# puts "Looking for role values in instances of #{ fact_types.map(&:to_s)*"; "}"

		# An internal PI covers one fact only:
		internal = pi.internal?
		last_fact_type = nil
		last_instance = nil

		role_values = rs.map{|r|
		    # Get Role Value.
		    # In the case of an Instance of a non-nested type, a
		    # single Fact (FactType instance) has this Instance as
		    # one role, and this role as the other - find the value
		    # of this other role on that fact instance.

		    facts = r.fact_type.facts.select{|f|
			    f.fact_roles.detect{|x| x.instance == self}
			}
		    throw "Instance with no identifying fact!" if (facts.size == 0)
		    fact_role = facts[0].fact_roles.find{|fr| fr.role == r }
		    fact_role.instance.to_s
		}

		"#{object_type.name}(#{role_values * ", "})"
	    end
	end
    end

    #==============================================================
    # Constraints
    #==============================================================

    class RoleSequence			# One or more Roles
	def to_s(verbose = false)
	    if internal?		# All Roles are on the same fact
		self[0].fact_type.name +
		"(" +
		map{|r| r ? r.to_s(verbose) : "nil" } * ", " +
		")"
	    else
		"(" +
		map{|r|
		    r.fact_type.name + "." + (r ? r.to_s(verbose) : "nil")
		} * ", " +
		")"
	    end
	end

	def internal?
	    first_fact = self[0].fact_type
	    !detect{|r| r.fact_type != first_fact }
	end

	def role_name_list
	    "(" + map{|r| r ? r.to_s : "nil" }*", " + ")"
	end

	def role_names
	    map{|r| r.name != "" ? r.name : r.object_type.name}
	end

	def object_names
	    map{|r| r.object_type.name}
	end
    end

    class Constraint < Feature
	typed_attr true, :must	# Alethic (must), Deontic (should)

	def initialize(*args)
	    super(*args)
	    @model.constraints << self if (@model)
	end
    end

    class SetConstraint < Constraint	# One RoleSequence
	typed_attr RoleSequence, :role_sequence

	def initialize(*args)
	    model = args.detect{|a| Model === a }
	    args.delete_if{|a|
		case a
		when RoleSequence, Array
		    @role_sequence = model.get_role_sequence(a)
		else
		    next
		end
		true
	    }
	    raise "#{self.class} requires a RoleSequence" if !role_sequence
	    super(*args)
	end

	def internal?
	    role_sequence.internal?
	end
    end

    class PresenceConstraint < SetConstraint # Unique,Mandatory,Freq
	typed_attr Integer, nil, :min, :max
	attr_accessor :is_mandatory	# Complement of "zero freq is ok"
	attr_accessor :is_preferred_id

	def initialize(_model, _name, rs, _mand, _min, _max, _pref = nil)
	    super(_model, _name, rs)
	    self.is_mandatory = _mand
	    self.min = _min
	    self.max = _max
	    self.min = 0 if (!self.is_mandatory && min == 1)
	    self.is_preferred_id = _pref
	    # puts "PI(#{object_id}) #{rs[0].fact_type.name}#{rs}" if (_pref)
	end

	def preferred_id_for
	    return nil if !is_preferred_id  # Not preferred_id

	    # An internal preferred id for a nested fact can only be for the nesting:
	    if (@role_sequence.internal? && (nested_as = @role_sequence[0].fact_type.nested_as))
		return nested_as
	    end

	    # Find all objects involved in all facts this constraint has a role in:
	    all_objects = @role_sequence.map{|r|
		    r.fact_type.roles
		}.flatten.map{|r|
		    r.object_type
		}.uniq
	    # Remove all objects this constraint has roles for:
	    pi_for = all_objects - @role_sequence.map{|r| r.object_type}
#	    if pi_for.size == 0
#		# When a PC covers all roles of an objectified fact, the above computes an empty set:
#		return @role_sequence[0].fact_type.nested_as
#	    else
		throw "Preferred identifier PresenceConstraint #{name} must identify one object"+
		    ", not #{pi_for.map{|o| o.name}.inspect}" if pi_for.size != 1
		return pi_for[0]
#	    end
	end

	def frequency
	    [
		((min && min > 0 && min != max) ? "at least #{min}" : nil),
		((max && min != max) ? "at most #{max == 1 ? "one" : max.to_s}" : nil),
		((max && min == max) ? "exactly #{max == 1 ? "one" : max.to_s}" : nil)
	    ].compact * " and"
	end

	def to_s
	    frequency = [
		    ((min && min > 0 && min != max) ? " at least #{min}" : nil),
		    ((max && min != max) ? " at most #{max}" : nil),
		    ((max && min == max) ? " exactly #{max}" : nil)
		].compact * " and" + " time#{max>1?"s":""}"

	    pref = is_preferred_id ? " (preferred identifier)" : "" # for #{preferred_id_for.name})" : ""
	    mand = (is_mandatory ? " must" : " may") + " occur"

	    cv = @role_sequence.size > 1 ? "combination" : "value"
	    if (@role_sequence.internal?)
		what = "in #{@role_sequence[0].fact_type.name}, each #{cv} #{@role_sequence.role_name_list}"
	    else
		what = "each "+cv+@role_sequence.to_s 
	    end

	    name + ": " + what + mand + frequency + pref
	    # REVISIT: Find a reading instead!
	end
    end

    class RingConstraint < SetConstraint
	TypeNames = %w{
	    Undefined
	    PurelyReflexive
	    Irreflexive
	    Acyclic
	    Intransitive
	    Symmetric
	    Asymmetric
	    AntiSymmetric
	    AcyclicIntransitive
	    SymmetricIrreflexive
	    SymmetricIntransitive
	    AsymmetricIntransitive
	}
	eval "(#{TypeNames * ", "}) = *(0..12)"

	typed_attr Integer, :type_num do |v| v >= 0 && v <= AsymmetricIntransitive; end
	def from_role; @role_sequence[0]; end 
	def to_role; @role_sequence[1]; end

	def initialize(*args)
	    @from_role = @to_role = nil
	    args.delete_if{|a|
		case a
		when Integer
		    self.type_num = a
		else
		    next
		end
		true
	    }
	    super(*args)
	    throw "Ring Constraint #{name} needs two roles" if role_sequence.size != 2
	    from_role = role_sequence[0]
	    to_role = role_sequence[1]
	end

	def type_name
	    TypeNames[type_num]
	end

	def to_s
	    "RingConstraint #{name}, #{type_name} over #{role_sequence}"
	end
    end

    class SubsetConstraint < Constraint	# Compares two RoleSeq's
	typed_attr RoleSequence, :superset_role_sequence
	typed_attr RoleSequence, :subset_role_sequence

	def initialize(*args)
	    @superset_role_sequence = @subset_role_sequence = nil
	    args.delete_if{|a|
		case a
		when RoleSequence
		    if !@superset_role_sequence
			@superset_role_sequence = a
		    elsif !@subset_role_sequence
			@subset_role_sequence = a
		    else
			next
		    end
		else
		    next
		end
		true
	    }
	    super(*args)
	    throw "Subset Constraint #{name} needs two role sequences" unless subset_role_sequence
	end

	def to_s
	    "SubsetConstraint #{name} #{subset_role_sequence} < #{superset_role_sequence}"
	end
    end

    class ExclusionConstraint < Constraint	# Many RoleSequences
	array_attr RoleSequence, :role_sequences

	def initialize(*args)
	    args.delete_if{|a|
		case a
		when Array
		    role_sequences.concat(a)
		when RoleSequence
		    role_sequences << a
		else
		    next
		end
		true
	    }
	    super(*args)
	end

	def to_s
	    "ExclusionConstraint #{name} over #{role_sequences.map{|rs| rs.to_s }*", "}"
	end
    end

    class EqualityConstraint < Constraint	# Many RoleSequences
	array_attr RoleSequence, :role_sequences

	def initialize(*args)
	    @superset_role_sequence = @subset_role_sequence = nil
	    args.delete_if{|a|
		case a
		when Array
		    role_sequences.concat(a)
		when RoleSequence
		    role_sequences << a
		else
		    next
		end
		true
	    }
	    super(*args)
	    throw "EqualityConstraint Constraint #{name} needs more than one role sequence" unless @role_sequences.size > 1
	end

	def to_s
	    "EqualityConstraint #{name} between #{role_sequences.map{|rs| rs.to_s}*", "}"
	end
    end

end
