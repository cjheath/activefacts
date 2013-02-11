#
#       ActiveFacts Generators.
#       Generate a Rails-friendly schema.rb from an ActiveFacts vocabulary.
#
# Copyright (c) 2012 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/persistence'
require 'active_support'

module ActiveFacts
  module Generate
    module Rails
      # Generate a Rails-friendly schema for the vocabulary
      # Invoke as
      #   afgen --rails/schema[=options] <file>.cql
      class SchemaRb
      private
	include Persistence

	def initialize(vocabulary, *options)
	  @vocabulary = vocabulary
	  @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
	  help if options.include? "help"
	  @exclude_fks = options.include? "exclude_fks"
	  @include_comments = options.include? "include_comments"
	  @closed_world = options.include? "closed_world"
	end

	def help
	  @helping = true
	  warn %Q{Options for --rails/schema:
	exclude_fks		Don't generate foreign key definitions for use with the foreigner gem
	include_comments	Generate a comment for each column showing the absorption path
	closed_world		Set this if your DBMS only allows one null in a unique index (MS SQL)
}
	end

	def warn *a
	  $stderr.puts *a
	end

	def puts s
	  @out.puts s
	end

	# Return ActiveRecord type and (modified?) length for the passed base type
	def normalise_type(type, length)
	  rails_type = case type
	    when /^Auto ?Counter$/
	      'integer'	    # REVISIT: Need to detect surrogate ID fields and handle them correctly

	    when /^Unsigned ?Integer$/,
	      /^Integer$/,
	      /^Signed ?Integer$/,
	      /^Unsigned ?Small ?Integer$/,
	      /^Signed ?Small ?Integer$/,
	      /^Unsigned ?Tiny ?Integer$/
	      length = nil
	      'integer'

	    when /^Decimal$/
	      'decimal'

	    when /^Fixed ?Length ?Text$/, /^Char$/
	      'string'
	    when /^Variable ?Length ?Text$/, /^String$/
	      'string'
	    when /^Large ?Length ?Text$/, /^Text$/
	      'text'

	    when /^Date ?And ?Time$/, /^Date ?Time$/
	      'datetime'
	    when /^Date$/
	      'datetime'
	    when /^Time$/
	      'time'
	    when /^Auto ?Time ?Stamp$/
	      'timestamp'

	    when /^Money$/
	      'decimal'
	    when /^Picture ?Raw ?Data$/, /^Image$/, /^Variable ?Length ?Raw ?Data$/, /^Blob$/
	      'binary'
	    when /^BIT$/
	      'boolean'
	    else type # raise "ActiveRecord type unknown for standard type #{type}"
	    end
	  [rails_type, length]
	end

	def rails_plural_name name
	  # Crunch spaces and convert to a plural form in snake_case
	  ActiveSupport::Inflector.tableize(name.gsub(/\s+/, ''))
	end

	def rails_singular_name name
	  # Crunch spaces and convert to snake_case
	  ActiveSupport::Inflector.underscore(name.gsub(/\s+/, ''))
	end

      public
	def generate(out = $>)      #:nodoc:
	  return if @helping
	  @out = out

	  foreign_keys = []

	  # If we get index names that need to be truncated, add a counter to ensure uniqueness
	  dup_id = 0

	  puts "#\n# schema.rb auto-generated using ActiveFacts for #{@vocabulary.name} on #{Date.today}\n#\n\n"
	  puts "ActiveRecord::Schema.define(:version => #{Time.now.strftime('%Y%m%d%H%M%S')}) do"

	  @vocabulary.tables.each do |table|
	    ar_table_name = rails_plural_name(table.name)

	    pk = table.identifier_columns
	    identity_column = pk[0] if pk.size == 1 && pk[0].is_auto_assigned

	    fk_refs = table.references_from.select{|ref| ref.is_simple_reference }
	    fk_columns = table.columns.select do |column|
	      column.references[0].is_simple_reference
	    end

	    # Detect if this table is a join table.
	    # Join tables have multi-part primary keys that are made up only of foreign keys
	    is_join_table = pk.length > 1 and
	      !pk.detect do |pk_column|
		!fk_columns.include?(pk_column)
	      end
	    warn "Warning: #{table.name} has a multi-part primary key" if pk.length > 1 and !is_join_table

	    needs_rails_id_field = (pk.length > 1) && !is_join_table
	    move_pk_to_create_table_call = !needs_rails_id_field &&
		pk.length == 1 &&
		(to = pk[0].references[-1].to) &&
		to.supertypes_transitive.detect{|t| t.name == 'Auto Counter'}

	    identity =
	      if move_pk_to_create_table_call
		":primary_key => :#{rails_singular_name(pk[0].name('_'))}"
	      else
		":id => #{needs_rails_id_field}"
	      end

	    puts %Q{  create_table "#{ar_table_name}", #{identity}, :force => true do |t|}

	    # We sort the columns here, not in the persistence layer, because it affects
	    # the ordering of columns in an index :-(.

	    columns = table.
		columns.
		sort_by do |column|
		  [
		    case
		    when column == identity_column
		      0
		    when fk_columns.include?(column)
		      1
		    else
		      2
		    end,
		    column.name('_') 
		  ]
		end.
		map do |column|
	      next [] if move_pk_to_create_table_call and column == pk[0]
	      name = rails_singular_name(column.name('_'))
	      type, params, constraints = column.type
	      length = params[:length]
	      length &&= length.to_i
	      scale = params[:scale]
	      scale &&= scale.to_i
	      type, length = normalise_type(type, length)

	      length_name = type == 'decimal' ? 'precision' : 'limit'

	      primary = (!is_join_table && pk.include?(column)) ? ", :primary => true" : ''
	      comment = column.comment
	      (@include_comments ? ["    \# #{comment}"] : []) +
	      [
		%Q{    t.#{type}\t"#{name}"#{
		    length ? ", :#{length_name} => #{length}" : ''
		  }#{
		    scale ? ", :scale => #{scale}" : ''
		  }#{
		    column.is_mandatory ? ', :null => false' : ''
		  }#{primary}}
	      ]
	    end.flatten

	    unless @exclude_fks
	      table.foreign_keys.each do |fk|
		from_columns = fk.from_columns.map{|column| rails_singular_name(column.name('_'))}
		to_columns = fk.to_columns.map{|column| rails_singular_name(column.name('_'))}
		foreign_keys <<
		  if (from_columns.length == 1)
		    "  add_foreign_key :#{rails_plural_name(fk.from.name)}, :#{rails_plural_name(fk.to.name)}, :column => :#{from_columns[0]}, :primary_key => :#{to_columns[0]}, :dependent => :cascade"
		  else
		    # This probably isn't going to work without Dr Nic's CPK gem:
		    "  add_foreign_key :#{rails_plural_name(fk.to.name)}, :#{rails_plural_name(fk.from.name)}, :column => [:#{from_columns.join(':, ')}], :primary_key => [:#{to_columns.join(':, ')}], :dependent => :cascade"
		  end
	      end
	    end

	    indices = table.indices
	    index_text = []
	    indices.each do |index|
	      abbreviated_column_names = index.abbreviated_column_names('_')*""
	      column_names = index.column_names('_').map{|c| rails_singular_name(c) }
	      index_name = "index_#{ar_table_name+'_on_'+column_names*'_'}"
	      index_name = index_name[0, 60] + (dup_id += 1).to_s if index_name.length > 63

	      unique = !index.columns.detect{|column| !column.is_mandatory} and !@closed_world
	      index_text << %Q{  add_index "#{ar_table_name}", ["#{column_names*'", "'}"], :name => :#{index_name
	      }#{
		unique ? ", :unique => true" : ''
	      }}
	    end

	    puts columns.join("\n")
	    puts "  end\n\n"

	    puts index_text.join("\n")
	    puts "\n" unless index_text.empty?
	  end

	  puts foreign_keys.join("\n")
	  puts "end"
	end

      end
    end
  end
end

ActiveFacts::Registry.generator('rails/schema', ActiveFacts::Generate::Rails::SchemaRb)
