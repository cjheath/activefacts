# This hack is required because Integer & Float don't support new,
# and can't be sensibly subclassed. Just delegate to an instance var,
# except for a few things that matter to us, like class().
require 'facets/basicobject'

class Int < BasicObject
  def initialize(i)
    @__value = i.to_i
  end

  define_method(:class) { __self__.class }

  private
  attr_accessor :__value

  def method_missing(meth, *args, &block)
    r = @__value.send meth, *args, &block
    # $stdout.puts "Calling #{@__value}.#{self.class}\##{meth}(#{args.map{|a|a.inspect}*", "}) --> #{r.inspect}"
    # r
  end
end

class Real < BasicObject
  def initialize(r)
    @__value = r.to_f
  end

  define_method(:class) { __self__.class }

  private
  attr_accessor :__value

  def method_missing(meth, *args, &block)
    r = @__value.send meth, *args, &block
    # $stdout.puts "Calling #{@__value}.#{self.class}\##{meth}(#{args.map{|a|a.inspect}*", "}) --> #{r.inspect}"
    # r
  end
end
