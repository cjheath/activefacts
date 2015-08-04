#
#       ActiveFacts Schema Transform
#       Transform a loaded ActiveFacts vocabulary to suit ActiveRecord
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/persistence'

module ActiveFacts
  module Metamodel
    class ObjectType

      def add_surrogate type_name = 'Auto Counter', suffix = 'ID'
        # Find or assert the surrogate value type
        auto_counter = vocabulary.valid_value_type_name(type_name) ||
          constellation.ValueType(:vocabulary => vocabulary, :name => type_name, :concept => :new)

        # Create a subtype to identify this entity type:
        vt_name = self.name + ' '+suffix
        my_id = @vocabulary.valid_value_type_name(vt_name) ||
          constellation.ValueType(:vocabulary => vocabulary, :name => vt_name, :concept => :new, :supertype => auto_counter)

        # Create a fact type
        identifying_fact_type = constellation.FactType(:concept => :new)
        my_role = constellation.Role(:concept => :new, :fact_type => identifying_fact_type, :ordinal => 0, :object_type => self)
        @injected_surrogate_role = my_role
        id_role = constellation.Role(:concept => :new, :fact_type => identifying_fact_type, :ordinal => 1, :object_type => my_id)

        # Create a reading (which needs a RoleSequence)
        reading = constellation.Reading(
          :fact_type => identifying_fact_type,
          :ordinal => 0,
          :role_sequence => [:new],
          :text => "{0} has {1}"
        )
        constellation.RoleRef(:role_sequence => reading.role_sequence, :ordinal => 0, :role => my_role)
        constellation.RoleRef(:role_sequence => reading.role_sequence, :ordinal => 1, :role => id_role)

        # Create two uniqueness constraints for the one-to-one. Each needs a RoleSequence (two RoleRefs)
        one_id = constellation.PresenceConstraint(
            :concept => :new,
            :vocabulary => vocabulary,
            :name => self.name+'HasOne'+suffix,
            :role_sequence => [:new],
            :is_mandatory => true,
            :min_frequency => 1,
            :max_frequency => 1,
            :is_preferred_identifier => false
          )
        @constellation.RoleRef(:role_sequence => one_id.role_sequence, :ordinal => 0, :role => my_role)

        one_me = constellation.PresenceConstraint(
            :concept => :new,
            :vocabulary => vocabulary,
            :name => self.name+suffix+'IsOfOne'+self.name,
            :role_sequence => [:new],
            :is_mandatory => false,
            :min_frequency => 0,
            :max_frequency => 1,
            :is_preferred_identifier => true
          )
        @constellation.RoleRef(:role_sequence => one_me.role_sequence, :ordinal => 0, :role => id_role)
      end
    end

    class ValueType
      def needs_surrogate
        !is_auto_assigned
      end

      def inject_surrogate
        trace :transform_surrogate, "Adding surrogate ID to Value Type #{name}"
        add_surrogate('Auto Counter', 'ID')
      end
    end

    class EntityType
      def identifying_refs_from
        pi = preferred_identifier
        rrs = pi.role_sequence.all_role_ref

#       REVISIT: This is actually a ref to us, not from
#       if absorbed_via
#         return [absorbed_via]
#       end

        rrs.map do |rr|
          r = references_from.detect{|ref| rr.role == ref.to_role }
          raise "failed to find #{name} identifying reference for #{rr.role.object_type.name} in #{references_from.inspect}" unless r
          r
        end
      end

      def needs_surrogate

        # A recursive proc to replace any reference to an Entity Type by its identifying references:
        trace :transform_surrogate_expansion, "Expanding key for #{name}"
        substitute_identifying_refs = proc do |object|
          if ref = object.absorbed_via
            # This shouldn't be necessary, but see the absorbed_via comment above.
            absorbed_into = ref.from
            trace :transform_surrogate_expansion, "recursing to handle absorption of #{object.name} into #{absorbed_into.name}"
            [substitute_identifying_refs.call(absorbed_into)]
          else
            irf = object.identifying_refs_from
            trace :transform_surrogate_expansion, "Iterating for #{object.name} over #{irf.inspect}" do
              irf.each_with_index do |ref, i|
                next if ref.is_unary
                next if ref.to_role.object_type.kind_of?(ActiveFacts::Metamodel::ValueType)
                recurse_to = ref.to_role.object_type

                trace :transform_surrogate_expansion, "#{i}: recursing to expand #{recurse_to.name} key in #{ref}" do
                  irf[i] = substitute_identifying_refs.call(recurse_to)
                end
              end
            end
            irf
          end
        end
        irf = substitute_identifying_refs.call(self)

        trace :transform_surrogate, "Does #{name} need a surrogate? it's identified by #{irf.inspect}" do

          pk_fks = identifying_refs_from.map do |ref|
            ref.to && ref.to.is_table ? ref.to : nil
          end

          irf.flatten!

          # Multi-part identifiers are only allowed if:
          # * each part is a foreign key (i.e. it's a join table),
          # * there are no other columns (that might require updating) and
          # * the object is not the target of a foreign key:
          if irf.size >= 2
            if pk_fks.include?(nil)
              trace :transform_surrogate, "#{self.name} needs a surrogate because its multi-part key contains a non-table"
              return true
            elsif references_to.size != 0
              trace :transform_surrogate, "#{self.name} is a join table between #{pk_fks.map(&:name).inspect} but is also an FK target"
              return true
            elsif (references_from-identifying_refs_from).size > 0
              # There are other attributes to worry about
              return true
            else
              trace :transform_surrogate, "#{self.name} is a join table between #{pk_fks.map(&:name).inspect}"
              return false
            end
            return true
          end

          # Single-part key. It must be an Auto Counter, or we will add a surrogate

          identifying_type = irf[0].to
          if identifying_type.needs_surrogate
            trace :transform_surrogate, "#{self.name} needs a surrogate because #{irf[0].to.name} is not an AutoCounter, but #{identifying_type.supertypes_transitive.map(&:name).inspect}"
            return true
          end

          false
        end
      end

      def inject_surrogate
        trace :transform_surrogate, "Injecting a surrogate key into #{self.name}"

        # Disable the preferred identifier:
        pi = preferred_identifier
        trace :transform_surrogate, "pi for #{name} was '#{pi.describe}'"
        pi.is_preferred_identifier = false
        @preferred_identifier = nil   # Kill the cache

        add_surrogate

        trace :transform_surrogate, "pi for #{name} is now '#{preferred_identifier.describe}'"
      end

    end
  end

  module Persistence
    class Column
      def is_injected_surrogate
        references.size == 1 and
          references[0].from_role == references[0].from.injected_surrogate_role
      end
    end
  end

  module Generate #:nodoc:
    module Transform #:nodoc:
      class Surrogate
        def initialize(vocabulary, *options)
          @vocabulary = vocabulary
        end

        def generate(out = $stdout)
          @out = out
          injections = 
            @vocabulary.tables.select do |table|
              table.needs_surrogate
            end
          injections.each do |table|
            table.inject_surrogate
          end

          @vocabulary.decide_tables
        end
      end
    end
  end
end

ActiveFacts::Registry.generator('transform/surrogate', ActiveFacts::Generate::Transform::Surrogate)
