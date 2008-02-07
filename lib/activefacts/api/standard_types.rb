require 'date'

module ActiveFacts
  # Adapter module to add value_type to all potential value classes
  module ValueClass
    def value_type *args
      include Value
      # the included method adds the Value::ClassMethods
      # REVISIT: args could be a hash, with keys :length, :scale, :unit, :allow
      raise "value_type args unexpected" if args.size > 0
    end
  end
end

ValueClasses = [String, Numeric, Date]
ValueClasses.each{|c| c.send :extend, ActiveFacts::ValueClass }

class Class
  def entity_type *args
    raise "not an entity type" if respond_to? :value_type
    include ActiveFacts::Entity
    known_by *args
  end
end
