#
#       ActiveFacts Support code.
#       The debug method supports indented tracing.
#       Set the DEBUG environment variable to enable it. Search the code to find the DEBUG keywords, or use "all".
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
#module ActiveFacts
  $debug_indent = nil
  $debug_nested = false
  $debug_keys = nil
  def debug(*args, &block)
    unless $debug_indent
      # First time, initialise the tracing environment
      $debug_indent = 0
      $debug_keys = {}
      if (e = ENV["DEBUG"])
        e.split(/[^a-zA-Z0-9]/).each{|k| $debug_keys[k.to_sym] = true }
      end
    end

    # Figure out whether this trace is enabled and nests:
    control = (!args.empty? && Symbol === args[0]) ? args.shift : :all
    key = control.to_s.sub(/_\Z/, '')
    enabled = $debug_nested || $debug_keys[key.to_sym]
    nesting = control.to_s =~ /_\Z/
    old_nested = $debug_nested
    $debug_nested = nesting

    # Emit the message if enabled or a parent is:
    puts "# "+"  "*$debug_indent + args.join(' ') if args.size > 0 && enabled

    if block
      begin
        $debug_indent += 1 if enabled
        r = yield       # Return the value of the block
      ensure
        $debug_indent -= 1 if enabled
        $debug_nesting = old_nested
      end
    else
      r = enabled     # Return whether enabled
    end
    r
  end
#end

# Return all duplicate objects in the array (using hash-equality)
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
