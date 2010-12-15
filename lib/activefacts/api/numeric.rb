#
#       ActiveFacts Runtime API
#       Numeric and Date delegates and hacks to handle immediate types.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# These delegates are required because Integer & Float don't support new,
# and can't be sensibly subclassed. Just delegate to an instance var.
# Date and DateTime don't have a sensible new() method, so we monkey-patch one here.
#
require 'delegate'
require 'date'

# It's not possible to subclass Integer, so instead we delegate to it.
class Int < SimpleDelegator
  def initialize(i = nil)               #:nodoc:
    __setobj__(Integer(i))
  end

  def to_s                              #:nodoc:
    __getobj__.to_s
  end

  def hash                              #:nodoc:
    __getobj__.hash ^ self.class.hash
  end

  def eql?(o)                           #:nodoc:
    self.class == o.class and __getobj__.eql?(Integer(o))
  end

  def ==(o)                             #:nodoc:
    __getobj__.==(o)
  end

  def is_a?(k)
    __getobj__.is_a?(k)
  end

  def inspect
    "#{self.class.basename}:#{__getobj__.inspect}"
  end
end

# It's not possible to subclass Float, so instead we delegate to it.
class Real < SimpleDelegator
  def initialize(r = nil)                               #:nodoc:
    __setobj__(Float(r))
  end

  def hash                              #:nodoc:
    __getobj__.hash ^ self.class.hash
  end

  def to_s                              #:nodoc:
    __getobj__.to_s
  end

  def eql?(o)                           #:nodoc:
    self.class == o.class and __getobj__.eql?(Float(o))
  end

  def ==(o)                             #:nodoc:
    __getobj__.==(o)
  end

  def is_a?(k)
    __getobj__.is_a?(k)
  end

  def inspect                           #:nodoc:
    "#{self.class.basename}:#{__getobj__.inspect}"
  end
end

# A Date can be constructed from any Date subclass, not just using the normal date constructors.
class ::Date
  class << self; alias_method :old_new, :new end
  # Date.new cannot normally be called passing a Date as the parameter. This allows that.
  def self.new(*a, &b)
    #puts "Constructing date with #{a.inspect} from #{caller*"\n\t"}"
    if (a.size == 1 && a[0].is_a?(Date))
      a = a[0]
      civil(a.year, a.month, a.day, a.start)
    elsif (a.size == 1 && a[0].is_a?(String))
      parse(a[0])
    else
      civil(*a, &b)
    end
  end
end

# A DateTime can be constructed from any Date or DateTime subclass
class ::DateTime
  class << self; alias_method :old_new, :new end
  # DateTime.new cannot normally be called passing a Date or DateTime as the parameter. This allows that.
  def self.new(*a, &b)
    #puts "Constructing DateTime with #{a.inspect} from #{caller*"\n\t"}"
    if (a.size == 1)
      a = a[0]
      if (DateTime === a)
        civil(a.year, a.month, a.day, a.hour, a.min, a.sec, a.start)
      elsif (Date === a)
        civil(a.year, a.month, a.day, a.start)
      else
        civil(*a, &b)
      end
    else
      civil(*a, &b)
    end
  end
end

# The AutoCounter class is an integer, but only after the value
# has been established in the database.
# Construct it with the value :new to get an uncommitted value.
# You can use this new instance as a value of any role of this type, including to identify an entity instance.
# The assigned value will be filled out everywhere it needs to be, upon save.
class AutoCounter
  def initialize(i = :new)
    raise "AutoCounter #{self.class} may not be #{i.inspect}" unless i == :new or i.is_a?(Integer)
    # puts "new AutoCounter #{self.class} from\n\t#{caller.select{|s| s !~ %r{rspec}}*"\n\t"}"
    @value = i == :new ? nil : i
  end

  # Assign a definite value to an AutoCounter; this may only be done once
  def assign(i)
    raise ArgumentError if @value
    @value = i.to_i
  end

  # Ask whether a definite value has been assigned
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

  # An AutoCounter may only be used in numeric expressions after a definite value has been assigned
  def self.coerce(i)
    raise ArgumentError unless @value
    [ i.to_i, @value ]
  end

  def inspect
    "\#<AutoCounter "+to_s+">"
  end

  def hash                              #:nodoc:
    to_s.hash ^ self.class.hash
  end

  def eql?(o)                           #:nodoc:
    self.class == o.class and to_s.eql?(o.to_s)
  end

  def self.inherited(other)             #:nodoc:
    def other.identifying_role_values(*args)
      return nil if args == [:new]  # A new object has no identifying_role_values
      return new(*args)
    end
    super
  end

private
  def clone
    raise "Not allowed to clone AutoCounters"
  end
end
