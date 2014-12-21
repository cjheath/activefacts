#
#       ActiveFacts Generators.
#       Generate a Relational Composition (for activefacts/composition).
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/generate/helpers/inject'
require 'activefacts/persistence'
require 'activefacts/generate/traits/ruby'

module ActiveFacts
  module Generate
    #   afgen --composition[=options] <file>.cql
    # Options are comma or space separated:
    class Composition #:nodoc:
    private
      include Persistence

      def initialize(vocabulary, *options)
	@vocabulary = vocabulary
	@vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
	@underscore = options.include?("underscore") ? "_" : ""
      end

      def puts s
	@out.puts s
      end

    public
      def generate(out = $>)      #:nodoc:
	@out = out

	tables_emitted = {}

	puts "require '#{@vocabulary.name}'"
	puts "require 'activefacts/composition'"
	puts "\n#{@vocabulary.name}_ER = ActiveFacts::Composition.new(#{@vocabulary.name}) do"
	@vocabulary.tables.each do |table|
	  puts "  composite :\"#{table.name.gsub(' ',@underscore)}\" do"

	  pk = table.identifier_columns
	  identity_column = pk[0] if pk[0].is_auto_assigned

	  fk_refs = table.references_from.select{|ref| ref.is_simple_reference }
	  fk_columns = table.columns.select do |column|
	    column.references[0].is_simple_reference
	  end

	  columns =
	    table.columns.map do |column|
	      [column, column.references.map{|r| r.to_names }]
	    end.sort_by do |column, refnames|
	      refnames
	    end
	  previous_flattening = []
	  ref_prefix = []
	  columns.each do |column, refnames|
	    ref_prefix = column.references[0...previous_flattening.size]
	    # Pop back. Not a succinct algorithm, but easy to check
	    while previous_flattening.size > ref_prefix.size
	      previous_flattening.pop
	      puts '    '+'  '*previous_flattening.size+"end\n"
	    end
	    while ref_prefix.size > 0 and previous_flattening != ref_prefix
	      previous_flattening.pop
	      ref_prefix.pop
	      puts '    '+'  '*previous_flattening.size+"end\n"
	    end
	    loop do
	      ref = column.references[ref_prefix.size]
	      role_name = ref.to_role.preferred_role_name
	      if ref == column.references.last
		# REVISIT: Avoid the "as" here when the value is implied by the role_name:
		puts '    '+'  '*ref_prefix.size+"nest :#{role_name}, :as => \"#{column.name}\"\t\t# #{ref.fact_type.default_reading}"
		break
	      else
		puts '    '+'  '*ref_prefix.size+"flatten :#{role_name} do\t\t# #{ref.fact_type.default_reading}"
		ref_prefix.push ref
	      end
	    end
	    previous_flattening = ref_prefix
	  end

	  while previous_flattening.size > 0
	    previous_flattening.pop
	    puts '    '+'  '*previous_flattening.size+"end\n"
	  end
	  puts "  end\n\n"

	  tables_emitted[table] = true

	end
	puts "end\n"
      end

    end
  end
end

ActiveFacts::Registry.generator('composition', ActiveFacts::Generate::Composition)
