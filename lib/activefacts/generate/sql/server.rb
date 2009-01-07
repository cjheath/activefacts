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
            when "UnsignedInteger",
              "SignedInteger",
              "UnsignedSmallInteger",
              "SignedSmallInteger",
              "UnsignedTinyInteger"
              s = case
                when length <= 8; "tinyint"
                when length <= 16; "shortint"
                when length <= 32; "int"
                else "bigint"
                end
              length = nil
              s
            when "Decimal"; "decimal"

            when "FixedLengthText"; "char"
            when "VariableLengthText"; "varchar"
            when "LargeLengthText"; "text"

            when "DateAndTime"; "datetime"
            when "Date"; "datetime" # SQLSVR 2K5: "date"
            when "Time"; "datetime" # SQLSVR 2K5: "time"
            when "AutoTimestamp"; "timestamp"

            when "Money"; "decimal"
            when "PictureRawData"; "image"
            when "VariableLengthRawData"; "varbinary"
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
            table.foreign_keys.each do |fk|
              fk_text = "FOREIGN KEY (" +
                fk.from_columns.map{|column| column.name}*", " +
                ") REFERENCES #{escape fk.to.name} (" +
                fk.to_columns.map{|column| column.name}*", " +
                ")"
              if tables_emitted[fk.to] && !@delay_fks
                inline_fks << fk_text
              else
                delayed_foreign_keys << ("ALTER TABLE #{escape fk.from.name}\n\tADD " + fk_text)
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
