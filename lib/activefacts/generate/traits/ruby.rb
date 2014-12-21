#
#       ActiveFacts Generators.
#       Generate Ruby classes for the ActiveFacts API from an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Generate
    module RubyTraits
      module Vocabulary
	def prelude
	  if @mapping == 'sql'
	    require 'activefacts/persistence'
	    @tables = self.tables
	  end

	  "require 'activefacts/api'\n" +
	    (@mapping == 'sql' ? "require 'activefacts/persistence'\n" : '') +
	    "\nmodule ::#{self.name}\n\n"
	end

	def finale
	  "end"
	end
      end

      module ObjectType
	def absorbed_roles
          all_role.
            select do |role|
              role.fact_type.all_role.size <= 2 &&
                !role.fact_type.is_a?(ActiveFacts::Metamodel::LinkFactType)
            end.
            sort_by do |role|
              r = role.fact_type.all_role.select{|r2| r2 != role}[0] || role
	      r.preferred_role_name(self)
            end
	end

	# Map the ObjectType name to a Ruby class name
	def ruby_type_name
	  oo_type_name
	end

	# Map the Ruby class name to a default role name
	def ruby_default_role_name
	  oo_default_role_name
	end


	def ruby_type_reference
	  if !ordered_dumped
	    '"'+name.gsub(/ /,'')+'"'
	  else
	    role_reference = name.gsub(/ /,'')
	  end
	end
      end

      module Role
        def preferred_role_name(is_for = nil, &name_builder)

	  if fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
	    # Subtype and Supertype roles default to TitleCase names, and have no role_name to worry about:
	    return (name_builder || proc {|names| names.titlecase}).call(object_type.name.words)
	  end

	  name_builder ||= proc {|names| names.map(&:downcase)*'_' }   # Make snake_case by default

	  # Handle an objectified unary role:
          if is_for && fact_type.entity_type == is_for && fact_type.all_role.size == 1
            return name_builder.call(object_type.name.words)
          end

          # debug "Looking for preferred_role_name of #{describe_fact_type(fact_type, self)}"
          reading = fact_type.preferred_reading
          preferred_role_ref = reading.role_sequence.all_role_ref.detect{|reading_rr|
              reading_rr.role == self
            }

          if fact_type.all_role.size == 1
            return name_builder.call(
	      role_name ?
		role_name.snakewords :
		reading.text.gsub(/ *\{0\} */,' ').gsub(/[- ]+/,'_').words
	    )
          end

	  if role_name && role_name != ""
	    role_words = [role_name]
	  else
	    role_words = []

	    la = preferred_role_ref.leading_adjective
	    role_words += la.words.snakewords if la && la != ""

	    role_words += object_type.name.words.snakewords

	    ta = preferred_role_ref.trailing_adjective
	    role_words += ta.words.snakewords if ta && ta != ""
	  end

          # n = role_words.map{|w| w.gsub(/([a-z])([A-Z]+)/,'\1_\2').downcase}*"_"
	  n = role_words*'_'
          # debug "\tresult=#{n}"
          return name_builder.call(n.gsub(' ','_').split(/_/))
        end

	def as_binary(role_name, role_player, mandatory = nil, one_to_one = nil, readings = nil, other_role_name = nil, other_method_name = nil)
	  ruby_role_name = ":"+role_name.words.snakecase

	  # Find whether we need the name of the other role player, and whether it's defined yet:
	  implied_role_name = role_player.name.gsub(/ /,'').sub(/^[a-z]/) {|i| i.upcase}
	  if role_name.camelcase != implied_role_name
	    # Only use Class name if it's not implied by the rolename
	    role_reference = ":class => "+role_player.ruby_type_reference
	  end

	  other_role_name = ":counterpart => :"+other_role_name.gsub(/ /,'_') if other_role_name

	  if vr = role_value_constraint
	    value_restriction = ":restrict => #{vr}"
	  end

	  options = [
	      ruby_role_name,
	      role_reference,
	      mandatory ? ":mandatory => true" : nil,
	      readings,
	      other_role_name,
	      value_restriction
	    ].compact

	  debugger if ruby_role_name == 'astronomicalobject'

	  line = "    #{one_to_one ? "one_to_one" : "has_one" } #{options*', '}  "
	  if other_method_name
	    line += " "*(48-line.length) if line.length < 48
	    line += "\# See #{role_player.name.gsub(/ /,'')}.#{other_method_name}"
	  end
	  line+"\n"
	end

	def ruby_role_definition
	  oo_role_definition
	end
      end

      module ValueType
	def ruby_definition
	  return if name == "_ImplicitBooleanValueType"

	  ruby_length = length && length > 0 ? ":length => #{length}" : nil
	  ruby_scale = scale && scale > 0 ? ":scale => #{scale}" : nil
	  params = [ruby_length,ruby_scale].compact * ", "

	  base_type = supertype || self
	  base_type_name = base_type.ruby_type_name
	  ruby_name = name.sub(/^[a-z]/) {|i| i.upcase}.gsub(/ /,'')
	  if base_type_name == ruby_name
	    base_type_name = '::'+base_type_name
	  end

	  "  class #{ruby_name} < #{base_type_name}\n" +
	  "    value_type #{params}\n" +
	  #emit_mapping self if is_table
	  (value_constraint ?
	    "    restrict #{value_constraint.all_allowed_range_sorted.map{|ar| ar.to_s}*", "}\n" :
	    ""
	  ) +
	  (unit ?
	    "    \# REVISIT: #{ruby_name} is in units of #{unit.name}\n" :
	    ""
	  ) +
	  absorbed_roles.map do |role|
	    role.ruby_role_definition
	  end.
	  compact*"" +
	  "  end\n\n"
	end
      end

      module FactType
        # An objectified fact type has internal roles that are always "has_one":
        def fact_roles
	  raise "Fact #{describe} type is not objectified" unless entity_type
          all_role.sort_by do |role|
	    role.preferred_role_name(entity_type)
	  end.
	  map do |role| 
	    role_name = role.preferred_role_name(entity_type)
	    one_to_one = role.all_role_ref.detect{|rr|
	      rr.role_sequence.all_role_ref.size == 1 &&
	      rr.role_sequence.all_presence_constraint.detect{|pc|
		pc.max_frequency == 1
	      }
	    }
	    counterpart_role_method = (one_to_one ? "" : "all_") + 
	      entity_type.oo_default_role_name +
	      (role_name != role.object_type.oo_default_role_name ? "_as_#{role_name}" : '')
	    role.as_binary(role_name, role.object_type, true, one_to_one, nil, nil, counterpart_role_method)
	  end.
	  join('')
	end
      end

      include ActiveFacts::TraitInjector	# Must be last in this module, after all submodules have been defined
    end
  end
end
