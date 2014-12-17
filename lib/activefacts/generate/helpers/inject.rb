require 'activefacts/vocabulary'

module ActiveFacts
  module Generate
    module Injector
      def self.included other
	overlap = Metamodel.constants & other.constants
	overlap.each do |const|
	  mix_into = Metamodel.const_get(const)
	  mix_in = other.const_get(const)
	  mix_into.instance_exec {
	    include(mix_in)
	  }
	end
      end
    end
  end
end
