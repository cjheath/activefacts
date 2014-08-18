#
#       ActiveFacts Generators.
#       Clone the compiled vocabulary to measure the performance
#
# Copyright (c) 2013 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    module Performance
      # Generate Rails models for the vocabulary
      # Invoke as
      #   afgen --rails/schema[=options] <file>.cql
      class Clone

      private

	def initialize(vocabulary, *options)
	  @vocabulary = vocabulary
	  @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
	  help if options.include? "help"
	  @count = 10
	  options.delete_if { |option| @count = $1.to_i if option =~ /^count=(.*)/ }
	  @keep = options.delete("keep")
	end

	def help
	  @helping = true
	  warn %Q{Options for --performance/clone:
	count=N			Clone N times (default 10)
	keep			Keep all clones until the end
}
	end

	def warn *a
	  $stderr.puts *a
	end

	def puts s
	  @out.puts s
	end

      public
	def generate(out = $>)      #:nodoc:
	  return if @helping
	  @out = out

	  @start_time = Time.now
	  @clones = []
	  @count.times do |i|
	    print "#{i+1}:\t"
	    @out.flush
	    clone = @vocabulary.constellation.clone
	    @clones << clone if @keep
	    time = Time.now
	    puts "#{time-@start_time}"
	  end
	end

      end
    end
  end
end

ActiveFacts::Registry.generator('performance/clone', ActiveFacts::Generate::Performance::Clone)
