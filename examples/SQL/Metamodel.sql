CREATE TABLE AllowedRange (
	-- AllowedRange is where ValueRestriction allows ValueRange and maybe ValueRange has maximum-Bound and Bound is inclusive,
	ValueRangeMaximumBoundIsInclusive       bit NULL,
	-- AllowedRange is where ValueRestriction allows ValueRange and maybe ValueRange has maximum-Bound and Bound has Value,
	ValueRangeMaximumBoundValue             varchar(256) NULL,
	-- AllowedRange is where ValueRestriction allows ValueRange and maybe ValueRange has minimum-Bound and Bound is inclusive,
	ValueRangeMinimumBoundIsInclusive       bit NULL,
	-- AllowedRange is where ValueRestriction allows ValueRange and maybe ValueRange has minimum-Bound and Bound has Value,
	ValueRangeMinimumBoundValue             varchar(256) NULL,
	-- AllowedRange is where ValueRestriction allows ValueRange and ValueRestriction has ValueRestrictionId,
	ValueRestrictionId                      int NOT NULL,
	UNIQUE(ValueRestrictionId, ValueRangeMinimumBoundValue, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValue, ValueRangeMaximumBoundIsInclusive)
)
GO

CREATE TABLE Derivation (
	-- Derivation is where DerivedUnit is derived from BaseUnit and Unit has UnitId,
	BaseUnitId                              int NOT NULL,
	-- Derivation is where DerivedUnit is derived from BaseUnit and Unit has UnitId,
	DerivedUnitId                           int NOT NULL,
	-- maybe Derivation has Exponent,
	Exponent                                int NULL,
	PRIMARY KEY(DerivedUnitId, BaseUnitId)
)
GO

CREATE TABLE Fact (
	-- Fact has FactId,
	FactId                                  int IDENTITY NOT NULL,
	-- Fact is of FactType and Feature has FeatureId,
	FactTypeId                              int NOT NULL,
	-- Population includes Fact and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Fact and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	PRIMARY KEY(FactId)
)
GO

CREATE TABLE Feature (
	-- maybe Concept is a subtype of Feature and Concept is independent,
	ConceptIsIndependent                    bit NULL,
	-- maybe Concept is a subtype of Feature and Concept is called Name,
	ConceptName                             varchar(64) NULL,
	-- maybe Concept is a subtype of Feature and maybe Concept uses Pronoun,
	ConceptPronoun                          varchar(20) NULL CHECK(ConceptPronoun = 'feminine' OR ConceptPronoun = 'masculine' OR ConceptPronoun = 'personal'),
	-- maybe Concept is a subtype of Feature and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	ConceptVocabularyName                   varchar(64) NULL,
	-- maybe Constraint is a subtype of Feature and maybe Constraint requires Enforcement,
	ConstraintEnforcement                   varchar(16) NULL,
	-- maybe Constraint is a subtype of Feature and maybe Name is of Constraint,
	ConstraintName                          varchar(64) NULL,
	-- maybe Constraint is a subtype of Feature and maybe Vocabulary contains Constraint and Vocabulary is called Name,
	ConstraintVocabularyName                varchar(64) NULL,
	-- maybe FactType is a subtype of Feature and maybe EntityType nests FactType and Concept is called Name,
	FactTypeEntityTypeName                  varchar(64) NULL,
	-- maybe FactType is a subtype of Feature and maybe EntityType nests FactType and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	FactTypeEntityTypeVocabularyName        varchar(64) NULL,
	-- Feature has FeatureId,
	FeatureId                               int IDENTITY NOT NULL,
	-- maybe Constraint is a subtype of Feature and maybe PresenceConstraint is a subtype of Constraint and PresenceConstraint is mandatory,
	PresenceConstraintIsMandatory           bit NULL,
	-- maybe Constraint is a subtype of Feature and maybe PresenceConstraint is a subtype of Constraint and PresenceConstraint is preferred identifier,
	PresenceConstraintIsPreferredIdentifier bit NULL,
	-- maybe Constraint is a subtype of Feature and maybe PresenceConstraint is a subtype of Constraint and maybe PresenceConstraint has max-Frequency restricted to {1..},
	PresenceConstraintMaxFrequency          int NULL CHECK(PresenceConstraintMaxFrequency >= 1),
	-- maybe Constraint is a subtype of Feature and maybe PresenceConstraint is a subtype of Constraint and maybe PresenceConstraint has min-Frequency restricted to {2..},
	PresenceConstraintMinFrequency          int NULL CHECK(PresenceConstraintMinFrequency >= 2),
	-- maybe Constraint is a subtype of Feature and maybe PresenceConstraint is a subtype of Constraint and PresenceConstraint covers RoleSequence and RoleSequence has RoleSequenceId,
	PresenceConstraintRoleSequenceId        int NULL,
	-- maybe Constraint is a subtype of Feature and maybe RingConstraint is a subtype of Constraint and maybe other-Role is of RingConstraint and Role is where FactType has Ordinal role played by Concept and Concept is called Name,
	RingConstraintOtherRoleConceptName      varchar(64) NULL,
	-- maybe Constraint is a subtype of Feature and maybe RingConstraint is a subtype of Constraint and maybe other-Role is of RingConstraint and Role is where FactType has Ordinal role played by Concept and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	RingConstraintOtherRoleConceptVocabularyName varchar(64) NULL,
	-- maybe Constraint is a subtype of Feature and maybe RingConstraint is a subtype of Constraint and maybe other-Role is of RingConstraint and Role is where FactType has Ordinal role played by Concept and Feature has FeatureId,
	RingConstraintOtherRoleFactTypeId       int NULL,
	-- maybe Constraint is a subtype of Feature and maybe RingConstraint is a subtype of Constraint and maybe other-Role is of RingConstraint and Role is where FactType has Ordinal role played by Concept,
	RingConstraintOtherRoleOrdinal          int NULL,
	-- maybe Constraint is a subtype of Feature and maybe RingConstraint is a subtype of Constraint and RingConstraint is of RingType,
	RingConstraintRingType                  varchar NULL,
	-- maybe Constraint is a subtype of Feature and maybe RingConstraint is a subtype of Constraint and maybe Role is of RingConstraint and Role is where FactType has Ordinal role played by Concept and Concept is called Name,
	RingConstraintRoleConceptName           varchar(64) NULL,
	-- maybe Constraint is a subtype of Feature and maybe RingConstraint is a subtype of Constraint and maybe Role is of RingConstraint and Role is where FactType has Ordinal role played by Concept and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	RingConstraintRoleConceptVocabularyName varchar(64) NULL,
	-- maybe Constraint is a subtype of Feature and maybe RingConstraint is a subtype of Constraint and maybe Role is of RingConstraint and Role is where FactType has Ordinal role played by Concept and Feature has FeatureId,
	RingConstraintRoleFactTypeId            int NULL,
	-- maybe Constraint is a subtype of Feature and maybe RingConstraint is a subtype of Constraint and maybe Role is of RingConstraint and Role is where FactType has Ordinal role played by Concept,
	RingConstraintRoleOrdinal               int NULL,
	-- maybe Constraint is a subtype of Feature and maybe SetConstraint is a subtype of Constraint and maybe SetComparisonConstraint is a subtype of SetConstraint and maybe SetExclusionConstraint is a subtype of SetComparisonConstraint and SetExclusionConstraint is mandatory,
	SetExclusionConstraintIsMandatory       bit NULL,
	-- maybe Constraint is a subtype of Feature and maybe SetConstraint is a subtype of Constraint and maybe SubsetConstraint is a subtype of SetConstraint and SubsetConstraint covers subset-RoleSequence and RoleSequence has RoleSequenceId,
	SubsetConstraintSubsetRoleSequenceId    int NULL,
	-- maybe Constraint is a subtype of Feature and maybe SetConstraint is a subtype of Constraint and maybe SubsetConstraint is a subtype of SetConstraint and SubsetConstraint covers superset-RoleSequence and RoleSequence has RoleSequenceId,
	SubsetConstraintSupersetRoleSequenceId  int NULL,
	-- maybe FactType is a subtype of Feature and maybe TypeInheritance is a subtype of FactType and TypeInheritance provides identification,
	TypeInheritanceProvidesIdentification   bit NULL,
	-- maybe FactType is a subtype of Feature and maybe TypeInheritance is a subtype of FactType and TypeInheritance is where Subtype is subtype of Supertype and Concept is called Name,
	TypeInheritanceSubtypeName              varchar(64) NULL,
	-- maybe FactType is a subtype of Feature and maybe TypeInheritance is a subtype of FactType and TypeInheritance is where Subtype is subtype of Supertype and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	TypeInheritanceSubtypeVocabularyName    varchar(64) NULL,
	-- maybe FactType is a subtype of Feature and maybe TypeInheritance is a subtype of FactType and TypeInheritance is where Subtype is subtype of Supertype and Concept is called Name,
	TypeInheritanceSupertypeName            varchar(64) NULL,
	-- maybe FactType is a subtype of Feature and maybe TypeInheritance is a subtype of FactType and TypeInheritance is where Subtype is subtype of Supertype and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	TypeInheritanceSupertypeVocabularyName  varchar(64) NULL,
	-- maybe Concept is a subtype of Feature and maybe ValueType is a subtype of Concept and maybe ValueType has Length,
	ValueTypeLength                         int NULL,
	-- maybe Concept is a subtype of Feature and maybe ValueType is a subtype of Concept and maybe ValueType has Scale,
	ValueTypeScale                          int NULL,
	-- maybe Concept is a subtype of Feature and maybe ValueType is a subtype of Concept and maybe ValueType is subtype of Supertype and Concept is called Name,
	ValueTypeSupertypeName                  varchar(64) NULL,
	-- maybe Concept is a subtype of Feature and maybe ValueType is a subtype of Concept and maybe ValueType is subtype of Supertype and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeSupertypeVocabularyName        varchar(64) NULL,
	-- maybe Concept is a subtype of Feature and maybe ValueType is a subtype of Concept and maybe ValueType is of Unit and Unit has UnitId,
	ValueTypeUnitId                         int NULL,
	-- maybe Concept is a subtype of Feature and maybe ValueType is a subtype of Concept and maybe ValueType has ValueRestriction and ValueRestriction has ValueRestrictionId,
	ValueTypeValueRestrictionId             int NULL,
	PRIMARY KEY(FeatureId)
)
GO

CREATE VIEW dbo.ConceptInFeature_VocabularyNameName (ConceptVocabularyName, ConceptName) WITH SCHEMABINDING AS
	SELECT ConceptVocabularyName, ConceptName FROM dbo.Feature
	WHERE	ConceptVocabularyName IS NOT NULL
	  AND	ConceptName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX NameIsUniqueInVocabulary ON dbo.ConceptInFeature_VocabularyNameName(ConceptVocabularyName, ConceptName)
GO

CREATE VIEW dbo.ConstraintInFeature_VocabularyNameName (ConstraintVocabularyName, ConstraintName) WITH SCHEMABINDING AS
	SELECT ConstraintVocabularyName, ConstraintName FROM dbo.Feature
	WHERE	ConstraintVocabularyName IS NOT NULL
	  AND	ConstraintName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ConstraintInFeatureByConstraintVocabularyNameConstraintName ON dbo.ConstraintInFeature_VocabularyNameName(ConstraintVocabularyName, ConstraintName)
GO

CREATE VIEW dbo.FactTypeInFeature_EntityTypeVocabularyNameEntityTypeName (FactTypeEntityTypeVocabularyName, FactTypeEntityTypeName) WITH SCHEMABINDING AS
	SELECT FactTypeEntityTypeVocabularyName, FactTypeEntityTypeName FROM dbo.Feature
	WHERE	FactTypeEntityTypeVocabularyName IS NOT NULL
	  AND	FactTypeEntityTypeName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX EntityTypeNestsOneFactType ON dbo.FactTypeInFeature_EntityTypeVocabularyNameEntityTypeName(FactTypeEntityTypeVocabularyName, FactTypeEntityTypeName)
GO

CREATE VIEW dbo.SubsetConstraintInFeature_SubsetRoleSequenceIdSupersetRoleSequenceId (SubsetConstraintSubsetRoleSequenceId, SubsetConstraintSupersetRoleSequenceId) WITH SCHEMABINDING AS
	SELECT SubsetConstraintSubsetRoleSequenceId, SubsetConstraintSupersetRoleSequenceId FROM dbo.Feature
	WHERE	SubsetConstraintSubsetRoleSequenceId IS NOT NULL
	  AND	SubsetConstraintSupersetRoleSequenceId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_SubsetConstraintInFeatureBySubsetConstraintSubsetRoleSequenceIdSubsetConstraintSupersetRoleSequenceId ON dbo.SubsetConstraintInFeature_SubsetRoleSequenceIdSupersetRoleSequenceId(SubsetConstraintSubsetRoleSequenceId, SubsetConstraintSupersetRoleSequenceId)
GO

CREATE VIEW dbo.TypeInheritanceInFeature_SubtypeVocabularyNameSubtypeNameProvidesIdentification (TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceProvidesIdentification) WITH SCHEMABINDING AS
	SELECT TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceProvidesIdentification FROM dbo.Feature
	WHERE	TypeInheritanceSubtypeVocabularyName IS NOT NULL
	  AND	TypeInheritanceSubtypeName IS NOT NULL
	  AND	TypeInheritanceProvidesIdentification IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX OnlyOneSupertypeMayBePrimary ON dbo.TypeInheritanceInFeature_SubtypeVocabularyNameSubtypeNameProvidesIdentification(TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceProvidesIdentification)
GO

CREATE VIEW dbo.TypeInheritanceInFeature_SubtypeVocabularyNameSubtypeNameSupertypeVocabularyNameSupertypeName (TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceSupertypeVocabularyName, TypeInheritanceSupertypeName) WITH SCHEMABINDING AS
	SELECT TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceSupertypeVocabularyName, TypeInheritanceSupertypeName FROM dbo.Feature
	WHERE	TypeInheritanceSubtypeVocabularyName IS NOT NULL
	  AND	TypeInheritanceSubtypeName IS NOT NULL
	  AND	TypeInheritanceSupertypeVocabularyName IS NOT NULL
	  AND	TypeInheritanceSupertypeName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PK_TypeInheritanceInFeature ON dbo.TypeInheritanceInFeature_SubtypeVocabularyNameSubtypeNameSupertypeVocabularyNameSupertypeName(TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceSupertypeVocabularyName, TypeInheritanceSupertypeName)
GO

CREATE TABLE Instance (
	-- Instance is of Concept and Concept is called Name,
	ConceptName                             varchar(64) NOT NULL,
	-- Instance is of Concept and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	ConceptVocabularyName                   varchar(64) NULL,
	-- Instance has InstanceId,
	InstanceId                              int IDENTITY NOT NULL,
	-- Population includes Instance and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Instance and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	-- maybe Instance has Value,
	Value                                   varchar(256) NULL,
	PRIMARY KEY(InstanceId),
	FOREIGN KEY (ConceptName, ConceptVocabularyName) REFERENCES Feature (ConceptName, ConceptVocabularyName)
)
GO

CREATE TABLE [Join] (
	-- maybe Join traverses Concept and Concept is called Name,
	ConceptName                             varchar(64) NULL,
	-- maybe Join traverses Concept and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	ConceptVocabularyName                   varchar(64) NULL,
	-- maybe Join has input-Role and Role is where FactType has Ordinal role played by Concept and Concept is called Name,
	InputRoleConceptName                    varchar(64) NULL,
	-- maybe Join has input-Role and Role is where FactType has Ordinal role played by Concept and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	InputRoleConceptVocabularyName          varchar(64) NULL,
	-- maybe Join has input-Role and Role is where FactType has Ordinal role played by Concept and Feature has FeatureId,
	InputRoleFactTypeId                     int NULL,
	-- maybe Join has input-Role and Role is where FactType has Ordinal role played by Concept,
	InputRoleOrdinal                        int NULL,
	-- Join is where RoleRef has JoinStep join,
	JoinStep                                int NOT NULL,
	-- maybe Join has output-Role and Role is where FactType has Ordinal role played by Concept and Concept is called Name,
	OutputRoleConceptName                   varchar(64) NULL,
	-- maybe Join has output-Role and Role is where FactType has Ordinal role played by Concept and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	OutputRoleConceptVocabularyName         varchar(64) NULL,
	-- maybe Join has output-Role and Role is where FactType has Ordinal role played by Concept and Feature has FeatureId,
	OutputRoleFactTypeId                    int NULL,
	-- maybe Join has output-Role and Role is where FactType has Ordinal role played by Concept,
	OutputRoleOrdinal                       int NULL,
	-- Join is where RoleRef has JoinStep join and RoleRef is where RoleSequence in Ordinal position includes Role,
	RoleRefOrdinal                          int NOT NULL,
	-- Join is where RoleRef has JoinStep join and RoleRef is where RoleSequence in Ordinal position includes Role and RoleSequence has RoleSequenceId,
	RoleRefRoleSequenceId                   int NOT NULL,
	PRIMARY KEY(RoleRefRoleSequenceId, RoleRefOrdinal, JoinStep),
	FOREIGN KEY (ConceptName, ConceptVocabularyName) REFERENCES Feature (ConceptName, ConceptVocabularyName)
)
GO

CREATE TABLE ParamValue (
	-- ParamValue is where Value for Parameter applies to ValueType and Parameter is where Name is a parameter of ValueType,
	ParameterName                           varchar(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Parameter is where Name is a parameter of ValueType and Concept is called Name,
	ParameterValueTypeName                  varchar(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Parameter is where Name is a parameter of ValueType and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	ParameterValueTypeVocabularyName        varchar(64) NULL,
	-- ParamValue is where Value for Parameter applies to ValueType,
	Value                                   varchar(256) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Concept is called Name,
	ValueTypeName                           varchar(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	ValueTypeVocabularyName                 varchar(64) NULL,
	UNIQUE(Value, ParameterName, ParameterValueTypeVocabularyName, ParameterValueTypeName),
	FOREIGN KEY (ValueTypeName, ValueTypeVocabularyName) REFERENCES Feature (ConceptName, ConceptVocabularyName)
)
GO

CREATE TABLE Reading (
	-- FactType has Reading and Feature has FeatureId,
	FactTypeId                              int NOT NULL,
	-- Reading is in Ordinal position,
	Ordinal                                 int NOT NULL,
	-- Reading is in RoleSequence and RoleSequence has RoleSequenceId,
	RoleSequenceId                          int NOT NULL,
	-- Reading has Text,
	Text                                    varchar(256) NOT NULL,
	PRIMARY KEY(FactTypeId, Ordinal),
	FOREIGN KEY (FactTypeId) REFERENCES Feature (FeatureId)
)
GO

CREATE TABLE Role (
	-- Role is where FactType has Ordinal role played by Concept and Concept is called Name,
	ConceptName                             varchar(64) NOT NULL,
	-- Role is where FactType has Ordinal role played by Concept and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	ConceptVocabularyName                   varchar(64) NULL,
	-- Role is where FactType has Ordinal role played by Concept and Feature has FeatureId,
	FactTypeId                              int NOT NULL,
	-- Role is where FactType has Ordinal role played by Concept,
	Ordinal                                 int NOT NULL,
	-- maybe Role has role-Name,
	RoleName                                varchar(64) NULL,
	-- maybe Role has role-ValueRestriction and ValueRestriction has ValueRestrictionId,
	RoleValueRestrictionId                  int NULL,
	UNIQUE(FactTypeId, Ordinal, ConceptVocabularyName, ConceptName),
	FOREIGN KEY (ConceptName, ConceptVocabularyName) REFERENCES Feature (ConceptName, ConceptVocabularyName),
	FOREIGN KEY (FactTypeId) REFERENCES Feature (FeatureId)
)
GO

CREATE TABLE RoleRef (
	-- maybe RoleRef has leading-Adjective,
	LeadingAdjective                        varchar(64) NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role,
	Ordinal                                 int NOT NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and Role is where FactType has Ordinal role played by Concept and Concept is called Name,
	RoleConceptName                         varchar(64) NOT NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and Role is where FactType has Ordinal role played by Concept and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	RoleConceptVocabularyName               varchar(64) NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and Role is where FactType has Ordinal role played by Concept and Feature has FeatureId,
	RoleFactTypeId                          int NOT NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and Role is where FactType has Ordinal role played by Concept,
	RoleOrdinal                             int NOT NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and RoleSequence has RoleSequenceId,
	RoleSequenceId                          int NOT NULL,
	-- maybe RoleRef has trailing-Adjective,
	TrailingAdjective                       varchar(64) NULL,
	PRIMARY KEY(RoleSequenceId, Ordinal),
	FOREIGN KEY (RoleConceptName, RoleConceptVocabularyName, RoleFactTypeId, RoleOrdinal) REFERENCES Role (ConceptName, ConceptVocabularyName, FactTypeId, Ordinal)
)
GO

CREATE VIEW dbo.RoleRef_RoleFactTypeIdRoleOrdinalRoleConceptVocabularyNameRoleConceptNameRoleSequenceId (RoleFactTypeId, RoleOrdinal, RoleConceptVocabularyName, RoleConceptName, RoleSequenceId) WITH SCHEMABINDING AS
	SELECT RoleFactTypeId, RoleOrdinal, RoleConceptVocabularyName, RoleConceptName, RoleSequenceId FROM dbo.RoleRef
	WHERE	RoleConceptVocabularyName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleRefByRoleFactTypeIdRoleOrdinalRoleConceptVocabularyNameRoleConceptNameRoleSequenceId ON dbo.RoleRef_RoleFactTypeIdRoleOrdinalRoleConceptVocabularyNameRoleConceptNameRoleSequenceId(RoleFactTypeId, RoleOrdinal, RoleConceptVocabularyName, RoleConceptName, RoleSequenceId)
GO

CREATE TABLE RoleSequence (
	-- RoleSequence has RoleSequenceId,
	RoleSequenceId                          int IDENTITY NOT NULL,
	PRIMARY KEY(RoleSequenceId)
)
GO

CREATE TABLE RoleValue (
	-- RoleValue fulfils Fact and Fact has FactId,
	FactId                                  int NOT NULL,
	-- Instance plays RoleValue and Instance has InstanceId,
	InstanceId                              int NOT NULL,
	-- Population includes RoleValue and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes RoleValue and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	-- RoleValue is of Role and Role is where FactType has Ordinal role played by Concept and Concept is called Name,
	RoleConceptName                         varchar(64) NOT NULL,
	-- RoleValue is of Role and Role is where FactType has Ordinal role played by Concept and maybe Concept belongs to Vocabulary and Vocabulary is called Name,
	RoleConceptVocabularyName               varchar(64) NULL,
	-- RoleValue is of Role and Role is where FactType has Ordinal role played by Concept and Feature has FeatureId,
	RoleFactTypeId                          int NOT NULL,
	-- RoleValue is of Role and Role is where FactType has Ordinal role played by Concept,
	RoleOrdinal                             int NOT NULL,
	PRIMARY KEY(InstanceId, FactId),
	FOREIGN KEY (FactId) REFERENCES Fact (FactId),
	FOREIGN KEY (InstanceId) REFERENCES Instance (InstanceId),
	FOREIGN KEY (RoleConceptName, RoleConceptVocabularyName, RoleFactTypeId, RoleOrdinal) REFERENCES Role (ConceptName, ConceptVocabularyName, FactTypeId, Ordinal)
)
GO

CREATE TABLE SetComparisonRoles (
	-- SetComparisonRoles is where SetComparisonConstraint has in Ordinal position RoleSequence,
	Ordinal                                 int NOT NULL,
	-- SetComparisonRoles is where SetComparisonConstraint has in Ordinal position RoleSequence and RoleSequence has RoleSequenceId,
	RoleSequenceId                          int NOT NULL,
	-- SetComparisonRoles is where SetComparisonConstraint has in Ordinal position RoleSequence and Feature has FeatureId,
	SetComparisonConstraintId               int NOT NULL,
	PRIMARY KEY(SetComparisonConstraintId, Ordinal),
	UNIQUE(SetComparisonConstraintId, RoleSequenceId),
	FOREIGN KEY (SetComparisonConstraintId) REFERENCES Feature (FeatureId),
	FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
)
GO

CREATE TABLE Unit (
	-- maybe Unit has Coefficient and Coefficient has Denominator,
	CoefficientDenominator                  int NULL,
	-- maybe Unit has Coefficient and Coefficient is precise,
	CoefficientIsPrecise                    bit NULL,
	-- maybe Unit has Coefficient and Coefficient has Numerator,
	CoefficientNumerator                    decimal NULL,
	-- Unit is fundamental,
	IsFundamental                           bit NOT NULL,
	-- Name is of Unit,
	Name                                    varchar(64) NOT NULL,
	-- maybe Unit has Offset,
	Offset                                  decimal NULL,
	-- Unit has UnitId,
	UnitId                                  int IDENTITY NOT NULL,
	-- Vocabulary includes Unit and Vocabulary is called Name,
	VocabularyName                          varchar(64) NOT NULL,
	PRIMARY KEY(UnitId),
	UNIQUE(VocabularyName, Name)
)
GO

CREATE TABLE ValueRestriction (
	-- ValueRestriction has ValueRestrictionId,
	ValueRestrictionId                      int IDENTITY NOT NULL,
	PRIMARY KEY(ValueRestrictionId)
)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueRestrictionId) REFERENCES ValueRestriction (ValueRestrictionId)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (BaseUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (DerivedUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE Fact
	ADD FOREIGN KEY (FactTypeId) REFERENCES Feature (FeatureId)
GO

ALTER TABLE Feature
	ADD FOREIGN KEY (FactTypeEntityTypeName, FactTypeEntityTypeVocabularyName) REFERENCES Feature (ConceptName, ConceptVocabularyName)
GO

ALTER TABLE Feature
	ADD FOREIGN KEY (TypeInheritanceSubtypeName, TypeInheritanceSubtypeVocabularyName) REFERENCES Feature (ConceptName, ConceptVocabularyName)
GO

ALTER TABLE Feature
	ADD FOREIGN KEY (TypeInheritanceSupertypeName, TypeInheritanceSupertypeVocabularyName) REFERENCES Feature (ConceptName, ConceptVocabularyName)
GO

ALTER TABLE Feature
	ADD FOREIGN KEY (ValueTypeSupertypeName, ValueTypeSupertypeVocabularyName) REFERENCES Feature (ConceptName, ConceptVocabularyName)
GO

ALTER TABLE Feature
	ADD FOREIGN KEY (RingConstraintOtherRoleConceptName, RingConstraintOtherRoleConceptVocabularyName, RingConstraintOtherRoleFactTypeId, RingConstraintOtherRoleOrdinal) REFERENCES Role (ConceptName, ConceptVocabularyName, FactTypeId, Ordinal)
GO

ALTER TABLE Feature
	ADD FOREIGN KEY (RingConstraintRoleConceptName, RingConstraintRoleConceptVocabularyName, RingConstraintRoleFactTypeId, RingConstraintRoleOrdinal) REFERENCES Role (ConceptName, ConceptVocabularyName, FactTypeId, Ordinal)
GO

ALTER TABLE Feature
	ADD FOREIGN KEY (PresenceConstraintRoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
GO

ALTER TABLE Feature
	ADD FOREIGN KEY (SubsetConstraintSubsetRoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
GO

ALTER TABLE Feature
	ADD FOREIGN KEY (SubsetConstraintSupersetRoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
GO

ALTER TABLE Feature
	ADD FOREIGN KEY (ValueTypeUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE Feature
	ADD FOREIGN KEY (ValueTypeValueRestrictionId) REFERENCES ValueRestriction (ValueRestrictionId)
GO

ALTER TABLE [Join]
	ADD FOREIGN KEY (InputRoleConceptName, InputRoleConceptVocabularyName, InputRoleFactTypeId, InputRoleOrdinal) REFERENCES Role (ConceptName, ConceptVocabularyName, FactTypeId, Ordinal)
GO

ALTER TABLE [Join]
	ADD FOREIGN KEY (OutputRoleConceptName, OutputRoleConceptVocabularyName, OutputRoleFactTypeId, OutputRoleOrdinal) REFERENCES Role (ConceptName, ConceptVocabularyName, FactTypeId, Ordinal)
GO

ALTER TABLE [Join]
	ADD FOREIGN KEY (RoleRefOrdinal, RoleRefRoleSequenceId) REFERENCES RoleRef (Ordinal, RoleSequenceId)
GO

ALTER TABLE Reading
	ADD FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
GO

ALTER TABLE Role
	ADD FOREIGN KEY (RoleValueRestrictionId) REFERENCES ValueRestriction (ValueRestrictionId)
GO

ALTER TABLE RoleRef
	ADD FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
GO

