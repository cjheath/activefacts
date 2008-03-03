require 'activefacts/api'

module Metamodel

  class Adjective < String
    value_type :length => 64
  end

  class Constraint_Id < AutoCounter
    value_type 
    binary :constraint, "Constraint", 1
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
    binary :fact_type, "FactType", 1
  end

  class Fact_Id < AutoCounter
    value_type 
    binary :fact, "Fact", 1
  end

  class Frequency < UnsignedInteger
    value_type :length => 32
  end

  class Instance_Id < AutoCounter
    value_type 
    binary :instance, "Instance", 1
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
    binary :role_sequence, "RoleSequence", 1
  end

  class Role_Id < AutoCounter
    value_type 
    binary :role, "Role", 1
  end

  class Scale < UnsignedInteger
    value_type :length => 32
  end

  class Unit_Id < AutoCounter
    value_type 
    binary :unit, "Unit", 1
  end

  class Value < String
    value_type :length => 256
  end

  class ValueRestriction_Id < AutoCounter
    value_type 
    binary :value_restriction, "ValueRestriction", 1
  end

  class Bound
    entity_type :value, :inclusive_bound
    binary :value, Value
  end

  class Coefficient
    entity_type :numerator, :denominator
    binary :numerator, Numerator
    binary :denominator, Denominator
  end

  class Constraint
    entity_type :constraint_id
    binary :constraint_id, Constraint_Id, 1
    binary :name, Name
    binary :enforcement, Enforcement
    binary :vocabulary, "Vocabulary"
  end

  class Fact
    entity_type :fact_id
    binary :fact_id, Fact_Id, 1
    binary :fact_type, "FactType"
    binary :population, "Population"
  end

  class FactType
    entity_type :fact_type_id
    binary :fact_type_id, FactType_Id, 1
    binary :entity_type, "EntityType", 1
  end

  class Instance
    entity_type :instance_id
    binary :instance_id, Instance_Id, 1
    binary :value, Value
    binary :concept, "Concept"
    binary :population, "Population"
  end

  class PresenceConstraint < Constraint
    binary :role_sequence, "RoleSequence"
    binary :max_frequency, Frequency
    binary :min_frequency, Frequency
  end

  class Reading
    entity_type :ordinal, :fact_type
    binary :fact_type, FactType
    binary :reading_text, ReadingText
    binary :role_sequence, "RoleSequence"
    binary :ordinal, Ordinal
  end

  class RingConstraint < Constraint
    binary :role, "Role"
    binary :other_role, "Role"
    binary :ring_type, RingType
  end

  class Role
    entity_type :role_id
    binary :concept, "Concept"
    binary :fact_type, FactType
    binary :role_name, Name
    binary :value_restriction, "ValueRestriction"
    binary :role_id, Role_Id, 1
  end

  class RoleSequence
    entity_type :role_sequence_id
    binary :role_sequence_id, RoleSequence_Id, 1
  end

  class RoleValue
    entity_type :instance, :fact
    binary :population, "Population"
    binary :fact, Fact
    binary :instance, Instance
    binary :role, Role
  end

  class SetConstraint < Constraint
  end

  class SubsetConstraint < SetConstraint
    binary :superset_role_sequence, RoleSequence
    binary :subset_role_sequence, RoleSequence
  end

  class UniquenessConstraint < PresenceConstraint
  end

  class Unit
    entity_type :unit_id
    binary :unit_id, Unit_Id, 1
    binary :coefficient, Coefficient
    binary :name, Name
  end

  class UnitBasis
    entity_type :base_unit, :unit
    binary :unit, Unit
    binary :base_unit, Unit
    binary :exponent, Exponent
  end

  class ValueRange
    entity_type :minimum_bound, :maximum_bound
    binary :minimum_bound, Bound
    binary :maximum_bound, Bound
  end

  class ValueRestriction
    entity_type :value_restriction_id
    binary :value_restriction_id, ValueRestriction_Id, 1
  end

  class AllowedRange	# Implicitly Objectified Fact Type
    entity_type :value_range, :value_restriction
    binary :value_restriction, ValueRestriction
    binary :value_range, ValueRange
  end

  class FrequencyConstraint < PresenceConstraint
  end

  class MandatoryConstraint < PresenceConstraint
  end

  class RoleInSequence
    entity_type :role_sequence, :ordinal
    binary :role, Role
    binary :ordinal, Ordinal
    binary :role_sequence, RoleSequence
    binary :leading_adjective, Adjective
    binary :trailing_adjective, Adjective
  end

  class SetComparisonConstraint < SetConstraint
  end

  class SetComparisonRoles	# Implicitly Objectified Fact Type
    entity_type :set_comparison_constraint, :role_sequence
    binary :role_sequence, RoleSequence
    binary :set_comparison_constraint, SetComparisonConstraint
  end

  class SetEqualityConstraint < SetComparisonConstraint
  end

  class SetExclusionConstraint < SetComparisonConstraint
  end

  class Feature
    entity_type :name, :vocabulary
    binary :name, Name
    binary :vocabulary, "Vocabulary"
  end

  class Vocabulary < Feature
    binary :parent_vocabulary, Vocabulary
  end

  class Alias < Feature
  end

  class Concept < Feature
  end

  class EntityType < Concept
    binary :fact_type, FactType, 1
  end

  class Import
    entity_type :imported_vocabulary, :vocabulary
    binary :vocabulary, Vocabulary
    binary :imported_vocabulary, Vocabulary
  end

  class Correspondence	# Implicitly Objectified Fact Type
    entity_type :imported_feature, :import
    binary :import, Import
    binary :imported_feature, Feature
    binary :local_feature, Feature
  end

  class Population
    entity_type :vocabulary, :name
    binary :name, Name
    binary :vocabulary, Vocabulary
  end

  class TypeInheritance < FactType
    entity_type :entity_type, :super_entity_type
    binary :super_entity_type, EntityType
    binary :entity_type, EntityType
  end

  class ValueType < Concept
    binary :value_type, ValueType
    binary :length, Length
    binary :scale, Scale
    binary :value_restriction, ValueRestriction
    binary :unit, Unit
  end

end
