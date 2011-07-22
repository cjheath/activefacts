CREATE TABLE AllowedRange (
	-- Allowed Range is where Value Constraint allows Value Range and Concept has GUID,
	ValueConstraintGUID                     varchar NOT NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound is inclusive,
	ValueRangeMaximumBoundIsInclusive       bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and Value is a string,
	ValueRangeMaximumBoundValueIsAString    bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMaximumBoundValueLiteral      varchar NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and maybe Value is in Unit and Unit has Unit Code,
	ValueRangeMaximumBoundValueUnitCode     char NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound is inclusive,
	ValueRangeMinimumBoundIsInclusive       bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and Value is a string,
	ValueRangeMinimumBoundValueIsAString    bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMinimumBoundValueLiteral      varchar NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and maybe Value is in Unit and Unit has Unit Code,
	ValueRangeMinimumBoundValueUnitCode     char NULL,
	UNIQUE(ValueConstraintGUID, ValueRangeMinimumBoundValueLiteral, ValueRangeMinimumBoundValueIsAString, ValueRangeMinimumBoundValueUnitCode, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValueLiteral, ValueRangeMaximumBoundValueIsAString, ValueRangeMaximumBoundValueUnitCode, ValueRangeMaximumBoundIsInclusive)
)
GO

CREATE TABLE Concept (
	-- maybe Constraint is a kind of Concept and maybe Constraint requires Enforcement and maybe Enforcement notifies Agent and Agent has Agent Name,
	ConstraintAgentName                     varchar NULL,
	-- maybe Constraint is a kind of Concept and maybe Constraint requires Enforcement and Enforcement has Enforcement Code,
	ConstraintEnforcementCode               varchar(16) NULL,
	-- maybe Constraint is a kind of Concept and maybe Name is of Constraint,
	ConstraintName                          varchar(64) NULL,
	-- maybe Constraint is a kind of Concept and maybe Vocabulary contains Constraint and Vocabulary is where Topic is described in Language and Language has Language Code,
	ConstraintVocabularyLanguageCode        char(3) NULL,
	-- maybe Constraint is a kind of Concept and maybe Vocabulary contains Constraint and Vocabulary is where Topic is described in Language and Topic has Name,
	ConstraintVocabularyTopicName           varchar(64) NULL,
	-- maybe Object Type is a kind of Concept and maybe Entity Type is a kind of Object Type and Entity Type is implied by objectification,
	EntityTypeIsImpliedByObjectification    bit NULL,
	-- maybe Fact Type is a kind of Concept and maybe Entity Type objectifies Fact Type and Concept has GUID,
	FactTypeEntityTypeGUID                  varchar NULL,
	-- Concept has GUID,
	GUID                                    varchar NOT NULL,
	-- maybe Object Type is a kind of Concept and Object Type is independent,
	ObjectTypeIsIndependent                 bit NULL,
	-- maybe Object Type is a kind of Concept and maybe Object Type uses Pronoun,
	ObjectTypePronoun                       varchar(20) NULL CHECK(ObjectTypePronoun = 'feminine' OR ObjectTypePronoun = 'masculine' OR ObjectTypePronoun = 'neuter' OR ObjectTypePronoun = 'personal'),
	-- maybe Constraint is a kind of Concept and maybe Presence Constraint is a kind of Constraint and Presence Constraint is mandatory,
	PresenceConstraintIsMandatory           bit NULL,
	-- maybe Constraint is a kind of Concept and maybe Presence Constraint is a kind of Constraint and Presence Constraint is preferred identifier,
	PresenceConstraintIsPreferredIdentifier bit NULL,
	-- maybe Constraint is a kind of Concept and maybe Presence Constraint is a kind of Constraint and maybe Presence Constraint has max-Frequency,
	PresenceConstraintMaxFrequency          int NULL CHECK(PresenceConstraintMaxFrequency >= 1),
	-- maybe Constraint is a kind of Concept and maybe Presence Constraint is a kind of Constraint and maybe Presence Constraint has min-Frequency,
	PresenceConstraintMinFrequency          int NULL CHECK(PresenceConstraintMinFrequency >= 2),
	-- maybe Constraint is a kind of Concept and maybe Presence Constraint is a kind of Constraint and Presence Constraint covers Role Sequence and Role Sequence has GUID,
	PresenceConstraintRoleSequenceGUID      varchar NULL,
	-- maybe Constraint is a kind of Concept and maybe Ring Constraint is a kind of Constraint and maybe Ring Constraint has other-Role and Concept has GUID,
	RingConstraintOtherRoleGUID             varchar NULL,
	-- maybe Constraint is a kind of Concept and maybe Ring Constraint is a kind of Constraint and Ring Constraint is of Ring Type,
	RingConstraintRingType                  varchar NULL,
	-- maybe Constraint is a kind of Concept and maybe Ring Constraint is a kind of Constraint and maybe Role is of Ring Constraint and Concept has GUID,
	RingConstraintRoleGUID                  varchar NULL,
	-- maybe Role is a kind of Concept and Role is where Fact Type has Ordinal role and Concept has GUID,
	RoleFactTypeGUID                        varchar NULL,
	-- maybe Role is a kind of Concept and maybe Implicit Fact Type is implied by Role and Concept has GUID,
	RoleImplicitFactTypeGUID                varchar NULL,
	-- maybe Role is a kind of Concept and maybe Term is name of Role and Term is where Vocabulary uses Name for Object Type,
	RoleName                                varchar(64) NULL,
	-- maybe Role is a kind of Concept and maybe Term is name of Role and Term is where Vocabulary uses Name for Object Type and Vocabulary is where Topic is described in Language and Language has Language Code,
	RoleNameVocabularyLanguageCode          char(3) NULL,
	-- maybe Role is a kind of Concept and maybe Term is name of Role and Term is where Vocabulary uses Name for Object Type and Vocabulary is where Topic is described in Language and Topic has Name,
	RoleNameVocabularyTopicName             varchar(64) NULL,
	-- maybe Role is a kind of Concept and Object Type plays Role and Concept has GUID,
	RoleObjectTypeGUID                      varchar NULL,
	-- maybe Role is a kind of Concept and Role is where Fact Type has Ordinal role,
	RoleOrdinal                             shortint NULL,
	-- maybe Constraint is a kind of Concept and maybe Set Constraint is a kind of Constraint and maybe Set Comparison Constraint is a kind of Set Constraint and maybe Set Exclusion Constraint is a kind of Set Comparison Constraint and Set Exclusion Constraint is mandatory,
	SetExclusionConstraintIsMandatory       bit NULL,
	-- maybe Constraint is a kind of Concept and maybe Set Constraint is a kind of Constraint and maybe Subset Constraint is a kind of Set Constraint and Subset Constraint covers subset-Role Sequence and Role Sequence has GUID,
	SubsetConstraintSubsetRoleSequenceGUID  varchar NULL,
	-- maybe Constraint is a kind of Concept and maybe Set Constraint is a kind of Constraint and maybe Subset Constraint is a kind of Set Constraint and Subset Constraint covers superset-Role Sequence and Role Sequence has GUID,
	SubsetConstraintSupersetRoleSequenceGUID varchar NULL,
	-- maybe Constraint is a kind of Concept and maybe Value Constraint is a kind of Constraint and maybe Role has role-Value Constraint and Concept has GUID,
	ValueConstraintRoleGUID                 varchar NULL,
	-- maybe Object Type is a kind of Concept and maybe Value Type is a kind of Object Type and maybe Value Type has auto- assigned Transaction Timing,
	ValueTypeAutoAssignedTransactionTiming  varchar NULL CHECK(ValueTypeAutoAssignedTransactionTiming = 'assert' OR ValueTypeAutoAssignedTransactionTiming = 'commit'),
	-- maybe Object Type is a kind of Concept and maybe Value Type is a kind of Object Type and maybe Value Type has Length,
	ValueTypeLength                         int NULL,
	-- maybe Object Type is a kind of Concept and maybe Value Type is a kind of Object Type and maybe Value Type has Scale,
	ValueTypeScale                          int NULL,
	-- maybe Object Type is a kind of Concept and maybe Value Type is a kind of Object Type and maybe Value Type is subtype of super-Value Type and Concept has GUID,
	ValueTypeSupertypeGUID                  varchar NULL,
	-- maybe Object Type is a kind of Concept and maybe Value Type is a kind of Object Type and maybe Value Type is of Unit and Unit has Unit Code,
	ValueTypeUnitCode                       char NULL,
	-- maybe Object Type is a kind of Concept and maybe Value Type is a kind of Object Type and maybe Value Type has Value Constraint and Concept has GUID,
	ValueTypeValueConstraintGUID            varchar NULL,
	PRIMARY KEY(GUID),
	FOREIGN KEY (RingConstraintOtherRoleGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (RingConstraintRoleGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (ValueConstraintRoleGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (ValueTypeValueConstraintGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (FactTypeEntityTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (RoleImplicitFactTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (RoleFactTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (RoleObjectTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (ValueTypeSupertypeGUID) REFERENCES Concept (GUID)
)
GO

CREATE VIEW dbo.ConstraintInConcept_VocabularyTopicNameVocabularyLanguageCodeName (ConstraintVocabularyTopicName, ConstraintVocabularyLanguageCode, ConstraintName) WITH SCHEMABINDING AS
	SELECT ConstraintVocabularyTopicName, ConstraintVocabularyLanguageCode, ConstraintName FROM dbo.Concept
	WHERE	ConstraintVocabularyTopicName IS NOT NULL
	  AND	ConstraintVocabularyLanguageCode IS NOT NULL
	  AND	ConstraintName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ConstraintInConceptByConstraintVocabularyTopicNameConstraintVocabularyLanguageCodeConstraintName ON dbo.ConstraintInConcept_VocabularyTopicNameVocabularyLanguageCodeName(ConstraintVocabularyTopicName, ConstraintVocabularyLanguageCode, ConstraintName)
GO

CREATE VIEW dbo.FactTypeInConcept_FactTypeEntityTypeGUID (FactTypeEntityTypeGUID) WITH SCHEMABINDING AS
	SELECT FactTypeEntityTypeGUID FROM dbo.Concept
	WHERE	FactTypeEntityTypeGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX EntityTypeNestsOneFactType ON dbo.FactTypeInConcept_FactTypeEntityTypeGUID(FactTypeEntityTypeGUID)
GO

CREATE VIEW dbo.RoleInConcept_FactTypeGUIDOrdinal (RoleFactTypeGUID, RoleOrdinal) WITH SCHEMABINDING AS
	SELECT RoleFactTypeGUID, RoleOrdinal FROM dbo.Concept
	WHERE	RoleFactTypeGUID IS NOT NULL
	  AND	RoleOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleInConceptByRoleFactTypeGUIDRoleOrdinal ON dbo.RoleInConcept_FactTypeGUIDOrdinal(RoleFactTypeGUID, RoleOrdinal)
GO

CREATE VIEW dbo.RoleInConcept_ImplicitFactTypeGUID (RoleImplicitFactTypeGUID) WITH SCHEMABINDING AS
	SELECT RoleImplicitFactTypeGUID FROM dbo.Concept
	WHERE	RoleImplicitFactTypeGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleInConceptByRoleImplicitFactTypeGUID ON dbo.RoleInConcept_ImplicitFactTypeGUID(RoleImplicitFactTypeGUID)
GO

CREATE VIEW dbo.SubsetConstraintInConcept_SubsetConstraintSubsetRoleSequenceGUIDSubsetConstraintSupersetRoleSequenceGUID (SubsetConstraintSubsetRoleSequenceGUID, SubsetConstraintSupersetRoleSequenceGUID) WITH SCHEMABINDING AS
	SELECT SubsetConstraintSubsetRoleSequenceGUID, SubsetConstraintSupersetRoleSequenceGUID FROM dbo.Concept
	WHERE	SubsetConstraintSubsetRoleSequenceGUID IS NOT NULL
	  AND	SubsetConstraintSupersetRoleSequenceGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_SubsetConstraintInConceptBySubsetConstraintSubsetRoleSequenceGUIDSubsetConstraintSupersetRoleSequenceGUID ON dbo.SubsetConstraintInConcept_SubsetConstraintSubsetRoleSequenceGUIDSubsetConstraintSupersetRoleSequenceGUID(SubsetConstraintSubsetRoleSequenceGUID, SubsetConstraintSupersetRoleSequenceGUID)
GO

CREATE VIEW dbo.ValueConstraintInConcept_ValueConstraintRoleGUID (ValueConstraintRoleGUID) WITH SCHEMABINDING AS
	SELECT ValueConstraintRoleGUID FROM dbo.Concept
	WHERE	ValueConstraintRoleGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX RoleHasOneRoleValueConstraint ON dbo.ValueConstraintInConcept_ValueConstraintRoleGUID(ValueConstraintRoleGUID)
GO

CREATE VIEW dbo.ValueTypeInConcept_ValueTypeValueConstraintGUID (ValueTypeValueConstraintGUID) WITH SCHEMABINDING AS
	SELECT ValueTypeValueConstraintGUID FROM dbo.Concept
	WHERE	ValueTypeValueConstraintGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueTypeInConceptByValueTypeValueConstraintGUID ON dbo.ValueTypeInConcept_ValueTypeValueConstraintGUID(ValueTypeValueConstraintGUID)
GO

CREATE TABLE ContextAccordingTo (
	-- Context According To is where Context Note is according to Agent and Agent has Agent Name,
	AgentName                               varchar NOT NULL,
	-- Context According To is where Context Note is according to Agent and Context Note has GUID,
	ContextNoteGUID                         varchar NOT NULL,
	-- maybe Context According To was lodged on Date,
	Date                                    datetime NULL,
	PRIMARY KEY(ContextNoteGUID, AgentName)
)
GO

CREATE TABLE ContextAgreedBy (
	-- Context Agreed By is where Agreement was reached by Agent and Agent has Agent Name,
	AgentName                               varchar NOT NULL,
	-- Context Agreed By is where Agreement was reached by Agent and Context Note has GUID,
	AgreementGUID                           varchar NOT NULL,
	PRIMARY KEY(AgreementGUID, AgentName)
)
GO

CREATE TABLE ContextNote (
	-- maybe Context Note was added by Agreement and maybe Agreement was on Date,
	AgreementDate                           datetime NULL,
	-- maybe Concept has Context Note and Concept has GUID,
	ConceptGUID                             varchar NULL,
	-- Context Note has Context Note Kind,
	ContextNoteKind                         varchar NOT NULL CHECK(ContextNoteKind = 'as_opposed_to' OR ContextNoteKind = 'because' OR ContextNoteKind = 'so_that' OR ContextNoteKind = 'to_avoid'),
	-- Context Note has Discussion,
	Discussion                              varchar NOT NULL,
	-- Context Note has GUID,
	GUID                                    varchar NOT NULL,
	PRIMARY KEY(GUID),
	FOREIGN KEY (ConceptGUID) REFERENCES Concept (GUID)
)
GO

CREATE TABLE Derivation (
	-- Derivation is where Unit is derived from base-Unit and Unit has Unit Code,
	BaseUnitCode                            char NOT NULL,
	-- Derivation is where Unit is derived from base-Unit and Unit has Unit Code,
	DerivedUnitCode                         char NOT NULL,
	-- maybe Derivation has Exponent,
	Exponent                                shortint NULL,
	PRIMARY KEY(DerivedUnitCode, BaseUnitCode)
)
GO

CREATE TABLE Facet (
	-- maybe Facet has values of facet-Value Type and Concept has GUID,
	FacetValueTypeGUID                      varchar NULL,
	-- Facet is where Value Type has facet called Name,
	Name                                    varchar(64) NOT NULL,
	-- Facet is where Value Type has facet called Name and Concept has GUID,
	ValueTypeGUID                           varchar NOT NULL,
	PRIMARY KEY(ValueTypeGUID, Name),
	FOREIGN KEY (FacetValueTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (ValueTypeGUID) REFERENCES Concept (GUID)
)
GO

CREATE TABLE FacetValue (
	-- Facet Value is where Value Type defines Facet as having Value and Facet is where Value Type has facet called Name,
	FacetName                               varchar(64) NOT NULL,
	-- Facet Value is where Value Type defines Facet as having Value and Facet is where Value Type has facet called Name and Concept has GUID,
	FacetValueTypeGUID                      varchar NOT NULL,
	-- Facet Value is where Value Type defines Facet as having Value and Value is a string,
	ValueIsAString                          bit NOT NULL,
	-- Facet Value is where Value Type defines Facet as having Value and Value is represented by Literal,
	ValueLiteral                            varchar NOT NULL,
	-- Facet Value is where Value Type defines Facet as having Value and Concept has GUID,
	ValueTypeGUID                           varchar NOT NULL,
	-- Facet Value is where Value Type defines Facet as having Value and maybe Value is in Unit and Unit has Unit Code,
	ValueUnitCode                           char NULL,
	PRIMARY KEY(ValueTypeGUID, FacetValueTypeGUID, FacetName),
	FOREIGN KEY (ValueTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (FacetName, FacetValueTypeGUID) REFERENCES Facet (Name, ValueTypeGUID)
)
GO

CREATE TABLE Fact (
	-- Fact is of Fact Type and Concept has GUID,
	FactTypeGUID                            varchar NOT NULL,
	-- Fact has GUID,
	GUID                                    varchar NOT NULL,
	-- Population includes Fact and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Fact and maybe Topic includes Population and Topic has Name,
	PopulationTopicName                     varchar(64) NULL,
	PRIMARY KEY(GUID),
	FOREIGN KEY (FactTypeGUID) REFERENCES Concept (GUID)
)
GO

CREATE TABLE Instance (
	-- maybe Instance objectifies Fact and Fact has GUID,
	FactGUID                                varchar NULL,
	-- Instance has GUID,
	GUID                                    varchar NOT NULL,
	-- Instance is of Object Type and Concept has GUID,
	ObjectTypeGUID                          varchar NOT NULL,
	-- Population includes Instance and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Instance and maybe Topic includes Population and Topic has Name,
	PopulationTopicName                     varchar(64) NULL,
	-- maybe Instance has Value and Value is a string,
	ValueIsAString                          bit NULL,
	-- maybe Instance has Value and Value is represented by Literal,
	ValueLiteral                            varchar NULL,
	-- maybe Instance has Value and maybe Value is in Unit and Unit has Unit Code,
	ValueUnitCode                           char NULL,
	PRIMARY KEY(GUID),
	FOREIGN KEY (ObjectTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (FactGUID) REFERENCES Fact (GUID)
)
GO

CREATE VIEW dbo.Instance_FactGUID (FactGUID) WITH SCHEMABINDING AS
	SELECT FactGUID FROM dbo.Instance
	WHERE	FactGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_InstanceByFactGUID ON dbo.Instance_FactGUID(FactGUID)
GO

CREATE TABLE [Join] (
	-- Join has GUID,
	GUID                                    varchar NOT NULL,
	PRIMARY KEY(GUID)
)
GO

CREATE TABLE JoinNode (
	-- Join includes Join Node and Join has GUID,
	JoinGUID                                varchar NOT NULL,
	-- Join Node is for Object Type and Concept has GUID,
	ObjectTypeGUID                          varchar NOT NULL,
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
	-- maybe Join Node has Value and maybe Value is in Unit and Unit has Unit Code,
	ValueUnitCode                           char NULL,
	PRIMARY KEY(JoinGUID, Ordinal),
	FOREIGN KEY (ObjectTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (JoinGUID) REFERENCES [Join] (GUID)
)
GO

CREATE TABLE JoinRole (
	-- Join Role is where Join Node includes Role and Join includes Join Node and Join has GUID,
	JoinNodeJoinGUID                        varchar NOT NULL,
	-- Join Role is where Join Node includes Role and Join Node has Ordinal position,
	JoinNodeOrdinal                         shortint NOT NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has input-Join Role and Join Role is where Join Node includes Role and Concept has GUID,
	JoinStepInputJoinRoleGUID               varchar NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has input-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has GUID,
	JoinStepInputJoinRoleJoinNodeJoinGUID   varchar NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has input-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position,
	JoinStepInputJoinRoleJoinNodeOrdinal    shortint NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has output-Join Role and Join Role is where Join Node includes Role and Concept has GUID,
	JoinStepOutputJoinRoleGUID              varchar NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has output-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has GUID,
	JoinStepOutputJoinRoleJoinNodeJoinGUID  varchar NULL,
	-- maybe Join Step involves incidental-Join Role and Join Step has output-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position,
	JoinStepOutputJoinRoleJoinNodeOrdinal   shortint NULL,
	-- Join Role is where Join Node includes Role and Concept has GUID,
	RoleGUID                                varchar NOT NULL,
	-- maybe Join Role projects Role Ref and Role Ref is where Role Sequence in Ordinal position includes Role,
	RoleRefOrdinal                          shortint NULL,
	-- maybe Join Role projects Role Ref and Role Ref is where Role Sequence in Ordinal position includes Role and Role Sequence has GUID,
	RoleRefRoleSequenceGUID                 varchar NULL,
	PRIMARY KEY(JoinNodeJoinGUID, JoinNodeOrdinal, RoleGUID),
	FOREIGN KEY (RoleGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (JoinNodeJoinGUID, JoinNodeOrdinal) REFERENCES JoinNode (JoinGUID, Ordinal)
)
GO

CREATE VIEW dbo.JoinRole_RoleRefRoleSequenceGUIDRoleRefOrdinal (RoleRefRoleSequenceGUID, RoleRefOrdinal) WITH SCHEMABINDING AS
	SELECT RoleRefRoleSequenceGUID, RoleRefOrdinal FROM dbo.JoinRole
	WHERE	RoleRefRoleSequenceGUID IS NOT NULL
	  AND	RoleRefOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_JoinRoleByRoleRefRoleSequenceGUIDRoleRefOrdinal ON dbo.JoinRole_RoleRefRoleSequenceGUIDRoleRefOrdinal(RoleRefRoleSequenceGUID, RoleRefOrdinal)
GO

CREATE TABLE JoinStep (
	-- Join Step traverses Fact Type and Concept has GUID,
	FactTypeGUID                            varchar NOT NULL,
	-- Join Step has input-Join Role and Join Role is where Join Node includes Role and Concept has GUID,
	InputJoinRoleGUID                       varchar NOT NULL,
	-- Join Step has input-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has GUID,
	InputJoinRoleJoinNodeJoinGUID           varchar NOT NULL,
	-- Join Step has input-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position,
	InputJoinRoleJoinNodeOrdinal            shortint NOT NULL,
	-- is anti Join Step,
	IsAnti                                  bit NOT NULL,
	-- Join Step is outer,
	IsOuter                                 bit NOT NULL,
	-- Join Step has output-Join Role and Join Role is where Join Node includes Role and Concept has GUID,
	OutputJoinRoleGUID                      varchar NOT NULL,
	-- Join Step has output-Join Role and Join Role is where Join Node includes Role and Join includes Join Node and Join has GUID,
	OutputJoinRoleJoinNodeJoinGUID          varchar NOT NULL,
	-- Join Step has output-Join Role and Join Role is where Join Node includes Role and Join Node has Ordinal position,
	OutputJoinRoleJoinNodeOrdinal           shortint NOT NULL,
	PRIMARY KEY(InputJoinRoleJoinNodeJoinGUID, InputJoinRoleJoinNodeOrdinal, InputJoinRoleGUID, OutputJoinRoleJoinNodeJoinGUID, OutputJoinRoleJoinNodeOrdinal, OutputJoinRoleGUID),
	FOREIGN KEY (FactTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (InputJoinRoleJoinNodeJoinGUID, InputJoinRoleJoinNodeOrdinal, InputJoinRoleGUID) REFERENCES JoinRole (JoinNodeJoinGUID, JoinNodeOrdinal, RoleGUID),
	FOREIGN KEY (OutputJoinRoleJoinNodeJoinGUID, OutputJoinRoleJoinNodeOrdinal, OutputJoinRoleGUID) REFERENCES JoinRole (JoinNodeJoinGUID, JoinNodeOrdinal, RoleGUID)
)
GO

CREATE TABLE Reading (
	-- Fact Type has Reading and Concept has GUID,
	FactTypeGUID                            varchar NOT NULL,
	-- Reading is in Ordinal position,
	Ordinal                                 shortint NOT NULL,
	-- Reading is in Role Sequence and Role Sequence has GUID,
	RoleSequenceGUID                        varchar NOT NULL,
	-- Reading has Text,
	Text                                    varchar(256) NOT NULL,
	-- maybe Reading is for Vocabulary and Vocabulary is where Topic is described in Language and Language has Language Code,
	VocabularyLanguageCode                  char(3) NULL,
	-- maybe Reading is for Vocabulary and Vocabulary is where Topic is described in Language and Topic has Name,
	VocabularyTopicName                     varchar(64) NULL,
	PRIMARY KEY(FactTypeGUID, Ordinal),
	FOREIGN KEY (FactTypeGUID) REFERENCES Concept (GUID)
)
GO

CREATE TABLE RoleDisplay (
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has GUID,
	FactTypeShapeGUID                       varchar NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position,
	Ordinal                                 shortint NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Concept has GUID,
	RoleGUID                                varchar NOT NULL,
	PRIMARY KEY(FactTypeShapeGUID, Ordinal),
	FOREIGN KEY (RoleGUID) REFERENCES Concept (GUID)
)
GO

CREATE TABLE RoleRef (
	-- maybe Role Ref has leading-Adjective,
	LeadingAdjective                        varchar(64) NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role,
	Ordinal                                 shortint NOT NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Concept has GUID,
	RoleGUID                                varchar NOT NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Role Sequence has GUID,
	RoleSequenceGUID                        varchar NOT NULL,
	-- maybe Role Ref has trailing-Adjective,
	TrailingAdjective                       varchar(64) NULL,
	PRIMARY KEY(RoleSequenceGUID, Ordinal),
	UNIQUE(RoleGUID, RoleSequenceGUID),
	FOREIGN KEY (RoleGUID) REFERENCES Concept (GUID)
)
GO

CREATE TABLE RoleSequence (
	-- Role Sequence has GUID,
	GUID                                    varchar NOT NULL,
	-- Role Sequence has unused dependency to force table in norma,
	HasUnusedDependencyToForceTableInNorma  bit NOT NULL,
	PRIMARY KEY(GUID)
)
GO

CREATE TABLE RoleValue (
	-- Role Value fulfils Fact and Fact has GUID,
	FactGUID                                varchar NOT NULL,
	-- Instance plays Role Value and Instance has GUID,
	InstanceGUID                            varchar NOT NULL,
	-- Population includes Role Value and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Role Value and maybe Topic includes Population and Topic has Name,
	PopulationTopicName                     varchar(64) NULL,
	-- Role Value is of Role and Concept has GUID,
	RoleGUID                                varchar NOT NULL,
	PRIMARY KEY(InstanceGUID, FactGUID),
	FOREIGN KEY (RoleGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (FactGUID) REFERENCES Fact (GUID),
	FOREIGN KEY (InstanceGUID) REFERENCES Instance (GUID)
)
GO

CREATE TABLE SetComparisonRoles (
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence,
	Ordinal                                 shortint NOT NULL,
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence and Role Sequence has GUID,
	RoleSequenceGUID                        varchar NOT NULL,
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence and Concept has GUID,
	SetComparisonConstraintGUID             varchar NOT NULL,
	PRIMARY KEY(SetComparisonConstraintGUID, Ordinal),
	UNIQUE(SetComparisonConstraintGUID, RoleSequenceGUID),
	FOREIGN KEY (SetComparisonConstraintGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (RoleSequenceGUID) REFERENCES RoleSequence (GUID)
)
GO

CREATE TABLE Shape (
	-- maybe Constraint Shape is a kind of Shape and Constraint Shape is for Constraint and Concept has GUID,
	ConstraintShapeConstraintGUID           varchar NULL,
	-- Shape is in Diagram and Diagram is called Name,
	DiagramName                             varchar(64) NOT NULL,
	-- Shape is in Diagram and Diagram is for Vocabulary and Vocabulary is where Topic is described in Language and Language has Language Code,
	DiagramVocabularyLanguageCode           char(3) NOT NULL,
	-- Shape is in Diagram and Diagram is for Vocabulary and Vocabulary is where Topic is described in Language and Topic has Name,
	DiagramVocabularyTopicName              varchar(64) NOT NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Display Role Names Setting,
	FactTypeShapeDisplayRoleNamesSetting    varchar NULL CHECK(FactTypeShapeDisplayRoleNamesSetting = 'false' OR FactTypeShapeDisplayRoleNamesSetting = 'true'),
	-- maybe Fact Type Shape is a kind of Shape and Fact Type Shape is for Fact Type and Concept has GUID,
	FactTypeShapeFactTypeGUID               varchar NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Reading Shape and Reading Shape is a kind of Shape and Shape has GUID,
	FactTypeShapeGUID                       varchar NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Objectified Fact Type Name Shape is for Fact Type Shape and Objectified Fact Type Name Shape is a kind of Shape and Shape has GUID,
	FactTypeShapeGUID                       varchar NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Reading Shape and Reading Shape is for Reading and Fact Type has Reading and Concept has GUID,
	FactTypeShapeReadingFactTypeGUID        varchar NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Reading Shape and Reading Shape is for Reading and Reading is in Ordinal position,
	FactTypeShapeReadingOrdinal             shortint NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Rotation Setting,
	FactTypeShapeRotationSetting            varchar NULL CHECK(FactTypeShapeRotationSetting = 'left' OR FactTypeShapeRotationSetting = 'right'),
	-- Shape has GUID,
	GUID                                    varchar NOT NULL,
	-- Shape is expanded,
	IsExpanded                              bit NOT NULL,
	-- maybe Model Note Shape is a kind of Shape and Model Note Shape is for Context Note and Context Note has GUID,
	ModelNoteShapeContextNoteGUID           varchar NULL,
	-- maybe Object Type Shape is a kind of Shape and Object Type Shape is for Object Type and Concept has GUID,
	ObjectTypeShapeObjectTypeGUID           varchar NULL,
	-- maybe Shape is at Position and Position is at X,
	PositionX                               int NULL,
	-- maybe Shape is at Position and Position is at Y,
	PositionY                               int NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Ring Constraint Shape is a kind of Constraint Shape and Ring Constraint Shape is attached to Fact Type and Concept has GUID,
	RingConstraintShapeFactTypeGUID         varchar NULL,
	-- maybe Role Name Shape is a kind of Shape and Role Name Shape is for Role Display and Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has GUID,
	RoleNameShapeRoleDisplayFactTypeShapeGUID varchar NULL,
	-- maybe Role Name Shape is a kind of Shape and Role Name Shape is for Role Display and Role Display is where Fact Type Shape displays Role in Ordinal position,
	RoleNameShapeRoleDisplayOrdinal         shortint NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Value Constraint Shape is a kind of Constraint Shape and maybe Value Constraint Shape is for Object Type Shape and Shape has GUID,
	ValueConstraintShapeObjectTypeShapeGUID varchar NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Value Constraint Shape is a kind of Constraint Shape and maybe Role Display has Value Constraint Shape and Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has GUID,
	ValueConstraintShapeRoleDisplayFactTypeShapeGUID varchar NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Value Constraint Shape is a kind of Constraint Shape and maybe Role Display has Value Constraint Shape and Role Display is where Fact Type Shape displays Role in Ordinal position,
	ValueConstraintShapeRoleDisplayOrdinal  shortint NULL,
	PRIMARY KEY(GUID),
	FOREIGN KEY (ConstraintShapeConstraintGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (RingConstraintShapeFactTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (FactTypeShapeFactTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (ObjectTypeShapeObjectTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (ModelNoteShapeContextNoteGUID) REFERENCES ContextNote (GUID),
	FOREIGN KEY (FactTypeShapeReadingFactTypeGUID, FactTypeShapeReadingOrdinal) REFERENCES Reading (FactTypeGUID, Ordinal),
	FOREIGN KEY (ValueConstraintShapeRoleDisplayFactTypeShapeGUID, ValueConstraintShapeRoleDisplayOrdinal) REFERENCES RoleDisplay (FactTypeShapeGUID, Ordinal),
	FOREIGN KEY (RoleNameShapeRoleDisplayFactTypeShapeGUID, RoleNameShapeRoleDisplayOrdinal) REFERENCES RoleDisplay (FactTypeShapeGUID, Ordinal),
	FOREIGN KEY (ValueConstraintShapeObjectTypeShapeGUID) REFERENCES Shape (GUID),
	FOREIGN KEY (FactTypeShapeGUID) REFERENCES Shape (GUID),
	FOREIGN KEY (FactTypeShapeGUID) REFERENCES Shape (GUID)
)
GO

CREATE VIEW dbo.Shape_DiagramVocabularyTopicNameDiagramVocabularyLanguageCodeDiagramNamePositionXPositionY (DiagramVocabularyTopicName, DiagramVocabularyLanguageCode, DiagramName, PositionX, PositionY) WITH SCHEMABINDING AS
	SELECT DiagramVocabularyTopicName, DiagramVocabularyLanguageCode, DiagramName, PositionX, PositionY FROM dbo.Shape
	WHERE	PositionX IS NOT NULL
	  AND	PositionY IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ShapeByDiagramVocabularyTopicNameDiagramVocabularyLanguageCodeDiagramNamePositionXPositionY ON dbo.Shape_DiagramVocabularyTopicNameDiagramVocabularyLanguageCodeDiagramNamePositionXPositionY(DiagramVocabularyTopicName, DiagramVocabularyLanguageCode, DiagramName, PositionX, PositionY)
GO

CREATE VIEW dbo.ObjectifiedFactTypeNameShapeInShape_FactTypeShapeGUID (FactTypeShapeGUID) WITH SCHEMABINDING AS
	SELECT FactTypeShapeGUID FROM dbo.Shape
	WHERE	FactTypeShapeGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ObjectifiedFactTypeNameShapeInShapeByFactTypeShapeGUID ON dbo.ObjectifiedFactTypeNameShapeInShape_FactTypeShapeGUID(FactTypeShapeGUID)
GO

CREATE VIEW dbo.ReadingShapeInShape_FactTypeShapeGUID (FactTypeShapeGUID) WITH SCHEMABINDING AS
	SELECT FactTypeShapeGUID FROM dbo.Shape
	WHERE	FactTypeShapeGUID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ReadingShapeInShapeByFactTypeShapeGUID ON dbo.ReadingShapeInShape_FactTypeShapeGUID(FactTypeShapeGUID)
GO

CREATE VIEW dbo.RoleNameShapeInShape_RoleNameShapeRoleDisplayFactTypeShapeGUIDRoleNameShapeRoleDisplayOrdinal (RoleNameShapeRoleDisplayFactTypeShapeGUID, RoleNameShapeRoleDisplayOrdinal) WITH SCHEMABINDING AS
	SELECT RoleNameShapeRoleDisplayFactTypeShapeGUID, RoleNameShapeRoleDisplayOrdinal FROM dbo.Shape
	WHERE	RoleNameShapeRoleDisplayFactTypeShapeGUID IS NOT NULL
	  AND	RoleNameShapeRoleDisplayOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleNameShapeInShapeByRoleNameShapeRoleDisplayFactTypeShapeGUIDRoleNameShapeRoleDisplayOrdinal ON dbo.RoleNameShapeInShape_RoleNameShapeRoleDisplayFactTypeShapeGUIDRoleNameShapeRoleDisplayOrdinal(RoleNameShapeRoleDisplayFactTypeShapeGUID, RoleNameShapeRoleDisplayOrdinal)
GO

CREATE VIEW dbo.ValueConstraintShapeInShape_ValueConstraintShapeRoleDisplayFactTypeShapeGUIDValueConstraintShapeRoleDisplayOrdinal (ValueConstraintShapeRoleDisplayFactTypeShapeGUID, ValueConstraintShapeRoleDisplayOrdinal) WITH SCHEMABINDING AS
	SELECT ValueConstraintShapeRoleDisplayFactTypeShapeGUID, ValueConstraintShapeRoleDisplayOrdinal FROM dbo.Shape
	WHERE	ValueConstraintShapeRoleDisplayFactTypeShapeGUID IS NOT NULL
	  AND	ValueConstraintShapeRoleDisplayOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueConstraintShapeInShapeByValueConstraintShapeRoleDisplayFactTypeShapeGUIDValueConstraintShapeRoleDisplayOrdinal ON dbo.ValueConstraintShapeInShape_ValueConstraintShapeRoleDisplayFactTypeShapeGUIDValueConstraintShapeRoleDisplayOrdinal(ValueConstraintShapeRoleDisplayFactTypeShapeGUID, ValueConstraintShapeRoleDisplayOrdinal)
GO

CREATE TABLE Term (
	-- Term is preferred,
	IsPreferred                             bit NOT NULL,
	-- Term is where Vocabulary uses Name for Object Type,
	Name                                    varchar(64) NOT NULL,
	-- Term is where Vocabulary uses Name for Object Type and Concept has GUID,
	ObjectTypeGUID                          varchar NOT NULL,
	-- Term is where Vocabulary uses Name for Object Type and Vocabulary is where Topic is described in Language and Language has Language Code,
	VocabularyLanguageCode                  char(3) NOT NULL,
	-- Term is where Vocabulary uses Name for Object Type and Vocabulary is where Topic is described in Language and Topic has Name,
	VocabularyTopicName                     varchar(64) NOT NULL,
	PRIMARY KEY(VocabularyTopicName, VocabularyLanguageCode, Name),
	UNIQUE(VocabularyTopicName, VocabularyLanguageCode, ObjectTypeGUID, IsPreferred),
	FOREIGN KEY (ObjectTypeGUID) REFERENCES Concept (GUID)
)
GO

CREATE TABLE TypeInheritance (
	-- maybe Assimilation applies to Type Inheritance,
	Assimilation                            varchar NULL CHECK(Assimilation = 'partitioned' OR Assimilation = 'separate'),
	-- Type Inheritance implies Fact Type and Concept has GUID,
	FactTypeGUID                            varchar NOT NULL,
	-- Type Inheritance provides identification,
	ProvidesIdentification                  bit NOT NULL,
	-- Type Inheritance is where Entity Type is subtype of super-Entity Type and Concept has GUID,
	SubtypeGUID                             varchar NOT NULL,
	-- Type Inheritance is where Entity Type is subtype of super-Entity Type and Concept has GUID,
	SupertypeGUID                           varchar NOT NULL,
	PRIMARY KEY(SubtypeGUID, SupertypeGUID),
	UNIQUE(FactTypeGUID),
	UNIQUE(SubtypeGUID, ProvidesIdentification),
	FOREIGN KEY (FactTypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (SubtypeGUID) REFERENCES Concept (GUID),
	FOREIGN KEY (SupertypeGUID) REFERENCES Concept (GUID)
)
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
	-- Unit has Unit Code,
	UnitCode                                char NOT NULL,
	-- Vocabulary includes Unit and Vocabulary is where Topic is described in Language and Language has Language Code,
	VocabularyLanguageCode                  char(3) NOT NULL,
	-- Vocabulary includes Unit and Vocabulary is where Topic is described in Language and Topic has Name,
	VocabularyTopicName                     varchar(64) NOT NULL,
	PRIMARY KEY(UnitCode),
	UNIQUE(VocabularyTopicName, VocabularyLanguageCode, Name)
)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueConstraintGUID) REFERENCES Concept (GUID)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (PresenceConstraintRoleSequenceGUID) REFERENCES RoleSequence (GUID)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (SubsetConstraintSubsetRoleSequenceGUID) REFERENCES RoleSequence (GUID)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (SubsetConstraintSupersetRoleSequenceGUID) REFERENCES RoleSequence (GUID)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (RoleName, RoleNameVocabularyLanguageCode, RoleNameVocabularyTopicName) REFERENCES Term (Name, VocabularyLanguageCode, VocabularyTopicName)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (ValueTypeUnitCode) REFERENCES Unit (UnitCode)
GO

ALTER TABLE ContextAccordingTo
	ADD FOREIGN KEY (ContextNoteGUID) REFERENCES ContextNote (GUID)
GO

ALTER TABLE ContextAgreedBy
	ADD FOREIGN KEY (AgreementGUID) REFERENCES ContextNote (GUID)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (BaseUnitCode) REFERENCES Unit (UnitCode)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (DerivedUnitCode) REFERENCES Unit (UnitCode)
GO

ALTER TABLE JoinRole
	ADD FOREIGN KEY (JoinStepInputJoinRoleGUID, JoinStepInputJoinRoleJoinNodeJoinGUID, JoinStepInputJoinRoleJoinNodeOrdinal, JoinStepOutputJoinRoleGUID, JoinStepOutputJoinRoleJoinNodeJoinGUID, JoinStepOutputJoinRoleJoinNodeOrdinal) REFERENCES JoinStep (InputJoinRoleGUID, InputJoinRoleJoinNodeJoinGUID, InputJoinRoleJoinNodeOrdinal, OutputJoinRoleGUID, OutputJoinRoleJoinNodeJoinGUID, OutputJoinRoleJoinNodeOrdinal)
GO

ALTER TABLE JoinRole
	ADD FOREIGN KEY (RoleRefOrdinal, RoleRefRoleSequenceGUID) REFERENCES RoleRef (Ordinal, RoleSequenceGUID)
GO

ALTER TABLE Reading
	ADD FOREIGN KEY (RoleSequenceGUID) REFERENCES RoleSequence (GUID)
GO

ALTER TABLE RoleDisplay
	ADD FOREIGN KEY (FactTypeShapeGUID) REFERENCES Shape (GUID)
GO

ALTER TABLE RoleRef
	ADD FOREIGN KEY (RoleSequenceGUID) REFERENCES RoleSequence (GUID)
GO

