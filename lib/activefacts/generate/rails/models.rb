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
	    puts "#{HEADER}. Generated at #{Time.now.strftime('%Y%m%d%H%M%S')}"
	  end
	  true
	end

	def generate_table table
	  old_out = @out
	  filename = rails_singular_name(table.name)+'.rb'

	  return unless create_if_ok filename

	  puts %Q{
module #{@concern}
  module #{rails_class_name(table.name)}
    extend ActiveSupport::Concern
    included do
#{
	    # belongs_to Associations
	    (
	      table.foreign_keys.map do |fk|
		from_columns = fk.from_columns.map{|column| rails_singular_name(column.name('_'))}
		to_columns = fk.to_columns.map{|column| rails_singular_name(column.name('_'))}
		fact_type = fk.reference.fact_type
		role = fact_type.all_role.detect { |r| r.object_type == fk.to }
		association_name = target_name = rails_singular_name fk.to.name
		role_name = role && role.role_name
		unless role_name
		  role_ref = fact_type.preferred_reading.role_sequence.all_role_ref.detect{|rr| rr.role == role}
		  if role_ref
		    role_name = [role_ref.leading_adjective, role.object_type.name, role_ref.trailing_adjective].compact*' '
		  end
		end
		if role_name and (role_name = rails_singular_name(role_name)) != target_name
		  class_name = ", :class_name => :#{target_name}"
		  association_name = rails_singular_name role_name
		end
		%Q{
      \# #{fk.reference.fact_type.default_reading}
      belongs_to :#{association_name}#{class_name}}
	      end +
	      table.references_to.map do |ref|
		if ref.is_simple_reference
		  if ref.fact_type.is_a? ActiveFacts::Metamodel::TypeInheritance and
		      table.absorbed_via and
		      absorbed_via.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
		    # Ignore references to secondary supertypes, when absorption is through primary
		    next nil
		  end

		  unless ref.from.is_table
		    # If the reference is not a table, it has been absorbed in one or more places
		    # We need a has_many from *each* such place.
		    next %Q{
      \# has_#{ref.is_one_to_one ? 'one' : 'many'} :#{rails_plural_name(ref.from.name)}, but that is fully absorbed here: #{ref.from.references_to.map{|r| r.from.name}.inspect}}
		  end

		  # Get the referencing (FK) column name.
		  # REVISIT: Where this name is the same as the name of the primary key column, we don't need to output it
		  # :class_name is never required.
		  from_column = ref.from.columns.detect{|c| c.references[0] == ref}
		  [
		    "\n      \# #{ref.fact_type.default_reading}\n"+
		    if ref.is_one_to_one
		      %Q{      has_one :#{association_name = rails_singular_name(ref.from.name)}}
		    else
		      %Q{      has_many :#{association_name = rails_plural_name(ref.from.name)}}
		    end +
		      %Q{, :foreign_key => :#{rails_singular_name(from_column.name)}, :dependent => destroy}
		  ] +
		    # If ref.from is a join table, we can emit a has_many :through for each other key
		    if ref.from.identifier_columns.length > 1
		      ref.from.identifier_columns.map do |ic|
			next nil if ic.references[0] == ref   # Skip the back-reference
			%Q{      has_many :#{rails_plural_name(ic.references[0].to.name)}, :through => :#{association_name}}
		      end
		    else
		      []
		    end

		elsif ref.is_absorbing
		  %Q{      # REVISIT: Skipped absorbed reference(s) from has_many :#{rails_plural_name(ref.from.name)}}
		else
		  nil
		end
	      end.flatten.compact
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
