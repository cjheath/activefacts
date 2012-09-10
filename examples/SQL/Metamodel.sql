CREATE TABLE AllowedRange (
	-- Allowed Range is where Value Constraint allows Value Range and Constraint has Constraint Id,
	ValueConstraintId                       int NOT NULL,
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
	UNIQUE(ValueConstraintId, ValueRangeMinimumBoundValueLiteral, ValueRangeMinimumBoundValueIsAString, ValueRangeMinimumBoundValueUnitId, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValueLiteral, ValueRangeMaximumBoundValueIsAString, ValueRangeMaximumBoundValueUnitId, ValueRangeMaximumBoundIsInclusive)
)
GO

CREATE TABLE [Constraint] (
	-- Constraint has Constraint Id,
	ConstraintId                            int IDENTITY NOT NULL,
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
	-- maybe Ring Constraint is a kind of Constraint and maybe Ring Constraint has other-Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id,
	RingConstraintOtherRoleFactTypeId       int NULL,
	-- maybe Ring Constraint is a kind of Constraint and maybe Ring Constraint has other-Role and Role is where Fact Type has Ordinal role,
	RingConstraintOtherRoleOrdinal          shortint NULL,
	-- maybe Ring Constraint is a kind of Constraint and Ring Constraint is of Ring Type,
	RingConstraintRingType                  varchar NULL,
	-- maybe Ring Constraint is a kind of Constraint and maybe Role is of Ring Constraint and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id,
	RingConstraintRoleFactTypeId            int NULL,
	-- maybe Ring Constraint is a kind of Constraint and maybe Role is of Ring Constraint and Role is where Fact Type has Ordinal role,
	RingConstraintRoleOrdinal               shortint NULL,
	-- maybe Set Constraint is a kind of Constraint and maybe Set Comparison Constraint is a kind of Set Constraint and maybe Set Exclusion Constraint is a kind of Set Comparison Constraint and Set Exclusion Constraint is mandatory,
	SetExclusionConstraintIsMandatory       bit NULL,
	-- maybe Set Constraint is a kind of Constraint and maybe Subset Constraint is a kind of Set Constraint and Subset Constraint covers subset-Role Sequence and Role Sequence has Role Sequence Id,
	SubsetConstraintSubsetRoleSequenceId    int NULL,
	-- maybe Set Constraint is a kind of Constraint and maybe Subset Constraint is a kind of Set Constraint and Subset Constraint covers superset-Role Sequence and Role Sequence has Role Sequence Id,
	SubsetConstraintSupersetRoleSequenceId  int NULL,
	-- maybe Value Constraint is a kind of Constraint and maybe Role has role-Value Constraint and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id,
	ValueConstraintRoleFactTypeId           int NULL,
	-- maybe Value Constraint is a kind of Constraint and maybe Role has role-Value Constraint and Role is where Fact Type has Ordinal role,
	ValueConstraintRoleOrdinal              shortint NULL,
	-- maybe Vocabulary contains Constraint and Vocabulary is called Name,
	VocabularyName                          varchar(64) NULL,
	PRIMARY KEY(ConstraintId)
)
GO

CREATE VIEW dbo.RingConstraintInConstraint_RingConstraintRoleFactTypeIdRingConstraintRoleOrdinal (RingConstraintRoleFactTypeId, RingConstraintRoleOrdinal) WITH SCHEMABINDING AS
	SELECT RingConstraintRoleFactTypeId, RingConstraintRoleOrdinal FROM dbo.[Constraint]
	WHERE	RingConstraintRoleFactTypeId IS NOT NULL
	  AND	RingConstraintRoleOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PK_RingConstraintInConstraint ON dbo.RingConstraintInConstraint_RingConstraintRoleFactTypeIdRingConstraintRoleOrdinal(RingConstraintRoleFactTypeId, RingConstraintRoleOrdinal)
GO

CREATE VIEW dbo.SubsetConstraintInConstraint_SubsetConstraintSubsetRoleSequenceIdSubsetConstraintSupersetRoleSequenceId (SubsetConstraintSubsetRoleSequenceId, SubsetConstraintSupersetRoleSequenceId) WITH SCHEMABINDING AS
	SELECT SubsetConstraintSubsetRoleSequenceId, SubsetConstraintSupersetRoleSequenceId FROM dbo.[Constraint]
	WHERE	SubsetConstraintSubsetRoleSequenceId IS NOT NULL
	  AND	SubsetConstraintSupersetRoleSequenceId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX SetConstraintMustHaveSupertypeConstraint ON dbo.SubsetConstraintInConstraint_SubsetConstraintSubsetRoleSequenceIdSubsetConstraintSupersetRoleSequenceId(SubsetConstraintSubsetRoleSequenceId, SubsetConstraintSupersetRoleSequenceId)
GO

CREATE VIEW dbo.ValueConstraintInConstraint_ValueConstraintRoleFactTypeIdValueConstraintRoleOrdinal (ValueConstraintRoleFactTypeId, ValueConstraintRoleOrdinal) WITH SCHEMABINDING AS
	SELECT ValueConstraintRoleFactTypeId, ValueConstraintRoleOrdinal FROM dbo.[Constraint]
	WHERE	ValueConstraintRoleFactTypeId IS NOT NULL
	  AND	ValueConstraintRoleOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueConstraintInConstraintByValueConstraintRoleFactTypeIdValueConstraintRoleOrdinal ON dbo.ValueConstraintInConstraint_ValueConstraintRoleFactTypeIdValueConstraintRoleOrdinal(ValueConstraintRoleFactTypeId, ValueConstraintRoleOrdinal)
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
	-- maybe Constraint has Context Note and Constraint has Constraint Id,
	ConstraintId                            int NULL,
	-- Context Note has Context Note Id,
	ContextNoteId                           int IDENTITY NOT NULL,
	-- Context Note has Context Note Kind,
	ContextNoteKind                         varchar NOT NULL CHECK(ContextNoteKind = 'as_opposed_to' OR ContextNoteKind = 'because' OR ContextNoteKind = 'so_that' OR ContextNoteKind = 'to_avoid'),
	-- Context Note has Discussion,
	Discussion                              varchar NOT NULL,
	-- maybe Fact Type has Context Note and Fact Type has Fact Type Id,
	FactTypeId                              int NULL,
	-- maybe Object Type has Context Note and Object Type is called Name,
	ObjectTypeName                          varchar(64) NULL,
	-- maybe Object Type has Context Note and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NULL,
	PRIMARY KEY(ContextNoteId),
	FOREIGN KEY (ConstraintId) REFERENCES [Constraint] (ConstraintId)
)
GO

CREATE TABLE Derivation (
	-- Derivation is where Unit is derived from base-Unit and Unit has Unit Id,
	BaseUnitId                              int NOT NULL,
	-- Derivation is where Unit is derived from base-Unit and Unit has Unit Id,
	DerivedUnitId                           int NOT NULL,
	-- maybe Derivation has Exponent,
	Exponent                                shortint NULL,
	PRIMARY KEY(DerivedUnitId, BaseUnitId)
)
GO

CREATE TABLE FacetValue (
	-- Facet Value is where Value Type defines Facet as having Value and Facet is where Value Type has facet called Name,
	FacetName                               varchar(64) NOT NULL,
	-- Facet Value is where Value Type defines Facet as having Value and Facet is where Value Type has facet called Name and Object Type is called Name,
	FacetValueTypeName                      varchar(64) NOT NULL,
	-- Facet Value is where Value Type defines Facet as having Value and Facet is where Value Type has facet called Name and Object Type belongs to Vocabulary and Vocabulary is called Name,
	FacetValueTypeVocabularyName            varchar(64) NOT NULL,
	-- Facet Value is where Value Type defines Facet as having Value and Value is a string,
	ValueIsAString                          bit NOT NULL,
	-- Facet Value is where Value Type defines Facet as having Value and Value is represented by Literal,
	ValueLiteral                            varchar NOT NULL,
	-- Facet Value is where Value Type defines Facet as having Value and Object Type is called Name,
	ValueTypeName                           varchar(64) NOT NULL,
	-- Facet Value is where Value Type defines Facet as having Value and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeVocabularyName                 varchar(64) NOT NULL,
	-- Facet Value is where Value Type defines Facet as having Value and maybe Value is in Unit and Unit has Unit Id,
	ValueUnitId                             int NULL,
	PRIMARY KEY(ValueTypeVocabularyName, ValueTypeName, FacetValueTypeVocabularyName, FacetValueTypeName, FacetName)
)
GO

CREATE TABLE Fact (
	-- Fact has Fact Id,
	FactId                                  int IDENTITY NOT NULL,
	-- Fact is of Fact Type and Fact Type has Fact Type Id,
	FactTypeId                              int NOT NULL,
	-- Population includes Fact and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Fact and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	PRIMARY KEY(FactId)
)
GO

CREATE TABLE FactType (
	-- maybe Entity Type nests Fact Type and Object Type is called Name,
	EntityTypeName                          varchar(64) NULL,
	-- maybe Entity Type nests Fact Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	EntityTypeVocabularyName                varchar(64) NULL,
	-- Fact Type has Fact Type Id,
	FactTypeId                              int IDENTITY NOT NULL,
	-- maybe Type Inheritance is a kind of Fact Type and maybe Assimilation applies to Type Inheritance,
	TypeInheritanceAssimilation             varchar NULL CHECK(TypeInheritanceAssimilation = 'partitioned' OR TypeInheritanceAssimilation = 'separate'),
	-- maybe Type Inheritance is a kind of Fact Type and Type Inheritance provides identification,
	TypeInheritanceProvidesIdentification   bit NULL,
	-- maybe Type Inheritance is a kind of Fact Type and Type Inheritance is where Entity Type is subtype of super-Entity Type and Object Type is called Name,
	TypeInheritanceSubtypeName              varchar(64) NULL,
	-- maybe Type Inheritance is a kind of Fact Type and Type Inheritance is where Entity Type is subtype of super-Entity Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	TypeInheritanceSubtypeVocabularyName    varchar(64) NULL,
	-- maybe Type Inheritance is a kind of Fact Type and Type Inheritance is where Entity Type is subtype of super-Entity Type and Object Type is called Name,
	TypeInheritanceSupertypeName            varchar(64) NULL,
	-- maybe Type Inheritance is a kind of Fact Type and Type Inheritance is where Entity Type is subtype of super-Entity Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	TypeInheritanceSupertypeVocabularyName  varchar(64) NULL,
	PRIMARY KEY(FactTypeId)
)
GO

CREATE VIEW dbo.FactType_EntityTypeVocabularyNameEntityTypeName (EntityTypeVocabularyName, EntityTypeName) WITH SCHEMABINDING AS
	SELECT EntityTypeVocabularyName, EntityTypeName FROM dbo.FactType
	WHERE	EntityTypeVocabularyName IS NOT NULL
	  AND	EntityTypeName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_FactTypeByEntityTypeVocabularyNameEntityTypeName ON dbo.FactType_EntityTypeVocabularyNameEntityTypeName(EntityTypeVocabularyName, EntityTypeName)
GO

CREATE VIEW dbo.TypeInheritanceInFactType_TypeInheritanceSubtypeVocabularyNameTypeInheritanceSubtypeNameTypeInheritanceProvidesIdentific (TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceProvidesIdentification) WITH SCHEMABINDING AS
	SELECT TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceProvidesIdentification FROM dbo.FactType
	WHERE	TypeInheritanceSubtypeVocabularyName IS NOT NULL
	  AND	TypeInheritanceSubtypeName IS NOT NULL
	  AND	TypeInheritanceProvidesIdentification IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_TypeInheritanceInFactTypeByTypeInheritanceSubtypeVocabularyNameTypeInheritanceSubtypeNameTypeInheritanceProvidesIdent ON dbo.TypeInheritanceInFactType_TypeInheritanceSubtypeVocabularyNameTypeInheritanceSubtypeNameTypeInheritanceProvidesIdentific(TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceProvidesIdentification)
GO

CREATE VIEW dbo.TypeInheritanceInFactType_TypeInheritanceSubtypeVocabularyNameTypeInheritanceSubtypeNameTypeInheritanceSupertypeVocabula (TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceSupertypeVocabularyName, TypeInheritanceSupertypeName) WITH SCHEMABINDING AS
	SELECT TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceSupertypeVocabularyName, TypeInheritanceSupertypeName FROM dbo.FactType
	WHERE	TypeInheritanceSubtypeVocabularyName IS NOT NULL
	  AND	TypeInheritanceSubtypeName IS NOT NULL
	  AND	TypeInheritanceSupertypeVocabularyName IS NOT NULL
	  AND	TypeInheritanceSupertypeName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX TypeInheritanceUQ ON dbo.TypeInheritanceInFactType_TypeInheritanceSubtypeVocabularyNameTypeInheritanceSubtypeNameTypeInheritanceSupertypeVocabula(TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceSupertypeVocabularyName, TypeInheritanceSupertypeName)
GO

CREATE TABLE Instance (
	-- maybe Instance objectifies Fact and Fact has Fact Id,
	FactId                                  int NULL,
	-- Instance has Instance Id,
	InstanceId                              int IDENTITY NOT NULL,
	-- Instance is of Object Type and Object Type is called Name,
	ObjectTypeName                          varchar(64) NOT NULL,
	-- Instance is of Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NOT NULL,
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
	-- Join Node is for Object Type and Object Type is called Name,
	ObjectTypeName                          varchar(64) NOT NULL,
	-- Join Node is for Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NOT NULL,
	-- Join Node has Ordinal position,
	Ordinal                                 shortint NOT NULL,
	-- maybe Join Node has role-Name,
	RoleName                                varchar(64) NULL,
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
	-- maybe Join Step involves incidental-Join Role and Join Step has input-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id,
	JoinStepInputJoinRoleFactTypeId         int NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has input-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id,
	JoinStepInputJoinRoleJoinNodeJoinId     int NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has input-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position,
	JoinStepInputJoinRoleJoinNodeOrdinal    shortint NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has input-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role,
	JoinStepInputJoinRoleOrdinal            shortint NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has output-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id,
	JoinStepOutputJoinRoleFactTypeId        int NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has output-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id,
	JoinStepOutputJoinRoleJoinNodeJoinId    int NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has output-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position,
	JoinStepOutputJoinRoleJoinNodeOrdinal   shortint NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has output-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role,
	JoinStepOutputJoinRoleOrdinal           shortint NULL,
	-- Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id,
	RoleFactTypeId                          int NOT NULL,
	-- Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role,
	RoleOrdinal                             shortint NOT NULL,
	-- maybe Join Role projects Role Ref and Role Ref is where Role Sequence in Ordinal position includes Role,
	RoleRefOrdinal                          shortint NULL,
	-- maybe Join Role projects Role Ref and Role Ref is where Role Sequence in Ordinal position includes Role and Role Sequence has Role Sequence Id,
	RoleRefRoleSequenceId                   int NULL,
	PRIMARY KEY(JoinNodeJoinId, JoinNodeOrdinal, RoleFactTypeId, RoleOrdinal),
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
	-- maybe Join Step falls under Disjunction and Disjunction has Disjunction Id,
	DisjunctionId                           int NULL,
	-- Join Step traverses Fact Type and Fact Type has Fact Type Id,
	FactTypeId                              int NOT NULL,
	-- Join Step has input-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id,
	InputJoinRoleFactTypeId                 int NOT NULL,
	-- Join Step has input-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id,
	InputJoinRoleJoinNodeJoinId             int NOT NULL,
	-- Join Step has input-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position,
	InputJoinRoleJoinNodeOrdinal            shortint NOT NULL,
	-- Join Step has input-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role,
	InputJoinRoleOrdinal                    shortint NOT NULL,
	-- is anti Join Step,
	IsAnti                                  bit NOT NULL,
	-- Join Step is outer,
	IsOuter                                 bit NOT NULL,
	-- Join Step has output-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id,
	OutputJoinRoleFactTypeId                int NOT NULL,
	-- Join Step has output-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has Join Id,
	OutputJoinRoleJoinNodeJoinId            int NOT NULL,
	-- Join Step has output-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position,
	OutputJoinRoleJoinNodeOrdinal           shortint NOT NULL,
	-- Join Step has output-Join Role and Join Role is where Join Node includes Role and Role is where Fact Type has Ordinal role,
	OutputJoinRoleOrdinal                   shortint NOT NULL,
	PRIMARY KEY(InputJoinRoleJoinNodeJoinId, InputJoinRoleJoinNodeOrdinal, InputJoinRoleFactTypeId, InputJoinRoleOrdinal, OutputJoinRoleJoinNodeJoinId, OutputJoinRoleJoinNodeOrdinal, OutputJoinRoleFactTypeId, OutputJoinRoleOrdinal),
	FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId),
	FOREIGN KEY (InputJoinRoleJoinNodeJoinId, InputJoinRoleJoinNodeOrdinal, InputJoinRoleFactTypeId, InputJoinRoleOrdinal) REFERENCES JoinRole (JoinNodeJoinId, JoinNodeOrdinal, RoleFactTypeId, RoleOrdinal),
	FOREIGN KEY (OutputJoinRoleJoinNodeJoinId, OutputJoinRoleJoinNodeOrdinal, OutputJoinRoleFactTypeId, OutputJoinRoleOrdinal) REFERENCES JoinRole (JoinNodeJoinId, JoinNodeOrdinal, RoleFactTypeId, RoleOrdinal)
)
GO

CREATE TABLE ObjectType (
	-- maybe Entity Type is a kind of Object Type and Entity Type is implied by objectification,
	EntityTypeIsImpliedByObjectification    bit NULL,
	-- Object Type is independent,
	IsIndependent                           bit NOT NULL,
	-- Object Type is called Name,
	Name                                    varchar(64) NOT NULL,
	-- maybe Object Type uses Pronoun,
	Pronoun                                 varchar(20) NULL CHECK(Pronoun = 'feminine' OR Pronoun = 'masculine' OR Pronoun = 'neuter' OR Pronoun = 'personal'),
	-- maybe Value Type is a kind of Object Type and maybe Value Type has auto- assigned Transaction Timing,
	ValueTypeAutoAssignedTransactionTiming  varchar NULL CHECK(ValueTypeAutoAssignedTransactionTiming = 'assert' OR ValueTypeAutoAssignedTransactionTiming = 'commit'),
	-- maybe Value Type is a kind of Object Type and maybe Value Type has Length,
	ValueTypeLength                         int NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type has Scale,
	ValueTypeScale                          int NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type is subtype of super-Value Type and Object Type is called Name,
	ValueTypeSupertypeName                  varchar(64) NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type is subtype of super-Value Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeSupertypeVocabularyName        varchar(64) NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type is of Unit and Unit has Unit Id,
	ValueTypeUnitId                         int NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type has Value Constraint and Constraint has Constraint Id,
	ValueTypeValueConstraintId              int NULL,
	-- Object Type belongs to Vocabulary and Vocabulary is called Name,
	VocabularyName                          varchar(64) NOT NULL,
	PRIMARY KEY(VocabularyName, Name),
	FOREIGN KEY (ValueTypeValueConstraintId) REFERENCES [Constraint] (ConstraintId),
	FOREIGN KEY (ValueTypeSupertypeName, ValueTypeSupertypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName)
)
GO

CREATE VIEW dbo.ValueTypeInObjectType_ValueTypeValueConstraintId (ValueTypeValueConstraintId) WITH SCHEMABINDING AS
	SELECT ValueTypeValueConstraintId FROM dbo.ObjectType
	WHERE	ValueTypeValueConstraintId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueTypeInObjectTypeByValueTypeValueConstraintId ON dbo.ValueTypeInObjectType_ValueTypeValueConstraintId(ValueTypeValueConstraintId)
GO

CREATE TABLE Reading (
	-- Fact Type has Reading and Fact Type has Fact Type Id,
	FactTypeId                              int NOT NULL,
	-- Reading is in Ordinal position,
	Ordinal                                 shortint NOT NULL,
	-- Reading is in Role Sequence and Role Sequence has Role Sequence Id,
	RoleSequenceId                          int NOT NULL,
	-- Reading has Text,
	Text                                    varchar(256) NOT NULL,
	PRIMARY KEY(FactTypeId, Ordinal),
	FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId)
)
GO

CREATE TABLE Role (
	-- Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id,
	FactTypeId                              int NOT NULL,
	-- maybe Implicit Fact Type is implied by Role and Fact Type has Fact Type Id,
	ImplicitFactTypeId                      int NULL,
	-- Object Type plays Role and Object Type is called Name,
	ObjectTypeName                          varchar(64) NOT NULL,
	-- Object Type plays Role and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NOT NULL,
	-- Role is where Fact Type has Ordinal role,
	Ordinal                                 shortint NOT NULL,
	-- maybe Role has role-Name,
	RoleName                                varchar(64) NULL,
	PRIMARY KEY(FactTypeId, Ordinal),
	FOREIGN KEY (ImplicitFactTypeId) REFERENCES FactType (FactTypeId),
	FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId),
	FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName)
)
GO

CREATE VIEW dbo.Role_ImplicitFactTypeId (ImplicitFactTypeId) WITH SCHEMABINDING AS
	SELECT ImplicitFactTypeId FROM dbo.Role
	WHERE	ImplicitFactTypeId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleByImplicitFactTypeId ON dbo.Role_ImplicitFactTypeId(ImplicitFactTypeId)
GO

CREATE TABLE RoleDisplay (
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Shape Id,
	FactTypeShapeId                         int NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position,
	Ordinal                                 shortint NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id,
	RoleFactTypeId                          int NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Role is where Fact Type has Ordinal role,
	RoleOrdinal                             shortint NOT NULL,
	PRIMARY KEY(FactTypeShapeId, Ordinal),
	FOREIGN KEY (RoleFactTypeId, RoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
)
GO

CREATE TABLE RoleRef (
	-- maybe Role Ref has leading-Adjective,
	LeadingAdjective                        varchar(64) NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role,
	Ordinal                                 shortint NOT NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id,
	RoleFactTypeId                          int NOT NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Role is where Fact Type has Ordinal role,
	RoleOrdinal                             shortint NOT NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Role Sequence has Role Sequence Id,
	RoleSequenceId                          int NOT NULL,
	-- maybe Role Ref has trailing-Adjective,
	TrailingAdjective                       varchar(64) NULL,
	PRIMARY KEY(RoleSequenceId, Ordinal),
	UNIQUE(RoleFactTypeId, RoleOrdinal, RoleSequenceId),
	FOREIGN KEY (RoleFactTypeId, RoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
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
	-- Role Value is of Role and Role is where Fact Type has Ordinal role and Fact Type has Fact Type Id,
	RoleFactTypeId                          int NOT NULL,
	-- Role Value is of Role and Role is where Fact Type has Ordinal role,
	RoleOrdinal                             shortint NOT NULL,
	PRIMARY KEY(InstanceId, FactId),
	FOREIGN KEY (FactId) REFERENCES Fact (FactId),
	FOREIGN KEY (InstanceId) REFERENCES Instance (InstanceId),
	FOREIGN KEY (RoleFactTypeId, RoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
)
GO

CREATE TABLE SetComparisonRoles (
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence,
	Ordinal                                 shortint NOT NULL,
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence and Role Sequence has Role Sequence Id,
	RoleSequenceId                          int NOT NULL,
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence and Constraint has Constraint Id,
	SetComparisonConstraintId               int NOT NULL,
	PRIMARY KEY(SetComparisonConstraintId, Ordinal),
	UNIQUE(SetComparisonConstraintId, RoleSequenceId),
	FOREIGN KEY (SetComparisonConstraintId) REFERENCES [Constraint] (ConstraintId),
	FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
)
GO

CREATE TABLE Shape (
	-- maybe Constraint Shape is a kind of Shape and Constraint Shape is for Constraint and Constraint has Constraint Id,
	ConstraintShapeConstraintId             int NULL,
	-- Shape is in Diagram and Diagram is called Name,
	DiagramName                             varchar(64) NOT NULL,
	-- Shape is in Diagram and Diagram is for Vocabulary and Vocabulary is called Name,
	DiagramVocabularyName                   varchar(64) NOT NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Display Role Names Setting,
	FactTypeShapeDisplayRoleNamesSetting    varchar NULL CHECK(FactTypeShapeDisplayRoleNamesSetting = 'false' OR FactTypeShapeDisplayRoleNamesSetting = 'true'),
	-- maybe Fact Type Shape is a kind of Shape and Fact Type Shape is for Fact Type and Fact Type has Fact Type Id,
	FactTypeShapeFactTypeId                 int NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Reading Shape and Reading Shape is a kind of Shape and Shape has Shape Id,
	FactTypeShapeId                         int NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Objectified Fact Type Name Shape is for Fact Type Shape and Objectified Fact Type Name Shape is a kind of Shape and Shape has Shape Id,
	FactTypeShapeId                         int NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Reading Shape and Reading Shape is for Reading and Fact Type has Reading and Fact Type has Fact Type Id,
	FactTypeShapeReadingFactTypeId          int NULL,
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
	-- maybe Object Type Shape is a kind of Shape and Object Type Shape is for Object Type and Object Type is called Name,
	ObjectTypeShapeObjectTypeName           varchar(64) NULL,
	-- maybe Object Type Shape is a kind of Shape and Object Type Shape is for Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ObjectTypeShapeObjectTypeVocabularyName varchar(64) NULL,
	-- maybe Shape is at Position and Position is at X,
	PositionX                               int NULL,
	-- maybe Shape is at Position and Position is at Y,
	PositionY                               int NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Ring Constraint Shape is a kind of Constraint Shape and Ring Constraint Shape is attached to Fact Type and Fact Type has Fact Type Id,
	RingConstraintShapeFactTypeId           int NULL,
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
	FOREIGN KEY (ConstraintShapeConstraintId) REFERENCES [Constraint] (ConstraintId),
	FOREIGN KEY (ModelNoteShapeContextNoteId) REFERENCES ContextNote (ContextNoteId),
	FOREIGN KEY (RingConstraintShapeFactTypeId) REFERENCES FactType (FactTypeId),
	FOREIGN KEY (FactTypeShapeFactTypeId) REFERENCES FactType (FactTypeId),
	FOREIGN KEY (ObjectTypeShapeObjectTypeName, ObjectTypeShapeObjectTypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName),
	FOREIGN KEY (FactTypeShapeReadingFactTypeId, FactTypeShapeReadingOrdinal) REFERENCES Reading (FactTypeId, Ordinal),
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

CREATE UNIQUE CLUSTERED INDEX ShapeMayBeAObjectifiedFactTypeNameShape ON dbo.ObjectifiedFactTypeNameShapeInShape_FactTypeShapeId(FactTypeShapeId)
GO

CREATE VIEW dbo.ReadingShapeInShape_FactTypeShapeId (FactTypeShapeId) WITH SCHEMABINDING AS
	SELECT FactTypeShapeId FROM dbo.Shape
	WHERE	FactTypeShapeId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX ShapeMayBeAReadingShape ON dbo.ReadingShapeInShape_FactTypeShapeId(FactTypeShapeId)
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
	UNIQUE(Name),
	UNIQUE(VocabularyName, Name)
)
GO

CREATE VIEW dbo.Unit_PluralName (PluralName) WITH SCHEMABINDING AS
	SELECT PluralName FROM dbo.Unit
	WHERE	PluralName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_UnitByPluralName ON dbo.Unit_PluralName(PluralName)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueConstraintId) REFERENCES [Constraint] (ConstraintId)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (RingConstraintOtherRoleFactTypeId, RingConstraintOtherRoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (RingConstraintRoleFactTypeId, RingConstraintRoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (ValueConstraintRoleFactTypeId, ValueConstraintRoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
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

ALTER TABLE ContextNote
	ADD FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId)
GO

ALTER TABLE ContextNote
	ADD FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (BaseUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (DerivedUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE FacetValue
	ADD FOREIGN KEY (ValueTypeName, ValueTypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName)
GO

ALTER TABLE Fact
	ADD FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId)
GO

ALTER TABLE FactType
	ADD FOREIGN KEY (EntityTypeName, EntityTypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName)
GO

ALTER TABLE FactType
	ADD FOREIGN KEY (TypeInheritanceSubtypeName, TypeInheritanceSubtypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName)
GO

ALTER TABLE FactType
	ADD FOREIGN KEY (TypeInheritanceSupertypeName, TypeInheritanceSupertypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName)
GO

ALTER TABLE Instance
	ADD FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName)
GO

ALTER TABLE JoinNode
	ADD FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName)
GO

ALTER TABLE JoinRole
	ADD FOREIGN KEY (JoinStepInputJoinRoleFactTypeId, JoinStepInputJoinRoleJoinNodeJoinId, JoinStepInputJoinRoleJoinNodeOrdinal, JoinStepInputJoinRoleOrdinal, JoinStepOutputJoinRoleFactTypeId, JoinStepOutputJoinRoleJoinNodeJoinId, JoinStepOutputJoinRoleJoinNodeOrdinal, JoinStepOutputJoinRoleOrdinal) REFERENCES JoinStep (InputJoinRoleFactTypeId, InputJoinRoleJoinNodeJoinId, InputJoinRoleJoinNodeOrdinal, InputJoinRoleOrdinal, OutputJoinRoleFactTypeId, OutputJoinRoleJoinNodeJoinId, OutputJoinRoleJoinNodeOrdinal, OutputJoinRoleOrdinal)
GO

ALTER TABLE JoinRole
	ADD FOREIGN KEY (RoleFactTypeId, RoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
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

