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

        def initialize(vocabulary, *options)
          @vocabulary = vocabulary
          #@no_columns = options.include? "no_columns"
          #@dependent = options.include? "dependent"
          #@paths = options.include? "paths"
          #@no_identifier = options.include? "no_identifier"
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
          s
        end

        # Return a ValueType definition for the passed ValueType
        def sql_type(vt)
          length = vt.length|| vt.supertype.length
          scale = vt.scale|| vt.supertype.scale
          basic_type = case (vt.supertype||vt).name
            when "AutoCounter"; "integer"
            when "Date"; "date"
            when "SignedInteger"
              l = length
              length = nil
              case
              when l <= 8; "tinyint"
              when l <= 16; "shortint"
              when l <= 32; "integer"
              else "bigint"
              end
            when "VariableLengthText"; "varchar"
            else vt.name
            end
          if length && length != 0
            basic_type << ((scale && scale != 0) ? "(#{length}, #{scale})" : "(#{length})")
          end
          basic_type
        end

        def generate(out = $>)
          @out = out
          go "CREATE SCHEMA #{@vocabulary.name}"
          @vocabulary.tables.each do |table|
            puts "CREATE TABLE #{escape table.name} ("
              puts table.absorbed_roles.all_role_ref.map { |role_ref|
                t = role_ref.role.fact_type.all_role.size > 1 ? sql_type(role_ref.role.concept) : "bit"
                name = role_ref.column_name(nil).map(&:capitalize)*""
                "\t#{escape name}\t#{t}"
              } * ",\n"
            go ")"
          end
        end

      end
    end
  end
end
