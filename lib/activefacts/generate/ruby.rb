#
#       ActiveFacts Generators.
#       Generate Ruby classes for the ActiveFacts API from an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/generate/oo'

module ActiveFacts
  module Generate
    # Generate Ruby module containing classes for an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --ruby[=options] <file>.cql
    # Options are comma or space separated:
    # * help list available options
    # * sql Emit the sql mapping for tables/columns (REVISIT: not functional at present)
    class RUBY < OO
    private

      def set_option(option)
        @sql ||= false
        case option
        when 'help', '?'
          $stderr.puts "Usage:\t\tafgen --ruby[=option,option] input_file.cql\n"+
              "options:\tsql\tEmit data to enable mappings to SQL"
          exit 0
        when 'sql'; @sql = true
        else super
        end
      end

      def vocabulary_start(vocabulary)
        puts "require 'activefacts/api'\n"
        if @sql
          require 'activefacts/persistence'
          puts "require 'activefacts/persistence'\n"
          @tables = vocabulary.tables
        end
        puts "\nmodule ::#{vocabulary.name}\n\n"
      end

      def vocabulary_end
        puts "end"
      end

      def value_type_dump(o)
        is_special_supertype = !o.supertype && %w{Date Time DateAndTime}.include?(o.name)

        # We map DateAndTime to DateTime; if such a ValueType exists, don't dump this one
        return if is_special_supertype && o.name == 'DateAndTime' && o.constellation.ValueType[[[o.vocabulary.name], 'DateTime']]

        return if !o.supertype && !is_special_supertype
        if o.supertype && o.name == o.supertype.name
          # In ActiveFacts, parameterising a ValueType will create a new ValueType
          # throw Can't handle parameterized value type of same name as its ValueType" if ...
        end

        length = (l = o.length) && l > 0 ? ":length => #{l}" : nil
        scale = (s = o.scale) && s > 0 ? ":scale => #{s}" : nil
        params = [length,scale].compact * ", "

        name = o.name
        ruby_type_name =
          case o.supertype ? o.supertype.name : o.name
            when "VariableLengthText"; "String"
            when "Date"; "::Date"
            when "DateAndTime"; "::DateTime"
            when "Time"; "::Time"
            else o.supertype.name
          end

        name = name.sub(/^[a-z]/) {|i| i.upcase}
        puts "  class #{name} < #{ruby_type_name}\n" +
             "    value_type #{params}\n"
        if @sql and o.is_table
          puts "    table"
        end
        puts "    restrict #{o.value_constraint.all_allowed_range_sorted.map{|ar| ar.to_s}*", "}\n" if o.value_constraint
        puts "    \# REVISIT: #{o.name} is in units of #{o.unit.name}\n" if o.unit
        roles_dump(o)
        puts "  end\n\n"
      end

      def subtype_dump(o, supertypes, pi = nil)
        primary_supertype = o && (o.identifying_supertype || o.supertypes[0])
        secondary_supertypes = o.supertypes-[primary_supertype]

        puts "  class #{o.name} < #{ primary_supertype.name }"
        puts "    identified_by #{identified_by(o, pi)}" if pi
        puts "    supertypes "+secondary_supertypes.map(&:name)*", " if secondary_supertypes.size > 0
        if @sql and o.is_table
          puts "    table"
        end
        fact_roles_dump(o.fact_type) if o.fact_type
        roles_dump(o)
        puts "  end\n\n"
        @constraints_used[pi] = true if pi
      end

      def non_subtype_dump(o, pi)
        puts "  class #{o.name}"

        # We want to name the absorption role only when it's absorbed along its single identifying role.
        puts "    identified_by #{identified_by(o, pi)}"
        if @sql and o.is_table
          puts "    table"
        end
        fact_roles_dump(o.fact_type) if o.fact_type
        roles_dump(o)
        puts "  end\n\n"
        @constraints_used[pi] = true
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

        puts "  class #{name}" +
          (primary_supertype ? " < "+primary_supertype.name : "") +
          "\n" +
          secondary_supertypes.map{|sst| "    supertype :#{sst.name}"}*"\n" +
          (pi ? "    identified_by #{identified_by(o, pi)}" : "")
        puts "    table" if @sql and o.is_table
        fact_roles_dump(fact_type)
        roles_dump(o)
        puts "  end\n\n"

        @fact_types_dumped[fact_type] = true
      end

      def identified_by_roles_and_facts(entity_type, identifying_roles, identifying_facts, preferred_readings)
        identifying_roles.map{|role|
            ":"+preferred_role_name(role, entity_type)
          }*", "
      end

      def unary_dump(role, role_name)
        puts "    maybe :"+role_name
      end

      def binary_dump(role, role_name, role_player, mandatory = nil, one_to_one = nil, readings = nil, other_role_name = nil, other_method_name = nil)
        # Find whether we need the name of the other role player, and whether it's defined yet:
        if role_name.camelcase(true) == role_player.name.sub(/^[a-z]/) {|i| i.upcase}
          # Don't use Class name if implied by rolename
          role_reference = nil
        else
          role_reference = ":class => "+concept_reference(role_player)
        end
        other_role_name = ":counterpart => :"+other_role_name if other_role_name

        line = "    #{one_to_one ? "one_to_one" : "has_one" } " +
                [ ":"+role_name,
                  role_reference,
                  mandatory ? ":mandatory => true" : nil,
                  readings,
                  other_role_name,
                  (vr = role.role_value_constraint) ? ":restrict => #{vr}" : nil
                ].compact*", "+"  "
        line += " "*(48-line.length) if line.length < 48
        line += "\# See #{role_player.name}.#{other_method_name}" if other_method_name
        puts line
        #puts "    \# REVISIT: #{other_role_name} has values restricted to #{role.role_value_constraint}\n" if role.role_value_constraint
      end

      def concept_reference concept
        if !@concept_types_dumped[concept]
          '"'+concept.name+'"'
        else
          role_reference = concept.name
        end
      end

    end
  end
end
