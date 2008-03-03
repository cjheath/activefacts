# This hack is required because Integer & Float don't support new,
# and can't be sensibly subclassed. Just delegate to an instance var.
require 'delegate'
require 'date'

class Int < SimpleDelegator
  def initialize(i = nil)
    __setobj__(i)
  end

  def hash
    __getobj__.hash ^ super
  end

  def ==(o)
    __getobj__.==(o)
  end
end

class Real < SimpleDelegator
  def initialize(r = nil)
    __setobj__(r)
  end

  def hash
    __getobj__.hash ^ super
  end

  def ==(o)
    __getobj__.==(o)
  end
end

# Ensure we don't pass a Constellation to the Date constructor:
class ::Date
  def self.__Is_A_Date; end
end
