#
#       ActiveFacts Generators.
#       Generate text output (verbalise the meta-vocabulary) for ActiveFacts vocabularies.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    # Generate a text verbalisation of the metamodel constellation created for an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --text <file>.cql
    class RECORDS
    private
      def initialize(vocabulary)
        @vocabulary = vocabulary
        @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
      end

    public
      def generate(out = $>)
        # Extract the list of tables in the relational mapping of the metamodel
        # We'll use the columns too.
        @metamodel = ActiveFacts::CQL::Compiler.new.compile_file "examples/CQL/Metamodel.cql"
        tables = @metamodel.tables.sort_by{|t| t.name}

        class_names = tables.map{|t| t.name.gsub(/\s/,'')}
        # map{|t| ActiveFacts::Metamodel.const_get(t.name.gsub(/\s/,''))}

        tables.zip(class_names).each do |table, class_name|
          instance_index = @vocabulary.constellation.send(class_name)
          debugger
          next if instance_index.empty?
          out.puts "#{table.name}(#{table.columns.map{|c| c.name}*', '})"
          debugger
          instance_index.each do |key, value|
            out.puts "\t"+value.verbalise
          end
        end
      end
    end
  end
end

