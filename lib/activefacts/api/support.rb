#
# ActiveFacts runtime API.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
# Note that we still require facets/basicobject, see numeric.rb
#

class Symbol #:nodoc:
  def to_proc
    Proc.new{|*args| args.shift.__send__(self, *args)}
  end
end

class String #:nodoc:
  def camelcase(first=false, on='_\s')
    if first
      gsub(/(^|[#{on}]+)([A-Za-z])/){ $2.upcase }
    else
      gsub(/([#{on}]+)([A-Za-z])/){ $2.upcase }
    end
  end

  def snakecase
    gsub(/([A-Z]+)([A-Z])/,'\1_\2').gsub(/([a-z])([A-Z])/,'\1_\2').downcase
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
