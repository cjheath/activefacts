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
    maybe :is_inclusive
    has_one :value                              # See Value.all_bound
  end

  class Coefficient
    identified_by :numerator, :denominator
    has_one :denominator                        # See Denominator.all_coefficient
    maybe :is_precise
    has_one :numerator                          # See Numerator.all_coefficient
  end

  class Constraint
    identified_by :constraint_id
    one_to_one :constraint_id                   # See ConstraintId.constraint
    has_one :enforcement                        # See Enforcement.all_constraint
    has_one :name                               # See Name.all_constraint
    has_one :vocabulary                         # See Vocabulary.all_constraint
  end

  class Fact
    identified_by :fact_id
    one_to_one :fact_id                         # See FactId.fact
    has_one :fact_type                          # See FactType.all_fact
    has_one :population                         # See Population.all_fact
  end

  class FactType
    identified_by :fact_type_id
    one_to_one :fact_type_id                    # See FactTypeId.fact_type
  end

  class Instance
    identified_by :instance_id
    has_one :concept                            # See Concept.all_instance
    one_to_one :instance_id                     # See InstanceId.instance
    has_one :population                         # See Population.all_instance
    has_one :value                              # See Value.all_instance
  end

  class PresenceConstraint < Constraint
    maybe :is_mandatory
    maybe :is_preferred_identifier
    has_one :max_frequency, Frequency           # See Frequency.all_presence_constraint_by_max_frequency
    has_one :min_frequency, Frequency           # See Frequency.all_presence_constraint_by_min_frequency
    has_one :role_sequence                      # See RoleSequence.all_presence_constraint
  end

  class Reading
    identified_by :fact_type, :ordinal
    has_one :fact_type                          # See FactType.all_reading
    has_one :ordinal                            # See Ordinal.all_reading
    has_one :reading_text                       # See ReadingText.all_reading
    has_one :role_sequence                      # See RoleSequence.all_reading
  end

  class RingConstraint < Constraint
    has_one :other_role, "Role"                 # See Role.all_ring_constraint_by_other_role
    has_one :ring_type                          # See RingType.all_ring_constraint
    has_one :role                               # See Role.all_ring_constraint
  end

  class RoleSequence
    identified_by :role_sequence_id
    one_to_one :role_sequence_id                # See RoleSequenceId.role_sequence
  end

  class RoleValue
    identified_by :instance, :fact
    has_one :fact                               # See Fact.all_role_value
    has_one :instance                           # See Instance.all_role_value
    has_one :population                         # See Population.all_role_value
    has_one :role                               # See Role.all_role_value
  end

  class SetConstraint < Constraint
  end

  class SubsetConstraint < SetConstraint
    has_one :subset_role_sequence, RoleSequence  # See RoleSequence.all_subset_constraint_by_subset_role_sequence
    has_one :superset_role_sequence, RoleSequence  # See RoleSequence.all_subset_constraint_by_superset_role_sequence
  end

  class Unit
    identified_by :unit_id
    has_one :coefficient                        # See Coefficient.all_unit
    maybe :is_fundamental
    has_one :name                               # See Name.all_unit
    one_to_one :unit_id                         # See UnitId.unit
  end

  class UnitBasis
    identified_by :base_unit, :derived_unit
    has_one :base_unit, Unit                    # See Unit.all_unit_basis_by_base_unit
    has_one :derived_unit, Unit                 # See Unit.all_unit_basis_by_derived_unit
    has_one :exponent                           # See Exponent.all_unit_basis
  end

  class ValueRange
    identified_by :minimum_bound, :maximum_bound
    has_one :maximum_bound, Bound               # See Bound.all_value_range_by_maximum_bound
    has_one :minimum_bound, Bound               # See Bound.all_value_range_by_minimum_bound
  end

  class ValueRestriction
    identified_by :value_restriction_id
    one_to_one :value_restriction_id            # See ValueRestrictionId.value_restriction
  end

  class AllowedRange
    identified_by :value_range, :value_restriction
    has_one :value_range                        # See ValueRange.all_allowed_range
    has_one :value_restriction                  # See ValueRestriction.all_allowed_range
  end

  class Vocabulary
    identified_by :name
    one_to_one :name                            # See Name.vocabulary
  end

  class Import
    identified_by :imported_vocabulary, :vocabulary
    has_one :imported_vocabulary, Vocabulary    # See Vocabulary.all_import_by_imported_vocabulary
    has_one :vocabulary                         # See Vocabulary.all_import
  end

  class Feature
    identified_by :name, :vocabulary
    has_one :name                               # See Name.all_feature
    has_one :vocabulary                         # See Vocabulary.all_feature
  end

  class Correspondence
    identified_by :imported_feature, :import
    has_one :import                             # See Import.all_correspondence
    has_one :imported_feature, Feature          # See Feature.all_correspondence_by_imported_feature
    has_one :local_feature, Feature             # See Feature.all_correspondence_by_local_feature
  end

  class Population
    identified_by :vocabulary, :name
    has_one :name                               # See Name.all_population
    has_one :vocabulary                         # See Vocabulary.all_population
  end

  class SetComparisonConstraint < SetConstraint
  end

  class SetComparisonRoles
    identified_by :set_comparison_constraint, :role_sequence
    has_one :role_sequence                      # See RoleSequence.all_set_comparison_roles
    has_one :set_comparison_constraint          # See SetComparisonConstraint.all_set_comparison_roles
  end

  class SetEqualityConstraint < SetComparisonConstraint
  end

  class SetExclusionConstraint < SetComparisonConstraint
    maybe :is_mandatory
  end

  class Alias < Feature
  end

  class Concept < Feature
    maybe :is_independent
    maybe :is_personal
  end

  class Role
    identified_by :fact_type, :ordinal, :concept
    has_one :concept                            # See Concept.all_role
    has_one :fact_type                          # See FactType.all_role
    has_one :ordinal                            # See Ordinal.all_role
    has_one :role_name, Name                    # See Name.all_role_by_role_name
    has_one :role_value_restriction, ValueRestriction  # See ValueRestriction.all_role_by_role_value_restriction
  end

  class RoleRef
    identified_by :role_sequence, :ordinal
    has_one :ordinal                            # See Ordinal.all_role_ref
    has_one :role                               # See Role.all_role_ref
    has_one :role_sequence                      # See RoleSequence.all_role_ref
    has_one :leading_adjective, Adjective       # See Adjective.all_role_ref_by_leading_adjective
    has_one :trailing_adjective, Adjective      # See Adjective.all_role_ref_by_trailing_adjective
  end

  class JoinPath
    identified_by :role_ref, :join_step
    has_one :join_step, Ordinal                 # See Ordinal.all_join_path_by_join_step
    has_one :role_ref                           # See RoleRef.all_join_path
    has_one :input_role, Role                   # See Role.all_join_path_by_input_role
    has_one :output_role, Role                  # See Role.all_join_path_by_output_role
  end

  class EntityType < Concept
    one_to_one :fact_type                       # See FactType.entity_type
  end

  class TypeInheritance < FactType
    identified_by :subtype, :supertype
    has_one :subtype, EntityType                # See EntityType.all_type_inheritance_by_subtype
    has_one :supertype, EntityType              # See EntityType.all_type_inheritance_by_supertype
    maybe :provides_identification
  end

  class ValueType < Concept
    has_one :length                             # See Length.all_value_type
    has_one :scale                              # See Scale.all_value_type
    has_one :supertype, ValueType               # See ValueType.all_value_type_by_supertype
    has_one :unit                               # See Unit.all_value_type
    has_one :value_restriction                  # See ValueRestriction.all_value_type
  end

end
