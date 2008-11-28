#
# The ActiveFacts Runtime API Numeric hacks to handle immediate types.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
# This hack is required because Integer & Float don't support new,
# and can't be sensibly subclassed. Just delegate to an instance var.
#
require 'delegate'
require 'date'

# It's not possible to subclass Integer, so instead we delegate to it.
class Int < SimpleDelegator
  def initialize(i = nil)
    __setobj__(Integer(i))
  end

  def to_s
    __getobj__.to_s
  end

  def hash
    __getobj__.hash ^ self.class.hash
  end

  def eql?(o)
    self.class == o.class and __getobj__.eql?(Integer(o))
  end

  def ==(o)
    __getobj__.==(o)
  end

  def inspect
    "#{self.class.basename}:#{__getobj__.inspect}"
  end
end

# It's not possible to subclass Float, so instead we delegate to it.
class Real < SimpleDelegator
  def initialize(r = nil)
    __setobj__(Float(r))
  end

  def hash
    __getobj__.hash ^ self.class.hash
  end

  def to_s
    __getobj__.to_s
  end

  def eql?(o)
    self.class == o.class and __getobj__.eql?(Float(o))
  end

  def ==(o)
    __getobj__.==(o)
  end

  def inspect
    "#{self.class.basename}:#{__getobj__.inspect}"
  end
end

# A Date can be constructed from any Date subclass, not just using the normal date constructors.
class ::Date #:nodoc:
  class << self; alias_method :old_new, :new end
  def self.new(*a, &b)
    #puts "Constructing date with #{a.inspect} from #{caller*"\n\t"}"
    if (a.size == 1 && Date === a[0])
      a = a[0]
      civil(a.year, a.month, a.day, a.start)
    else
      civil(*a, &b)
    end
  end
end

# A DateTime can be constructed from any Date or DateTime subclass
class ::DateTime #:nodoc:
  class << self; alias_method :old_new, :new end
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
# You can use this new instance as a role value to identify an entity instance,
# or anywhere else for that matter.
# The assigned value will be filled out everywhere it needs to be, upon save.
class AutoCounter
  def initialize(i = :new)
    raise "AutoCounter #{self.class} may not be #{i.inspect}" unless i == :new or Integer === i
    # puts "new AutoCounter #{self.class} from\n\t#{caller.select{|s| s !~ %r{rspec}}*"\n\t"}"
    @value = i == :new ? nil : i
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

  def inspect
    "\#<AutoCounter "+to_s+">"
  end

  def hash
    to_s.hash ^ self.class.hash
  end

  def eql?(o)
    self.class == o.class and to_s.eql?(o.to_s)
  end

  def self.inherited(other)
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
