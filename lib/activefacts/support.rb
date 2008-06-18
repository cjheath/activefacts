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
