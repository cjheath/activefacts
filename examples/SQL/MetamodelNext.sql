CREATE TABLE AllowedRange (
	-- Allowed Range is where Value Constraint allows Value Range and Constraint is a kind of Concept and Concept has GUID,
	ValueConstraintGUID                     varchar NOT NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound is inclusive,
	ValueRangeMaximumBoundIsInclusive       bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and Value is a string,
	ValueRangeMaximumBoundValueIsAString    bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMaximumBoundValueLiteral      varchar NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and maybe Value is in Unit and Unit has Unit Id,
	ValueRangeMaximumBoundValueUnitId       int NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound is inclusive,
	ValueRangeMinimumBoundIsInclusive       bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and Value is a string,
	ValueRangeMinimumBoundValueIsAString    bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMinimumBoundValueLiteral      varchar NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and maybe Value is in Unit and Unit has Unit Id,
	ValueRangeMinimumBoundValueUnitId       int NULL,
	UNIQUE(ValueConstraintGUID, ValueRangeMinimumBoundValueLiteral, ValueRangeMinimumBoundValueIsAString, ValueRangeMinimumBoundValueUnitId, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValueLiteral, ValueRangeMaximumBoundValueIsAString, ValueRangeMaximumBoundValueUnitId, ValueRangeMaximumBoundIsInclusive)
)
GO

CREATE TABLE [Constraint] (
	-- Constraint is a kind of Concept and Concept has GUID,
	ConceptGUID                             varchar NOT NULL,
	-- maybe Constraint requires Enforcement and maybe Enforcement notifies Agent and Agent has Agent Name,
	EnforcementAgentName                    varchar NULL,
	-- maybe Constraint requires Enforcement and Enforcement has Enforcement Code,
	EnforcementCode                         varchar(16) NULL,
	-- maybe Name is of Constraint,
	Name                                    varchar(64) NULL,
	-- maybe Presence Constraint is a kind of Constraint and Presence Constraint is mandatory,
	PresenceConstraintIsMandatory           bit NULL,
	-- maybe Presence Constraint is a kind of Constraint and Presence Constraint is preferred identifier,
	PresenceConstraintIsPreferredIdentifier bit NULL,
	-- maybe Presence Constraint is a kind of Constraint and maybe Presence Constraint has max-Frequency,
	PresenceConstraintMaxFrequency          int NULL CHECK(PresenceConstraintMaxFrequency >= 1),
	-- maybe Presence Constraint is a kind of Constraint and maybe Presence Constraint has min-Frequency,
	PresenceConstraintMinFrequency          int NULL CHECK(PresenceConstraintMinFrequency >= 2),
	-- maybe Presence Constraint is a kind of Constraint and Presence Constraint covers Role Sequence and Role Sequence has Role Sequence Id,
	PresenceConstraintRoleSequenceId        int NULL,
	-- maybe Ring Constraint is a kind of Constraint and maybe Ring Constraint has other-Role and Role is a kind of Concept and Concept has GUID,
	RingConstraintOtherRoleGUID             varchar NULL,
	-- maybe Ring Constraint is a kind of Constraint and Ring Constraint is of Ring Type,
	RingConstraintRingType                  varchar NULL,
	-- maybe Ring Constraint is a kind of Constraint and maybe Role is of Ring Constraint and Role is a kind of Concept and Concept has GUID,
	RingConstraintRoleGUID                  varchar NULL,
	-- maybe Set Constraint is a kind of Constraint and maybe Set Comparison Constraint is a kind of Set Constraint and maybe Set Exclusion Constraint is a kind of Set Comparison Constraint and Set Exclusion Constraint is mandatory,
	SetExclusionConstraintIsMandatory       bit NULL,
	-- maybe Set Constraint is a kind of Constraint and maybe Subset Constraint is a kind of Set Constraint and Subset Constraint covers subset-Role Sequence and Role Sequence has Role Sequence Id,
	SubsetConstraintSubsetRoleSequenceId    int NULL,
	-- maybe Set Constraint is a kind of Constraint and maybe Subset Constraint is a kind of Set Constraint and Subset Constraint covers superset-Role Sequence and Role Sequence has Role Sequence Id,
	SubsetConstraintSupersetRoleSequenceId  int NULL,
	-- maybe Value Constraint is a kind of Constraint and maybe Role has role-Value Constraint and Role is a kind of Concept and Concept has GUID,
	ValueConstraintRoleGUID                 varchar NULL,
	-- maybe Vocabulary contains Constraint and Vocabulary is called Name,
	VocabularyName                          varchar(64) NULL,
	PRIMARY KEY(ConceptGUID)
)
GO

CREATE VIEW dbo.SubsetConstraintInConstraint_SubsetConstraintSubsetRoleSequenceIdSubsetConstraintSupersetRoleSequenceId (SubsetConstraintSubsetRoleSequenceId, SubsetConstraintSupersetRoleSequenceId) WITH SCHEMABINDING AS
	SELECT SubsetConstraintSubsetRoleSequenceId, SubsetConstraintSupersetRoleSequenceId FROM dbo.[Constraint]
	WHERE	SubsetConstraintSubsetRoleSequenceId IS NOT NULL
	  AND	SubsetConstraintSupersetRoleSequenceId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_SubsetConstraintInConstraintBySubsetConstraintSubsetRoleSequenceIdSubsetConstraintSupersetRoleSequenceId ON dbo.SubsetConstraintInConstraint_SubsetConstraintSubsetRoleSequenceIdSubsetConstraintSupersetRoleSequenceId(SubsetConstraintSubsetRoleSequenceId, SubsetConstraintSupersetRoleSequenceId)
GO

CREATE VIEW dbo.ValueConstraintInConstraint_ValueConstraintRoleGUID (ValueConstraintRoleGUID) WITH SCHEMABINDING AS
	SELECT ValueConstraintRoleGUID FROM dbo.[Constraint]
	WHERE	ValueConstraintRoleGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX RoleHasOneRoleValueConstraint ON dbo.ValueConstraintInConstraint_ValueConstraintRoleGUID(ValueConstraintRoleGUID)
GO

CREATE VIEW dbo.Constraint_VocabularyNameName (VocabularyName, Name) WITH SCHEMABINDING AS
	SELECT VocabularyName, Name FROM dbo.[Constraint]
	WHERE	VocabularyName IS NOT NULL
	  AND	Name IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ConstraintByVocabularyNameName ON dbo.Constraint_VocabularyNameName(VocabularyName, Name)
GO

CREATE TABLE ContextAccordingTo (
	-- Context According To is where Context Note is according to Agent and Agent has Agent Name,
	AgentName                               varchar NOT NULL,
	-- Context According To is where Context Note is according to Agent and Context Note has Context Note Id,
	ContextNoteId                           int NOT NULL,
	-- maybe Context According To was lodged on Date,
	Date                                    datetime NULL,
	PRIMARY KEY(ContextNoteId, AgentName)
)
GO

CREATE TABLE ContextAgreedBy (
	-- Context Agreed By is where Agreement was reached by Agent and Agent has Agent Name,
	AgentName                               varchar NOT NULL,
	-- Context Agreed By is where Agreement was reached by Agent and Context Note has Context Note Id,
	AgreementContextNoteId                  int NOT NULL,
	PRIMARY KEY(AgreementContextNoteId, AgentName)
)
GO

CREATE TABLE ContextNote (
	-- maybe Context Note was added by Agreement and maybe Agreement was on Date,
	AgreementDate                           datetime NULL,
	-- maybe Concept has Context Note and Concept has GUID,
	ConceptGUID                             varchar NULL,
	-- Context Note has Context Note Id,
	ContextNoteId                           int IDENTITY NOT NULL,
	-- Context Note has Context Note Kind,
	ContextNoteKind                         varchar NOT NULL CHECK(ContextNoteKind = 'as_opposed_to' OR ContextNoteKind = 'because' OR ContextNoteKind = 'so_that' OR ContextNoteKind = 'to_avoid'),
	-- Context Note has Discussion,
	Discussion                              varchar NOT NULL,
	PRIMARY KEY(ContextNoteId)
)
GO

CREATE TABLE Derivation (
	-- Derivation is where Unit (as Derived Unit) is derived from base-Unit (as Base Unit) and Unit has Unit Id,
	BaseUnitId                              int NOT NULL,
	-- Derivation is where Unit (as Derived Unit) is derived from base-Unit (as Base Unit) and Unit has Unit Id,
	DerivedUnitId                           int NOT NULL,
	-- maybe Derivation has Exponent,
	Exponent                                shortint NULL,
	PRIMARY KEY(DerivedUnitId, BaseUnitId)
)
GO

CREATE TABLE Fact (
	-- Fact has Fact Id,
	FactId                                  int IDENTITY NOT NULL,
	-- Fact is of Fact Type and Fact Type is a kind of Concept and Concept has GUID,
	FactTypeGUID                            varchar NOT NULL,
	-- Population includes Fact and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Fact and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	PRIMARY KEY(FactId)
)
GO

CREATE TABLE FactType (
	-- Fact Type is a kind of Concept and Concept has GUID,
	ConceptGUID                             varchar NOT NULL,
	-- maybe Entity Type nests Fact Type and Object Type is a kind of Concept and Concept has GUID,
	EntityTypeGUID                          varchar NULL,
	-- maybe Type Inheritance implies Fact Type and maybe Assimilation applies to Type Inheritance,
	TypeInheritanceAssimilation             varchar NULL CHECK(TypeInheritanceAssimilation = 'partitioned' OR TypeInheritanceAssimilation = 'separate'),
	-- maybe Type Inheritance implies Fact Type and Type Inheritance provides identification,
	TypeInheritanceProvidesIdentification   bit NULL,
	-- maybe Type Inheritance implies Fact Type and Type Inheritance is where Entity Type (as Subtype) is subtype of super-Entity Type (as Supertype) and Object Type is a kind of Concept and Concept has GUID,
	TypeInheritanceSubtypeGUID              varchar NULL,
	-- maybe Type Inheritance implies Fact Type and Type Inheritance is where Entity Type (as Subtype) is subtype of super-Entity Type (as Supertype) and Object Type is a kind of Concept and Concept has GUID,
	TypeInheritanceSupertypeGUID            varchar NULL,
	PRIMARY KEY(ConceptGUID)
)
GO

CREATE VIEW dbo.FactType_EntityTypeGUID (EntityTypeGUID) WITH SCHEMABINDING AS
	SELECT EntityTypeGUID FROM dbo.FactType
	WHERE	EntityTypeGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX EntityTypeNestsOneFactType ON dbo.FactType_EntityTypeGUID(EntityTypeGUID)
GO

CREATE VIEW dbo.FactType_TypeInheritanceSubtypeGUIDTypeInheritanceSupertypeGUIDTypeInheritanceAssimilationTypeInheritanceProvidesIdentif (TypeInheritanceSubtypeGUID, TypeInheritanceSupertypeGUID, TypeInheritanceAssimilation, TypeInheritanceProvidesIdentification) WITH SCHEMABINDING AS
	SELECT TypeInheritanceSubtypeGUID, TypeInheritanceSupertypeGUID, TypeInheritanceAssimilation, TypeInheritanceProvidesIdentification FROM dbo.FactType
	WHERE	TypeInheritanceSubtypeGUID IS NOT NULL
	  AND	TypeInheritanceSupertypeGUID IS NOT NULL
	  AND	TypeInheritanceAssimilation IS NOT NULL
	  AND	TypeInheritanceProvidesIdentification IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_FactTypeByTypeInheritanceSubtypeGUIDTypeInheritanceSupertypeGUIDTypeInheritanceAssimilationTypeInheritanceProvidesIde ON dbo.FactType_TypeInheritanceSubtypeGUIDTypeInheritanceSupertypeGUIDTypeInheritanceAssimilationTypeInheritanceProvidesIdentif(TypeInheritanceSubtypeGUID, TypeInheritanceSupertypeGUID, TypeInheritanceAssimilation, TypeInheritanceProvidesIdentification)
GO

CREATE TABLE Instance (
	-- maybe Instance objectifies Fact and Fact has Fact Id,
	FactId                                  int NULL,
	-- Instance has Instance Id,
	InstanceId                              int IDENTITY NOT NULL,
	-- Instance is of Object Type and Object Type is a kind of Concept and Concept has GUID,
	ObjectTypeGUID                          varchar NOT NULL,
	-- Population includes Instance and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Instance and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	-- maybe Instance has Value and Value is a string,
	ValueIsAString                          bit NULL,
	-- maybe Instance has Value and Value is represented by Literal,
	ValueLiteral                            varchar NULL,
	-- maybe Instance has Value and maybe Value is in Unit and Unit has Unit Id,
	ValueUnitId                             int NULL,
	PRIMARY KEY(InstanceId),
	FOREIGN KEY (FactId) REFERENCES Fact (FactId)
)
GO

CREATE VIEW dbo.Instance_FactId (FactId) WITH SCHEMABINDING AS
	SELECT FactId FROM dbo.Instance
	WHERE	FactId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_InstanceByFactId ON dbo.Instance_FactId(FactId)
GO

CREATE TABLE JoinNode (
	-- Join includes Join Node and Join has Join Id,
	JoinId                                  int NOT NULL,
	-- Join Node is for Object Type and Object Type is a kind of Concept and Concept has GUID,
	ObjectTypeGUID                          varchar NOT NULL,
	-- Join Node has Ordinal position,
	Ordinal                                 shortint NOT NULL,
	-- maybe Join Node has Subscript,
	Subscript                               shortint NULL,
	-- maybe Join Node has Value and Value is a string,
	ValueIsAString                          bit NULL,
	-- maybe Join Node has Value and Value is represented by Literal,
	ValueLiteral                            varchar NULL,
	-- maybe Join Node has Value and maybe Value is in Unit and Unit has Unit Id,
	ValueUnitId                             int NULL,
	PRIMARY KEY(JoinId, Ordinal)
)
GO

CREATE TABLE JoinRole (
	-- Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id,
	JoinNodeJoinId                          int NOT NULL,
	-- Join Role is where Join Node includes Role and Join Node has Ordinal position,
	JoinNodeOrdinal                         shortint NOT NULL,
	-- Join Role is where Join Node includes Role and Role is a kind of Concept and Concept has GUID,
	RoleGUID                                varchar NOT NULL,
	-- maybe Join Role projects Role Ref and Role Ref is where Role Sequence in Ordinal position includes Role,
	RoleRefOrdinal                          shortint NULL,
	-- maybe Join Role projects Role Ref and Role Ref is where Role Sequence in Ordinal position includes Role and Role Sequence has Role Sequence Id,
	RoleRefRoleSequenceId                   int NULL,
	PRIMARY KEY(JoinNodeJoinId, JoinNodeOrdinal, RoleGUID),
	FOREIGN KEY (JoinNodeJoinId, JoinNodeOrdinal) REFERENCES JoinNode (JoinId, Ordinal)
)
GO

CREATE VIEW dbo.JoinRole_RoleRefRoleSequenceIdRoleRefOrdinal (RoleRefRoleSequenceId, RoleRefOrdinal) WITH SCHEMABINDING AS
	SELECT RoleRefRoleSequenceId, RoleRefOrdinal FROM dbo.JoinRole
	WHERE	RoleRefRoleSequenceId IS NOT NULL
	  AND	RoleRefOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_JoinRoleByRoleRefRoleSequenceIdRoleRefOrdinal ON dbo.JoinRole_RoleRefRoleSequenceIdRoleRefOrdinal(RoleRefRoleSequenceId, RoleRefOrdinal)
GO

CREATE TABLE JoinStep (
	-- Join Step traverses Fact Type and Fact Type is a kind of Concept and Concept has GUID,
	FactTypeGUID                            varchar NOT NULL,
	-- Join Step has input-Join Role and Join Role is where Join Node includes Role and Role is a kind of Concept and Concept has GUID,
	InputJoinRoleGUID                       varchar NOT NULL,
	-- Join Step has input-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id,
	InputJoinRoleJoinNodeJoinId             int NOT NULL,
	-- Join Step has input-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position,
	InputJoinRoleJoinNodeOrdinal            shortint NOT NULL,
	-- is anti Join Step,
	IsAnti                                  bit NOT NULL,
	-- Join Step is outer,
	IsOuter                                 bit NOT NULL,
	-- Join Step has output-Join Role and Join Role is where Join Node includes Role and Role is a kind of Concept and Concept has GUID,
	OutputJoinRoleGUID                      varchar NOT NULL,
	-- Join Step has output-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id,
	OutputJoinRoleJoinNodeJoinId            int NOT NULL,
	-- Join Step has output-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position,
	OutputJoinRoleJoinNodeOrdinal           shortint NOT NULL,
	PRIMARY KEY(InputJoinRoleJoinNodeJoinId, InputJoinRoleJoinNodeOrdinal, InputJoinRoleGUID, OutputJoinRoleJoinNodeJoinId, OutputJoinRoleJoinNodeOrdinal, OutputJoinRoleGUID),
	FOREIGN KEY (FactTypeGUID) REFERENCES FactType (ConceptGUID),
	FOREIGN KEY (InputJoinRoleJoinNodeJoinId, InputJoinRoleJoinNodeOrdinal, InputJoinRoleGUID) REFERENCES JoinRole (JoinNodeJoinId, JoinNodeOrdinal, RoleGUID),
	FOREIGN KEY (OutputJoinRoleJoinNodeJoinId, OutputJoinRoleJoinNodeOrdinal, OutputJoinRoleGUID) REFERENCES JoinRole (JoinNodeJoinId, JoinNodeOrdinal, RoleGUID)
)
GO

CREATE TABLE ObjectType (
	-- Object Type is a kind of Concept and Concept has GUID,
	ConceptGUID                             varchar NOT NULL,
	-- Object Type is independent,
	IsIndependent                           bit NOT NULL,
	-- maybe Object Type uses Pronoun,
	Pronoun                                 varchar(20) NULL CHECK(Pronoun = 'feminine' OR Pronoun = 'masculine' OR Pronoun = 'neuter' OR Pronoun = 'personal'),
	-- maybe Value Type is a kind of Object Type and maybe Value Type has Length,
	ValueTypeLength                         int NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type has Scale,
	ValueTypeScale                          int NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type is subtype of super-Value Type (as Supertype) and Object Type is a kind of Concept and Concept has GUID,
	ValueTypeSupertypeGUID                  varchar NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type is of Unit and Unit has Unit Id,
	ValueTypeUnitId                         int NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type has Value Constraint and Constraint is a kind of Concept and Concept has GUID,
	ValueTypeValueConstraintGUID            varchar NULL,
	PRIMARY KEY(ConceptGUID),
	FOREIGN KEY (ValueTypeValueConstraintGUID) REFERENCES [Constraint] (ConceptGUID),
	FOREIGN KEY (ValueTypeSupertypeGUID) REFERENCES ObjectType (ConceptGUID)
)
GO

CREATE VIEW dbo.ValueTypeInObjectType_ValueTypeValueConstraintGUID (ValueTypeValueConstraintGUID) WITH SCHEMABINDING AS
	SELECT ValueTypeValueConstraintGUID FROM dbo.ObjectType
	WHERE	ValueTypeValueConstraintGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueTypeInObjectTypeByValueTypeValueConstraintGUID ON dbo.ValueTypeInObjectType_ValueTypeValueConstraintGUID(ValueTypeValueConstraintGUID)
GO

CREATE TABLE ParamValue (
	-- Param Value is where Value for Parameter applies to Value Type and Parameter is where Name is a parameter of Value Type,
	ParameterName                           varchar(64) NOT NULL,
	-- Param Value is where Value for Parameter applies to Value Type and Parameter is where Name is a parameter of Value Type and Object Type is a kind of Concept and Concept has GUID,
	ParameterValueTypeGUID                  varchar NOT NULL,
	-- Param Value is where Value for Parameter applies to Value Type and Value is a string,
	ValueIsAString                          bit NOT NULL,
	-- Param Value is where Value for Parameter applies to Value Type and Value is represented by Literal,
	ValueLiteral                            varchar NOT NULL,
	-- Param Value is where Value for Parameter applies to Value Type and Object Type is a kind of Concept and Concept has GUID,
	ValueTypeGUID                           varchar NOT NULL,
	-- Param Value is where Value for Parameter applies to Value Type and maybe Value is in Unit and Unit has Unit Id,
	ValueUnitId                             int NULL,
	UNIQUE(ValueLiteral, ValueIsAString, ValueUnitId, ParameterName, ParameterValueTypeGUID),
	FOREIGN KEY (ValueTypeGUID) REFERENCES ObjectType (ConceptGUID)
)
GO

CREATE TABLE Reading (
	-- Fact Type has Reading and Fact Type is a kind of Concept and Concept has GUID,
	FactTypeGUID                            varchar NOT NULL,
	-- Reading is in Ordinal position,
	Ordinal                                 shortint NOT NULL,
	-- Reading is in Role Sequence and Role Sequence has Role Sequence Id,
	RoleSequenceId                          int NOT NULL,
	-- Reading has Text,
	Text                                    varchar(256) NOT NULL,
	PRIMARY KEY(FactTypeGUID, Ordinal),
	FOREIGN KEY (FactTypeGUID) REFERENCES FactType (ConceptGUID)
)
GO

CREATE TABLE Role (
	-- Role is a kind of Concept and Concept has GUID,
	ConceptGUID                             varchar NOT NULL,
	-- Role is where Fact Type has Ordinal role and Fact Type is a kind of Concept and Concept has GUID,
	FactTypeGUID                            varchar NOT NULL,
	-- maybe Implicit Fact Type is implied by Role and Fact Type is a kind of Concept and Concept has GUID,
	ImplicitFactTypeGUID                    varchar NULL,
	-- Object Type plays Role and Object Type is a kind of Concept and Concept has GUID,
	ObjectTypeGUID                          varchar NOT NULL,
	-- Role is where Fact Type has Ordinal role,
	Ordinal                                 shortint NOT NULL,
	PRIMARY KEY(ConceptGUID),
	UNIQUE(FactTypeGUID, Ordinal),
	FOREIGN KEY (ImplicitFactTypeGUID) REFERENCES FactType (ConceptGUID),
	FOREIGN KEY (FactTypeGUID) REFERENCES FactType (ConceptGUID),
	FOREIGN KEY (ObjectTypeGUID) REFERENCES ObjectType (ConceptGUID)
)
GO

CREATE VIEW dbo.Role_ImplicitFactTypeGUID (ImplicitFactTypeGUID) WITH SCHEMABINDING AS
	SELECT ImplicitFactTypeGUID FROM dbo.Role
	WHERE	ImplicitFactTypeGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleByImplicitFactTypeGUID ON dbo.Role_ImplicitFactTypeGUID(ImplicitFactTypeGUID)
GO

CREATE TABLE RoleDisplay (
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Shape Id,
	FactTypeShapeId                         int NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position,
	Ordinal                                 shortint NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Role is a kind of Concept and Concept has GUID,
	RoleGUID                                varchar NOT NULL,
	PRIMARY KEY(FactTypeShapeId, Ordinal),
	FOREIGN KEY (RoleGUID) REFERENCES Role (ConceptGUID)
)
GO

CREATE TABLE RoleRef (
	-- maybe Role Ref has leading-Adjective,
	LeadingAdjective                        varchar(64) NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role,
	Ordinal                                 shortint NOT NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Role is a kind of Concept and Concept has GUID,
	RoleGUID                                varchar NOT NULL,
	-- maybe Term (as Role Name) is name of Role Ref and Term is where Vocabulary contains Name,
	RoleName                                varchar(64) NULL,
	-- maybe Term (as Role Name) is name of Role Ref and Term is where Vocabulary contains Name and Vocabulary is called Name,
	RoleNameVocabularyName                  varchar(64) NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Role Sequence has Role Sequence Id,
	RoleSequenceId                          int NOT NULL,
	-- maybe Role Ref has trailing-Adjective,
	TrailingAdjective                       varchar(64) NULL,
	PRIMARY KEY(RoleSequenceId, Ordinal),
	UNIQUE(RoleGUID, RoleSequenceId),
	FOREIGN KEY (RoleGUID) REFERENCES Role (ConceptGUID)
)
GO

CREATE TABLE RoleSequence (
	-- Role Sequence has unused dependency to force table in norma,
	HasUnusedDependencyToForceTableInNorma  bit NOT NULL,
	-- Role Sequence has Role Sequence Id,
	RoleSequenceId                          int IDENTITY NOT NULL,
	PRIMARY KEY(RoleSequenceId)
)
GO

CREATE TABLE RoleValue (
	-- Role Value fulfils Fact and Fact has Fact Id,
	FactId                                  int NOT NULL,
	-- Instance plays Role Value and Instance has Instance Id,
	InstanceId                              int NOT NULL,
	-- Population includes Role Value and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Role Value and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	-- Role Value is of Role and Role is a kind of Concept and Concept has GUID,
	RoleGUID                                varchar NOT NULL,
	PRIMARY KEY(InstanceId, FactId),
	FOREIGN KEY (FactId) REFERENCES Fact (FactId),
	FOREIGN KEY (InstanceId) REFERENCES Instance (InstanceId),
	FOREIGN KEY (RoleGUID) REFERENCES Role (ConceptGUID)
)
GO

CREATE TABLE SetComparisonRoles (
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence,
	Ordinal                                 shortint NOT NULL,
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence and Role Sequence has Role Sequence Id,
	RoleSequenceId                          int NOT NULL,
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence and Constraint is a kind of Concept and Concept has GUID,
	SetComparisonConstraintGUID             varchar NOT NULL,
	PRIMARY KEY(SetComparisonConstraintGUID, Ordinal),
	UNIQUE(SetComparisonConstraintGUID, RoleSequenceId),
	FOREIGN KEY (SetComparisonConstraintGUID) REFERENCES [Constraint] (ConceptGUID),
	FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
)
GO

CREATE TABLE Shape (
	-- maybe Constraint Shape is a kind of Shape and Constraint Shape is for Constraint and Constraint is a kind of Concept and Concept has GUID,
	ConstraintShapeConstraintGUID           varchar NULL,
	-- Shape is in Diagram and Diagram is called Name,
	DiagramName                             varchar(64) NOT NULL,
	-- Shape is in Diagram and Diagram is for Vocabulary and Vocabulary is called Name,
	DiagramVocabularyName                   varchar(64) NOT NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Display Role Names Setting,
	FactTypeShapeDisplayRoleNamesSetting    varchar NULL CHECK(FactTypeShapeDisplayRoleNamesSetting = 'false' OR FactTypeShapeDisplayRoleNamesSetting = 'true'),
	-- maybe Fact Type Shape is a kind of Shape and Fact Type Shape is for Fact Type and Fact Type is a kind of Concept and Concept has GUID,
	FactTypeShapeFactTypeGUID               varchar NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Reading Shape and Reading Shape is a kind of Shape and Shape has Shape Id,
	FactTypeShapeId                         int NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Objectified Fact Type Name Shape is for Fact Type Shape and Objectified Fact Type Name Shape is a kind of Shape and Shape has Shape Id,
	FactTypeShapeId                         int NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Reading Shape and Reading Shape is for Reading and Fact Type has Reading and Fact Type is a kind of Concept and Concept has GUID,
	FactTypeShapeReadingFactTypeGUID        varchar NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Reading Shape and Reading Shape is for Reading and Reading is in Ordinal position,
	FactTypeShapeReadingOrdinal             shortint NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Rotation Setting,
	FactTypeShapeRotationSetting            varchar NULL CHECK(FactTypeShapeRotationSetting = 'left' OR FactTypeShapeRotationSetting = 'right'),
	-- Shape is expanded,
	IsExpanded                              bit NOT NULL,
	-- maybe Model Note Shape is a kind of Shape and Model Note Shape is for Context Note and Context Note has Context Note Id,
	ModelNoteShapeContextNoteId             int NULL,
	-- maybe Object Type Shape is a kind of Shape and Object Type Shape has expanded reference mode,
	ObjectTypeShapeHasExpandedReferenceMode bit NULL,
	-- maybe Object Type Shape is a kind of Shape and Object Type Shape is for Object Type and Object Type is a kind of Concept and Concept has GUID,
	ObjectTypeShapeObjectTypeGUID           varchar NULL,
	-- maybe Shape is at Position and Position is at X,
	PositionX                               int NULL,
	-- maybe Shape is at Position and Position is at Y,
	PositionY                               int NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Ring Constraint Shape is a kind of Constraint Shape and Ring Constraint Shape is attached to Fact Type and Fact Type is a kind of Concept and Concept has GUID,
	RingConstraintShapeFactTypeGUID         varchar NULL,
	-- maybe Role Name Shape is a kind of Shape and Role Name Shape is for Role Display and Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Shape Id,
	RoleNameShapeRoleDisplayFactTypeShapeId int NULL,
	-- maybe Role Name Shape is a kind of Shape and Role Name Shape is for Role Display and Role Display is where Fact Type Shape displays Role in Ordinal position,
	RoleNameShapeRoleDisplayOrdinal         shortint NULL,
	-- Shape has Shape Id,
	ShapeId                                 int IDENTITY NOT NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Value Constraint Shape is a kind of Constraint Shape and maybe Value Constraint Shape is for Object Type Shape and Shape has Shape Id,
	ValueConstraintShapeObjectTypeShapeId   int NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Value Constraint Shape is a kind of Constraint Shape and maybe Role Display has Value Constraint Shape and Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Shape Id,
	ValueConstraintShapeRoleDisplayFactTypeShapeId int NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Value Constraint Shape is a kind of Constraint Shape and maybe Role Display has Value Constraint Shape and Role Display is where Fact Type Shape displays Role in Ordinal position,
	ValueConstraintShapeRoleDisplayOrdinal  shortint NULL,
	PRIMARY KEY(ShapeId),
	FOREIGN KEY (ConstraintShapeConstraintGUID) REFERENCES [Constraint] (ConceptGUID),
	FOREIGN KEY (ModelNoteShapeContextNoteId) REFERENCES ContextNote (ContextNoteId),
	FOREIGN KEY (RingConstraintShapeFactTypeGUID) REFERENCES FactType (ConceptGUID),
	FOREIGN KEY (FactTypeShapeFactTypeGUID) REFERENCES FactType (ConceptGUID),
	FOREIGN KEY (ObjectTypeShapeObjectTypeGUID) REFERENCES ObjectType (ConceptGUID),
	FOREIGN KEY (FactTypeShapeReadingFactTypeGUID, FactTypeShapeReadingOrdinal) REFERENCES Reading (FactTypeGUID, Ordinal),
	FOREIGN KEY (ValueConstraintShapeRoleDisplayFactTypeShapeId, ValueConstraintShapeRoleDisplayOrdinal) REFERENCES RoleDisplay (FactTypeShapeId, Ordinal),
	FOREIGN KEY (RoleNameShapeRoleDisplayFactTypeShapeId, RoleNameShapeRoleDisplayOrdinal) REFERENCES RoleDisplay (FactTypeShapeId, Ordinal),
	FOREIGN KEY (ValueConstraintShapeObjectTypeShapeId) REFERENCES Shape (ShapeId),
	FOREIGN KEY (FactTypeShapeId) REFERENCES Shape (ShapeId),
	FOREIGN KEY (FactTypeShapeId) REFERENCES Shape (ShapeId)
)
GO

CREATE VIEW dbo.Shape_DiagramVocabularyNameDiagramNamePositionXPositionY (DiagramVocabularyName, DiagramName, PositionX, PositionY) WITH SCHEMABINDING AS
	SELECT DiagramVocabularyName, DiagramName, PositionX, PositionY FROM dbo.Shape
	WHERE	PositionX IS NOT NULL
	  AND	PositionY IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ShapeByDiagramVocabularyNameDiagramNamePositionXPositionY ON dbo.Shape_DiagramVocabularyNameDiagramNamePositionXPositionY(DiagramVocabularyName, DiagramName, PositionX, PositionY)
GO

CREATE VIEW dbo.ObjectifiedFactTypeNameShapeInShape_FactTypeShapeId (FactTypeShapeId) WITH SCHEMABINDING AS
	SELECT FactTypeShapeId FROM dbo.Shape
	WHERE	FactTypeShapeId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ObjectifiedFactTypeNameShapeInShapeByFactTypeShapeId ON dbo.ObjectifiedFactTypeNameShapeInShape_FactTypeShapeId(FactTypeShapeId)
GO

CREATE VIEW dbo.ReadingShapeInShape_FactTypeShapeId (FactTypeShapeId) WITH SCHEMABINDING AS
	SELECT FactTypeShapeId FROM dbo.Shape
	WHERE	FactTypeShapeId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ReadingShapeInShapeByFactTypeShapeId ON dbo.ReadingShapeInShape_FactTypeShapeId(FactTypeShapeId)
GO

CREATE VIEW dbo.RoleNameShapeInShape_RoleNameShapeRoleDisplayFactTypeShapeIdRoleNameShapeRoleDisplayOrdinal (RoleNameShapeRoleDisplayFactTypeShapeId, RoleNameShapeRoleDisplayOrdinal) WITH SCHEMABINDING AS
	SELECT RoleNameShapeRoleDisplayFactTypeShapeId, RoleNameShapeRoleDisplayOrdinal FROM dbo.Shape
	WHERE	RoleNameShapeRoleDisplayFactTypeShapeId IS NOT NULL
	  AND	RoleNameShapeRoleDisplayOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleNameShapeInShapeByRoleNameShapeRoleDisplayFactTypeShapeIdRoleNameShapeRoleDisplayOrdinal ON dbo.RoleNameShapeInShape_RoleNameShapeRoleDisplayFactTypeShapeIdRoleNameShapeRoleDisplayOrdinal(RoleNameShapeRoleDisplayFactTypeShapeId, RoleNameShapeRoleDisplayOrdinal)
GO

CREATE VIEW dbo.ValueConstraintShapeInShape_ValueConstraintShapeRoleDisplayFactTypeShapeIdValueConstraintShapeRoleDisplayOrdinal (ValueConstraintShapeRoleDisplayFactTypeShapeId, ValueConstraintShapeRoleDisplayOrdinal) WITH SCHEMABINDING AS
	SELECT ValueConstraintShapeRoleDisplayFactTypeShapeId, ValueConstraintShapeRoleDisplayOrdinal FROM dbo.Shape
	WHERE	ValueConstraintShapeRoleDisplayFactTypeShapeId IS NOT NULL
	  AND	ValueConstraintShapeRoleDisplayOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueConstraintShapeInShapeByValueConstraintShapeRoleDisplayFactTypeShapeIdValueConstraintShapeRoleDisplayOrdinal ON dbo.ValueConstraintShapeInShape_ValueConstraintShapeRoleDisplayFactTypeShapeIdValueConstraintShapeRoleDisplayOrdinal(ValueConstraintShapeRoleDisplayFactTypeShapeId, ValueConstraintShapeRoleDisplayOrdinal)
GO

CREATE TABLE Term (
	-- Term is where Vocabulary contains Name,
	Name                                    varchar(64) NOT NULL,
	-- maybe Term designates Object Type and Object Type is a kind of Concept and Concept has GUID,
	ObjectTypeGUID                          varchar NULL,
	-- maybe Term is secondary for Object Type (as Secondary) and Object Type is a kind of Concept and Concept has GUID,
	SecondaryGUID                           varchar NULL,
	-- Term is where Vocabulary contains Name and Vocabulary is called Name,
	VocabularyName                          varchar(64) NOT NULL,
	PRIMARY KEY(VocabularyName, Name),
	FOREIGN KEY (ObjectTypeGUID) REFERENCES ObjectType (ConceptGUID),
	FOREIGN KEY (SecondaryGUID) REFERENCES ObjectType (ConceptGUID)
)
GO

CREATE VIEW dbo.Term_ObjectTypeGUID (ObjectTypeGUID) WITH SCHEMABINDING AS
	SELECT ObjectTypeGUID FROM dbo.Term
	WHERE	ObjectTypeGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_TermByObjectTypeGUID ON dbo.Term_ObjectTypeGUID(ObjectTypeGUID)
GO

CREATE TABLE Unit (
	-- maybe Unit has Coefficient and Coefficient has Denominator,
	CoefficientDenominator                  int NULL,
	-- maybe Unit has Coefficient and Coefficient is precise,
	CoefficientIsPrecise                    bit NULL,
	-- maybe Unit has Coefficient and Coefficient has Numerator,
	CoefficientNumerator                    decimal NULL,
	-- maybe Ephemera URL provides Unit coefficient,
	EphemeraURL                             varchar NULL,
	-- Unit is fundamental,
	IsFundamental                           bit NOT NULL,
	-- Name is of Unit,
	Name                                    varchar(64) NOT NULL,
	-- maybe Unit has Offset,
	Offset                                  decimal NULL,
	-- maybe Unit has plural-Name,
	PluralName                              varchar(64) NULL,
	-- Unit has Unit Id,
	UnitId                                  int IDENTITY NOT NULL,
	-- Vocabulary includes Unit and Vocabulary is called Name,
	VocabularyName                          varchar(64) NOT NULL,
	PRIMARY KEY(UnitId),
	UNIQUE(VocabularyName, Name)
)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueConstraintGUID) REFERENCES [Constraint] (ConceptGUID)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (RingConstraintOtherRoleGUID) REFERENCES Role (ConceptGUID)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (RingConstraintRoleGUID) REFERENCES Role (ConceptGUID)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (ValueConstraintRoleGUID) REFERENCES Role (ConceptGUID)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (PresenceConstraintRoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (SubsetConstraintSubsetRoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (SubsetConstraintSupersetRoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
GO

ALTER TABLE ContextAccordingTo
	ADD FOREIGN KEY (ContextNoteId) REFERENCES ContextNote (ContextNoteId)
GO

ALTER TABLE ContextAgreedBy
	ADD FOREIGN KEY (AgreementContextNoteId) REFERENCES ContextNote (ContextNoteId)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (BaseUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (DerivedUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE Fact
	ADD FOREIGN KEY (FactTypeGUID) REFERENCES FactType (ConceptGUID)
GO

ALTER TABLE FactType
	ADD FOREIGN KEY (EntityTypeGUID) REFERENCES ObjectType (ConceptGUID)
GO

ALTER TABLE Instance
	ADD FOREIGN KEY (ObjectTypeGUID) REFERENCES ObjectType (ConceptGUID)
GO

ALTER TABLE JoinNode
	ADD FOREIGN KEY (ObjectTypeGUID) REFERENCES ObjectType (ConceptGUID)
GO

ALTER TABLE JoinRole
	ADD FOREIGN KEY (RoleGUID) REFERENCES Role (ConceptGUID)
GO

ALTER TABLE JoinRole
	ADD FOREIGN KEY (RoleRefOrdinal, RoleRefRoleSequenceId) REFERENCES RoleRef (Ordinal, RoleSequenceId)
GO

ALTER TABLE ObjectType
	ADD FOREIGN KEY (ValueTypeUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE Reading
	ADD FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
GO

ALTER TABLE RoleDisplay
	ADD FOREIGN KEY (FactTypeShapeId) REFERENCES Shape (ShapeId)
GO

ALTER TABLE RoleRef
	ADD FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
GO

ALTER TABLE RoleRef
	ADD FOREIGN KEY (RoleName, RoleNameVocabularyName) REFERENCES Term (Name, VocabularyName)
GO

