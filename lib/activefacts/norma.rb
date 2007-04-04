require 'rexml/document'
require 'activefacts/base'

module ActiveFacts
    class Norma
	def self.read(filename)
	    begin
		file = File.new(filename)
		doc = REXML::Document.new(file)
	    rescue => e
		puts "Failure in reading #{filename}: #{e.inspect}"
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

	def self.read_model
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
	    scan_fact_types
	    read_nested_types
	    read_roles
	    read_constraints
	end

	def self.read_entity_types
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
		# x.attributes['_ReferenceMode'] is implied.

		# REVISIT: deal with PreferredIdentifier
		# pp x.elements.to_a('*')
	    }
	end

	def self.read_value_types
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
		data_type = DataType.new(base_type.name.sub(/^orm:/,''))
		data_type.length = length
		data_type.scale = scale

		# puts "ValueType #{name} is #{id}"
		value_types <<
		    @by_id[id] = ValueType.new(@model, name, data_type)
	    }
	end

	def self.scan_fact_types
	    # Handle the fact types:
	    facts = []
	    @x_facts = @x_model.elements.to_a("orm:Facts/orm:Fact")
	    @x_facts.each{|x|
		id = x.attributes['id']
		name = x.attributes['Name'] || x.attributes['_Name']
		name = nil if name.size == 0
		# puts "FactType #{name || id}"

		facts << @by_id[id] = fact_type = FactType.new(name)
	    }
	end

	def self.read_nested_types
	    # Process NestedTypes, but ignore ones having an NestedPredicate with IsImplied="true"
	    nested_types = []
	    x_nested_types = @x_model.elements.to_a("orm:Objects/orm:NestedType")
	    x_nested_types.each{|x|
		id = x.attributes['id']
		name = x.attributes['Name'] || ""
		name = nil if name.size == 0

		x_fact_type = x.elements.to_a('orm:NestedPredicate')[0]
		is_implied = x_fact_type.attributes['IsImplied'] == "true"

		# puts "NestedType #{name} is #{id}, is_implied=#{is_implied}"
		next if is_implied

		nested_types <<
		    @by_id[id] =
		    nested_type = NestedType.new(@model, name)

		fact_id = x_fact_type.attributes['ref']
		fact_type = @by_id[fact_id]
		throw "Nested fact #{fact_id} not found" if !fact_type

		# puts "nested_type: #{nested_type.name} nests #{fact_type.name}"
		nested_type.fact_type = fact_type

		# REVISIT: deal with PreferredIdentifier
	    }
	end

	def self.read_roles
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

		    # puts "\tRole "+(name||id)+" played by "+object_type.name
		    role = @by_id[id] = Role.new(x.attributes['Name'], object_type)
		    fact_type.add_role(role)
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

		# REVISIT: deal with InternalConstraints
	    }
	end

	def self.read_constraints
	    @constraints_by_rs = {}

	    x_mandatory_constraints = @x_model.elements.to_a("orm:Constraints/orm:MandatoryConstraint")
	    mandatory_constraints = {}
	    x_mandatory_constraints.each{|x|
		    x_roles = x.elements.to_a("orm:RoleSequence/orm:Role")
		    roles = x_roles.map{|x| @by_id[x.attributes['ref']] }
		    # We didn't make Implied objects, so some constraints are unconnectable
		    next if roles.include? nil
		    rs = RoleSequence.new
		    roles.each{|r| rs << r }
		    rs = @model.get_role_sequence(rs)

puts "Mandatory("+roles.map{|r|
	"#{r.object_type.name} in #{r.fact_type.to_s}"
    }*", "+")"

		    mandatory_constraints[rs] = true
	    }

	    x_uniqueness_constraints = @x_model.elements.to_a("orm:Constraints/orm:UniquenessConstraint")
	    x_constraints = @x_model.elements.to_a("orm:Constraints/*")
	    x_constraints.each{|x|
		constraint_name = x.attributes['Name']
		case x.name
		when 'UniquenessConstraint'
		    x_pi = x.elements.to_a("orm:PreferredIdentifierFor")
		    x_pi = x_pi.size > 0 ? x_pi[0] : nil
		    pi = x_pi ? @by_id[x_pi.attributes['ref']] : nil

		    # Skip uniqueness constraints on implied object types
		    next if x_pi && !pi

		    # Get the RoleSequence:
		    x_roles = x.elements.to_a("orm:RoleSequence/orm:Role")
		    roles = x_roles.map{|x| @by_id[x.attributes['ref']] }
		    # We didn't make Implied objects, so some constraints are unconnectable
		    next if roles.include? nil
		    rs = RoleSequence.new
		    roles.each{|r| rs << r }
		    rs = @model.get_role_sequence(rs)

		    pc = PresenceConstraint.new(
				    constraint_name,
				    rs,
				    1, 1,
				    mandatory_constraints[rs] || pi != nil,
				    pi != nil
				)
		    (@constraints_by_rs[rs] ||= []) << pc

		    # puts pc.to_s
		    @model.constraints << pc

		when 'MandatoryConstraint'
		when 'ValueConstraint'
		end
	    }
	    @constraints_by_rs.each_pair{|rs, ca|
		next if ca.size == 1
		puts "Constraints paired:"
		pp rs.map{|r| r.to_s}
		pp ca.map{|c| c.name }
	    }

=begin
	    x_implied_facts = @x_model.elements.to_a("orm:Facts/orm:ImpliedFact")
	    pp x_implied_facts
	    x_datatypes = @x_model.elements.to_a("orm:DataTypes/*")
	    pp x_datatypes
	    x_refmodekinds = @x_model.elements.to_a("orm:ReferenceModeKinds/*")
	    pp x_refmodekinds
=end
	end
    end
end
