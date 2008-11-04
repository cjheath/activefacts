#
# Generate text output for ActiveFacts vocabularies.
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    class ABSORPTION
      include Metamodel

      def initialize(vocabulary, *options)
        @vocabulary = vocabulary
        @no_columns = options.include? "no_columns"
        @dependent = options.include? "dependent"
        @paths = options.include? "paths"
        @no_identifier = options.include? "no_identifier"
      end

      def generate(out = $>)
        no_absorption = 0
        single_absorption_vts = 0
        single_absorption_ets = 0
        multi_absorption_vts = 0
        multi_absorption_ets = 0
        @vocabulary.tables
        @vocabulary.all_feature.sort_by{|c| c.name}.each do |o|
          # Don't dump imported (base) ValueTypes:
          next if ValueType === o && !o.supertype
          show(o)

          case o.absorption_paths.size
          when 0; no_absorption += 1
          when 1
            if ValueType === o
              single_absorption_vts += 1
            else
              single_absorption_ets += 1
            end
          else
            if ValueType === o
              multi_absorption_vts += 1
            else
              multi_absorption_ets += 1
            end
          end

        end
        puts "#{no_absorption} concepts have no absorption paths, #{single_absorption_vts}/#{single_absorption_ets} value/entity types have only one path, #{multi_absorption_vts}/#{multi_absorption_ets} have more than one"
      end

      def show concept
        return unless concept.independent || @dependent

        print "#{concept.name}"
        print " (#{concept.tentative ? "tentatively " : ""}#{concept.independent ? "in" : ""}dependent)" if @dependent

        if !@no_identifier && concept.is_a?(EntityType)
          print " is identified by:\n\t#{
              concept.absorbed_reference_roles.all_role_ref.map { |rr| rr.column_name*"." } * ",\n\t"
            }"
        end
        print "\n"

        unless @no_columns
          puts "#{ concept.absorbed_roles.all_role_ref.map do |role_ref|
              "\t#{role_ref.column_name(".")}\n"
            end*"" }"
        end

        if (@paths)
          ap = concept.absorption_paths
          puts "#{ ap.map {|role|
            prr = role.preferred_reference.describe
            player = role.fact_type.entity_type == concept ? role.concept : (role.fact_type.all_role-[role])[0].concept
            "\tcan absorb #{prr != role.concept.name ? "(via #{prr}) " : "" }into #{player.name}\n"
          }*"" }"
        end

      end
    end
  end
end

