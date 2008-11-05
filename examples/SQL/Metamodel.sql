CREATE TABLE AllowedRange (
	ValueRangeMaximumBoundIsInclusive	bit NULL,
	ValueRangeMaximumBoundValue	varchar(256) NULL,
	ValueRangeMinimumBoundIsInclusive	bit NULL,
	ValueRangeMinimumBoundValue	varchar(256) NULL,
	ValueRestrictionId	int NOT NULL,
	UNIQUE(ValueRangeMinimumBoundValue, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValue, ValueRangeMaximumBoundIsInclusive, ValueRestrictionId)
)
GO

CREATE TABLE Constraint (
	ConstraintId	int NOT NULL,
	Enforcement	varchar(16) NULL,
	Name	varchar(64) NULL,
	PresenceConstraintIsMandatory	bit NULL,
	PresenceConstraintIsPreferredIdentifier	bit NULL,
	PresenceConstraintMaxFrequency	int NULL,
	PresenceConstraintMinFrequency	int NULL,
	PresenceConstraintRoleSequenceId	int NULL,
	RingConstraintOtherRoleConceptName	varchar(64) NULL,
	RingConstraintOtherRoleConceptVocabularyName	varchar(64) NULL,
	RingConstraintOtherRoleFactTypeId	int NULL,
	RingConstraintOtherRoleOrdinal	UnsignedSmallInteger(32) NULL,
	RingConstraintRingType	varchar NULL,
	RingConstraintRoleConceptName	varchar(64) NULL,
	RingConstraintRoleConceptVocabularyName	varchar(64) NULL,
	RingConstraintRoleFactTypeId	int NULL,
	RingConstraintRoleOrdinal	UnsignedSmallInteger(32) NULL,
	SetExclusionConstraintIsMandatory	bit NULL,
	SubsetConstraintSubsetRoleSequenceId	int NULL,
	SubsetConstraintSupersetRoleSequenceId	int NULL,
	VocabularyName	varchar(64) NULL,
	UNIQUE(ConstraintId)
)
GO

CREATE TABLE Correspondence (
	ImportImportedVocabularyName	varchar(64) NOT NULL,
	ImportVocabularyName	varchar(64) NOT NULL,
	ImportedFeatureName	varchar(64) NOT NULL,
	ImportedFeatureVocabularyName	varchar(64) NULL,
	LocalFeatureName	varchar(64) NOT NULL,
	LocalFeatureVocabularyName	varchar(64) NULL,
	UNIQUE(ImportedFeatureName, ImportedFeatureVocabularyName, ImportImportedVocabularyName, ImportVocabularyName)
)
GO

CREATE TABLE Fact (
	FactId	int NOT NULL,
	FactTypeId	int NOT NULL,
	PopulationName	varchar(64) NOT NULL,
	PopulationVocabularyName	varchar(64) NULL,
	UNIQUE(FactId)
)
GO

CREATE TABLE FactType (
	FactTypeId	int NOT NULL,
	EntityTypeName	varchar(64) NULL,
	EntityTypeVocabularyName	varchar(64) NULL,
	TypeInheritanceProvidesIdentification	bit NULL,
	TypeInheritanceSubtypeName	varchar(64) NULL,
	TypeInheritanceSubtypeVocabularyName	varchar(64) NULL,
	TypeInheritanceSupertypeName	varchar(64) NULL,
	TypeInheritanceSupertypeVocabularyName	varchar(64) NULL,
	UNIQUE(FactTypeId)
)
GO

CREATE TABLE Feature (
	Name	varchar(64) NOT NULL,
	VocabularyName	varchar(64) NULL,
	ConceptIsIndependent	bit NULL,
	ConceptIsPersonal	bit NULL,
	EntityTypeFactTypeId	int NULL,
	ValueTypeLength	int NULL,
	ValueTypeScale	int NULL,
	ValueTypeSupertypeName	varchar(64) NULL,
	ValueTypeSupertypeVocabularyName	varchar(64) NULL,
	ValueTypeUnitId	int NULL,
	ValueTypeValueRestrictionId	int NULL,
	UNIQUE(Name, VocabularyName)
)
GO

CREATE TABLE Instance (
	InstanceId	int NOT NULL,
	ConceptName	varchar(64) NOT NULL,
	ConceptVocabularyName	varchar(64) NULL,
	PopulationName	varchar(64) NOT NULL,
	PopulationVocabularyName	varchar(64) NULL,
	Value	varchar(256) NULL,
	UNIQUE(InstanceId)
)
GO

CREATE TABLE JoinPath (
	JoinStep	UnsignedSmallInteger(32) NOT NULL,
	RoleRefOrdinal	UnsignedSmallInteger(32) NOT NULL,
	RoleRefRoleSequenceId	int NOT NULL,
	ConceptName	varchar(64) NULL,
	ConceptVocabularyName	varchar(64) NULL,
	InputRoleConceptName	varchar(64) NOT NULL,
	InputRoleConceptVocabularyName	varchar(64) NULL,
	InputRoleFactTypeId	int NOT NULL,
	InputRoleOrdinal	UnsignedSmallInteger(32) NOT NULL,
	OutputRoleConceptName	varchar(64) NOT NULL,
	OutputRoleConceptVocabularyName	varchar(64) NULL,
	OutputRoleFactTypeId	int NOT NULL,
	OutputRoleOrdinal	UnsignedSmallInteger(32) NOT NULL,
	UNIQUE(RoleRefRoleSequenceId, RoleRefOrdinal, JoinStep)
)
GO

CREATE TABLE Reading (
	FactTypeId	int NOT NULL,
	Ordinal	UnsignedSmallInteger(32) NULL,
	ReadingText	varchar(256) NOT NULL,
	RoleSequenceId	int NOT NULL,
	UNIQUE(FactTypeId, Ordinal)
)
GO

CREATE TABLE Role (
	ConceptName	varchar(64) NOT NULL,
	ConceptVocabularyName	varchar(64) NULL,
	FactTypeId	int NOT NULL,
	Ordinal	UnsignedSmallInteger(32) NOT NULL,
	RoleName	varchar(64) NULL,
	RoleValueRestrictionId	int NULL,
	UNIQUE(FactTypeId, Ordinal, ConceptName, ConceptVocabularyName)
)
GO

CREATE TABLE RoleRef (
	Ordinal	UnsignedSmallInteger(32) NOT NULL,
	RoleSequenceId	int NOT NULL,
	LeadingAdjective	varchar(64) NULL,
	RoleConceptName	varchar(64) NOT NULL,
	RoleConceptVocabularyName	varchar(64) NULL,
	RoleFactTypeId	int NOT NULL,
	RoleOrdinal	UnsignedSmallInteger(32) NOT NULL,
	TrailingAdjective	varchar(64) NULL,
	UNIQUE(RoleSequenceId, Ordinal)
)
GO

CREATE TABLE RoleSequence (
	RoleSequenceId	int NOT NULL,
	UNIQUE(RoleSequenceId)
)
GO

CREATE TABLE RoleValue (
	FactId	int NOT NULL,
	InstanceId	int NOT NULL,
	PopulationName	varchar(64) NOT NULL,
	PopulationVocabularyName	varchar(64) NULL,
	RoleConceptName	varchar(64) NOT NULL,
	RoleConceptVocabularyName	varchar(64) NULL,
	RoleFactTypeId	int NOT NULL,
	RoleOrdinal	UnsignedSmallInteger(32) NOT NULL,
	UNIQUE(InstanceId, FactId)
)
GO

CREATE TABLE SetComparisonRoles (
	RoleSequenceId	int NOT NULL,
	SetComparisonConstraintId	int NOT NULL,
	UNIQUE(SetComparisonConstraintId, RoleSequenceId)
)
GO

CREATE TABLE Unit (
	UnitId	int NOT NULL,
	CoefficientDenominator	int NULL,
	CoefficientIsPrecise	bit NULL,
	CoefficientNumerator	decimal NULL,
	IsFundamental	bit NOT NULL,
	Name	varchar(64) NOT NULL,
	UNIQUE(UnitId)
)
GO

CREATE TABLE UnitBasis (
	BaseUnitId	int NOT NULL,
	DerivedUnitId	int NOT NULL,
	Exponent	SignedSmallInteger(32) NULL,
	UNIQUE(BaseUnitId, DerivedUnitId)
)
GO

CREATE TABLE ValueRestriction (
	ValueRestrictionId	int NOT NULL,
	UNIQUE(ValueRestrictionId)
)
GO

