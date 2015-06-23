#
# schema.rb auto-generated using ActiveFacts for Metamodel on 2015-06-02
#

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Schema.define(:version => 20150602173456) do
  enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
  create_table "aggregations", :id => false, :force => true do |t|
    t.column "aggregation_id", :primary_key, :null => false
    t.column "aggregated_variable_id", :integer, :null => false
    t.column "variable_id", :integer, :null => false
    t.column "aggregate_code", :string, :limit => 32, :null => false
  end

  add_index "aggregations", ["aggregate_code", "aggregated_variable_id"], :name => :index_aggregations_on_aggregate_code_aggregated_variable_id, :unique => true

  create_table "allowed_ranges", :id => false, :force => true do |t|
    t.column "allowed_range_id", :primary_key, :null => false
    t.column "value_constraint_concept_guid", :uuid, :null => false
    t.column "value_range_maximum_bound_is_inclusive", :boolean, :null => true
    t.column "value_range_maximum_bound_value_id", :integer, :null => true
    t.column "value_range_minimum_bound_is_inclusive", :boolean, :null => true
    t.column "value_range_minimum_bound_value_id", :integer, :null => true
  end

  add_index "allowed_ranges", ["value_constraint_concept_guid", "value_range_minimum_bound_value_id", "value_range_minimum_bound_is_inclusive", "value_range_maximum_bound_value_id", "value_range_maximum_bound_is_inclusive"], :name => :index_allowed_ranges_on_value_constraint_concept_guid__27f61618

  create_table "alternative_sets", :id => false, :force => true do |t|
    t.column "guid", :uuid, :default => 'gen_random_uuid()', :primary_key => true, :null => false
    t.column "members_are_exclusive", :boolean, :null => true
  end


  create_table "concepts", :id => false, :force => true do |t|
    t.column "guid", :uuid, :default => 'gen_random_uuid()', :primary_key => true, :null => false
    t.column "constraint_agent_name", :string, :null => true
    t.column "constraint_enforcement_code", :string, :limit => 16, :null => true
    t.column "constraint_name", :string, :limit => 64, :null => true
    t.column "constraint_vocabulary_name", :string, :limit => 64, :null => true
    t.column "context_note_date", :datetime, :null => true
    t.column "context_note_discussion", :string, :null => true
    t.column "context_note_kind", :string, :null => true
    t.column "context_note_relevant_concept_guid", :uuid, :null => true
    t.column "fact_population_id", :integer, :null => true
    t.column "fact_type_concept_guid", :uuid, :null => true
    t.column "implication_rule_name", :string, :null => true
    t.column "instance_fact_concept_guid", :uuid, :null => true
    t.column "instance_object_type_id", :integer, :null => true
    t.column "instance_population_id", :integer, :null => true
    t.column "instance_value_id", :integer, :null => true
    t.column "presence_constraint_is_mandatory", :boolean, :null => true
    t.column "presence_constraint_is_preferred_identifier", :boolean, :null => true
    t.column "presence_constraint_max_frequency", :integer, :limit => 32, :null => true
    t.column "presence_constraint_min_frequency", :integer, :limit => 32, :null => true
    t.column "presence_constraint_role_sequence_guid", :uuid, :null => true
    t.column "ring_constraint_other_role_id", :integer, :null => true
    t.column "ring_constraint_ring_type", :string, :null => true
    t.column "ring_constraint_role_id", :integer, :null => true
    t.column "set_exclusion_constraint_is_mandatory", :boolean, :null => true
    t.column "subset_constraint_subset_role_sequence_guid", :uuid, :null => true
    t.column "subset_constraint_superset_role_sequence_guid", :uuid, :null => true
    t.column "unit_coefficient_denominator", :integer, :limit => 32, :null => true
    t.column "unit_coefficient_is_precise", :boolean, :null => true
    t.column "unit_coefficient_numerator", :decimal, :null => true
    t.column "unit_ephemera_url", :string, :null => true
    t.column "unit_is_fundamental", :boolean, :null => true
    t.column "unit_name", :string, :limit => 64, :null => true
    t.column "unit_offset", :decimal, :null => true
    t.column "unit_plural_name", :string, :limit => 64, :null => true
    t.column "unit_vocabulary_name", :string, :limit => 64, :null => true
    t.column "value_constraint_regular_expression", :string, :null => true
    t.column "value_constraint_role_id", :integer, :null => true
  end

  add_index "concepts", ["constraint_vocabulary_name", "constraint_name"], :name => :index_concepts_on_constraint_vocabulary_name_constraint_name
  add_index "concepts", ["instance_fact_concept_guid"], :name => :index_concepts_on_instance_fact_concept_guid
  add_index "concepts", ["subset_constraint_subset_role_sequence_guid", "subset_constraint_superset_role_sequence_guid"], :name => :index_concepts_on_subset_constraint_subset_role_seque__0804b3dc
  add_index "concepts", ["unit_name"], :name => :index_concepts_on_unit_name
  add_index "concepts", ["unit_plural_name"], :name => :index_concepts_on_unit_plural_name
  add_index "concepts", ["unit_vocabulary_name", "unit_name"], :name => :index_concepts_on_unit_vocabulary_name_unit_name
  add_index "concepts", ["value_constraint_role_id"], :name => :index_concepts_on_value_constraint_role_id

  create_table "context_according_tos", :id => false, :force => true do |t|
    t.column "context_according_to_id", :primary_key, :null => false
    t.column "context_note_concept_guid", :uuid, :null => false
    t.column "agent_name", :string, :null => false
    t.column "date", :datetime, :null => true
  end

  add_index "context_according_tos", ["context_note_concept_guid", "agent_name"], :name => :index_context_according_tos_on_context_note_concept_g__19dd27b8, :unique => true

  create_table "context_agreed_bies", :id => false, :force => true do |t|
    t.column "context_agreed_by_id", :primary_key, :null => false
    t.column "agreement_context_note_concept_guid", :uuid, :null => false
    t.column "agent_name", :string, :null => false
  end

  add_index "context_agreed_bies", ["agreement_context_note_concept_guid", "agent_name"], :name => :index_context_agreed_bies_on_agreement_context_note_c__7f25bff2, :unique => true

  create_table "derivations", :id => false, :force => true do |t|
    t.column "derivation_id", :primary_key, :null => false
    t.column "base_unit_concept_guid", :uuid, :null => false
    t.column "derived_unit_concept_guid", :uuid, :null => false
    t.column "exponent", :integer, :limit => 16, :null => true
  end

  add_index "derivations", ["derived_unit_concept_guid", "base_unit_concept_guid"], :name => :index_derivations_on_derived_unit_concept_guid_base_u__a3406667, :unique => true

  create_table "diagrams", :id => false, :force => true do |t|
    t.column "diagram_id", :primary_key, :null => false
    t.column "name", :string, :limit => 64, :null => false
    t.column "vocabulary_name", :string, :limit => 64, :null => false
  end

  add_index "diagrams", ["vocabulary_name", "name"], :name => :index_diagrams_on_vocabulary_name_name, :unique => true

  create_table "facets", :id => false, :force => true do |t|
    t.column "facet_id", :primary_key, :null => false
    t.column "facet_value_type_object_type_id", :integer, :null => false
    t.column "value_type_object_type_id", :integer, :null => false
    t.column "name", :string, :limit => 64, :null => false
  end

  add_index "facets", ["value_type_object_type_id", "name"], :name => :index_facets_on_value_type_object_type_id_name, :unique => true

  create_table "facet_restrictions", :id => false, :force => true do |t|
    t.column "facet_restriction_id", :primary_key, :null => false
    t.column "facet_id", :integer, :null => false
    t.column "value_id", :integer, :null => false
    t.column "value_type_object_type_id", :integer, :null => false
  end

  add_index "facet_restrictions", ["value_type_object_type_id", "facet_id"], :name => :index_facet_restrictions_on_value_type_object_type_id_facet_id, :unique => true

  create_table "fact_types", :id => false, :force => true do |t|
    t.column "concept_guid", :uuid, :default => 'gen_random_uuid()', :primary_key => true, :null => false
    t.column "entity_type_object_type_id", :integer, :null => true
    t.column "type_inheritance_assimilation", :string, :null => true
    t.column "type_inheritance_provides_identification", :boolean, :null => true
    t.column "type_inheritance_subtype_object_type_id", :integer, :null => true
    t.column "type_inheritance_supertype_object_type_id", :integer, :null => true
  end

  add_index "fact_types", ["entity_type_object_type_id"], :name => :index_fact_types_on_entity_type_object_type_id
  add_index "fact_types", ["type_inheritance_subtype_object_type_id", "type_inheritance_provides_identification"], :name => :index_fact_types_on_type_inheritance_subtype_object_t__04417c92
  add_index "fact_types", ["type_inheritance_subtype_object_type_id", "type_inheritance_supertype_object_type_id"], :name => :index_fact_types_on_type_inheritance_subtype_object_t__9c8eded7

  create_table "object_types", :id => false, :force => true do |t|
    t.column "object_type_id", :primary_key, :null => false
    t.column "concept_guid", :uuid, :null => false
    t.column "is_independent", :boolean, :null => true
    t.column "name", :string, :limit => 64, :null => false
    t.column "pronoun", :string, :limit => 20, :null => true
    t.column "value_type_length", :integer, :limit => 32, :null => true
    t.column "value_type_scale", :integer, :limit => 32, :null => true
    t.column "value_type_supertype_object_type_id", :integer, :null => true
    t.column "value_type_transaction_phase", :string, :null => true
    t.column "value_type_unit_concept_guid", :uuid, :null => true
    t.column "value_type_value_constraint_concept_guid", :uuid, :null => true
    t.column "vocabulary_name", :string, :limit => 64, :null => false
  end

  add_index "object_types", ["concept_guid"], :name => :index_object_types_on_concept_guid, :unique => true
  add_index "object_types", ["value_type_length", "value_type_scale", "value_type_supertype_object_type_id", "value_type_transaction_phase", "value_type_unit_concept_guid", "value_type_value_constraint_concept_guid"], :name => :index_object_types_on_value_type_length_value_type_sc__bb56328c
  add_index "object_types", ["value_type_value_constraint_concept_guid"], :name => :index_object_types_on_value_type_value_constraint_concept_guid
  add_index "object_types", ["vocabulary_name", "name"], :name => :index_object_types_on_vocabulary_name_name, :unique => true

  create_table "plays", :id => false, :force => true do |t|
    t.column "play_id", :primary_key, :null => false
    t.column "role_id", :integer, :null => false
    t.column "step_id", :integer, :null => true
    t.column "variable_id", :integer, :null => false
  end

  add_index "plays", ["variable_id", "role_id"], :name => :index_plays_on_variable_id_role_id, :unique => true

  create_table "populations", :id => false, :force => true do |t|
    t.column "population_id", :primary_key, :null => false
    t.column "concept_guid", :uuid, :null => false
    t.column "name", :string, :limit => 64, :null => false
    t.column "vocabulary_name", :string, :limit => 64, :null => true
  end

  add_index "populations", ["concept_guid"], :name => :index_populations_on_concept_guid, :unique => true
  add_index "populations", ["vocabulary_name", "name"], :name => :index_populations_on_vocabulary_name_name

  create_table "readings", :id => false, :force => true do |t|
    t.column "reading_id", :primary_key, :null => false
    t.column "fact_type_concept_guid", :uuid, :null => false
    t.column "role_sequence_guid", :uuid, :null => false
    t.column "is_negative", :boolean, :null => true
    t.column "ordinal", :integer, :limit => 16, :null => false
    t.column "text", :string, :limit => 256, :null => false
  end

  add_index "readings", ["fact_type_concept_guid", "ordinal"], :name => :index_readings_on_fact_type_concept_guid_ordinal, :unique => true

  create_table "roles", :id => false, :force => true do |t|
    t.column "role_id", :primary_key, :null => false
    t.column "concept_guid", :uuid, :null => false
    t.column "fact_type_concept_guid", :uuid, :null => false
    t.column "object_type_id", :integer, :null => false
    t.column "ordinal", :integer, :limit => 16, :null => false
    t.column "role_name", :string, :limit => 64, :null => true
    t.column "role_proxy_link_fact_type_concept_guid", :uuid, :null => true
    t.column "role_proxy_role_id", :integer, :null => true
  end

  add_index "roles", ["concept_guid"], :name => :index_roles_on_concept_guid, :unique => true
  add_index "roles", ["fact_type_concept_guid", "ordinal"], :name => :index_roles_on_fact_type_concept_guid_ordinal, :unique => true
  add_index "roles", ["role_proxy_link_fact_type_concept_guid"], :name => :index_roles_on_role_proxy_link_fact_type_concept_guid
  add_index "roles", ["role_proxy_role_id"], :name => :index_roles_on_role_proxy_role_id

  create_table "role_displays", :id => false, :force => true do |t|
    t.column "role_display_id", :primary_key, :null => false
    t.column "fact_type_shape_guid", :uuid, :null => false
    t.column "role_id", :integer, :null => false
    t.column "ordinal", :integer, :limit => 16, :null => false
  end

  add_index "role_displays", ["fact_type_shape_guid", "ordinal"], :name => :index_role_displays_on_fact_type_shape_guid_ordinal, :unique => true

  create_table "role_refs", :id => false, :force => true do |t|
    t.column "role_ref_id", :primary_key, :null => false
    t.column "play_id", :integer, :null => true
    t.column "role_id", :integer, :null => false
    t.column "role_sequence_guid", :uuid, :null => false
    t.column "leading_adjective", :string, :limit => 64, :null => true
    t.column "ordinal", :integer, :limit => 16, :null => false
    t.column "trailing_adjective", :string, :limit => 64, :null => true
  end

  add_index "role_refs", ["play_id"], :name => :index_role_refs_on_play_id
  add_index "role_refs", ["role_id", "role_sequence_guid"], :name => :index_role_refs_on_role_id_role_sequence_guid, :unique => true
  add_index "role_refs", ["role_sequence_guid", "ordinal"], :name => :index_role_refs_on_role_sequence_guid_ordinal, :unique => true

  create_table "role_sequences", :id => false, :force => true do |t|
    t.column "guid", :uuid, :default => 'gen_random_uuid()', :primary_key => true, :null => false
    t.column "has_unused_dependency_to_force_table_in_norma", :boolean, :null => true
  end


  create_table "role_values", :id => false, :force => true do |t|
    t.column "role_value_id", :primary_key, :null => false
    t.column "fact_concept_guid", :uuid, :null => false
    t.column "instance_concept_guid", :uuid, :null => false
    t.column "population_id", :integer, :null => false
    t.column "role_id", :integer, :null => false
  end

  add_index "role_values", ["fact_concept_guid", "role_id"], :name => :index_role_values_on_fact_concept_guid_role_id, :unique => true

  create_table "set_comparison_roles", :id => false, :force => true do |t|
    t.column "set_comparison_roles_id", :primary_key, :null => false
    t.column "role_sequence_guid", :uuid, :null => false
    t.column "set_comparison_constraint_concept_guid", :uuid, :null => false
    t.column "ordinal", :integer, :limit => 16, :null => false
  end

  add_index "set_comparison_roles", ["set_comparison_constraint_concept_guid", "ordinal"], :name => :index_set_comparison_roles_on_set_comparison_constrai__5dea248f, :unique => true
  add_index "set_comparison_roles", ["set_comparison_constraint_concept_guid", "role_sequence_guid"], :name => :index_set_comparison_roles_on_set_comparison_constrai__619ed890, :unique => true

  create_table "shapes", :id => false, :force => true do |t|
    t.column "guid", :uuid, :default => 'gen_random_uuid()', :primary_key => true, :null => false
    t.column "orm_diagram_id", :integer, :null => false
    t.column "constraint_shape_constraint_concept_guid", :uuid, :null => true
    t.column "fact_type_shape_display_role_names_setting", :string, :null => true
    t.column "fact_type_shape_fact_type_concept_guid", :uuid, :null => true
    t.column "fact_type_shape_rotation_setting", :string, :null => true
    t.column "is_expanded", :boolean, :null => true
    t.column "location_x", :integer, :limit => 32, :null => true
    t.column "location_y", :integer, :limit => 32, :null => true
    t.column "model_note_shape_context_note_concept_guid", :uuid, :null => true
    t.column "object_type_shape_has_expanded_reference_mode", :boolean, :null => true
    t.column "object_type_shape_object_type_id", :integer, :null => true
    t.column "objectified_fact_type_name_shape_fact_type_shape_guid", :uuid, :null => true
    t.column "reading_shape_fact_type_shape_guid", :uuid, :null => true
    t.column "reading_shape_reading_id", :integer, :null => true
    t.column "ring_constraint_shape_fact_type_shape_guid", :uuid, :null => true
    t.column "role_name_shape_role_display_id", :integer, :null => true
    t.column "value_constraint_shape_object_type_shape_guid", :uuid, :null => true
    t.column "value_constraint_shape_role_display_id", :integer, :null => true
  end

  add_index "shapes", ["orm_diagram_id", "location_x", "location_y"], :name => :index_shapes_on_orm_diagram_id_location_x_location_y
  add_index "shapes", ["objectified_fact_type_name_shape_fact_type_shape_guid"], :name => :index_shapes_on_objectified_fact_type_name_shape_fact__12ad8c9b
  add_index "shapes", ["reading_shape_fact_type_shape_guid"], :name => :index_shapes_on_reading_shape_fact_type_shape_guid
  add_index "shapes", ["role_name_shape_role_display_id"], :name => :index_shapes_on_role_name_shape_role_display_id
  add_index "shapes", ["value_constraint_shape_role_display_id"], :name => :index_shapes_on_value_constraint_shape_role_display_id

  create_table "steps", :id => false, :force => true do |t|
    t.column "step_id", :primary_key, :null => false
    t.column "alternative_set_guid", :uuid, :null => true
    t.column "fact_type_concept_guid", :uuid, :null => false
    t.column "input_play_id", :integer, :null => false
    t.column "output_play_id", :integer, :null => true
    t.column "is_disallowed", :boolean, :null => true
    t.column "is_optional", :boolean, :null => true
  end

  add_index "steps", ["input_play_id", "output_play_id"], :name => :index_steps_on_input_play_id_output_play_id

  create_table "values", :id => false, :force => true do |t|
    t.column "value_id", :primary_key, :null => false
    t.column "unit_concept_guid", :uuid, :null => true
    t.column "value_type_object_type_id", :integer, :null => false
    t.column "is_literal_string", :boolean, :null => true
    t.column "literal", :string, :null => false
  end

  add_index "values", ["literal", "is_literal_string", "unit_concept_guid"], :name => :index_values_on_literal_is_literal_string_unit_concept_guid

  create_table "variables", :id => false, :force => true do |t|
    t.column "variable_id", :primary_key, :null => false
    t.column "object_type_id", :integer, :null => false
    t.column "projection_id", :integer, :null => true
    t.column "query_concept_guid", :uuid, :null => false
    t.column "value_id", :integer, :null => true
    t.column "ordinal", :integer, :limit => 16, :null => false
    t.column "role_name", :string, :limit => 64, :null => true
    t.column "subscript", :integer, :limit => 16, :null => true
  end

  add_index "variables", ["projection_id"], :name => :index_variables_on_projection_id
  add_index "variables", ["query_concept_guid", "ordinal"], :name => :index_variables_on_query_concept_guid_ordinal, :unique => true

  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :aggregations, :variables, :column => :aggregated_variable_id, :primary_key => :variable_id, :on_delete => :cascade
    add_index :aggregations, [:aggregated_variable_id], :unique => false
    add_foreign_key :aggregations, :variables, :column => :variable_id, :primary_key => :variable_id, :on_delete => :cascade
    add_index :aggregations, [:variable_id], :unique => false
    add_foreign_key :allowed_ranges, :concepts, :column => :value_constraint_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :allowed_ranges, [:value_constraint_concept_guid], :unique => false
    add_foreign_key :allowed_ranges, :values, :column => :value_range_maximum_bound_value_id, :primary_key => :value_id, :on_delete => :cascade
    add_index :allowed_ranges, [:value_range_maximum_bound_value_id], :unique => false
    add_foreign_key :allowed_ranges, :values, :column => :value_range_minimum_bound_value_id, :primary_key => :value_id, :on_delete => :cascade
    add_index :allowed_ranges, [:value_range_minimum_bound_value_id], :unique => false
    add_foreign_key :concepts, :concepts, :column => :context_note_relevant_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :concepts, [:context_note_relevant_concept_guid], :unique => false
    add_foreign_key :concepts, :concepts, :column => :instance_fact_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_foreign_key :concepts, :fact_types, :column => :fact_type_concept_guid, :primary_key => :concept_guid, :on_delete => :cascade
    add_index :concepts, [:fact_type_concept_guid], :unique => false
    add_foreign_key :concepts, :object_types, :column => :instance_object_type_id, :primary_key => :object_type_id, :on_delete => :cascade
    add_index :concepts, [:instance_object_type_id], :unique => false
    add_foreign_key :concepts, :populations, :column => :fact_population_id, :primary_key => :population_id, :on_delete => :cascade
    add_index :concepts, [:fact_population_id], :unique => false
    add_foreign_key :concepts, :populations, :column => :instance_population_id, :primary_key => :population_id, :on_delete => :cascade
    add_index :concepts, [:instance_population_id], :unique => false
    add_foreign_key :concepts, :roles, :column => :ring_constraint_other_role_id, :primary_key => :role_id, :on_delete => :cascade
    add_index :concepts, [:ring_constraint_other_role_id], :unique => false
    add_foreign_key :concepts, :roles, :column => :ring_constraint_role_id, :primary_key => :role_id, :on_delete => :cascade
    add_index :concepts, [:ring_constraint_role_id], :unique => false
    add_foreign_key :concepts, :roles, :column => :value_constraint_role_id, :primary_key => :role_id, :on_delete => :cascade
    add_foreign_key :concepts, :role_sequences, :column => :presence_constraint_role_sequence_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :concepts, [:presence_constraint_role_sequence_guid], :unique => false
    add_foreign_key :concepts, :role_sequences, :column => :subset_constraint_subset_role_sequence_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :concepts, [:subset_constraint_subset_role_sequence_guid], :unique => false
    add_foreign_key :concepts, :role_sequences, :column => :subset_constraint_superset_role_sequence_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :concepts, [:subset_constraint_superset_role_sequence_guid], :unique => false
    add_foreign_key :concepts, :values, :column => :instance_value_id, :primary_key => :value_id, :on_delete => :cascade
    add_index :concepts, [:instance_value_id], :unique => false
    add_foreign_key :context_according_tos, :concepts, :column => :context_note_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :context_according_tos, [:context_note_concept_guid], :unique => false
    add_foreign_key :context_agreed_bies, :concepts, :column => :agreement_context_note_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :context_agreed_bies, [:agreement_context_note_concept_guid], :unique => false
    add_foreign_key :derivations, :concepts, :column => :base_unit_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :derivations, [:base_unit_concept_guid], :unique => false
    add_foreign_key :derivations, :concepts, :column => :derived_unit_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :derivations, [:derived_unit_concept_guid], :unique => false
    add_foreign_key :facets, :object_types, :column => :facet_value_type_object_type_id, :primary_key => :object_type_id, :on_delete => :cascade
    add_index :facets, [:facet_value_type_object_type_id], :unique => false
    add_foreign_key :facets, :object_types, :column => :value_type_object_type_id, :primary_key => :object_type_id, :on_delete => :cascade
    add_index :facets, [:value_type_object_type_id], :unique => false
    add_foreign_key :facet_restrictions, :facets, :column => :facet_id, :primary_key => :facet_id, :on_delete => :cascade
    add_index :facet_restrictions, [:facet_id], :unique => false
    add_foreign_key :facet_restrictions, :object_types, :column => :value_type_object_type_id, :primary_key => :object_type_id, :on_delete => :cascade
    add_index :facet_restrictions, [:value_type_object_type_id], :unique => false
    add_foreign_key :facet_restrictions, :values, :column => :value_id, :primary_key => :value_id, :on_delete => :cascade
    add_index :facet_restrictions, [:value_id], :unique => false
    add_foreign_key :fact_types, :concepts, :column => :concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_foreign_key :fact_types, :object_types, :column => :entity_type_object_type_id, :primary_key => :object_type_id, :on_delete => :cascade
    add_foreign_key :fact_types, :object_types, :column => :type_inheritance_subtype_object_type_id, :primary_key => :object_type_id, :on_delete => :cascade
    add_index :fact_types, [:type_inheritance_subtype_object_type_id], :unique => false
    add_foreign_key :fact_types, :object_types, :column => :type_inheritance_supertype_object_type_id, :primary_key => :object_type_id, :on_delete => :cascade
    add_index :fact_types, [:type_inheritance_supertype_object_type_id], :unique => false
    add_foreign_key :object_types, :concepts, :column => :value_type_value_constraint_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_foreign_key :object_types, :concepts, :column => :concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_foreign_key :object_types, :concepts, :column => :value_type_unit_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :object_types, [:value_type_unit_concept_guid], :unique => false
    add_foreign_key :object_types, :object_types, :column => :value_type_supertype_object_type_id, :primary_key => :object_type_id, :on_delete => :cascade
    add_index :object_types, [:value_type_supertype_object_type_id], :unique => false
    add_foreign_key :plays, :roles, :column => :role_id, :primary_key => :role_id, :on_delete => :cascade
    add_index :plays, [:role_id], :unique => false
    add_foreign_key :plays, :steps, :column => :step_id, :primary_key => :step_id, :on_delete => :cascade
    add_index :plays, [:step_id], :unique => false
    add_foreign_key :plays, :variables, :column => :variable_id, :primary_key => :variable_id, :on_delete => :cascade
    add_index :plays, [:variable_id], :unique => false
    add_foreign_key :populations, :concepts, :column => :concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_foreign_key :readings, :fact_types, :column => :fact_type_concept_guid, :primary_key => :concept_guid, :on_delete => :cascade
    add_index :readings, [:fact_type_concept_guid], :unique => false
    add_foreign_key :readings, :role_sequences, :column => :role_sequence_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :readings, [:role_sequence_guid], :unique => false
    add_foreign_key :roles, :concepts, :column => :concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_foreign_key :roles, :fact_types, :column => :role_proxy_link_fact_type_concept_guid, :primary_key => :concept_guid, :on_delete => :cascade
    add_foreign_key :roles, :fact_types, :column => :fact_type_concept_guid, :primary_key => :concept_guid, :on_delete => :cascade
    add_index :roles, [:fact_type_concept_guid], :unique => false
    add_foreign_key :roles, :object_types, :column => :object_type_id, :primary_key => :object_type_id, :on_delete => :cascade
    add_index :roles, [:object_type_id], :unique => false
    add_foreign_key :roles, :roles, :column => :role_proxy_role_id, :primary_key => :role_id, :on_delete => :cascade
    add_foreign_key :role_displays, :roles, :column => :role_id, :primary_key => :role_id, :on_delete => :cascade
    add_index :role_displays, [:role_id], :unique => false
    add_foreign_key :role_displays, :shapes, :column => :fact_type_shape_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :role_displays, [:fact_type_shape_guid], :unique => false
    add_foreign_key :role_refs, :plays, :column => :play_id, :primary_key => :play_id, :on_delete => :cascade
    add_foreign_key :role_refs, :roles, :column => :role_id, :primary_key => :role_id, :on_delete => :cascade
    add_index :role_refs, [:role_id], :unique => false
    add_foreign_key :role_refs, :role_sequences, :column => :role_sequence_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :role_refs, [:role_sequence_guid], :unique => false
    add_foreign_key :role_values, :concepts, :column => :fact_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :role_values, [:fact_concept_guid], :unique => false
    add_foreign_key :role_values, :concepts, :column => :instance_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :role_values, [:instance_concept_guid], :unique => false
    add_foreign_key :role_values, :populations, :column => :population_id, :primary_key => :population_id, :on_delete => :cascade
    add_index :role_values, [:population_id], :unique => false
    add_foreign_key :role_values, :roles, :column => :role_id, :primary_key => :role_id, :on_delete => :cascade
    add_index :role_values, [:role_id], :unique => false
    add_foreign_key :set_comparison_roles, :concepts, :column => :set_comparison_constraint_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :set_comparison_roles, [:set_comparison_constraint_concept_guid], :unique => false
    add_foreign_key :set_comparison_roles, :role_sequences, :column => :role_sequence_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :set_comparison_roles, [:role_sequence_guid], :unique => false
    add_foreign_key :shapes, :concepts, :column => :constraint_shape_constraint_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :shapes, [:constraint_shape_constraint_concept_guid], :unique => false
    add_foreign_key :shapes, :concepts, :column => :model_note_shape_context_note_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :shapes, [:model_note_shape_context_note_concept_guid], :unique => false
    add_foreign_key :shapes, :diagrams, :column => :orm_diagram_id, :primary_key => :diagram_id, :on_delete => :cascade
    add_index :shapes, [:orm_diagram_id], :unique => false
    add_foreign_key :shapes, :fact_types, :column => :fact_type_shape_fact_type_concept_guid, :primary_key => :concept_guid, :on_delete => :cascade
    add_index :shapes, [:fact_type_shape_fact_type_concept_guid], :unique => false
    add_foreign_key :shapes, :object_types, :column => :object_type_shape_object_type_id, :primary_key => :object_type_id, :on_delete => :cascade
    add_index :shapes, [:object_type_shape_object_type_id], :unique => false
    add_foreign_key :shapes, :readings, :column => :reading_shape_reading_id, :primary_key => :reading_id, :on_delete => :cascade
    add_index :shapes, [:reading_shape_reading_id], :unique => false
    add_foreign_key :shapes, :role_displays, :column => :value_constraint_shape_role_display_id, :primary_key => :role_display_id, :on_delete => :cascade
    add_foreign_key :shapes, :role_displays, :column => :role_name_shape_role_display_id, :primary_key => :role_display_id, :on_delete => :cascade
    add_foreign_key :shapes, :shapes, :column => :ring_constraint_shape_fact_type_shape_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :shapes, [:ring_constraint_shape_fact_type_shape_guid], :unique => false
    add_foreign_key :shapes, :shapes, :column => :value_constraint_shape_object_type_shape_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :shapes, [:value_constraint_shape_object_type_shape_guid], :unique => false
    add_foreign_key :shapes, :shapes, :column => :objectified_fact_type_name_shape_fact_type_shape_guid, :primary_key => :guid, :on_delete => :cascade
    add_foreign_key :shapes, :shapes, :column => :reading_shape_fact_type_shape_guid, :primary_key => :guid, :on_delete => :cascade
    add_foreign_key :steps, :alternative_sets, :column => :alternative_set_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :steps, [:alternative_set_guid], :unique => false
    add_foreign_key :steps, :fact_types, :column => :fact_type_concept_guid, :primary_key => :concept_guid, :on_delete => :cascade
    add_index :steps, [:fact_type_concept_guid], :unique => false
    add_foreign_key :steps, :plays, :column => :input_play_id, :primary_key => :play_id, :on_delete => :cascade
    add_index :steps, [:input_play_id], :unique => false
    add_foreign_key :steps, :plays, :column => :output_play_id, :primary_key => :play_id, :on_delete => :cascade
    add_index :steps, [:output_play_id], :unique => false
    add_foreign_key :values, :concepts, :column => :unit_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :values, [:unit_concept_guid], :unique => false
    add_foreign_key :values, :object_types, :column => :value_type_object_type_id, :primary_key => :object_type_id, :on_delete => :cascade
    add_index :values, [:value_type_object_type_id], :unique => false
    add_foreign_key :variables, :concepts, :column => :query_concept_guid, :primary_key => :guid, :on_delete => :cascade
    add_index :variables, [:query_concept_guid], :unique => false
    add_foreign_key :variables, :object_types, :column => :object_type_id, :primary_key => :object_type_id, :on_delete => :cascade
    add_index :variables, [:object_type_id], :unique => false
    add_foreign_key :variables, :roles, :column => :projection_id, :primary_key => :role_id, :on_delete => :cascade
    add_foreign_key :variables, :values, :column => :value_id, :primary_key => :value_id, :on_delete => :cascade
    add_index :variables, [:value_id], :unique => false
  end
end
