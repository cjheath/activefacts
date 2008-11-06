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
          @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::Constellation === @vocabulary
          @delay_fks = options.include? "delay_fks"
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
        def sql_type(role_ref)
          if role_ref.role.fact_type.all_role.size == 1
            "bit"
          else
            vt = role_ref.role.concept
            length = vt.length
            scale = vt.scale
            while vt.supertype
              length ||= vt.length
              scale ||= vt.scale
              vt = vt.supertype
            end
            basic_type = case (vt.supertype||vt).name
              when "AutoCounter"; "int"
              when "Date"; "datetime"
              when "UnsignedInteger",
                "SignedInteger"
                l = length
                length = nil
                case
                when l <= 8; "tinyint"
                when l <= 16; "shortint"
                when l <= 32; "int"
                else "bigint"
                end
              when "VariableLengthText"; "varchar"
              when "Decimal"; "decimal"
              else vt.name
              end
            if length && length != 0
              basic_type + ((scale && scale != 0) ? "(#{length}, #{scale})" : "(#{length})")
            else
              basic_type
            end
          end +
          (
            # Is there any role along the path that lacks a mandatory constraint?
            role_ref.output_roles.detect { |role| !role.is_mandatory } ? " NULL" : " NOT NULL"
          )
        end

        def column_name(role_ref)
          escape(role_ref.column_name(nil).map{|n| n.sub(/^[a-z]/){|s| s.upcase}}*"")
        end

        def generate(out = $>)
          @out = out
          #go "CREATE SCHEMA #{@vocabulary.name}"

          tables_emitted = {}
          delayed_foreign_keys = []

          @vocabulary.tables.sort_by{|table| table.name}.each do |table|
            tables_emitted[table] = true
            puts "CREATE TABLE #{escape table.name} ("

            pk = table.absorbed_reference_roles.all_role_ref
            pk_names = pk.map{|rr| column_name(rr) }

            columns = table.absorbed_roles.all_role_ref.sort_by do |role_ref|
                  name = column_name(role_ref)
                  [pk_names.include?(name) ? 0 : 1, name]
                end.map do |role_ref|
                  "\t#{column_name(role_ref)}\t#{sql_type(role_ref)}"
                end

            pk_def =
                  if pk.detect{ |role_ref| !role_ref.role.is_mandatory }
                    # Any nullable fields mean this can't be a primary key, just a unique constraint
                    "\tUNIQUE("
                  else
                    "\tPRIMARY KEY("
                  end +
                  table.absorbed_reference_roles.all_role_ref.map do |role_ref|
                    column_name(role_ref)
                  end*", " + ")"

            inline_fks = []
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

            puts((columns + [pk_def] + inline_fks)*",\n")
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
