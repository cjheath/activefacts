#
#       ActiveFacts Runtime API
#       Standard types extensions.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# These extensions add ActiveFacts ObjectType and Instance behaviour into base Ruby value classes,
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

# Add the methods that convert our classes into ObjectType types:

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
  # Make this Class into a ObjectType and if necessary its module into a Vocabulary.
  # The parameters are the names (Symbols) of the identifying roles.
  def identified_by *args
    raise "#{basename} is not an entity type" if respond_to? :value_type  # Don't make a ValueType into an EntityType
    include ActiveFacts::API::Entity
    initialise_entity_type(*args)
  end

  def is_entity_type
    respond_to?(:identifying_role_names)
  end
end

require 'bigdecimal'
class Decimal < BigDecimal #:nodoc:
  extend ActiveFacts::API::ValueClass
  # The problem here is you can't pass a BigDecimal to BigDecimal.new. Fix it.
  def self.new(v)
    if v.is_a?(BigDecimal)
      super(v.to_s)
    else
      super
    end
  end
end

# These types are generated on conversion from NORMA's types:
class Char < String #:nodoc:  # FixedLengthText
end
class Text < String #:nodoc:  # LargeLengthText
end
class Image < String #:nodoc: # PictureRawData
end
class SignedInteger < Int #:nodoc:
end
class UnsignedInteger < Int   #:nodoc:
end
class AutoTimeStamp < String  #:nodoc: AutoTimeStamp
end
class Blob < String           #:nodoc: VariableLengthRawData
end
unless Object.const_defined?("Money")
  class Money < Decimal       #:nodoc:
  end
end
