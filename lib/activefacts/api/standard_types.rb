require 'date'

module ActiveFacts
  # Adapter module to add value_type to all potential value classes
  module ValueClass
    def value_type *args, &block
      include ActiveFacts::Value
      # the included method adds the Value::ClassMethods
      initialise_value_type *args, &block
    end
  end
end

require 'activefacts/api/numeric'

# Add the methods that convert our classes into Concept types:

ValueClasses = [String, Date, Int, Real]
ValueClasses.each{|c|
    c.send :extend, ActiveFacts::ValueClass
  }

class Class
  def entity_type *args
    raise "not an entity type" if respond_to? :value_type
    include ActiveFacts::Entity
    initialise_entity_type *args
  end
end
