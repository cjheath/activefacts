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
  $debug_available = {}

  def debug_enabled(args)
    # Figure out whether this trace is enabled and nests:
    control = (!args.empty? && Symbol === args[0]) ? args.shift : :all
    key = control.to_s.sub(/_\Z/, '').to_sym
    $debug_available[key] ||= key
    enabled = $debug_nested || $debug_keys[key] || $debug_keys[:all]
    nesting = control.to_s =~ /_\Z/
    old_nested = $debug_nested
    $debug_nested = nesting
    [(enabled ? 1 : 0), $debug_keys[:all] ? " %-15s"%control : nil, old_nested]
  end

  def debug(*args, &block)
    unless $debug_indent
      # First time, initialise the tracing environment
      $debug_indent = 0
      $debug_keys = {}
      if (e = ENV["DEBUG"])
        e.split(/[^_a-zA-Z0-9]/).each{|k| $debug_keys[k.to_sym] = true }
        if $debug_keys[:help]
          at_exit {
            $stderr.puts "---\nDebugging keys available: #{$debug_available.keys.map{|s| s.to_s}.sort*", "}"
          }
        end
      end
    end

    enabled, show_key, old_nested = debug_enabled(args)

    # Emit the message if enabled or a parent is:
    puts "\##{show_key} "+"  "*$debug_indent + args.join(' ') if args.size > 0 && enabled == 1

    if block
      begin
        $debug_indent += enabled
        return yield       # Return the value of the block
      ensure
        $debug_indent -= enabled
        $debug_nesting = old_nested
      end
    else
      r = enabled == 1     # If no block, return whether enabled
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

  # Allow indexing using a custom comparator:
  def index value, &compare_block
    compare_block ||= lambda{|a,b| a == b}
    (0...size).detect{|i| compare_block[value, self[i]] }
  end

  # If any element, or sequence of elements, repeats immediately, delete the repetition.
  # Note that this doesn't remove all re-occurrences of a subsequence, only consecutive ones.
  # The compare_block allows a custom equality comparison.
  def elide_repeated_subsequences &compare_block
    compare_block ||= lambda{|a,b| a == b}
    i = 0
    while i < size  # Need to re-evaluate size on each loop - the array shrinks.
      j = i
      #puts "Looking for repetitions of #{self[i]}@[#{i}]"
      while tail = self[j+1..-1] and k = tail.index(self[i], &compare_block)
        length = j+1+k-i
        #puts "Found at #{j+1+k} (subsequence of length #{j+1+k-i}), will need to repeat to #{j+k+length}"
        if j+k+1+length <= size && compare_block[self[i, length], self[j+k+1, length]]
          #puts "Subsequence from #{i}..#{j+k} repeats immediately at #{j+k+1}..#{j+k+length}"
          slice!(j+k+1, length)
          j = i
        else
          j += k+1
        end
      end
      i += 1
    end
    self
  end
end
