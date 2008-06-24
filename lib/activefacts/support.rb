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
  def duplicates
    inject({}){|h,e| h[e]||=0; h[e] += 1; h}.reject{|k,v| v == 1}.keys
  end
end
