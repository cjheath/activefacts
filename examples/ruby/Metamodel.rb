require 'activefacts/api'

module ::Metamodel

  class Adjective < String
    value_type :length => 64
  end

  class AgentName < String
    value_type 
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

  class DisplayRoleNamesSetting < String
    value_type 
    restrict 'false', 'true'
  end

  class EnforcementCode < String
    value_type :length => 16
  end

  class EphemeraURL < String
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

  class RotationSetting < String
    value_type 
    restrict 'left', 'right'
  end

  class Scale < UnsignedInteger
    value_type :length => 32
  end

  class ShapeId < AutoCounter
    value_type 
  end

  class Text < String
    value_type :length => 256
  end

  class UnitId < AutoCounter
    value_type 
  end

  class X < SignedInteger
    value_type :length => 32
  end

  class Y < SignedInteger
    value_type :length => 32
  end

  class Agent
    identified_by :agent_name
    one_to_one :agent_name, :mandatory => true  # See AgentName.agent
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
    has_one :name                               # See Name.all_constraint
    has_one :vocabulary                         # See Vocabulary.all_constraint
  end

  class ContextNote
    identified_by :context_note_id
    has_one :concept                            # See Concept.all_context_note
    has_one :constraint                         # See Constraint.all_context_note
    one_to_one :context_note_id, :mandatory => true  # See ContextNoteId.context_note
    has_one :context_note_kind, :mandatory => true  # See ContextNoteKind.all_context_note
    has_one :discussion, :mandatory => true     # See Discussion.all_context_note
    has_one :fact_type                          # See FactType.all_context_note
  end

  class Enforcement
    identified_by :constraint
    has_one :agent                              # See Agent.all_enforcement
    one_to_one :constraint, :mandatory => true  # See Constraint.enforcement
    has_one :enforcement_code, :mandatory => true  # See EnforcementCode.all_enforcement
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
    has_one :concept, :mandatory => true        # See Concept.all_instance
    one_to_one :fact                            # See Fact.instance
    one_to_one :instance_id, :mandatory => true  # See InstanceId.instance
    has_one :population, :mandatory => true     # See Population.all_instance
    has_one :value                              # See Value.all_instance
  end

  class Position
    identified_by :x, :y
    has_one :x, :mandatory => true              # See X.all_position
    has_one :y, :mandatory => true              # See Y.all_position
  end

  class PresenceConstraint < Constraint
    maybe :is_mandatory
    maybe :is_preferred_identifier
    has_one :max_frequency, :class => Frequency  # See Frequency.all_presence_constraint_as_max_frequency
    has_one :min_frequency, :class => Frequency  # See Frequency.all_presence_constraint_as_min_frequency
    has_one :role_sequence, :mandatory => true  # See RoleSequence.all_presence_constraint
  end

  class Reading
    identified_by :fact_type, :ordinal
    has_one :fact_type, :mandatory => true      # See FactType.all_reading
    has_one :ordinal, :mandatory => true        # See Ordinal.all_reading
    has_one :role_sequence, :mandatory => true  # See RoleSequence.all_reading
    has_one :text, :mandatory => true           # See Text.all_reading
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
    has_one :concept, :mandatory => true        # See Concept.all_role
    has_one :role_name, :class => Name          # See Name.all_role_as_role_name
  end

  class RoleSequence
    identified_by :role_sequence_id
    maybe :has_unused_dependency_to_force_table_in_norma
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

  class Shape
    identified_by :shape_id
    has_one :diagram, :mandatory => true        # See Diagram.all_shape
    maybe :is_expanded
    has_one :position                           # See Position.all_shape
    one_to_one :shape_id, :mandatory => true    # See ShapeId.shape
  end

  class SubsetConstraint < SetConstraint
    has_one :subset_role_sequence, :class => RoleSequence, :mandatory => true  # See RoleSequence.all_subset_constraint_as_subset_role_sequence
    has_one :superset_role_sequence, :class => RoleSequence, :mandatory => true  # See RoleSequence.all_subset_constraint_as_superset_role_sequence
  end

  class Unit
    identified_by :unit_id
    has_one :coefficient                        # See Coefficient.all_unit
    has_one :ephemera_url, :class => EphemeraURL  # See EphemeraURL.all_unit
    maybe :is_ephemeral
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

  class ValueRestriction < Constraint
    one_to_one :role, :counterpart => :role_value_restriction  # See Role.role_value_restriction
  end

  class Vocabulary
    identified_by :name
    one_to_one :name, :mandatory => true        # See Name.vocabulary
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

  class Concept
    identified_by :vocabulary, :name
    maybe :is_independent
    has_one :name, :mandatory => true           # See Name.all_concept
    has_one :pronoun                            # See Pronoun.all_concept
    has_one :vocabulary, :mandatory => true     # See Vocabulary.all_concept
  end

  class ConstraintShape < Shape
    has_one :constraint, :mandatory => true     # See Constraint.all_constraint_shape
  end

  class ContextAccordingTo
    identified_by :context_note, :agent
    has_one :agent, :mandatory => true          # See Agent.all_context_according_to
    has_one :context_note, :mandatory => true   # See ContextNote.all_context_according_to
  end

  class ContextAgreedBy
    identified_by :agreement, :agent
    has_one :agent, :mandatory => true          # See Agent.all_context_agreed_by
    has_one :agreement, :mandatory => true      # See Agreement.all_context_agreed_by
  end

  class Derivation
    identified_by :derived_unit, :base_unit
    has_one :base_unit, :class => Unit, :mandatory => true  # See Unit.all_derivation_as_base_unit
    has_one :derived_unit, :class => Unit, :mandatory => true  # See Unit.all_derivation_as_derived_unit
    has_one :exponent                           # See Exponent.all_derivation
  end

  class Diagram
    identified_by :vocabulary, :name
    has_one :name, :mandatory => true           # See Name.all_diagram
    has_one :vocabulary, :mandatory => true     # See Vocabulary.all_diagram
  end

  class EntityType < Concept
    one_to_one :fact_type                       # See FactType.entity_type
  end

  class FactTypeShape < Shape
    has_one :display_role_names_setting         # See DisplayRoleNamesSetting.all_fact_type_shape
    has_one :fact_type, :mandatory => true      # See FactType.all_fact_type_shape
    has_one :rotation_setting                   # See RotationSetting.all_fact_type_shape
  end

  class FrequencyConstraintShape < ConstraintShape
    has_one :role_display, :mandatory => true   # See RoleDisplay.all_frequency_constraint_shape
  end

  class ModelNoteShape < Shape
    has_one :context_note, :mandatory => true   # See ContextNote.all_model_note_shape
  end

  class ObjectTypeShape < Shape
    has_one :concept, :mandatory => true        # See Concept.all_object_type_shape
    maybe :has_expanded_reference_mode
  end

  class ObjectifiedFactTypeNameShape < Shape
    identified_by :fact_type_shape
    one_to_one :fact_type_shape, :mandatory => true  # See FactTypeShape.objectified_fact_type_name_shape
  end

  class Population
    identified_by :vocabulary, :name
    has_one :name, :mandatory => true           # See Name.all_population
    has_one :vocabulary                         # See Vocabulary.all_population
  end

  class ReadingShape < Shape
    identified_by :fact_type_shape
    one_to_one :fact_type_shape, :mandatory => true  # See FactTypeShape.reading_shape
    has_one :reading, :mandatory => true        # See Reading.all_reading_shape
  end

  class RingConstraintShape < ConstraintShape
    has_one :fact_type, :mandatory => true      # See FactType.all_ring_constraint_shape
  end

  class RoleDisplay
    identified_by :fact_type_shape, :ordinal
    has_one :fact_type_shape, :mandatory => true  # See FactTypeShape.all_role_display
    has_one :ordinal, :mandatory => true        # See Ordinal.all_role_display
    has_one :role, :mandatory => true           # See Role.all_role_display
  end

  class RoleNameShape < Shape
    one_to_one :role_display, :mandatory => true  # See RoleDisplay.role_name_shape
  end

  class RoleRef
    identified_by :role_sequence, :ordinal
    has_one :ordinal, :mandatory => true        # See Ordinal.all_role_ref
    has_one :role, :mandatory => true           # See Role.all_role_ref
    has_one :role_sequence, :mandatory => true  # See RoleSequence.all_role_ref
    has_one :leading_adjective, :class => Adjective  # See Adjective.all_role_ref_as_leading_adjective
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

  class TypeInheritance < FactType
    identified_by :subtype, :supertype
    has_one :subtype, :class => EntityType, :mandatory => true  # See EntityType.all_type_inheritance_as_subtype
    has_one :supertype, :class => EntityType, :mandatory => true  # See EntityType.all_type_inheritance_as_supertype
    has_one :assimilation                       # See Assimilation.all_type_inheritance
    maybe :provides_identification
  end

  class ValueConstraintShape < ConstraintShape
    has_one :object_type_shape                  # See ObjectTypeShape.all_value_constraint_shape
    one_to_one :role_display                    # See RoleDisplay.value_constraint_shape
  end

  class ValueRange
    identified_by :minimum_bound, :maximum_bound
    has_one :maximum_bound, :class => Bound     # See Bound.all_value_range_as_maximum_bound
    has_one :minimum_bound, :class => Bound     # See Bound.all_value_range_as_minimum_bound
  end

  class ValueType < Concept
    has_one :length                             # See Length.all_value_type
    has_one :scale                              # See Scale.all_value_type
    has_one :supertype, :class => ValueType     # See ValueType.all_value_type_as_supertype
    has_one :unit                               # See Unit.all_value_type
    one_to_one :value_restriction               # See ValueRestriction.value_type
  end

  class AllowedRange
    identified_by :value_restriction, :value_range
    has_one :value_range, :mandatory => true    # See ValueRange.all_allowed_range
    has_one :value_restriction, :mandatory => true  # See ValueRestriction.all_allowed_range
  end

  class Join
    identified_by :role_ref, :join_step
    has_one :join_step, :class => Ordinal, :mandatory => true  # See Ordinal.all_join_as_join_step
    has_one :role_ref, :mandatory => true       # See RoleRef.all_join
    has_one :concept                            # See Concept.all_join
    has_one :input_role, :class => Role         # See Role.all_join_as_input_role
    maybe :is_anti
    maybe :is_outer
    has_one :output_role, :class => Role        # See Role.all_join_as_output_role
  end

  class Parameter
    identified_by :name, :value_type
    has_one :name, :mandatory => true           # See Name.all_parameter
    has_one :value_type, :mandatory => true     # See ValueType.all_parameter
  end

  class ParamValue
    identified_by :value, :parameter
    has_one :parameter, :mandatory => true      # See Parameter.all_param_value
    has_one :value, :mandatory => true          # See Value.all_param_value
    has_one :value_type, :mandatory => true     # See ValueType.all_param_value
  end

end
