=begin rdoc
# Base class hierarchy for representing ORM2 schemas and fact instances.
#
# Author: Clifford Heath.
=end
require 'rubygems'
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
    class Fact; end
    class FactRole; end
    class Value; end
    class Instance; end	# Usually? an EntityInstance.

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

    class Model
	array_attr ObjectType, :object_types	# Array of ObjectType
	array_attr FactType, :fact_types		# Array of FactType
	array_attr Constraint, :constraints		# Array of Constraint
	array_attr DataType, :data_types		# Array of DataType
	array_attr RoleSequence, :role_sequences	# Array of DataType
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
    end

    # A connection to a specified database
    class Session
	typed_attr Model, :model
    end

    class DataType < Feature
	typed_attr String, :base # Name of the base type of this Data Type
	typed_attr Integer, nil, :length
	typed_attr Integer, nil, :scale
	array_attr :allowed_values do |given|	# Array of AllowedValues
		    Range === given || Integer === given || String === given
		end

	def initialize(*args)
	    @base = nil
	    @length = nil
	    @scale = nil
	    args.delete_if{|a|
		case a
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

	    puts "DataType should have name" if !name
	    puts "DataType #{name} should be part of Model" if !model
	    # REVISIT: We have no built-in types yet:
	    # puts "DataType #{name} should have base DateType" if !base || base == ""
	end

	def to_s
	    "DataType #{@name} : #{@base}#{[@length, @scale].compact.inspect}"
	end
    end

    class Role < Feature
	typed_attr ObjectType, :object_type # role player
	typed_attr FactType, :fact_type	# Fact it's a role of
	typed_attr DataType, :data_type	# subtype of object_type's DataT
	array_attr FactRole, :fact_roles	# Instances of this Role

	# These things will go in "derive":
	#attr_accessor :value_restriction	# RoleValueRestriction
	#attr_accessor :_is_mandatory	# Boolean, derived
	#attr_accessor :_multiplicity	# Multiplicity, derived

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
		when DataType
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

	    puts "Role #{self} should be part of Model" if !model
	    #puts "Role should have name" if !name
	    #puts "Role #{name} should have base DateType" if !base || base == ""
	end

	def to_s
	    # Show role name only if set and different from Role Player's name:
	    (@name && @name != "" && @name != object_type.name ? "#{@name} of " : "") + 
		object_type.name
	end
    end

    class FactType < Feature
	typed_attr RoleSequence, :roles		# Array of Role
	array_attr Reading, :readings	# Array of Readings
	array_attr Fact, :facts		# Array of fact instance
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

	    puts "FactType #{self} should be part of Model" if !model
	end

	def add_role(role)
	    roles << role
	    role.fact_type = self;
	    role.object_type.roles << role
	end

	def to_s
	    roles.to_s +
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

	def to_s
	    expanded = name
	    (0...@role_sequence.size).each{|i|
		expanded.gsub!("{#{i}}", @role_sequence[i].object_type.name)
	    }

	    "Reading '#{expanded}'"
	end
    end

    # Object Types
    class ObjectType < Feature
	array_attr Role, :roles			# All Played Roles
	array_attr Instance, :instances		# Array of Instance
	attr_accessor :is_independent    		# Boolean, default false
	attr_accessor :is_personal			# Boolean, default false

	def initialize(*args)
	    super(*args)
	    model.object_types << self if (model)

	    puts "ObjectType #{self} should be part of Model" if !model
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

	# Get all RoleSequences that include this object:
	# REVISIT: What was I smoking when I wrote this?
	def preferred_identifier
	    rss = role_sequences
	    model.constraints.detect{|c|
		c.kind_of?(PresenceConstraint) &&
		    c.is_preferred_id &&
		    rss.include?(c.PresenceConstraint)
	    }
	end
    end

    class EntityType < ObjectType
	# These things will go in "derive":
	#attr_accessor :preferred_identifier	# -> Constraint
	#attr_accessor :instances			# Array of EntityTypeInstance
	#attr_accessor :_reference_mode		# String, derived

	def to_s
	    "#{@name} is an EntityType"
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
	    "#{@name} is a ValueType of #{data_type.to_s}"
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
    end

    #==============================================================
    # Instances
    # REVISIT: Incomplete
    #==============================================================

    class Fact
	typed_attr FactType, :fact_type
	array_attr FactRole, :fact_roles

	def initialize(*args)
	    raise "REVISIT: Incomplete"
	end
    end

    class FactRole
	typed_attr Role, :role
	typed_attr Fact, :fact
	typed_attr Value, :value

	def initialize(*args)
	    raise "REVISIT: Incomplete"
	end
    end

    # An Instance, often a Value of a ValueType
    class Value
	typed_attr ObjectType, :object_type
	typed_attr nil, :value do |v| String === v || Integer === v; end

	def initialize(*args)
	    raise "REVISIT: Incomplete"
	end
    end

    #==============================================================
    # Constraints
    #==============================================================

    class RoleSequence			# One or more Roles
	def to_s
	    if internal?		# All Roles are on the same fact
		self[0].fact_type.name +
		"(" +
		map{|r| r ? r.to_s : "nil" } * ", " +
		")"
	    else
		"(" +
		map{|r|
		    r.fact_type.name + "." + (r ? r.to_s : "nil")
		} * ", " +
		")"
	    end
	end

	def internal?
	    first_fact = self[0].fact_type
	    !detect{|r| r.fact_type != first_fact }
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
	    args.delete_if{|a|
		case a
		when RoleSequence
		    @role_sequence = a
		else
		    next
		end
		true
	    }
	    raise "#{self.class} requires a RoleSequence" if !role_sequence
	    super(*args)
	end
    end

    class PresenceConstraint < SetConstraint # Unique,Mandatory,Freq
	typed_attr Integer, :min, :max
	attr_accessor :is_mandatory	# Complement of "zero freq is ok"
	attr_accessor :is_preferred_id

	def initialize(_model, _name, rs, _min, _max, _mand, _pref = nil)
	    super(_model, _name, rs)
	    self.min = _min
	    self.max = _max
	    self.is_mandatory = _mand
	    self.min = 0 if (!self.is_mandatory && min == 1)
	    self.is_preferred_id = _pref
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

	def to_s
	    frequency = [
		    ((min && min > 0 && min != max) ? " at least #{min} time#{min>1?"s":""}" : nil),
		    ((max && min != max) ? " at most #{max} time#{max>1?"s":""}" : nil),
		    ((max && min == max) ? " exactly #{max} time#{max>1?"s":""}" : nil)
		].compact * " and"

	    pref = is_preferred_id ? " (preferred identifier for #{preferred_id_for.name})" : ""
	    mand = (is_mandatory ? " must" : " may") + " occur"

	    name + ": " + @role_sequence.to_s + mand + frequency + pref
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
