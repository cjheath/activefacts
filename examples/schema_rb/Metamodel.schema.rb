#
# schema.rb auto-generated using ActiveFacts for Metamodel on 2013-04-17
#

ActiveRecord::Schema.define(:version => 20130417151502) do
  create_table "aggregations", :primary_key => :aggregation_id, :force => true do |t|
    t.integer	"aggregated_variable_id", :null => false
    t.integer	"variable_id", :null => false
    t.string	"aggregate_code", :limit => 32, :null => false
  end

  add_index "aggregations", ["aggregate_code", "aggregated_variable_id"], :name => :index_aggregations_on_aggregate_code_aggregated_variable_id, :unique => true

  create_table "allowed_ranges", :primary_key => :allowed_range_id, :force => true do |t|
    t.Guid	"value_constraint_guid", :null => false
    t.boolean	"value_range_maximum_bound_is_inclusive"
    t.boolean	"value_range_maximum_bound_value_is_a_string"
    t.string	"value_range_maximum_bound_value_literal"
    t.Guid	"value_range_maximum_bound_value_unit_guid"
    t.boolean	"value_range_minimum_bound_is_inclusive"
    t.boolean	"value_range_minimum_bound_value_is_a_string"
    t.string	"value_range_minimum_bound_value_literal"
    t.Guid	"value_range_minimum_bound_value_unit_guid"
  end

  add_index "allowed_ranges", ["value_constraint_guid", "value_range_minimum_bound_value_literal", "value_range_minimum_bound_value_is_a_string", "value_range_minimum_bound_value_unit_guid", "value_range_minimum_bound_is_inclusive", "value_range_maximum_bound_value_literal", "value_range_maximum_bound_value_is_a_string", "value_range_maximum_bound_value_unit_guid", "value_range_maximum_bound_is_inclusive"], :name => :index_allowed_ranges_on_value_constraint_guid_value_range_mi1

  create_table "alternative_sets", :id => false, :force => true do |t|
    t.Guid	"guid", :null => false, :primary => true
    t.boolean	"members_are_exclusive"
  end

  add_index "alternative_sets", ["guid"], :name => :index_alternative_sets_on_guid, :unique => true

  create_table "concepts", :id => false, :force => true do |t|
    t.Guid	"guid", :null => false, :primary => true
    t.string	"implication_rule_name"
  end

  add_index "concepts", ["guid"], :name => :index_concepts_on_guid, :unique => true

  create_table "constraints", :id => false, :force => true do |t|
    t.Guid	"concept_guid", :null => false, :primary => true
    t.string	"enforcement_agent_name"
    t.string	"enforcement_code", :limit => 16
    t.string	"name", :limit => 64
    t.boolean	"presence_constraint_is_mandatory"
    t.boolean	"presence_constraint_is_preferred_identifier"
    t.integer	"presence_constraint_max_frequency"
    t.integer	"presence_constraint_min_frequency"
    t.Guid	"presence_constraint_role_sequence_guid"
    t.integer	"ring_constraint_other_role_id"
    t.string	"ring_constraint_ring_type"
    t.integer	"ring_constraint_role_id"
    t.boolean	"set_exclusion_constraint_is_mandatory"
    t.Guid	"subset_constraint_subset_role_sequence_guid"
    t.Guid	"subset_constraint_superset_role_sequence_guid"
    t.integer	"value_constraint_role_id"
    t.string	"vocabulary_name", :limit => 64
  end

  add_index "constraints", ["concept_guid"], :name => :index_constraints_on_concept_guid, :unique => true
  add_index "constraints", ["subset_constraint_subset_role_sequence_guid", "subset_constraint_superset_role_sequence_guid"], :name => :index_constraints_on_subset_constraint_subset_role_sequence_2
  add_index "constraints", ["value_constraint_role_id"], :name => :index_constraints_on_value_constraint_role_id
  add_index "constraints", ["vocabulary_name", "name"], :name => :index_constraints_on_vocabulary_name_name

  create_table "context_according_tos", :primary_key => :context_according_to_id, :force => true do |t|
    t.Guid	"context_note_guid", :null => false
    t.string	"agent_name", :null => false
    t.datetime	"date"
  end

  add_index "context_according_tos", ["context_note_guid", "agent_name"], :name => :index_context_according_tos_on_context_note_guid_agent_name, :unique => true

  create_table "context_agreed_bies", :primary_key => :context_agreed_by_id, :force => true do |t|
    t.Guid	"agreement_guid", :null => false
    t.string	"agent_name", :null => false
  end

  add_index "context_agreed_bies", ["agreement_guid", "agent_name"], :name => :index_context_agreed_bies_on_agreement_guid_agent_name, :unique => true

  create_table "context_notes", :id => false, :force => true do |t|
    t.Guid	"concept_guid", :null => false, :primary => true
    t.Guid	"relevant_concept_guid"
    t.datetime	"agreement_date"
    t.string	"context_note_kind", :null => false
    t.string	"discussion", :null => false
  end

  add_index "context_notes", ["concept_guid"], :name => :index_context_notes_on_concept_guid, :unique => true

  create_table "derivations", :id => false, :force => true do |t|
    t.Guid	"base_unit_guid", :null => false
    t.Guid	"derived_unit_guid", :null => false
    t.integer	"exponent"
  end

  add_index "derivations", ["derived_unit_guid", "base_unit_guid"], :name => :index_derivations_on_derived_unit_guid_base_unit_guid, :unique => true

  create_table "diagrams", :primary_key => :diagram_id, :force => true do |t|
    t.string	"name", :limit => 64, :null => false
    t.string	"vocabulary_name", :limit => 64, :null => false
  end

  add_index "diagrams", ["vocabulary_name", "name"], :name => :index_diagrams_on_vocabulary_name_name, :unique => true

  create_table "facet_values", :primary_key => :facet_value_id, :force => true do |t|
    t.integer	"value_type_object_type_id", :null => false
    t.string	"facet_name", :limit => 64, :null => false
    t.integer	"facet_value_type_object_type_id", :null => false
    t.boolean	"value_is_a_string"
    t.string	"value_literal", :null => false
    t.Guid	"value_unit_guid"
  end

  add_index "facet_values", ["value_type_object_type_id", "facet_value_type_object_type_id", "facet_name"], :name => :index_facet_values_on_value_type_object_type_id_facet_value_3, :unique => true

  create_table "facts", :id => false, :force => true do |t|
    t.Guid	"concept_guid", :null => false, :primary => true
    t.Guid	"fact_type_guid", :null => false
    t.integer	"population_id", :null => false
  end

  add_index "facts", ["concept_guid"], :name => :index_facts_on_concept_guid, :unique => true

  create_table "fact_types", :id => false, :force => true do |t|
    t.Guid	"concept_guid", :null => false, :primary => true
    t.integer	"entity_type_object_type_id"
    t.string	"type_inheritance_assimilation"
    t.boolean	"type_inheritance_provides_identification"
    t.integer	"type_inheritance_subtype_object_type_id"
    t.integer	"type_inheritance_supertype_object_type_id"
  end

  add_index "fact_types", ["concept_guid"], :name => :index_fact_types_on_concept_guid, :unique => true
  add_index "fact_types", ["entity_type_object_type_id"], :name => :index_fact_types_on_entity_type_object_type_id
  add_index "fact_types", ["type_inheritance_subtype_object_type_id", "type_inheritance_provides_identification"], :name => :index_fact_types_on_type_inheritance_subtype_object_type_id_4
  add_index "fact_types", ["type_inheritance_subtype_object_type_id", "type_inheritance_supertype_object_type_id"], :name => :index_fact_types_on_type_inheritance_subtype_object_type_id_5

  create_table "instances", :id => false, :force => true do |t|
    t.Guid	"concept_guid", :null => false, :primary => true
    t.Guid	"fact_guid"
    t.integer	"object_type_id", :null => false
    t.integer	"population_id", :null => false
    t.boolean	"value_is_a_string"
    t.string	"value_literal"
    t.Guid	"value_unit_guid"
  end

  add_index "instances", ["concept_guid"], :name => :index_instances_on_concept_guid, :unique => true
  add_index "instances", ["fact_guid"], :name => :index_instances_on_fact_guid

  create_table "object_types", :primary_key => :object_type_id, :force => true do |t|
    t.Guid	"concept_guid", :null => false
    t.boolean	"entity_type_is_implied_by_objectification"
    t.boolean	"is_independent"
    t.string	"name", :limit => 64, :null => false
    t.string	"pronoun", :limit => 20
    t.integer	"value_type_length"
    t.integer	"value_type_scale"
    t.integer	"value_type_supertype_object_type_id"
    t.string	"value_type_transaction_timing"
    t.Guid	"value_type_unit_guid"
    t.Guid	"value_type_value_constraint_guid"
    t.string	"vocabulary_name", :limit => 64, :null => false
  end

  add_index "object_types", ["concept_guid"], :name => :index_object_types_on_concept_guid, :unique => true
  add_index "object_types", ["value_type_length", "value_type_scale", "value_type_supertype_object_type_id", "value_type_transaction_timing", "value_type_unit_guid", "value_type_value_constraint_guid"], :name => :index_object_types_on_value_type_length_value_type_scale_val6
  add_index "object_types", ["value_type_value_constraint_guid"], :name => :index_object_types_on_value_type_value_constraint_guid
  add_index "object_types", ["vocabulary_name", "name"], :name => :index_object_types_on_vocabulary_name_name, :unique => true

  create_table "plays", :primary_key => :play_id, :force => true do |t|
    t.integer	"role_id", :null => false
    t.integer	"step_id"
    t.integer	"variable_id", :null => false
  end

  add_index "plays", ["variable_id", "role_id"], :name => :index_plays_on_variable_id_role_id, :unique => true

  create_table "populations", :primary_key => :population_id, :force => true do |t|
    t.Guid	"concept_guid", :null => false
    t.string	"name", :limit => 64, :null => false
    t.string	"vocabulary_name", :limit => 64
  end

  add_index "populations", ["concept_guid"], :name => :index_populations_on_concept_guid, :unique => true
  add_index "populations", ["vocabulary_name", "name"], :name => :index_populations_on_vocabulary_name_name

  create_table "queries", :id => false, :force => true do |t|
    t.Guid	"concept_guid", :null => false, :primary => true
  end

  add_index "queries", ["concept_guid"], :name => :index_queries_on_concept_guid, :unique => true

  create_table "readings", :primary_key => :reading_id, :force => true do |t|
    t.Guid	"fact_type_guid", :null => false
    t.Guid	"role_sequence_guid", :null => false
    t.boolean	"is_negative"
    t.integer	"ordinal", :null => false
    t.string	"text", :limit => 256, :null => false
  end

  add_index "readings", ["fact_type_guid", "ordinal"], :name => :index_readings_on_fact_type_guid_ordinal, :unique => true

  create_table "roles", :primary_key => :role_id, :force => true do |t|
    t.Guid	"concept_guid", :null => false
    t.Guid	"fact_type_guid", :null => false
    t.Guid	"implicit_fact_type_guid"
    t.integer	"object_type_id", :null => false
    t.integer	"ordinal", :null => false
    t.string	"role_name", :limit => 64
  end

  add_index "roles", ["concept_guid"], :name => :index_roles_on_concept_guid, :unique => true
  add_index "roles", ["fact_type_guid", "ordinal"], :name => :index_roles_on_fact_type_guid_ordinal, :unique => true
  add_index "roles", ["implicit_fact_type_guid"], :name => :index_roles_on_implicit_fact_type_guid

  create_table "role_displays", :primary_key => :role_display_id, :force => true do |t|
    t.Guid	"fact_type_shape_guid", :null => false
    t.integer	"role_id", :null => false
    t.integer	"ordinal", :null => false
  end

  add_index "role_displays", ["fact_type_shape_guid", "ordinal"], :name => :index_role_displays_on_fact_type_shape_guid_ordinal, :unique => true

  create_table "role_refs", :primary_key => :role_ref_id, :force => true do |t|
    t.integer	"play_id"
    t.integer	"role_id", :null => false
    t.Guid	"role_sequence_guid", :null => false
    t.string	"leading_adjective", :limit => 64
    t.integer	"ordinal", :null => false
    t.string	"trailing_adjective", :limit => 64
  end

  add_index "role_refs", ["play_id"], :name => :index_role_refs_on_play_id
  add_index "role_refs", ["role_id", "role_sequence_guid"], :name => :index_role_refs_on_role_id_role_sequence_guid, :unique => true
  add_index "role_refs", ["role_sequence_guid", "ordinal"], :name => :index_role_refs_on_role_sequence_guid_ordinal, :unique => true

  create_table "role_sequences", :id => false, :force => true do |t|
    t.Guid	"guid", :null => false, :primary => true
    t.boolean	"has_unused_dependency_to_force_table_in_norma"
  end

  add_index "role_sequences", ["guid"], :name => :index_role_sequences_on_guid, :unique => true

  create_table "role_values", :id => false, :force => true do |t|
    t.Guid	"fact_guid", :null => false
    t.Guid	"instance_guid", :null => false
    t.integer	"population_id", :null => false
    t.integer	"role_id", :null => false
  end

  add_index "role_values", ["fact_guid", "role_id"], :name => :index_role_values_on_fact_guid_role_id, :unique => true

  create_table "set_comparison_roles", :primary_key => :set_comparison_roles_id, :force => true do |t|
    t.Guid	"role_sequence_guid", :null => false
    t.Guid	"set_comparison_constraint_guid", :null => false
    t.integer	"ordinal", :null => false
  end

  add_index "set_comparison_roles", ["set_comparison_constraint_guid", "ordinal"], :name => :index_set_comparison_roles_on_set_comparison_constraint_guid7, :unique => true
  add_index "set_comparison_roles", ["set_comparison_constraint_guid", "role_sequence_guid"], :name => :index_set_comparison_roles_on_set_comparison_constraint_guid8, :unique => true

  create_table "shapes", :id => false, :force => true do |t|
    t.integer	"orm_diagram_id", :null => false
    t.Guid	"constraint_shape_constraint_guid"
    t.string	"fact_type_shape_display_role_names_setting"
    t.Guid	"fact_type_shape_fact_type_guid"
    t.string	"fact_type_shape_rotation_setting"
    t.Guid	"guid", :null => false, :primary => true
    t.boolean	"is_expanded"
    t.integer	"location_x"
    t.integer	"location_y"
    t.Guid	"model_note_shape_context_note_guid"
    t.boolean	"object_type_shape_has_expanded_reference_mode"
    t.integer	"object_type_shape_object_type_id"
    t.Guid	"objectified_fact_type_name_shape_fact_type_shape_guid"
    t.Guid	"reading_shape_fact_type_shape_guid"
    t.integer	"reading_shape_reading_id"
    t.Guid	"ring_constraint_shape_fact_type_guid"
    t.integer	"role_name_shape_role_display_id"
    t.Guid	"value_constraint_shape_object_type_shape_guid"
    t.integer	"value_constraint_shape_role_display_id"
  end

  add_index "shapes", ["guid"], :name => :index_shapes_on_guid, :unique => true
  add_index "shapes", ["orm_diagram_id", "location_x", "location_y"], :name => :index_shapes_on_orm_diagram_id_location_x_location_y
  add_index "shapes", ["objectified_fact_type_name_shape_fact_type_shape_guid"], :name => :index_shapes_on_objectified_fact_type_name_shape_fact_type_s9
  add_index "shapes", ["reading_shape_fact_type_shape_guid"], :name => :index_shapes_on_reading_shape_fact_type_shape_guid
  add_index "shapes", ["role_name_shape_role_display_id"], :name => :index_shapes_on_role_name_shape_role_display_id
  add_index "shapes", ["value_constraint_shape_role_display_id"], :name => :index_shapes_on_value_constraint_shape_role_display_id

  create_table "steps", :primary_key => :step_id, :force => true do |t|
    t.Guid	"alternative_set_guid"
    t.Guid	"fact_type_guid", :null => false
    t.integer	"input_play_id", :null => false
    t.integer	"output_play_id"
    t.boolean	"is_disallowed"
    t.boolean	"is_optional"
  end

  add_index "steps", ["input_play_id", "output_play_id"], :name => :index_steps_on_input_play_id_output_play_id

  create_table "units", :id => false, :force => true do |t|
    t.Guid	"concept_guid", :null => false, :primary => true
    t.integer	"coefficient_denominator"
    t.boolean	"coefficient_is_precise"
    t.decimal	"coefficient_numerator"
    t.string	"ephemera_url"
    t.boolean	"is_fundamental"
    t.string	"name", :limit => 64, :null => false
    t.decimal	"offset"
    t.string	"plural_name", :limit => 64
    t.string	"vocabulary_name", :limit => 64, :null => false
  end

  add_index "units", ["concept_guid"], :name => :index_units_on_concept_guid, :unique => true
  add_index "units", ["name"], :name => :index_units_on_name, :unique => true
  add_index "units", ["plural_name"], :name => :index_units_on_plural_name
  add_index "units", ["vocabulary_name", "name"], :name => :index_units_on_vocabulary_name_name, :unique => true

  create_table "variables", :primary_key => :variable_id, :force => true do |t|
    t.integer	"object_type_id", :null => false
    t.integer	"projection_id"
    t.Guid	"query_guid", :null => false
    t.integer	"ordinal", :null => false
    t.string	"role_name", :limit => 64
    t.integer	"subscript"
    t.boolean	"value_is_a_string"
    t.string	"value_literal"
    t.Guid	"value_unit_guid"
  end

  add_index "variables", ["projection_id"], :name => :index_variables_on_projection_id
  add_index "variables", ["query_guid", "ordinal"], :name => :index_variables_on_query_guid_ordinal, :unique => true

  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :aggregations, :variables, :column => :aggregated_variable_id, :primary_key => :variable_id, :dependent => :cascade
    add_foreign_key :aggregations, :variables, :column => :variable_id, :primary_key => :variable_id, :dependent => :cascade
    add_foreign_key :allowed_ranges, :constraints, :column => :value_constraint_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :allowed_ranges, :units, :column => :value_range_maximum_bound_value_unit_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :allowed_ranges, :units, :column => :value_range_minimum_bound_value_unit_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :constraints, :concepts, :column => :concept_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :constraints, :roles, :column => :ring_constraint_other_role_id, :primary_key => :role_id, :dependent => :cascade
    add_foreign_key :constraints, :roles, :column => :ring_constraint_role_id, :primary_key => :role_id, :dependent => :cascade
    add_foreign_key :constraints, :roles, :column => :value_constraint_role_id, :primary_key => :role_id, :dependent => :cascade
    add_foreign_key :constraints, :role_sequences, :column => :presence_constraint_role_sequence_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :constraints, :role_sequences, :column => :subset_constraint_subset_role_sequence_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :constraints, :role_sequences, :column => :subset_constraint_superset_role_sequence_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :context_according_tos, :context_notes, :column => :context_note_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :context_agreed_bies, :context_notes, :column => :agreement_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :context_notes, :concepts, :column => :concept_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :context_notes, :concepts, :column => :relevant_concept_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :derivations, :units, :column => :base_unit_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :derivations, :units, :column => :derived_unit_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :facet_values, :object_types, :column => :facet_value_type_object_type_id, :primary_key => :object_type_id, :dependent => :cascade
    add_foreign_key :facet_values, :object_types, :column => :value_type_object_type_id, :primary_key => :object_type_id, :dependent => :cascade
    add_foreign_key :facet_values, :units, :column => :value_unit_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :facts, :concepts, :column => :concept_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :facts, :fact_types, :column => :fact_type_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :facts, :populations, :column => :population_id, :primary_key => :population_id, :dependent => :cascade
    add_foreign_key :fact_types, :concepts, :column => :concept_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :fact_types, :object_types, :column => :entity_type_object_type_id, :primary_key => :object_type_id, :dependent => :cascade
    add_foreign_key :fact_types, :object_types, :column => :type_inheritance_subtype_object_type_id, :primary_key => :object_type_id, :dependent => :cascade
    add_foreign_key :fact_types, :object_types, :column => :type_inheritance_supertype_object_type_id, :primary_key => :object_type_id, :dependent => :cascade
    add_foreign_key :instances, :concepts, :column => :concept_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :instances, :facts, :column => :fact_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :instances, :object_types, :column => :object_type_id, :primary_key => :object_type_id, :dependent => :cascade
    add_foreign_key :instances, :populations, :column => :population_id, :primary_key => :population_id, :dependent => :cascade
    add_foreign_key :instances, :units, :column => :value_unit_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :object_types, :concepts, :column => :concept_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :object_types, :constraints, :column => :value_type_value_constraint_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :object_types, :object_types, :column => :value_type_supertype_object_type_id, :primary_key => :object_type_id, :dependent => :cascade
    add_foreign_key :object_types, :units, :column => :value_type_unit_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :plays, :roles, :column => :role_id, :primary_key => :role_id, :dependent => :cascade
    add_foreign_key :plays, :steps, :column => :step_id, :primary_key => :step_id, :dependent => :cascade
    add_foreign_key :plays, :variables, :column => :variable_id, :primary_key => :variable_id, :dependent => :cascade
    add_foreign_key :populations, :concepts, :column => :concept_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :queries, :concepts, :column => :concept_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :readings, :fact_types, :column => :fact_type_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :readings, :role_sequences, :column => :role_sequence_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :roles, :concepts, :column => :concept_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :roles, :fact_types, :column => :implicit_fact_type_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :roles, :fact_types, :column => :fact_type_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :roles, :object_types, :column => :object_type_id, :primary_key => :object_type_id, :dependent => :cascade
    add_foreign_key :role_displays, :roles, :column => :role_id, :primary_key => :role_id, :dependent => :cascade
    add_foreign_key :role_displays, :shapes, :column => :fact_type_shape_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :role_refs, :plays, :column => :play_id, :primary_key => :play_id, :dependent => :cascade
    add_foreign_key :role_refs, :roles, :column => :role_id, :primary_key => :role_id, :dependent => :cascade
    add_foreign_key :role_refs, :role_sequences, :column => :role_sequence_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :role_values, :facts, :column => :fact_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :role_values, :instances, :column => :instance_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :role_values, :populations, :column => :population_id, :primary_key => :population_id, :dependent => :cascade
    add_foreign_key :role_values, :roles, :column => :role_id, :primary_key => :role_id, :dependent => :cascade
    add_foreign_key :set_comparison_roles, :constraints, :column => :set_comparison_constraint_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :set_comparison_roles, :role_sequences, :column => :role_sequence_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :shapes, :constraints, :column => :constraint_shape_constraint_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :shapes, :context_notes, :column => :model_note_shape_context_note_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :shapes, :diagrams, :column => :orm_diagram_id, :primary_key => :diagram_id, :dependent => :cascade
    add_foreign_key :shapes, :fact_types, :column => :ring_constraint_shape_fact_type_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :shapes, :fact_types, :column => :fact_type_shape_fact_type_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :shapes, :object_types, :column => :object_type_shape_object_type_id, :primary_key => :object_type_id, :dependent => :cascade
    add_foreign_key :shapes, :readings, :column => :reading_shape_reading_id, :primary_key => :reading_id, :dependent => :cascade
    add_foreign_key :shapes, :role_displays, :column => :value_constraint_shape_role_display_id, :primary_key => :role_display_id, :dependent => :cascade
    add_foreign_key :shapes, :role_displays, :column => :role_name_shape_role_display_id, :primary_key => :role_display_id, :dependent => :cascade
    add_foreign_key :shapes, :shapes, :column => :value_constraint_shape_object_type_shape_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :shapes, :shapes, :column => :objectified_fact_type_name_shape_fact_type_shape_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :shapes, :shapes, :column => :reading_shape_fact_type_shape_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :steps, :alternative_sets, :column => :alternative_set_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :steps, :fact_types, :column => :fact_type_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :steps, :plays, :column => :input_play_id, :primary_key => :play_id, :dependent => :cascade
    add_foreign_key :steps, :plays, :column => :output_play_id, :primary_key => :play_id, :dependent => :cascade
    add_foreign_key :units, :concepts, :column => :concept_guid, :primary_key => :guid, :dependent => :cascade
    add_foreign_key :variables, :object_types, :column => :object_type_id, :primary_key => :object_type_id, :dependent => :cascade
    add_foreign_key :variables, :queries, :column => :query_guid, :primary_key => :concept_guid, :dependent => :cascade
    add_foreign_key :variables, :roles, :column => :projection_id, :primary_key => :role_id, :dependent => :cascade
    add_foreign_key :variables, :units, :column => :value_unit_guid, :primary_key => :concept_guid, :dependent => :cascade
  end
end
