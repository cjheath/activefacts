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
          @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::Constellation === @vocabulary
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

        # Return a ValueType definition for the passed role reference
        def sql_type(role_ref)
          if role_ref.role.fact_type.all_role.size == 1
            "bit"
          else
            vt = role_ref.role.concept
            length = vt.length|| vt.supertype.length
            scale = vt.scale|| vt.supertype.scale
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

          @vocabulary.tables.each do |table|
            puts "CREATE TABLE #{escape table.name} ("
            puts((
                table.absorbed_roles.all_role_ref.map { |role_ref|
                  "\t#{column_name(role_ref)}\t#{sql_type(role_ref)}"
                } +
                [
                  # Any nullable fields mean this can't be a primary key, just a unique constraint
                  if table.absorbed_reference_roles.all_role_ref.detect{ |role_ref| !role_ref.role.is_mandatory }
                    "\tUNIQUE("
                  else
                    "\tPRIMARY KEY("
                  end +
                  table.absorbed_reference_roles.all_role_ref.map { |role_ref|
                    column_name(role_ref)
                  }*", " +
                  ")"
                ]
              ) * ",\n"
            )
              go ")"
            end
          end

      end
    end
  end
end
