# This hack is required because Integer & Float don't support new,
# and can't be sensibly subclassed:
class Int
  def initialize(i)
    @__value = i.to_i
  end

  alias __respond_to respond_to?
  def respond_to?(m, p = false)
    __respond_to(m, p) || @__value.respond_to?(m, p)
  end

  private
  attr_accessor :__value

  def method_missing(meth, *args, &block)
    @__value.send meth, *args, &block
  end
end

class Real
  def initialize(r)
    @__value = r.to_f
  end

  alias __respond_to respond_to?
  def respond_to?(m, p = false)
    __respond_to(m, p) || @__value.respond_to?(m, p)
  end

  private
  attr_accessor :__value

  def method_missing(meth, *args, &block)
    @__value.send meth, *args, &block
  end
end

