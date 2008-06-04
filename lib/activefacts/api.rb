#
# ActiveFacts runtime API.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
# Note that we still require facets/basicobject, see numeric.rb
#

require 'activefacts/api/support'               # General support code and core patches
require 'activefacts/api/vocabulary'            # A Ruby module may become a Vocabulary
require 'activefacts/api/constellation'         # A Constellation is a query result or fact population
require 'activefacts/api/concept'               # A Ruby class may become a Concept in a Vocabulary
require 'activefacts/api/role'                  # A Concept has a collection of Roles
require 'activefacts/api/instance'              # An Instance is an instance of a Concept class
require 'activefacts/api/value'                 # A Value is an Instance of a value class (String, Numeric, etc)
require 'activefacts/api/entity'                # An Entity class is an Instance not of a value class
require 'activefacts/api/standard_types'        # Value classes are augmented so their subclasses may become Value Types
