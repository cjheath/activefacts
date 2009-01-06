#
# Generate an SQL Server schema from an ActiveFacts vocabulary.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    class SQL
      class SERVER
        include Metamodel
        ColumnNameMax = 40

        RESERVED_WORDS = %w{
          ADD ALL ALTER AND ANY AS ASC AUTHORIZATION BACKUP BEGIN BETWEEN
          BREAK BROWSE BULK BY CASCADE CASE CHECK CHECKPOINT CLOSE CLUSTERED
          COALESCE COLLATE COLUMN COMMIT COMPUTE CONSTRAINT CONTAINS CONTAINSTABLE
          CONTINUE CONVERT CREATE CROSS CURRENT CURRENT_DATE CURRENT_TIME
          CURRENT_TIMESTAMP CURRENT_USER CURSOR DATABASE DBCC DEALLOCATE
          DECLARE DEFAULT DELETE DENY DESC DISK DISTINCT DISTRIBUTED DOUBLE
          DROP DUMMY DUMP ELSE END ERRLVL ESCAPE EXCEPT EXEC EXECUTE EXISTS
          EXIT FETCH FILE FILLFACTOR FOR FOREIGN FREETEXT FREETEXTTABLE FROM
          FULL FUNCTION GOTO GRANT GROUP HAVING HOLDLOCK IDENTITY IDENTITYCOL
          IDENTITY_INSERT IF IN INDEX INNER INSERT INTERSECT INTO IS JOIN KEY
          KILL LEFT LIKE LINENO LOAD NATIONAL NOCHECK NONCLUSTERED NOT NULL
          NULLIF OF OFF OFFSETS ON OPEN OPENDATASOURCE OPENQUERY OPENROWSET
          OPENXML OPTION OR ORDER OUTER OVER PERCENT PLAN PRECISION PRIMARY
          PRINT PROC PROCEDURE PUBLIC RAISERROR READ READTEXT RECONFIGURE
          REFERENCES REPLICATION RESTORE RESTRICT RETURN REVOKE RIGHT ROLLBACK
          ROWCOUNT ROWGUIDCOL RULE SAVE SCHEMA SELECT SESSION_USER SET SETUSER
          SHUTDOWN SOME STATISTICS SYSTEM_USER TABLE TEXTSIZE THEN TO TOP
          TRAN TRANSACTION TRIGGER TRUNCATE TSEQUAL UNION UNIQUE UPDATE
          UPDATETEXT USE USER VALUES VARYING VIEW WAITFOR WHEN WHERE WHILE
          WITH WRITETEXT
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
          puts s
          puts "GO\n\n"
        end

        def escape s
          # Escape SQL keywords and non-identifiers
          if s =~ /[^A-Za-z0-9_]/ || RESERVED_WORDS[s.upcase]
            "[#{s}]"
          else
            s
          end
        end

        # Return SQL type and (modified?) length for the passed NORMA base type
        def norma_type(type, length)
          sql_type = case type
            when "AutoCounter"; "int"
            when "Date"; "datetime"
            when "UnsignedInteger", "SignedInteger"
              s = case
                when length <= 8; "tinyint"
                when length <= 16; "shortint"
                when length <= 32; "int"
                else "bigint"
                end
              length = nil
              s
            when "FixedLengthText"; "char"
            when "VariableLengthText"; "varchar"
            when "LargeLengthText"; "text"
            when "Decimal"; "decimal"
            when "DateAndTime"; "datetime"
            when "Money"; "decimal"
            when "PictureRawData"; "image"
            when "Time"; "datetime"
            when "UnsignedSmallInteger"; "shortint"
            when "SignedSmallInteger"; "shortint"
            when "UnsignedTinyInteger"; "tinyint"
            when "BIT"; "bit"
            else raise "SQL type unknown for NORMA type #{type}"
            end
          [sql_type, length]
        end

        def generate(out = $>)
          @out = out
          #go "CREATE SCHEMA #{@vocabulary.name}"

          tables_emitted = {}
          delayed_foreign_keys = []

          @vocabulary.tables.sort_by{|table| table.name}.each do |table|
            tables_emitted[table] = true
            puts "CREATE TABLE #{escape table.name} ("

            pk = table.identifier_columns
            identity_column = pk[0] if pk.size == 1 && pk[0].is_auto_assigned

            fk_refs = table.references_from.select{|ref| ref.is_simple_reference }
            fk_columns = table.columns.select do |column|
              column.references[0].is_simple_reference
            end

            columns = table.columns.map do |column|
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
              identity = column == identity_column ? " IDENTITY" : ""
              null = (column.is_mandatory ? "NOT " : "") + "NULL"
              check = check_clause(name, restrictions)
              "#{name}#{padding}#{sql_type}#{identity} #{null}#{check}"
            end

            pk_def = (pk.detect{|column| !column.is_mandatory} ? "UNIQUE(" : "PRIMARY KEY(") +
                pk.map{|column| escape column.name("")}*", " +
                ")"

            inline_fks = []
            fk_refs.map do |fk_ref|
              from_columns = table.columns.select{|column| column.references[0] == fk_ref }

              to = fk_ref.to
              # REVISIT: There should be a better way to find where it's absorbed (especially since this fails for absorbed subtypes having their own identification!)
              while (r = to.absorbed_via)
                #puts "#{to.name} is absorbed into #{r.to.name}/#{r.from.name}"
                to = r.to == to ? r.from : r.to
              end
              raise "REVISIT: #{fk_ref} is bad" unless to and to.columns

              all_to_columns_by_role = to.columns.inject({}) do |hash, column|
                r0 = column.references[0]
                hash[r0.to_role] = column
                hash
              end
              to_columns = from_columns.map do |from_column|
                c ||= all_to_columns_by_role[from_column.references[1].to_role]
                raise "REVISIT: Failed to find target column for #{fk_ref} matching #{from_column.name}" unless c
                # p from_column.references
                # p from_column.references[1]
                # p from_column.references[1].from_role
                # p from_column.references[1].to_role
                c
              end
              fk = "FOREIGN KEY (" +
                from_columns.map{|column| column.name}*", " +
                ") REFERENCES #{escape to.name} (" +
                to_columns.map{|column| column.name}*", " +
                ")"
              if tables_emitted[to] && !@delay_fks
                inline_fks << fk
              else
                delayed_foreign_keys << ("ALTER TABLE #{escape table.name}\n\tADD " + fk)
              end
            end

            puts("\t" + (columns + [pk_def] + inline_fks)*",\n\t")
            go ")"
          end

          delayed_foreign_keys.each do |fk|
            go fk
          end
        end

        def check_clause(column_name, restrictions)
          return "" if restrictions.empty?
          # REVISIT: Merge all restrictions (later; now just use the first)
          " CHECK(" +
            restrictions[0].all_allowed_range.map do |ar|
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
