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

        # Return a ValueType definition for the passed role reference
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
            when "VariableLengthText"; "varchar"
            when "LargeLengthText"; "text"
            when "Decimal"; "decimal"
            else type
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
            columns = table.columns.map do |column|
              name = escape column.name("")
              padding = " "*(name.size >= ColumnNameMax ? 1 : ColumnNameMax-name.size)
              type, params, restrictions = column.type
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
              null = (column.is_mandatory ? "NOT " : "") + "NULL"
              check = (restrictions.empty? ? "" : " CHECK(REVISIT: valid value)")
              "#{name}#{padding}#{sql_type} #{null}#{check}"
            end

            pk_def = (pk.detect{|column| !column.is_mandatory} ? "UNIQUE(" : "PRIMARY KEY(") +
                pk.map{|column| escape column.name("")}*", " +
                ")"

            inline_fks = []
=begin
            table.absorbed_references.sort_by { |role, other_table, from_columns, to_columns|
              [ other_table.name, from_columns.map{|c| column_name(c)} ]
            }.each do |role, other_table, from_columns, to_columns|
              fk =
                if tables_emitted[other_table] && !@delay_fks
                  inline_fks << "\t"
                else
                  delayed_foreign_keys << "ALTER TABLE #{escape table.name}\n\tADD "
                end.last
              fk << "FOREIGN KEY(#{from_columns.map{|c| column_name(c)}*", "})\n"+
                "\tREFERENCES #{escape other_table.name}(#{to_columns.map{|c| column_name(c)}*", "})"
            end
=end

            puts("\t" + (columns + [pk_def] + inline_fks)*",\n\t")
            go ")"
          end

          delayed_foreign_keys.each do |fk|
            go fk
          end
        end
      end
    end
  end
end
