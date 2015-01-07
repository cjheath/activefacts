#
#       ActiveFacts Generators.
#       Generate metamodel statistics fora compiled vocabulary
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    # Generate a text verbalisation of the metamodel constellation created for an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --text <file>.cql
    class Statistics
    private
      def initialize(vocabulary)
        @vocabulary = vocabulary
        @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
      end

    public
      def generate(out = $>)
	constellation = @vocabulary.constellation
	object_types = constellation.ObjectType.values
	fact_types = constellation.FactType.values

	# All metamodel object types:
	object_count = 0
	populated_object_type_count = 0
	fact_types_processed = {}
	fact_count = 0
	role_played_count = 0
	constellation.vocabulary.object_type.map do |object_type_name, object_type|
	  objects = constellation.send(object_type_name)
	  next unless objects.size > 0
	  puts "\t#{object_type_name}: #{objects.size} instances (which play #{object_type.all_role.size} roles)"
	  populated_object_type_count += 1
	  object_count += objects.size

	  #puts "#{object_type_name} has #{object_type.all_role.size} roles"
	  object_type.all_role.each do |name, role|
	    next unless role.unique
	    next if fact_types_processed[role.fact_type]
	    next if role.fact_type.is_a?(ActiveFacts::API::TypeInheritanceFactType)
	    role_population_count =
	      objects.values.inject(0) do |count, object|
		count += 1 if object.send(role.name) != nil
		count
	      end
	    puts "\t\t#{object_type_name}.#{role.name} has #{role_population_count} instances" if role_population_count > 0
	    fact_count += role_population_count
	    role_played_count += role_population_count*role.fact_type.all_role.size

	    fact_types_processed[role.fact_type] = true
	  end

	end
	puts "#{@vocabulary.name} has"
	puts "\t#{object_types.size} object types"
	puts "\t#{fact_types.size} fact types"
	puts "\tcompiles to #{object_count} objects in total, of #{populated_object_type_count} metamodel types"
	puts "\tcompiles to #{fact_count} facts in total, of #{fact_types_processed.size} metamodel fact types"
	puts "\tcompiles to #{role_played_count} role instances in total"
      end
    end
  end
end

ActiveFacts::Registry.generator('records', ActiveFacts::Generate::Statistics)
