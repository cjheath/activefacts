#
#       ActiveFacts Generators.
#       Generate Ruby classes for the ActiveFacts API from an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts'
require 'activefacts/vocabulary'
require 'activefacts/generate/helpers/oo'
require 'activefacts/generate/traits/ruby'
require 'activefacts/mapping/rails'

module ActiveFacts
  module Generate

    # Generate Ruby module containing classes for an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --ruby[=options] <file>.cql
    # Options are comma or space separated:
    # * help list available options
    # * sql Emit the sql mapping for tables/columns (REVISIT: not functional at present)
    class RUBY < Helpers::OO
    private

      def set_option(option)
        @mapping = false
        case option
        when 'help', '?'
          $stderr.puts "Usage:\t\tafgen --ruby[=option,option] input_file.cql\n"+
              "\t\tmapping={sql|rails}\tEmit data to enable mappings to SQL or to Rails"
          exit 0
        when /mapping=(.*)/
          @mapping = $1
          @vocabulary.tables
        else super
        end
      end

      def vocabulary_start
        puts @vocabulary.prelude
      end

      def vocabulary_end
        puts @vocabulary.finale
      end

      def emit_mapping o
        case @mapping
        when 'sql'
          puts "    table"
        when 'rails'
          puts "    table :#{o.rails_name}"
        end
      end

      def data_type_dump(o)
	value_type_dump(o, o.name, {}) if o.all_role.size > 0
      end

      def value_type_dump(o, super_type_name, facets)
	puts o.ruby_definition
      end

      def subtype_dump(o, supertypes, pi = nil)
        primary_supertype = o && (o.identifying_supertype || o.supertypes[0])
        secondary_supertypes = o.supertypes-[primary_supertype]

        puts "  class #{o.name.gsub(/ /,'')} < #{ primary_supertype.name.gsub(/ /,'') }"
        puts "    identified_by #{identified_by(o, pi)}" if pi
        puts "    supertypes "+secondary_supertypes.map{|st| st.name.gsub(/ /,'')}*", " if secondary_supertypes.size > 0
        emit_mapping(o) if o.is_table
        fact_roles_dump(o.fact_type) if o.fact_type
        roles_dump(o)
        puts "  end\n\n"
        pi.ordered_dumped! if pi
      end

      def non_subtype_dump(o, pi)
        puts "  class #{o.name.gsub(/ /,'')}"

        # We want to name the absorption role only when it's absorbed along its single identifying role.
        puts "    identified_by #{identified_by(o, pi)}"
        emit_mapping o if o.is_table
        fact_roles_dump(o.fact_type) if o.fact_type
        roles_dump(o)
        puts "  end\n\n"
        pi.ordered_dumped!
      end

      # Dump one fact type.
      def fact_type_dump(fact_type, name)
        return if skip_fact_type(fact_type)
        o = fact_type.entity_type

        primary_supertype = o && (o.identifying_supertype || o.supertypes[0])
        secondary_supertypes = o.supertypes-[primary_supertype]

        # Get the preferred identifier, but don't emit it unless it's different from the primary supertype's:
        pi = o.preferred_identifier
        pi = nil if pi && primary_supertype && primary_supertype.preferred_identifier == pi

        puts "  class #{name.gsub(/ /,'')}" +
          (primary_supertype ? " < "+primary_supertype.name.gsub(/ /,'') : "") +
          "\n" +
          secondary_supertypes.map{|sst| "    supertype :#{sst.name.gsub(/ /,'_')}"}*"\n" +
          (pi ? "    identified_by #{identified_by(o, pi)}" : "")
        emit_mapping o if o.is_table
        fact_roles_dump(fact_type)
        roles_dump(o)
        puts "  end\n\n"

        fact_type.ordered_dumped!
      end

      def identified_by_roles_and_facts(entity_type, identifying_role_refs, identifying_facts)
        identifying_role_refs.map{|role_ref|
            ":"+role_ref.role.preferred_role_name(entity_type)
          }*", "
      end

      def unary_dump(role, role_name)
        puts "    maybe :"+role_name
      end

      def binary_dump(role, role_name, role_player, mandatory = nil, one_to_one = nil, readings = nil, counterpart_role_name = nil, counterpart_method_name = nil)
	puts role.as_binary(role_name, role_player, mandatory, one_to_one, readings, counterpart_role_name, counterpart_method_name)
      end

    end
  end
end

ActiveFacts::Registry.generator('ruby', ActiveFacts::Generate::RUBY)
