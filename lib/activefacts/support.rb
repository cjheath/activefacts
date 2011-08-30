#
#       ActiveFacts Support code.
#       The debug method supports indented tracing.
#       Set the DEBUG environment variable to enable it. Search the code to find the DEBUG keywords, or use "all".
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
#module ActiveFacts
  $debug_indent = nil
  $debug_nested = false   # Set when a block enables all enclosed debugging
  $debug_keys = nil
  $debug_available = {}

  def debug_initialize
    # First time, initialise the tracing environment
    $debug_indent = 0
    $debug_keys = {}
    if (e = ENV["DEBUG"])
      e.split(/[^_a-zA-Z0-9]/).each{|k| debug_enable(k) }
      if $debug_keys[:help]
        at_exit {
          $stderr.puts "---\nDebugging keys available: #{$debug_available.keys.map{|s| s.to_s}.sort*", "}"
        }
      end
    end
  end

  def debug_keys
    $debug_available.keys
  end

  def debug_enabled key
    !key.empty? && $debug_keys[key.to_sym]
  end

  def debug_enable key
    !key.empty? && $debug_keys[key.to_sym] = true
  end

  def debug_disable key
    !key.empty? && $debug_keys.delete(key.to_sym)
  end

  def debug_toggle key
    !key.empty? and debug_enabled(key) ? (debug_disable(key); false) : (debug_enable(key); true)
  end

  def debug_selected(args)
    # Figure out whether this trace is enabled (itself or by :all), if it nests, and if we should print the key:
    key =
      if Symbol === args[0]
        control = args.shift
        if (s = control.to_s) =~ /_\Z/
          nested = true
          s.sub(/_\Z/, '').to_sym     # Avoid creating new strings willy-nilly
        else
          control
        end
      else
        :all
      end

    $debug_available[key] ||= key   # Remember that this debug was requested, for help
    enabled = $debug_nested ||      # This debug is enabled because it's in a nested block
              $debug_keys[key] ||   # This debug is enabled in its own right
              $debug_keys[:all]     # This debug is enabled because all are
    $debug_nested = nested
    [
      (enabled ? 1 : 0),
      $debug_keys[:all] ? " %-15s"%control : nil
    ]
  end

  def debug_show(*args)
    debug_initialize unless $debug_indent

    enabled, key_to_show = debug_selected(args)

    # Emit the message if enabled or a parent is:
    if args.size > 0 && enabled == 1
      puts "\##{key_to_show} " +
        '  '*$debug_indent +
        args.
#          A laudable aim, certainly, but in practise the Procs leak and slow things down:
#          map{|a| a.respond_to?(:call) ? a.call : a}.
          join(' ')
    end
    $debug_indent += enabled
    enabled
  end

  def debug(*args, &block)
    begin
      old_indent, old_nested, enabled  = $debug_indent, $debug_nested, debug_show(*args)
      return (block || proc { enabled == 1 }).call
    ensure
      $debug_indent, $debug_nested = old_indent, old_nested
    end
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

  if RUBY_VERSION =~ /^1\.8/
    # Fake up Ruby 1.9's Array#index method, mostly
    alias_method :__orig_index, :index
    def index *a, &b
      if a.size == 0
        raise "Not faking Enumerator for #{RUBY_VERSION}" if !b
        (0...size).detect{|i| return i if b.call(self[i]) }
      else
        __orig_index(*a, &b)
      end
    end
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
      while tail = self[j+1..-1] and k = tail.index {|e| compare_block.call(e, self[i]) }
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

# Load the ruby debugger before everything else, if requested
if debug :debug
  begin
    require 'ruby-debug'
    Debugger.start # (:post_mortem => true)  # Some Ruby versions crash on post-mortem debugging
  rescue LoadError
    # Ok, no debugger, tough luck.
  end

  if debug :trap
    trap('SIGINT') do
      puts "Stopped at:\n\t"+caller*"\n\t"
      debugger
      true
    end
  end
end
