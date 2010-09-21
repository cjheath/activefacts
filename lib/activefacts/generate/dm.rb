#
#       ActiveFacts Generators.
#       Generate Ruby code for Data Mapper from an ActiveFacts vocabulary.
#
# REVISIT: This is very rudimentary and will probably only work for the simplest cases.
# I'm not even sure that the approach is right, working from a relational schema and
# trying to guess the DM models that will result in the required tables.  We probably
# should begin with the OO mapping instead, just using 'persistence' to determine tables...
#
# A testing strategy:
#   Generate and load a set of models
#   call DataMapper::finalize to check they're consistent
#   call DataMapper::Spec.cleanup_models to delete them again
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    class DM #:nodoc:
      # Generate SQL for DataMapper for an ActiveFacts vocabulary.
      # Invoke as
      #   afgen --dm[=options] <file>.cql
      #   Options:
      #     dir=<mixins directory>
      #   Example:
      #     afgen --dm=dir=app/mixins MyApp.cql
      include Persistence

      def initialize(vocabulary, *options)
        @vocabulary = vocabulary
        @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
        @mixins = options.grep(/^dir=/)[-1]
        @mixins && @mixins.sub!(/^dir=/,'')
      end

      def puts s
        @out.puts s
      end

      # Return SQL type and (modified?) length for the passed base type
      def normalise_type(type, length)
        sql_type = case type
          when /^Auto ?Counter$/
            'int'

          when /^Unsigned ?Integer$/,
            /^Signed ?Integer$/,
            /^Unsigned ?Small ?Integer$/,
            /^Signed ?Small ?Integer$/,
            /^Unsigned ?Tiny ?Integer$/
            s = case
              when length <= 8
                'tinyint'
              when length <= 16
                'shortint'
              when length <= 32
                'int'
              else
                'bigint'
              end
            length = nil
            s

          when /^Decimal$/
            'decimal'

          when /^Fixed ?Length ?Text$/, /^Char$/
            'char'
          when /^Variable ?Length ?Text$/, /^String$/
            'varchar'
          when /^Large ?Length ?Text$/, /^Text$/
            'text'

          when /^Date ?And ?Time$/, /^Date ?Time$/
            'datetime'
          when /^Date$/
            'datetime' # SQLSVR 2K5: 'date'
          when /^Time$/
            'datetime' # SQLSVR 2K5: 'time'
          when /^Auto ?Time ?Stamp$/
            'timestamp'

          when /^Money$/
            'decimal'
          when /^Picture ?Raw ?Data$/, /^Image$/
            'image'
          when /^Variable ?Length ?Raw ?Data$/, /^Blob$/
            'varbinary'
          when /^BIT$/
            'bit'
          else type # raise "SQL type unknown for standard type #{type}"
          end
        [sql_type, length]
      end

      def model_file(name)
        @mixins+'/'+name.gsub(/\s/,'')+'.rb'
      end

      def class_name(name)
        name.gsub(/\s/,'')
      end

      def column_name(column)
        column.name('_').snakecase
      end

      def symbol_name(name)
        name.gsub(/\s/,'_').snakecase
      end

      def new_output(name)
        return unless @mixins
        @out.flush
        @out = File.open(model_file(name), "w")
        puts "require 'dm-core'\n\n"
      end

      public
        def generate(out = $>)      #:nodoc:
          @out = out

          @vocabulary.tables.each do |table|
            new_output(table.name)

            puts "class #{class_name(table.name)}"
            puts "  include DataMapper::Resource\n\n"

            has_associations = false

            #debugger if table.name == 'Vehicle Incident'

            # All belongs_to and has1's:
            columns = table.columns
            table.references_from.
              select{|ref| ref.is_simple_reference }.
              each do |ref|
                #puts "to #{table.name} in #{ref.inspect}"
                fk_columns = columns.select{|c| c.references[0] == ref}
                fk_column_names = fk_columns.map{|c| symbol_name(c.name)}
                pk_columns = ref.to.identifier_columns
                pk_column_names = pk_columns.map{|c| symbol_name(c.name)}
                type = [:supertype, :subtype, :one_one].include?(ref.role_type) ? 'has 1,' : 'belongs_to'

                # If the target was absorbed, find the target model
                # The target model may be a subtype, absorbed into a supertype table
                eventual_target = to = ref.to
                until eventual_target.is_table
                  break if eventual_target.absorbed_via.role_type == :subtype  # Handle STI
                  eventual_target = eventual_target.absorbed_via.from
                end

                target_class_name = eventual_target.name.gsub(/\s/,'')
                # REVISIT: Need to account for the role names here:
                if ref.to_role and rn = ref.to_role.role_name
                  to = nil
                  association_name = symbol_name(rn)
                else
                  association_name = symbol_name(ref.to.name)
                end

                puts "  #{type} :#{association_name}" +
                  (eventual_target != to ? ", '#{target_class_name}'" : '') +
                  (fk_column_names != pk_column_names ?
                    ", :child_key => [:#{fk_column_names*', :'}], :parent_key => [:#{pk_column_names*', :'}]" : ''
                  )
                has_associations = true
              end

            # All "has n"s:
            table.references_to.
              select{|ref| ref.is_simple_reference }.
              each do |ref|
                from_columns = ref.from.columns
                pk_columns = ref.to.identifier_columns
                pk_column_names = pk_columns.map{|c| symbol_name(c.name)}

                if ref.from.is_table
                  fk_columns = from_columns.select{|c| c.references[0] == ref}
                  fk_column_names = fk_columns.map{|c| symbol_name(c.name)}
                  type = [:supertype, :subtype, :one_one].include?(ref.role_type) ? 'has 1' : 'has n'

                  # If the target was absorbed, find the target model
                  # The target model may be a subtype, absorbed into a supertype table
                  eventual_target = ref.from
                  until eventual_target.is_table
                    break if eventual_target.absorbed_via.role_type == 'subtype'  # Handle STI
                    eventual_target = eventual_target.absorbed_via.from
                  end

                  target_class_name = eventual_target.name.gsub(/\s/,'')
                  # REVISIT: Need to account for the role names here:
                  if ref.from_role && ref.from_role.role_name
                    debugger
                    p ref # .from_role.role_name
                  end
                  association_name = symbol_name(ref.from.name)

                  puts "  #{type}, :#{association_name}" +
                    (eventual_target != ref.from ? ", '#{target_class_name}'" : '') +
                    (fk_column_names != pk_column_names ?
                      ", :child_key => [:#{fk_column_names*', :'}], :parent_key => [:#{pk_column_names*', :'}]" : ''
                    )
                else
                  # REVISIT: "from" is fully absorbed, so we need to emit a "has n" for each ref.from.references_to (transitively)
                end

                if (ref.from.fact_type)
                  # REVISIT: Objectified fact type, do "has n,... :through =>"
                  #puts "  has n, #{symbol_name(ref.from.name))}"
                end
                has_associations = true
              end

            puts "\n" if has_associations

            # We sort the columns here, not in the persistence layer, because it affects
            # the ordering of columns in an index :-(.
            absorbed_subtype_columns = {}
            table.columns.sort_by { |column| column.name(@underscore) }.map do |column|
              type, params, constraints = column.type
              length = params[:length]
              length &&= length.to_i
              scale = params[:scale]
              scale &&= scale.to_i
              type, length = normalise_type(type, length)

              if column.references[0].role_type != :supertype
                # REVISIT: Add :key => true for PK columns
                puts "  property :#{column_name(column)}, :#{type}#{length ? ", :length => "+length.to_s : ''}, :required => #{true}"
              else
                subtype = column.references.detect{|r| r.role_type != :supertype}.from
                (absorbed_subtype_columns[subtype] ||= []) <<
                  "  property :#{column_name(column)}, :#{type}#{length ? ", :length => "+length.to_s : ''}, :required => #{true}"
              end
            end

            # Indexes
            indices = table.indices
            indices.each do |index|
              # REVISIT: No indexing is performed here
              # puts "index [#{columns.map{|c| column_name(c)}*','}]"
            end

            puts "end\n\n"

            # Emit STI'd subtypes:
            until absorbed_subtype_columns.empty?
              subtypes = absorbed_subtype_columns.keys.sort_by{|c| c.name}
              subtypes.each do |subtype|
                columns = absorbed_subtype_columns[subtype]
                supertype_ref = subtype.absorbed_via
                if !absorbed_subtype_columns[supertype = supertype_ref.from]
                  puts "class #{class_name(subtype.name)} < #{class_name(supertype.name)}"
                  puts "  include DataMapper::Resource\n\n"
                  absorbed_subtype_columns[subtype].each do |prop|
                    # The property names here are the column names, which include the class name.
                    # REVISIT: Need to separate the property name from the column name
                    puts prop
                  end
                  puts "end\n\n"
                  absorbed_subtype_columns.delete(subtype)
                end
              end
            end

          end
        end

    end
  end
end
