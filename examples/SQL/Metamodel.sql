CREATE TABLE Aggregation (
	-- Aggregation (in which Variable is bound to Aggregate over aggregated-Variable) and Aggregate has Aggregate Code,
	AggregateCode                           varchar(32) NOT NULL,
	-- Aggregation (in which Variable is bound to Aggregate over aggregated-Variable) and Variable has Ordinal position,
	AggregatedVariableOrdinal               smallint NOT NULL,
	-- Aggregation (in which Variable is bound to Aggregate over aggregated-Variable) and Variable is in Query and Query is an instance of Concept and Concept has Guid,
	AggregatedVariableQueryConceptGuid      uniqueidentifier NOT NULL,
	-- Aggregation (in which Variable is bound to Aggregate over aggregated-Variable) and Variable has Ordinal position,
	VariableOrdinal                         smallint NOT NULL,
	-- Aggregation (in which Variable is bound to Aggregate over aggregated-Variable) and Variable is in Query and Query is an instance of Concept and Concept has Guid,
	VariableQueryConceptGuid                uniqueidentifier NOT NULL,
	PRIMARY KEY(AggregateCode, AggregatedVariableQueryConceptGuid, AggregatedVariableOrdinal)
)
GO

CREATE TABLE AllowedRange (
	-- Allowed Range (in which Value Constraint allows Value Range) and Value Constraint is a kind of Constraint and Constraint is an instance of Concept and Concept has Guid,
	ValueConstraintConceptGuid              uniqueidentifier NOT NULL,
	-- Allowed Range (in which Value Constraint allows Value Range) and maybe Value Range has maximum-Bound and Bound is inclusive,
	ValueRangeMaximumBoundIsInclusive       bit NULL,
	-- Allowed Range (in which Value Constraint allows Value Range) and maybe Value Range has maximum-Bound and Bound has Value and Value is literal string,
	ValueRangeMaximumBoundValueIsLiteralString bit NULL,
	-- Allowed Range (in which Value Constraint allows Value Range) and maybe Value Range has maximum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMaximumBoundValueLiteral      varchar NULL,
	-- Allowed Range (in which Value Constraint allows Value Range) and maybe Value Range has maximum-Bound and Bound has Value and maybe Value is in Unit and Unit is an instance of Concept and Concept has Guid,
	ValueRangeMaximumBoundValueUnitConceptGuid uniqueidentifier NULL,
	-- Allowed Range (in which Value Constraint allows Value Range) and maybe Value Range has minimum-Bound and Bound is inclusive,
	ValueRangeMinimumBoundIsInclusive       bit NULL,
	-- Allowed Range (in which Value Constraint allows Value Range) and maybe Value Range has minimum-Bound and Bound has Value and Value is literal string,
	ValueRangeMinimumBoundValueIsLiteralString bit NULL,
	-- Allowed Range (in which Value Constraint allows Value Range) and maybe Value Range has minimum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMinimumBoundValueLiteral      varchar NULL,
	-- Allowed Range (in which Value Constraint allows Value Range) and maybe Value Range has minimum-Bound and Bound has Value and maybe Value is in Unit and Unit is an instance of Concept and Concept has Guid,
	ValueRangeMinimumBoundValueUnitConceptGuid uniqueidentifier NULL,
	UNIQUE(ValueConstraintConceptGuid, ValueRangeMinimumBoundValueLiteral, ValueRangeMinimumBoundValueIsLiteralString, ValueRangeMinimumBoundValueUnitConceptGuid, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValueLiteral, ValueRangeMaximumBoundValueIsLiteralString, ValueRangeMaximumBoundValueUnitConceptGuid, ValueRangeMaximumBoundIsInclusive)
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
	-- maybe Constraint is an instance of Concept and maybe Constraint is called Name,
	ConstraintName                          varchar(64) NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint belongs to Vocabulary and Vocabulary is called Name,
	ConstraintVocabularyName                varchar(64) NULL,
	-- maybe Context Note is an instance of Concept and maybe Context Note was added by Agreement and maybe Agreement was on Date,
	ContextNoteDate                         datetime NULL,
	-- maybe Context Note is an instance of Concept and Context Note has Discussion,
	ContextNoteDiscussion                   varchar NULL,
	-- maybe Context Note is an instance of Concept and Context Note has Context Note Kind,
	ContextNoteKind                         varchar NULL CHECK(ContextNoteKind = 'as_opposed_to' OR ContextNoteKind = 'because' OR ContextNoteKind = 'so_that' OR ContextNoteKind = 'to_avoid'),
	-- maybe Context Note is an instance of Concept and maybe Context Note applies to relevant-Concept and Concept has Guid,
	ContextNoteRelevantConceptGuid          uniqueidentifier NULL,
	-- maybe Fact is an instance of Concept and Fact belongs to Population and Population has Name,
	FactPopulationName                      varchar(64) NULL,
	-- maybe Fact is an instance of Concept and Fact belongs to Population and maybe Population belongs to Vocabulary and Vocabulary is called Name,
	FactPopulationVocabularyName            varchar(64) NULL,
	-- maybe Fact is an instance of Concept and Fact is of Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	FactTypeConceptGuid                     uniqueidentifier NULL,
	-- Concept has Guid,
	Guid                                    uniqueidentifier NOT NULL,
	-- maybe Concept is implied by Implication Rule and Implication Rule has Implication Rule Name,
	ImplicationRuleName                     varchar NULL,
	-- maybe Instance is an instance of Concept and maybe Instance objectifies Fact and Fact is an instance of Concept and Concept has Guid,
	InstanceFactConceptGuid                 uniqueidentifier NULL,
	-- maybe Instance is an instance of Concept and Instance is of Object Type and Object Type is called Name,
	InstanceObjectTypeName                  varchar(64) NULL,
	-- maybe Instance is an instance of Concept and Instance is of Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	InstanceObjectTypeVocabularyName        varchar(64) NULL,
	-- maybe Instance is an instance of Concept and Instance belongs to Population and Population has Name,
	InstancePopulationName                  varchar(64) NULL,
	-- maybe Instance is an instance of Concept and Instance belongs to Population and maybe Population belongs to Vocabulary and Vocabulary is called Name,
	InstancePopulationVocabularyName        varchar(64) NULL,
	-- maybe Instance is an instance of Concept and maybe Instance has Value and Value is literal string,
	InstanceValueIsLiteralString            bit NULL,
	-- maybe Instance is an instance of Concept and maybe Instance has Value and Value is represented by Literal,
	InstanceValueLiteral                    varchar NULL,
	-- maybe Instance is an instance of Concept and maybe Instance has Value and maybe Value is in Unit and Unit is an instance of Concept and Concept has Guid,
	InstanceValueUnitConceptGuid            uniqueidentifier NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Presence Constraint and Presence Constraint is mandatory,
	PresenceConstraintIsMandatory           bit NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Presence Constraint and Presence Constraint is preferred identifier,
	PresenceConstraintIsPreferredIdentifier bit NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Presence Constraint and maybe Presence Constraint has max-Frequency,
	PresenceConstraintMaxFrequency          int NULL CHECK(PresenceConstraintMaxFrequency >= 1),
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Presence Constraint and maybe Presence Constraint has min-Frequency,
	PresenceConstraintMinFrequency          int NULL CHECK(PresenceConstraintMinFrequency >= 2),
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Presence Constraint and Presence Constraint covers Role Sequence and Role Sequence has Guid,
	PresenceConstraintRoleSequenceGuid      uniqueidentifier NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Ring Constraint and maybe Ring Constraint has other-Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RingConstraintOtherRoleFactTypeConceptGuid uniqueidentifier NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Ring Constraint and maybe Ring Constraint has other-Role and Role fills Ordinal,
	RingConstraintOtherRoleOrdinal          smallint NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Ring Constraint and Ring Constraint is of Ring Type,
	RingConstraintRingType                  varchar NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Ring Constraint and maybe Ring Constraint has Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RingConstraintRoleFactTypeConceptGuid   uniqueidentifier NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Ring Constraint and maybe Ring Constraint has Role and Role fills Ordinal,
	RingConstraintRoleOrdinal               smallint NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Set Constraint and maybe Set Constraint is a Set Comparison Constraint and maybe Set Comparison Constraint is a Set Exclusion Constraint and Set Exclusion Constraint is mandatory,
	SetExclusionConstraintIsMandatory       bit NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Set Constraint and maybe Set Constraint is a Subset Constraint and Subset Constraint covers subset-Role Sequence and Role Sequence has Guid,
	SubsetConstraintSubsetRoleSequenceGuid  uniqueidentifier NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Set Constraint and maybe Set Constraint is a Subset Constraint and Subset Constraint covers superset-Role Sequence and Role Sequence has Guid,
	SubsetConstraintSupersetRoleSequenceGuid uniqueidentifier NULL,
	-- maybe Unit is an instance of Concept and maybe Unit has Coefficient and Coefficient has Denominator,
	UnitCoefficientDenominator              int NULL,
	-- maybe Unit is an instance of Concept and maybe Unit has Coefficient and Coefficient is precise,
	UnitCoefficientIsPrecise                bit NULL,
	-- maybe Unit is an instance of Concept and maybe Unit has Coefficient and Coefficient has Numerator,
	UnitCoefficientNumerator                decimal NULL,
	-- maybe Unit is an instance of Concept and maybe Unit uses coefficient from Ephemera URL,
	UnitEphemeraURL                         varchar NULL,
	-- maybe Unit is an instance of Concept and Unit is fundamental,
	UnitIsFundamental                       bit NULL,
	-- maybe Unit is an instance of Concept and Unit is called Name,
	UnitName                                varchar(64) NULL,
	-- maybe Unit is an instance of Concept and maybe Unit has Offset,
	UnitOffset                              decimal NULL,
	-- maybe Unit is an instance of Concept and maybe Unit has plural-Name,
	UnitPluralName                          varchar(64) NULL,
	-- maybe Unit is an instance of Concept and Unit is in Vocabulary and Vocabulary is called Name,
	UnitVocabularyName                      varchar(64) NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Value Constraint and maybe Value Constraint requires matching Regular Expression,
	ValueConstraintRegularExpression        varchar NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Value Constraint and maybe Value Constraint applies to Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	ValueConstraintRoleFactTypeConceptGuid  uniqueidentifier NULL,
	-- maybe Constraint is an instance of Concept and maybe Constraint is a Value Constraint and maybe Value Constraint applies to Role and Role fills Ordinal,
	ValueConstraintRoleOrdinal              smallint NULL,
	PRIMARY KEY(Guid),
	FOREIGN KEY (ContextNoteRelevantConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (InstanceFactConceptGuid) REFERENCES Concept (Guid)
)
GO

CREATE VIEW dbo.ConstraintInConcept_VocabularyNameName (ConstraintVocabularyName, ConstraintName) WITH SCHEMABINDING AS
	SELECT ConstraintVocabularyName, ConstraintName FROM dbo.Concept
	WHERE	ConstraintVocabularyName IS NOT NULL
	  AND	ConstraintName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ConstraintInConceptByConstraintVocabularyNameConstraintName ON dbo.ConstraintInConcept_VocabularyNameName(ConstraintVocabularyName, ConstraintName)
GO

CREATE VIEW dbo.InstanceInConcept_FactConceptGuid (InstanceFactConceptGuid) WITH SCHEMABINDING AS
	SELECT InstanceFactConceptGuid FROM dbo.Concept
	WHERE	InstanceFactConceptGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_InstanceInConceptByInstanceFactConceptGuid ON dbo.InstanceInConcept_FactConceptGuid(InstanceFactConceptGuid)
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
	-- Context According To (in which Context Note is according to Agent) and Agent has Agent Name,
	AgentName                               varchar NOT NULL,
	-- Context According To (in which Context Note is according to Agent) and Context Note is an instance of Concept and Concept has Guid,
	ContextNoteConceptGuid                  uniqueidentifier NOT NULL,
	-- maybe Context According To was lodged on Date,
	Date                                    datetime NULL,
	PRIMARY KEY(ContextNoteConceptGuid, AgentName),
	FOREIGN KEY (ContextNoteConceptGuid) REFERENCES Concept (Guid)
)
GO

CREATE TABLE ContextAgreedBy (
	-- Context Agreed By (in which Agreement was reached by Agent) and Agent has Agent Name,
	AgentName                               varchar NOT NULL,
	-- Context Agreed By (in which Agreement was reached by Agent) and Agreement covers Context Note and Context Note is an instance of Concept and Concept has Guid,
	AgreementContextNoteConceptGuid         uniqueidentifier NOT NULL,
	PRIMARY KEY(AgreementContextNoteConceptGuid, AgentName),
	FOREIGN KEY (AgreementContextNoteConceptGuid) REFERENCES Concept (Guid)
)
GO

CREATE TABLE Derivation (
	-- Derivation (in which Unit is derived from base-Unit) and Unit is an instance of Concept and Concept has Guid,
	BaseUnitConceptGuid                     uniqueidentifier NOT NULL,
	-- Derivation (in which Unit is derived from base-Unit) and Unit is an instance of Concept and Concept has Guid,
	DerivedUnitConceptGuid                  uniqueidentifier NOT NULL,
	-- maybe Derivation has Exponent,
	Exponent                                smallint NULL,
	PRIMARY KEY(DerivedUnitConceptGuid, BaseUnitConceptGuid),
	FOREIGN KEY (BaseUnitConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (DerivedUnitConceptGuid) REFERENCES Concept (Guid)
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
	-- Facet requires value of facet-Value Type and Value Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type is called Name,
	FacetValueTypeName                      varchar(64) NOT NULL,
	-- Facet requires value of facet-Value Type and Value Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	FacetValueTypeVocabularyName            varchar(64) NOT NULL,
	-- Facet (in which Value Type has facet called Name) involves Name,
	Name                                    varchar(64) NOT NULL,
	-- Facet (in which Value Type has facet called Name) and Value Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type is called Name,
	ValueTypeName                           varchar(64) NOT NULL,
	-- Facet (in which Value Type has facet called Name) and Value Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeVocabularyName                 varchar(64) NOT NULL,
	PRIMARY KEY(ValueTypeVocabularyName, ValueTypeName, Name)
)
GO

CREATE TABLE FacetRestriction (
	-- Facet Restriction (in which Value Type applies Facet) and Facet (in which Value Type has facet called Name) involves Name,
	FacetName                               varchar(64) NOT NULL,
	-- Facet Restriction (in which Value Type applies Facet) and Facet (in which Value Type has facet called Name) and Value Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type is called Name,
	FacetValueTypeName                      varchar(64) NOT NULL,
	-- Facet Restriction (in which Value Type applies Facet) and Facet (in which Value Type has facet called Name) and Value Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	FacetValueTypeVocabularyName            varchar(64) NOT NULL,
	-- Facet Restriction has Value and Value is literal string,
	ValueIsLiteralString                    bit NULL,
	-- Facet Restriction has Value and Value is represented by Literal,
	ValueLiteral                            varchar NOT NULL,
	-- Facet Restriction (in which Value Type applies Facet) and Value Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type is called Name,
	ValueTypeName                           varchar(64) NOT NULL,
	-- Facet Restriction (in which Value Type applies Facet) and Value Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeVocabularyName                 varchar(64) NOT NULL,
	-- Facet Restriction has Value and maybe Value is in Unit and Unit is an instance of Concept and Concept has Guid,
	ValueUnitConceptGuid                    uniqueidentifier NULL,
	PRIMARY KEY(ValueTypeVocabularyName, ValueTypeName, FacetValueTypeVocabularyName, FacetValueTypeName, FacetName),
	FOREIGN KEY (FacetValueTypeVocabularyName, FacetValueTypeName, FacetName) REFERENCES Facet (ValueTypeVocabularyName, ValueTypeName, Name)
)
GO

CREATE TABLE FactType (
	-- Fact Type is an instance of Concept and Concept has Guid,
	ConceptGuid                             uniqueidentifier NOT NULL,
	-- maybe Fact Type is nested as Entity Type and Entity Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type is called Name,
	EntityTypeName                          varchar(64) NULL,
	-- maybe Fact Type is nested as Entity Type and Entity Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	EntityTypeVocabularyName                varchar(64) NULL,
	-- maybe Fact Type is a Type Inheritance and maybe Type Inheritance uses Assimilation,
	TypeInheritanceAssimilation             varchar NULL CHECK(TypeInheritanceAssimilation = 'absorbed' OR TypeInheritanceAssimilation = 'partitioned' OR TypeInheritanceAssimilation = 'separate'),
	-- maybe Fact Type is a Type Inheritance and Type Inheritance provides identification,
	TypeInheritanceProvidesIdentification   bit NULL,
	-- maybe Fact Type is a Type Inheritance and Type Inheritance (in which Entity Type is subtype of super-Entity Type) and Entity Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type is called Name,
	TypeInheritanceSubtypeName              varchar(64) NULL,
	-- maybe Fact Type is a Type Inheritance and Type Inheritance (in which Entity Type is subtype of super-Entity Type) and Entity Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	TypeInheritanceSubtypeVocabularyName    varchar(64) NULL,
	-- maybe Fact Type is a Type Inheritance and Type Inheritance (in which Entity Type is subtype of super-Entity Type) and Entity Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type is called Name,
	TypeInheritanceSupertypeName            varchar(64) NULL,
	-- maybe Fact Type is a Type Inheritance and Type Inheritance (in which Entity Type is subtype of super-Entity Type) and Entity Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
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
	-- maybe Object Type is a Domain Object Type and maybe Domain Object Type is a Value Type and maybe Value Type has Length,
	ValueTypeLength                         int NULL,
	-- maybe Object Type is a Domain Object Type and maybe Domain Object Type is a Value Type and maybe Value Type has Scale,
	ValueTypeScale                          int NULL,
	-- maybe Object Type is a Domain Object Type and maybe Domain Object Type is a Value Type and maybe Value Type is subtype of super-Value Type and Value Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type is called Name,
	ValueTypeSupertypeName                  varchar(64) NULL,
	-- maybe Object Type is a Domain Object Type and maybe Domain Object Type is a Value Type and maybe Value Type is subtype of super-Value Type and Value Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeSupertypeVocabularyName        varchar(64) NULL,
	-- maybe Object Type is a Domain Object Type and maybe Domain Object Type is a Value Type and maybe Value Type is auto-assigned at Transaction Phase,
	ValueTypeTransactionPhase               varchar NULL CHECK(ValueTypeTransactionPhase = 'assert' OR ValueTypeTransactionPhase = 'commit'),
	-- maybe Object Type is a Domain Object Type and maybe Domain Object Type is a Value Type and maybe Value Type is of Unit and Unit is an instance of Concept and Concept has Guid,
	ValueTypeUnitConceptGuid                uniqueidentifier NULL,
	-- maybe Object Type is a Domain Object Type and maybe Domain Object Type is a Value Type and maybe Value Type has Value Constraint and Value Constraint is a kind of Constraint and Constraint is an instance of Concept and Concept has Guid,
	ValueTypeValueConstraintConceptGuid     uniqueidentifier NULL,
	-- Object Type belongs to Vocabulary and Vocabulary is called Name,
	VocabularyName                          varchar(64) NOT NULL,
	PRIMARY KEY(VocabularyName, Name),
	UNIQUE(ConceptGuid),
	FOREIGN KEY (ValueTypeValueConstraintConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (ConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (ValueTypeUnitConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (ValueTypeSupertypeVocabularyName, ValueTypeSupertypeName) REFERENCES ObjectType (VocabularyName, Name)
)
GO

CREATE VIEW dbo.ValueTypeInObjectType_ValueTypeLengthValueTypeScaleValueTypeSupertypeVocabularyNameValueTypeTransactionPhaseValueTypeUni (ValueTypeLength, ValueTypeScale, ValueTypeSupertypeVocabularyName, ValueTypeTransactionPhase, ValueTypeUnitConceptGuid, ValueTypeValueConstraintConceptGuid, ValueTypeSupertypeName) WITH SCHEMABINDING AS
	SELECT ValueTypeLength, ValueTypeScale, ValueTypeSupertypeVocabularyName, ValueTypeTransactionPhase, ValueTypeUnitConceptGuid, ValueTypeValueConstraintConceptGuid, ValueTypeSupertypeName FROM dbo.ObjectType
	WHERE	ValueTypeLength IS NOT NULL
	  AND	ValueTypeScale IS NOT NULL
	  AND	ValueTypeSupertypeVocabularyName IS NOT NULL
	  AND	ValueTypeTransactionPhase IS NOT NULL
	  AND	ValueTypeUnitConceptGuid IS NOT NULL
	  AND	ValueTypeValueConstraintConceptGuid IS NOT NULL
	  AND	ValueTypeSupertypeName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX DomainObjectTypeMustHaveSupertypeObjectType ON dbo.ValueTypeInObjectType_ValueTypeLengthValueTypeScaleValueTypeSupertypeVocabularyNameValueTypeTransactionPhaseValueTypeUni(ValueTypeLength, ValueTypeScale, ValueTypeSupertypeVocabularyName, ValueTypeTransactionPhase, ValueTypeUnitConceptGuid, ValueTypeValueConstraintConceptGuid, ValueTypeSupertypeName)
GO

CREATE VIEW dbo.ValueTypeInObjectType_ValueTypeValueConstraintConceptGuid (ValueTypeValueConstraintConceptGuid) WITH SCHEMABINDING AS
	SELECT ValueTypeValueConstraintConceptGuid FROM dbo.ObjectType
	WHERE	ValueTypeValueConstraintConceptGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueTypeInObjectTypeByValueTypeValueConstraintConceptGuid ON dbo.ValueTypeInObjectType_ValueTypeValueConstraintConceptGuid(ValueTypeValueConstraintConceptGuid)
GO

CREATE TABLE Play (
	-- Play (in which Variable is restricted by Role) and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RoleFactTypeConceptGuid                 uniqueidentifier NOT NULL,
	-- Play (in which Variable is restricted by Role) and Role fills Ordinal,
	RoleOrdinal                             smallint NOT NULL,
	-- maybe Play is incidentally involved in Step and Step has input-Play and Play (in which Variable is restricted by Role) and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	StepInputPlayRoleFactTypeConceptGuid    uniqueidentifier NULL,
	-- maybe Play is incidentally involved in Step and Step has input-Play and Play (in which Variable is restricted by Role) and Role fills Ordinal,
	StepInputPlayRoleOrdinal                smallint NULL,
	-- maybe Play is incidentally involved in Step and Step has input-Play and Play (in which Variable is restricted by Role) and Variable has Ordinal position,
	StepInputPlayVariableOrdinal            smallint NULL,
	-- maybe Play is incidentally involved in Step and Step has input-Play and Play (in which Variable is restricted by Role) and Variable is in Query and Query is an instance of Concept and Concept has Guid,
	StepInputPlayVariableQueryConceptGuid   uniqueidentifier NULL,
	-- maybe Play is incidentally involved in Step and maybe Step has output-Play and Play (in which Variable is restricted by Role) and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	StepOutputPlayRoleFactTypeConceptGuid   uniqueidentifier NULL,
	-- maybe Play is incidentally involved in Step and maybe Step has output-Play and Play (in which Variable is restricted by Role) and Role fills Ordinal,
	StepOutputPlayRoleOrdinal               smallint NULL,
	-- maybe Play is incidentally involved in Step and maybe Step has output-Play and Play (in which Variable is restricted by Role) and Variable has Ordinal position,
	StepOutputPlayVariableOrdinal           smallint NULL,
	-- maybe Play is incidentally involved in Step and maybe Step has output-Play and Play (in which Variable is restricted by Role) and Variable is in Query and Query is an instance of Concept and Concept has Guid,
	StepOutputPlayVariableQueryConceptGuid  uniqueidentifier NULL,
	-- Play (in which Variable is restricted by Role) and Variable has Ordinal position,
	VariableOrdinal                         smallint NOT NULL,
	-- Play (in which Variable is restricted by Role) and Variable is in Query and Query is an instance of Concept and Concept has Guid,
	VariableQueryConceptGuid                uniqueidentifier NOT NULL,
	PRIMARY KEY(VariableQueryConceptGuid, VariableOrdinal, RoleFactTypeConceptGuid, RoleOrdinal)
)
GO

CREATE TABLE Population (
	-- Population is an instance of Concept and Concept has Guid,
	ConceptGuid                             uniqueidentifier NOT NULL,
	-- Population has Name,
	Name                                    varchar(64) NOT NULL,
	-- maybe Population belongs to Vocabulary and Vocabulary is called Name,
	VocabularyName                          varchar(64) NULL,
	UNIQUE(VocabularyName, Name),
	UNIQUE(ConceptGuid),
	FOREIGN KEY (ConceptGuid) REFERENCES Concept (Guid)
)
GO

CREATE TABLE Reading (
	-- Reading is for Fact Type and Fact Type is an instance of Concept and Concept has Guid,
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
	-- Role is played by Object Type and Object Type is called Name,
	ObjectTypeName                          varchar(64) NOT NULL,
	-- Role is played by Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NOT NULL,
	-- Role fills Ordinal,
	Ordinal                                 smallint NOT NULL,
	-- maybe Role has role-Name,
	RoleName                                varchar(64) NULL,
	-- maybe Role is a Role Proxy and maybe Role Proxy is of Link Fact Type and Link Fact Type is a kind of Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RoleProxyLinkFactTypeConceptGuid        uniqueidentifier NULL,
	-- maybe Role is a Role Proxy and maybe Role Proxy is for Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RoleProxyRoleFactTypeConceptGuid        uniqueidentifier NULL,
	-- maybe Role is a Role Proxy and maybe Role Proxy is for Role and Role fills Ordinal,
	RoleProxyRoleOrdinal                    smallint NULL,
	PRIMARY KEY(FactTypeConceptGuid, Ordinal),
	UNIQUE(ConceptGuid),
	FOREIGN KEY (ConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (RoleProxyLinkFactTypeConceptGuid) REFERENCES FactType (ConceptGuid),
	FOREIGN KEY (FactTypeConceptGuid) REFERENCES FactType (ConceptGuid),
	FOREIGN KEY (ObjectTypeVocabularyName, ObjectTypeName) REFERENCES ObjectType (VocabularyName, Name),
	FOREIGN KEY (RoleProxyRoleFactTypeConceptGuid, RoleProxyRoleOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal)
)
GO

CREATE VIEW dbo.RoleProxyInRole_RoleProxyLinkFactTypeConceptGuid (RoleProxyLinkFactTypeConceptGuid) WITH SCHEMABINDING AS
	SELECT RoleProxyLinkFactTypeConceptGuid FROM dbo.Role
	WHERE	RoleProxyLinkFactTypeConceptGuid IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleProxyInRoleByRoleProxyLinkFactTypeConceptGuid ON dbo.RoleProxyInRole_RoleProxyLinkFactTypeConceptGuid(RoleProxyLinkFactTypeConceptGuid)
GO

CREATE VIEW dbo.RoleProxyInRole_RoleProxyRoleFactTypeConceptGuidRoleProxyRoleOrdinal (RoleProxyRoleFactTypeConceptGuid, RoleProxyRoleOrdinal) WITH SCHEMABINDING AS
	SELECT RoleProxyRoleFactTypeConceptGuid, RoleProxyRoleOrdinal FROM dbo.Role
	WHERE	RoleProxyRoleFactTypeConceptGuid IS NOT NULL
	  AND	RoleProxyRoleOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleProxyInRoleByRoleProxyRoleFactTypeConceptGuidRoleProxyRoleOrdinal ON dbo.RoleProxyInRole_RoleProxyRoleFactTypeConceptGuidRoleProxyRoleOrdinal(RoleProxyRoleFactTypeConceptGuid, RoleProxyRoleOrdinal)
GO

CREATE TABLE RoleDisplay (
	-- Role Display (in which Fact Type Shape displays Role in Ordinal position) and Fact Type Shape is a kind of Shape and Shape has Guid,
	FactTypeShapeGuid                       uniqueidentifier NOT NULL,
	-- Role Display (in which Fact Type Shape displays Role in Ordinal position) involves Ordinal,
	Ordinal                                 smallint NOT NULL,
	-- Role Display (in which Fact Type Shape displays Role in Ordinal position) and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RoleFactTypeConceptGuid                 uniqueidentifier NOT NULL,
	-- Role Display (in which Fact Type Shape displays Role in Ordinal position) and Role fills Ordinal,
	RoleOrdinal                             smallint NOT NULL,
	PRIMARY KEY(FactTypeShapeGuid, Ordinal),
	FOREIGN KEY (RoleFactTypeConceptGuid, RoleOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal)
)
GO

CREATE TABLE RoleRef (
	-- maybe Role Ref has leading-Adjective,
	LeadingAdjective                        varchar(64) NULL,
	-- Role Ref (in which Role Sequence in Ordinal position includes Role) involves Ordinal,
	Ordinal                                 smallint NOT NULL,
	-- maybe Play projects Role Ref and Play (in which Variable is restricted by Role) and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	PlayRoleFactTypeConceptGuid             uniqueidentifier NULL,
	-- maybe Play projects Role Ref and Play (in which Variable is restricted by Role) and Role fills Ordinal,
	PlayRoleOrdinal                         smallint NULL,
	-- maybe Play projects Role Ref and Play (in which Variable is restricted by Role) and Variable has Ordinal position,
	PlayVariableOrdinal                     smallint NULL,
	-- maybe Play projects Role Ref and Play (in which Variable is restricted by Role) and Variable is in Query and Query is an instance of Concept and Concept has Guid,
	PlayVariableQueryConceptGuid            uniqueidentifier NULL,
	-- Role Ref (in which Role Sequence in Ordinal position includes Role) and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RoleFactTypeConceptGuid                 uniqueidentifier NOT NULL,
	-- Role Ref (in which Role Sequence in Ordinal position includes Role) and Role fills Ordinal,
	RoleOrdinal                             smallint NOT NULL,
	-- Role Ref (in which Role Sequence in Ordinal position includes Role) and Role Sequence has Guid,
	RoleSequenceGuid                        uniqueidentifier NOT NULL,
	-- maybe Role Ref has trailing-Adjective,
	TrailingAdjective                       varchar(64) NULL,
	PRIMARY KEY(RoleSequenceGuid, Ordinal),
	UNIQUE(RoleFactTypeConceptGuid, RoleOrdinal, RoleSequenceGuid),
	FOREIGN KEY (PlayVariableQueryConceptGuid, PlayVariableOrdinal, PlayRoleFactTypeConceptGuid, PlayRoleOrdinal) REFERENCES Play (VariableQueryConceptGuid, VariableOrdinal, RoleFactTypeConceptGuid, RoleOrdinal),
	FOREIGN KEY (RoleFactTypeConceptGuid, RoleOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal)
)
GO

CREATE VIEW dbo.RoleRef_PlayVariableQueryConceptGuidPlayVariableOrdinalPlayRoleFactTypeConceptGuidPlayRoleOrdinal (PlayVariableQueryConceptGuid, PlayVariableOrdinal, PlayRoleFactTypeConceptGuid, PlayRoleOrdinal) WITH SCHEMABINDING AS
	SELECT PlayVariableQueryConceptGuid, PlayVariableOrdinal, PlayRoleFactTypeConceptGuid, PlayRoleOrdinal FROM dbo.RoleRef
	WHERE	PlayVariableQueryConceptGuid IS NOT NULL
	  AND	PlayVariableOrdinal IS NOT NULL
	  AND	PlayRoleFactTypeConceptGuid IS NOT NULL
	  AND	PlayRoleOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleRefByPlayVariableQueryConceptGuidPlayVariableOrdinalPlayRoleFactTypeConceptGuidPlayRoleOrdinal ON dbo.RoleRef_PlayVariableQueryConceptGuidPlayVariableOrdinalPlayRoleFactTypeConceptGuidPlayRoleOrdinal(PlayVariableQueryConceptGuid, PlayVariableOrdinal, PlayRoleFactTypeConceptGuid, PlayRoleOrdinal)
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
	-- Role Value fulfils Fact and Fact is an instance of Concept and Concept has Guid,
	FactConceptGuid                         uniqueidentifier NOT NULL,
	-- Role Value is of Instance and Instance is an instance of Concept and Concept has Guid,
	InstanceConceptGuid                     uniqueidentifier NOT NULL,
	-- Role Value belongs to Population and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Role Value belongs to Population and maybe Population belongs to Vocabulary and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	-- Role Value is of Role and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	RoleFactTypeConceptGuid                 uniqueidentifier NOT NULL,
	-- Role Value is of Role and Role fills Ordinal,
	RoleOrdinal                             smallint NOT NULL,
	PRIMARY KEY(FactConceptGuid, RoleFactTypeConceptGuid, RoleOrdinal),
	FOREIGN KEY (FactConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (InstanceConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (PopulationVocabularyName, PopulationName) REFERENCES Population (VocabularyName, Name),
	FOREIGN KEY (RoleFactTypeConceptGuid, RoleOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal)
)
GO

CREATE TABLE SetComparisonRoles (
	-- Set Comparison Roles (in which Set Comparison Constraint has in Ordinal position Role Sequence) involves Ordinal,
	Ordinal                                 smallint NOT NULL,
	-- Set Comparison Roles (in which Set Comparison Constraint has in Ordinal position Role Sequence) and Role Sequence has Guid,
	RoleSequenceGuid                        uniqueidentifier NOT NULL,
	-- Set Comparison Roles (in which Set Comparison Constraint has in Ordinal position Role Sequence) and Set Comparison Constraint is a kind of Set Constraint and Set Constraint is a kind of Constraint and Constraint is an instance of Concept and Concept has Guid,
	SetComparisonConstraintConceptGuid      uniqueidentifier NOT NULL,
	PRIMARY KEY(SetComparisonConstraintConceptGuid, Ordinal),
	UNIQUE(SetComparisonConstraintConceptGuid, RoleSequenceGuid),
	FOREIGN KEY (SetComparisonConstraintConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (RoleSequenceGuid) REFERENCES RoleSequence (Guid)
)
GO

CREATE TABLE Shape (
	-- maybe Shape is a Constraint Shape and Constraint Shape is for Constraint and Constraint is an instance of Concept and Concept has Guid,
	ConstraintShapeConstraintConceptGuid    uniqueidentifier NULL,
	-- maybe Shape is a Fact Type Shape and maybe Fact Type Shape has Display Role Names Setting,
	FactTypeShapeDisplayRoleNamesSetting    varchar NULL CHECK(FactTypeShapeDisplayRoleNamesSetting = 'false' OR FactTypeShapeDisplayRoleNamesSetting = 'true'),
	-- maybe Shape is a Fact Type Shape and Fact Type Shape is for Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	FactTypeShapeFactTypeConceptGuid        uniqueidentifier NULL,
	-- maybe Shape is a Fact Type Shape and maybe Fact Type Shape has Rotation Setting,
	FactTypeShapeRotationSetting            varchar NULL CHECK(FactTypeShapeRotationSetting = 'left' OR FactTypeShapeRotationSetting = 'right'),
	-- Shape has Guid,
	Guid                                    uniqueidentifier NOT NULL,
	-- Shape is expanded,
	IsExpanded                              bit NULL,
	-- maybe Shape is at Location and Location is at X,
	LocationX                               int NULL,
	-- maybe Shape is at Location and Location is at Y,
	LocationY                               int NULL,
	-- maybe Shape is a Model Note Shape and Model Note Shape is for Context Note and Context Note is an instance of Concept and Concept has Guid,
	ModelNoteShapeContextNoteConceptGuid    uniqueidentifier NULL,
	-- Shape is in ORM Diagram and ORM Diagram is a kind of Diagram and Diagram is called Name,
	ORMDiagramName                          varchar(64) NOT NULL,
	-- Shape is in ORM Diagram and ORM Diagram is a kind of Diagram and Diagram is for Vocabulary and Vocabulary is called Name,
	ORMDiagramVocabularyName                varchar(64) NOT NULL,
	-- maybe Shape is an Object Type Shape and Object Type Shape has expanded reference mode,
	ObjectTypeShapeHasExpandedReferenceMode bit NULL,
	-- maybe Shape is an Object Type Shape and Object Type Shape is for Object Type and Object Type is called Name,
	ObjectTypeShapeObjectTypeName           varchar(64) NULL,
	-- maybe Shape is an Object Type Shape and Object Type Shape is for Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ObjectTypeShapeObjectTypeVocabularyName varchar(64) NULL,
	-- maybe Shape is an Objectified Fact Type Name Shape and Objectified Fact Type Name Shape is for Fact Type Shape and Fact Type Shape is a kind of Shape and Shape has Guid,
	ObjectifiedFactTypeNameShapeFactTypeShapeGuid uniqueidentifier NULL,
	-- maybe Shape is a Reading Shape and Reading Shape is for Fact Type Shape and Fact Type Shape is a kind of Shape and Shape has Guid,
	ReadingShapeFactTypeShapeGuid           uniqueidentifier NULL,
	-- maybe Shape is a Reading Shape and Reading Shape is for Reading and Reading is for Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	ReadingShapeReadingFactTypeConceptGuid  uniqueidentifier NULL,
	-- maybe Shape is a Reading Shape and Reading Shape is for Reading and Reading is in Ordinal position,
	ReadingShapeReadingOrdinal              smallint NULL,
	-- maybe Shape is a Constraint Shape and maybe Constraint Shape is a Ring Constraint Shape and Ring Constraint Shape is attached to Fact Type Shape and Fact Type Shape is a kind of Shape and Shape has Guid,
	RingConstraintShapeFactTypeShapeGuid    uniqueidentifier NULL,
	-- maybe Shape is a Role Name Shape and Role Name Shape is for Role Display and Role Display (in which Fact Type Shape displays Role in Ordinal position) and Fact Type Shape is a kind of Shape and Shape has Guid,
	RoleNameShapeRoleDisplayFactTypeShapeGuid uniqueidentifier NULL,
	-- maybe Shape is a Role Name Shape and Role Name Shape is for Role Display and Role Display (in which Fact Type Shape displays Role in Ordinal position) involves Ordinal,
	RoleNameShapeRoleDisplayOrdinal         smallint NULL,
	-- maybe Shape is a Constraint Shape and maybe Constraint Shape is a Value Constraint Shape and maybe Value Constraint Shape is for Object Type Shape and Object Type Shape is a kind of Shape and Shape has Guid,
	ValueConstraintShapeObjectTypeShapeGuid uniqueidentifier NULL,
	-- maybe Shape is a Constraint Shape and maybe Constraint Shape is a Value Constraint Shape and maybe Value Constraint Shape is for Role Display and Role Display (in which Fact Type Shape displays Role in Ordinal position) and Fact Type Shape is a kind of Shape and Shape has Guid,
	ValueConstraintShapeRoleDisplayFactTypeShapeGuid uniqueidentifier NULL,
	-- maybe Shape is a Constraint Shape and maybe Constraint Shape is a Value Constraint Shape and maybe Value Constraint Shape is for Role Display and Role Display (in which Fact Type Shape displays Role in Ordinal position) involves Ordinal,
	ValueConstraintShapeRoleDisplayOrdinal  smallint NULL,
	PRIMARY KEY(Guid),
	FOREIGN KEY (ConstraintShapeConstraintConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (ModelNoteShapeContextNoteConceptGuid) REFERENCES Concept (Guid),
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
	-- Step has input-Play and Play (in which Variable is restricted by Role) and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	InputPlayRoleFactTypeConceptGuid        uniqueidentifier NOT NULL,
	-- Step has input-Play and Play (in which Variable is restricted by Role) and Role fills Ordinal,
	InputPlayRoleOrdinal                    smallint NOT NULL,
	-- Step has input-Play and Play (in which Variable is restricted by Role) and Variable has Ordinal position,
	InputPlayVariableOrdinal                smallint NOT NULL,
	-- Step has input-Play and Play (in which Variable is restricted by Role) and Variable is in Query and Query is an instance of Concept and Concept has Guid,
	InputPlayVariableQueryConceptGuid       uniqueidentifier NOT NULL,
	-- Step is disallowed,
	IsDisallowed                            bit NULL,
	-- Step is optional,
	IsOptional                              bit NULL,
	-- maybe Step has output-Play and Play (in which Variable is restricted by Role) and Role belongs to Fact Type and Fact Type is an instance of Concept and Concept has Guid,
	OutputPlayRoleFactTypeConceptGuid       uniqueidentifier NULL,
	-- maybe Step has output-Play and Play (in which Variable is restricted by Role) and Role fills Ordinal,
	OutputPlayRoleOrdinal                   smallint NULL,
	-- maybe Step has output-Play and Play (in which Variable is restricted by Role) and Variable has Ordinal position,
	OutputPlayVariableOrdinal               smallint NULL,
	-- maybe Step has output-Play and Play (in which Variable is restricted by Role) and Variable is in Query and Query is an instance of Concept and Concept has Guid,
	OutputPlayVariableQueryConceptGuid      uniqueidentifier NULL,
	UNIQUE(InputPlayVariableQueryConceptGuid, InputPlayVariableOrdinal, InputPlayRoleFactTypeConceptGuid, InputPlayRoleOrdinal, OutputPlayVariableQueryConceptGuid, OutputPlayVariableOrdinal, OutputPlayRoleFactTypeConceptGuid, OutputPlayRoleOrdinal),
	FOREIGN KEY (AlternativeSetGuid) REFERENCES AlternativeSet (Guid),
	FOREIGN KEY (FactTypeConceptGuid) REFERENCES FactType (ConceptGuid),
	FOREIGN KEY (InputPlayVariableQueryConceptGuid, InputPlayVariableOrdinal, InputPlayRoleFactTypeConceptGuid, InputPlayRoleOrdinal) REFERENCES Play (VariableQueryConceptGuid, VariableOrdinal, RoleFactTypeConceptGuid, RoleOrdinal),
	FOREIGN KEY (OutputPlayVariableQueryConceptGuid, OutputPlayVariableOrdinal, OutputPlayRoleFactTypeConceptGuid, OutputPlayRoleOrdinal) REFERENCES Play (VariableQueryConceptGuid, VariableOrdinal, RoleFactTypeConceptGuid, RoleOrdinal)
)
GO

CREATE TABLE Value (
	-- Value is literal string,
	IsLiteralString                         bit NULL,
	-- Value is represented by Literal,
	Literal                                 varchar NOT NULL,
	-- maybe Value is in Unit and Unit is an instance of Concept and Concept has Guid,
	UnitConceptGuid                         uniqueidentifier NULL,
	-- Value is of Value Type and Value Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type is called Name,
	ValueTypeName                           varchar(64) NOT NULL,
	-- Value is of Value Type and Value Type is a kind of Domain Object Type and Domain Object Type is a kind of Object Type and Object Type belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeVocabularyName                 varchar(64) NOT NULL,
	UNIQUE(Literal, IsLiteralString, UnitConceptGuid),
	FOREIGN KEY (UnitConceptGuid) REFERENCES Concept (Guid),
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
	-- Variable is in Query and Query is an instance of Concept and Concept has Guid,
	QueryConceptGuid                        uniqueidentifier NOT NULL,
	-- maybe Variable has role-Name,
	RoleName                                varchar(64) NULL,
	-- maybe Variable has Subscript,
	Subscript                               smallint NULL,
	-- maybe Variable is bound to Value and Value is literal string,
	ValueIsLiteralString                    bit NULL,
	-- maybe Variable is bound to Value and Value is represented by Literal,
	ValueLiteral                            varchar NULL,
	-- maybe Variable is bound to Value and maybe Value is in Unit and Unit is an instance of Concept and Concept has Guid,
	ValueUnitConceptGuid                    uniqueidentifier NULL,
	PRIMARY KEY(QueryConceptGuid, Ordinal),
	FOREIGN KEY (QueryConceptGuid) REFERENCES Concept (Guid),
	FOREIGN KEY (ObjectTypeVocabularyName, ObjectTypeName) REFERENCES ObjectType (VocabularyName, Name),
	FOREIGN KEY (ProjectionFactTypeConceptGuid, ProjectionOrdinal) REFERENCES Role (FactTypeConceptGuid, Ordinal),
	FOREIGN KEY (ValueLiteral, ValueIsLiteralString, ValueUnitConceptGuid) REFERENCES Value (Literal, IsLiteralString, UnitConceptGuid)
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
	ADD FOREIGN KEY (AggregatedVariableQueryConceptGuid, AggregatedVariableOrdinal) REFERENCES Variable (QueryConceptGuid, Ordinal)
GO

ALTER TABLE Aggregation
	ADD FOREIGN KEY (VariableQueryConceptGuid, VariableOrdinal) REFERENCES Variable (QueryConceptGuid, Ordinal)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueConstraintConceptGuid) REFERENCES Concept (Guid)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueRangeMaximumBoundValueLiteral, ValueRangeMaximumBoundValueIsLiteralString, ValueRangeMaximumBoundValueUnitConceptGuid) REFERENCES Value (Literal, IsLiteralString, UnitConceptGuid)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueRangeMinimumBoundValueLiteral, ValueRangeMinimumBoundValueIsLiteralString, ValueRangeMinimumBoundValueUnitConceptGuid) REFERENCES Value (Literal, IsLiteralString, UnitConceptGuid)
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
	ADD FOREIGN KEY (InstanceValueLiteral, InstanceValueIsLiteralString, InstanceValueUnitConceptGuid) REFERENCES Value (Literal, IsLiteralString, UnitConceptGuid)
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
	ADD FOREIGN KEY (ValueLiteral, ValueIsLiteralString, ValueUnitConceptGuid) REFERENCES Value (Literal, IsLiteralString, UnitConceptGuid)
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
	ADD FOREIGN KEY (StepInputPlayVariableQueryConceptGuid, StepInputPlayVariableOrdinal, StepInputPlayRoleFactTypeConceptGuid, StepInputPlayRoleOrdinal, StepOutputPlayVariableQueryConceptGuid, StepOutputPlayVariableOrdinal, StepOutputPlayRoleFactTypeConceptGuid, StepOutputPlayRoleOrdinal) REFERENCES Step (InputPlayVariableQueryConceptGuid, InputPlayVariableOrdinal, InputPlayRoleFactTypeConceptGuid, InputPlayRoleOrdinal, OutputPlayVariableQueryConceptGuid, OutputPlayVariableOrdinal, OutputPlayRoleFactTypeConceptGuid, OutputPlayRoleOrdinal)
GO

ALTER TABLE Play
	ADD FOREIGN KEY (VariableQueryConceptGuid, VariableOrdinal) REFERENCES Variable (QueryConceptGuid, Ordinal)
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

