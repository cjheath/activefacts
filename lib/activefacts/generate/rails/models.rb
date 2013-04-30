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
#require 'activefacts/generate/helpers/rails'
require 'activefacts/mapping/rails'
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

	def initialize(vocabulary, *options)
	  @vocabulary = vocabulary
	  @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
	  help if options.include? "help"
	  options.delete_if { |option| @output = $1 if option =~ /^output=(.*)/ }
	  @concern = nil
	  options.delete_if { |option| @concern = $1 if option =~ /^concern=(.*)/ }
	  @validations = true
	  options.delete_if { |option| @validations = eval($1) if option =~ /^validation=(.*)/ }
	end

	def help
	  @helping = true
	  warn %Q{Options for --rails/schema:
	output=dir		Overwrite model files into this output directory
	concern=name		Namespace for the concerns
	validation=false	Disable generation of validations
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
	  list_extant_files if @output

	  # Populate all foreignkeys first:
	  @vocabulary.tables.each { |table| table.foreign_keys }
	  ok = true
	  @vocabulary.tables.each do |table|
	    ok &= generate_table(table)
	  end
	  $stderr.puts "\# #{@vocabulary.name} generated with errors" unless ok
	  delete_old_generated_files if @output
	  ok
	end

	def list_extant_files
	  @preexisting_files = Dir[@output+'/*.rb']
	end

	def delete_old_generated_files
	  remaining = []
	  cleaned = 0
	  @preexisting_files.each do |pathname|
	    if generated_file_exists(pathname) == true
	      File.unlink(pathname) 
	      cleaned += 1
	    else
	      remaining << pathname
	    end
	  end
	  $stderr.puts "Cleaned up #{cleaned} old generated files" if @preexisting_files.size > 0
	  $stderr.puts "Remaining non-generated files:\n\t#{remaining*"\n\t"}" if remaining.size > 0
	end

	def generated_file_exists pathname
	  File.open(pathname, 'r') do |existing|
	    first_lines = existing.read(1024)	  # Make it possible to pass over a magic charset comment
	    if first_lines.length == 0 or first_lines =~ %r{^#{HEADER}}
	      return true
	    end
	  end
	  return false	  # File exists, but is not generated
	rescue Errno::ENOENT
	  return nil	  # File does not exist
	end

	def create_if_ok filename
	  # Create a file in the output directory, being careful not to overwrite carelessly
	  if @output
	    pathname = (@output+'/'+filename).gsub(%r{//+}, '/')
	    @preexisting_files.reject!{|f| f == pathname }    # Don't clean up this file
	    if generated_file_exists(pathname) == false
	      $stderr.puts "not overwriting non-generated file #{pathname}"
	      @individual_file = nil
	      return
	    end
	    @individual_file = @out = File.open(pathname, 'w')
	    puts "#{HEADER}"
	  end
	  true
	end

	def to_associations table
	  # belongs_to Associations
	  table.foreign_keys.map do |fk|
	    association_name = fk.rails_from_association_name

	    foreign_key = ""
	    if association_name != Persistence::rails_singular_name(fk.to.name)
	      # A different class_name is implied, emit an explicit one:
	      class_name = ", :class_name => '#{fk.to.rails_class_name}'"
	      from_column = fk.from_columns
	      foreign_key = ", :foreign_key => :#{fk.from_columns[0].rails_name}"
	    end

	    %Q{
    \# #{fk.verbalised_path}
    belongs_to :#{association_name}#{class_name}#{foreign_key}}
	  end
	end

	def from_associations table
	  # has_one/has_many Associations
	  table.foreign_keys_to.sort_by{|fk| fk.describe}.map do |fk|
	    # Get the jump reference

	    if fk.from_columns.size > 1
	      raise "Can't emit Rails associations for multi-part foreign key with #{fk.references.inspect}. Did you mean to use --transform/surrogate"
	    end

	    association_type, association_name = *fk.rails_to_association

	    ref = fk.jump_reference
	    [
	      "\n    \# #{fk.verbalised_path}" +
	      "\n" +
		%Q{    #{association_type} :#{association_name}} +
		%Q{, :class_name => '#{fk.from.rails_class_name}'} +
		%Q{, :foreign_key => :#{fk.from_columns[0].rails_name}} +
		%Q{, :dependent => :destroy}
	    ] +
	      # If ref.from is a join table, we can emit a has_many :through for each other key
	      # REVISIT Could alternately do this for all belongs_to's in ref.from
	      if ref.from.identifier_columns.length > 1
		ref.from.identifier_columns.map do |ic|
		  next nil if ic.references[0] == ref or	# Skip the back-reference
		    ic.references[0].is_unary		# or use rails_plural_name(ic.references[0].to_names) ?
		  # This far association name needs to be augmented for its role name
		  far_association_name = ic.references[0].to.rails_name
		  %Q{    has_many :#{far_association_name}, :through => :#{association_name}} # \# via #{ic.name}}
		end
	      else
		[]
	      end
	  end.flatten.compact
	end

	def column_constraints table
	  return [] unless @validations
	  ccs =
	    table.columns.map do |column|
	      name = column.rails_name
	      column.is_mandatory &&
		!column.is_auto_assigned ? [
		"    validates_presence_of :#{name}"
	      ] : []
	    end.flatten
	  ccs.unshift("") unless ccs.empty?
	  ccs
	end

	def model_body table
	  %Q{module #{table.rails_class_name}
  extend ActiveSupport::Concern
  included do} +
	    (table.identifier_columns.length == 1 ? %Q{
    self.primary_key = '#{table.identifier_columns[0].rails_name}'
} : ''
	    ) +

	    (
	      to_associations(table) +
	      from_associations(table) +
	      column_constraints(table)
	    ) * "\n" +
	    %Q{
  end
end
}
	end

	def generate_table table
	  old_out = @out
	  filename = table.rails_name+'.rb'

	  return unless create_if_ok filename

	  puts "\n"
	  puts "module #{@concern}" if @concern
	  puts model_body(table).gsub(/^./, @concern ? '  \0' : '\0')
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
