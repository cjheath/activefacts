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
    entity_type :value, :inclusive_bound
    binary :value, Value, :bound
  end

  class Coefficient
    entity_type :numerator, :denominator
    binary :numerator, Numerator, :coefficient
    binary :denominator, Denominator, :coefficient
  end

  class Constraint
    entity_type :constraint_id
    binary :constraint_id, Constraint_Id, 1, :constraint
    binary :name, Name, :constraint
    binary :enforcement, Enforcement, :constraint
    binary :vocabulary, "Vocabulary", :constraint
  end

  class Fact
    entity_type :fact_id
    binary :fact_id, Fact_Id, 1, :fact
    binary :fact_type, "FactType", :fact
    binary :population, "Population", :fact
  end

  class FactType
    entity_type :fact_type_id
    binary :fact_type_id, FactType_Id, 1, :fact_type
  end

  class Instance
    entity_type :instance_id
    binary :instance_id, Instance_Id, 1, :instance
    binary :value, Value, :instance
    binary :concept, "Concept", :instance
    binary :population, "Population", :instance
  end

  class PresenceConstraint < Constraint
    binary :role_sequence, "RoleSequence", :presence_constraint
    binary :max_frequency, Frequency, :presence_constraint
    binary :min_frequency, Frequency, :presence_constraint
  end

  class Reading
    entity_type :ordinal, :fact_type
    binary :fact_type, FactType, :reading
    binary :reading_text, ReadingText, :reading
    binary :role_sequence, "RoleSequence", :reading
    binary :ordinal, Ordinal, :reading
  end

  class RingConstraint < Constraint
    binary :role, "Role", :ring_constraint
    binary :other_role, "Role", :ring_constraint
    binary :ring_type, RingType, :ring_constraint
  end

  class Role
    entity_type :role_id
    binary :concept, "Concept"
    binary :fact_type, FactType
    binary :role_name, Name, :role
    binary :value_restriction, "ValueRestriction", :role
    binary :role_id, Role_Id, 1, :role
  end

  class RoleSequence
    entity_type :role_sequence_id
    binary :role_sequence_id, RoleSequence_Id, 1, :role_sequence
  end

  class RoleValue
    entity_type :instance, :fact
    binary :population, "Population", :role_value
    binary :fact, Fact, :role_value
    binary :instance, Instance, :role_value
    binary :role, Role, :role_value
  end

  class SetConstraint < Constraint
  end

  class SubsetConstraint < SetConstraint
    binary :superset_role_sequence, RoleSequence, :subset_constraint
    binary :subset_role_sequence, RoleSequence, :subset_constraint
  end

  class UniquenessConstraint < PresenceConstraint
  end

  class Unit
    entity_type :unit_id
    binary :unit_id, Unit_Id, 1, :unit
    binary :coefficient, Coefficient, :unit
    binary :name, Name, :unit
  end

  class UnitBasis
    entity_type :base_unit, :unit
    binary :unit, Unit
    binary :base_unit, Unit
    binary :exponent, Exponent, :unit_basis
  end

  class ValueRange
    entity_type :minimum_bound, :maximum_bound
    binary :minimum_bound, Bound, :value_range
    binary :maximum_bound, Bound, :value_range
  end

  class ValueRestriction
    entity_type :value_restriction_id
    binary :value_restriction_id, ValueRestriction_Id, 1, :value_restriction
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

  class RoleRef
    entity_type :role_sequence, :ordinal
    binary :role, Role
    binary :ordinal, Ordinal
    binary :role_sequence, RoleSequence
    binary :leading_adjective, Adjective, :role_ref
    binary :trailing_adjective, Adjective, :role_ref
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
    binary :name, Name, :feature
    binary :vocabulary, "Vocabulary", :feature
  end

  class Vocabulary < Feature
    binary :parent_vocabulary, Vocabulary, :vocabulary
  end

  class Alias < Feature
  end

  class Concept < Feature
  end

  class EntityType < Concept
    binary :fact_type, FactType, 1, :entity_type
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
    binary :name, Name, :population
    binary :vocabulary, Vocabulary, :population
  end

  class TypeInheritance < FactType
    entity_type :entity_type, :super_entity_type
    binary :super_entity_type, EntityType
    binary :entity_type, EntityType
  end

  class ValueType < Concept
    binary :value_type, ValueType, :value_type
    binary :length, Length, :value_type
    binary :scale, Scale, :value_type
    binary :value_restriction, ValueRestriction, :value_type
    binary :unit, Unit, :value_type
  end

end
