require 'activefacts/api'

module ActiveFacts
  module Metamodel

    class Adjective < String
      value_type :length => 64
    end

    class Assimilation < String
      value_type 
      # REVISIT: Assimilation has restricted values
    end

    class ConstraintId < AutoCounter
      value_type 
    end

    class ContextNoteId < AutoCounter
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

    class Offset < Decimal
      value_type 
    end

    class Ordinal < UnsignedSmallInteger
      value_type :length => 32
    end

    class Pronoun < String
      value_type :length => 20
      # REVISIT: Pronoun has restricted values
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

    class Text < String
      value_type :length => 256
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
      identified_by :numerator, :denominator, :is_precise
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

    class ContextNote
      identified_by :context_note_id
      has_one :concept                            # See Concept.all_context_note
      has_one :constraint                         # See Constraint.all_context_note
      one_to_one :context_note_id                 # See ContextNoteId.context_note
      has_one :fact_type                          # See FactType.all_context_note
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
      has_one :max_frequency, Frequency           # See Frequency.all_presence_constraint_as_max_frequency
      has_one :min_frequency, Frequency           # See Frequency.all_presence_constraint_as_min_frequency
      has_one :role_sequence                      # See RoleSequence.all_presence_constraint
    end

    class Reading
      identified_by :fact_type, :ordinal
      has_one :fact_type                          # See FactType.all_reading
      has_one :ordinal                            # See Ordinal.all_reading
      has_one :role_sequence                      # See RoleSequence.all_reading
      has_one :text                               # See Text.all_reading
    end

    class RingConstraint < Constraint
      has_one :other_role, "Role"                 # See Role.all_ring_constraint_as_other_role
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
      has_one :subset_role_sequence, RoleSequence  # See RoleSequence.all_subset_constraint_as_subset_role_sequence
      has_one :superset_role_sequence, RoleSequence  # See RoleSequence.all_subset_constraint_as_superset_role_sequence
    end

    class Unit
      identified_by :unit_id
      has_one :coefficient                        # See Coefficient.all_unit
      maybe :is_fundamental
      has_one :name                               # See Name.all_unit
      has_one :offset                             # See Offset.all_unit
      one_to_one :unit_id                         # See UnitId.unit
      has_one :vocabulary                         # See Vocabulary.all_unit
    end

    class ValueRange
      identified_by :minimum_bound, :maximum_bound
      has_one :maximum_bound, Bound               # See Bound.all_value_range_as_maximum_bound
      has_one :minimum_bound, Bound               # See Bound.all_value_range_as_minimum_bound
    end

    class ValueRestriction
      identified_by :value_restriction_id
      one_to_one :value_restriction_id            # See ValueRestrictionId.value_restriction
    end

    class Vocabulary
      identified_by :name
      one_to_one :name                            # See Name.vocabulary
    end

    class AllowedRange
      identified_by :value_restriction, :value_range
      has_one :value_range                        # See ValueRange.all_allowed_range
      has_one :value_restriction                  # See ValueRestriction.all_allowed_range
    end

    class Concept
      identified_by :vocabulary, :name
      maybe :is_independent
      has_one :name                               # See Name.all_concept
      has_one :pronoun                            # See Pronoun.all_concept
      has_one :vocabulary                         # See Vocabulary.all_concept
    end

    class Derivation
      identified_by :derived_unit, :base_unit
      has_one :base_unit, Unit                    # See Unit.all_derivation_as_base_unit
      has_one :derived_unit, Unit                 # See Unit.all_derivation_as_derived_unit
      has_one :exponent                           # See Exponent.all_derivation
    end

    class EntityType < Concept
      one_to_one :fact_type                       # See FactType.entity_type
    end

    class Population
      identified_by :vocabulary, :name
      has_one :name                               # See Name.all_population
      has_one :vocabulary                         # See Vocabulary.all_population
    end

    class Role
      identified_by :fact_type, :ordinal
      has_one :concept                            # See Concept.all_role
      has_one :fact_type                          # See FactType.all_role
      has_one :ordinal                            # See Ordinal.all_role
      has_one :role_name, Name                    # See Name.all_role_as_role_name
      has_one :role_value_restriction, ValueRestriction  # See ValueRestriction.all_role_as_role_value_restriction
    end

    class RoleRef
      identified_by :role_sequence, :ordinal
      has_one :ordinal                            # See Ordinal.all_role_ref
      has_one :role                               # See Role.all_role_ref
      has_one :role_sequence                      # See RoleSequence.all_role_ref
      has_one :leading_adjective, Adjective       # See Adjective.all_role_ref_as_leading_adjective
      has_one :trailing_adjective, Adjective      # See Adjective.all_role_ref_as_trailing_adjective
    end

    class SetComparisonConstraint < SetConstraint
    end

    class SetComparisonRoles
      identified_by :set_comparison_constraint, :ordinal
      has_one :ordinal                            # See Ordinal.all_set_comparison_roles
      has_one :role_sequence                      # See RoleSequence.all_set_comparison_roles
      has_one :set_comparison_constraint          # See SetComparisonConstraint.all_set_comparison_roles
    end

    class SetEqualityConstraint < SetComparisonConstraint
    end

    class SetExclusionConstraint < SetComparisonConstraint
      maybe :is_mandatory
    end

    class TypeInheritance < FactType
      identified_by :subtype, :supertype
      has_one :subtype, EntityType                # See EntityType.all_type_inheritance_as_subtype
      has_one :supertype, EntityType              # See EntityType.all_type_inheritance_as_supertype
      has_one :assimilation                       # See Assimilation.all_type_inheritance
      maybe :provides_identification
    end

    class ValueType < Concept
      has_one :length                             # See Length.all_value_type
      has_one :scale                              # See Scale.all_value_type
      has_one :supertype, ValueType               # See ValueType.all_value_type_as_supertype
      has_one :unit                               # See Unit.all_value_type
      has_one :value_restriction                  # See ValueRestriction.all_value_type
    end

    class Join
      identified_by :role_ref, :join_step
      has_one :join_step, Ordinal                 # See Ordinal.all_join_as_join_step
      has_one :role_ref                           # See RoleRef.all_join
      has_one :concept                            # See Concept.all_join
      has_one :input_role, Role                   # See Role.all_join_as_input_role
      has_one :output_role, Role                  # See Role.all_join_as_output_role
    end

    class Parameter
      identified_by :name, :value_type
      has_one :name                               # See Name.all_parameter
      has_one :value_type                         # See ValueType.all_parameter
    end

    class ParamValue
      identified_by :value, :parameter
      has_one :parameter                          # See Parameter.all_param_value
      has_one :value                              # See Value.all_param_value
      has_one :value_type                         # See ValueType.all_param_value
    end

  end
end
