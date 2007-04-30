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
require "drysql"    # N.B. to handle multi-part FKs, you need my drysql patch.
require "activefacts"

module ActiveFacts
    class Reflector
	class LogNull; def puts(*args); end; end
	attr_reader :connection

	def self.load(arghash)
	    self.new(arghash).load_schema
	end

	def initialize(arghash, logfile = nil)
	    @log = logfile || LogNull.new

	    @database = arghash[:dsn] || arghash[:database] || "unknown"

	    ActiveRecord::Base.establish_connection(arghash)
	    # ActiveRecord::Base.pluralize_table_names = false
	    # ActiveRecord::Base.primary_key_prefix_type = :table_name

	    @connection = ActiveRecord::Base.connection
	end

	def load_schema
	    @log.puts "Loading database #{@database}"
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
	    @log.puts "Phase 1, create EntityTypes, functional roles, simple UC/MCs"
	    @connection.tables.each{|table_name|
		@log.puts "\t#{table_name}:"

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
			role = Role.new(@model, entity_type),
			table_name
		    )

		# The EntityType role is mandatory here:
		PresenceConstraint.new(
			@model,
			"#{table_name.capitalize}Is#{table_name.capitalize}",
			RoleSequence.new([role]),
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
				# @log.puts "\t\tColumn #{table_name}.#{c.name} is a FK, later"
				fk_columns << c
				true
			    else
				false
			    end
			}

		    value_type = @value_types[c.sql_type]
		    if (new_type = (!value_type || value_type.name != c.name))
			value_type = make_value_type(c.name, c.sql_type)
		    end

#		    @log.puts "\t\tTo #{fact_type.name}, adding Role #{c.name}" +
#			" of#{new_type ? " new" : " existing"} #{value_type.name}"
		    role = Role.new(@model, c.name, fact_type, value_type)
		    @log.puts "\t\t#{role.to_s}"
		    fact_type.add_role(role)

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

			primary = index &&
			    (index.constraint_type=="PRIMARY KEY" ? true : nil)

			rs = RoleSequence.new([role])
			pc = PresenceConstraint.new(
				@model,
				constraint_name,
				rs,		    # Fact population of Role
				!c.null,	    # must/may have
				1,		    # at least one
				index ? 1 : nil,    # at most one, or unlimited
				index && index.constraint_type=="PRIMARY KEY"
			    )
			@log.puts "\t\t" + pc.to_s

#			@log.puts "\t\t" +
#			    (c.null ? "optional " : "mandatory ") +
#			    (index ? "unique " : "non-unique ") +
#			    (primary ? "primary " : "") +
#			    "PresenceConstraint #{constraint_name}: " +
#			    RoleSequence.new([role]).to_s
		    end
		}
	    }

	    @log.puts "Phase 2, add EntityType roles (foreign keys)"
	    @connection.tables.each{|table_name|
		@log.puts "\t#{table_name}:"

		columns = @entity_columns[table_name]
		constraints = @entity_constraints[table_name]
		fact_type = @fact_types[table_name]

		# Now add Roles for all tables referenced by foreign keys
		@fk_names = {}
		constraints.each{|fk|
		    next if fk.constraint_type != "FOREIGN KEY" ||
			    fk.table_name != table_name

		    role_name, ref_table = *fk_role_name(fk)

		    fact_type.add_role(
			role = Role.new(@model, role_name, fact_type, ref_table)
		    )
		    @log.puts "\t\t#{role.to_s}"
		}

		# Look for missed UC's (multi-part, or on FK's):
		constraints.each{|uc|
		    next if uc.constraint_type == "FOREIGN KEY"

		    constraint_name = uc.constraint_name
		    colnames = uc.column_name.clone
		    non_fk_colnames = colnames.clone
		    #p (colnames.methods-Object.instance_methods).sort

		    mandatory = true
		    colnames.entries.each{|c|
			next unless columns.detect{|l| l.name == c }.null
			mandatory = nil
		    }

		    # Find all FKs that have a column in the key:
		    fks = constraints.select{|fk|   # not an FK column
			    next if fk.constraint_type != "FOREIGN KEY"
			    next if fk.table_name != table_name

			    non_fk_colnames -= fk.column_name
			    colnames - fk.column_name != colnames
			}

		    # Some constraints have already been processed:
		    next if (uc.column_name.size == 1 && fks.size == 0)

		    roles = RoleSequence.new
		    fks.each{|fk|
			role_name, table_name = *fk_role_name(fk)
			role = fact_type.role_by_name(role_name)
			roles << role
		    }
		    non_fk_colnames.each{|c|
			role = fact_type.role_by_name(c)
			roles << role
		    }

		    primary = uc.constraint_type=="PRIMARY KEY" ? true : nil

		    pc = PresenceConstraint.new(
			    @model,
			    constraint_name,
			    roles,
			    mandatory,
			    1,	    # at least one, but maybe optional
			    1,	    # at most one
			    primary
			)
		    @log.puts "\t\t" + pc.to_s

#		    @log.puts "\t\t" +
#			(mandatory ? "mandatory " : "optional ") +
#			"unique " +
#			(primary ? "primary " : "") +
#			"PresenceConstraint #{constraint_name}: " +
#			roles.to_s
		}

	    }

	    @model
	end

	def make_value_type(name, vtype)
	    # REVISIT: Consider c.limit, c.scale, c.precision instead:
	    vtparams = vtype.split(/\D+/).reject{|v| v==""}.map(&:to_i)
	    dtname = vtype.sub(/\W.*/,'')

	    @log.puts "\t\tMaking base DataType #{dtname}" if !@data_types[dtname]
	    base_type =
	    data_type =
		@data_types[dtname] ||= DataType.new(
		    @model,
		    dtname
		)

	    if (vtype != dtname)
		@log.puts "\t\tMaking refined DataType #{vtype}" if !@data_types[vtype]
		data_type =
		    @data_types[vtype] ||= DataType.new(
			@model,
			vtype,
			base_type,
			*vtparams
		    )
	    end

	    # @log.puts "Making ValueType(model, #{name}, #{dtname})"
	    @value_types[vtype] = ValueType.new(
		    @model,
		    name,
		    data_type
		)
	end

	def fk_role_name(fk)
	    role_name = fk.referenced_table_name
	    ref_table = @entity_types[role_name]
	    throw "FK to unknown table #{role_name}, #{fk.inspect}" if (!ref_table)
	    # Already mapped this one?
	    return [role_name, ref_table] if @fk_names[role_name]

	    # If the FK has columns whose names correspond to the names
	    # of columns of a UC on the referenced table, name the Role
	    # the same as the name of the referenced table, assuming
	    # that hasn't alread been done. Otherwise, concatenate the
	    # column names of the FK and use that.
	    ref_constraints = @entity_constraints[fk.referenced_table_name]
	    if !ref_constraints.detect{|rc|
		    next if rc.constraint_type == "FOREIGN KEY"
		    # Consider a smarter match here.
		    # For example, if the TableName is a prefix or suffix, crop
		    fk.column_name == rc.column_name
		}
		# No matching UC found. Create a name (crop again?):
		role_name = fk.column_name.entries.join
		# @log.puts "Using column-sequence #{role_name} for #{fk.constraint_name}" if fk.column_name.entries.size > 1

		if ((f = @fk_names[role_name]) && f != fk)
		    throw "Identical FK #{role_name} from #{fk.table_name} to #{fk.referenced_table_name} twice (now #{fk.constraint_name}, was #{@fk_names[role_name].constraint_name}"
		end
	    end

	    @fk_names[role_name] = fk

	    [role_name, ref_table]
	end
    end
end
