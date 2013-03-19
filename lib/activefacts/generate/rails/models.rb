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
	  # Crunch spaces and pluralise the first part, all in snake_case
	  name.pop if name.is_a?(Array) and name.last == []
	  name = name[0]*'_' if name.is_a?(Array) and name.size == 1
	  if name.is_a?(Array)
	    name = ActiveSupport::Inflector.tableize((name[0]*'_').gsub(/\s+/, '_')) +
	      '_' +
	      ActiveSupport::Inflector.underscore((name[1..-1].flatten*'_').gsub(/\s+/, '_'))
	  else
	    ActiveSupport::Inflector.tableize(name.gsub(/\s+/, '_'))
	  end
	end

	def rails_singular_name name
	  # Crunch spaces and convert to snake_case
	  name = name.flatten*'_' if name.is_a?(Array)
	  ActiveSupport::Inflector.underscore(name.gsub(/\s+/, '_'))
	end

	def rails_class_name name
	  name = name*'_' if name.is_a?(Array)
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

	def model_body table
	  %Q{module #{rails_class_name(table.name)}
  extend ActiveSupport::Concern
  included do} +
	    (table.identifier_columns.length == 1 ? %Q{
    self.primary_key = '#{rails_singular_name(table.identifier_columns[0].name)}'
} : ''
	    ) +

	    (
	      # belongs_to Associations
	      table.foreign_keys.map do |fk|
		references = crunch_successive_subclassing(fk.references)
		association_name = rails_singular_name(fk.to_name.join('_'))

		foreign_key = ""
		if association_name != rails_singular_name(fk.to.name)
		  # A different class_name is implied, emit an explicit one:
		  class_name = ", :class_name => '#{rails_class_name fk.to.name}'"
		  from_column = fk.from_columns
		  foreign_key = ", :foreign_key => :#{rails_singular_name(fk.from_columns[0].name)}"
		end
		%Q{
    \# #{fk.verbalised_path}
    belongs_to :#{association_name}#{class_name}#{foreign_key}}
	      end +

	      # has_one/has_many Associations
	      table.foreign_keys_to.sort_by{|fk| fk.describe}.map do |fk|
		# Get the jump reference
		ref = fk.jump_reference

		# Get the referencing (FK) column name.
		from_column = fk.from_columns
		if from_column.size > 1
		  raise "Can't emit Rails associations for multi-part foreign key with #{fk.references.inspect}. Did you mean to use --transform/surrogate"
		end
		from_column = from_column[0]

		[
		  "\n    \# #{fk.verbalised_path}" +
		  "\n" +
		  if ref.is_one_to_one
		    %Q{    has_one :#{association_name = rails_singular_name(fk.from_name)}}
		  else
		    %Q{    has_many :#{association_name = rails_plural_name(fk.from_name)}}
		  end +
		    %Q{, :class_name => '#{rails_class_name(fk.from.name)}', :foreign_key => :#{rails_singular_name(from_column.name)}, :dependent => :destroy}
		] +
		  # If ref.from is a join table, we can emit a has_many :through for each other key
		  if ref.from.identifier_columns.length > 1
		    ref.from.identifier_columns.map do |ic|
		      next nil if ic.references[0] == ref or	# Skip the back-reference
			ic.references[0].is_unary		# or use rails_plural_name(ic.references[0].to_names) ?
		      # This far association name needs to be augmented for its role name
		      far_association_name = rails_plural_name(ic.references[0].to.name)
		      %Q{    has_many :#{far_association_name}, :through => :#{association_name}} # \# via #{ic.name}}
		    end
		  else
		    []
		  end
	      end.flatten.compact
	    ) * "\n" + %Q{
  end
end
}
	end

	def generate_table table
	  old_out = @out
	  filename = rails_singular_name(table.name)+'.rb'

	  return unless create_if_ok filename

	  puts "\n"
	  puts "module #{@concern}" if @concern
	  puts model_body(table).gsub(/^/, @concern ? '  ' : '')
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
