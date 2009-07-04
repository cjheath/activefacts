#
#       ActiveFacts Generators.
#       Generate SQL for SQL Server from an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    class SQL #:nodoc:
      # Generate SQL for SQL Server for an ActiveFacts vocabulary.
      # Invoke as
      #   afgen --sql/server[=options] <file>.cql
      # Options are comma or space separated:
      # * delay_fks Leave all foreign keys until the end, not just those that contain forward-references
      # * norma Translate valuetypes from NORMA to SQL Server
      class SERVER
      private
        include Persistence
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
          @underscore = options.include?("underscore") ? "_" : ""
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
          s = s[0...120]
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
            else type # raise "SQL type unknown for NORMA type #{type}"
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
            puts "CREATE TABLE #{escape table.name(@underscore)} ("

            pk = table.identifier_columns
            identity_column = pk[0] if pk.size == 1 && pk[0].is_auto_assigned

            fk_refs = table.references_from.select{|ref| ref.is_simple_reference }
            fk_columns = table.columns.select do |column|
              column.references[0].is_simple_reference
            end

            # We sort the columns here, not in the persistence layer, because it affects
            # the ordering of columns in an index :-(.
            columns = table.columns.sort_by { |column| column.name(@underscore) }.map do |column|
              name = escape column.name(@underscore)
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
              comment = column.comment
              [ "-- #{comment}", "#{name}#{padding}#{sql_type}#{identity} #{null}#{check}" ]
            end.flatten

            pk_def = (pk.detect{|column| !column.is_mandatory} ? "UNIQUE(" : "PRIMARY KEY(") +
                pk.map{|column| escape column.name(@underscore)}*", " +
                ")"

            inline_fks = []
            table.foreign_keys.each do |fk|
              fk_text = "FOREIGN KEY (" +
                fk.from_columns.map{|column| column.name(@underscore)}*", " +
                ") REFERENCES #{escape fk.to.name(@underscore)} (" +
                fk.to_columns.map{|column| column.name(@underscore)}*", " +
                ")"
              if !@delay_fks and              # We don't want to delay all Fks
                (tables_emitted[fk.to] or     # The target table has been emitted
                fk.to == table && !fk.to_columns.detect{|column| !column.is_mandatory})   # The reference columns already have the required indexes
                inline_fks << fk_text
              else
                delayed_foreign_keys << ("ALTER TABLE #{escape fk.from.name(@underscore)}\n\tADD " + fk_text)
              end
            end

            indices = table.indices
            inline_indices = []
            delayed_indices = []
            indices.each do |index|
              next if index.over == table && index.is_primary   # Already did the primary keys
              abbreviated_column_names = index.abbreviated_column_names(@underscore)*""
              column_names = index.column_names(@underscore)
              column_name_list = column_names.map{|n| escape(n)}*", "
              if index.columns.all?{|column| column.is_mandatory}
                inline_indices << "UNIQUE(#{column_name_list})"
              else
                view_name = escape "#{index.view_name}_#{abbreviated_column_names}"
                delayed_indices <<
%Q{CREATE VIEW dbo.#{view_name} (#{column_name_list}) WITH SCHEMABINDING AS
\tSELECT #{column_name_list} FROM dbo.#{escape index.on.name(@underscore)}
\tWHERE\t#{
  index.columns.
    select{|column| !column.is_mandatory }.
    map{|column|
      escape(column.name(@underscore)) + " IS NOT NULL"
    }*"\n\t  AND\t"
}
GO

CREATE UNIQUE CLUSTERED INDEX #{escape index.name} ON dbo.#{view_name}(#{index.columns.map{|column| column.name(@underscore)}*", "})
}
              end
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
