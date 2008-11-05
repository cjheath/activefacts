CREATE TABLE Feature (
	VocabularyName	varchar(64) NULL,
	ConceptIsIndependent	bit NULL,
	ConceptIsPersonal	bit NULL,
	ValueTypeSupertypeName	varchar(64) NULL,
	ValueTypeSupertypeVocabularyName	varchar(64) NULL,
	ValueTypeValueRestrictionId	int NULL,
	ValueTypeUnitId	int NULL,
	ValueTypeLength	int NULL,
	ValueTypeScale	int NULL,
	EntityTypeFactTypeId	int NULL,
	Name	varchar(64) NOT NULL,
	UNIQUE(Name, VocabularyName)
)
GO

CREATE TABLE FactType (
	EntityTypeName	varchar(64) NULL,
	EntityTypeVocabularyName	varchar(64) NULL,
	FactTypeId	int NOT NULL,
	TypeInheritanceSupertypeName	varchar(64) NULL,
	TypeInheritanceSupertypeVocabularyName	varchar(64) NULL,
	TypeInheritanceSubtypeName	varchar(64) NULL,
	TypeInheritanceSubtypeVocabularyName	varchar(64) NULL,
	TypeInheritanceProvidesIdentification	bit NULL,
	UNIQUE(FactTypeId)
)
GO

CREATE TABLE ValueRestriction (
	ValueRestrictionId	int NOT NULL,
	UNIQUE(ValueRestrictionId)
)
GO

CREATE TABLE Unit (
	IsFundamental	bit NOT NULL,
	CoefficientIsPrecise	bit NULL,
	CoefficientNumerator	decimal NULL,
	CoefficientDenominator	int NULL,
	Name	varchar(64) NOT NULL,
	UnitId	int NOT NULL,
	UNIQUE(UnitId)
)
GO

CREATE TABLE Reading (
	FactTypeId	int NOT NULL,
	RoleSequenceId	int NOT NULL,
	Ordinal	Ordinal(32) NULL,
	ReadingText	varchar(256) NOT NULL,
	UNIQUE(FactTypeId, Ordinal)
)
GO

CREATE TABLE Constraint (
	VocabularyName	varchar(64) NULL,
	RingConstraintRingType	varchar NULL,
	RingConstraintRoleFactTypeId	int NULL,
	RingConstraintRoleOrdinal	Ordinal(32) NULL,
	RingConstraintRoleConceptName	varchar(64) NULL,
	RingConstraintRoleConceptVocabularyName	varchar(64) NULL,
	RingConstraintOtherRoleFactTypeId	int NULL,
	RingConstraintOtherRoleOrdinal	Ordinal(32) NULL,
	RingConstraintOtherRoleConceptName	varchar(64) NULL,
	RingConstraintOtherRoleConceptVocabularyName	varchar(64) NULL,
	PresenceConstraintIsPreferredIdentifier	bit NULL,
	PresenceConstraintIsMandatory	bit NULL,
	PresenceConstraintRoleSequenceId	int NULL,
	PresenceConstraintMaxFrequency	int NULL,
	PresenceConstraintMinFrequency	int NULL,
	SetExclusionConstraintIsMandatory	bit NULL,
	SubsetConstraintSupersetRoleSequenceId	int NULL,
	SubsetConstraintSubsetRoleSequenceId	int NULL,
	Name	varchar(64) NULL,
	ConstraintId	int NOT NULL,
	Enforcement	varchar(16) NULL,
	UNIQUE(ConstraintId)
)
GO

CREATE TABLE RoleSequence (
	RoleSequenceId	int NOT NULL,
	UNIQUE(RoleSequenceId)
)
GO

CREATE TABLE Instance (
	ConceptName	varchar(64) NOT NULL,
	ConceptVocabularyName	varchar(64) NULL,
	PopulationVocabularyName	varchar(64) NULL,
	PopulationName	varchar(64) NOT NULL,
	Value	varchar(256) NULL,
	InstanceId	int NOT NULL,
	UNIQUE(InstanceId)
)
GO

CREATE TABLE Fact (
	FactTypeId	int NOT NULL,
	PopulationVocabularyName	varchar(64) NULL,
	PopulationName	varchar(64) NOT NULL,
	FactId	int NOT NULL,
	UNIQUE(FactId)
)
GO

CREATE TABLE RoleValue (
	InstanceId	int NOT NULL,
	PopulationVocabularyName	varchar(64) NULL,
	PopulationName	varchar(64) NOT NULL,
	FactId	int NOT NULL,
	RoleFactTypeId	int NOT NULL,
	RoleOrdinal	Ordinal(32) NOT NULL,
	RoleConceptName	varchar(64) NOT NULL,
	RoleConceptVocabularyName	varchar(64) NULL,
	UNIQUE(InstanceId, FactId)
)
GO

CREATE TABLE AllowedRange (
	ValueRestrictionId	int NOT NULL,
	ValueRangeMinimumBoundIsInclusive	bit NULL,
	ValueRangeMinimumBoundValue	varchar(256) NULL,
	ValueRangeMaximumBoundIsInclusive	bit NULL,
	ValueRangeMaximumBoundValue	varchar(256) NULL,
	UNIQUE(ValueRangeMinimumBoundValue, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValue, ValueRangeMaximumBoundIsInclusive, ValueRestrictionId)
)
GO

CREATE TABLE UnitBasis (
	DerivedUnitId	int NOT NULL,
	BaseUnitId	int NOT NULL,
	Exponent	Exponent(32) NULL,
	UNIQUE(BaseUnitId, DerivedUnitId)
)
GO

CREATE TABLE SetComparisonRoles (
	SetComparisonConstraintId	int NOT NULL,
	RoleSequenceId	int NOT NULL,
	UNIQUE(SetComparisonConstraintId, RoleSequenceId)
)
GO

CREATE TABLE RoleRef (
	RoleSequenceId	int NOT NULL,
	Ordinal	Ordinal(32) NOT NULL,
	LeadingAdjective	varchar(64) NULL,
	TrailingAdjective	varchar(64) NULL,
	RoleFactTypeId	int NOT NULL,
	RoleOrdinal	Ordinal(32) NOT NULL,
	RoleConceptName	varchar(64) NOT NULL,
	RoleConceptVocabularyName	varchar(64) NULL,
	UNIQUE(RoleSequenceId, Ordinal)
)
GO

CREATE TABLE Correspondence (
	ImportedFeatureName	varchar(64) NOT NULL,
	ImportedFeatureVocabularyName	varchar(64) NULL,
	LocalFeatureName	varchar(64) NOT NULL,
	LocalFeatureVocabularyName	varchar(64) NULL,
	ImportVocabularyName	varchar(64) NOT NULL,
	ImportImportedVocabularyName	varchar(64) NOT NULL,
	UNIQUE(ImportedFeatureName, ImportedFeatureVocabularyName, ImportImportedVocabularyName, ImportVocabularyName)
)
GO

CREATE TABLE Role (
	ConceptName	varchar(64) NOT NULL,
	ConceptVocabularyName	varchar(64) NULL,
	FactTypeId	int NOT NULL,
	RoleValueRestrictionId	int NULL,
	RoleName	varchar(64) NULL,
	Ordinal	Ordinal(32) NOT NULL,
	UNIQUE(FactTypeId, Ordinal, ConceptName, ConceptVocabularyName)
)
GO

CREATE TABLE JoinPath (
	ConceptName	varchar(64) NULL,
	ConceptVocabularyName	varchar(64) NULL,
	JoinStep	Ordinal(32) NOT NULL,
	RoleRefRoleSequenceId	int NOT NULL,
	RoleRefOrdinal	Ordinal(32) NOT NULL,
	InputRoleFactTypeId	int NOT NULL,
	InputRoleOrdinal	Ordinal(32) NOT NULL,
	InputRoleConceptName	varchar(64) NOT NULL,
	InputRoleConceptVocabularyName	varchar(64) NULL,
	OutputRoleFactTypeId	int NOT NULL,
	OutputRoleOrdinal	Ordinal(32) NOT NULL,
	OutputRoleConceptName	varchar(64) NOT NULL,
	OutputRoleConceptVocabularyName	varchar(64) NULL,
	UNIQUE(RoleRefRoleSequenceId, RoleRefOrdinal, JoinStep)
)
GO

