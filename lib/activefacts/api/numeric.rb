# This hack is required because Integer & Float don't support new,
# and can't be sensibly subclassed. Just delegate to an instance var.
require 'delegate'
require 'date'

class Int < SimpleDelegator
  def initialize(i = nil)
    __setobj__(Integer(i))
  end

  def hash
    __getobj__.hash ^ super
  end

  def to_s
    __getobj__.to_s
  end

  def ==(o)
    __getobj__.==(o)
  end
end

class Real < SimpleDelegator
  def initialize(r = nil)
    __setobj__(Float(r))
  end

  def hash
    __getobj__.hash ^ super
  end

  def to_s
    __getobj__.to_s
  end

  def ==(o)
    __getobj__.==(o)
  end
end

# Ensure we don't pass a Constellation to the Date constructor:
class ::Date
  def self.__Is_A_Date; end
end

# The AutoCounter class is an integer, but only after the value has been established in the database
class AutoCounter
  def initialize(i = nil)
    @value = i
  end

  def assign(i)
    raise ArgumentError if @value
    @value = i.to_i
  end

  def defined?
    !@value.nil?
  end

  def to_s
    if self.defined?
      @value.to_s 
    else
      "new_#{object_id}"
    end
  end

  def self.coerce(i)
    raise ArgumentError unless @value
    [ i.to_i, @value ]
  end
end
