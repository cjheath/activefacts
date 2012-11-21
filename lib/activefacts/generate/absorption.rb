#
#       ActiveFacts Generators.
#       Absorption generator.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    # Emit the absorption (Relational summary) for vocabulary.
    # Not currently working, it relies on the old relational composition code.
    # Invoke as
    #   afgen --absorption[=options] <file>.cql"
    # Options are comma or space separated:
    # * no_columns Don't emit the columns
    # * all Show ObjectTypes that are not tables as well
    # * paths Show the references paths through which each column was defined
    # * no_identifier Don't show the identified_by columns for an EntityType

    class ABSORPTION
      def initialize(vocabulary, *options)  #:nodoc:
        @vocabulary = vocabulary
        @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
        @no_columns = options.include? "no_columns"
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
        @vocabulary.all_object_type.sort_by{|c| c.name}.each do |o|
          next if !o.is_table
          show(o)
        end
      end

      def show object_type        #:nodoc:
        indices = object_type.indices
        pk = indices.select(&:is_primary)[0]
        indices = indices.clone
        indices.delete pk
        puts "#{object_type.name}: #{
#            "[#{object_type.indices.size} indices] "
#          } #{
            object_type.columns.sort_by do |column|
              column.name(nil)
            end.map do |column|
              index_nrs =
                [pk && pk.columns.include?(column) ? "*" : nil] +
                (0...indices.size).select{|i| indices[i].columns.include?(column)}.map{|i| (i+1).to_i }
              index_nrs.compact!
              (@paths ? column.references.map{|r| r.to_names}.flatten : column.name(nil)) * '.' +
                (index_nrs.empty? ? "" : "["+index_nrs*""+"]")
            end*", "
          }"

      end
    end
  end
end

ActiveFacts::Registry.generator('absorption', ActiveFacts::Generate::ABSORPTION)
