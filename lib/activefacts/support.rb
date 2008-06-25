module ActiveFacts
  $debug_indent = 0
  def debug(arg, &block)
    puts "  "*$debug_indent + arg if ENV["DEBUG"]
    $debug_indent += 1
    r = yield if block
    $debug_indent -= 1
    r
  end
end

class Array
  def duplicates(&b)
    inject({}) do |h,e|
      h[e] ||= 0
      h[e] += 1
      h
    end.reject do |k,v|
      v == 1
    end.keys
  end
end
