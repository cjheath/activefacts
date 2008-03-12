require 'date'

module ActiveFacts
  module API
    # Adapter module to add value_type to all potential value classes
    module ValueClass
      def value_type *args, &block
	include ActiveFacts::API::Value
	# the included method adds the Value::ClassMethods
	initialise_value_type(*args, &block)
      end
    end
  end
end

require 'activefacts/api/numeric'

# Add the methods that convert our classes into Concept types:

ValueClasses = [String, Date, DateTime, Int, Real, AutoCounter]
ValueClasses.each{|c|
    c.send :extend, ActiveFacts::API::ValueClass
  }

class TrueClass
  def verbalise; "true"; end
end

class NilClass
  def verbalise; "nil"; end
end

class Class
  def identified_by *args
    raise "not an entity type" if respond_to? :value_type
    include ActiveFacts::API::Entity
    initialise_entity_type(*args)
  end
end

# REVISIT: Fix these NORMA types
class Decimal < Int; end
class SignedInteger < Int; end
class SignedSmallInteger < Int; end
class UnsignedInteger < Int; end
class UnsignedSmallInteger < Int; end
class LargeLengthText < String; end
class FixedLengthText < String; end
class PictureRawData < String; end
class DateAndTime < DateTime; end
class Money < Decimal; end
