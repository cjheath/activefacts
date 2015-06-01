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
	exclude_fks		Don't generate foreign key definitions for use with Rails 4 or the foreigner gem
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

	# We sort the columns here, not in the persistence layer, because it affects
	# the ordering of columns in an index :-(.
	def sorted_columns table, pk, fk_columns
	  table.columns.sort_by do |column|
	    [ # Emit columns alphabetically, but PK first, then FKs, then others
	      case
	      when i = pk.index(column)
		i
	      when fk_columns.include?(column)
		pk.size+1
	      else
		pk.size+2
	      end,
	      column.rails_name
	    ]
	  end
	end

	def generate_column table, pk, column
	  name = column.rails_name
	  type, params, constraints = column.type
	  length = params[:length]
	  length &&= length.to_i
	  scale = params[:scale]
	  scale &&= scale.to_i
	  type, length = *column.rails_type

	  length_name = type == 'decimal' ? 'precision' : 'limit'
	  length_option = length ? ", :#{length_name} => #{length}" : ''
	  scale_option = scale ? ", :scale => #{scale}" : ''

	  comment = column.comment
	  null_option = ", :null => #{!column.is_mandatory}"
	  if pk.size == 1 && pk[0] == column
	    case type
	    when 'serial'
	      type = "primary_key"
	    when 'uuid'
	      type = "uuid, :default => 'gen_random_uuid()', :primary_key => true"
	    end
	  else
	    case type
	    when 'serial'
	      type = 'integer'	    # An integer foreign key
	    end
	  end

	  (@include_comments ? ["    \# #{comment}"] : []) +
	  [
	    %Q{    t.column "#{name}", :#{type}#{length_option}#{scale_option}#{null_option}}
	  ]
	end

	def generate_columns table, pk, fk_columns
	  sc = sorted_columns(table, pk, fk_columns)
	  lines = sc.map do |column|
	    generate_column table, pk, column
	  end
	  lines.flatten
	end

	def generate_table table, foreign_keys
	  ar_table_name = table.rails_name

	  pk = table.identifier_columns
	  if pk[0].is_auto_assigned
	    identity_column = pk[0]
	    warn "Warning: redundant column(s) after #{identity_column.name} in primary key of #{ar_table_name}" if pk.size > 1
	  end

	  # Get the list of references that give rise to foreign keys:
	  fk_refs = table.references_from.select{|ref| ref.is_simple_reference }

	  # Get the list of columns that embody the foreign keys:
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

	  puts %Q{  create_table "#{ar_table_name}", :id => false, :force => true do |t|}

	  columns = generate_columns table, pk, fk_columns

	  unless @exclude_fks
	    table.foreign_keys.each do |fk|
	      from_columns = fk.from_columns.map{|column| column.rails_name}
	      to_columns = fk.to_columns.map{|column| column.rails_name}
	      foreign_keys.concat(
		if (from_columns.length == 1)
		  [
		    "    add_foreign_key :#{fk.from.rails_name}, :#{fk.to.rails_name}, :column => :#{from_columns[0]}, :primary_key => :#{to_columns[0]}, :on_delete => :cascade",
		    "    add_index :#{fk.from.rails_name}, [:#{from_columns[0]}], :unique => false"
		  ]
		else
		  # This probably isn't going to work without Dr Nic's CPK gem:
		  [
		    "    add_foreign_key :#{fk.to.rails_name}, :#{fk.from.rails_name}, :column => [:#{from_columns.join(':, ')}], :primary_key => [:#{to_columns.join(':, ')}], :on_delete => :cascade"
		  ]
		end
	      )
	    end
	  end

	  indices = table.indices
	  index_text = []
	  indices.each do |index|
	    next if index.is_primary && index.columns.size == 1	  # We've handled this already

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

	def generate(out = $>)      #:nodoc:
	  return if @helping
	  @out = out

	  foreign_keys = []

	  # If we get index names that need to be truncated, add a counter to ensure uniqueness
	  dup_id = 0

	  puts "#\n# schema.rb auto-generated using ActiveFacts for #{@vocabulary.name} on #{Date.today}\n#\n\n"
	  puts "ActiveRecord::Base.logger = Logger.new(STDOUT)\n"
	  puts "ActiveRecord::Schema.define(:version => #{Time.now.strftime('%Y%m%d%H%M%S')}) do"
	  puts "  enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')\n"

	  @vocabulary.tables.each do |table|
	    generate_table table, foreign_keys
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
