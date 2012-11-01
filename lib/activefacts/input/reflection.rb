#
#       ActiveFacts Vocabulary Input.
#       Create an ActiveFacts vocabulary by reverse engineering the schema of any database.
#       Currently doesn't work.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# Uses ActiveRecord with DRYSql.
# DRYSql can't reflect foreign key constraints that have more than one
# field - I have a patch that fixes this for SQL Server, IBM DB2 and Oracle.
#
require "rubygems"
require "active_record"
require "drysql"  # N.B. to handle multi-part FKs, you need my drysql patch.
require "activefacts"

module ActiveFacts
  module Input
    # Reverse-engineer a database schema to an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --<connection_string> <file>.orm
    # This input method is stale and no longer works
    class Reflector
    private
      class LogNull; def puts(*args); end; end  # A null logger
      attr_reader :database       # Name of the database we're reversing
      attr_reader :connection       # The ActiveRecord connection
      attr_reader :vocabulary       # This is what we're building
      attr_reader :entity_types     # A hash by table name
      attr_reader :fact_types       # A hash by table name
      attr_reader :base_value_types       # By name, e.g. "bit", "char(128)"
      attr_reader :value_types      # By field name
      attr_reader :entity_columns     # A hash by table name yielding array
      attr_reader :entity_constraints   # A hash by table name yielding array

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
        @vocabulary = Vocabulary.new(@database)

        # The process is as follows:
        #
        # Phase 1:
        # a) Create a FactType and an ObjectifiedEntityType for each table.
        #
        # b) All columns that aren't part of a foreign key are added to
        #  this FactType as Roles of a ValueType.
        #
        #  The ValueTypes are instantiated progressively as we go along.
        #  Each uses a base valuetype created on first occurrence of each SQL
        #  Type, and a new VT is created for each distinct parameterised
        #  type. This might result in fewer VTs than needed; we use the
        #  column name for the Role where it differs from a prior usage
        #  of that VT. Each not-null field also has a PresenceConstraint
        #  created for it, which means also checking for unique constraints
        #  over that field also
        #
        # Phase 2:
        # a) All FKs are created as Roles of the referenced EntityType
        #
        # b) PresenceConstraints are created for remaining unique/primary keys.
        #  If an entity has UC but no PK, choose the first one as primary.
        #  (Move the PK roles to the start of the fact - not yet)
        #
        # Incomplete:
        # * Columns that are part of a FK need to be added as implied
        # Roles of the same VT as the PK column in the referenced table,
        # if the original FK field names are to be known (for queries).
        # * Not sure how to handle FK's referencing columns of non-PK UCs.
        # Both the column names and the matching column names are needed.
        # * Check constraints aren't processed yet, neither are triggers
        # * There's no attempt to deduce subtyping or reduce to elementary
        # form - those are left for a separate module to do afterwards.
        #
        @entity_types = {}
        @fact_types = {}
        @base_value_types = {}    # Base value type
        @value_types = {}   # Named value type with parameters defined
        @entity_columns = {}
        @entity_constraints = {}

        phase1
        phase2

        @vocabulary
      end

      def phase1
        @log.puts "Phase 1, create EntityTypes, functional roles, simple UC/MCs"

        @connection.tables.each{|table_name|
          make_fact_with_simple_roles(table_name)
        }
      end

      def phase2
        @log.puts "Phase 2, add EntityType roles (foreign keys)"
        @connection.tables.each{|table_name|
          add_roles_from_fks(table_name)
          add_remaining_unique_constraints(table_name)
        }
      end

      def make_fact_with_simple_roles(table_name)
        @log.puts "\t#{table_name}:"

        # Get all columns and constraints for each table:
        columns =
          @entity_columns[table_name] =
          @connection.columns(table_name)
        constraints =
          @entity_constraints[table_name] =
          @connection.constraints(table_name)

        # Create a NestedType (objectified fact) for each table:
        fact_type =
          @fact_types[table_name] =
          FactType.new(@vocabulary, table_name)
        entity_type =
          @entity_types[table_name] =
          NestedType.new(@vocabulary, table_name, fact_type)

        columns.each{|c|
          add_column_if_simple(entity_type, fact_type, table_name, c, constraints)
        }
      end

      # If the column c isn't part of a foreign key, add it as a simple role:
      def add_column_if_simple(entity_type, fact_type, table_name, c, constraints)
        return if constraints.detect{|s|
            case
            when s.constraint_type != "FOREIGN KEY" then false
            when s.table_name != table_name then false
            when s.column_name.member?(c.name)
              # @log.puts "\t\tColumn #{table_name}.#{c.name} is a FK, later"
              true
            else
              false
            end
          }

        # Ensure we have a base valuetype and valuetype for each column that
        # isn't an FK column.
        #
        # A given column name should only have one ValueType, but that
        # won't always be followed. We define a ValueType for the
        # first occurrence of a given refined-type, and use the Role
        # name for the column name.

        # See if there's a ValueType of the same base ValueType and Name already
        value_type = @value_types[c.sql_type]
        if (new_type = (!value_type || value_type.name != c.name))
          value_type = make_value_type(c.name, c.sql_type)
        end
        @log.puts "\t\tTo #{fact_type.name}, adding role #{c.name}" +
          " of#{new_type ? " new" : " existing"} #{value_type}"

        # Add the Role to the fact type:
        role = Role.new(@vocabulary, c.name, fact_type, value_type)
        @log.puts "\t\t#{role.to_s}"
        fact_type.add_role(role)

        # Create a PresenceConstraint on mandatory fields, or where
        # a unique index exists over just this one field.

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
              @vocabulary,
              constraint_name,
              rs,         # Fact population of Role
              !c.null,      # must/may have
              1,          # at least one
              index ? 1 : nil,  # at most one, or unlimited
              index && index.constraint_type=="PRIMARY KEY"
            )
          @log.puts "\t\t" + pc.to_s
        end
      end

      # Deduce roles implied by foreign keys
      def add_roles_from_fks(table_name)
        @log.puts "\t#{table_name}, adding roles from foreign keys:"

        columns = @entity_columns[table_name]
        constraints = @entity_constraints[table_name]
        fact_type = @fact_types[table_name]

        # Add Roles for all tables referenced by foreign keys from here
        @fk_by_assigned_role_name = {}
        @assigned_role_name_by_fk = {}
        constraints.each{|fk|
          next if fk.constraint_type != "FOREIGN KEY" ||
              fk.table_name != table_name

          role_name, ref_table = *fk_role_name(fk)

          fact_type.add_role(
            role = Role.new(@vocabulary, role_name, fact_type, ref_table)
          )
          @log.puts "\t\t#{role.to_s}"
        }
      end

      def add_remaining_unique_constraints(table_name)
        @log.puts "\t#{table_name}, adding remaining unique constraints:"

        columns = @entity_columns[table_name]
        constraints = @entity_constraints[table_name]
        fact_type = @fact_types[table_name]

        # Look for missed UC's (multi-part, or on FK's):
        constraints.each{|uc|
          next if uc.constraint_type == "FOREIGN KEY"

          constraint_name = uc.constraint_name
          colnames = uc.column_name.clone
          non_fk_colnames = colnames.clone
          primary = uc.constraint_type=="PRIMARY KEY" ? true : nil

          # Check whether any column of the UC is optional:
          mandatory = true
          colnames.entries.each{|c|
            next unless columns.detect{|l| l.name == c }.null
            mandatory = nil
          }

          # Find all FKs that have a column in the key, and partition the names:
          fks = constraints.select{|fk| # not an FK column
              next if fk.constraint_type != "FOREIGN KEY"
              next if fk.table_name != table_name

              # Calculate the residual non-FK fields:
              non_fk_colnames -= fk.column_name

              # The FK is included if any of its columns are:
              relevant = colnames.intersection(fk.column_name) == fk.column_name
              if (relevant != (colnames.intersection(fk.column_name).size > 0))
                # Odd, but possible situation, report it:
                @log.puts "UC #{uc.constraint_name} includes only some of FK #{fk.constraint_name}"
              end

              relevant
            }

          # Some constraints have already been processed:
          next if (uc.column_name.size == 1 && fks.size == 0)

          # Say what we're doing:
          @log.puts "\t\t#{primary ?"primary":"unique"} key #{uc.constraint_name} over (#{colnames.entries*", "})"
          @log.puts "\t\t\t#{constraint_name} includes optional columns" if !mandatory
          @log.puts "\t\t\t#{constraint_name} includes fks (#{fks.map{|f| f.constraint_name}*","}) and non-fk columns (#{non_fk_colnames.entries*", "})"

          roles = RoleSequence.new
          fks.each{|fk|
            role_name, junk = *fk_role_name(fk)
            role = fact_type.role_by_name(role_name)
            roles << role
          }
          non_fk_colnames.each{|c|
            role = fact_type.role_by_name(c)
            throw "Role #{c} in #{fact_type} not found when adding #{primary ?"primary":"unique"} constraint #{uc.constraint_name}" if !role
            roles << role
          }

          pc = PresenceConstraint.new(
              @vocabulary,
              constraint_name,
              roles,
              mandatory,
              1,      # at least one, but maybe optional
              1,      # at most one
              primary
            )
          @log.puts "\t\t" + pc.to_s
        }
      end

      def make_value_type(name, vtype)
        # REVISIT: Consider using c.limit, c.scale, c.precision instead:
        vtparams = vtype.split(/\D+/).reject{|v| v==""}.map{|v| v.to_i}
        bvtname = vtype.sub(/\W.*/,'')

        @log.puts "\t\tMaking base ValueType #{bvtname}" if !@base_value_types[bvtname]
        base_type =
        base_value_type =
          @base_value_types[bvtname] ||= ValueType.new(
            @vocabulary,
            bvtname
          )

        if (vtype != bvtname)
          @log.puts "\t\tMaking refined ValueType #{vtype}" if !@base_value_types[vtype]
          base_value_type =
            @base_value_types[vtype] ||= ValueType.new(
              @vocabulary,
              vtype,
              base_type,
              *vtparams
            )
        end

        # @log.puts "Making ValueType(vocabulary, #{name}, :guid => :new)"
        @value_types[vtype] = ValueType.new(
            @vocabulary,
            name,
            :supertype => base_value_type,
            :guid => :new
          )
      end

      # A Foreign Key becomes a role that needs a name.
      # The referenced Entity Type name is the default if we return an empty name,
      # however, there may be more than one reference to the same ET.
      # We could use the column name, if there's only one.
      def fk_role_name(fk)
        table_name = fk.referenced_table_name
        ref_table = @entity_types[table_name]
        ref_constraints = @entity_constraints[table_name]
        throw "FK to unknown table #{fk.referenced_table_name}, #{fk.inspect}" if (!ref_table)

        # Already mapped this one?
        role_name = @assigned_role_name_by_fk[fk]
        return [role_name, ref_table] if role_name

        # If the FK has columns whose names correspond to the names
        # of columns of a UC on the referenced table (modulo possible
        # use of the table name as prefix or suffix?), name the Role
        # the same as the name of the referenced table, assuming
        # that hasn't already been done for another FK. Otherwise,
        # concatenate the column names of the FK (removing the table
        # name if it occurs as a suffix?) and use that.

        #puts "Matching FK #{fk.constraint_name} from #{fk.table_name} to #{table_name}"
        names = fk.column_name.entries
        rnames = fk.referenced_column_name.entries
        #puts "\tColumn names are #{names.inspect} -> #{rnames.inspect}"
        role_name = ""
        !names.zip(rnames).each{|pair|
            name, rname = *pair

            # Often a PK will be called TableNameID. We remove the ID.
            trailer = rname.sub(/\A#{table_name}/,'')

            truncated = name.
              gsub(/_/,'').       # Remove all underscores
              sub(/#{rname}\Z/i,'').    # Remove trailing column_name
              sub(/\A#{table_name}/i,''). # Remove leading table_name
              sub(/#{table_name}\Z/i,''). # Remove trailing table_name
              sub(/#{trailer}/i,'').    # Remove the PK trailer
              sub(/\Aid\Z/i,'').      # Remove ID if that's all that's left
              sub(/([a-z])I[Dd]\Z/,'\1')  # Remove ID if that's all that's left
            #puts "\tTruncating #{name} by removing #{rname}, #{table_name}, #{trailer}, yielding #{truncated}"
            role_name += truncated
          }

        if (role_name == '')
          role_name = table_name
        else
          # No match found, use the residual
          @log.puts "\t\tIn FK #{fk.constraint_name}, the residual role_name is #{role_name}"

          # Check for duplicates:
          if ((f = @fk_by_assigned_role_name[role_name]) && f != fk)
            @log.puts "\t\tBut that yields a duplicate FK #{role_name} from #{fk.table_name} to #{fk.referenced_table_name} (now #{fk.constraint_name}, was #{f.constraint_name}"
            role_name = names*""
            @log.puts "\t\tUsing #{role_name} (FK column names) instead"
          end
        end

        @assigned_role_name_by_fk[fk] = role_name
        @fk_by_assigned_role_name[role_name] = fk

        [role_name, ref_table]
      end
    end
  end
end
