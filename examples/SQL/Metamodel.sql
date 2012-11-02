CREATE TABLE Aggregation (
	-- Aggregation is where Variable is bound to Aggregate over aggregated-Variable and Aggregate has Aggregate Code,
	AggregateCode                           varchar(32) NOT NULL,
	-- Aggregation is where Variable is bound to Aggregate over aggregated-Variable and Variable has Ordinal position,
	AggregatedVariableOrdinal               shortint NOT NULL,
	-- Aggregation is where Variable is bound to Aggregate over aggregated-Variable and Query includes Variable and Query is a kind of Concept and Concept has Guid,
	AggregatedVariableQueryGuid             Guid NOT NULL,
	-- Aggregation is where Variable is bound to Aggregate over aggregated-Variable and Variable has Ordinal position,
	VariableOrdinal                         shortint NOT NULL,
	-- Aggregation is where Variable is bound to Aggregate over aggregated-Variable and Query includes Variable and Query is a kind of Concept and Concept has Guid,
	VariableQueryGuid                       Guid NOT NULL,
	PRIMARY KEY(VariableQueryGuid, VariableOrdinal, AggregateCode, AggregatedVariableQueryGuid, AggregatedVariableOrdinal),
	UNIQUE(AggregateCode, AggregatedVariableQueryGuid, AggregatedVariableOrdinal)
)
GO

CREATE TABLE AllowedRange (
	-- Allowed Range is where Value Constraint allows Value Range and Constraint is a kind of Concept and Concept has Guid,
	ValueConstraintGuid                     Guid NOT NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound is inclusive,
	ValueRangeMaximumBoundIsInclusive       bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and Value is a string,
	ValueRangeMaximumBoundValueIsAString    bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMaximumBoundValueLiteral      varchar NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and maybe Value is in Unit and Unit is a kind of Concept and Concept has Guid,
	ValueRangeMaximumBoundValueUnitGuid     Guid NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound is inclusive,
	ValueRangeMinimumBoundIsInclusive       bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and Value is a string,
	ValueRangeMinimumBoundValueIsAString    bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMinimumBoundValueLiteral      varchar NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and maybe Value is in Unit and Unit is a kind of Concept and Concept has Guid,
	ValueRangeMinimumBoundValueUnitGuid     Guid NULL,
	UNIQUE(ValueConstraintGuid, ValueRangeMinimumBoundValueLiteral, ValueRangeMinimumBoundValueIsAString, ValueRangeMinimumBoundValueUnitGuid, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValueLiteral, ValueRangeMaximumBoundValueIsAString, ValueRangeMaximumBoundValueUnitGuid, ValueRangeMaximumBoundIsInclusive)
)
GO

CREATE TABLE AlternativeSet (
	-- Alternative Set has Guid,
	Guid                                    Guid NOT NULL,
	-- Alternative Set members are exclusive,
	MembersAreExclusive                     bit NOT NULL,
	PRIMARY KEY(Guid)
)
GO

CREATE TABLE [Constraint] (
	-- Constraint is a kind of Concept and Concept has Guid,
	ConceptGuid                             Guid NOT NULL,
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
	-- maybe Presence Constraint is a kind of Constraint and Presence Constraint covers Role Sequence and Role Sequence has Guid,
	PresenceConstraintRoleSequenceGuid      Guid NULL,
	-- maybe Ring Constraint is a kind of Constraint and maybe Ring Constraint has other-Role and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	RingConstraintOtherRoleFactTypeGuid     Guid NULL,
	-- maybe Ring Constraint is a kind of Constraint and maybe Ring Constraint has other-Role and Role fills Ordinal,
	RingConstraintOtherRoleOrdinal          shortint NULL,
	-- maybe Ring Constraint is a kind of Constraint and Ring Constraint is of Ring Type,
	RingConstraintRingType                  varchar NULL,
	-- maybe Ring Constraint is a kind of Constraint and maybe Role is of Ring Constraint and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	RingConstraintRoleFactTypeGuid          Guid NULL,
	-- maybe Ring Constraint is a kind of Constraint and maybe Role is of Ring Constraint and Role fills Ordinal,
	RingConstraintRoleOrdinal               shortint NULL,
	-- maybe Set Constraint is a kind of Constraint and maybe Set Comparison Constraint is a kind of Set Constraint and maybe Set Exclusion Constraint is a kind of Set Comparison Constraint and Set Exclusion Constraint is mandatory,
	SetExclusionConstraintIsMandatory       bit NULL,
	-- maybe Set Constraint is a kind of Constraint and maybe Subset Constraint is a kind of Set Constraint and Subset Constraint covers subset-Role Sequence and Role Sequence has Guid,
	SubsetConstraintSubsetRoleSequenceGuid  Guid NULL,
	-- maybe Set Constraint is a kind of Constraint and maybe Subset Constraint is a kind of Set Constraint and Subset Constraint covers superset-Role Sequence and Role Sequence has Guid,
	SubsetConstraintSupersetRoleSequenceGuid Guid NULL,
	-- maybe Value Constraint is a kind of Constraint and maybe Role has role-Value Constraint and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	ValueConstraintRoleFactTypeGuid         Guid NULL,
	-- maybe Value Constraint is a kind of Constraint and maybe Role has role-Value Constraint and Role fills Ordinal,
	ValueConstraintRoleOrdinal              shortint NULL,
	-- maybe Vocabulary contains Constraint and Vocabulary is called Name,
	VocabularyName                          varchar(64) NULL,
	PRIMARY KEY(ConceptGuid)
)
GO

CREATE VIEW dbo.RingConstraintInConstraint_RingConstraintRoleFactTypeGuidRingConstraintRoleOrdinal (RingConstraintRoleFactTypeGuid, RingConstraintRoleOrdinal) WITH SCHEMABINDING AS
	SELECT RingConstraintRoleFactTypeGuid, RingConstraintRoleOrdinal FROM dbo.[Constraint]
	WHERE	RingConstraintRoleFactTypeGuid IS NOT NULL
	  AND	RingConstraintRoleOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PK_RingConstraintInConstraint ON dbo.RingConstraintInConstraint_RingConstraintRoleFactTypeGuidRingConstraintRoleOrdinal(RingConstraintRoleFactTypeGuid, RingConstraintRoleOrdinal)
GO

CREATE VIEW dbo.SubsetConstraintInConstraint_SubsetConstraintSubsetRoleSequenceGuidSubsetConstraintSupersetRoleSequenceGuid (SubsetConstraintSubsetRoleSequenceGuid, SubsetConstraintSupersetRoleSequenceGuid) WITH SCHEMABINDING AS
	SELECT SubsetConstraintSubsetRoleSequenceGuid, SubsetConstraintSupersetRoleSequenceGuid FROM dbo.[Constraint]
	WHERE	SubsetConstraintSubsetRoleSequenceGuid IS NOT NULL
	  AND	SubsetConstraintSupersetRoleSequenceGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX SetConstraintMustHaveSupertypeConstraint ON dbo.SubsetConstraintInConstraint_SubsetConstraintSubsetRoleSequenceGuidSubsetConstraintSupersetRoleSequenceGuid(SubsetConstraintSubsetRoleSequenceGuid, SubsetConstraintSupersetRoleSequenceGuid)
GO

CREATE VIEW dbo.ValueConstraintInConstraint_ValueConstraintRoleFactTypeGuidValueConstraintRoleOrdinal (ValueConstraintRoleFactTypeGuid, ValueConstraintRoleOrdinal) WITH SCHEMABINDING AS
	SELECT ValueConstraintRoleFactTypeGuid, ValueConstraintRoleOrdinal FROM dbo.[Constraint]
	WHERE	ValueConstraintRoleFactTypeGuid IS NOT NULL
	  AND	ValueConstraintRoleOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueConstraintInConstraintByValueConstraintRoleFactTypeGuidValueConstraintRoleOrdinal ON dbo.ValueConstraintInConstraint_ValueConstraintRoleFactTypeGuidValueConstraintRoleOrdinal(ValueConstraintRoleFactTypeGuid, ValueConstraintRoleOrdinal)
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
	-- Context According To is where Context Note is according to Agent and Context Note is a kind of Concept and Concept has Guid,
	ContextNoteGuid                         Guid NOT NULL,
	-- maybe Context According To was lodged on Date,
	Date                                    datetime NULL,
	PRIMARY KEY(ContextNoteGuid, AgentName)
)
GO

CREATE TABLE ContextAgreedBy (
	-- Context Agreed By is where Agreement was reached by Agent and Agent has Agent Name,
	AgentName                               varchar NOT NULL,
	-- Context Agreed By is where Agreement was reached by Agent and Context Note is a kind of Concept and Concept has Guid,
	AgreementGuid                           Guid NOT NULL,
	PRIMARY KEY(AgreementGuid, AgentName)
)
GO

CREATE TABLE ContextNote (
	-- maybe Context Note was added by Agreement and maybe Agreement was on Date,
	AgreementDate                           datetime NULL,
	-- Context Note is a kind of Concept and Concept has Guid,
	ConceptGuid                             Guid NOT NULL,
	-- maybe Concept has Context Note and Concept has Guid,
	ConceptGuid                             Guid NULL,
	-- Context Note has Context Note Kind,
	ContextNoteKind                         varchar NOT NULL CHECK(ContextNoteKind = 'as_opposed_to' OR ContextNoteKind = 'because' OR ContextNoteKind = 'so_that' OR ContextNoteKind = 'to_avoid'),
	-- Context Note has Discussion,
	Discussion                              varchar NOT NULL,
	PRIMARY KEY(ConceptGuid)
)
GO

CREATE TABLE Derivation (
	-- Derivation is where Unit is derived from base-Unit and Unit is a kind of Concept and Concept has Guid,
	BaseUnitGuid                            Guid NOT NULL,
	-- Derivation is where Unit is derived from base-Unit and Unit is a kind of Concept and Concept has Guid,
	DerivedUnitGuid                         Guid NOT NULL,
	-- maybe Derivation has Exponent,
	Exponent                                shortint NULL,
	PRIMARY KEY(DerivedUnitGuid, BaseUnitGuid)
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
	-- Facet Value is where Value Type defines Facet as having Value and maybe Value is in Unit and Unit is a kind of Concept and Concept has Guid,
	ValueUnitGuid                           Guid NULL,
	PRIMARY KEY(ValueTypeVocabularyName, ValueTypeName, FacetValueTypeVocabularyName, FacetValueTypeName, FacetName)
)
GO

CREATE TABLE Fact (
	-- Fact is a kind of Concept and Concept has Guid,
	ConceptGuid                             Guid NOT NULL,
	-- Fact is of Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	FactTypeGuid                            Guid NOT NULL,
	-- Population includes Fact and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Fact and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	PRIMARY KEY(ConceptGuid)
)
GO

CREATE TABLE FactType (
	-- Fact Type is a kind of Concept and Concept has Guid,
	ConceptGuid                             Guid NOT NULL,
	-- maybe Entity Type nests Fact Type and Object Type is called Name,
	EntityTypeName                          varchar(64) NULL,
	-- maybe Entity Type nests Fact Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	EntityTypeVocabularyName                varchar(64) NULL,
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
	PRIMARY KEY(ConceptGuid)
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
	-- Instance is a kind of Concept and Concept has Guid,
	ConceptGuid                             Guid NOT NULL,
	-- maybe Instance objectifies Fact and Fact is a kind of Concept and Concept has Guid,
	FactGuid                                Guid NULL,
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
	-- maybe Instance has Value and maybe Value is in Unit and Unit is a kind of Concept and Concept has Guid,
	ValueUnitGuid                           Guid NULL,
	PRIMARY KEY(ConceptGuid),
	FOREIGN KEY (FactGuid) REFERENCES Fact (ConceptGuid)
)
GO

CREATE VIEW dbo.Instance_FactGuid (FactGuid) WITH SCHEMABINDING AS
	SELECT FactGuid FROM dbo.Instance
	WHERE	FactGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_InstanceByFactGuid ON dbo.Instance_FactGuid(FactGuid)
GO

CREATE TABLE ObjectType (
	-- Object Type is a kind of Concept and Concept has Guid,
	ConceptGuid                             Guid NOT NULL,
	-- maybe Entity Type is a kind of Object Type and Entity Type is implied by objectification,
	EntityTypeIsImpliedByObjectification    bit NULL,
	-- Object Type is independent,
	IsIndependent                           bit NOT NULL,
	-- Object Type is called Name,
	Name                                    varchar(64) NOT NULL,
	-- maybe Object Type uses Pronoun,
	Pronoun                                 varchar(20) NULL CHECK(Pronoun = 'feminine' OR Pronoun = 'masculine' OR Pronoun = 'neuter' OR Pronoun = 'personal'),
	-- maybe Value Type is a kind of Object Type and maybe Value Type has auto-- assigned Transaction Timing,
	ValueTypeAutoAssignedTransactionTiming  varchar NULL CHECK(ValueTypeAutoAssignedTransactionTiming = 'assert' OR ValueTypeAutoAssignedTransactionTiming = 'commit'),
	-- maybe Value Type is a kind of Object Type and maybe Value Type has Length,
	ValueTypeLength                         int NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type has Scale,
	ValueTypeScale                          int NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type is subtype of super-Value Type and Object Type is called Name,
	ValueTypeSupertypeName                  varchar(64) NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type is subtype of super-Value Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeSupertypeVocabularyName        varchar(64) NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type is of Unit and Unit is a kind of Concept and Concept has Guid,
	ValueTypeUnitGuid                       Guid NULL,
	-- maybe Value Type is a kind of Object Type and maybe Value Type has Value Constraint and Constraint is a kind of Concept and Concept has Guid,
	ValueTypeValueConstraintGuid            Guid NULL,
	-- Object Type belongs to Vocabulary and Vocabulary is called Name,
	VocabularyName                          varchar(64) NOT NULL,
	PRIMARY KEY(VocabularyName, Name),
	UNIQUE(ConceptGuid),
	FOREIGN KEY (ValueTypeValueConstraintGuid) REFERENCES [Constraint] (ConceptGuid),
	FOREIGN KEY (ValueTypeSupertypeName, ValueTypeSupertypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName)
)
GO

CREATE VIEW dbo.ValueTypeInObjectType_ValueTypeValueConstraintGuid (ValueTypeValueConstraintGuid) WITH SCHEMABINDING AS
	SELECT ValueTypeValueConstraintGuid FROM dbo.ObjectType
	WHERE	ValueTypeValueConstraintGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueTypeInObjectTypeByValueTypeValueConstraintGuid ON dbo.ValueTypeInObjectType_ValueTypeValueConstraintGuid(ValueTypeValueConstraintGuid)
GO

CREATE TABLE Play (
	-- Play is where Variable is restricted by Role and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	RoleFactTypeGuid                        Guid NOT NULL,
	-- Play is where Variable is restricted by Role and Role fills Ordinal,
	RoleOrdinal                             shortint NOT NULL,
	-- maybe Step involves incidental-Play and Step has input-Play and Play is where Variable is restricted by Role and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	StepInputPlayRoleFactTypeGuid           Guid NULL,
	-- maybe Step involves incidental-Play and Step has input-Play and Play is where Variable is restricted by Role and Role fills Ordinal,
	StepInputPlayRoleOrdinal                shortint NULL,
	-- maybe Step involves incidental-Play and Step has input-Play and Play is where Variable is restricted by Role and Variable has Ordinal position,
	StepInputPlayVariableOrdinal            shortint NULL,
	-- maybe Step involves incidental-Play and Step has input-Play and Play is where Variable is restricted by Role and Query includes Variable and Query is a kind of Concept and Concept has Guid,
	StepInputPlayVariableQueryGuid          Guid NULL,
	-- maybe Step involves incidental-Play and Step has output-Play and Play is where Variable is restricted by Role and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	StepOutputPlayRoleFactTypeGuid          Guid NULL,
	-- maybe Step involves incidental-Play and Step has output-Play and Play is where Variable is restricted by Role and Role fills Ordinal,
	StepOutputPlayRoleOrdinal               shortint NULL,
	-- maybe Step involves incidental-Play and Step has output-Play and Play is where Variable is restricted by Role and Variable has Ordinal position,
	StepOutputPlayVariableOrdinal           shortint NULL,
	-- maybe Step involves incidental-Play and Step has output-Play and Play is where Variable is restricted by Role and Query includes Variable and Query is a kind of Concept and Concept has Guid,
	StepOutputPlayVariableQueryGuid         Guid NULL,
	-- Play is where Variable is restricted by Role and Variable has Ordinal position,
	VariableOrdinal                         shortint NOT NULL,
	-- Play is where Variable is restricted by Role and Query includes Variable and Query is a kind of Concept and Concept has Guid,
	VariableQueryGuid                       Guid NOT NULL,
	PRIMARY KEY(VariableQueryGuid, VariableOrdinal, RoleFactTypeGuid, RoleOrdinal)
)
GO

CREATE TABLE Population (
	-- Population is a kind of Concept and Concept has Guid,
	ConceptGuid                             Guid NOT NULL,
	-- Population has Name,
	Name                                    varchar(64) NOT NULL,
	-- maybe Vocabulary includes Population and Vocabulary is called Name,
	VocabularyName                          varchar(64) NULL,
	UNIQUE(VocabularyName, Name),
	UNIQUE(ConceptGuid)
)
GO

CREATE TABLE Query (
	-- Query is a kind of Concept and Concept has Guid,
	ConceptGuid                             Guid NOT NULL,
	PRIMARY KEY(ConceptGuid)
)
GO

CREATE TABLE Reading (
	-- Fact Type has Reading and Fact Type is a kind of Concept and Concept has Guid,
	FactTypeGuid                            Guid NOT NULL,
	-- Reading is in Ordinal position,
	Ordinal                                 shortint NOT NULL,
	-- Reading is in Role Sequence and Role Sequence has Guid,
	RoleSequenceGuid                        Guid NOT NULL,
	-- Reading has Text,
	Text                                    varchar(256) NOT NULL,
	PRIMARY KEY(FactTypeGuid, Ordinal),
	FOREIGN KEY (FactTypeGuid) REFERENCES FactType (ConceptGuid)
)
GO

CREATE TABLE Role (
	-- Role is a kind of Concept and Concept has Guid,
	ConceptGuid                             Guid NOT NULL,
	-- Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	FactTypeGuid                            Guid NOT NULL,
	-- maybe Implicit Fact Type is implied by Role and Fact Type is a kind of Concept and Concept has Guid,
	ImplicitFactTypeGuid                    Guid NULL,
	-- Object Type plays Role and Object Type is called Name,
	ObjectTypeName                          varchar(64) NOT NULL,
	-- Object Type plays Role and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NOT NULL,
	-- Role fills Ordinal,
	Ordinal                                 shortint NOT NULL,
	-- maybe Role has role-Name,
	RoleName                                varchar(64) NULL,
	PRIMARY KEY(FactTypeGuid, Ordinal),
	UNIQUE(ConceptGuid),
	FOREIGN KEY (ImplicitFactTypeGuid) REFERENCES FactType (ConceptGuid),
	FOREIGN KEY (FactTypeGuid) REFERENCES FactType (ConceptGuid),
	FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName)
)
GO

CREATE VIEW dbo.Role_ImplicitFactTypeGuid (ImplicitFactTypeGuid) WITH SCHEMABINDING AS
	SELECT ImplicitFactTypeGuid FROM dbo.Role
	WHERE	ImplicitFactTypeGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleByImplicitFactTypeGuid ON dbo.Role_ImplicitFactTypeGuid(ImplicitFactTypeGuid)
GO

CREATE TABLE RoleDisplay (
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Guid,
	FactTypeShapeGuid                       Guid NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position,
	Ordinal                                 shortint NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	RoleFactTypeGuid                        Guid NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Role fills Ordinal,
	RoleOrdinal                             shortint NOT NULL,
	PRIMARY KEY(FactTypeShapeGuid, Ordinal),
	FOREIGN KEY (RoleFactTypeGuid, RoleOrdinal) REFERENCES Role (FactTypeGuid, Ordinal)
)
GO

CREATE TABLE RoleRef (
	-- maybe Role Ref has leading-Adjective,
	LeadingAdjective                        varchar(64) NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role,
	Ordinal                                 shortint NOT NULL,
	-- maybe Play projects Role Ref and Play is where Variable is restricted by Role and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	PlayRoleFactTypeGuid                    Guid NULL,
	-- maybe Play projects Role Ref and Play is where Variable is restricted by Role and Role fills Ordinal,
	PlayRoleOrdinal                         shortint NULL,
	-- maybe Play projects Role Ref and Play is where Variable is restricted by Role and Variable has Ordinal position,
	PlayVariableOrdinal                     shortint NULL,
	-- maybe Play projects Role Ref and Play is where Variable is restricted by Role and Query includes Variable and Query is a kind of Concept and Concept has Guid,
	PlayVariableQueryGuid                   Guid NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	RoleFactTypeGuid                        Guid NOT NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Role fills Ordinal,
	RoleOrdinal                             shortint NOT NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Role Sequence has Guid,
	RoleSequenceGuid                        Guid NOT NULL,
	-- maybe Role Ref has trailing-Adjective,
	TrailingAdjective                       varchar(64) NULL,
	PRIMARY KEY(RoleSequenceGuid, Ordinal),
	UNIQUE(RoleFactTypeGuid, RoleOrdinal, RoleSequenceGuid),
	FOREIGN KEY (PlayRoleFactTypeGuid, PlayRoleOrdinal, PlayVariableOrdinal, PlayVariableQueryGuid) REFERENCES Play (RoleFactTypeGuid, RoleOrdinal, VariableOrdinal, VariableQueryGuid),
	FOREIGN KEY (RoleFactTypeGuid, RoleOrdinal) REFERENCES Role (FactTypeGuid, Ordinal)
)
GO

CREATE VIEW dbo.RoleRef_PlayVariableQueryGuidPlayVariableOrdinalPlayRoleFactTypeGuidPlayRoleOrdinal (PlayVariableQueryGuid, PlayVariableOrdinal, PlayRoleFactTypeGuid, PlayRoleOrdinal) WITH SCHEMABINDING AS
	SELECT PlayVariableQueryGuid, PlayVariableOrdinal, PlayRoleFactTypeGuid, PlayRoleOrdinal FROM dbo.RoleRef
	WHERE	PlayVariableQueryGuid IS NOT NULL
	  AND	PlayVariableOrdinal IS NOT NULL
	  AND	PlayRoleFactTypeGuid IS NOT NULL
	  AND	PlayRoleOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleRefByPlayVariableQueryGuidPlayVariableOrdinalPlayRoleFactTypeGuidPlayRoleOrdinal ON dbo.RoleRef_PlayVariableQueryGuidPlayVariableOrdinalPlayRoleFactTypeGuidPlayRoleOrdinal(PlayVariableQueryGuid, PlayVariableOrdinal, PlayRoleFactTypeGuid, PlayRoleOrdinal)
GO

CREATE TABLE RoleSequence (
	-- Role Sequence has Guid,
	Guid                                    Guid NOT NULL,
	-- Role Sequence has unused dependency to force table in norma,
	HasUnusedDependencyToForceTableInNorma  bit NOT NULL,
	PRIMARY KEY(Guid)
)
GO

CREATE TABLE RoleValue (
	-- Role Value fulfils Fact and Fact is a kind of Concept and Concept has Guid,
	FactGuid                                Guid NOT NULL,
	-- Instance plays Role Value and Instance is a kind of Concept and Concept has Guid,
	InstanceGuid                            Guid NOT NULL,
	-- Population includes Role Value and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Role Value and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	-- Role Value is of Role and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	RoleFactTypeGuid                        Guid NOT NULL,
	-- Role Value is of Role and Role fills Ordinal,
	RoleOrdinal                             shortint NOT NULL,
	PRIMARY KEY(InstanceGuid, FactGuid),
	FOREIGN KEY (FactGuid) REFERENCES Fact (ConceptGuid),
	FOREIGN KEY (InstanceGuid) REFERENCES Instance (ConceptGuid),
	FOREIGN KEY (PopulationName, PopulationVocabularyName) REFERENCES Population (Name, VocabularyName),
	FOREIGN KEY (RoleFactTypeGuid, RoleOrdinal) REFERENCES Role (FactTypeGuid, Ordinal)
)
GO

CREATE TABLE SetComparisonRoles (
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence,
	Ordinal                                 shortint NOT NULL,
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence and Role Sequence has Guid,
	RoleSequenceGuid                        Guid NOT NULL,
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence and Constraint is a kind of Concept and Concept has Guid,
	SetComparisonConstraintGuid             Guid NOT NULL,
	PRIMARY KEY(SetComparisonConstraintGuid, Ordinal),
	UNIQUE(SetComparisonConstraintGuid, RoleSequenceGuid),
	FOREIGN KEY (SetComparisonConstraintGuid) REFERENCES [Constraint] (ConceptGuid),
	FOREIGN KEY (RoleSequenceGuid) REFERENCES RoleSequence (Guid)
)
GO

CREATE TABLE Shape (
	-- maybe Constraint Shape is a kind of Shape and Constraint Shape is for Constraint and Constraint is a kind of Concept and Concept has Guid,
	ConstraintShapeConstraintGuid           Guid NULL,
	-- Shape is in Diagram and Diagram is called Name,
	DiagramName                             varchar(64) NOT NULL,
	-- Shape is in Diagram and Diagram is for Vocabulary and Vocabulary is called Name,
	DiagramVocabularyName                   varchar(64) NOT NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Display Role Names Setting,
	FactTypeShapeDisplayRoleNamesSetting    varchar NULL CHECK(FactTypeShapeDisplayRoleNamesSetting = 'false' OR FactTypeShapeDisplayRoleNamesSetting = 'true'),
	-- maybe Fact Type Shape is a kind of Shape and Fact Type Shape is for Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	FactTypeShapeFactTypeGuid               Guid NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Reading Shape and Reading Shape is a kind of Shape and Shape has Guid,
	FactTypeShapeGuid                       Guid NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Objectified Fact Type Name Shape is for Fact Type Shape and Objectified Fact Type Name Shape is a kind of Shape and Shape has Guid,
	FactTypeShapeGuid                       Guid NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Reading Shape and Reading Shape is for Reading and Fact Type has Reading and Fact Type is a kind of Concept and Concept has Guid,
	FactTypeShapeReadingFactTypeGuid        Guid NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Reading Shape and Reading Shape is for Reading and Reading is in Ordinal position,
	FactTypeShapeReadingOrdinal             shortint NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Rotation Setting,
	FactTypeShapeRotationSetting            varchar NULL CHECK(FactTypeShapeRotationSetting = 'left' OR FactTypeShapeRotationSetting = 'right'),
	-- Shape has Guid,
	Guid                                    Guid NOT NULL,
	-- Shape is expanded,
	IsExpanded                              bit NOT NULL,
	-- maybe Model Note Shape is a kind of Shape and Model Note Shape is for Context Note and Context Note is a kind of Concept and Concept has Guid,
	ModelNoteShapeContextNoteGuid           Guid NULL,
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
	-- maybe Constraint Shape is a kind of Shape and maybe Ring Constraint Shape is a kind of Constraint Shape and Ring Constraint Shape is attached to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	RingConstraintShapeFactTypeGuid         Guid NULL,
	-- maybe Role Name Shape is a kind of Shape and Role Name Shape is for Role Display and Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Guid,
	RoleNameShapeRoleDisplayFactTypeShapeGuid Guid NULL,
	-- maybe Role Name Shape is a kind of Shape and Role Name Shape is for Role Display and Role Display is where Fact Type Shape displays Role in Ordinal position,
	RoleNameShapeRoleDisplayOrdinal         shortint NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Value Constraint Shape is a kind of Constraint Shape and maybe Value Constraint Shape is for Object Type Shape and Shape has Guid,
	ValueConstraintShapeObjectTypeShapeGuid Guid NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Value Constraint Shape is a kind of Constraint Shape and maybe Role Display has Value Constraint Shape and Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Guid,
	ValueConstraintShapeRoleDisplayFactTypeShapeGuid Guid NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Value Constraint Shape is a kind of Constraint Shape and maybe Role Display has Value Constraint Shape and Role Display is where Fact Type Shape displays Role in Ordinal position,
	ValueConstraintShapeRoleDisplayOrdinal  shortint NULL,
	PRIMARY KEY(Guid),
	FOREIGN KEY (ConstraintShapeConstraintGuid) REFERENCES [Constraint] (ConceptGuid),
	FOREIGN KEY (ModelNoteShapeContextNoteGuid) REFERENCES ContextNote (ConceptGuid),
	FOREIGN KEY (RingConstraintShapeFactTypeGuid) REFERENCES FactType (ConceptGuid),
	FOREIGN KEY (FactTypeShapeFactTypeGuid) REFERENCES FactType (ConceptGuid),
	FOREIGN KEY (ObjectTypeShapeObjectTypeName, ObjectTypeShapeObjectTypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName),
	FOREIGN KEY (FactTypeShapeReadingFactTypeGuid, FactTypeShapeReadingOrdinal) REFERENCES Reading (FactTypeGuid, Ordinal),
	FOREIGN KEY (ValueConstraintShapeRoleDisplayFactTypeShapeGuid, ValueConstraintShapeRoleDisplayOrdinal) REFERENCES RoleDisplay (FactTypeShapeGuid, Ordinal),
	FOREIGN KEY (RoleNameShapeRoleDisplayFactTypeShapeGuid, RoleNameShapeRoleDisplayOrdinal) REFERENCES RoleDisplay (FactTypeShapeGuid, Ordinal),
	FOREIGN KEY (ValueConstraintShapeObjectTypeShapeGuid) REFERENCES Shape (Guid),
	FOREIGN KEY (FactTypeShapeGuid) REFERENCES Shape (Guid),
	FOREIGN KEY (FactTypeShapeGuid) REFERENCES Shape (Guid)
)
GO

CREATE VIEW dbo.Shape_DiagramVocabularyNameDiagramNamePositionXPositionY (DiagramVocabularyName, DiagramName, PositionX, PositionY) WITH SCHEMABINDING AS
	SELECT DiagramVocabularyName, DiagramName, PositionX, PositionY FROM dbo.Shape
	WHERE	PositionX IS NOT NULL
	  AND	PositionY IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ShapeByDiagramVocabularyNameDiagramNamePositionXPositionY ON dbo.Shape_DiagramVocabularyNameDiagramNamePositionXPositionY(DiagramVocabularyName, DiagramName, PositionX, PositionY)
GO

CREATE VIEW dbo.ObjectifiedFactTypeNameShapeInShape_FactTypeShapeGuid (FactTypeShapeGuid) WITH SCHEMABINDING AS
	SELECT FactTypeShapeGuid FROM dbo.Shape
	WHERE	FactTypeShapeGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX ShapeMayBeAObjectifiedFactTypeNameShape ON dbo.ObjectifiedFactTypeNameShapeInShape_FactTypeShapeGuid(FactTypeShapeGuid)
GO

CREATE VIEW dbo.ReadingShapeInShape_FactTypeShapeGuid (FactTypeShapeGuid) WITH SCHEMABINDING AS
	SELECT FactTypeShapeGuid FROM dbo.Shape
	WHERE	FactTypeShapeGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX ShapeMayBeAReadingShape ON dbo.ReadingShapeInShape_FactTypeShapeGuid(FactTypeShapeGuid)
GO

CREATE VIEW dbo.RoleNameShapeInShape_RoleNameShapeRoleDisplayFactTypeShapeGuidRoleNameShapeRoleDisplayOrdinal (RoleNameShapeRoleDisplayFactTypeShapeGuid, RoleNameShapeRoleDisplayOrdinal) WITH SCHEMABINDING AS
	SELECT RoleNameShapeRoleDisplayFactTypeShapeGuid, RoleNameShapeRoleDisplayOrdinal FROM dbo.Shape
	WHERE	RoleNameShapeRoleDisplayFactTypeShapeGuid IS NOT NULL
	  AND	RoleNameShapeRoleDisplayOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleNameShapeInShapeByRoleNameShapeRoleDisplayFactTypeShapeGuidRoleNameShapeRoleDisplayOrdinal ON dbo.RoleNameShapeInShape_RoleNameShapeRoleDisplayFactTypeShapeGuidRoleNameShapeRoleDisplayOrdinal(RoleNameShapeRoleDisplayFactTypeShapeGuid, RoleNameShapeRoleDisplayOrdinal)
GO

CREATE VIEW dbo.ValueConstraintShapeInShape_ValueConstraintShapeRoleDisplayFactTypeShapeGuidValueConstraintShapeRoleDisplayOrdinal (ValueConstraintShapeRoleDisplayFactTypeShapeGuid, ValueConstraintShapeRoleDisplayOrdinal) WITH SCHEMABINDING AS
	SELECT ValueConstraintShapeRoleDisplayFactTypeShapeGuid, ValueConstraintShapeRoleDisplayOrdinal FROM dbo.Shape
	WHERE	ValueConstraintShapeRoleDisplayFactTypeShapeGuid IS NOT NULL
	  AND	ValueConstraintShapeRoleDisplayOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueConstraintShapeInShapeByValueConstraintShapeRoleDisplayFactTypeShapeGuidValueConstraintShapeRoleDisplayOrdinal ON dbo.ValueConstraintShapeInShape_ValueConstraintShapeRoleDisplayFactTypeShapeGuidValueConstraintShapeRoleDisplayOrdinal(ValueConstraintShapeRoleDisplayFactTypeShapeGuid, ValueConstraintShapeRoleDisplayOrdinal)
GO

CREATE TABLE Step (
	-- maybe Step falls under Alternative Set and Alternative Set has Guid,
	AlternativeSetGuid                      Guid NULL,
	-- Step traverses Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	FactTypeGuid                            Guid NOT NULL,
	-- Step has input-Play and Play is where Variable is restricted by Role and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	InputPlayRoleFactTypeGuid               Guid NOT NULL,
	-- Step has input-Play and Play is where Variable is restricted by Role and Role fills Ordinal,
	InputPlayRoleOrdinal                    shortint NOT NULL,
	-- Step has input-Play and Play is where Variable is restricted by Role and Variable has Ordinal position,
	InputPlayVariableOrdinal                shortint NOT NULL,
	-- Step has input-Play and Play is where Variable is restricted by Role and Query includes Variable and Query is a kind of Concept and Concept has Guid,
	InputPlayVariableQueryGuid              Guid NOT NULL,
	-- Step is disallowed,
	IsDisallowed                            bit NOT NULL,
	-- Step is optional,
	IsOptional                              bit NOT NULL,
	-- Step has output-Play and Play is where Variable is restricted by Role and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	OutputPlayRoleFactTypeGuid              Guid NOT NULL,
	-- Step has output-Play and Play is where Variable is restricted by Role and Role fills Ordinal,
	OutputPlayRoleOrdinal                   shortint NOT NULL,
	-- Step has output-Play and Play is where Variable is restricted by Role and Variable has Ordinal position,
	OutputPlayVariableOrdinal               shortint NOT NULL,
	-- Step has output-Play and Play is where Variable is restricted by Role and Query includes Variable and Query is a kind of Concept and Concept has Guid,
	OutputPlayVariableQueryGuid             Guid NOT NULL,
	PRIMARY KEY(InputPlayVariableQueryGuid, InputPlayVariableOrdinal, InputPlayRoleFactTypeGuid, InputPlayRoleOrdinal, OutputPlayVariableQueryGuid, OutputPlayVariableOrdinal, OutputPlayRoleFactTypeGuid, OutputPlayRoleOrdinal),
	FOREIGN KEY (AlternativeSetGuid) REFERENCES AlternativeSet (Guid),
	FOREIGN KEY (FactTypeGuid) REFERENCES FactType (ConceptGuid),
	FOREIGN KEY (InputPlayRoleFactTypeGuid, InputPlayRoleOrdinal, InputPlayVariableOrdinal, InputPlayVariableQueryGuid) REFERENCES Play (RoleFactTypeGuid, RoleOrdinal, VariableOrdinal, VariableQueryGuid),
	FOREIGN KEY (OutputPlayRoleFactTypeGuid, OutputPlayRoleOrdinal, OutputPlayVariableOrdinal, OutputPlayVariableQueryGuid) REFERENCES Play (RoleFactTypeGuid, RoleOrdinal, VariableOrdinal, VariableQueryGuid)
)
GO

CREATE TABLE Unit (
	-- maybe Unit has Coefficient and Coefficient has Denominator,
	CoefficientDenominator                  int NULL,
	-- maybe Unit has Coefficient and Coefficient is precise,
	CoefficientIsPrecise                    bit NULL,
	-- maybe Unit has Coefficient and Coefficient has Numerator,
	CoefficientNumerator                    decimal NULL,
	-- Unit is a kind of Concept and Concept has Guid,
	ConceptGuid                             Guid NOT NULL,
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
	-- Vocabulary includes Unit and Vocabulary is called Name,
	VocabularyName                          varchar(64) NOT NULL,
	PRIMARY KEY(ConceptGuid),
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

CREATE TABLE Variable (
	-- Variable is for Object Type and Object Type is called Name,
	ObjectTypeName                          varchar(64) NOT NULL,
	-- Variable is for Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NOT NULL,
	-- Variable has Ordinal position,
	Ordinal                                 shortint NOT NULL,
	-- maybe Variable projects Role and Role belongs to Fact Type and Fact Type is a kind of Concept and Concept has Guid,
	ProjectionFactTypeGuid                  Guid NULL,
	-- maybe Variable projects Role and Role fills Ordinal,
	ProjectionOrdinal                       shortint NULL,
	-- Query includes Variable and Query is a kind of Concept and Concept has Guid,
	QueryGuid                               Guid NOT NULL,
	-- maybe Variable has role-Name,
	RoleName                                varchar(64) NULL,
	-- maybe Variable has Subscript,
	Subscript                               shortint NULL,
	-- maybe Variable is bound to Value and Value is a string,
	ValueIsAString                          bit NULL,
	-- maybe Variable is bound to Value and Value is represented by Literal,
	ValueLiteral                            varchar NULL,
	-- maybe Variable is bound to Value and maybe Value is in Unit and Unit is a kind of Concept and Concept has Guid,
	ValueUnitGuid                           Guid NULL,
	PRIMARY KEY(QueryGuid, Ordinal),
	FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName),
	FOREIGN KEY (QueryGuid) REFERENCES Query (ConceptGuid),
	FOREIGN KEY (ProjectionFactTypeGuid, ProjectionOrdinal) REFERENCES Role (FactTypeGuid, Ordinal)
)
GO

CREATE VIEW dbo.Variable_ProjectionFactTypeGuidProjectionOrdinal (ProjectionFactTypeGuid, ProjectionOrdinal) WITH SCHEMABINDING AS
	SELECT ProjectionFactTypeGuid, ProjectionOrdinal FROM dbo.Variable
	WHERE	ProjectionFactTypeGuid IS NOT NULL
	  AND	ProjectionOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_VariableByProjectionFactTypeGuidProjectionOrdinal ON dbo.Variable_ProjectionFactTypeGuidProjectionOrdinal(ProjectionFactTypeGuid, ProjectionOrdinal)
GO

ALTER TABLE Aggregation
	ADD FOREIGN KEY (AggregatedVariableOrdinal, AggregatedVariableQueryGuid) REFERENCES Variable (Ordinal, QueryGuid)
GO

ALTER TABLE Aggregation
	ADD FOREIGN KEY (VariableOrdinal, VariableQueryGuid) REFERENCES Variable (Ordinal, QueryGuid)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueConstraintGuid) REFERENCES [Constraint] (ConceptGuid)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (RingConstraintOtherRoleFactTypeGuid, RingConstraintOtherRoleOrdinal) REFERENCES Role (FactTypeGuid, Ordinal)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (RingConstraintRoleFactTypeGuid, RingConstraintRoleOrdinal) REFERENCES Role (FactTypeGuid, Ordinal)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (ValueConstraintRoleFactTypeGuid, ValueConstraintRoleOrdinal) REFERENCES Role (FactTypeGuid, Ordinal)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (PresenceConstraintRoleSequenceGuid) REFERENCES RoleSequence (Guid)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (SubsetConstraintSubsetRoleSequenceGuid) REFERENCES RoleSequence (Guid)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (SubsetConstraintSupersetRoleSequenceGuid) REFERENCES RoleSequence (Guid)
GO

ALTER TABLE ContextAccordingTo
	ADD FOREIGN KEY (ContextNoteGuid) REFERENCES ContextNote (ConceptGuid)
GO

ALTER TABLE ContextAgreedBy
	ADD FOREIGN KEY (AgreementGuid) REFERENCES ContextNote (ConceptGuid)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (BaseUnitGuid) REFERENCES Unit (ConceptGuid)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (DerivedUnitGuid) REFERENCES Unit (ConceptGuid)
GO

ALTER TABLE FacetValue
	ADD FOREIGN KEY (ValueTypeName, ValueTypeVocabularyName) REFERENCES ObjectType (Name, VocabularyName)
GO

ALTER TABLE Fact
	ADD FOREIGN KEY (FactTypeGuid) REFERENCES FactType (ConceptGuid)
GO

ALTER TABLE Fact
	ADD FOREIGN KEY (PopulationName, PopulationVocabularyName) REFERENCES Population (Name, VocabularyName)
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

ALTER TABLE Instance
	ADD FOREIGN KEY (PopulationName, PopulationVocabularyName) REFERENCES Population (Name, VocabularyName)
GO

ALTER TABLE ObjectType
	ADD FOREIGN KEY (ValueTypeUnitGuid) REFERENCES Unit (ConceptGuid)
GO

ALTER TABLE Play
	ADD FOREIGN KEY (RoleFactTypeGuid, RoleOrdinal) REFERENCES Role (FactTypeGuid, Ordinal)
GO

ALTER TABLE Play
	ADD FOREIGN KEY (StepInputPlayRoleFactTypeGuid, StepInputPlayRoleOrdinal, StepInputPlayVariableOrdinal, StepInputPlayVariableQueryGuid, StepOutputPlayRoleFactTypeGuid, StepOutputPlayRoleOrdinal, StepOutputPlayVariableOrdinal, StepOutputPlayVariableQueryGuid) REFERENCES Step (InputPlayRoleFactTypeGuid, InputPlayRoleOrdinal, InputPlayVariableOrdinal, InputPlayVariableQueryGuid, OutputPlayRoleFactTypeGuid, OutputPlayRoleOrdinal, OutputPlayVariableOrdinal, OutputPlayVariableQueryGuid)
GO

ALTER TABLE Play
	ADD FOREIGN KEY (VariableOrdinal, VariableQueryGuid) REFERENCES Variable (Ordinal, QueryGuid)
GO

ALTER TABLE Reading
	ADD FOREIGN KEY (RoleSequenceGuid) REFERENCES RoleSequence (Guid)
GO

ALTER TABLE RoleDisplay
	ADD FOREIGN KEY (FactTypeShapeGuid) REFERENCES Shape (Guid)
GO

ALTER TABLE RoleRef
	ADD FOREIGN KEY (RoleSequenceGuid) REFERENCES RoleSequence (Guid)
GO

