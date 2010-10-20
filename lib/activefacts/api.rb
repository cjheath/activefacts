#
#       ActiveFacts Runtime API.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# The ActiveFacts API is heavily metaprogrammed, so difficult to document.
#
# It operates on the principle that a Ruby module is used to encapsulate
# a Vocabulary (the methods of the class Vocabulary are extend()ed into
# the module). A Vocabulary contains classes that either derive from a
# builtin Value type class (see standard_types.rb), or that use the method
# Class#_identified_by_ to become an Entity (their classes are extend()ed
# by the class Entity::ClassMethods). Each Value and Entity class also
# contains the methods of the class ObjectType.
#
# A module becomes a Vocabulary when the first ObjectType class is defined within it.
# A Constellation is a unique collection of ObjectType instances; no two instances may
# exist of the same value of a ValueType, or having the same identifying roles for
# an Entity type.
#
# Both kinds of ObjectTypes play Roles, which are either binary or unary. Each Role
# corresponds to an accessor method on Instances which are used to access the
# counterpart. Roles are created by the class methods *has_one*, *one_to_one*,
# and *maybe*. The former two create *two* roles, since the role has a counterpart
# object_type that also plays a role. In the case of a has_one role, the counterpart
# role is a set, implemented by the RoleValues class, and the accessor method is
# named beginning with *all_*.
#
# The roles of any Instance of any ObjectType may only be played by another Instance
# of the counterpart ObjectType. There are no raw values, only instances of ValueType
# classes.

require 'activefacts/api/support'               # General support code and core patches
require 'activefacts/api/vocabulary'            # A Ruby module may become a Vocabulary
require 'activefacts/api/role_proxy'            # Experimental proxy for has_one/one_to_one role accessors
require 'activefacts/api/instance_index'        # The index used by a constellation to record every instance
require 'activefacts/api/constellation'         # A Constellation is a query result or fact population
require 'activefacts/api/object_type'               # A Ruby class may become a ObjectType in a Vocabulary
require 'activefacts/api/role'                  # A ObjectType has a collection of Roles
require 'activefacts/api/role_values'           # The container used for sets of role players in many_one's
require 'activefacts/api/instance'              # An Instance is an instance of a ObjectType class
require 'activefacts/api/value'                 # A Value is an Instance of a value class (String, Numeric, etc)
require 'activefacts/api/entity'                # An Entity class is an Instance not of a value class
require 'activefacts/api/standard_types'        # Value classes are augmented so their subclasses may become Value Types
