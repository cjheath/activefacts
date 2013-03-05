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
	  @concern = nil
	  options.delete_if { |option| @concern = $1 if option =~ /^concern=(.*)/ }
	end

	def help
	  @helping = true
	  warn %Q{Options for --rails/schema:
	output=dir		Overwrite model files into this output directory
	concern=name		Namespace for the concerns
}
	end

	def warn *a
	  $stderr.puts *a
	end

	def puts s
	  @out.puts s
	end

	def rails_plural_name name
	  # Crunch spaces and convert to a plural form in snake_case
	  ActiveSupport::Inflector.tableize(name.gsub(/\s+/, '_'))
	end

	def rails_singular_name name
	  # Crunch spaces and convert to snake_case
	  ActiveSupport::Inflector.underscore(name.gsub(/\s+/, '_'))
	end

	def rails_class_name name
	  ActiveSupport::Inflector.classify(name.gsub(/\s+/, ''))
	end

      public
	def generate(out = $>)      #:nodoc:
	  return if @helping
	  @out = out

	  # Populate all foreignkeys first:
	  @vocabulary.tables.each { |table| table.foreign_keys }
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
	      if first_lines.length > 1 and first_lines !~ %r{^#{HEADER}}
		$stderr.puts "not overwriting non-generated file #{pathname}"
		return false
	      end
	    end rescue nil  # Handle File.open failure
	    @individual_file = @out = File.open(pathname, 'w')
	    puts "#{HEADER}"
	  end
	  true
	end

	# Crunch consecutive type inheritance to the last one.
	def crunch_successive_subclassing references
	  references.inject([]) do |a, r|
	    if a[-1] && a[-1].fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) && r.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
	      a.pop
	    end
	    a << r
	  end
	end

	def generate_table table
	  old_out = @out
	  filename = rails_singular_name(table.name)+'.rb'

	  return unless create_if_ok filename

	  puts "\n"
	  puts "module #{@concern}" if @concern
	  puts %Q{module #{rails_class_name(table.name)}
  extend ActiveSupport::Concern
  included do
    self.primary_key = '#{rails_singular_name(table.identifier_columns[0].name)}'
#{

	  # belongs_to Associations
	  (
	    table.foreign_keys.map do |fk|
	      references = crunch_successive_subclassing(fk.references)
	      association_name = rails_singular_name(references.map(&:to_names).flatten.join('_'))

	      if association_name != rails_singular_name(fk.to.name)
	      #if association_name != rails_singular_name(references[-1].to_names.join('_'))
		# A different class_name is implied, emit an explicit one:
		class_name = ", :class_name => '#{rails_class_name fk.to.name}'"
	      end
	      %Q{
    \# #{fk.references.map{|r| r.fact_type.default_reading}*' and '}
    belongs_to :#{association_name}#{class_name}}
	    end +

	    table.foreign_keys_to.sort_by{|fk| fk.describe}.map do |fk|
	      ref = fk.references[-1]

	      # REVISIT: Need to check that this is appropriate here:
	      if ref.is_simple_reference
		if ref.fact_type.is_a? ActiveFacts::Metamodel::TypeInheritance and
		    table.absorbed_via and
		    absorbed_via.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
		  # Ignore references to secondary supertypes, when absorption is through primary
		  next nil
		end

#	        debugger if fk.references.size > 1
=begin
                from_ref = fk.references[0]
                if !from_ref.to.is_table or !ref.from.is_table	# There's absorption on one end at least
                  $stdout.puts("fk origin #{fk.references[0].to.name} is absorbed into #{fk.from.name}") if !from_ref.to.is_table && fk.references[0].to != fk.from
                  $stdout.puts("fk target #{fk.references[-1].to.name} is absorbed into #{fk.to.name}") if !ref.from.is_table && fk.references[-1].to != fk.to
                  debugger
                  p fk
                end
=end

#		unless ref.from.is_table
#		  # If the reference is not a table, it has been absorbed in one or more places
#		  # We need a has_many from *each* such place.
#		  next %Q{
#    \# has_#{ref.is_one_to_one ? 'one' : 'many'} :#{rails_plural_name(ref.from.name)}, but that is fully absorbed here: #{ref.from.references_to.map{|r| r.from.name}.inspect}}
#		end

		# Get the referencing (FK) column name.
		# REVISIT: Where this name is the same as the name of the primary key column, we don't need to output it
		# :class_name is never required.
		from_column = ref.from.columns.detect{|c| c.references[0] == ref}
		[
		  "\n    \# #{ref.fact_type.default_reading}\n"+
		  if ref.is_one_to_one
		    %Q{    has_one :#{association_name = rails_singular_name(ref.from.name)}}
		  else
		    %Q{    has_many :#{association_name = rails_plural_name(ref.from.name)}}
		  end +
		    %Q{, :foreign_key => :#{rails_singular_name(from_column.name)}, :dependent => :destroy}
		] +
		  # If ref.from is a join table, we can emit a has_many :through for each other key
		  if ref.from.identifier_columns.length > 1
		    ref.from.identifier_columns.map do |ic|
		      next nil if ic.references[0] == ref   # Skip the back-reference
		      %Q{    has_many :#{rails_plural_name(ic.references[0].to.name)}, :through => :#{association_name}} # \# via #{ic.name}}
		    end
		  else
		    []
		  end

	      elsif ref.is_absorbing
		%Q{    # REVISIT: Skipped absorbed reference(s) from has_many :#{rails_plural_name(ref.from.name)}}
	      else
		nil
	      end
	    end.flatten.compact
	  ) * "\n"
}
  end
end
}.gsub(/^/, @concern ? '  ' : '')
	  puts 'end' if @concern

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
