#
#       ActiveFacts Generators.
#       Generate models for Rails from an ActiveFacts vocabulary.
#
#       Models should normally be generated into "app/models/auto",
#       then extend(ed) into your real models.
#
# Copyright (c) 2013 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/persistence'
require 'active_support'

module ActiveFacts
  module Generate
    module Rails
      # Generate Rails models for the vocabulary
      # Invoke as
      #   afgen --rails/schema[=options] <file>.cql
      class Models

	HEADER = "# Auto-generated from CQL, edits will be lost"

      private
	include Persistence

	def initialize(vocabulary, *options)
	  @vocabulary = vocabulary
	  @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
	  help if options.include? "help"
	  options.delete_if { |option| @output = $1 if option =~ /^output=(.*)/ }
	  @concern = 'Concern'
	  options.delete_if { |option| @concern = $1 if option =~ /^concern=(.*)/ }
	end

	def help
	  @helping = true
	  warn %Q{Options for --rails/schema:
	output=dir		Overwrite model files into this output directory
	concern=name		Namespace (defaults to Concern)
}
	end

	def warn *a
	  $stderr.puts *a
	end

	def puts s
	  @out.puts s
	end

	def pluralise name
	  # Crunch spaces and convert to a plural form in snake_case
	  ActiveSupport::Inflector.tableize(name.gsub(/\s+/, ''))
	end

	def columnise name
	  # Crunch spaces and convert to snake_case
	  ActiveSupport::Inflector.underscore(name.gsub(/\s+/, ''))
	end

      public
	def generate(out = $>)      #:nodoc:
	  return if @helping
	  @out = out

	  ok = true
	  @vocabulary.tables.each do |table|
	    ok &= generate_table(table)
	  end
	  $stderr.puts "\# #{@vocabulary.name} generated with errors" unless ok
	  ok
	end

	def create_if_ok filename
	  # Create a file in the output directory, being careful not to overwrite carelessly
	  if @output
	    pathname = (@output+'/'+filename).gsub(%r{//+}, '/')
	    File.open(pathname, 'r') do |existing|
	      first_lines = existing.read(1024)	  # Make it possible to pass over a magic charset comment
	      if first_lines !~ %r{^#{HEADER}}
		$stderr.puts "not overwriting non-generated file #{pathname}"
		return false
	      end
	    end rescue nil
	    @individual_file = @out = File.open(pathname, 'w')
	    puts "#{HEADER}. Generated at #{Time.now.strftime('%Y%m%d%H%M%S')}"
	  end
	  true
	end

	def generate_table table
	  old_out = @out
	  filename = columnise(table.name)+'.rb'

	  return unless create_if_ok filename

	  puts %Q{
module #{@concern}
  module #{ActiveSupport::Inflector.classify(table.name)}
    extend ActiveSupport::Concern
    included do

#{
	    # belongs_to Associations
	    (
	      table.foreign_keys.map do |fk|
		from_columns = fk.from_columns.map{|column| columnise(column.name('_'))}
		to_columns = fk.to_columns.map{|column| columnise(column.name('_'))}
		%Q{      belongs_to :#{columnise(fk.to.name)}}
	      end +
	      table.references_to.map do |ref|
		if ref.is_simple_reference
		  if ref.fact_type.is_a? ActiveFacts::Metamodel::TypeInheritance
		     if absorbed_via && TypeInheritance === absorbed_via.fact_type
		       # Ignore references to secondary supertypes, when absorption is through primary
		       next nil
		     end
		  end

		  %Q{      has_many :#{ActiveSupport::Inflector.tableize(ref.from.name)}}
		elsif ref.is_absorbing
		  %Q{      # REVISIT: Skipped absorbed reference(s) from has_many :#{ActiveSupport::Inflector.tableize(ref.from.name)}}
		else
		  nil
		end
	      end.compact
	    ) * "\n"
}
    end
  end
end
}

	  true	  # We succeeded
	ensure
	  @out = old_out
	  @individual_file.close if @individual_file
	end

      end
    end
  end
end

ActiveFacts::Registry.generator('rails/models', ActiveFacts::Generate::Rails::Models)
