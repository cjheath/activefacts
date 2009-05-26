#
#       ActiveFacts Generators.
#       Generate SQL for MySQL from an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Daniel Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    class SQL #:nodoc:
      # Generate SQL for MySQL for an ActiveFacts vocabulary.
      # Invoke as
      #   afgen --sql/mysql[=options] <file>.cql
      # Options are comma or space separated:
      # * delay_fks Leave all foreign keys until the end, not just those that contain forward-references
      # * norma Translate valuetypes from NORMA to SQL Server
      class MYSQL
      private
        include Persistence
        ColumnNameMax = 63
        DefaultCharColLength = 63

        RESERVED_WORDS = %w{
          ACCESSIBLE ADD ALL ALTER ANALYZE AND AS ASC ASENSITIVE
          BEFORE BETWEEN BIGINT BINARY BLOB BOTH BY CALL CASCADE
          CASE CHANGE CHAR CHARACTER CHECK COLLATE COLUMN CONNECTION
          CONDITION CONSTRAINT CONTINUE CONVERT CREATE CROSS
          CURRENT_DATE CURRENT_TIME CURRENT_TIMESTAMP CURRENT_USER
          CURSOR DATABASE DATABASES DAY_HOUR DAY_MICROSECOND
          DAY_MINUTE DAY_SECOND DEC DECIMAL DECLARE DEFAULT DELAYED
          DELETE DESC DESCRIBE DETERMINISTIC DISTINCT DISTINCTROW
          DIV DOUBLE DROP DUAL EACH ELSE ELSEIF ENCLOSED ESCAPED
          EXISTS EXIT EXPLAIN FALSE FETCH FLOAT FLOAT4 FLOAT8 FOR
          FORCE FOREIGN FROM FULLTEXT GRANT GROUP HAVING HIGH_PRIORITY
          HOUR_MICROSECOND HOUR_MINUTE HOUR_SECOND IF IGNORE IN
          INDEX INFILE INNER INOUT INSENSITIVE INSERT INT INT1 INT2
          INT3 INT4 INT8 INTEGER INTERVAL INTO IS ITERATE JOIN KEY
          KEYS KILL LEADING LEAVE LEFT LIKE LIMIT LINEAR LINES LOAD
          LOCALTIME LOCALTIMESTAMP LOCK LONG LONGBLOB LONGTEXT LOOP
          LOW_PRIORITY MASTER_SSL_VERIFY_SERVER_CERT MATCH MEDIUMBLOB
          MEDIUMINT MEDIUMTEXT MIDDLEINT MINUTE_MICROSECOND
          MINUTE_SECOND MOD MODIFIES NATURAL NOT NO_WRITE_TO_BINLOG
          NULL NUMERIC ON OPTIMIZE OPTION OPTIONALLY OR ORDER OUT
          OUTER OUTFILE PRECISION PRIMARY PROCEDURE PURGE RANGE
          READ READ_ONLY READS READ_WRITE READ_WRITE REAL REFERENCES
          REGEXP RELEASE RENAME REPEAT REPLACE REQUIRE RESTRICT
          RETURN REVOKE RIGHT RLIKE SCHEMA SCHEMAS SECOND_MICROSECOND
          SELECT SENSITIVE SEPARATOR SET SHOW SMALLINT SPATIAL
          SPECIFIC SQL SQL_BIG_RESULT SQL_CALC_FOUND_ROWS SQLEXCEPTION
          SQL_SMALL_RESULT SQLSTATE SQLWARNING SSL STARTING
          STRAIGHT_JOIN TABLE TERMINATED THEN TINYBLOB TINYINT
          TINYTEXT TO TRAILING TRIGGER TRUE UNDO UNION UNIQUE UNLOCK
          UNSIGNED UPDATE UPGRADE USAGE USE USING UTC_DATE UTC_TIME
          UTC_TIMESTAMP VALUES VARBINARY VARCHAR VARCHARACTER VARYING
          WHEN WHERE WHILE WITH WRITE XOR YEAR_MONTH ZEROFILL
        }.inject({}){ |h,w| h[w] = true; h }

        def initialize(vocabulary, *options)
          @vocabulary = vocabulary
          @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
          @delay_fks = options.include? "delay_fks"
          @norma = options.include? "norma"
        end

        def puts s
          @out.puts s
        end

        def go s
          puts s + ";\n\n"
        end

        def escape s
          # Escape SQL keywords and non-identifiers
          s = s[0...120]
          if s =~ /[^A-Za-z0-9_]/ || RESERVED_WORDS[s.upcase]
            "`#{s}`"
          else
            s
          end
        end

        # Return SQL type and (modified?) length for the passed NORMA base type
        def norma_type(type, length)
          sql_type = case type
            when "AutoCounter"; "INT"
            when "SignedInteger",
              "SignedSmallInteger"
              s = case
                when length <= 8; "TINYINT UNSIGNED"
                when length <= 16; "SMALLINT UNSIGNED"
                when length <= 24; "MEDIUMINT UNSIGNED"
                else "INT UNSIGNED"
                end
              length = nil
              s
            when "UnsignedInteger",
              "UnsignedSmallInteger",
              "UnsignedTinyInteger"
              s = case
                when length <= 8; "TINYINT"
                when length <= 16; "SMALLINT"
                when length <= 24; "MEDIUMINT"
                when length <= 32; "INT"
                else "BIGINT"
                end
              length = nil
              s
            when "Decimal"; "DECIMAL"

            when "FixedLengthText"; 
                length ||= DefaultCharColLength
                "CHAR"
            when "VariableLengthText"; 
                length ||= DefaultCharColLength
                "VARCHAR"
            # There are several large length text types; If you need to store more than 65k chars, look at using MEDIUMTEXT or LONGTEXT
            # CQL does not yet allow you to specify a length for LargeLengthText.
            when "LargeLengthText"; "TEXT"

            when "DateAndTime"; "DATETIME"
            when "Date"; "DATE" 
            when "Time"; "TIME"
            when "AutoTimestamp"; "TIMESTAMP"

            when "Money"; "DECIMAL"
            # Warning: Max 65 kbytes. To use larger types, try MediumBlob (16mb) or LongBlob (4gb)
            when "PictureRawData"; "BLOB"
            when "VariableLengthRawData"; "BLOB"
            # Assuming you only want a boolean out of this. Should we specify length instead?
            when "BIT"; "BIT"
            else raise "SQL type unknown for NORMA type #{type}"
            end
          [sql_type, length]
        end

      public
        def generate(out = $>)      #:nodoc:
          @out = out
          #go "CREATE SCHEMA #{@vocabulary.name}"

          tables_emitted = {}
          delayed_foreign_keys = []

          @vocabulary.tables.each do |table|
            puts "CREATE TABLE #{escape table.name} ("

            pk = table.identifier_columns
            identity_column = pk[0] if pk.size == 1 && pk[0].is_auto_assigned

            fk_refs = table.references_from.select{|ref| ref.is_simple_reference }
            fk_columns = table.columns.select do |column|
              column.references[0].is_simple_reference
            end

            # We sort the columns here, not in the persistence layer, because it affects
            # the ordering of columns in an index :-(.
            columns = table.columns.sort_by { |column| column.name(nil) }.map do |column|
              name = escape column.name("")
              padding = " "*(name.size >= ColumnNameMax ? 1 : ColumnNameMax-name.size)
              type, params, restrictions = column.type
              restrictions = [] if (fk_columns.include?(column))  # Don't enforce VT restrictions on FK columns
              length = params[:length]
              length &&= length.to_i
              scale = params[:scale]
              scale &&= scale.to_i
              type, length = norma_type(type, length) if @norma
              sql_type = "#{type}#{
                if !length
                  ""
                else
                  "(" + length.to_s + (scale ? ", #{scale}" : "") + ")"
                end
                }"
              identity = column == identity_column ? " AUTO_INCREMENT" : ""
              null = (column.is_mandatory ? "NOT " : "") + "NULL"
              check = check_clause(name, restrictions)
              comment = column.comment
              [ "-- #{comment}", "#{name}#{padding}#{sql_type}#{identity} #{null}#{check}" ]
            end.flatten

            pk_def = (pk.detect{|column| !column.is_mandatory} ? "UNIQUE(" : "PRIMARY KEY(") +
                pk.map{|column| escape column.name("")}*", " +
                ")"

            inline_fks = []
            table.foreign_keys.each do |fk|
              fk_text = "FOREIGN KEY (" +
                fk.from_columns.map{|column| column.name}*", " +
                ") REFERENCES #{escape fk.to.name} (" +
                fk.to_columns.map{|column| column.name}*", " +
                ")"
              if !@delay_fks and              # We don't want to delay all Fks
                (tables_emitted[fk.to] or     # The target table has been emitted
                fk.to == table && !fk.to_columns.detect{|column| !column.is_mandatory})   # The reference columns already have the required indexes
                inline_fks << fk_text
              else
                delayed_foreign_keys << ("ALTER TABLE #{escape fk.from.name}\n\tADD " + fk_text)
              end
            end

            indices = table.indices
            inline_indices = []
            delayed_indices = []
            indices.each do |index|
              next if index.over == table && index.is_primary   # Already did the primary keys
              abbreviated_column_names = index.abbreviated_column_names*""
              column_names = index.column_names
              column_name_list = column_names.map{|n| escape(n)}*", "
              inline_indices << "UNIQUE(#{column_name_list})"
            end

            tables_emitted[table] = true

            puts("\t" + (columns + [pk_def] + inline_indices + inline_fks)*",\n\t")
            go ")"
            delayed_indices.each {|index_text|
              go index_text
            }
          end

          delayed_foreign_keys.each do |fk|
            go fk
          end
        end

      private
        def check_clause(column_name, restrictions)
          return "" if restrictions.empty?
          # REVISIT: Merge all restrictions (later; now just use the first)
          " CHECK(" +
            restrictions[0].all_allowed_range.sort_by do |ar|
              # Put the allowed ranges into a defined order:
              ((min = ar.value_range.minimum_bound) && min.value) ||
                ((max = ar.value_range.maximum_bound) && max.value)
            end.map do |ar|
              vr = ar.value_range
              min = vr.minimum_bound
              max = vr.maximum_bound
              if (min && max && max.value == min.value)
                "#{column_name} = #{min.value}"
              else
                inequalities = [
                  min && "#{column_name} >#{min.is_inclusive ? "=" : ""} #{min.value}",
                  max && "#{column_name} <#{max.is_inclusive ? "=" : ""} #{max.value}"
                ].compact
                inequalities.size > 1 ? "(" + inequalities*" AND " + ")" : inequalities[0]
              end
            end*" OR " +
          ")"
        end
      end
    end
  end
end
