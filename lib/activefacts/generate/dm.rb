#
#       ActiveFacts Generators.
#       Generate Ruby code for Data Mapper from an ActiveFacts vocabulary.
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
require 'activefacts/generate/helpers/oo'

module ActiveFacts
  module Generate
    class DM < Helpers::OO #:nodoc:
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
        puts "require 'datamapper'\n\n"
      end

      def key_fields(ref, reverse = false)
        # Compute and return child_key and parent_key if necessary
        fk = ref.from.foreign_keys.detect{|k| k.reference == ref}
        child_key = fk.from_columns.map{|c| column_name(c)}
        parent_key = fk.to_columns.map{|c| column_name(c)}
        if child_key != parent_key
          c, p = *(reverse ? ['parent', 'child'] : ['child', 'parent'])
          ", :#{c}_key => [:#{child_key*', :'}], :#{p}_key => [:#{parent_key*', :'}]"
        else
          ''
        end
      end

      public

        def generate(out = $>)      #:nodoc:
          @out = out

          # Calculate the relational absorption:
          tables = @vocabulary.tables

          # Figure out which ObjectType will be models (tables and their subtypes)
          models =
            @vocabulary.all_object_type.sort_by{|o| o.name}.select do |o|
              next false if o.name =~ /_?ImplicitBooleanValueType/
              o.is_table || (o.absorbed_via && o.absorbed_via.role_type == :supertype)
            end
          is_model = models.inject({}) { |h, m| h[m] = true; h }

          puts "require 'dm-core'"
          puts "require 'dm-constraints'"
          puts "\n"

          # Dump tables until all done, subtypes before supertypes:
          until models.empty?
            # Choose another object type that we can dump now:
            o = models.detect do |o|
              next true if o.is_table
              next true if a = o.absorbed_via and a.role_type == :supertype and supertype = a.from and !models.include?(supertype)
              false
            end
            models.delete(o)

            supertype = (a = o.absorbed_via and a.role_type == :supertype) ? supertype = a.from : nil
            if o.is_a?(ActiveFacts::Metamodel::EntityType)
              if secondary_supertypes = o.supertypes-[supertype] and
                secondary_supertypes.size > 0 and
                secondary_supertypes.detect do |sst|
                  sst_ref_facts = sst.preferred_identifier.role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq
                  non_identifying_inheritable_references =
                    sst.references_from.reject do |ref|
                      sst_ref_facts.include?(ref.fact_type)
                    end
                  non_identifying_inheritable_references.size > 0
                end
                raise "Cannot map classes like #{o.name} with roles inherited from external supertypes (#{secondary_supertypes.map{|t|t.name}*", "})"
              end
              pi = o.preferred_identifier
              identifying_role_refs = pi.role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}
              identifying_facts = ([o.fact_type]+identifying_role_refs.map{|rr| rr.role.fact_type }).compact.uniq
            else
              identifying_facts = []
            end

            # REVISIT: STI fails where the base class is absorbed into another table, like Incident in Insurance for example.
            # In this case you get the subtype fields absorbed and should not get an STI model.

            puts "class #{class_name(o.name)}#{supertype ? " < #{class_name(supertype.name)}" : ''}"
            puts "  include DataMapper::Resource\n\n" unless supertype

            columns = o.columns
            o.references_from.each do |ref|
              # A (set of) columns
              if !columns
                # absorbed subtypes didn't have columns populated
                columns = o.all_columns({})
              end

              next if [:subtype, :supertype].include?(ref.role_type)
              # debugger if ref_columns.detect{|c| [:subtype, :supertype].include?(c.references[0].role_type)}
              ref_columns = columns.select{|c| c.references[0] == ref }
              # puts "  \# #{ref.reading}:"
              ref_columns.each do |column|
                type, params, constraints = column.type
                length = params[:length]
                length &&= length.to_i
                scale = params[:scale]
                scale &&= scale.to_i
                type, length = normalise_type(type, length)
                key = identifying_facts.include?(column.references[0].fact_type) ||
                  (identifying_facts.empty? && ref.is_self_value)
                cname = column_name(column)
                required = column.is_mandatory && !key ? ", :required => true" : "" # Key fields are implicitly required
                if type == 'Serial'
                  if !key || o.preferred_identifier.role_sequence.all_role_ref.size != 1
                    type = 'Integer'
                  else
                    key = false # This is implicit
                  end
                end
                $stderr.puts "Warning: non-mandatory key field #{o.name}.#{column.name} is forced to mandatory" if !column.is_mandatory && key
                puts "  property :#{column_name(column)}, #{type}#{length ? ", :length => "+length.to_s : ''}#{required}#{key ? ', :key => true' : ''}\t\# #{column.comment}"
              end

              if is_model[ref.to]
                # An association
                reverse = false
                association_type =
                  case ref.role_type
                  when :one_one
                    reverse = true
                    "has 1,"
                  when :one_many, :many_one
                    "belongs_to"
                  when :supertype
                    next
                  when :subtype
                    next
                  else
                    raise "role type #{ref.role_type} not handled"
                  end

                association_name = (ref.to_names*'_')
                model_name = association_name != ref.to.name ? model_name = ", '#{class_name(ref.to.name)}'" : ''
                comment = o.fact_type ? "#{association_name} is involved in #{o.name}" : ref.reading
                keys = key_fields(ref, reverse)
                puts "  #{association_type} :#{association_name.downcase}#{model_name}#{keys}\t\# #{comment}"
              end
            end

            # Emit the "has n," associations
            # REVISIT: Need to use ActiveSupport to pluralise these names, or disable inflexion somehow.
            o.references_to.each do |ref|
              next unless is_model[ref.from]
              constraint = ''
              association_type =
                case ref.role_type
                when :one_one
                  "has 1,"
                when :many_one, :one_many
                  constraint = ', :constraint => :destroy'    # REVISIT: Check mandatory, and use nullify?
                  "has n,"
                else
                  next
                end
              prr = ref.fact_type.preferred_reading.role_sequence.all_role_ref.detect{|rr| rr.role == ref.to_role}
              association_name = (ref.from_names*'_')
              if prr && (prr.role.role_name || prr.leading_adjective || prr.trailing_adjective)
                association_name += "_as_"+symbol_name(ref.to_names*'_')
              end
              model_name = association_name != ref.from.name ? model_name = ", '#{class_name(ref.from.name)}'" : ''
              comment = o.is_a?(ActiveFacts::Metamodel::EntityType) && o.fact_type ? "#{association_name} is involved in #{o.name}" : ref.reading
              keys = key_fields(ref)

              puts "  #{association_type} :#{association_name.downcase}#{model_name}#{keys}\t\# #{comment}"
            end
            puts "end\n\n"
          end
        end


      # Return DataMapper type and (modified?) length for the passed base type
      def normalise_type(type, length)
        dm_type = case type
          when /^Auto ?Counter$/
            'Serial'

          when /^Unsigned ?Integer$/,
            /^Signed ?Integer$/,
            /^Unsigned ?Small ?Integer$/,
            /^Signed ?Small ?Integer$/,
            /^Unsigned ?Tiny ?Integer$/
            length = nil
            'Integer'

          when /^Decimal$/
            'Decimal'

          when /^Fixed ?Length ?Text$/, /^Char$/
            'String'
          when /^Variable ?Length ?Text$/, /^String$/
            'String'
          when /^Large ?Length ?Text$/, /^Text$/
            'Text'

          when /^Date ?And ?Time$/, /^Date ?Time$/
            'DateTime'
          when /^Date$/
            'DateTime'
          when /^Time$/
            'DateTime'
          when /^Auto ?Time ?Stamp$/
            'DateTime'

          when /^Money$/
            'Decimal'
          when /^Picture ?Raw ?Data$/, /^Image$/
            'String'
          when /^Variable ?Length ?Raw ?Data$/, /^Blob$/
            'String'
          when /^BIT$/
            'Boolean'
          else
            # raise "DataMapper type unknown for standard type #{type}"
            type
          end
        [dm_type, length]
      end

    end
  end
end
