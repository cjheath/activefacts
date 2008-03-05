require 'activefacts/api'

module Metamodel

  class Adjective < String
    value_type :length => 64
  end

  class Constraint_Id < AutoCounter
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

  class FactType_Id < AutoCounter
    value_type 
  end

  class Fact_Id < AutoCounter
    value_type 
  end

  class Frequency < UnsignedInteger
    value_type :length => 32
  end

  class Instance_Id < AutoCounter
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

  class RoleSequence_Id < AutoCounter
    value_type 
  end

  class Role_Id < AutoCounter
    value_type 
  end

  class Scale < UnsignedInteger
    value_type :length => 32
  end

  class Unit_Id < AutoCounter
    value_type 
  end

  class Value < String
    value_type :length => 256
  end

  class ValueRestriction_Id < AutoCounter
    value_type 
  end

  class Bound
    identified_by :value, :is_inclusive
    has_one :value, Value, :bound
    maybe :is_inclusive
  end

  class Coefficient
    identified_by :numerator, :denominator
    maybe :is_precise
    has_one :numerator, Numerator, :coefficient
    has_one :denominator, Denominator, :coefficient
  end

  class Constraint
    identified_by :constraint_id
    one_to_one :constraint_id, Constraint_Id, :constraint
    has_one :name, Name, :constraint
    has_one :enforcement, Enforcement, :constraint
    has_one :vocabulary, "Vocabulary", :constraint
  end

  class Fact
    identified_by :fact_id
    one_to_one :fact_id, Fact_Id, :fact
    has_one :fact_type, "FactType", :fact
    has_one :population, "Population", :fact
  end

  class FactType
    identified_by :fact_type_id
    one_to_one :fact_type_id, FactType_Id, :fact_type
  end

  class Instance
    identified_by :instance_id
    one_to_one :instance_id, Instance_Id, :instance
    has_one :value, Value, :instance
    has_one :concept, "Concept", :instance
    has_one :population, "Population", :instance
  end

  class PresenceConstraint < Constraint
    has_one :role_sequence, "RoleSequence", :presence_constraint
    has_one :max_frequency, Frequency, :presence_constraint
    has_one :min_frequency, Frequency, :presence_constraint
    maybe :is_preferred_identifier
    maybe :is_mandatory
  end

  class Reading
    identified_by :ordinal, :fact_type
    has_one :fact_type, FactType, :reading
    has_one :reading_text, ReadingText, :reading
    has_one :role_sequence, "RoleSequence", :reading
    has_one :ordinal, Ordinal, :reading
  end

  class RingConstraint < Constraint
    has_one :role, "Role", :ring_constraint
    has_one :other_role, "Role", :ring_constraint
    has_one :ring_type, RingType, :ring_constraint
  end

  class Role
    identified_by :role_id
    has_one :concept, "Concept"
    has_one :fact_type, FactType
    has_one :role_name, Name, :role
    has_one :value_restriction, "ValueRestriction", :role
    one_to_one :role_id, Role_Id, :role
  end

  class RoleSequence
    identified_by :role_sequence_id
    one_to_one :role_sequence_id, RoleSequence_Id, :role_sequence
  end

  class RoleValue
    identified_by :instance, :fact
    has_one :population, "Population", :role_value
    has_one :fact, Fact, :role_value
    has_one :instance, Instance, :role_value
    has_one :role, Role, :role_value
  end

  class SetConstraint < Constraint
  end

  class SubsetConstraint < SetConstraint
    has_one :superset_role_sequence, RoleSequence, :subset_constraint
    has_one :subset_role_sequence, RoleSequence, :subset_constraint
  end

  class UniquenessConstraint < PresenceConstraint
  end

  class Unit
    identified_by :unit_id
    one_to_one :unit_id, Unit_Id, :unit
    has_one :coefficient, Coefficient, :unit
    has_one :name, Name, :unit
    maybe :is_fundamental
  end

  class UnitBasis
    identified_by :base_unit, :unit
    has_one :unit, Unit
    has_one :base_unit, Unit
    has_one :exponent, Exponent, :unit_basis
  end

  class ValueRange
    identified_by :minimum_bound, :maximum_bound
    has_one :minimum_bound, Bound, :value_range
    has_one :maximum_bound, Bound, :value_range
  end

  class ValueRestriction
    identified_by :value_restriction_id
    one_to_one :value_restriction_id, ValueRestriction_Id, :value_restriction
  end

  class AllowedRange	# Implicitly Objectified Fact Type
    identified_by :value_range, :value_restriction
    has_one :value_restriction, ValueRestriction
    has_one :value_range, ValueRange
  end

  class FrequencyConstraint < PresenceConstraint
  end

  class MandatoryConstraint < PresenceConstraint
  end

  class RoleRef
    identified_by :role_sequence, :ordinal
    has_one :role, Role
    has_one :ordinal, Ordinal
    has_one :role_sequence, RoleSequence
    has_one :leading_adjective, Adjective, :role_ref
    has_one :trailing_adjective, Adjective, :role_ref
  end

  class SetComparisonConstraint < SetConstraint
  end

  class SetComparisonRoles	# Implicitly Objectified Fact Type
    identified_by :set_comparison_constraint, :role_sequence
    has_one :role_sequence, RoleSequence
    has_one :set_comparison_constraint, SetComparisonConstraint
  end

  class SetEqualityConstraint < SetComparisonConstraint
  end

  class SetExclusionConstraint < SetComparisonConstraint
    maybe :is_mandatory
  end

  class Feature
    identified_by :name, :vocabulary
    has_one :name, Name, :feature
    has_one :vocabulary, "Vocabulary", :feature
  end

  class Vocabulary < Feature
    has_one :parent_vocabulary, Vocabulary, :vocabulary
  end

  class Alias < Feature
  end

  class Concept < Feature
  end

  class EntityType < Concept
    maybe :is_independent
    maybe :is_personal
    one_to_one :fact_type, FactType, :entity_type
  end

  class Import
    identified_by :imported_vocabulary, :vocabulary
    has_one :vocabulary, Vocabulary
    has_one :imported_vocabulary, Vocabulary
  end

  class Correspondence	# Implicitly Objectified Fact Type
    identified_by :imported_feature, :import
    has_one :import, Import
    has_one :imported_feature, Feature
    has_one :local_feature, Feature
  end

  class Population
    identified_by :vocabulary, :name
    has_one :name, Name, :population
    has_one :vocabulary, Vocabulary, :population
  end

  class TypeInheritance < FactType
    identified_by :entity_type, :super_entity_type
    has_one :super_entity_type, EntityType
    has_one :entity_type, EntityType
    maybe :defines_primary_supertype
  end

  class ValueType < Concept
    has_one :value_type, ValueType, :value_type
    has_one :length, Length, :value_type
    has_one :scale, Scale, :value_type
    has_one :value_restriction, ValueRestriction, :value_type
    has_one :unit, Unit, :value_type
  end

end
