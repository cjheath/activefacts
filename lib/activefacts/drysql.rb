#
# $Id$
#
# ActiveFacts module that provides a class which can use ActiveRecord
# with DRYSql to reflect the schema of any database.
#
# DRYSql can't reflect foreign key constraints that have more than one
# field - I have a patch that fixes this for SQL Server, IBM DB2 and Oracle.
#
require "rubygems"
require "active_record"
require "drysql"	# N.B. to handle multi-part FKs, you need my drysql patch.
require "activefacts"

# Standard class extensions that are used only in diagostics below:
class SortedSet
    def join(s = "")
	to_a.join(s)
    end
end

class NilClass
    def join(s = "")
	""
    end
end

module ActiveFacts
    class DrySQL
	attr_reader :connection

	def self.load(arghash)
	    self.new(arghash).load_schema
	end

	def initialize(arghash)
	    @database = arghash[:dsn] || arghash[:database] || "unknown"

	    ActiveRecord::Base.establish_connection(arghash)
	    # ActiveRecord::Base.pluralize_table_names = false
	    # ActiveRecord::Base.primary_key_prefix_type = :table_name

	    @connection = ActiveRecord::Base.connection
	end

	def load_schema
	    puts "Loading database #{@database}"
	    @model = Model.new(@database)

	    # The process is as follows:
	    # 1) Create an EntityType for each table, and a FactType having
	    #    ET as its only Role.
	    # 2) All columns that aren't part of a foreign key are added to
	    #    this FactType as Roles of a ValueType.
	    #    The ValueTypes are instantiated progressively as we go along.
	    #	 Each uses a datatype created on first occurrence of each SQL
	    #	 Type, and a new VT is created for each distinct parameterised
	    #	 type. This might result in fewer VTs than needed; we use the
	    #	 column name for the Role where it differs from a prior usage
	    #	 of that VT.
	    #!!! Each not-null field also has a PresenceConstraint created for it.
	    # 3) All FKs are created as Roles of the referenced EntityType
	    # 4) PresenceConstraints are created for all unique/primary keys.
	    #    If an entity has UC but no PK, choose the first one as primary.
	    #    If no UC, create a PresenceConstraint over all roles.
	    #    Move the PK roles to the start of the fact
	    # 5) All columns that are part of a FK are added as Roles of the
	    #    same VT as the referenced table
	    # 5) Check constraints aren't processed yet, neither are triggers
	    #
	    @entity_types = {}
	    @fact_types = {}
	    @data_types = {}	    # Base data type
	    @value_types = {}	    # Named Data type with parameters defined
	    @entity_columns = {}
	    @entity_constraints = {}
	    puts "Phase 1, create EntityTypes, functional roles, simple UC/MCs"
	    @connection.tables.each{|table_name|
		puts "\t#{table_name}:"

		# Create an EntityType for each table:
		entity_type =
		    @entity_types[table_name] =
		    EntityType.new(@model, table_name)

		# Get all columns and constraints for each table:
		columns =
		    @entity_columns[table_name] =
		    @connection.columns(table_name)
		constraints =
		    @entity_constraints[table_name] =
		    @connection.constraints(table_name)

		fact_type =
		    @fact_types[table_name] =
		    FactType.new(
			@model,
			role = Role.new(@model, entity_type)
		    )

		# The EntityType role is mandatory here:
		PresenceConstraint.new(
			@model,
			"#{table_name.capitalize}Is#{table_name.capitalize}",
			[role],
			true,	# Must have...
			1, 1	# exactly one occurrence.
		    )

		# Ensure we have a datatype and valuetype for each column that
		# isn't an FK column.
		#
		# A given column name should only have one ValueType, but that
		# won't always be followed. We define a ValueType for the
		# first occurrence, and use the Role name for the column name.
		fk_columns = []
		columns.each{|c|

		    next if constraints.detect{|s|
			    case
			    when s.constraint_type != "FOREIGN KEY" then false
			    when s.table_name != table_name then false
			    when s.column_name.member?(c.name)
				# puts "\t\tColumn #{table_name}.#{c.name} is a FK, later"
				fk_columns << c
				true
			    else
				false
			    end
			}

		    puts "\t\t#{c.name}"
		    value_type = @value_types[c.sql_type] ||
			make_value_type(c.name, c.sql_type)

		    # REVISIT: Consider c.limit, c.scale, c.precision
		    fact_type.add_role(role = Role.new(@model, c.name, fact_type, value_type))

		    index = constraints.detect{|s|
			    # Does the column have a unique index?
			    next if s.constraint_type == "FOREIGN KEY"
			    s.column_name == SortedSet.new([c.name])
			}
		    if !c.null || index
			#p "#{table_name}.#{c.name} is mandatory" if !c.null
			#p "#{table_name}.#{c.name} is unique" if index

			constraint_name = (index && index.constraint_name) ||
			    "#{table_name.capitalize}MustHave#{c.name.capitalize}"
			puts "\t\tPresenceConstraint #{constraint_name}("+
			    [ c.null ? "optional" : "mandatory",
			      index ? "unique" : "non-unique",
			      index && index.constraint_type=="PRIMARY KEY" ?
				"primary" : nil
			    ].compact*", "+")"

			PresenceConstraint.new(
				@model,
				constraint_name,
				[role],		    # Fact population of Role
				!c.null,	    # must/may have
				1,		    # at least one
				index ? 1 : nil,    # at most one, or unlimited
				index && index.constraint_type=="PRIMARY KEY"
			    )
		    end
		}
	    }

	    puts "Phase 2, add EntityType roles (foreign keys)"
	    @connection.tables.each{|table_name|
		puts "\t#{table_name}:"

		columns = @entity_columns[table_name]
		constraints = @entity_constraints[table_name]
		fact_type = @fact_types[table_name]

		# Now add Roles for all tables referenced by foreign keys
		constraints.each{|s|
		    next if s.constraint_type != "FOREIGN KEY" ||
			    s.table_name != table_name
		    ref_table = @entity_types[refname = s.referenced_table_name]
		    throw "FK to unknown table #{refname}, #{s.inspect}" if (!ref_table)
		    puts "\t\t#{refname}(#{s.column_name.join(",")})"
		    fact_type.add_role(
			role = Role.new(@model, refname, fact_type, ref_table)
		    )
		}

		# Look for missed UC's (multi-part, or on FK's):
		constraints.each{|uc|
		    next if uc.constraint_type == "FOREIGN KEY"

		    fks = []
		    if (uc.column_name.size == 1)
			fks = constraints.select{|fk|   # not an FK column
				fk.constraint_type == "FOREIGN KEY" &&
				fk.table_name == table_name &&
				fk.column_name.member?(uc.column_name.entries[0])
			    }
			next if (fks.size == 0)
		    end

		    # add remaining UCs here:
		    puts "\t\tREVISIT: unique #{uc.constraint_name}(#{uc.column_name.entries*", "})"

#		    PresenceConstraint.new(
#			    @model,
#			    constraint_name,
#			    1,	    # at least one
#			    uc,	    # at most one, or unlimited
#			    uc.constraint_type=="PRIMARY KEY"
#			)

		}

	    }

	    @model
	end

	def make_value_type(name, vtype)
	    vtparams = vtype.split(/\D+/).reject{|v| v==""}.map(&:to_i)
	    dtname = vtype.sub(/\W.*/,'')

	    #puts "Making base DataType #{dtname}" if !@data_types[dtname]
	    base_type =
	    data_type =
		@data_types[dtname] ||= DataType.new(
		    @model,
		    dtname
		)

	    if (vtype != dtname)
		# puts "Making refined DataType #{vtype}" if !@data_types[vtype]
		data_type =
		    @data_types[vtype] ||= DataType.new(
			@model,
			name,    # here's where a name might be mis-associated
			base_type,
			*vtparams
		    )
	    end

	    # puts "Making ValueType(model, #{name}, #{dtname})"
	    @value_types[vtype] = ValueType.new(
		    @model,
		    name,
		    data_type
		)
	end
    end
end
