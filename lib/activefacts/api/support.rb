#
#       ActiveFacts Runtime API.
#       Various additions or patches to Ruby built-in classes, and some global support methods
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

class Symbol #:nodoc:
  def to_proc
    Proc.new{|*args| args.shift.__send__(self, *args)}
  end
end

class String #:nodoc:
  # This may be overridden by a version from ActiveSupport. For our purposes, either will work.
  def camelcase(first_letter = :upper)
    if first_letter == :upper
      gsub(/(^|[_\s]+)([A-Za-z])/){ $2.upcase }
    else
      gsub(/([_\s]+)([A-Za-z])/){ $2.upcase }
    end
  end

  def snakecase
    gsub(/([a-z])([A-Z])/,'\1_\2').downcase
  end

  def camelwords
    gsub(/-([a-zA-Z])/){ $1.upcase }.                 # Break and upcase on hyphenated words
      gsub(/([a-z])([A-Z])/,'\1_\2').
      split(/[_\s]+/)
  end
end

class Module #:nodoc:
  def modspace
    space = name[ 0...(name.rindex( '::' ) || 0)]
    space == '' ? Object : eval(space)
  end

  def basename
    name.gsub(/.*::/, '')
  end
end

module ActiveFacts #:nodoc:
  # If the args array ends with a hash, remove it.
  # If the remaining args are fewer than the arg_names,
  # extract values from the hash and append them to args.
  # Return the new args array and the hash.
  # In any case leave the original args unmodified.
  def self.extract_hash_args(arg_names, args)
    if Hash === args[-1]
      arg_hash = args[-1]     # Don't pop args, leave it unmodified
      args = args[0..-2]
      arg_hash = arg_hash.clone if (args.size < arg_names.size)
      while args.size < arg_names.size
        args << arg_hash[n = arg_names[args.size]]
        arg_hash.delete(n)
      end
    else
      arg_hash = {}
    end
    return args, arg_hash
  end
end
