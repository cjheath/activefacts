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

      def initialize(vocabulary)
        @vocabulary = vocabulary
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
        print "#{concept.name} (#{concept.tentative ? "tentatively " : ""}#{concept.independent ? "in" : ""}dependent)"
        if concept.is_a? EntityType
          print " is identified by: #{
              concept.absorbed_reference_roles.all_role_ref.map { |rr| rr.describe } * ", "
            }"
        end
        puts "#{ concept.absorbed_roles.all_role_ref.map do |role_ref|
            "\n\t#{role_ref.describe}"
          end*"" }"
=begin
        ap = concept.absorption_paths
        puts "#{ ap.map {|role|
          prr = role.preferred_reference.describe
          "\n\tcan absorb #{prr != role.concept.name ? "(via #{prr}) " : "" }into #{concept.absorbed_into(role).name}"
        }*"" }"
=end
      end
    end
  end
end

