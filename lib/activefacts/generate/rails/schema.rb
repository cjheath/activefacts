#
#       ActiveFacts Generators.
#       Generate a Rails-friendly schema.rb from an ActiveFacts vocabulary.
#
# Copyright (c) 2012 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/persistence'
require 'activefacts/mapping/rails'

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
	    ar_table_name = table.rails_name

	    pk = table.identifier_columns
	    identity_column = pk[0] if pk[0].is_auto_assigned

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
		":primary_key => :#{pk[0].rails_name}"
	      else
		":id => #{needs_rails_id_field}"
	      end

	    puts %Q{  create_table "#{ar_table_name}", #{identity}, :force => true do |t|}

	    # We sort the columns here, not in the persistence layer, because it affects
	    # the ordering of columns in an index :-(.

	    columns = table.
		columns.
		sort_by do |column|
		  [ # Emit columns alphabetically, but PK first, then FKs, then others
		    case
		    when column == identity_column
		      0
		    when fk_columns.include?(column)
		      1
		    else
		      2
		    end,
		    column.rails_name
		  ]
		end.
		map do |column|
	      next [] if move_pk_to_create_table_call and column == pk[0]
	      name = column.rails_name
	      type, params, constraints = column.type
	      length = params[:length]
	      length &&= length.to_i
	      scale = params[:scale]
	      scale &&= scale.to_i
	      type, length = Persistence::rails_type(type, length)

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
		from_columns = fk.from_columns.map{|column| column.rails_name}
		to_columns = fk.to_columns.map{|column| column.rails_name}
		foreign_keys <<
		  if (from_columns.length == 1)
		    "    add_foreign_key :#{fk.from.rails_name}, :#{fk.to.rails_name}, :column => :#{from_columns[0]}, :primary_key => :#{to_columns[0]}, :dependent => :cascade"
		  else
		    # This probably isn't going to work without Dr Nic's CPK gem:
		    "    add_foreign_key :#{fk.to.rails_name}, :#{fk.from.rails_name}, :column => [:#{from_columns.join(':, ')}], :primary_key => [:#{to_columns.join(':, ')}], :dependent => :cascade"
		  end
	      end
	    end

	    indices = table.indices
	    index_text = []
	    indices.each do |index|
	      next if move_pk_to_create_table_call and index.is_primary	  # We've handled this already

	      index_name = index.rails_name

	      unique = !index.columns.detect{|column| !column.is_mandatory} and !@closed_world
	      index_text << %Q{  add_index "#{ar_table_name}", ["#{index.columns.map{|c| c.rails_name}*'", "'}"], :name => :#{index_name}#{
		unique ? ", :unique => true" : ''
	      }}
	    end

	    puts columns.join("\n")
	    puts "  end\n\n"

	    puts index_text.join("\n")
	    puts "\n" unless index_text.empty?
	  end

	  unless @exclude_fks
	    puts '  unless ENV["EXCLUDE_FKS"]'
	    puts foreign_keys.join("\n")
	    puts '  end'
	  end
	  puts "end"
	end

      end
    end
  end
end

ActiveFacts::Registry.generator('rails/schema', ActiveFacts::Generate::Rails::SchemaRb)
