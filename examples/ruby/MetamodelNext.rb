require 'activefacts/api'

module ::Metamodel

  class Adjective < String
    value_type :length => 64
  end

  class Assimilation < String
    value_type 
    restrict 'partitioned', 'separate'
  end

  class ConstraintId < AutoCounter
    value_type 
  end

  class ContextNoteId < AutoCounter
    value_type 
  end

  class ContextNoteKind < String
    value_type 
    restrict 'as_opposed_to', 'because', 'so_that', 'to_avoid'
  end

  class Date < ::Date
    value_type 
  end

  class Denominator < UnsignedInteger
    value_type :length => 32
  end

  class Discussion < String
    value_type 
  end

  class Enforcement < String
    value_type :length => 16
  end

  class Ephemera < String
    value_type 
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

  class Literal < String
    value_type 
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

  class PersonName < String
    value_type 
  end

  class Pronoun < String
    value_type :length => 20
    restrict 'feminine', 'masculine', 'neuter', 'personal'
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

  class ValueConstraintId < AutoCounter
    value_type 
  end

  class Coefficient
    identified_by :numerator, :denominator, :is_precise
    has_one :denominator, :mandatory => true    # See Denominator.all_coefficient
    maybe :is_precise
    has_one :numerator, :mandatory => true      # See Numerator.all_coefficient
  end

  class Constraint
    identified_by :constraint_id
    one_to_one :constraint_id, :mandatory => true  # See ConstraintId.constraint
    has_one :enforcement                        # See Enforcement.all_constraint
    has_one :name                               # See Name.all_constraint
    has_one :vocabulary                         # See Vocabulary.all_constraint
  end

  class ContextNote
    identified_by :context_note_id
    has_one :constraint                         # See Constraint.all_context_note
    one_to_one :context_note_id, :mandatory => true  # See ContextNoteId.context_note
    has_one :context_note_kind, :mandatory => true  # See ContextNoteKind.all_context_note
    has_one :discussion, :mandatory => true     # See Discussion.all_context_note
    has_one :fact_type                          # See FactType.all_context_note
    has_one :object_type                        # See ObjectType.all_context_note
  end

  class Fact
    identified_by :fact_id
    one_to_one :fact_id, :mandatory => true     # See FactId.fact
    has_one :fact_type, :mandatory => true      # See FactType.all_fact
    has_one :population, :mandatory => true     # See Population.all_fact
  end

  class FactType
    identified_by :fact_type_id
    one_to_one :fact_type_id, :mandatory => true  # See FactTypeId.fact_type
  end

  class Instance
    identified_by :instance_id
    one_to_one :fact                            # See Fact.instance
    one_to_one :instance_id, :mandatory => true  # See InstanceId.instance
    has_one :object_type, :mandatory => true    # See ObjectType.all_instance
    has_one :population, :mandatory => true     # See Population.all_instance
    has_one :value                              # See Value.all_instance
  end

  class Person
    identified_by :person_name
    one_to_one :person_name, :mandatory => true  # See PersonName.person
  end

  class PresenceConstraint < Constraint
    maybe :is_mandatory
    maybe :is_preferred_identifier
    has_one :max_frequency, :class => Frequency  # See Frequency.all_presence_constraint_as_max_frequency
    has_one :min_frequency, :class => Frequency  # See Frequency.all_presence_constraint_as_min_frequency
    has_one :role_sequence, :mandatory => true  # See RoleSequence.all_presence_constraint
  end

  class RingConstraint < Constraint
    has_one :other_role, :class => "Role"       # See Role.all_ring_constraint_as_other_role
    has_one :ring_type, :mandatory => true      # See RingType.all_ring_constraint
    has_one :role                               # See Role.all_ring_constraint
  end

  class Role
    identified_by :fact_type, :ordinal
    has_one :fact_type, :mandatory => true      # See FactType.all_role
    has_one :ordinal, :mandatory => true        # See Ordinal.all_role
    has_one :object_type, :mandatory => true    # See ObjectType.all_role
    has_one :role_value_constraint, :class => "ValueConstraint"  # See ValueConstraint.all_role_as_role_value_constraint
  end

  class RoleSequence
    identified_by :role_sequence_id
    one_to_one :role_sequence_id, :mandatory => true  # See RoleSequenceId.role_sequence
  end

  class RoleValue
    identified_by :instance, :fact
    has_one :fact, :mandatory => true           # See Fact.all_role_value
    has_one :instance, :mandatory => true       # See Instance.all_role_value
    has_one :population, :mandatory => true     # See Population.all_role_value
    has_one :role, :mandatory => true           # See Role.all_role_value
  end

  class SetConstraint < Constraint
  end

  class SubsetConstraint < SetConstraint
    has_one :subset_role_sequence, :class => RoleSequence, :mandatory => true  # See RoleSequence.all_subset_constraint_as_subset_role_sequence
    has_one :superset_role_sequence, :class => RoleSequence, :mandatory => true  # See RoleSequence.all_subset_constraint_as_superset_role_sequence
  end

  class Unit
    identified_by :unit_id
    has_one :coefficient                        # See Coefficient.all_unit
    has_one :ephemera                           # See Ephemera.all_unit
    maybe :is_fundamental
    has_one :name, :mandatory => true           # See Name.all_unit
    has_one :offset                             # See Offset.all_unit
    one_to_one :unit_id, :mandatory => true     # See UnitId.unit
    has_one :vocabulary, :mandatory => true     # See Vocabulary.all_unit
  end

  class Value
    identified_by :literal, :is_a_string, :unit
    maybe :is_a_string
    has_one :literal, :mandatory => true        # See Literal.all_value
    has_one :unit                               # See Unit.all_value
  end

  class ValueConstraint
    identified_by :value_constraint_id
    one_to_one :value_constraint_id, :mandatory => true  # See ValueConstraintId.value_constraint
  end

  class Vocabulary
    identified_by :name
    one_to_one :name, :mandatory => true        # See Name.vocabulary
  end

  class less
    identified_by :fact_type, :ordinal
    has_one :fact_type, :mandatory => true      # See FactType.all_less
    has_one :ordinal, :mandatory => true        # See Ordinal.all_less
    has_one :role_sequence, :mandatory => true  # See RoleSequence.all_less
    has_one :text, :mandatory => true           # See Text.all_less
  end

  class Agreement
    identified_by :context_note
    one_to_one :context_note, :mandatory => true  # See ContextNote.agreement
    has_one :date                               # See Date.all_agreement
  end

  class Bound
    identified_by :value, :is_inclusive
    maybe :is_inclusive
    has_one :value, :mandatory => true          # See Value.all_bound
  end

  class ContextAccordingTo
    identified_by :context_note, :person
    has_one :context_note, :mandatory => true   # See ContextNote.all_context_according_to
    has_one :person, :mandatory => true         # See Person.all_context_according_to
    has_one :date                               # See Date.all_context_according_to
  end

  class ContextAgreedBy
    identified_by :agreement, :person
    has_one :agreement, :mandatory => true      # See Agreement.all_context_agreed_by
    has_one :person, :mandatory => true         # See Person.all_context_agreed_by
  end

  class Derivation
    identified_by :derived_unit, :base_unit
    has_one :base_unit, :class => Unit, :mandatory => true  # See Unit.all_derivation_as_base_unit
    has_one :derived_unit, :class => Unit, :mandatory => true  # See Unit.all_derivation_as_derived_unit
    has_one :exponent                           # See Exponent.all_derivation
  end

  class Population
    identified_by :vocabulary, :name
    has_one :name, :mandatory => true           # See Name.all_population
    has_one :vocabulary                         # See Vocabulary.all_population
  end

  class RoleRef
    identified_by :role_sequence, :ordinal
    has_one :ordinal, :mandatory => true        # See Ordinal.all_role_ref
    has_one :role, :mandatory => true           # See Role.all_role_ref
    has_one :role_sequence, :mandatory => true  # See RoleSequence.all_role_ref
    has_one :leading_adjective, :class => Adjective  # See Adjective.all_role_ref_as_leading_adjective
    has_one :role_term, :class => "Term"        # See Term.all_role_ref_as_role_term
    has_one :trailing_adjective, :class => Adjective  # See Adjective.all_role_ref_as_trailing_adjective
  end

  class SetComparisonConstraint < SetConstraint
  end

  class SetComparisonRoles
    identified_by :set_comparison_constraint, :ordinal
    has_one :ordinal, :mandatory => true        # See Ordinal.all_set_comparison_roles
    has_one :role_sequence, :mandatory => true  # See RoleSequence.all_set_comparison_roles
    has_one :set_comparison_constraint, :mandatory => true  # See SetComparisonConstraint.all_set_comparison_roles
  end

  class SetEqualityConstraint < SetComparisonConstraint
  end

  class SetExclusionConstraint < SetComparisonConstraint
    maybe :is_mandatory
  end

  class Term
    identified_by :vocabulary, :name
    has_one :name, :mandatory => true           # See Name.all_term
    has_one :vocabulary, :mandatory => true     # See Vocabulary.all_term
    has_one :object_type                        # See ObjectType.all_term
  end

  class ValueRange
    identified_by :minimum_bound, :maximum_bound
    has_one :maximum_bound, :class => Bound     # See Bound.all_value_range_as_maximum_bound
    has_one :minimum_bound, :class => Bound     # See Bound.all_value_range_as_minimum_bound
  end

  class AllowedRange
    identified_by :value_constraint, :value_range
    has_one :value_constraint, :mandatory => true  # See ValueConstraint.all_allowed_range
    has_one :value_range, :mandatory => true    # See ValueRange.all_allowed_range
  end

  class Join
    identified_by :role_ref, :join_step
    has_one :join_step, :class => Ordinal, :mandatory => true  # See Ordinal.all_join_as_join_step
    has_one :role_ref, :mandatory => true       # See RoleRef.all_join
    has_one :input_role, :class => Role         # See Role.all_join_as_input_role
    maybe :is
    maybe :is_outer
    has_one :object_type                        # See ObjectType.all_join
    has_one :output_role, :class => Role        # See Role.all_join_as_output_role
  end

  class ObjectType
    identified_by :term
    maybe :is_independent
    has_one :pronoun                            # See Pronoun.all_object_type
    one_to_one :term, :mandatory => true        # See Term.object_type
  end

  class ValueType < ObjectType
    has_one :length                             # See Length.all_value_type
    has_one :scale                              # See Scale.all_value_type
    has_one :supertype, :class => ValueType     # See ValueType.all_value_type_as_supertype
    has_one :unit                               # See Unit.all_value_type
    has_one :value_constraint                   # See ValueConstraint.all_value_type
  end

  class EntityType < ObjectType
    one_to_one :fact_type                       # See FactType.entity_type
  end

  class Parameter
    identified_by :name, :value_type
    has_one :name, :mandatory => true           # See Name.all_parameter
    has_one :value_type, :mandatory => true     # See ValueType.all_parameter
  end

  class TypeInheritance < FactType
    identified_by :subtype, :supertype
    has_one :subtype, :class => EntityType, :mandatory => true  # See EntityType.all_type_inheritance_as_subtype
    has_one :supertype, :class => EntityType, :mandatory => true  # See EntityType.all_type_inheritance_as_supertype
    has_one :assimilation                       # See Assimilation.all_type_inheritance
    maybe :provides_identification
  end

  class ParamValue
    identified_by :value, :parameter
    has_one :parameter, :mandatory => true      # See Parameter.all_param_value
    has_one :value, :mandatory => true          # See Value.all_param_value
    has_one :value_type, :mandatory => true     # See ValueType.all_param_value
  end

end
