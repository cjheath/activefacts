require 'activefacts/api'

module Metamodel

  class Adjective < String
    value_type :length => 64
  end

  class ConstraintId < AutoCounter
    value_type 
  end

  class Denominator < UnsignedInteger
    value_type :length => 32
  end

  class Enforcement < String
    value_type :length => 16
  end

  class Exponent < SignedSmallInteger
    value_type :length => 32
  end

  class FactId < AutoCounter
    value_type 
  end

  class FactTypeId < AutoCounter
    value_type 
  end

  class Frequency < UnsignedInteger
    value_type :length => 32
  end

  class InstanceId < AutoCounter
    value_type 
  end

  class Length < UnsignedInteger
    value_type :length => 32
  end

  class Name < String
    value_type :length => 64
  end

  class Numerator < Decimal
    value_type 
  end

  class Ordinal < UnsignedSmallInteger
    value_type :length => 32
  end

  class ReadingText < String
    value_type :length => 256
  end

  class RingType < String
    value_type 
  end

  class RoleId < AutoCounter
    value_type 
  end

  class RoleSequenceId < AutoCounter
    value_type 
  end

  class Scale < UnsignedInteger
    value_type :length => 32
  end

  class UnitId < AutoCounter
    value_type 
  end

  class Value < String
    value_type :length => 256
  end

  class ValueRestrictionId < AutoCounter
    value_type 
  end

  class Bound
    identified_by :value, :is_inclusive
    has_one :value
    maybe :is_inclusive
  end

  class Coefficient
    identified_by :numerator, :denominator
    maybe :is_precise
    has_one :numerator
    has_one :denominator
  end

  class Constraint
    identified_by :constraint_id
    one_to_one :constraint_id
    has_one :name
    has_one :enforcement
    has_one :vocabulary
  end

  class Fact
    identified_by :fact_id
    one_to_one :fact_id
    has_one :fact_type
    has_one :population
  end

  class FactType
    identified_by :fact_type_id
    one_to_one :fact_type_id
  end

  class Instance
    identified_by :instance_id
    one_to_one :instance_id
    has_one :value
    has_one :concept
    has_one :population
  end

  class PresenceConstraint < Constraint
    has_one :role_sequence
    has_one :max_frequency, Frequency
    has_one :min_frequency, Frequency
    maybe :is_preferred_identifier
    maybe :is_mandatory
  end

  class Reading
    identified_by :fact_type, :ordinal
    has_one :fact_type
    has_one :reading_text
    has_one :role_sequence
    has_one :ordinal
  end

  class RingConstraint < Constraint
    has_one :role
    has_one :other_role, "Role"
    has_one :ring_type
  end

  class RoleSequence
    identified_by :role_sequence_id
    one_to_one :role_sequence_id
  end

  class RoleValue
    identified_by :instance, :fact
    has_one :population
    has_one :fact
    has_one :instance
    has_one :role
  end

  class SetConstraint < Constraint
  end

  class SubsetConstraint < SetConstraint
    has_one :superset_role_sequence, RoleSequence
    has_one :subset_role_sequence, RoleSequence
  end

  class UniquenessConstraint < PresenceConstraint
  end

  class Unit
    identified_by :unit_id
    one_to_one :unit_id
    has_one :coefficient
    has_one :name
    maybe :is_fundamental
  end

  class UnitBasis
    identified_by :base_unit, :unit
    has_one :unit
    has_one :base_unit, Unit
    has_one :exponent
  end

  class ValueRange
    identified_by :minimum_bound, :maximum_bound
    has_one :minimum_bound, Bound
    has_one :maximum_bound, Bound
  end

  class ValueRestriction
    identified_by :value_restriction_id
    one_to_one :value_restriction_id
  end

  class AllowedRange
    identified_by :value_range, :value_restriction
    has_one :value_restriction
    has_one :value_range
  end

  class FrequencyConstraint < PresenceConstraint
  end

  class MandatoryConstraint < PresenceConstraint
  end

  class SetComparisonConstraint < SetConstraint
  end

  class SetComparisonRoles
    identified_by :set_comparison_constraint, :role_sequence
    has_one :role_sequence
    has_one :set_comparison_constraint
  end

  class SetEqualityConstraint < SetComparisonConstraint
  end

  class SetExclusionConstraint < SetComparisonConstraint
    maybe :is_mandatory
  end

  class Feature
    identified_by :name, :vocabulary
    has_one :name
    has_one :vocabulary
  end

  class Vocabulary < Feature
    has_one :parent_vocabulary, Vocabulary
  end

  class Import
    identified_by :imported_vocabulary, :vocabulary
    has_one :vocabulary
    has_one :imported_vocabulary, Vocabulary
  end

  class Correspondence
    identified_by :imported_feature, :import
    has_one :import
    has_one :imported_feature, Feature
    has_one :local_feature, Feature
  end

  class Alias < Feature
  end

  class Concept < Feature
  end

  class Role
    identified_by :role_id
    has_one :concept
    has_one :fact_type
    has_one :role_name, Name
    has_one :value_restriction
    one_to_one :role_id
  end

  class RoleRef
    identified_by :role_sequence, :ordinal
    has_one :role
    has_one :ordinal
    has_one :role_sequence
    has_one :leading_adjective, Adjective
    has_one :trailing_adjective, Adjective
  end

  class EntityType < Concept
    maybe :is_independent
    maybe :is_personal
    one_to_one :fact_type
  end

  class TypeInheritance < FactType
    identified_by :entity_type, :super_entity_type
    has_one :super_entity_type, EntityType
    has_one :entity_type
    maybe :defines_primary_supertype
  end

  class Population
    identified_by :vocabulary, :name
    has_one :name
    has_one :vocabulary
  end

  class ValueType < Concept
    has_one :supertype, ValueType
    has_one :length
    has_one :scale
    has_one :value_restriction
    has_one :unit
  end

end
