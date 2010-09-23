require 'dm-core'

class AllowedRange
  include DataMapper::Resource

  property :value_constraint_id, Integer, :key => true	# Allowed Range is where Value Constraint allows Value Range and Constraint has Constraint Id
  belongs_to :value_constraint, 'ValueConstraint', :child_key => [:value_constraint_id], :parent_key => [:constraint_id]	# Value_Constraint is involved in Allowed Range
  property :value_range_minimum_bound_value_literal, String, :key => true	# Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and Value is represented by Literal
  property :value_range_minimum_bound_value_is_a_string, Boolean, :key => true	# Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and Value is a string
  property :value_range_minimum_bound_value_unit_id, Integer, :key => true	# Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and maybe Value is in Unit and Unit has Unit Id
  property :value_range_minimum_bound_is_inclusive, Boolean, :key => true	# Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound is inclusive
  property :value_range_maximum_bound_value_literal, String, :key => true	# Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and Value is represented by Literal
  property :value_range_maximum_bound_value_is_a_string, Boolean, :key => true	# Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and Value is a string
  property :value_range_maximum_bound_value_unit_id, Integer, :key => true	# Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and maybe Value is in Unit and Unit has Unit Id
  property :value_range_maximum_bound_is_inclusive, Boolean, :key => true	# Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound is inclusive
end

class Concept
  include DataMapper::Resource

  property :name, String, :length => 64, :key => true	# Concept is called Name
  property :vocabulary_name, String, :length => 64, :key => true	# Concept belongs to Vocabulary and Vocabulary is called Name
  property :pronoun, String, :length => 20	# maybe Concept uses Pronoun
  property :is_independent, Boolean, :required => true	# Concept is independent
  has n, :context_note, 'ContextNote', :child_key => [:concept_name, :concept_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Concept has Context Note
  has n, :instance, :child_key => [:concept_name, :concept_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Instance is of Concept
  has n, :join_node, 'JoinNode', :child_key => [:concept_name, :concept_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Join Node is for Concept
  has n, :role, :child_key => [:concept_name, :concept_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Concept plays Role
  has n, :object_type_shape, 'ObjectTypeShape', :child_key => [:concept_name, :concept_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Object Type Shape is for Concept
end

class Constraint
  include DataMapper::Resource

  property :constraint_id, Serial	# Constraint has Constraint Id
  property :name, String, :length => 64	# maybe Name is of Constraint
  property :enforcement_agent_name, String	# maybe Constraint requires Enforcement and maybe Enforcement notifies Agent and Agent has Agent Name
  property :enforcement_code, String, :length => 16	# maybe Constraint requires Enforcement and Enforcement has Enforcement Code
  property :vocabulary_name, String, :length => 64	# maybe Vocabulary contains Constraint and Vocabulary is called Name
  has n, :context_note, 'ContextNote'	# Constraint has Context Note
  has n, :constraint_shape, 'ConstraintShape'	# Constraint Shape is for Constraint
end

class ContextAccordingTo
  include DataMapper::Resource

  property :context_note_id, Integer, :key => true	# Context According To is where Context Note is according to Agent and Context Note has Context Note Id
  belongs_to :context_note, 'ContextNote'	# Context_Note is involved in Context According To
  property :agent_name, String, :key => true	# Context According To is where Context Note is according to Agent and Agent has Agent Name
  property :date, DateTime	# maybe Context According To was lodged on Date
end

class ContextAgreedBy
  include DataMapper::Resource

  property :agreement_context_note_id, Integer, :key => true	# Context Agreed By is where Agreement was reached by Agent and Context Note has Context Note Id
  property :agent_name, String, :key => true	# Context Agreed By is where Agreement was reached by Agent and Agent has Agent Name
end

class ContextNote
  include DataMapper::Resource

  property :context_note_id, Serial	# Context Note has Context Note Id
  property :constraint_id, Integer	# maybe Constraint has Context Note and Constraint has Constraint Id
  belongs_to :constraint	# Constraint has Context Note
  property :context_note_kind, String, :required => true	# Context Note has Context Note Kind
  property :discussion, String, :required => true	# Context Note has Discussion
  property :fact_type_id, Integer	# maybe Fact Type has Context Note and Fact Type has Fact Type Id
  belongs_to :fact_type, 'FactType'	# Fact Type has Context Note
  property :agreement_date, DateTime	# maybe Context Note was added by Agreement and maybe Agreement was on Date
  property :concept_vocabulary_name, String, :length => 64	# maybe Concept has Context Note and Concept belongs to Vocabulary and Vocabulary is called Name
  property :concept_name, String, :length => 64	# maybe Concept has Context Note and Concept is called Name
  belongs_to :concept, :child_key => [:concept_name, :concept_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Concept has Context Note
  has n, :context_according_to, 'ContextAccordingTo'	# Context Note is according to Agent
  has n, :model_note_shape, 'ModelNoteShape'	# Model Note Shape is for Context Note
end

class Derivation
  include DataMapper::Resource

  property :derived_unit_id, Integer, :key => true	# Derivation is where Unit (as Derived Unit) is derived from base-Unit (as Base Unit) and Unit has Unit Id
  belongs_to :derived_unit, 'Unit', :child_key => [:derived_unit_id], :parent_key => [:unit_id]	# Derived_Unit is involved in Derivation
  property :base_unit_id, Integer, :key => true	# Derivation is where Unit (as Derived Unit) is derived from base-Unit (as Base Unit) and Unit has Unit Id
  belongs_to :base_unit, 'Unit', :child_key => [:base_unit_id], :parent_key => [:unit_id]	# Base_Unit is involved in Derivation
  property :exponent, Integer	# maybe Derivation has Exponent
end

class EntityType < Concept
  has 1, :fact_type, 'FactType', :child_key => [:entity_type_name, :entity_type_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Entity Type nests Fact Type
  has n, :type_inheritance_as_subtype, 'TypeInheritance', :child_key => [:subtype_name, :subtype_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Entity Type (as Subtype) is subtype of super-Entity Type (as Supertype)
  has n, :type_inheritance_as_supertype, 'TypeInheritance', :child_key => [:supertype_name, :supertype_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Entity Type (as Subtype) is subtype of super-Entity Type (as Supertype)
end

class Fact
  include DataMapper::Resource

  property :fact_id, Serial	# Fact has Fact Id
  property :fact_type_id, Integer, :required => true	# Fact is of Fact Type and Fact Type has Fact Type Id
  belongs_to :fact_type, 'FactType'	# Fact is of Fact Type
  property :population_vocabulary_name, String, :length => 64	# Population includes Fact and maybe Vocabulary includes Population and Vocabulary is called Name
  property :population_name, String, :length => 64, :required => true	# Population includes Fact and Population has Name
  has 1, :instance	# Instance objectifies Fact
  has n, :role_value, 'RoleValue'	# Role Value fulfils Fact
end

class FactType
  include DataMapper::Resource

  property :fact_type_id, Serial	# Fact Type has Fact Type Id
  property :entity_type_vocabulary_name, String, :length => 64	# maybe Entity Type nests Fact Type and Concept belongs to Vocabulary and Vocabulary is called Name
  property :entity_type_name, String, :length => 64	# maybe Entity Type nests Fact Type and Concept is called Name
  has 1, :entity_type, 'EntityType', :parent_key => [:entity_type_name, :entity_type_vocabulary_name], :child_key => [:name, :vocabulary_name]	# Entity Type nests Fact Type
  has n, :context_note, 'ContextNote'	# Fact Type has Context Note
  has n, :fact	# Fact is of Fact Type
  has n, :reading	# Fact Type has Reading
  has n, :role	# Fact Type has Ordinal role
  has n, :fact_type_shape, 'FactTypeShape'	# Fact Type Shape is for Fact Type
  has n, :join_step, 'JoinStep'	# Join Step traverses Fact Type
  has n, :ring_constraint_shape, 'RingConstraintShape'	# Ring Constraint Shape is attached to Fact Type
end

class ImplicitFactType < FactType
  has 1, :role, :child_key => [:implicit_fact_type_id], :parent_key => [:fact_type_id]	# Implicit Fact Type is implied by Role
end

class Instance
  include DataMapper::Resource

  property :instance_id, Serial	# Instance has Instance Id
  property :fact_id, Integer	# maybe Instance objectifies Fact and Fact has Fact Id
  has 1, :fact	# Instance objectifies Fact
  property :value_literal, String	# maybe Instance has Value and Value is represented by Literal
  property :value_is_a_string, Boolean	# maybe Instance has Value and Value is a string
  property :value_unit_id, Integer	# maybe Instance has Value and maybe Value is in Unit and Unit has Unit Id
  property :concept_vocabulary_name, String, :length => 64, :required => true	# Instance is of Concept and Concept belongs to Vocabulary and Vocabulary is called Name
  property :concept_name, String, :length => 64, :required => true	# Instance is of Concept and Concept is called Name
  belongs_to :concept, :child_key => [:concept_name, :concept_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Instance is of Concept
  property :population_vocabulary_name, String, :length => 64	# Population includes Instance and maybe Vocabulary includes Population and Vocabulary is called Name
  property :population_name, String, :length => 64, :required => true	# Population includes Instance and Population has Name
  has n, :role_value, 'RoleValue'	# Instance plays Role Value
end

class JoinNode
  include DataMapper::Resource

  property :ordinal, Integer, :key => true	# Join Node has Ordinal position
  property :join_id, Integer, :key => true	# Join includes Join Node and Join has Join Id
  property :subscript, Integer	# maybe Join Node has Subscript
  property :value_literal, String	# maybe Join Node has Value and Value is represented by Literal
  property :value_is_a_string, Boolean	# maybe Join Node has Value and Value is a string
  property :value_unit_id, Integer	# maybe Join Node has Value and maybe Value is in Unit and Unit has Unit Id
  property :concept_vocabulary_name, String, :length => 64, :required => true	# Join Node is for Concept and Concept belongs to Vocabulary and Vocabulary is called Name
  property :concept_name, String, :length => 64, :required => true	# Join Node is for Concept and Concept is called Name
  belongs_to :concept, :child_key => [:concept_name, :concept_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Join Node is for Concept
  has n, :join_role, 'JoinRole', :child_key => [:join_node_join_id, :join_node_ordinal], :parent_key => [:join_id, :ordinal]	# Join Node includes Role
end

class JoinRole
  include DataMapper::Resource

  property :join_node_join_id, Integer, :key => true	# Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id
  property :join_node_ordinal, Integer, :key => true	# Join Role is where Join Node includes Role and Join Node has Ordinal position
  belongs_to :join_node, 'JoinNode', :child_key => [:join_node_join_id, :join_node_ordinal], :parent_key => [:join_id, :ordinal]	# Join_Node is involved in Join Role
  property :role_fact_type_id, Integer, :key => true	# Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  property :role_ordinal, Integer, :key => true	# Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role
  belongs_to :role, :child_key => [:role_fact_type_id, :role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# Role is involved in Join Role
  property :join_step_input_join_role_join_node_join_id, Integer	# maybe Join Step involves incidental-Join Role and Join Step has input-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id
  property :join_step_input_join_role_join_node_ordinal, Integer	# maybe Join Step involves incidental-Join Role and Join Step has input-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position
  property :join_step_input_join_role_fact_type_id, Integer	# maybe Join Step involves incidental-Join Role and Join Step has input-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  property :join_step_input_join_role_ordinal, Integer	# maybe Join Step involves incidental-Join Role and Join Step has input-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role
  property :join_step_output_join_role_join_node_join_id, Integer	# maybe Join Step involves incidental-Join Role and Join Step has output-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id
  property :join_step_output_join_role_join_node_ordinal, Integer	# maybe Join Step involves incidental-Join Role and Join Step has output-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position
  property :join_step_output_join_role_fact_type_id, Integer	# maybe Join Step involves incidental-Join Role and Join Step has output-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  property :join_step_output_join_role_ordinal, Integer	# maybe Join Step involves incidental-Join Role and Join Step has output-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role
  belongs_to :join_step, 'JoinStep', :child_key => [:join_step_input_join_role_fact_type_id, :join_step_input_join_role_join_node_join_id, :join_step_input_join_role_join_node_ordinal, :join_step_input_join_role_ordinal, :join_step_output_join_role_fact_type_id, :join_step_output_join_role_join_node_join_id, :join_step_output_join_role_join_node_ordinal, :join_step_output_join_role_ordinal], :parent_key => [:input_join_role_fact_type_id, :input_join_role_join_node_join_id, :input_join_role_join_node_ordinal, :input_join_role_ordinal, :output_join_role_fact_type_id, :output_join_role_join_node_join_id, :output_join_role_join_node_ordinal, :output_join_role_ordinal]	# Join_Step is involved in Join Role
  has n, :join_step, 'JoinStep', :child_key => [:input_join_role_join_node_join_id, :input_join_role_join_node_ordinal, :input_join_role_fact_type_id, :input_join_role_ordinal], :parent_key => [:join_node_join_id, :join_node_ordinal, :role_fact_type_id, :role_ordinal]	# Join_Step is involved in Join Role
  has n, :join_step, 'JoinStep', :child_key => [:output_join_role_join_node_join_id, :output_join_role_join_node_ordinal, :output_join_role_fact_type_id, :output_join_role_ordinal], :parent_key => [:join_node_join_id, :join_node_ordinal, :role_fact_type_id, :role_ordinal]	# Join_Step is involved in Join Role
  has 1, :role_ref, 'RoleRef', :child_key => [:join_role_join_node_join_id, :join_role_join_node_ordinal, :join_role_fact_type_id, :join_role_ordinal], :parent_key => [:join_node_join_id, :join_node_ordinal, :role_fact_type_id, :role_ordinal]	# Role_Ref is involved in Join Role
end

class JoinStep
  include DataMapper::Resource

  property :input_join_role_join_node_join_id, Integer, :key => true	# Join Step has input-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id
  property :input_join_role_join_node_ordinal, Integer, :key => true	# Join Step has input-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position
  property :input_join_role_fact_type_id, Integer, :key => true	# Join Step has input-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  property :input_join_role_ordinal, Integer, :key => true	# Join Step has input-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role
  belongs_to :input_join_role, 'JoinRole', :child_key => [:input_join_role_join_node_join_id, :input_join_role_join_node_ordinal, :input_join_role_fact_type_id, :input_join_role_ordinal], :parent_key => [:join_node_join_id, :join_node_ordinal, :role_fact_type_id, :role_ordinal]	# Join Step has input-Join Role
  property :output_join_role_join_node_join_id, Integer, :key => true	# Join Step has output-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id
  property :output_join_role_join_node_ordinal, Integer, :key => true	# Join Step has output-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position
  property :output_join_role_fact_type_id, Integer, :key => true	# Join Step has output-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  property :output_join_role_ordinal, Integer, :key => true	# Join Step has output-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role
  belongs_to :output_join_role, 'JoinRole', :child_key => [:output_join_role_join_node_join_id, :output_join_role_join_node_ordinal, :output_join_role_fact_type_id, :output_join_role_ordinal], :parent_key => [:join_node_join_id, :join_node_ordinal, :role_fact_type_id, :role_ordinal]	# Join Step has output-Join Role
  property :fact_type_id, Integer, :required => true	# Join Step traverses Fact Type and Fact Type has Fact Type Id
  belongs_to :fact_type, 'FactType'	# Join Step traverses Fact Type
  property :is_anti, Boolean, :required => true	# is anti Join Step
  property :is_outer, Boolean, :required => true	# Join Step is outer
  has n, :incidental_join_role, 'JoinRole', :child_key => [:join_step_input_join_role_fact_type_id, :join_step_input_join_role_join_node_join_id, :join_step_input_join_role_join_node_ordinal, :join_step_input_join_role_ordinal, :join_step_output_join_role_fact_type_id, :join_step_output_join_role_join_node_join_id, :join_step_output_join_role_join_node_ordinal, :join_step_output_join_role_ordinal], :parent_key => [:input_join_role_fact_type_id, :input_join_role_join_node_join_id, :input_join_role_join_node_ordinal, :input_join_role_ordinal, :output_join_role_fact_type_id, :output_join_role_join_node_join_id, :output_join_role_join_node_ordinal, :output_join_role_ordinal]	# Join Step involves incidental-Join Role
end

class ParamValue
  include DataMapper::Resource

  property :value_literal, String, :key => true	# Param Value is where Value for Parameter applies to Value Type and Value is represented by Literal
  property :value_is_a_string, Boolean, :key => true	# Param Value is where Value for Parameter applies to Value Type and Value is a string
  property :value_unit_id, Integer, :key => true	# Param Value is where Value for Parameter applies to Value Type and maybe Value is in Unit and Unit has Unit Id
  property :parameter_name, String, :length => 64, :key => true	# Param Value is where Value for Parameter applies to Value Type and Parameter is where Name is a parameter of Value Type
  property :parameter_value_type_vocabulary_name, String, :length => 64, :key => true	# Param Value is where Value for Parameter applies to Value Type and Parameter is where Name is a parameter of Value Type and Concept belongs to Vocabulary and Vocabulary is called Name
  property :parameter_value_type_name, String, :length => 64, :key => true	# Param Value is where Value for Parameter applies to Value Type and Parameter is where Name is a parameter of Value Type and Concept is called Name
  property :value_type_vocabulary_name, String, :length => 64, :key => true	# Param Value is where Value for Parameter applies to Value Type and Concept belongs to Vocabulary and Vocabulary is called Name
  property :value_type_name, String, :length => 64, :key => true	# Param Value is where Value for Parameter applies to Value Type and Concept is called Name
  belongs_to :value_type, 'ValueType', :child_key => [:value_type_name, :value_type_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Value_Type is involved in Param Value
end

class PresenceConstraint < Constraint
  property :max_frequency, Integer	# maybe Presence Constraint has max-Frequency
  property :min_frequency, Integer	# maybe Presence Constraint has min-Frequency
  property :is_mandatory, Boolean, :required => true	# Presence Constraint is mandatory
  property :is_preferred_identifier, Boolean, :required => true	# Presence Constraint is preferred identifier
  property :role_sequence_id, Integer, :required => true	# Presence Constraint covers Role Sequence and Role Sequence has Role Sequence Id
  belongs_to :role_sequence, 'RoleSequence'	# Presence Constraint covers Role Sequence
end

class Reading
  include DataMapper::Resource

  property :ordinal, Integer, :key => true	# Reading is in Ordinal position
  property :fact_type_id, Integer, :key => true	# Fact Type has Reading and Fact Type has Fact Type Id
  belongs_to :fact_type, 'FactType'	# Fact Type has Reading
  property :text, String, :length => 256, :required => true	# Reading has Text
  property :role_sequence_id, Integer, :required => true	# Reading is in Role Sequence and Role Sequence has Role Sequence Id
  belongs_to :role_sequence, 'RoleSequence'	# Reading is in Role Sequence
end

class RingConstraint < Constraint
  property :ring_type, String, :required => true	# Ring Constraint is of Ring Type
  property :other_role_fact_type_id, Integer	# maybe Ring Constraint has other-Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  property :other_role_ordinal, Integer	# maybe Ring Constraint has other-Role and Role is where Fact Type has Ordinal role
  belongs_to :other_role, 'Role', :child_key => [:other_role_fact_type_id, :other_role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# Ring Constraint has other-Role
  property :role_fact_type_id, Integer	# maybe Role is of Ring Constraint and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  property :role_ordinal, Integer	# maybe Role is of Ring Constraint and Role is where Fact Type has Ordinal role
  belongs_to :role, :child_key => [:role_fact_type_id, :role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# Role is of Ring Constraint
end

class Role
  include DataMapper::Resource

  property :fact_type_id, Integer, :key => true	# Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  belongs_to :fact_type, 'FactType'	# Fact_Type is involved in Role
  property :ordinal, Integer, :key => true	# Role is where Fact Type has Ordinal role
  property :implicit_fact_type_id, Integer	# maybe Implicit Fact Type is implied by Role and Fact Type has Fact Type Id
  has 1, :implicit_fact_type, 'ImplicitFactType', :parent_key => [:implicit_fact_type_id], :child_key => [:fact_type_id]	# Implicit_Fact_Type is involved in Role
  property :role_name, String, :length => 64	# maybe Role has role-Name
  property :concept_vocabulary_name, String, :length => 64, :required => true	# Concept plays Role and Concept belongs to Vocabulary and Vocabulary is called Name
  property :concept_name, String, :length => 64, :required => true	# Concept plays Role and Concept is called Name
  belongs_to :concept, :child_key => [:concept_name, :concept_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Concept is involved in Role
  has n, :ring_constraint, 'RingConstraint', :child_key => [:other_role_fact_type_id, :other_role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# Ring_Constraint is involved in Role
  has n, :ring_constraint, 'RingConstraint', :child_key => [:role_fact_type_id, :role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# Ring_Constraint is involved in Role
  has n, :role_value, 'RoleValue', :child_key => [:role_fact_type_id, :role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# Role_Value is involved in Role
  has 1, :role_value_constraint, 'ValueConstraint', :child_key => [:role_fact_type_id, :role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# role_Value_Constraint is involved in Role
  has n, :join_role, 'JoinRole', :child_key => [:role_fact_type_id, :role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# Join_Role is involved in Role
  has n, :role_display, 'RoleDisplay', :child_key => [:role_fact_type_id, :role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# Role_Display is involved in Role
  has n, :role_ref, 'RoleRef', :child_key => [:role_fact_type_id, :role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# Role_Ref is involved in Role
end

class RoleDisplay
  include DataMapper::Resource

  property :fact_type_shape_id, Integer, :key => true	# Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Shape Id
  belongs_to :fact_type_shape, 'FactTypeShape', :child_key => [:fact_type_shape_id], :parent_key => [:shape_id]	# Fact_Type_Shape is involved in Role Display
  property :role_fact_type_id, Integer, :key => true	# Role Display is where Fact Type Shape displays Role in Ordinal position and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  property :role_ordinal, Integer, :key => true	# Role Display is where Fact Type Shape displays Role in Ordinal position and Role is where Fact Type has Ordinal role
  belongs_to :role, :child_key => [:role_fact_type_id, :role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# Role is involved in Role Display
  property :ordinal, Integer, :key => true	# Role Display is where Fact Type Shape displays Role in Ordinal position
  has 1, :role_name_shape, 'RoleNameShape', :child_key => [:role_display_fact_type_shape_id, :role_display_ordinal], :parent_key => [:fact_type_shape_id, :ordinal]	# Role_Name_Shape is involved in Role Display
  has 1, :value_constraint_shape, 'ValueConstraintShape', :child_key => [:role_display_fact_type_shape_id, :role_display_ordinal], :parent_key => [:fact_type_shape_id, :ordinal]	# Value_Constraint_Shape is involved in Role Display
end

class RoleRef
  include DataMapper::Resource

  property :role_sequence_id, Integer, :key => true	# Role Ref is where Role Sequence in Ordinal position includes Role and Role Sequence has Role Sequence Id
  belongs_to :role_sequence, 'RoleSequence'	# Role_Sequence is involved in Role Ref
  property :ordinal, Integer, :key => true	# Role Ref is where Role Sequence in Ordinal position includes Role
  property :role_fact_type_id, Integer, :key => true	# Role Ref is where Role Sequence in Ordinal position includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  property :role_ordinal, Integer, :key => true	# Role Ref is where Role Sequence in Ordinal position includes Role and Role is where Fact Type has Ordinal role
  belongs_to :role, :child_key => [:role_fact_type_id, :role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# Role is involved in Role Ref
  property :join_role_join_node_join_id, Integer	# maybe Join Role projects Role Ref and Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id
  property :join_role_join_node_ordinal, Integer	# maybe Join Role projects Role Ref and Join Role is where Join Node includes Role and Join Node has Ordinal position
  property :join_role_fact_type_id, Integer	# maybe Join Role projects Role Ref and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  property :join_role_ordinal, Integer	# maybe Join Role projects Role Ref and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role
  has 1, :join_role, 'JoinRole', :parent_key => [:join_role_join_node_join_id, :join_role_join_node_ordinal, :join_role_fact_type_id, :join_role_ordinal], :child_key => [:join_node_join_id, :join_node_ordinal, :role_fact_type_id, :role_ordinal]	# Join_Role is involved in Role Ref
  property :leading_adjective, String, :length => 64	# maybe Role Ref has leading-Adjective
  property :trailing_adjective, String, :length => 64	# maybe Role Ref has trailing-Adjective
end

class RoleSequence
  include DataMapper::Resource

  property :role_sequence_id, Serial	# Role Sequence has Role Sequence Id
  property :has_unused_dependency_to_force_table_in_norma, Boolean, :required => true	# Role Sequence has unused dependency to force table in norma
  has n, :presence_constraint, 'PresenceConstraint'	# Presence Constraint covers Role Sequence
  has n, :reading	# Reading is in Role Sequence
  has n, :subset_constraint, 'SubsetConstraint', :child_key => [:subset_role_sequence_id], :parent_key => [:role_sequence_id]	# Subset Constraint covers subset-Role Sequence
  has n, :subset_constraint, 'SubsetConstraint', :child_key => [:superset_role_sequence_id], :parent_key => [:role_sequence_id]	# Subset Constraint covers superset-Role Sequence
  has n, :role_ref, 'RoleRef'	# Role Sequence in Ordinal position includes Role
  has n, :set_comparison_roles, 'SetComparisonRoles'	# Set Comparison Constraint has in Ordinal position Role Sequence
end

class RoleValue
  include DataMapper::Resource

  property :fact_id, Integer, :key => true	# Role Value fulfils Fact and Fact has Fact Id
  belongs_to :fact	# Role Value fulfils Fact
  property :instance_id, Integer, :key => true	# Instance plays Role Value and Instance has Instance Id
  belongs_to :instance	# Instance plays Role Value
  property :role_fact_type_id, Integer, :required => true	# Role Value is of Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  property :role_ordinal, Integer, :required => true	# Role Value is of Role and Role is where Fact Type has Ordinal role
  belongs_to :role, :child_key => [:role_fact_type_id, :role_ordinal], :parent_key => [:fact_type_id, :ordinal]	# Role Value is of Role
  property :population_vocabulary_name, String, :length => 64	# Population includes Role Value and maybe Vocabulary includes Population and Vocabulary is called Name
  property :population_name, String, :length => 64, :required => true	# Population includes Role Value and Population has Name
end

class SetComparisonRoles
  include DataMapper::Resource

  property :set_comparison_constraint_id, Integer, :key => true	# Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence and Constraint has Constraint Id
  belongs_to :set_comparison_constraint, 'SetComparisonConstraint', :child_key => [:set_comparison_constraint_id], :parent_key => [:constraint_id]	# Set_Comparison_Constraint is involved in Set Comparison Roles
  property :ordinal, Integer, :key => true	# Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence
  property :role_sequence_id, Integer, :key => true	# Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence and Role Sequence has Role Sequence Id
  belongs_to :role_sequence, 'RoleSequence'	# Role_Sequence is involved in Set Comparison Roles
end

class SetConstraint < Constraint
end

class SetComparisonConstraint < SetConstraint
  has n, :set_comparison_roles, 'SetComparisonRoles', :child_key => [:set_comparison_constraint_id], :parent_key => [:constraint_id]	# Set Comparison Constraint has in Ordinal position Role Sequence
end

class SetEqualityConstraint < SetComparisonConstraint
end

class SetExclusionConstraint < SetComparisonConstraint
  property :is_mandatory, Boolean, :required => true	# Set Exclusion Constraint is mandatory
end

class Shape
  include DataMapper::Resource

  property :shape_id, Serial	# Shape has Shape Id
  property :position_x, Integer	# maybe Shape is at Position and Position is at X
  property :position_y, Integer	# maybe Shape is at Position and Position is at Y
  property :is_expanded, Boolean, :required => true	# Shape is expanded
  property :diagram_vocabulary_name, String, :length => 64, :required => true	# Shape is in Diagram and Diagram is for Vocabulary and Vocabulary is called Name
  property :diagram_name, String, :length => 64, :required => true	# Shape is in Diagram and Diagram is called Name
end

class ConstraintShape < Shape
  property :constraint_id, Integer, :required => true	# Constraint Shape is for Constraint and Constraint has Constraint Id
  belongs_to :constraint	# Constraint Shape is for Constraint
end

class FactTypeShape < Shape
  property :display_role_names_setting, String	# maybe Fact Type Shape has Display Role Names Setting
  property :fact_type_id, Integer, :required => true	# Fact Type Shape is for Fact Type and Fact Type has Fact Type Id
  belongs_to :fact_type, 'FactType'	# Fact Type Shape is for Fact Type
  property :rotation_setting, String	# maybe Fact Type Shape has Rotation Setting
  property :objectified_fact_type_name_shape_id, Integer	# maybe Objectified Fact Type Name Shape is for Fact Type Shape and Objectified Fact Type Name Shape is a kind of Shape and Shape has Shape Id
  property :reading_shape_id, Integer	# maybe Fact Type Shape has Reading Shape and Reading Shape is a kind of Shape and Shape has Shape Id
  property :reading_shape_reading_fact_type_id, Integer	# maybe Fact Type Shape has Reading Shape and Reading Shape is for Reading and Fact Type has Reading and Fact Type has Fact Type Id
  property :reading_shape_reading_ordinal, Integer	# maybe Fact Type Shape has Reading Shape and Reading Shape is for Reading and Reading is in Ordinal position
  has n, :role_display, 'RoleDisplay', :child_key => [:fact_type_shape_id], :parent_key => [:shape_id]	# Fact Type Shape displays Role in Ordinal position
end

class ModelNoteShape < Shape
  property :context_note_id, Integer, :required => true	# Model Note Shape is for Context Note and Context Note has Context Note Id
  belongs_to :context_note, 'ContextNote'	# Model Note Shape is for Context Note
end

class ObjectTypeShape < Shape
  property :concept_vocabulary_name, String, :length => 64, :required => true	# Object Type Shape is for Concept and Concept belongs to Vocabulary and Vocabulary is called Name
  property :concept_name, String, :length => 64, :required => true	# Object Type Shape is for Concept and Concept is called Name
  belongs_to :concept, :child_key => [:concept_name, :concept_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Object Type Shape is for Concept
  property :has_expanded_reference_mode, Boolean, :required => true	# Object Type Shape has expanded reference mode
  has n, :value_constraint_shape, 'ValueConstraintShape', :child_key => [:object_type_shape_id], :parent_key => [:shape_id]	# Value Constraint Shape is for Object Type Shape
end

class RingConstraintShape < ConstraintShape
  property :fact_type_id, Integer, :required => true	# Ring Constraint Shape is attached to Fact Type and Fact Type has Fact Type Id
  belongs_to :fact_type, 'FactType'	# Ring Constraint Shape is attached to Fact Type
end

class RoleNameShape < Shape
  property :role_display_fact_type_shape_id, Integer, :required => true	# Role Name Shape is for Role Display and Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Shape Id
  property :role_display_ordinal, Integer, :required => true	# Role Name Shape is for Role Display and Role Display is where Fact Type Shape displays Role in Ordinal position
  has 1, :role_display, 'RoleDisplay', :parent_key => [:role_display_fact_type_shape_id, :role_display_ordinal], :child_key => [:fact_type_shape_id, :ordinal]	# Role Name Shape is for Role Display
end

class SubsetConstraint < SetConstraint
  property :subset_role_sequence_id, Integer, :required => true	# Subset Constraint covers subset-Role Sequence and Role Sequence has Role Sequence Id
  belongs_to :subset_role_sequence, 'RoleSequence', :child_key => [:subset_role_sequence_id], :parent_key => [:role_sequence_id]	# Subset Constraint covers subset-Role Sequence
  property :superset_role_sequence_id, Integer, :required => true	# Subset Constraint covers superset-Role Sequence and Role Sequence has Role Sequence Id
  belongs_to :superset_role_sequence, 'RoleSequence', :child_key => [:superset_role_sequence_id], :parent_key => [:role_sequence_id]	# Subset Constraint covers superset-Role Sequence
end

class TypeInheritance < FactType
  property :subtype_vocabulary_name, String, :length => 64, :key => true	# Type Inheritance is where Entity Type (as Subtype) is subtype of super-Entity Type (as Supertype) and Concept belongs to Vocabulary and Vocabulary is called Name
  property :subtype_name, String, :length => 64, :key => true	# Type Inheritance is where Entity Type (as Subtype) is subtype of super-Entity Type (as Supertype) and Concept is called Name
  belongs_to :subtype, 'EntityType', :child_key => [:subtype_name, :subtype_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Subtype is involved in Type Inheritance
  property :supertype_vocabulary_name, String, :length => 64, :key => true	# Type Inheritance is where Entity Type (as Subtype) is subtype of super-Entity Type (as Supertype) and Concept belongs to Vocabulary and Vocabulary is called Name
  property :supertype_name, String, :length => 64, :key => true	# Type Inheritance is where Entity Type (as Subtype) is subtype of super-Entity Type (as Supertype) and Concept is called Name
  belongs_to :supertype, 'EntityType', :child_key => [:supertype_name, :supertype_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Supertype is involved in Type Inheritance
  property :assimilation, String	# maybe Assimilation applies to Type Inheritance
  property :provides_identification, Boolean, :required => true	# Type Inheritance provides identification
end

class Unit
  include DataMapper::Resource

  property :unit_id, Serial	# Unit has Unit Id
  property :ephemera_url, String	# maybe Ephemera URL provides Unit coefficient
  property :name, String, :length => 64, :required => true	# Name is of Unit
  property :coefficient_numerator, Decimal	# maybe Unit has Coefficient and Coefficient has Numerator
  property :coefficient_denominator, Integer	# maybe Unit has Coefficient and Coefficient has Denominator
  property :coefficient_is_precise, Boolean	# maybe Unit has Coefficient and Coefficient is precise
  property :offset, Decimal	# maybe Unit has Offset
  property :plural_name, String, :length => 64	# maybe Unit has plural-Name
  property :is_fundamental, Boolean, :required => true	# Unit is fundamental
  property :vocabulary_name, String, :length => 64, :required => true	# Vocabulary includes Unit and Vocabulary is called Name
  has n, :derivation_as_derived_unit, 'Derivation', :child_key => [:derived_unit_id], :parent_key => [:unit_id]	# Unit (as Derived Unit) is derived from base-Unit (as Base Unit)
  has n, :derivation_as_base_unit, 'Derivation', :child_key => [:base_unit_id], :parent_key => [:unit_id]	# Unit (as Derived Unit) is derived from base-Unit (as Base Unit)
  has n, :value_type, 'ValueType'	# Value Type is of Unit
end

class ValueConstraint < Constraint
  property :role_fact_type_id, Integer	# maybe Role has role-Value Constraint and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id
  property :role_ordinal, Integer	# maybe Role has role-Value Constraint and Role is where Fact Type has Ordinal role
  has 1, :role, :parent_key => [:role_fact_type_id, :role_ordinal], :child_key => [:fact_type_id, :ordinal]	# Role has role-Value Constraint
  has 1, :value_type, 'ValueType', :child_key => [:value_constraint_id], :parent_key => [:constraint_id]	# Value Type has Value Constraint
  has n, :allowed_range, 'AllowedRange', :child_key => [:value_constraint_id], :parent_key => [:constraint_id]	# Value Constraint allows Value Range
end

class ValueConstraintShape < ConstraintShape
  property :role_display_fact_type_shape_id, Integer	# maybe Role Display has Value Constraint Shape and Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Shape Id
  property :role_display_ordinal, Integer	# maybe Role Display has Value Constraint Shape and Role Display is where Fact Type Shape displays Role in Ordinal position
  has 1, :role_display, 'RoleDisplay', :parent_key => [:role_display_fact_type_shape_id, :role_display_ordinal], :child_key => [:fact_type_shape_id, :ordinal]	# Role Display has Value Constraint Shape
  property :object_type_shape_id, Integer	# maybe Value Constraint Shape is for Object Type Shape and Shape has Shape Id
  belongs_to :object_type_shape, 'ObjectTypeShape', :child_key => [:object_type_shape_id], :parent_key => [:shape_id]	# Value Constraint Shape is for Object Type Shape
end

class ValueType < Concept
  property :length, Integer	# maybe Value Type has Length
  property :scale, Integer	# maybe Value Type has Scale
  property :unit_id, Integer	# maybe Value Type is of Unit and Unit has Unit Id
  belongs_to :unit	# Value Type is of Unit
  property :value_constraint_id, Integer	# maybe Value Type has Value Constraint and Constraint has Constraint Id
  has 1, :value_constraint, 'ValueConstraint', :parent_key => [:value_constraint_id], :child_key => [:constraint_id]	# Value Type has Value Constraint
  property :supertype_vocabulary_name, String, :length => 64	# maybe Value Type is subtype of super-Value Type (as Supertype) and Concept belongs to Vocabulary and Vocabulary is called Name
  property :supertype_name, String, :length => 64	# maybe Value Type is subtype of super-Value Type (as Supertype) and Concept is called Name
  belongs_to :supertype, 'ValueType', :child_key => [:supertype_name, :supertype_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Value Type is subtype of super-Value Type (as Supertype)
  property :is_auto_assigned, Boolean, :required => true	# Value Type is auto-assigned
  has n, :value_type_as_supertype, 'ValueType', :child_key => [:supertype_name, :supertype_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Value Type is subtype of super-Value Type (as Supertype)
  has n, :param_value, 'ParamValue', :child_key => [:value_type_name, :value_type_vocabulary_name], :parent_key => [:name, :vocabulary_name]	# Value for Parameter applies to Value Type
end

