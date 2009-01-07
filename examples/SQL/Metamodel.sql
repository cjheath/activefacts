CREATE TABLE AllowedRange (
	ValueRestrictionId                      int NOT NULL,
	ValueRangeMinimumBoundValue             varchar(256) NULL,
	ValueRangeMinimumBoundIsInclusive       bit NULL,
	ValueRangeMaximumBoundValue             varchar(256) NULL,
	ValueRangeMaximumBoundIsInclusive       bit NULL,
	UNIQUE(ValueRestrictionId, ValueRangeMinimumBoundValue, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValue, ValueRangeMaximumBoundIsInclusive)
)
GO

CREATE TABLE [Constraint] (
	ConstraintId                            int IDENTITY NOT NULL,
	Name                                    varchar(64) NULL,
	Enforcement                             varchar(16) NULL,
	VocabularyName                          varchar(64) NULL,
	RingConstraintRoleFactTypeId            int NULL,
	RingConstraintRoleOrdinal               int NULL,
	RingConstraintRoleConceptName           varchar(64) NULL,
	RingConstraintRoleConceptVocabularyName varchar(64) NULL,
	RingConstraintOtherRoleFactTypeId       int NULL,
	RingConstraintOtherRoleOrdinal          int NULL,
	RingConstraintOtherRoleConceptName      varchar(64) NULL,
	RingConstraintOtherRoleConceptVocabularyName varchar(64) NULL,
	RingConstraintRingType                  varchar NULL,
	PresenceConstraintRoleSequenceId        int NULL,
	PresenceConstraintMaxFrequency          int NULL CHECK(PresenceConstraintMaxFrequency >= 1),
	PresenceConstraintMinFrequency          int NULL CHECK(PresenceConstraintMinFrequency >= 2),
	PresenceConstraintIsPreferredIdentifier bit NULL,
	PresenceConstraintIsMandatory           bit NULL,
	SetExclusionConstraintIsMandatory       bit NULL,
	SubsetConstraintSupersetRoleSequenceId  int NULL,
	SubsetConstraintSubsetRoleSequenceId    int NULL,
	PRIMARY KEY(ConstraintId)
)
GO

CREATE TABLE Correspondence (
	ImportVocabularyName                    varchar(64) NOT NULL,
	ImportImportedVocabularyName            varchar(64) NOT NULL,
	ImportedFeatureName                     varchar(64) NOT NULL,
	ImportedFeatureVocabularyName           varchar(64) NULL,
	LocalFeatureName                        varchar(64) NOT NULL,
	LocalFeatureVocabularyName              varchar(64) NULL,
	UNIQUE(ImportVocabularyName, ImportImportedVocabularyName, ImportedFeatureName, ImportedFeatureVocabularyName)
)
GO

CREATE TABLE Derivation (
	DerivedUnitId                           int NOT NULL,
	BaseUnitId                              int NOT NULL,
	Exponent                                int NULL,
	PRIMARY KEY(DerivedUnitId, BaseUnitId)
)
GO

CREATE TABLE Fact (
	FactId                                  int IDENTITY NOT NULL,
	FactTypeId                              int NOT NULL,
	PopulationName                          varchar(64) NOT NULL,
	PopulationVocabularyName                varchar(64) NULL,
	PRIMARY KEY(FactId)
)
GO

CREATE TABLE FactType (
	FactTypeId                              int IDENTITY NOT NULL,
	EntityTypeName                          varchar(64) NULL,
	EntityTypeVocabularyName                varchar(64) NULL,
	TypeInheritanceSubtypeName              varchar(64) NULL,
	TypeInheritanceSubtypeVocabularyName    varchar(64) NULL,
	TypeInheritanceSupertypeName            varchar(64) NULL,
	TypeInheritanceSupertypeVocabularyName  varchar(64) NULL,
	TypeInheritanceProvidesIdentification   bit NULL,
	PRIMARY KEY(FactTypeId)
)
GO

CREATE TABLE Feature (
	Name                                    varchar(64) NOT NULL,
	VocabularyName                          varchar(64) NULL,
	ConceptIsIndependent                    bit NULL,
	ConceptIsPersonal                       bit NULL,
	ValueTypeSupertypeName                  varchar(64) NULL,
	ValueTypeSupertypeVocabularyName        varchar(64) NULL,
	ValueTypeLength                         int NULL,
	ValueTypeScale                          int NULL,
	ValueTypeValueRestrictionId             int NULL,
	ValueTypeUnitId                         int NULL,
	UNIQUE(Name, VocabularyName)
)
GO

CREATE TABLE Instance (
	InstanceId                              int IDENTITY NOT NULL,
	Value                                   varchar(256) NULL,
	ConceptName                             varchar(64) NOT NULL,
	ConceptVocabularyName                   varchar(64) NULL,
	PopulationName                          varchar(64) NOT NULL,
	PopulationVocabularyName                varchar(64) NULL,
	PRIMARY KEY(InstanceId),
	FOREIGN KEY (ConceptName, ConceptVocabularyName) REFERENCES Feature (Name, VocabularyName)
)
GO

CREATE TABLE JoinPath (
	RoleRefRoleSequenceId                   int NOT NULL,
	RoleRefOrdinal                          int NOT NULL,
	JoinStep                                int NOT NULL,
	InputRoleFactTypeId                     int NOT NULL,
	InputRoleOrdinal                        int NOT NULL,
	InputRoleConceptName                    varchar(64) NOT NULL,
	InputRoleConceptVocabularyName          varchar(64) NULL,
	OutputRoleFactTypeId                    int NOT NULL,
	OutputRoleOrdinal                       int NOT NULL,
	OutputRoleConceptName                   varchar(64) NOT NULL,
	OutputRoleConceptVocabularyName         varchar(64) NULL,
	ConceptName                             varchar(64) NULL,
	ConceptVocabularyName                   varchar(64) NULL,
	PRIMARY KEY(RoleRefRoleSequenceId, RoleRefOrdinal, JoinStep),
	FOREIGN KEY (ConceptName, ConceptVocabularyName) REFERENCES Feature (Name, VocabularyName)
)
GO

CREATE TABLE Reading (
	FactTypeId                              int NOT NULL,
	Text                                    varchar(256) NOT NULL,
	RoleSequenceId                          int NOT NULL,
	Ordinal                                 int NOT NULL,
	PRIMARY KEY(FactTypeId, Ordinal),
	FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId)
)
GO

CREATE TABLE Role (
	FactTypeId                              int NOT NULL,
	Ordinal                                 int NOT NULL,
	ConceptName                             varchar(64) NOT NULL,
	ConceptVocabularyName                   varchar(64) NULL,
	RoleName                                varchar(64) NULL,
	RoleValueRestrictionId                  int NULL,
	UNIQUE(FactTypeId, Ordinal, ConceptName, ConceptVocabularyName),
	FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId),
	FOREIGN KEY (ConceptName, ConceptVocabularyName) REFERENCES Feature (Name, VocabularyName)
)
GO

CREATE TABLE RoleRef (
	RoleSequenceId                          int NOT NULL,
	Ordinal                                 int NOT NULL,
	RoleFactTypeId                          int NOT NULL,
	RoleOrdinal                             int NOT NULL,
	RoleConceptName                         varchar(64) NOT NULL,
	RoleConceptVocabularyName               varchar(64) NULL,
	LeadingAdjective                        varchar(64) NULL,
	TrailingAdjective                       varchar(64) NULL,
	PRIMARY KEY(RoleSequenceId, Ordinal),
	FOREIGN KEY (RoleFactTypeId, RoleOrdinal, RoleConceptName, RoleConceptVocabularyName) REFERENCES Role (FactTypeId, Ordinal, ConceptName, ConceptVocabularyName)
)
GO

CREATE TABLE RoleSequence (
	RoleSequenceId                          int IDENTITY NOT NULL,
	PRIMARY KEY(RoleSequenceId)
)
GO

CREATE TABLE RoleValue (
	PopulationName                          varchar(64) NOT NULL,
	PopulationVocabularyName                varchar(64) NULL,
	FactId                                  int NOT NULL,
	InstanceId                              int NOT NULL,
	RoleFactTypeId                          int NOT NULL,
	RoleOrdinal                             int NOT NULL,
	RoleConceptName                         varchar(64) NOT NULL,
	RoleConceptVocabularyName               varchar(64) NULL,
	PRIMARY KEY(InstanceId, FactId),
	FOREIGN KEY (FactId) REFERENCES Fact (FactId),
	FOREIGN KEY (InstanceId) REFERENCES Instance (InstanceId),
	FOREIGN KEY (RoleFactTypeId, RoleOrdinal, RoleConceptName, RoleConceptVocabularyName) REFERENCES Role (FactTypeId, Ordinal, ConceptName, ConceptVocabularyName)
)
GO

CREATE TABLE SetComparisonRoles (
	SetComparisonConstraintId               int NOT NULL,
	RoleSequenceId                          int NOT NULL,
	PRIMARY KEY(SetComparisonConstraintId, RoleSequenceId),
	FOREIGN KEY (SetComparisonConstraintId) REFERENCES [Constraint] (ConstraintId),
	FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
)
GO

CREATE TABLE Unit (
	UnitId                                  int IDENTITY NOT NULL,
	CoefficientIsPrecise                    bit NULL,
	CoefficientNumerator                    decimal NULL,
	CoefficientDenominator                  int NULL,
	Name                                    varchar(64) NOT NULL,
	IsFundamental                           bit NOT NULL,
	PRIMARY KEY(UnitId)
)
GO

CREATE TABLE ValueRestriction (
	ValueRestrictionId                      int IDENTITY NOT NULL,
	PRIMARY KEY(ValueRestrictionId)
)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueRestrictionId) REFERENCES ValueRestriction (ValueRestrictionId)
GO

ALTER TABLE Correspondence
	ADD FOREIGN KEY (ImportedFeatureName, ImportedFeatureVocabularyName) REFERENCES Feature (Name, VocabularyName)
GO

ALTER TABLE Correspondence
	ADD FOREIGN KEY (LocalFeatureName, LocalFeatureVocabularyName) REFERENCES Feature (Name, VocabularyName)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (DerivedUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (BaseUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE Fact
	ADD FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId)
GO

ALTER TABLE FactType
	ADD FOREIGN KEY (EntityTypeName, EntityTypeVocabularyName) REFERENCES Feature (Name, VocabularyName)
GO

ALTER TABLE JoinPath
	ADD FOREIGN KEY (RoleRefRoleSequenceId, RoleRefOrdinal) REFERENCES RoleRef (RoleSequenceId, Ordinal)
GO

ALTER TABLE JoinPath
	ADD FOREIGN KEY (InputRoleFactTypeId, InputRoleOrdinal, InputRoleConceptName, InputRoleConceptVocabularyName) REFERENCES Role (FactTypeId, Ordinal, ConceptName, ConceptVocabularyName)
GO

ALTER TABLE JoinPath
	ADD FOREIGN KEY (OutputRoleFactTypeId, OutputRoleOrdinal, OutputRoleConceptName, OutputRoleConceptVocabularyName) REFERENCES Role (FactTypeId, Ordinal, ConceptName, ConceptVocabularyName)
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

