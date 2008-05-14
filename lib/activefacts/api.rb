#
# ActiveFacts runtime API.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
# Note that we still require facets/basicobject, see numeric.rb
#

class Symbol
  def to_proc
    Proc.new{|*args| args.shift.__send__(self, *args)}
  end
end

class String
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

class Module
  def modspace
    space = name[ 0...(name.rindex( '::' ) || 0)]
    space == '' ? Object : eval(space)
  end

  def basename
    name.gsub(/.*::/, '')
  end
end

require 'activefacts/api/vocabulary'            # A Ruby module may become a Vocabulary
require 'activefacts/api/constellation'         # A Constellation is a query result or fact population
require 'activefacts/api/concept'               # A Ruby class may become a Concept in a Vocabulary
require 'activefacts/api/instance'              # An Instance is an instance of a Concept class
require 'activefacts/api/value'                 # A Value is an Instance of a value class (String, Numeric, etc)
require 'activefacts/api/entity'                # An Entity class is an Instance not of a value class
require 'activefacts/api/standard_types'        # Value classes are augmented so their subclasses may become Value Types
