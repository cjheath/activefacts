#
#       Data Vault Transform
#       Transform a loaded ActiveFacts vocabulary to suit Data Vault
#
# Copyright (c) 2015 Infinuendo. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/persistence'

require 'activefacts/generate/traits/datavault'

module ActiveFacts

  module Generate #:nodoc:
    module Transform #:nodoc:
      class DataVault
	def initialize(vocabulary, *options)
	  @vocabulary = vocabulary
	  @constellation = vocabulary.constellation
	end

	def classify_tables
	  initial_tables = @vocabulary.tables
	  non_reference_tables = initial_tables.reject do |table|
	    table.concept.all_concept_annotation.detect{|ca| ca.mapping_annotation == 'static'} or
	      !table.is_a?(ActiveFacts::Metamodel::EntityType)
	  end
	  @reference_tables = initial_tables-non_reference_tables

	  @link_tables, @hub_tables = non_reference_tables.partition do |table|
	    identifying_references = table.identifier_columns.map{|c| c.references.first}.uniq
	    # Which identifying_references are played by other tables?
	    ir_tables =
	      identifying_references.select do |r|
		table_referred_to = r.to
		# I have no examples of multi-level absorption, but it's possible, so loop
		while av = table_referred_to.absorbed_via
		  table_referred_to = av.from
		end
		table_referred_to.is_table
	      end
	    ir_tables.size > 1
	  end
	  trace_table_classifications
	end

	def trace_table_classifications
	  # Trace the decisions about table types:
	  if trace :datavault
	    [@reference_tables, @hub_tables, @link_tables].zip(['Reference', 'Hub', 'Link']).each do |tables, kind|
	      trace :datavault, kind+' tables: ' do
		tables.each do |table|
		  identifying_references = table.identifier_columns.map{|c| c.references.first}.uniq
		  trace :datavault, "#{table.name}(#{identifying_references.map{|r| (t = r.to) && t.name || 'self'}*', '})"
		end
	      end
	    end
	  end
	end

	def detect_required_surrogates
	  trace :datavault, "Detecting required surrogates" do
	    @required_surrogates =
	      (@hub_tables+@link_tables).select do |table|
		table.dv_needs_surrogate
	      end
	  end
	end

	def inject_required_surrogates
	  trace :datavault, "Injecting any required surrogates" do
	    trace :datavault, "Need to inject surrogates into #{@required_surrogates.map(&:name)*', '}"
	    @required_surrogates.each do |table|
	      table.dv_inject_surrogate
	    end
	  end
	end

	def classify_satellite_references table
	  identifying_references = table.identifier_columns.map{|c| c.references.first}.uniq
	  non_identifying_references = table.columns.map{|c| c.references[0]}.uniq - identifying_references

	  # Skip this table if no satellite data is needed
	  # REVISIT: Needed anyway for a link?
	  if non_identifying_references.size == 0
	    return nil
	  end

	  satellites = non_identifying_references.inject({}) do |hash, ref|
	      satellite_name =
		ref.fact_type.internal_presence_constraints.map do |pc|
		  next if !pc.max_frequency || pc.max_frequency > 1 # Not a Uniqueness Constraint
		  next if pc.role_sequence.all_role_ref.size > 1    # Covers more than one role
		  next if pc.role_sequence.all_role_ref.single.role.object_type != table  # Not a unique attribute
		  pc.concept.all_concept_annotation.map do |ca|
		    if ca.mapping_annotation =~ /^satellite */
		      ca.mapping_annotation.sub(/^satellite +/, '')
		    else
		      nil
		    end
		  end
		end.flatten.compact.uniq[0] || 'satellite'
	      (hash[satellite_name] ||= []) << ref
	      hash
	    end
	  # trace :datavault, "#{table.name} satellites are #{satellites.inspect}"
	  satellites
	end

	def create_one_to_many(table, satellite, predicate_1 = 'has', predicate_2 = 'is of')
	  # Create a fact type
	  fact_type = @constellation.FactType(:concept => :new)
	  table_role = @constellation.Role(:concept => :new, :fact_type => fact_type, :ordinal => 0, :object_type => table)
	  sat_role = @constellation.Role(:concept => :new, :fact_type => fact_type, :ordinal => 1, :object_type => satellite)

	  # Create two readings
	  reading1 = @constellation.Reading(:fact_type => fact_type, :ordinal => 0, :role_sequence => [:new], :text => "{0} #{predicate_1} {1}")
	  @constellation.RoleRef(:role_sequence => reading1.role_sequence, :ordinal => 0, :role => table_role)
	  @constellation.RoleRef(:role_sequence => reading1.role_sequence, :ordinal => 1, :role => sat_role)
	  reading2 = @constellation.Reading(:fact_type => fact_type, :ordinal => 1, :role_sequence => [:new], :text => "{0} #{predicate_2} {1}")
	  @constellation.RoleRef(:role_sequence => reading2.role_sequence, :ordinal => 0, :role => sat_role)
	  @constellation.RoleRef(:role_sequence => reading2.role_sequence, :ordinal => 1, :role => table_role)

	  one_id = @constellation.PresenceConstraint(
	      :concept => :new,
	      :vocabulary => @vocabulary,
	      :name => table.name+'HasOne'+satellite.name,
	      :role_sequence => [:new],
	      :is_mandatory => true,
	      :min_frequency => 1,
	      :max_frequency => 1,
	      :is_preferred_identifier => false
	    )
	  @constellation.RoleRef(:role_sequence => one_id.role_sequence, :ordinal => 0, :role => sat_role)
	  table_role
	end

	def add_datetime table
	  # Add a new fact where this table has a new DateTime field
	  type_name = 'Date Time'
	  datetime = @constellation.ValueType(:vocabulary => @vocabulary, :name => type_name, :concept => :new)

	  datetime
	end

	# Create a PresenceConstraint with two roles, marked as preferred_identifier
	def create_two_role_identifier(r1, r2)
	  pc = @constellation.PresenceConstraint(
	      :concept => :new,
	      :vocabulary => @vocabulary,
	      :name => r1.object_type.name+' '+r1.object_type.name+'PK',
	      :role_sequence => [:new],
	      :is_mandatory => true,
	      :min_frequency => 1,
	      :max_frequency => 1,
	      :is_preferred_identifier => true
	    )
	  @constellation.RoleRef(:role_sequence => pc.role_sequence, :ordinal => 0, :role => r1)
	  @constellation.RoleRef(:role_sequence => pc.role_sequence, :ordinal => 1, :role => r2)
	end

	def create_satellite(table, satellite_name, references)
	  satellite_name = satellite_name.words.titlewords*' '
	  trace :datavault, "Creating #{satellite_name} for #{table.name} with #{references.size} references" do
	    # Create a new entity type with record-date fields in its identifier

	    satellite = @constellation.EntityType(:vocabulary => @vocabulary, :name => "#{table.name} #{satellite_name}", :concept => [:new, :implication_rule => "datavault"])
	    satellite.definitely_table

	    date_time = add_datetime(satellite)
	    table_role = create_one_to_many(table, satellite)
	    date_time_role = create_one_to_many(date_time, satellite, 'is of', 'was loaded at')
	    create_two_role_identifier(table_role, date_time_role)

	    # Move all roles across to it from the parent table.
	    references.each do |ref|
	      trace :datavault, "Moving #{ref} across to #{table.name}_#{satellite_name}" do
		table_role = ref.fact_type.all_role.detect{|r| r.object_type == table}
		# Reassign the role player to the satellite:
		if table_role
		  table_role.object_type = satellite
		else
		  #debugger  # Bum, the crappy Reference object bites again.
		  puts "REVISIT: Can't move this role across without mangling the Reference. Later, doodz!"
		end
	      end
	    end
	  end
	end

	def generate(out = $stdout)
	  @out = out

	  # Strategy:
	  # Determine list of ER tables
	  # Partition tables into reference tables (annotated), link tables (two+ FKs in PK), and hub tables
	  # For each hub and link table
	  #   Apply a surrogate key if needed (all links, hubs lacking a simple surrogate)
	  #   Detect references (fact types) leading to all attributes (non-identifying columns)
	  #   Group attribute facts into satellites (use the satellite annotation if present)
	  #   For each satellite
	  #	Create a new entity type with a (hub-key, record-date key)
	  #	Make new one->many fact type between hub and satellite
	  #	Modify all attribute facts in this group to attach to the satellite
	  # Compute a gresh relational mapping
	  # Exclude reference tables and disable enforcement to them

	  classify_tables

	  detect_required_surrogates

	  trace :datavault, "Creating satellites" do
	    (@hub_tables+@link_tables).each do |table|
	      satellites = classify_satellite_references table
	      next unless satellites

	      trace :datavault, "Creating #{satellites.size} satellites for #{table.name}" do
		satellites.each do |satellite_name, references|
		  create_satellite(table, satellite_name, references)
		end
	      end
	    end
	  end

	  inject_required_surrogates

	  # Now, redo the E-R mapping using the revised schema:
          @vocabulary.decide_tables

	  # Before departing, ensure we don't emit the reference tables!
	  @reference_tables.each do |table|
	    table.definitely_not_table
	  end

	end # generate

      end
    end
  end
end

ActiveFacts::Registry.generator('transform/datavault', ActiveFacts::Generate::Transform::DataVault)
