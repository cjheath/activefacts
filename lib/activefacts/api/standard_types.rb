#
#       ActiveFacts Runtime API
#       Standard types extensions.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# These extensions add ActiveFacts Concept and Instance behaviour into base Ruby value classes,
# and allow any Class to become an Entity.
#
require 'date'

module ActiveFacts
  module API
    # Adapter module to add value_type to all potential value classes
    module ValueClass #:nodoc:
      def value_type *args, &block #:nodoc:
        include ActiveFacts::API::Value
        # the included method adds the Value::ClassMethods
        initialise_value_type(*args, &block)
      end
    end
  end
end

require 'activefacts/api/numeric'

# Add the methods that convert our classes into Concept types:

ValueClasses = [String, Date, DateTime, Time, Int, Real, AutoCounter]
ValueClasses.each{|c|
    c.send :extend, ActiveFacts::API::ValueClass
  }

class TrueClass #:nodoc:
  def verbalise(role_name = nil); role_name ? "#{role_name}: true" : "true"; end
end

class NilClass #:nodoc:
  def verbalise; "nil"; end
end

class Class
  # Make this Class into a Concept and if necessary its module into a Vocabulary.
  # The parameters are the names (Symbols) of the identifying roles.
  def identified_by *args
    raise "not an entity type" if respond_to? :value_type  # Don't make a ValueType into an EntityType
    include ActiveFacts::API::Entity
    initialise_entity_type(*args)
  end

  def is_entity_type
    respond_to?(:identifying_role_names)
  end
end

# REVISIT: Fix these NORMA types
class Decimal < Int #:nodoc:
end
class SignedInteger < Int #:nodoc:
end
class SignedSmallInteger < Int #:nodoc:
end
class UnsignedInteger < Int #:nodoc:
end
class UnsignedSmallInteger < Int #:nodoc:
end
class LargeLengthText < String #:nodoc:
end
class FixedLengthText < String #:nodoc:
end
class PictureRawData < String #:nodoc:
end
class DateAndTime < DateTime #:nodoc:
end
class Money < Decimal #:nodoc:
end
