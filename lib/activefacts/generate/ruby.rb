#
# Generate Ruby for the ActiveFacts API from an ActiveFacts vocabulary.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/generate/ordered'

module ActiveFacts

  module Generate
    class RUBY < OrderedDumper
      include Metamodel

      def vocabulary_start(vocabulary)
        puts "require 'activefacts/api'\n\n"
        puts "module #{vocabulary.name}\n\n"
      end

      def constraints_dump(constraints_used)
        # Stub, not needed.
      end

      def vocabulary_end
        puts "end"
      end

      def value_type_banner
      end

      def value_type_end
      end

      def value_type_dump(o)
        return if !o.supertype
        if o.name == o.supertype.name
            # In ActiveFacts, parameterising a ValueType will create a new datatype
            # throw Can't handle parameterized value type of same name as its datatype" if ...
        end

        length = (l = o.length) && l > 0 ? ":length => #{l}" : nil
        scale = (s = o.scale) && s > 0 ? ":scale => #{s}" : nil
        params = [length,scale].compact * ", "

        ruby_type_name =
          case o.supertype.name
            when "VariableLengthText"; "String"
            when "Date"; "::Date"
            else o.supertype.name
          end

        puts "  class #{o.name} < #{ruby_type_name}\n" +
             "    value_type #{params}\n"
        puts "    \# REVISIT: #{o.name} has restricted values\n" if o.value_restriction
        puts "    \# REVISIT: #{o.name} is in units of #{o.unit.name}\n" if o.unit
        roles_dump(o)
        puts "  end\n\n"
      end

      def roles_dump(o)
        o.all_role.each {|role|
            role_dump(role)
          }
      end

      def preferred_role_name(role)
        # debug "Looking for preferred_role_name of #{describe_fact_type(role.fact_type, role)}"
        reading = role.fact_type.preferred_reading
        preferred_role_ref = reading.role_sequence.all_role_ref.detect{|reading_rr|
            reading_rr.role == role
          }

        # Unaries are a hack, with only one role for what is effectively a binary:
        if (role.fact_type.all_role.size == 1)
          return (role.role_name && role.role_name.snakecase) ||
            reading.reading_text.gsub(/ *\{0\} */,'').gsub(' ','_').downcase
        end

        # debug "\tleading_adjective=#{(p=preferred_role_ref).leading_adjective}, role_name=#{role.role_name}, role player=#{role.concept.name}, trailing_adjective=#{p.trailing_adjective}"
        role_words = []
        role_name = role.role_name
        role_name = nil if role_name == ""

        # REVISIT: Consider whether NOT to use the adjective if it's a prefix of the role_name
        role_words << preferred_role_ref.leading_adjective.gsub(/ /,'_') if preferred_role_ref.leading_adjective != "" and !role.role_name

        role_words << (role_name || role.concept.name)
        # REVISIT: Same when trailing_adjective is a suffix of the role_name
        role_words << preferred_role_ref.trailing_adjective.gsub(/ /,'_') if preferred_role_ref.trailing_adjective != "" and !role_name
        n = role_words.map(&:snakecase)*"_"
        # debug "\tresult=#{n}"
        n
      end

      def role_dump(role)
        fact_type = role.fact_type
        if fact_type.all_role.size == 1
          # Handle Unary Roles here
          puts "    maybe :"+preferred_role_name(role)
          return
        elsif fact_type.all_role.size != 2
          return  # ternaries and higher are always objectified
        end

        # REVISIT: TypeInheritance
        if TypeInheritance === fact_type
          # debug "Ignoring role #{role} in #{fact_type}, subtype fact type"
          return
        end

        other_role_number = fact_type.all_role[0] == role ? 1 : 0
        other_role = fact_type.all_role[other_role_number]
        other_role_name = preferred_role_name(other_role)
        #other_role_name = ruby_role_name(other_role)
        other_player = other_role.concept

        # Find any uniqueness constraint over this role:
        fact_constraints = @presence_constraints_by_fact[fact_type]
        #debug "Considering #{fact_constraints.size} fact constraints over fact role #{role.concept.name}"
        ucs = fact_constraints.select{|c| PresenceConstraint === c && c.max_frequency == 1 }
        # Emit "has_one/one_to_one..." only for functional roles here:
        #debug "Considering #{ucs.size} unique constraints over role #{role.concept.name}"
        unless ucs.find {|c|
              roles = c.role_sequence.all_role_ref.map(&:role)
              #debug "Unique constraint over role #{role.concept.name} has roles #{roles.map{|r| describe_fact_type(r.fact_type, r)}*", "}"
              roles == [role]
          }
          #debug "No uniqueness constraint found for #{role} in #{fact_type}"
          return
        end

        if ucs.find {|c| c.role_sequence.all_role_ref.map(&:role) == [other_role] } &&
            !@concept_types_dumped[other_role.concept]
          #debug "Will dump 1:1 later for #{role} in #{fact_type}"
          return
        end

        # It's a one_to_one if there's a uniqueness constraint on the other role:
        one_to_one = ucs.find {|c| c.role_sequence.all_role_ref.map(&:role) == [other_role] }

        # REVISIT: Add readings

        # Find role name:
        role_method = preferred_role_name(role)
        by = other_role_name != other_player.name.snakecase ? "_by_#{other_role_name}" : ""
        other_role_method = one_to_one ? role_method : "all_"+role_method
        other_role_method += by

        role_name = role_method
        role_name = nil if role_name == role.concept.name.snakecase

        binary_dump(other_role_name, other_player, one_to_one, nil, role_name, other_role_method)
        puts "    \# REVISIT: #{other_role_name} has restricted values\n" if role.value_restriction
      end

      def subtype_dump(o, supertypes, pi = nil)
        puts "  class #{o.name} < #{ supertypes[0].name }"
        puts "    identified_by #{identified_by(o, pi)}" if pi
        fact_roles_dump(o.fact_type) if o.fact_type
        roles_dump(o)
        puts "  end\n\n"
        @constraints_used[pi] = true if pi
      end

      def non_subtype_dump(o, pi)
        puts "  class #{o.name}"
        puts "    identified_by #{identified_by(o, pi)}"
        fact_roles_dump(o.fact_type) if o.fact_type
        roles_dump(o)
        puts "  end\n\n"
        @constraints_used[pi] = true
      end

      def skip_fact_type(f)
        # REVISIT: There might be constraints we have to merge into the nested entity or subtype. 
        # These will come up as un-handled constraints:
        #debug "Skipping objectified fact type #{f.entity_type.name}" if f.entity_type
        #f.entity_type ||
          TypeInheritance === f
      end

      # An objectified fact type has internal roles that are always "has_one":
      def fact_roles_dump(fact)
        fact.all_role.each{|role| 
            role_name = preferred_role_name(role)
            by = role_name != role.concept.name.snakecase ? "_by_#{role_name}" : ""
            other_role_method = "all_"+fact.entity_type.name.snakecase+by
            binary_dump(role_name, role.concept, false, nil, nil, other_role_method)
          }
      end

      def binary_dump(role_name, role_player, one_to_one = nil, readings = nil, other_role_name = nil, other_method_name = nil)
        # Find whether we need the name of the other role player, and whether it's defined yet:
        if role_name.camelcase(true) == role_player.name
          # Don't use Class name if implied by rolename
          role_reference = nil
        elsif !@concept_types_dumped[role_player]
          role_reference = '"'+role_player.name+'"'
        else
          role_reference = role_player.name
        end
        other_role_name = ":"+other_role_name if other_role_name

        line = "    #{one_to_one ? "one_to_one" : "has_one" } " +
                [ ":"+role_name,
                  role_reference,
                  readings,
                  other_role_name
                ].compact*", "+"  "
        line += " "*(48-line.length) if line.length < 48
        line += "\# See #{role_player.name}.#{other_method_name}" if other_method_name
        puts line
      end

      # Dump one fact type.
      # Include as many as possible internal constraints in the fact type readings.
      def fact_type_dump(fact_type, name, readings)
        return if skip_fact_type(fact_type)

        fact_constraints = @presence_constraints_by_fact[fact_type]

        # debug "for fact type #{fact_type.to_s}, considering\n\t#{fact_constraints.map(&:to_s)*",\n\t"}"
        # debug "#{fact_type.name} has readings:\n\t#{fact_type.readings.map(&:name)*"\n\t"}"

        pc = fact_constraints.detect{|c|
            PresenceConstraint === c &&
            c.role_sequence.all_role_ref.size > 1
          }
        return unless pc          # Omit fact types that aren't implicitly nested

        supertype = fact_type.entity_type &&
            (fact_type.entity_type.identifying_supertype || fact_type.entity_type.supertypes[0])

        # REVISIT: If fact_type.entity_type.supertypes.size > 1, handle additional supertypes

        puts "  class #{name}#{supertype ? " < "+supertype.name : ""}\n" +
                  "    identified_by #{identified_by(fact_type.entity_type, pc)}"
        fact_roles_dump(fact_type)
        roles_dump(fact_type.entity_type)
        puts "  end\n\n"

        @fact_types_dumped[fact_type] = true
      end

      def ruby_role_name(role_name)
        if Role === role_name
          role_name = role_name.role_name || role_name.concept.name
        end
        role_name.snakecase.gsub("-",'_')
      end

      def identified_by_roles_and_facts(identifying_roles, identifying_facts, preferred_readings)
        identifying_roles.map{|role|
            ":"+preferred_role_name(role)
          }*", "
      end

      def show_role(r)
        puts "Role player #{r.concept.name} facttype #{r.fact_type.name} lead_adj #{r.leading_adjective} trail_adj #{r.trailing_adjective} allows #{r.allowed_values.inspect}"
      end

      def entity_type_banner
      end

      def entity_type_group_end
      end

      def expand_reading(reading, frequency_constraints, define_role_names)
        # debug "Ignoring reading #{reading.reading_text.inspect}"
      end

      def append_ring_to_reading(reading, ring)
        # REVISIT: debug "Should override append_ring_to_reading"
      end

      def fact_type_banner
      end

      def fact_type_end
      end

      def constraint_banner
        # debug "Should override constraint_banner"
      end

      def constraint_end
        # debug "Should override constraint_end"
      end

      def constraint_dump(c)
        # debug "Should override constraint_dump"
      end

    end

  end
end
