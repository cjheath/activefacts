#
#       ActiveFacts Generators.
#
#       Generate a glossary in HTML
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/api'

module ActiveFacts
  module Generate #:nodoc:
    class HTML #:nodoc:
      class GLOSSARY #:nodoc:
        # Base class for generators of object-oriented class libraries for an ActiveFacts vocabulary.
        def initialize(vocabulary, *options)
          @vocabulary = vocabulary
          @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
          options.each{|option| set_option(option) }
        end

        def set_option(option)
        end

        def puts(*a)
          @out.puts *a
        end

        def print(*a)
          @out.print *a
        end

        def generate(out = $>)
          @out = out
          vocabulary_start

          object_types_dump()

          vocabulary_end
        end

        def vocabulary_start
          puts "<link rel='stylesheet' href='css/orm2.css' media='screen' type='text/css'/>"
          puts "<h1>#{@vocabulary.name}</h1>"
          puts "<dl>"
        end

        def vocabulary_end
          puts "</dl>"
        end

        def object_types_dump
          @vocabulary.
            all_object_type.
            sort_by{|o| o.name.gsub(/ /,'').downcase}.
            each do |o|
              case o
              when ActiveFacts::Metamodel::TypeInheritance
                nil
              when ActiveFacts::Metamodel::ValueType
                value_type_dump(o)
              else
                if o.fact_type
                  objectified_fact_type_dump(o)
                else
                  entity_type_dump(o)
                end
              end
            end
        end

        def element(text, attrs, tag = 'span')
          "<#{tag}#{attrs.empty? ? '' : attrs.map{|k,v| " #{k}='#{v}'"}*''}>#{text}</#{tag}>"
        end

        # A definition of a term
        def termdef(name)
          element(name, {:name => name, :class => 'object_type'}, 'a')
        end

        # A reference to a defined term (excluding role adjectives)
        def termref(name, role_name = nil)
          role_name ||= name
          element(role_name, {:href=>'#'+name, :class=>:object_type}, 'a')
        end

        # Text that should appear as part of a term (including role adjectives)
        def term(name)
          element(name, :class=>:object_type)
        end

        def value_type_dump(o)
          return if o.all_role.size == 0  # Skip value types that are only used as supertypes
          puts "  <dt>" +
            "Value Type: #{termdef(o.name)}" +
            (o.supertype ? " (written as #{termref(o.supertype.name)})" : "") +
            "</dt>"

          puts "  <dd>"
          relevant_facts_and_constraints(o)
          puts "  </dd>"
        end

        def relevant_facts_and_constraints(o)
          puts(
            o.
              all_role.
              map{|r| r.fact_type}.
              uniq.
              reject{|ft| ft.is_a?(ActiveFacts::Metamodel::TypeInheritance) || ft.is_a?(ActiveFacts::Metamodel::ImplicitFactType) }.
              map { |ft| "    #{fact_type_with_constraints(ft, o)}</br>" }.
              sort * "\n"
          )
        end

        def role_ref rr, freq_con, l_adj, name, t_adj, role_name_def, literal
          term_parts = [l_adj, termref(name), t_adj].compact
          [
            freq_con ? element(freq_con, :class=>:keyword) : nil,
            term_parts.size > 1 ? term([l_adj, termref(name), t_adj].compact*' ') : term_parts[0],
            role_name_def,
            literal
          ]
        end

        def expand_reading(r)
          element(
            r.expand do |*a|
              role_ref(*a)
            end,
            {:class => 'copula'}
          )
        end

        def fact_type(ft, wrt = nil)
          role = ft.all_role.detect{|r| r.object_type == wrt}
          preferred_reading = ft.reading_preferably_starting_with_role(role)
          alternate_readings = ft.all_reading.reject{|r| r == preferred_reading}
          expand_reading(preferred_reading) +
            (alternate_readings.size > 0 ?
              ' (alternatively, ' +
              alternate_readings.map { |r| expand_reading(r)}*', ' +
              ')' : '')
        end

        def fact_type_with_constraints(ft, wrt = nil)
          fact_type(ft, wrt) +
            "<br/>\n<ul>\n" +
            fact_type_constraints(ft) +
            "</ul>"
        end

        def fact_type_constraints(ft)
          ft.internal_presence_constraints.map do |pc|
            residual_role = ft.all_role.detect{|r| !pc.role_sequence.all_role_ref.detect{|rr| rr.role == r}}
            next nil unless residual_role
            reading = ft.all_reading.detect{|reading|
                reading.role_sequence.all_role_ref_in_order[reading.role_numbers[-1]].role == residual_role
              }
            next nil unless reading
            element(
              reading.expand_with_final_presence_constraint { |*a| role_ref(*a) },
              {:class => 'copula'}
            )+"<br/>\n"
          end.compact*''
        end

        def objectified_fact_type_dump(o)
          puts "  <dt>" +
            "Entity Type: #{termdef(o.name)}" +
            " (objectification of #{fact_type(o.fact_type)})" +
            "</dt>"
          # REVISIT: Handle separate identification

          puts "  <dd>"
          puts fact_type_constraints(o.fact_type)
          o.fact_type.all_role_in_order.each do |r|
            n = r.object_type.name
            puts "#{termref(o.name)} involves exactly one #{termref(r.role_name || n, n)}<br/>"
          end
          relevant_facts_and_constraints(o)
          puts "  </dd>"
        end

        def entity_type_dump(o)
          pi = o.preferred_identifier
          supers = o.supertypes
          if (supers.size > 0) # Ignore identification by a supertype:
            pi = nil if pi && pi.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) }
          end

          puts "  <dt>" +
            "Entity Type: #{termdef(o.name)}" +
            " (" +
            [
              (supers.size > 0 ? "Subtype of #{supers.map{|s| s.name}*', '})" : nil),
              (pi ? "identified by "+pi.role_sequence.describe : nil)
            ].compact*', '
            ")" +
            "</dt>"

          puts "  <dd>"
          relevant_facts_and_constraints(o)
          puts "  </dd>"
        end

      end
    end
  end
end
