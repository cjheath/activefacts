require 'rexml/document'
require 'activefacts/base'

module ActiveFacts
    class Norma
	def self.read(filename)
	    Norma.new(filename).read
	end 

	def initialize(filename)
	    @filename = filename
	end

	def read
	    begin
		file = File.new(@filename)
		doc = REXML::Document.new(file)
	    rescue => e
		puts "Failure in reading #{@filename}: #{e.inspect}"
	    end

	    # Find the Model and do some setup:
	    root = doc.elements[1]
	    if root.expanded_name == "ormRoot:ORM2"
		x_models = root.elements.to_a("orm:ORMModel")
		throw "No model found" unless x_models.size == 1
		@x_model = x_models[0]
	    elsif root.name == "ORMModel"
		@x_model = doc.elements[1]
	    else
		pp root
		throw "NORMA model not found in file"
	    end

	    read_model
	    @model
	end

	def read_model
	    @model = Model.new(@x_model.attributes['Name'])

	    # Find all elements having an "id" attribute and index them
	    x_identified = @x_model.elements.to_a("//*[@id]")
	    @x_by_id = x_identified.inject({}){|h, x|
		id = x.attributes['id']
		h[id] = x
		h
	    }

	    # Everything we build will be indexed here:
	    @by_id = {}

	    read_entity_types
	    read_value_types
	    read_fact_types
	    read_nested_types
	    read_subtypes
	    read_roles
	    read_constraints
	end

	def read_entity_types
	    # get and process all the entity types:
	    entity_types = []
	    x_entity_types = @x_model.elements.to_a("orm:Objects/orm:EntityType")
	    x_entity_types.each{|x|
		id = x.attributes['id']
		name = x.attributes['Name'] || ""
		name = nil if name.size == 0
		# puts "EntityType #{name} is #{id}"
		entity_types <<
		    @by_id[id] = EntityType.new(@model, name)
	    }
	end

	def read_value_types
	    # Now the value types:
	    value_types = []
	    x_value_types = @x_model.elements.to_a("orm:Objects/orm:ValueType")
	    #pp x_value_types
	    x_value_types.each{|x|
		id = x.attributes['id']
		name = x.attributes['Name'] || ""
		name = nil if name.size == 0

		cdt = x.elements.to_a('orm:ConceptualDataType')[0]
		scale = cdt.attributes['Scale'].to_i
		length = cdt.attributes['Length'].to_i
		base_type = @x_by_id[cdt.attributes['ref']]
		data_type = DataType.new(@model, base_type.name.sub(/^orm:/,''))
		data_type.length = length
		data_type.scale = scale

		# puts "ValueType #{name} is #{id}"
		value_types <<
		    @by_id[id] = ValueType.new(@model, name, data_type)

		# Look for value restrictions
		value_ranges = x.elements.to_a("orm:ValueRestriction/orm:ValueConstraint/orm:ValueRanges/orm:ValueRange")
		p value_ranges if value_ranges.size > 0
	    }
	end

	def read_fact_types
	    # Handle the fact types:
	    facts = []
	    @x_facts = @x_model.elements.to_a("orm:Facts/orm:Fact")
	    @x_facts.each{|x|
		id = x.attributes['id']
		name = x.attributes['Name'] || x.attributes['_Name']
		name = "<unnamed>" if !name
		name = "" if !name || name.size == 0
		# puts "FactType #{name || id}"

		facts << @by_id[id] = fact_type = FactType.new(@model, name)
	    }
	end

	def read_subtypes
	    # Handle the subtype fact types:
	    facts = []
	    @x_subtypes = @x_model.elements.to_a("orm:Facts/orm:SubtypeFact")
	    @x_subtypes.each{|x|
		id = x.attributes['id']
		name = x.attributes['Name'] || x.attributes['_Name']
		name = nil if name.size == 0
		# puts "FactType #{name || id}"

		x_subtype_role = x.elements['orm:FactRoles/orm:SubtypeMetaRole']
		subtype_role_id = x_subtype_role.attributes['id']
		subtype_id = x_subtype_role.elements['orm:RolePlayer'].attributes['ref']
		subtype = @by_id[subtype_id]

		x_supertype_role = x.elements['orm:FactRoles/orm:SupertypeMetaRole']
		supertype_role_id = x_supertype_role.attributes['id']
		supertype_id = x_supertype_role.elements['orm:RolePlayer'].attributes['ref']
		supertype = @by_id[supertype_id]

		throw "For Subtype fact #{name}, the supertype #{supertype_id} was not found" if !supertype
		throw "For Subtype fact #{name}, the subtype #{subtype_id} was not found" if !subtype
	#	puts "#{subtype.name} is a subtype of #{supertype.name}"

		fact_type = SubtypeFactType.new(name, @model, subtype, supertype)
		facts << @by_id[id] = fact_type

		# Index the new Roles so we can find constraints on them:
		#puts "SubtypeFactType #{fact_type}"
		subtype_role = fact_type.roles[0]
		@by_id[subtype_role_id] = subtype_role
		supertype_role = fact_type.roles[1]
		@by_id[supertype_role_id] = supertype_role
	    }
	end

	def read_nested_types
	    # Process NestedTypes, but ignore ones having a NestedPredicate with IsImplied="true"
	    # We'll ignore the fact roles (and constraints) that implied objectifications have.
	    # This happens for all ternaries and higher order facts
	    nested_types = []
	    x_nested_types = @x_model.elements.to_a("orm:Objects/orm:ObjectifiedType")
	    x_nested_types.each{|x|
		id = x.attributes['id']
		name = x.attributes['Name'] || ""
		name = nil if name.size == 0

		x_fact_type = x.elements.to_a('orm:NestedPredicate')[0]
		is_implied = x_fact_type.attributes['IsImplied'] == "true"

		fact_id = x_fact_type.attributes['ref']
		fact_type = @by_id[fact_id]
		throw "Nested fact #{fact_id} not found" if !fact_type

		if is_implied
		    # puts "Implied type #{name} (#{id}) nests #{fact_type ? fact_type.name : "unknown"}"
		    @by_id[id] = fact_type
		else
		    # puts "NestedType #{name} is #{id}, nests #{fact_type.name}"
		    nested_types <<
			@by_id[id] =
			nested_type = NestedType.new(@model, name, fact_type)
		end
	    }
	end

	def read_roles
	    @x_facts.each{|x|
		id = x.attributes['id']
		fact_type = @by_id[id]

		x_fact_roles = x.elements.to_a('orm:FactRoles/*')
		x_reading_orders = x.elements.to_a('orm:ReadingOrders/*')

		# Deal with FactRoles (Roles):
		x_fact_roles.each{|x|
		    name = x.attributes['Name'] || ""
		    name = nil if name.size == 0
		    # _IsMandatory = x.attributes['_IsMandatory']
		    # _Multiplicity = x.attributes['_Multiplicity]
		    id = x.attributes['id']
		    ref = x.elements[1].attributes['ref']

		    # Find the object type that plays the role:
		    object_type = @by_id[ref]
		    throw "RolePlayer for #{name||ref} was not found" if !object_type

		    #puts "#{@model}, Name=#{x.attributes['Name']}, object_type=#{object_type}"
		    throw "Role is played by #{object_type.class} not ObjectType" if !(ObjectType === object_type)

		    role = @by_id[id] = Role.new(@model, x.attributes['Name'], object_type)
		    fact_type.add_role(role)
		    # puts "\tRole #{role} is #{id}"
		}

		# Deal with Readings:
		x_reading_orders.each{|x|
		    x_role_sequence = x.elements.to_a('orm:RoleSequence/*')
		    x_readings = x.elements.to_a('orm:Readings/orm:Reading/orm:Data')

		    role_sequence = RoleSequence.new
		    x_role_sequence.each{|x|
			ref = x.attributes['ref']
			role = @by_id[ref]
			role_sequence << role
		    }
		    role_sequence = @model.get_role_sequence(role_sequence)

		    x_readings.each{|x|
			fact_type.readings << Reading.new(role_sequence, x.text)
		    }
		}
	    }
	end

	def map_roles(x_roles, why = nil)
	    ra = x_roles.map{|x|
		id = x.attributes['ref']
		role = @by_id[id]
		if (why && !role)
		    # We didn't make Implied objects, so some constraints are unconnectable
		    x_role = @x_by_id[id]
		    x_player = x_role.elements.to_a('orm:RolePlayer')[0]
		    x_object = @x_by_id[x_player.attributes['ref']]
		    x_nests = nil
		    if (x_object.name.to_s == 'ObjectifiedType')
			x_nests = x_object.elements.to_a('orm:NestedPredicate')[0]
			implied = x_nests.attributes['IsImplied']
			x_fact = @x_by_id[x_nests.attributes['ref']]
		    end

		    # This might have been a role of an ImpliedFact, which makes it safe to ignore.
		    next if 'ImpliedFact' == x_role.parent.parent.name

		    # Talk about why this wasn't found - this shouldn't happen.
		    if (!x_nests || !implied)
			puts "="*60
			puts "Skipping #{why}, #{x_role.name} #{id} not found"

			if (x_nests)
			    puts "Role is on #{implied ? "implied " : ""}objectification #{x_object}"
			    puts "which objectifies #{x_fact}"
			end
			puts x_object.to_s
		    end
		end
		role
	    }
	    ra.include?(nil) ? nil : RoleSequence.new(ra)
	end

	def read_constraints
	    @constraints_by_rs = {}

	    read_mandatory_constraints
	    read_uniqueness_constraints
	    read_exclusion_constraints
	    read_subset_constraints
	    read_ring_constraints
	    read_value_constraints
	    read_equality_constraints
	end

	def read_mandatory_constraints
	    x_mandatory_constraints = @x_model.elements.to_a("orm:Constraints/orm:MandatoryConstraint")
	    @mandatory_constraints = {}
	    x_mandatory_constraints.each{|x|
		    name = x.attributes["Name"]
		    x_roles = x.elements.to_a("orm:RoleSequence/orm:Role")
		    roles = map_roles(x_roles, "mandatory constraint #{name}")
		    next if !roles

		    # If X-OR mandatory, the Exclusion is accessed by:
		#    x_exclusion = (ex = x.elements.to_a("orm:ExclusiveOrExclusionConstraint")[0]) &&
		#		    @x_by_id[ex.attributes['ref']]
		#    puts "Mandatory #{name}(#{roles}) is paired with exclusive #{x_exclusion.attributes['Name']}" if x_exclusion

		    rs = RoleSequence.new
		    roles.each{|r| rs << r }
		    rs = @model.get_role_sequence(rs)

# puts "Mandatory("+roles.map{|r| "#{r.object_type.name} in #{r.fact_type.to_s}" }*", "+")"

		    @mandatory_constraints[rs] = true
	    }
	end

	def read_uniqueness_constraints
	    x_uniqueness_constraints = @x_model.elements.to_a("orm:Constraints/orm:UniquenessConstraint")
	    x_uniqueness_constraints.each{|x|
		name = x.attributes["Name"]
		x_pi = x.elements.to_a("orm:PreferredIdentifierFor")[0]
		pi = x_pi ? @by_id[eref = x_pi.attributes['ref']] : nil

		# Skip uniqueness constraints on implied object types
		if x_pi && !pi
		    puts "Skipping uniqueness constraint #{name}, entity not found"
		    next
		end

		# A uniqueness constraint on a fact having an implied objectification isn't preferred:
		if pi &&
		    (x_pi_for = @x_by_id[eref]) &&
		    (np = x_pi_for.elements.to_a('orm:NestedPredicate')[0]) &&
		    np.attributes['IsImplied']
			pi = nil
		end

		# Get the RoleSequence:
		x_roles = x.elements.to_a("orm:RoleSequence/orm:Role")
		roles = map_roles(x_roles, "uniqueness constraint #{name}")
		next if !roles

		rs = RoleSequence.new
		roles.each{|r| rs << r }
		rs = @model.get_role_sequence(rs)
		mc = @mandatory_constraints[rs]

		# A UC that spans more than one Role of a fact will be a Preferred Id for the implied object
		#puts "Unique" + rs.to_s +
		#    (pi ? " (preferred id for #{pi.name})" : "") +
		#    (mc ? " (mandatory)" : "") if pi && !mc

		pc = PresenceConstraint.new(
				@model,
				name,
				rs,
				1, 1,
				mc,
				pi != nil
			    )
		(@constraints_by_rs[rs] ||= []) << pc
	    }
	end

	def read_exclusion_constraints
	    x_exclusion_constraints = @x_model.elements.to_a("orm:Constraints/orm:ExclusionConstraint")
	    x_exclusion_constraints.each{|x|
		name = x.attributes["Name"]
		x_mandatory = (m = x.elements.to_a("orm:ExclusiveOrMandatoryConstraint")[0]) &&
				@x_by_id[m.attributes['ref']]
		rss = []
		x.elements.to_a("orm:RoleSequences/orm:RoleSequence").each{|x_rs|
			rss << @model.get_role_sequence(RoleSequence.new(
				x_rs.elements.to_a("orm:Role").map{|xr|
					@by_id[xr.attributes['ref']]
				    }
			    ))
		    }
		ec = ExclusionConstraint.new(@model, name, rss)
	    }
	end

	def read_equality_constraints
	    x_equality_constraints = @x_model.elements.to_a("orm:Constraints/orm:EqualityConstraint")
	    x_equality_constraints.each{|x|
		name = x.attributes["Name"]
		rss = []
		x.elements.to_a("orm:RoleSequences/orm:RoleSequence").each{|x_rs|
			rss << @model.get_role_sequence(RoleSequence.new(
				x_rs.elements.to_a("orm:Role").map{|xr|
					@by_id[xr.attributes['ref']]
				    }
			    ))
		    }
		ec = EqualityConstraint.new(@model, name, rss)
	    }
	end

	def read_subset_constraints
	    x_subset_constraints = @x_model.elements.to_a("orm:Constraints/orm:SubsetConstraint")
	    x_subset_constraints.each{|x|
		name = x.attributes["Name"]
		rss = []
		x.elements.to_a("orm:RoleSequences/orm:RoleSequence").each{|x_rs|
			rss << @model.get_role_sequence(RoleSequence.new(
				x_rs.elements.to_a("orm:Role").map{|xr|
					@by_id[xr.attributes['ref']]
				    }
			    ))
		    }
		ec = SubsetConstraint.new(@model, name, *rss)
	    }
	end

	def read_ring_constraints
	    x_ring_constraints = @x_model.elements.to_a("orm:Constraints/orm:RingConstraint")
	    x_ring_constraints.each{|x|
		name = x.attributes["Name"]
		type = x.attributes["Type"]
		begin
		    # Convert the RingConstraint name to a number:
		    type_num = eval("::ActiveFacts::RingConstraint::#{type}") 
		rescue => e
		    throw "RingConstraint type #{type} isn't known"
		end

		rs = @model.get_role_sequence(RoleSequence.new(
			x.elements.to_a("orm:RoleSequence/orm:Role").map{|xr|
				@by_id[xr.attributes['ref']]
			    }
		    ))
		RingConstraint.new(@model, name, type_num, rs)
	    }
	end

	def read_value_constraints
	    x_value_constraints = @x_model.elements.to_a("orm:Constraints/orm:ValueConstraint")
	    x_value_constraints.each{|x|
		name = x.attributes["Name"]
		puts "REVISIT: ValueConstraint #{name} not loaded yet"
		puts x
	    }
	end

	def show_constraints_by_role_sequence
	    @constraints_by_rs.each_pair{|rs, ca|
		next if ca.size == 1
		puts "Constraints paired:"
		pp rs.to_s
		pp ca.map{|c| c.name }
	    }
	end

	def read_rest
	    puts "Reading Implied Facts (not yet)"
=begin
	    x_implied_facts = @x_model.elements.to_a("orm:Facts/orm:ImpliedFact")
	    pp x_implied_facts
=end
	    puts "Reading Data Types (not yet)"
=begin
	    x_datatypes = @x_model.elements.to_a("orm:DataTypes/*")
	    pp x_datatypes
=end
	    puts "Reading Reference Mode Kinds (not yet)"
=begin
	    x_refmodekinds = @x_model.elements.to_a("orm:ReferenceModeKinds/*")
	    pp x_refmodekinds
=end
	end
    end
end
