CREATE TABLE Aggregation (
	-- Aggregation is where Variable is bound to Aggregate over aggregated-Variable and Aggregate has Aggregate Code,
	AggregateCode                           varchar(32) NOT NULL,
	-- Aggregation is where Variable is bound to Aggregate over aggregated-Variable and Variable has Ordinal position,
	AggregatedVariableOrdinal               smallint NOT NULL,
	-- Aggregation is where Variable is bound to Aggregate over aggregated-Variable and Query includes Variable and Concept has Guid,
	AggregatedVariableQueryGuid             uniqueidentifier NOT NULL,
	-- Aggregation is where Variable is bound to Aggregate over aggregated-Variable and Variable has Ordinal position,
	VariableOrdinal                         smallint NOT NULL,
	-- Aggregation is where Variable is bound to Aggregate over aggregated-Variable and Query includes Variable and Concept has Guid,
	VariableQueryGuid                       uniqueidentifier NOT NULL,
	PRIMARY KEY(AggregateCode, AggregatedVariableQueryGuid, AggregatedVariableOrdinal)
)
GO

CREATE TABLE AllowedRange (
	-- Allowed Range is where Value Constraint allows Value Range and Concept has Guid,
	ValueConstraintGuid                     uniqueidentifier NOT NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound is inclusive,
	ValueRangeMaximumBoundIsInclusive       bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and Value is literal string,
	ValueRangeMaximumBoundValueIsLiteralString bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMaximumBoundValueLiteral      varchar NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has maximum-Bound and Bound has Value and maybe Value is in Unit and Concept has Guid,
	ValueRangeMaximumBoundValueUnitGuid     uniqueidentifier NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound is inclusive,
	ValueRangeMinimumBoundIsInclusive       bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and Value is literal string,
	ValueRangeMinimumBoundValueIsLiteralString bit NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMinimumBoundValueLiteral      varchar NULL,
	-- Allowed Range is where Value Constraint allows Value Range and maybe Value Range has minimum-Bound and Bound has Value and maybe Value is in Unit and Concept has Guid,
	ValueRangeMinimumBoundValueUnitGuid     uniqueidentifier NULL,
	UNIQUE(ValueConstraintGuid, ValueRangeMinimumBoundValueLiteral, ValueRangeMinimumBoundValueIsLiteralString, ValueRangeMinimumBoundValueUnitGuid, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValueLiteral, ValueRangeMaximumBoundValueIsLiteralString, ValueRangeMaximumBoundValueUnitGuid, ValueRangeMaximumBoundIsInclusive)
)
GO

CREATE TABLE AlternativeSet (
	-- Alternative Set has Guid,
	Guid                                    uniqueidentifier NOT NULL,
	-- Alternative Set members are exclusive,
	MembersAreExclusive                     bit NULL,
	PRIMARY KEY(Guid)
)
GO

CREATE TABLE Concept (
	-- maybe Constraint is an instance of Concept and maybe Constraint requires Enforcement and maybe Enforcement notifies Agent and Agent has Agent Name,
	ConstraintAgentName                     varchar NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint requires Enforcement and Enforcement has Enforcement Code,
	ConstraintEnforcementCode               varchar(16) NULL,
	-- maybe Constraint is an instance of Concept and maybe Name is of Constraint,
	ConstraintName                          varchar(64) NULL,
	-- maybe Constraint is an instance of Concept and maybe Vocabulary contains Constraint and Vocabulary is called Name,
	ConstraintVocabularyName                varchar(64) NULL,
	-- maybe Context Note is an instance of Concept and maybe Context Note was added by Agreement and maybe Agreement was on Date,
	ContextNoteDate                         datetime NULL,
	-- maybe Context Note is an instance of Concept and Context Note has Discussion,
	ContextNoteDiscussion                   varchar NULL,
	-- maybe Context Note is an instance of Concept and Context Note has Context Note Kind,
	ContextNoteKind                         varchar NULL CHECK(ContextNoteKind = 'as_opposed_to' OR ContextNoteKind = 'because' OR ContextNoteKind = 'so_that' OR ContextNoteKind = 'to_avoid'),
	-- maybe Context Note is an instance of Concept and maybe Context Note applies to relevant-Concept and Concept has Guid,
	ContextNoteRelevantConceptGuid          uniqueidentifier NULL,
	-- maybe Fact is an instance of Concept and Population includes Fact and Population has Name,
	FactPopulationName                      varchar(64) NULL,
	-- maybe Fact is an instance of Concept and Population includes Fact and maybe Vocabulary includes Population and Vocabulary is called Name,
	FactPopulationVocabularyName            varchar(64) NULL,
	-- maybe Fact is an instance of Concept and Fact is of Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	FactTypeConceptGuid                     uniqueidentifier NULL,
	-- Concept has Guid,
	Guid                                    uniqueidentifier NOT NULL,
	-- maybe Concept is implied by Implication Rule and Implication Rule has Implication Rule Name,
	ImplicationRuleName                     varchar NULL,
	-- maybe Instance is an instance of Concept and maybe Instance objectifies Fact and Concept has Guid,
	InstanceFactGuid                        uniqueidentifier NULL,
	-- maybe Instance is an instance of Concept and Instance is of Object Type and Object Type is called Name,
	InstanceObjectTypeName                  varchar(64) NULL,
	-- maybe Instance is an instance of Concept and Instance is of Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	InstanceObjectTypeVocabularyName        varchar(64) NULL,
	-- maybe Instance is an instance of Concept and Population includes Instance and Population has Name,
	InstancePopulationName                  varchar(64) NULL,
	-- maybe Instance is an instance of Concept and Population includes Instance and maybe Vocabulary includes Population and Vocabulary is called Name,
	InstancePopulationVocabularyName        varchar(64) NULL,
	-- maybe Instance is an instance of Concept and maybe Instance has Value and Value is literal string,
	InstanceValueIsLiteralString            bit NULL,
	-- maybe Instance is an instance of Concept and maybe Instance has Value and Value is represented by Literal,
	InstanceValueLiteral                    varchar NULL,
	-- maybe Instance is an instance of Concept and maybe Instance has Value and maybe Value is in Unit and Concept has Guid,
	InstanceValueUnitGuid                   uniqueidentifier NULL,
	-- maybe Constraint is an instance of Concept and maybe Presence Constraint is a kind of Constraint and Presence Constraint is mandatory,
	PresenceConstraintIsMandatory           bit NULL,
	-- maybe Constraint is an instance of Concept and maybe Presence Constraint is a kind of Constraint and Presence Constraint is preferred identifier,
	PresenceConstraintIsPreferredIdentifier bit NULL,
	-- maybe Constraint is an instance of Concept and maybe Presence Constraint is a kind of Constraint and maybe Presence Constraint has max-Frequency,
	PresenceConstraintMaxFrequency          int NULL CHECK(PresenceConstraintMaxFrequency >= 1),
	-- maybe Constraint is an instance of Concept and maybe Presence Constraint is a kind of Constraint and maybe Presence Constraint has min-Frequency,
	PresenceConstraintMinFrequency          int NULL CHECK(PresenceConstraintMinFrequency >= 2),
	-- maybe Constraint is an instance of Concept and maybe Presence Constraint is a kind of Constraint and Presence Constraint covers Role Sequence and Role Sequence has Guid,
	PresenceConstraintRoleSequenceGuid      uniqueidentifier NULL,
	-- maybe Constraint is an instance of Concept and maybe Ring Constraint is a kind of Constraint and maybe Ring Constraint has other-Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RingConstraintOtherRoleFactTypeConceptGuid uniqueidentifier NULL,
	-- maybe Constraint is an instance of Concept and maybe Ring Constraint is a kind of Constraint and maybe Ring Constraint has other-Role and Role fills Ordinal,
	RingConstraintOtherRoleOrdinal          smallint NULL,
	-- maybe Constraint is an instance of Concept and maybe Ring Constraint is a kind of Constraint and Ring Constraint is of Ring Type,
	RingConstraintRingType                  varchar NULL,
	-- maybe Constraint is an instance of Concept and maybe Ring Constraint is a kind of Constraint and maybe Role is of Ring Constraint and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RingConstraintRoleFactTypeConceptGuid   uniqueidentifier NULL,
	-- maybe Constraint is an instance of Concept and maybe Ring Constraint is a kind of Constraint and maybe Role is of Ring Constraint and Role fills Ordinal,
	RingConstraintRoleOrdinal               smallint NULL,
	-- maybe Constraint is an instance of Concept and maybe Set Constraint is a kind of Constraint and maybe Set Comparison Constraint is a kind of Set Constraint and maybe Set Exclusion Constraint is a kind of Set Comparison Constraint and Set Exclusion Constraint is mandatory,
	SetExclusionConstraintIsMandatory       bit NULL,
	-- maybe Constraint is an instance of Concept and maybe Set Constraint is a kind of Constraint and maybe Subset Constraint is a kind of Set Constraint and Subset Constraint covers subset-Role Sequence and Role Sequence has Guid,
	SubsetConstraintSubsetRoleSequenceGuid  uniqueidentifier NULL,
	-- maybe Constraint is an instance of Concept and maybe Set Constraint is a kind of Constraint and maybe Subset Constraint is a kind of Set Constraint and Subset Constraint covers superset-Role Sequence and Role Sequence has Guid,
	SubsetConstraintSupersetRoleSequenceGuid uniqueidentifier NULL,
	-- maybe Unit is an instance of Concept and maybe Unit has Coefficient and Coefficient has Denominator,
	UnitCoefficientDenominator              int NULL,
	-- maybe Unit is an instance of Concept and maybe Unit has Coefficient and Coefficient is precise,
	UnitCoefficientIsPrecise                bit NULL,
	-- maybe Unit is an instance of Concept and maybe Unit has Coefficient and Coefficient has Numerator,
	UnitCoefficientNumerator                decimal NULL,
	-- maybe Unit is an instance of Concept and maybe Ephemera URL provides Unit coefficient,
	UnitEphemeraURL                         varchar NULL,
	-- maybe Unit is an instance of Concept and Unit is fundamental,
	UnitIsFundamental                       bit NULL,
	-- maybe Unit is an instance of Concept and Name is of Unit,
	UnitName                                varchar(64) NULL,
	-- maybe Unit is an instance of Concept and maybe Unit has Offset,
	UnitOffset                              decimal NULL,
	-- maybe Unit is an instance of Concept and maybe Unit has plural-Name,
	UnitPluralName                          varchar(64) NULL,
	-- maybe Unit is an instance of Concept and Vocabulary includes Unit and Vocabulary is called Name,
	UnitVocabularyName                      varchar(64) NULL,
	-- maybe Constraint is an instance of Concept and maybe Value Constraint is a kind of Constraint and maybe Value Constraint requires matching Regular Expression,
	ValueConstraintRegularExpression        varchar NULL,
	-- maybe Constraint is an instance of Concept and maybe Value Constraint is a kind of Constraint and maybe Role has role-Value Constraint and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	ValueConstraintRoleFactTypeConceptGuid  uniqueidentifier NULL,
	-- maybe Constraint is an instance of Concept and maybe Value Constraint is a kind of Constraint and maybe Role has role-Value Constraint and Role fills Ordinal,
	ValueConstraintRoleOrdinal              smallint NULL,
	PRIMARY KEY(Guid),
	FOREIGN KEY (ContextNoteRelevantConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (InstanceFactGuid) REFERENCES Concept (Guid)
)
GO

CREATE VIEW dbo.ConstraintInConcept_VocabularyNameName (ConstraintVocabularyName, ConstraintName) WITH SCHEMABINDING AS
	SELECT ConstraintVocabularyName, ConstraintName FROM dbo.Concept
	WHERE	ConstraintVocabularyName IS NOT NULL
	  AND	ConstraintName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ConstraintInConceptByConstraintVocabularyNameConstraintName ON dbo.ConstraintInConcept_VocabularyNameName(ConstraintVocabularyName, ConstraintName)
GO

CREATE VIEW dbo.InstanceInConcept_FactGuid (InstanceFactGuid) WITH SCHEMABINDING AS
	SELECT InstanceFactGuid FROM dbo.Concept
	WHERE	InstanceFactGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_InstanceInConceptByInstanceFactGuid ON dbo.InstanceInConcept_FactGuid(InstanceFactGuid)
GO

CREATE VIEW dbo.SubsetConstraintInConcept_SubsetConstraintSubsetRoleSequenceGuidSubsetConstraintSupersetRoleSequenceGuid (SubsetConstraintSubsetRoleSequenceGuid, SubsetConstraintSupersetRoleSequenceGuid) WITH SCHEMABINDING AS
	SELECT SubsetConstraintSubsetRoleSequenceGuid, SubsetConstraintSupersetRoleSequenceGuid FROM dbo.Concept
	WHERE	SubsetConstraintSubsetRoleSequenceGuid IS NOT NULL
	  AND	SubsetConstraintSupersetRoleSequenceGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX SetConstraintMustHaveSupertypeConstraint ON dbo.SubsetConstraintInConcept_SubsetConstraintSubsetRoleSequenceGuidSubsetConstraintSupersetRoleSequenceGuid(SubsetConstraintSubsetRoleSequenceGuid, SubsetConstraintSupersetRoleSequenceGuid)
GO

CREATE VIEW dbo.UnitInConcept_Name (UnitName) WITH SCHEMABINDING AS
	SELECT UnitName FROM dbo.Concept
	WHERE	UnitName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_UnitInConceptByUnitName ON dbo.UnitInConcept_Name(UnitName)
GO

CREATE VIEW dbo.UnitInConcept_PluralName (UnitPluralName) WITH SCHEMABINDING AS
	SELECT UnitPluralName FROM dbo.Concept
	WHERE	UnitPluralName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_UnitInConceptByUnitPluralName ON dbo.UnitInConcept_PluralName(UnitPluralName)
GO

CREATE VIEW dbo.UnitInConcept_VocabularyNameName (UnitVocabularyName, UnitName) WITH SCHEMABINDING AS
	SELECT UnitVocabularyName, UnitName FROM dbo.Concept
	WHERE	UnitVocabularyName IS NOT NULL
	  AND	UnitName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_UnitInConceptByUnitVocabularyNameUnitName ON dbo.UnitInConcept_VocabularyNameName(UnitVocabularyName, UnitName)
GO

CREATE VIEW dbo.ValueConstraintInConcept_ValueConstraintRoleFactTypeConceptGuidValueConstraintRoleOrdinal (ValueConstraintRoleFactTypeConceptGuid, ValueConstraintRoleOrdinal) WITH SCHEMABINDING AS
	SELECT ValueConstraintRoleFactTypeConceptGuid, ValueConstraintRoleOrdinal FROM dbo.Concept
	WHERE	ValueConstraintRoleFactTypeConceptGuid IS NOT NULL
	  AND	ValueConstraintRoleOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueConstraintInConceptByValueConstraintRoleFactTypeConceptGuidValueConstraintRoleOrdinal ON dbo.ValueConstraintInConcept_ValueConstraintRoleFactTypeConceptGuidValueConstraintRoleOrdinal(ValueConstraintRoleFactTypeConceptGuid, ValueConstraintRoleOrdinal)
GO

CREATE TABLE ContextAccordingTo (
	-- Context According To is where Context Note is according to Agent and Agent has Agent Name,
	AgentName                               varchar NOT NULL,
	-- Context According To is where Context Note is according to Agent and Concept has Guid,
	ContextNoteGuid                         uniqueidentifier NOT NULL,
	-- maybe Context According To was lodged on Date,
	Date                                    datetime NULL,
	PRIMARY KEY(ContextNoteGuid, AgentName),
	FOREIGN KEY (ContextNoteGuid) REFERENCES Concept (Guid)
)
GO

CREATE TABLE ContextAgreedBy (
	-- Context Agreed By is where Agreement was reached by Agent and Agent has Agent Name,
	AgentName                               varchar NOT NULL,
	-- Context Agreed By is where Agreement was reached by Agent and Concept has Guid,
	AgreementGuid                           uniqueidentifier NOT NULL,
	PRIMARY KEY(AgreementGuid, AgentName),
	FOREIGN KEY (AgreementGuid) REFERENCES Concept (Guid)
)
GO

CREATE TABLE Derivation (
	-- Derivation is where Unit is derived from base-Unit and Concept has Guid,
	BaseUnitGuid                            uniqueidentifier NOT NULL,
	-- Derivation is where Unit is derived from base-Unit and Concept has Guid,
	DerivedUnitGuid                         uniqueidentifier NOT NULL,
	-- maybe Derivation has Exponent,
	Exponent                                smallint NULL,
	PRIMARY KEY(DerivedUnitGuid, BaseUnitGuid),
	FOREIGN KEY (BaseUnitGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (DerivedUnitGuid) REFERENCES Concept (Guid)
)
GO

CREATE TABLE Diagram (
	-- Diagram is called Name,
	Name                                    varchar(64) NOT NULL,
	-- Diagram is for Vocabulary and Vocabulary is called Name,
	VocabularyName                          varchar(64) NOT NULL,
	PRIMARY KEY(VocabularyName, Name)
)
GO

CREATE TABLE Facet (
	-- Facet requires value of facet-Value Type and Object Type is called Name,
	FacetValueTypeName                      varchar(64) NOT NULL,
	-- Facet requires value of facet-Value Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	FacetValueTypeVocabularyName            varchar(64) NOT NULL,
	-- Facet is where Value Type has facet called Name,
	Name                                    varchar(64) NOT NULL,
	-- Facet is where Value Type has facet called Name and Object Type is called Name,
	ValueTypeName                           varchar(64) NOT NULL,
	-- Facet is where Value Type has facet called Name and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeVocabularyName                 varchar(64) NOT NULL,
	PRIMARY KEY(ValueTypeVocabularyName, ValueTypeName, Name)
)
GO

CREATE TABLE FacetRestriction (
	-- Facet Restriction is where Value Type applies Facet and Facet is where Value Type has facet called Name,
	FacetName                               varchar(64) NOT NULL,
	-- Facet Restriction is where Value Type applies Facet and Facet is where Value Type has facet called Name and Object Type is called Name,
	FacetValueTypeName                      varchar(64) NOT NULL,
	-- Facet Restriction is where Value Type applies Facet and Facet is where Value Type has facet called Name and Object Type belongs to Vocabulary and Vocabulary is called Name,
	FacetValueTypeVocabularyName            varchar(64) NOT NULL,
	-- Facet Restriction has Value and Value is literal string,
	ValueIsLiteralString                    bit NULL,
	-- Facet Restriction has Value and Value is represented by Literal,
	ValueLiteral                            varchar NOT NULL,
	-- Facet Restriction is where Value Type applies Facet and Object Type is called Name,
	ValueTypeName                           varchar(64) NOT NULL,
	-- Facet Restriction is where Value Type applies Facet and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeVocabularyName                 varchar(64) NOT NULL,
	-- Facet Restriction has Value and maybe Value is in Unit and Concept has Guid,
	ValueUnitGuid                           uniqueidentifier NULL,
	PRIMARY KEY(ValueTypeVocabularyName, ValueTypeName, FacetValueTypeVocabularyName, FacetValueTypeName, FacetName),
	FOREIGN KEY (FacetValueTypeVocabularyName, FacetValueTypeName, FacetName) REFERENCES Facet (ValueTypeVocabularyName, ValueTypeName, Name)
)
GO

CREATE TABLE FactType (
	-- Fact Type is an instance of Concept and Concept has Guid,
	ConceptGuid                             uniqueidentifier NOT NULL,
	-- maybe Entity Type nests Fact Type and Object Type is called Name,
	EntityTypeName                          varchar(64) NULL,
	-- maybe Entity Type nests Fact Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	EntityTypeVocabularyName                varchar(64) NULL,
	-- maybe Type Inheritance is a kind of Fact Type and maybe Assimilation applies to Type Inheritance,
	TypeInheritanceAssimilation             varchar NULL CHECK(TypeInheritanceAssimilation = 'absorbed' OR TypeInheritanceAssimilation = 'partitioned' OR TypeInheritanceAssimilation = 'separate'),
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
	PRIMARY KEY(ConceptGuid),
	FOREIGN KEY (ConceptGuid) REFERENCES Concept (Guid)
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

CREATE TABLE ObjectType (
	-- Object Type is an instance of Concept and Concept has Guid,
	ConceptGuid                             uniqueidentifier NOT NULL,
	-- Object Type is independent,
	IsIndependent                           bit NULL,
	-- Object Type is called Name,
	Name                                    varchar(64) NOT NULL,
	-- maybe Object Type uses Pronoun,
	Pronoun                                 varchar(20) NULL CHECK(Pronoun = 'feminine' OR Pronoun = 'masculine' OR Pronoun = 'neuter' OR Pronoun = 'personal'),
	-- maybe Domain Object Type is a kind of Object Type and maybe Value Type is a kind of Domain Object Type and maybe Value Type has Length,
	ValueTypeLength                         int NULL,
	-- maybe Domain Object Type is a kind of Object Type and maybe Value Type is a kind of Domain Object Type and maybe Value Type has Scale,
	ValueTypeScale                          int NULL,
	-- maybe Domain Object Type is a kind of Object Type and maybe Value Type is a kind of Domain Object Type and maybe Value Type is subtype of super-Value Type and Object Type is called Name,
	ValueTypeSupertypeName                  varchar(64) NULL,
	-- maybe Domain Object Type is a kind of Object Type and maybe Value Type is a kind of Domain Object Type and maybe Value Type is subtype of super-Value Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeSupertypeVocabularyName        varchar(64) NULL,
	-- maybe Domain Object Type is a kind of Object Type and maybe Value Type is a kind of Domain Object Type and maybe Value Type is auto-assigned at Transaction Phase,
	ValueTypeTransactionPhase               varchar NULL CHECK(ValueTypeTransactionPhase = 'assert' OR ValueTypeTransactionPhase = 'commit'),
	-- maybe Domain Object Type is a kind of Object Type and maybe Value Type is a kind of Domain Object Type and maybe Value Type is of Unit and Concept has Guid,
	ValueTypeUnitGuid                       uniqueidentifier NULL,
	-- maybe Domain Object Type is a kind of Object Type and maybe Value Type is a kind of Domain Object Type and maybe Value Type has Value Constraint and Concept has Guid,
	ValueTypeValueConstraintGuid            uniqueidentifier NULL,
	-- Object Type belongs to Vocabulary and Vocabulary is called Name,
	VocabularyName                          varchar(64) NOT NULL,
	PRIMARY KEY(VocabularyName, Name),
	UNIQUE(ConceptGuid),
	FOREIGN KEY (ConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (ValueTypeValueConstraintGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (ValueTypeUnitGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (ValueTypeSupertypeVocabularyName, ValueTypeSupertypeName) REFERENCES ObjectType (VocabularyName, Name)
)
GO

CREATE VIEW dbo.ValueTypeInObjectType_ValueTypeLengthValueTypeScaleValueTypeSupertypeVocabularyNameValueTypeTransactionPhaseValueTypeUni (ValueTypeLength, ValueTypeScale, ValueTypeSupertypeVocabularyName, ValueTypeTransactionPhase, ValueTypeUnitGuid, ValueTypeValueConstraintGuid, ValueTypeSupertypeName) WITH SCHEMABINDING AS
	SELECT ValueTypeLength, ValueTypeScale, ValueTypeSupertypeVocabularyName, ValueTypeTransactionPhase, ValueTypeUnitGuid, ValueTypeValueConstraintGuid, ValueTypeSupertypeName FROM dbo.ObjectType
	WHERE	ValueTypeLength IS NOT NULL
	  AND	ValueTypeScale IS NOT NULL
	  AND	ValueTypeSupertypeVocabularyName IS NOT NULL
	  AND	ValueTypeTransactionPhase IS NOT NULL
	  AND	ValueTypeUnitGuid IS NOT NULL
	  AND	ValueTypeValueConstraintGuid IS NOT NULL
	  AND	ValueTypeSupertypeName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX DomainObjectTypeMustHaveSupertypeObjectType ON dbo.ValueTypeInObjectType_ValueTypeLengthValueTypeScaleValueTypeSupertypeVocabularyNameValueTypeTransactionPhaseValueTypeUni(ValueTypeLength, ValueTypeScale, ValueTypeSupertypeVocabularyName, ValueTypeTransactionPhase, ValueTypeUnitGuid, ValueTypeValueConstraintGuid, ValueTypeSupertypeName)
GO

CREATE VIEW dbo.ValueTypeInObjectType_ValueTypeValueConstraintGuid (ValueTypeValueConstraintGuid) WITH SCHEMABINDING AS
	SELECT ValueTypeValueConstraintGuid FROM dbo.ObjectType
	WHERE	ValueTypeValueConstraintGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueTypeInObjectTypeByValueTypeValueConstraintGuid ON dbo.ValueTypeInObjectType_ValueTypeValueConstraintGuid(ValueTypeValueConstraintGuid)
GO

CREATE TABLE Play (
	-- Play is where Variable is restricted by Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RoleFactTypeConceptGuid                 uniqueidentifier NOT NULL,
	-- Play is where Variable is restricted by Role and Role fills Ordinal,
	RoleOrdinal                             smallint NOT NULL,
	-- maybe Step involves incidental-Play and Step has input-Play and Play is where Variable is restricted by Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	StepInputPlayRoleFactTypeConceptGuid    uniqueidentifier NULL,
	-- maybe Step involves incidental-Play and Step has input-Play and Play is where Variable is restricted by Role and Role fills Ordinal,
	StepInputPlayRoleOrdinal                smallint NULL,
	-- maybe Step involves incidental-Play and Step has input-Play and Play is where Variable is restricted by Role and Variable has Ordinal position,
	StepInputPlayVariableOrdinal            smallint NULL,
	-- maybe Step involves incidental-Play and Step has input-Play and Play is where Variable is restricted by Role and Query includes Variable and Concept has Guid,
	StepInputPlayVariableQueryGuid          uniqueidentifier NULL,
	-- maybe Step involves incidental-Play and maybe Step has output-Play and Play is where Variable is restricted by Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	StepOutputPlayRoleFactTypeConceptGuid   uniqueidentifier NULL,
	-- maybe Step involves incidental-Play and maybe Step has output-Play and Play is where Variable is restricted by Role and Role fills Ordinal,
	StepOutputPlayRoleOrdinal               smallint NULL,
	-- maybe Step involves incidental-Play and maybe Step has output-Play and Play is where Variable is restricted by Role and Variable has Ordinal position,
	StepOutputPlayVariableOrdinal           smallint NULL,
	-- maybe Step involves incidental-Play and maybe Step has output-Play and Play is where Variable is restricted by Role and Query includes Variable and Concept has Guid,
	StepOutputPlayVariableQueryGuid         uniqueidentifier NULL,
	-- Play is where Variable is restricted by Role and Variable has Ordinal position,
	VariableOrdinal                         smallint NOT NULL,
	-- Play is where Variable is restricted by Role and Query includes Variable and Concept has Guid,
	VariableQueryGuid                       uniqueidentifier NOT NULL,
	PRIMARY KEY(VariableQueryGuid, VariableOrdinal, RoleFactTypeConceptGuid, RoleOrdinal)
)
GO

CREATE TABLE Population (
	-- Population is an instance of Concept and Concept has Guid,
	ConceptGuid                             uniqueidentifier NOT NULL,
	-- Population has Name,
	Name                                    varchar(64) NOT NULL,
	-- maybe Vocabulary includes Population and Vocabulary is called Name,
	VocabularyName                          varchar(64) NULL,
	UNIQUE(VocabularyName, Name),
	UNIQUE(ConceptGuid),
	FOREIGN KEY (ConceptGuid) REFERENCES Concept (Guid)
)
GO

CREATE TABLE Reading (
	-- Fact Type has Reading and Fact Type is an instance of Concept and Concept has Guid,
	FactTypeConceptGuid                     uniqueidentifier NOT NULL,
	-- Reading is negative,
	IsNegative                              bit NULL,
	-- Reading is in Ordinal position,
	Ordinal                                 smallint NOT NULL,
	-- Reading is in Role Sequence and Role Sequence has Guid,
	RoleSequenceGuid                        uniqueidentifier NOT NULL,
	-- Reading has Text,
	Text                                    varchar(256) NOT NULL,
	PRIMARY KEY(FactTypeConceptGuid, Ordinal),
	FOREIGN KEY (FactTypeConceptGuid) REFERENCES FactType (ConceptGuid)
)
GO

CREATE TABLE Role (
	-- Role is an instance of Concept and Concept has Guid,
	ConceptGuid                             uniqueidentifier NOT NULL,
	-- Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	FactTypeConceptGuid                     uniqueidentifier NOT NULL,
	-- maybe Link Fact Type is for Role and Fact Type is an instance of Concept and Concept has Guid,
	LinkFactTypeConceptGuid                 uniqueidentifier NULL,
	-- Object Type plays Role and Object Type is called Name,
	ObjectTypeName                          varchar(64) NOT NULL,
	-- Object Type plays Role and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NOT NULL,
	-- Role fills Ordinal,
	Ordinal                                 smallint NOT NULL,
	-- maybe Role has role-Name,
	RoleName                                varchar(64) NULL,
	PRIMARY KEY(FactTypeConceptGuid, Ordinal),
	UNIQUE(ConceptGuid),
	FOREIGN KEY (ConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (LinkFactTypeConceptGuid) REFERENCES FactType (ConceptGuid),
	FOREIGN KEY (FactTypeConceptGuid) REFERENCES FactType (ConceptGuid),
	FOREIGN KEY (ObjectTypeVocabularyName, ObjectTypeName) REFERENCES ObjectType (VocabularyName, Name)
)
GO

CREATE VIEW dbo.Role_LinkFactTypeConceptGuid (LinkFactTypeConceptGuid) WITH SCHEMABINDING AS
	SELECT LinkFactTypeConceptGuid FROM dbo.Role
	WHERE	LinkFactTypeConceptGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleByLinkFactTypeConceptGuid ON dbo.Role_LinkFactTypeConceptGuid(LinkFactTypeConceptGuid)
GO

CREATE TABLE RoleDisplay (
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Guid,
	FactTypeShapeGuid                       uniqueidentifier NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position,
	Ordinal                                 smallint NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RoleFactTypeConceptGuid                 uniqueidentifier NOT NULL,
	-- Role Display is where Fact Type Shape displays Role in Ordinal position and Role fills Ordinal,
	RoleOrdinal                             smallint NOT NULL,
	PRIMARY KEY(FactTypeShapeGuid, Ordinal),
	FOREIGN KEY (RoleFactTypeConceptGuid, RoleOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal)
)
GO

CREATE TABLE RoleRef (
	-- maybe Role Ref has leading-Adjective,
	LeadingAdjective                        varchar(64) NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role,
	Ordinal                                 smallint NOT NULL,
	-- maybe Play projects Role Ref and Play is where Variable is restricted by Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	PlayRoleFactTypeConceptGuid             uniqueidentifier NULL,
	-- maybe Play projects Role Ref and Play is where Variable is restricted by Role and Role fills Ordinal,
	PlayRoleOrdinal                         smallint NULL,
	-- maybe Play projects Role Ref and Play is where Variable is restricted by Role and Variable has Ordinal position,
	PlayVariableOrdinal                     smallint NULL,
	-- maybe Play projects Role Ref and Play is where Variable is restricted by Role and Query includes Variable and Concept has Guid,
	PlayVariableQueryGuid                   uniqueidentifier NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RoleFactTypeConceptGuid                 uniqueidentifier NOT NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Role fills Ordinal,
	RoleOrdinal                             smallint NOT NULL,
	-- Role Ref is where Role Sequence in Ordinal position includes Role and Role Sequence has Guid,
	RoleSequenceGuid                        uniqueidentifier NOT NULL,
	-- maybe Role Ref has trailing-Adjective,
	TrailingAdjective                       varchar(64) NULL,
	PRIMARY KEY(RoleSequenceGuid, Ordinal),
	UNIQUE(RoleFactTypeConceptGuid, RoleOrdinal, RoleSequenceGuid),
	FOREIGN KEY (PlayVariableQueryGuid, PlayVariableOrdinal, PlayRoleFactTypeConceptGuid, PlayRoleOrdinal) REFERENCES Play (VariableQueryGuid, VariableOrdinal, RoleFactTypeConceptGuid, RoleOrdinal),
	FOREIGN KEY (RoleFactTypeConceptGuid, RoleOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal)
)
GO

CREATE VIEW dbo.RoleRef_PlayVariableQueryGuidPlayVariableOrdinalPlayRoleFactTypeConceptGuidPlayRoleOrdinal (PlayVariableQueryGuid, PlayVariableOrdinal, PlayRoleFactTypeConceptGuid, PlayRoleOrdinal) WITH SCHEMABINDING AS
	SELECT PlayVariableQueryGuid, PlayVariableOrdinal, PlayRoleFactTypeConceptGuid, PlayRoleOrdinal FROM dbo.RoleRef
	WHERE	PlayVariableQueryGuid IS NOT NULL
	  AND	PlayVariableOrdinal IS NOT NULL
	  AND	PlayRoleFactTypeConceptGuid IS NOT NULL
	  AND	PlayRoleOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleRefByPlayVariableQueryGuidPlayVariableOrdinalPlayRoleFactTypeConceptGuidPlayRoleOrdinal ON dbo.RoleRef_PlayVariableQueryGuidPlayVariableOrdinalPlayRoleFactTypeConceptGuidPlayRoleOrdinal(PlayVariableQueryGuid, PlayVariableOrdinal, PlayRoleFactTypeConceptGuid, PlayRoleOrdinal)
GO

CREATE TABLE RoleSequence (
	-- Role Sequence has Guid,
	Guid                                    uniqueidentifier NOT NULL,
	-- Role Sequence has unused dependency to force table in norma,
	HasUnusedDependencyToForceTableInNorma  bit NULL,
	PRIMARY KEY(Guid)
)
GO

CREATE TABLE RoleValue (
	-- Role Value fulfils Fact and Concept has Guid,
	FactGuid                                uniqueidentifier NOT NULL,
	-- Instance plays Role Value and Concept has Guid,
	InstanceGuid                            uniqueidentifier NOT NULL,
	-- Population includes Role Value and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Role Value and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	-- Role Value is of Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RoleFactTypeConceptGuid                 uniqueidentifier NOT NULL,
	-- Role Value is of Role and Role fills Ordinal,
	RoleOrdinal                             smallint NOT NULL,
	PRIMARY KEY(FactGuid, RoleFactTypeConceptGuid, RoleOrdinal),
	FOREIGN KEY (FactGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (InstanceGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (PopulationVocabularyName, PopulationName) REFERENCES Population (VocabularyName, Name),
	FOREIGN KEY (RoleFactTypeConceptGuid, RoleOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal)
)
GO

CREATE TABLE SetComparisonRoles (
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence,
	Ordinal                                 smallint NOT NULL,
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence and Role Sequence has Guid,
	RoleSequenceGuid                        uniqueidentifier NOT NULL,
	-- Set Comparison Roles is where Set Comparison Constraint has in Ordinal position Role Sequence and Concept has Guid,
	SetComparisonConstraintGuid             uniqueidentifier NOT NULL,
	PRIMARY KEY(SetComparisonConstraintGuid, Ordinal),
	UNIQUE(SetComparisonConstraintGuid, RoleSequenceGuid),
	FOREIGN KEY (SetComparisonConstraintGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (RoleSequenceGuid) REFERENCES RoleSequence (Guid)
)
GO

CREATE TABLE Shape (
	-- maybe Constraint Shape is a kind of Shape and Constraint Shape is for Constraint and Concept has Guid,
	ConstraintShapeConstraintGuid           uniqueidentifier NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Display Role Names Setting,
	FactTypeShapeDisplayRoleNamesSetting    varchar NULL CHECK(FactTypeShapeDisplayRoleNamesSetting = 'false' OR FactTypeShapeDisplayRoleNamesSetting = 'true'),
	-- maybe Fact Type Shape is a kind of Shape and Fact Type Shape is for Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	FactTypeShapeFactTypeConceptGuid        uniqueidentifier NULL,
	-- maybe Fact Type Shape is a kind of Shape and maybe Fact Type Shape has Rotation Setting,
	FactTypeShapeRotationSetting            varchar NULL CHECK(FactTypeShapeRotationSetting = 'left' OR FactTypeShapeRotationSetting = 'right'),
	-- Shape has Guid,
	Guid                                    uniqueidentifier NOT NULL,
	-- Shape is expanded,
	IsExpanded                              bit NULL,
	-- maybe Shape is at Location and Location is at X,
	LocationX                               int NULL,
	-- maybe Shape is at Location and Location is at Y,
	LocationY                               int NULL,
	-- maybe Model Note Shape is a kind of Shape and Model Note Shape is for Context Note and Concept has Guid,
	ModelNoteShapeContextNoteGuid           uniqueidentifier NULL,
	-- Shape is in ORM Diagram and Diagram is called Name,
	ORMDiagramName                          varchar(64) NOT NULL,
	-- Shape is in ORM Diagram and Diagram is for Vocabulary and Vocabulary is called Name,
	ORMDiagramVocabularyName                varchar(64) NOT NULL,
	-- maybe Object Type Shape is a kind of Shape and Object Type Shape has expanded reference mode,
	ObjectTypeShapeHasExpandedReferenceMode bit NULL,
	-- maybe Object Type Shape is a kind of Shape and Object Type Shape is for Object Type and Object Type is called Name,
	ObjectTypeShapeObjectTypeName           varchar(64) NULL,
	-- maybe Object Type Shape is a kind of Shape and Object Type Shape is for Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ObjectTypeShapeObjectTypeVocabularyName varchar(64) NULL,
	-- maybe Objectified Fact Type Name Shape is a kind of Shape and Objectified Fact Type Name Shape is for Fact Type Shape and Shape has Guid,
	ObjectifiedFactTypeNameShapeFactTypeShapeGuid uniqueidentifier NULL,
	-- maybe Reading Shape is a kind of Shape and Fact Type Shape has Reading Shape and Shape has Guid,
	ReadingShapeFactTypeShapeGuid           uniqueidentifier NULL,
	-- maybe Reading Shape is a kind of Shape and Reading Shape is for Reading and Fact Type has Reading and Fact Type is an instance of Concept and Concept has Guid,
	ReadingShapeReadingFactTypeConceptGuid  uniqueidentifier NULL,
	-- maybe Reading Shape is a kind of Shape and Reading Shape is for Reading and Reading is in Ordinal position,
	ReadingShapeReadingOrdinal              smallint NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Ring Constraint Shape is a kind of Constraint Shape and Ring Constraint Shape is attached to Fact Type Shape and Shape has Guid,
	RingConstraintShapeFactTypeShapeGuid    uniqueidentifier NULL,
	-- maybe Role Name Shape is a kind of Shape and Role Name Shape is for Role Display and Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Guid,
	RoleNameShapeRoleDisplayFactTypeShapeGuid uniqueidentifier NULL,
	-- maybe Role Name Shape is a kind of Shape and Role Name Shape is for Role Display and Role Display is where Fact Type Shape displays Role in Ordinal position,
	RoleNameShapeRoleDisplayOrdinal         smallint NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Value Constraint Shape is a kind of Constraint Shape and maybe Value Constraint Shape is for Object Type Shape and Shape has Guid,
	ValueConstraintShapeObjectTypeShapeGuid uniqueidentifier NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Value Constraint Shape is a kind of Constraint Shape and maybe Role Display has Value Constraint Shape and Role Display is where Fact Type Shape displays Role in Ordinal position and Shape has Guid,
	ValueConstraintShapeRoleDisplayFactTypeShapeGuid uniqueidentifier NULL,
	-- maybe Constraint Shape is a kind of Shape and maybe Value Constraint Shape is a kind of Constraint Shape and maybe Role Display has Value Constraint Shape and Role Display is where Fact Type Shape displays Role in Ordinal position,
	ValueConstraintShapeRoleDisplayOrdinal  smallint NULL,
	PRIMARY KEY(Guid),
	FOREIGN KEY (ConstraintShapeConstraintGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (ModelNoteShapeContextNoteGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (ORMDiagramVocabularyName, ORMDiagramName) REFERENCES Diagram (VocabularyName, Name),
	FOREIGN KEY (FactTypeShapeFactTypeConceptGuid) REFERENCES FactType (ConceptGuid),
	FOREIGN KEY (ObjectTypeShapeObjectTypeVocabularyName, ObjectTypeShapeObjectTypeName) REFERENCES ObjectType (VocabularyName, Name),
	FOREIGN KEY (ReadingShapeReadingFactTypeConceptGuid, ReadingShapeReadingOrdinal) REFERENCES Reading (FactTypeConceptGuid, Ordinal),
	FOREIGN KEY (ValueConstraintShapeRoleDisplayFactTypeShapeGuid, ValueConstraintShapeRoleDisplayOrdinal) REFERENCES RoleDisplay (FactTypeShapeGuid, Ordinal),
	FOREIGN KEY (RoleNameShapeRoleDisplayFactTypeShapeGuid, RoleNameShapeRoleDisplayOrdinal) REFERENCES RoleDisplay (FactTypeShapeGuid, Ordinal),
	FOREIGN KEY (RingConstraintShapeFactTypeShapeGuid) REFERENCES Shape (Guid),
	FOREIGN KEY (ValueConstraintShapeObjectTypeShapeGuid) REFERENCES Shape (Guid),
	FOREIGN KEY (ObjectifiedFactTypeNameShapeFactTypeShapeGuid) REFERENCES Shape (Guid),
	FOREIGN KEY (ReadingShapeFactTypeShapeGuid) REFERENCES Shape (Guid)
)
GO

CREATE VIEW dbo.Shape_ORMDiagramVocabularyNameORMDiagramNameLocationXLocationY (ORMDiagramVocabularyName, ORMDiagramName, LocationX, LocationY) WITH SCHEMABINDING AS
	SELECT ORMDiagramVocabularyName, ORMDiagramName, LocationX, LocationY FROM dbo.Shape
	WHERE	LocationX IS NOT NULL
	  AND	LocationY IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ShapeByORMDiagramVocabularyNameORMDiagramNameLocationXLocationY ON dbo.Shape_ORMDiagramVocabularyNameORMDiagramNameLocationXLocationY(ORMDiagramVocabularyName, ORMDiagramName, LocationX, LocationY)
GO

CREATE VIEW dbo.ObjectifiedFactTypeNameShapeInShape_ObjectifiedFactTypeNameShapeFactTypeShapeGuid (ObjectifiedFactTypeNameShapeFactTypeShapeGuid) WITH SCHEMABINDING AS
	SELECT ObjectifiedFactTypeNameShapeFactTypeShapeGuid FROM dbo.Shape
	WHERE	ObjectifiedFactTypeNameShapeFactTypeShapeGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ObjectifiedFactTypeNameShapeInShapeByObjectifiedFactTypeNameShapeFactTypeShapeGuid ON dbo.ObjectifiedFactTypeNameShapeInShape_ObjectifiedFactTypeNameShapeFactTypeShapeGuid(ObjectifiedFactTypeNameShapeFactTypeShapeGuid)
GO

CREATE VIEW dbo.ReadingShapeInShape_ReadingShapeFactTypeShapeGuid (ReadingShapeFactTypeShapeGuid) WITH SCHEMABINDING AS
	SELECT ReadingShapeFactTypeShapeGuid FROM dbo.Shape
	WHERE	ReadingShapeFactTypeShapeGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ReadingShapeInShapeByReadingShapeFactTypeShapeGuid ON dbo.ReadingShapeInShape_ReadingShapeFactTypeShapeGuid(ReadingShapeFactTypeShapeGuid)
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
	AlternativeSetGuid                      uniqueidentifier NULL,
	-- Step specifies Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	FactTypeConceptGuid                     uniqueidentifier NOT NULL,
	-- Step has input-Play and Play is where Variable is restricted by Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	InputPlayRoleFactTypeConceptGuid        uniqueidentifier NOT NULL,
	-- Step has input-Play and Play is where Variable is restricted by Role and Role fills Ordinal,
	InputPlayRoleOrdinal                    smallint NOT NULL,
	-- Step has input-Play and Play is where Variable is restricted by Role and Variable has Ordinal position,
	InputPlayVariableOrdinal                smallint NOT NULL,
	-- Step has input-Play and Play is where Variable is restricted by Role and Query includes Variable and Concept has Guid,
	InputPlayVariableQueryGuid              uniqueidentifier NOT NULL,
	-- Step is disallowed,
	IsDisallowed                            bit NULL,
	-- Step is optional,
	IsOptional                              bit NULL,
	-- maybe Step has output-Play and Play is where Variable is restricted by Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	OutputPlayRoleFactTypeConceptGuid       uniqueidentifier NULL,
	-- maybe Step has output-Play and Play is where Variable is restricted by Role and Role fills Ordinal,
	OutputPlayRoleOrdinal                   smallint NULL,
	-- maybe Step has output-Play and Play is where Variable is restricted by Role and Variable has Ordinal position,
	OutputPlayVariableOrdinal               smallint NULL,
	-- maybe Step has output-Play and Play is where Variable is restricted by Role and Query includes Variable and Concept has Guid,
	OutputPlayVariableQueryGuid             uniqueidentifier NULL,
	UNIQUE(InputPlayVariableQueryGuid, InputPlayVariableOrdinal, InputPlayRoleFactTypeConceptGuid, InputPlayRoleOrdinal, OutputPlayVariableQueryGuid, OutputPlayVariableOrdinal, OutputPlayRoleFactTypeConceptGuid, OutputPlayRoleOrdinal),
	FOREIGN KEY (AlternativeSetGuid) REFERENCES AlternativeSet (Guid),
	FOREIGN KEY (FactTypeConceptGuid) REFERENCES FactType (ConceptGuid),
	FOREIGN KEY (InputPlayVariableQueryGuid, InputPlayVariableOrdinal, InputPlayRoleFactTypeConceptGuid, InputPlayRoleOrdinal) REFERENCES Play (VariableQueryGuid, VariableOrdinal, RoleFactTypeConceptGuid, RoleOrdinal),
	FOREIGN KEY (OutputPlayVariableQueryGuid, OutputPlayVariableOrdinal, OutputPlayRoleFactTypeConceptGuid, OutputPlayRoleOrdinal) REFERENCES Play (VariableQueryGuid, VariableOrdinal, RoleFactTypeConceptGuid, RoleOrdinal)
)
GO

CREATE TABLE Value (
	-- Value is literal string,
	IsLiteralString                         bit NULL,
	-- Value is represented by Literal,
	Literal                                 varchar NOT NULL,
	-- maybe Value is in Unit and Concept has Guid,
	UnitGuid                                uniqueidentifier NULL,
	-- Value is of Value Type and Object Type is called Name,
	ValueTypeName                           varchar(64) NOT NULL,
	-- Value is of Value Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeVocabularyName                 varchar(64) NOT NULL,
	UNIQUE(Literal, IsLiteralString, UnitGuid),
	FOREIGN KEY (UnitGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (ValueTypeVocabularyName, ValueTypeName) REFERENCES ObjectType (VocabularyName, Name)
)
GO

CREATE TABLE Variable (
	-- Variable is for Object Type and Object Type is called Name,
	ObjectTypeName                          varchar(64) NOT NULL,
	-- Variable is for Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NOT NULL,
	-- Variable has Ordinal position,
	Ordinal                                 smallint NOT NULL,
	-- maybe Variable projects Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	ProjectionFactTypeConceptGuid           uniqueidentifier NULL,
	-- maybe Variable projects Role and Role fills Ordinal,
	ProjectionOrdinal                       smallint NULL,
	-- Query includes Variable and Concept has Guid,
	QueryGuid                               uniqueidentifier NOT NULL,
	-- maybe Variable has role-Name,
	RoleName                                varchar(64) NULL,
	-- maybe Variable has Subscript,
	Subscript                               smallint NULL,
	-- maybe Variable is bound to Value and Value is literal string,
	ValueIsLiteralString                    bit NULL,
	-- maybe Variable is bound to Value and Value is represented by Literal,
	ValueLiteral                            varchar NULL,
	-- maybe Variable is bound to Value and maybe Value is in Unit and Concept has Guid,
	ValueUnitGuid                           uniqueidentifier NULL,
	PRIMARY KEY(QueryGuid, Ordinal),
	FOREIGN KEY (QueryGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (ObjectTypeVocabularyName, ObjectTypeName) REFERENCES ObjectType (VocabularyName, Name),
	FOREIGN KEY (ProjectionFactTypeConceptGuid, ProjectionOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal),
	FOREIGN KEY (ValueLiteral, ValueIsLiteralString, ValueUnitGuid) REFERENCES Value (Literal, IsLiteralString, UnitGuid)
)
GO

CREATE VIEW dbo.Variable_ProjectionFactTypeConceptGuidProjectionOrdinal (ProjectionFactTypeConceptGuid, ProjectionOrdinal) WITH SCHEMABINDING AS
	SELECT ProjectionFactTypeConceptGuid, ProjectionOrdinal FROM dbo.Variable
	WHERE	ProjectionFactTypeConceptGuid IS NOT NULL
	  AND	ProjectionOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_VariableByProjectionFactTypeConceptGuidProjectionOrdinal ON dbo.Variable_ProjectionFactTypeConceptGuidProjectionOrdinal(ProjectionFactTypeConceptGuid, ProjectionOrdinal)
GO

ALTER TABLE Aggregation
	ADD FOREIGN KEY (AggregatedVariableQueryGuid, AggregatedVariableOrdinal) REFERENCES Variable (QueryGuid, Ordinal)
GO

ALTER TABLE Aggregation
	ADD FOREIGN KEY (VariableQueryGuid, VariableOrdinal) REFERENCES Variable (QueryGuid, Ordinal)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueConstraintGuid) REFERENCES Concept (Guid)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueRangeMaximumBoundValueLiteral, ValueRangeMaximumBoundValueIsLiteralString, ValueRangeMaximumBoundValueUnitGuid) REFERENCES Value (Literal, IsLiteralString, UnitGuid)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueRangeMinimumBoundValueLiteral, ValueRangeMinimumBoundValueIsLiteralString, ValueRangeMinimumBoundValueUnitGuid) REFERENCES Value (Literal, IsLiteralString, UnitGuid)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (FactTypeConceptGuid) REFERENCES FactType (ConceptGuid)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (InstanceObjectTypeVocabularyName, InstanceObjectTypeName) REFERENCES ObjectType (VocabularyName, Name)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (FactPopulationVocabularyName, FactPopulationName) REFERENCES Population (VocabularyName, Name)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (InstancePopulationVocabularyName, InstancePopulationName) REFERENCES Population (VocabularyName, Name)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (RingConstraintOtherRoleFactTypeConceptGuid, RingConstraintOtherRoleOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (RingConstraintRoleFactTypeConceptGuid, RingConstraintRoleOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (ValueConstraintRoleFactTypeConceptGuid, ValueConstraintRoleOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (PresenceConstraintRoleSequenceGuid) REFERENCES RoleSequence (Guid)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (SubsetConstraintSubsetRoleSequenceGuid) REFERENCES RoleSequence (Guid)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (SubsetConstraintSupersetRoleSequenceGuid) REFERENCES RoleSequence (Guid)
GO

ALTER TABLE Concept
	ADD FOREIGN KEY (InstanceValueLiteral, InstanceValueIsLiteralString, InstanceValueUnitGuid) REFERENCES Value (Literal, IsLiteralString, UnitGuid)
GO

ALTER TABLE Facet
	ADD FOREIGN KEY (FacetValueTypeVocabularyName, FacetValueTypeName) REFERENCES ObjectType (VocabularyName, Name)
GO

ALTER TABLE Facet
	ADD FOREIGN KEY (ValueTypeVocabularyName, ValueTypeName) REFERENCES ObjectType (VocabularyName, Name)
GO

ALTER TABLE FacetRestriction
	ADD FOREIGN KEY (ValueTypeVocabularyName, ValueTypeName) REFERENCES ObjectType (VocabularyName, Name)
GO

ALTER TABLE FacetRestriction
	ADD FOREIGN KEY (ValueLiteral, ValueIsLiteralString, ValueUnitGuid) REFERENCES Value (Literal, IsLiteralString, UnitGuid)
GO

ALTER TABLE FactType
	ADD FOREIGN KEY (EntityTypeVocabularyName, EntityTypeName) REFERENCES ObjectType (VocabularyName, Name)
GO

ALTER TABLE FactType
	ADD FOREIGN KEY (TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName) REFERENCES ObjectType (VocabularyName, Name)
GO

ALTER TABLE FactType
	ADD FOREIGN KEY (TypeInheritanceSupertypeVocabularyName, TypeInheritanceSupertypeName) REFERENCES ObjectType (VocabularyName, Name)
GO

ALTER TABLE Play
	ADD FOREIGN KEY (RoleFactTypeConceptGuid, RoleOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal)
GO

ALTER TABLE Play
	ADD FOREIGN KEY (StepInputPlayVariableQueryGuid, StepInputPlayVariableOrdinal, StepInputPlayRoleFactTypeConceptGuid, StepInputPlayRoleOrdinal, StepOutputPlayVariableQueryGuid, StepOutputPlayVariableOrdinal, StepOutputPlayRoleFactTypeConceptGuid, StepOutputPlayRoleOrdinal) REFERENCES Step (InputPlayVariableQueryGuid, InputPlayVariableOrdinal, InputPlayRoleFactTypeConceptGuid, InputPlayRoleOrdinal, OutputPlayVariableQueryGuid, OutputPlayVariableOrdinal, OutputPlayRoleFactTypeConceptGuid, OutputPlayRoleOrdinal)
GO

ALTER TABLE Play
	ADD FOREIGN KEY (VariableQueryGuid, VariableOrdinal) REFERENCES Variable (QueryGuid, Ordinal)
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

