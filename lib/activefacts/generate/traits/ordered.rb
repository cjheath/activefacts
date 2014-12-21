#
#       ActiveFacts Generators.
#       Generation support superclass that sequences entity types to avoid forward references.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Generate #:nodoc:
    module OrderedTraits
      module DumpedFlag
	attr_reader :ordered_dumped

	def ordered_dumped!
	  @ordered_dumped = true
	end
      end

      module ObjectType
	include DumpedFlag
      end

      module FactType
	include DumpedFlag
      end

      module Constraint
	include DumpedFlag
      end

      include ActiveFacts::TraitInjector	# Must be last in this module, after all submodules have been defined
    end
  end
end
