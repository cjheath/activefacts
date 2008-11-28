#
# ActiveFacts runtime API.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
# The ActiveFacts API is heavily metaprogrammed, so difficult to document.
#
# It operates on the principle that a Ruby module is used to encapsulate
# a Vocabulary (the methods of the class Vocabulary are extend()ed into
# the module). A Vocabulary contains classes that either derive from a
# builtin Value type class (see standard_types.rb), or that use the method
# Class#_identified_by_ to become an Entity (their classes are extend()ed
# by the class Entity::ClassMethods). Each Value and Entity class also
# contains the methods of the class Concept.
#
# A module becomes a Vocabulary when the first Concept class is defined within it.

require 'activefacts/api/support'               # General support code and core patches
require 'activefacts/api/vocabulary'            # A Ruby module may become a Vocabulary
require 'activefacts/api/constellation'         # A Constellation is a query result or fact population
require 'activefacts/api/concept'               # A Ruby class may become a Concept in a Vocabulary
require 'activefacts/api/role'                  # A Concept has a collection of Roles
require 'activefacts/api/instance'              # An Instance is an instance of a Concept class
require 'activefacts/api/value'                 # A Value is an Instance of a value class (String, Numeric, etc)
require 'activefacts/api/entity'                # An Entity class is an Instance not of a value class
require 'activefacts/api/standard_types'        # Value classes are augmented so their subclasses may become Value Types
