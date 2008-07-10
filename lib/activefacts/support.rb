#module ActiveFacts
  $debug_indent = nil
  $debug_keys = nil
  def debug(*args, &block)
    # Initialise the tracing environment
    unless $debug_indent
      $debug_indent = 0
      $debug_keys = {}
      if (e = ENV["DEBUG"])
        e.split.each{|k| $debug_keys[k.to_sym] = true }
      end
    end

    # Figure out whether this trace is enabled:
    control = (!args.empty? && Symbol === args[0]) ? args.shift : :all
    enabled = $debug_keys[control] || $debug_indent > 0

    # Emit the message if enabled or a parent is:
    puts "# "+"  "*$debug_indent + args.join(' ') if args.size > 0 && enabled

    if block
      $debug_indent += 1 if enabled
      r = yield       # Return the value of the block
      $debug_indent -= 1 if enabled
    else
      r = enabled     # Return whether enabled
    end
    r
  end
#end

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
