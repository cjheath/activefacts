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

      def set_option(option)
        @sql ||= false
        case option
        when 'sql'; @sql = true
        else super
        end
      end

      def vocabulary_start(vocabulary)
        if @sql
          require 'activefacts/persistence'
          @tables = vocabulary.tables
        end
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
        puts "    table" if @sql and @tables.include? o
        puts "    \# REVISIT: #{o.name} has restricted values\n" if o.value_restriction
        puts "    \# REVISIT: #{o.name} is in units of #{o.unit.name}\n" if o.unit
        roles_dump(o)
        puts "  end\n\n"
      end

      def roles_dump(o)
        ar_by_role = nil
        if @sql and @tables.include?(o)
          ar = o.absorbed_roles
          ar_by_role = ar.all_role_ref.inject({}){|h,rr|
            input_role = (j=rr.all_join_path).size > 0 ? j[0].input_role : rr.role
            (h[input_role] ||= []) << rr
            h
          }
          #puts ar.all_role_ref.map{|rr| "\t"+rr.describe}*"\n"
        end
        o.all_role.
          sort_by{|role|
            other_role = role.fact_type.all_role[role.fact_type.all_role[0] != role ? 0 : -1]
            other_role ? preferred_role_name(other_role) : ""
            #puts "\t#{role.fact_type.describe(other_role)} by #{p}"
          }.each{|role| 
            other_role = role.fact_type.all_role[role.fact_type.all_role[0] != role ? 0 : -1]
            if ar_by_role and ar_by_role[other_role]
              puts "    # role #{role.fact_type.describe(role)}: absorbs in through #{preferred_role_name(other_role)}: "+ar_by_role[other_role].map(&:column_name)*", "
            end
            role_dump(role)
          }
      end

      def preferred_role_name(role)
        return "" if TypeInheritance === role.fact_type
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
        la = preferred_role_ref.leading_adjective
        role_words << la.gsub(/ /,'_') if la && la != "" and !role.role_name

        role_words << (role_name || role.concept.name)
        # REVISIT: Same when trailing_adjective is a suffix of the role_name
        ta = preferred_role_ref.trailing_adjective
        role_words << ta.gsub(/ /,'_') if ta && ta != "" and !role_name
        n = role_words.map{|w| w.gsub(/([a-z])([A-Z]+)/,'\1_\2').downcase}*"_"
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
        puts "    \# REVISIT: #{other_role_name} has restricted values\n" if role.role_value_restriction
      end

      def subtype_dump(o, supertypes, pi = nil)
        puts "  class #{o.name} < #{ supertypes[0].name }"
        puts "    identified_by #{identified_by(o, pi)}" if pi
        puts "    table" if @sql and @tables.include? o
        fact_roles_dump(o.fact_type) if o.fact_type
        roles_dump(o)
        puts "  end\n\n"
        @constraints_used[pi] = true if pi
      end

      def non_subtype_dump(o, pi)
        puts "  class #{o.name}"
        puts "    identified_by #{identified_by(o, pi)}"
        puts "    table" if @sql and @tables.include? o
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
        fact.all_role.sort_by{|role|
            preferred_role_name(role)
          }.each{|role| 
            role_name = preferred_role_name(role)
            by = role_name != role.concept.name.snakecase ? "_by_#{role_name}" : ""
            raise "Fact #{fact.describe} type is not objectified" unless fact.entity_type
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
      def fact_type_dump(fact_type, name)
        return if skip_fact_type(fact_type) || !(o = fact_type.entity_type)

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
        fact_roles_dump(fact_type)
        roles_dump(o)
        puts "  end\n\n"

        @fact_types_dumped[fact_type] = true
      end

      def ruby_role_name(role_name)
        if Role === role_name
          role_name = role_name.role_name || role_name.concept.name
        end
        role_name.snakecase.gsub("-",'_')
      end

      def identified_by_roles_and_facts(entity_type, identifying_roles, identifying_facts, preferred_readings)
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
