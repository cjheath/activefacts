#
#       ActiveFacts Generators.
#       Base class for generators of class libraries in any object-oriented language that supports the ActiveFacts API.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/generate/ordered'

module ActiveFacts
  module Generate
    # Base class for generators of object-oriented class libraries for an ActiveFacts vocabulary.
    class OO < OrderedDumper  #:nodoc:
      include Metamodel

      def constraints_dump(constraints_used)
        # Stub, not needed.
      end

      def value_type_banner
      end

      def value_type_end
      end

      def roles_dump(o)
        o.all_role.
          select{|role|
            role.fact_type.all_role.size <= 2
          }.
          sort_by{|role|
            preferred_role_name(role.fact_type.all_role.select{|r2| r2 != role}[0] || role)
          }.each{|role| 
            role_dump(role)
          }
      end

      def role_dump(role)
        fact_type = role.fact_type
        if fact_type.all_role.size == 1
          unary_dump(role, preferred_role_name(role))
          return
        elsif fact_type.all_role.size != 2
          return  # ternaries and higher are always objectified
        end

        # REVISIT: TypeInheritance
        if TypeInheritance === fact_type
          # debug "Ignoring role #{role} in #{fact_type}, subtype fact type"
          return
        end

        other_role = fact_type.all_role.select{|r| r != role}[0]
        other_role_name = preferred_role_name(other_role)
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

        # Find role name:
        role_method = preferred_role_name(role)
        by = other_role_name != other_player.name.snakecase ? "_by_#{other_role_name}" : ""
        other_role_method = one_to_one ? role_method : "all_"+role_method
        other_role_method += by

        role_name = role_method
        role_name = nil if role_name == role.concept.name.snakecase

        binary_dump(role, other_role_name, other_player, one_to_one, nil, role_name, other_role_method)
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

      def skip_fact_type(f)
        # REVISIT: There might be constraints we have to merge into the nested entity or subtype.  These will come up as un-handled constraints.
        !f.entity_type ||
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
            binary_dump(role, role_name, role.concept, false, nil, nil, other_role_method)
          }
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
