#
#       ActiveFacts Generators.
#       Absorption generator.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    # Emit the absorption (Relational summary) for vocabulary.
    # Not currently working, it relies on the old relational composition code.
    # Invoke as
    #   afgen --absorption[=options] <file>.cql"
    # Options are comma or space separated:
    # * no_columns Don't emit the columns
    # * dependent Show Concepts that are not tables as well
    # * paths Show the references paths through which each column was defined
    # * no_identifier Don't show the identified_by columns for an EntityType

    class ABSORPTION
      include Metamodel

      def initialize(vocabulary, *options)  #:nodoc:
        @vocabulary = vocabulary
        @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
        @no_columns = options.include? "no_columns"
        @dependent = options.include? "dependent"
        @paths = options.include? "paths"
        @no_identifier = options.include? "no_identifier"
      end

      def generate(out = $>)  #:nodoc:
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
        end
      end

      def show concept        #:nodoc:
        return unless concept.is_table || @dependent

        print "#{concept.name}"
        print " (#{concept.tentative ? "tentatively " : ""}#{concept.is_table ? "in" : ""}dependent)" if @dependent

        if !@no_identifier && concept.is_a?(EntityType)
          print " is identified by:\n\t#{
"REVISIT" #              concept.references_from.to_s
            }"
        end
        print "\n"

        unless @no_columns
          puts "#{ concept.references_from.map do |role_ref|
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

