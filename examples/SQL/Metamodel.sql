CREATE TABLE AllowedRange (
	ValueRestrictionId                      AutoCounter NOT NULL,
	ValueRangeMinimumBoundValue             VariableLengthText(256) NULL,
	ValueRangeMinimumBoundIsInclusive       BIT NULL,
	ValueRangeMaximumBoundValue             VariableLengthText(256) NULL,
	ValueRangeMaximumBoundIsInclusive       BIT NULL,
	UNIQUE(ValueRestrictionId, ValueRangeMinimumBoundValue, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValue, ValueRangeMaximumBoundIsInclusive)
)
GO

CREATE TABLE [Constraint] (
	ConstraintId                            AutoCounter NOT NULL,
	Name                                    VariableLengthText(64) NULL,
	Enforcement                             VariableLengthText(16) NULL,
	VocabularyName                          VariableLengthText(64) NULL,
	RingConstraintRoleFactTypeId            AutoCounter NULL,
	RingConstraintRoleOrdinal               UnsignedSmallInteger(32) NULL,
	RingConstraintRoleConceptName           VariableLengthText(64) NULL,
	RingConstraintRoleConceptVocabularyName VariableLengthText(64) NULL,
	RingConstraintOtherRoleFactTypeId       AutoCounter NULL,
	RingConstraintOtherRoleOrdinal          UnsignedSmallInteger(32) NULL,
	RingConstraintOtherRoleConceptName      VariableLengthText(64) NULL,
	RingConstraintOtherRoleConceptVocabularyName VariableLengthText(64) NULL,
	RingConstraintRingType                  VariableLengthText NULL,
	PresenceConstraintRoleSequenceId        AutoCounter NULL,
	PresenceConstraintMaxFrequency          UnsignedInteger(32) NULL CHECK(REVISIT: valid value),
	PresenceConstraintMinFrequency          UnsignedInteger(32) NULL CHECK(REVISIT: valid value),
	PresenceConstraintIsPreferredIdentifier BIT NULL,
	PresenceConstraintIsMandatory           BIT NULL,
	SetExclusionConstraintIsMandatory       BIT NULL,
	SubsetConstraintSupersetRoleSequenceId  AutoCounter NULL,
	SubsetConstraintSubsetRoleSequenceId    AutoCounter NULL,
	PRIMARY KEY(ConstraintId)
)
GO

CREATE TABLE Correspondence (
	ImportVocabularyName                    VariableLengthText(64) NOT NULL,
	ImportImportedVocabularyName            VariableLengthText(64) NOT NULL,
	ImportedFeatureName                     VariableLengthText(64) NOT NULL,
	ImportedFeatureVocabularyName           VariableLengthText(64) NULL,
	LocalFeatureName                        VariableLengthText(64) NOT NULL,
	LocalFeatureVocabularyName              VariableLengthText(64) NULL,
	UNIQUE(ImportVocabularyName, ImportImportedVocabularyName, ImportedFeatureName, ImportedFeatureVocabularyName)
)
GO

CREATE TABLE Derivation (
	DerivedUnitId                           AutoCounter NOT NULL,
	BaseUnitId                              AutoCounter NOT NULL,
	Exponent                                SignedSmallInteger(32) NULL,
	PRIMARY KEY(DerivedUnitId, BaseUnitId)
)
GO

CREATE TABLE Fact (
	FactId                                  AutoCounter NOT NULL,
	FactTypeId                              AutoCounter NOT NULL,
	PopulationName                          VariableLengthText(64) NOT NULL,
	PopulationVocabularyName                VariableLengthText(64) NULL,
	PRIMARY KEY(FactId)
)
GO

CREATE TABLE FactType (
	FactTypeId                              AutoCounter NOT NULL,
	EntityTypeName                          VariableLengthText(64) NULL,
	EntityTypeVocabularyName                VariableLengthText(64) NULL,
	TypeInheritanceSubtypeName              VariableLengthText(64) NULL,
	TypeInheritanceSubtypeVocabularyName    VariableLengthText(64) NULL,
	TypeInheritanceSupertypeName            VariableLengthText(64) NULL,
	TypeInheritanceSupertypeVocabularyName  VariableLengthText(64) NULL,
	TypeInheritanceProvidesIdentification   BIT NULL,
	PRIMARY KEY(FactTypeId)
)
GO

CREATE TABLE Feature (
	Name                                    VariableLengthText(64) NOT NULL,
	VocabularyName                          VariableLengthText(64) NULL,
	ConceptIsIndependent                    BIT NULL,
	ConceptIsPersonal                       BIT NULL,
	ValueTypeSupertypeName                  VariableLengthText(64) NULL,
	ValueTypeSupertypeVocabularyName        VariableLengthText(64) NULL,
	ValueTypeLength                         UnsignedInteger(32) NULL,
	ValueTypeScale                          UnsignedInteger(32) NULL,
	ValueTypeValueRestrictionId             AutoCounter NULL,
	ValueTypeUnitId                         AutoCounter NULL,
	UNIQUE(Name, VocabularyName)
)
GO

CREATE TABLE Instance (
	InstanceId                              AutoCounter NOT NULL,
	Value                                   VariableLengthText(256) NULL,
	ConceptName                             VariableLengthText(64) NOT NULL,
	ConceptVocabularyName                   VariableLengthText(64) NULL,
	PopulationName                          VariableLengthText(64) NOT NULL,
	PopulationVocabularyName                VariableLengthText(64) NULL,
	PRIMARY KEY(InstanceId)
)
GO

CREATE TABLE JoinPath (
	RoleRefRoleSequenceId                   AutoCounter NOT NULL,
	RoleRefOrdinal                          UnsignedSmallInteger(32) NOT NULL,
	JoinStep                                UnsignedSmallInteger(32) NOT NULL,
	InputRoleFactTypeId                     AutoCounter NOT NULL,
	InputRoleOrdinal                        UnsignedSmallInteger(32) NOT NULL,
	InputRoleConceptName                    VariableLengthText(64) NOT NULL,
	InputRoleConceptVocabularyName          VariableLengthText(64) NULL,
	OutputRoleFactTypeId                    AutoCounter NOT NULL,
	OutputRoleOrdinal                       UnsignedSmallInteger(32) NOT NULL,
	OutputRoleConceptName                   VariableLengthText(64) NOT NULL,
	OutputRoleConceptVocabularyName         VariableLengthText(64) NULL,
	ConceptName                             VariableLengthText(64) NULL,
	ConceptVocabularyName                   VariableLengthText(64) NULL,
	PRIMARY KEY(RoleRefRoleSequenceId, RoleRefOrdinal, JoinStep)
)
GO

CREATE TABLE Reading (
	FactTypeId                              AutoCounter NOT NULL,
	Text                                    VariableLengthText(256) NOT NULL,
	RoleSequenceId                          AutoCounter NOT NULL,
	Ordinal                                 UnsignedSmallInteger(32) NOT NULL,
	PRIMARY KEY(FactTypeId, Ordinal)
)
GO

CREATE TABLE Role (
	FactTypeId                              AutoCounter NOT NULL,
	Ordinal                                 UnsignedSmallInteger(32) NOT NULL,
	ConceptName                             VariableLengthText(64) NOT NULL,
	ConceptVocabularyName                   VariableLengthText(64) NULL,
	RoleName                                VariableLengthText(64) NULL,
	RoleValueRestrictionId                  AutoCounter NULL,
	UNIQUE(FactTypeId, Ordinal, ConceptName, ConceptVocabularyName)
)
GO

CREATE TABLE RoleRef (
	RoleSequenceId                          AutoCounter NOT NULL,
	Ordinal                                 UnsignedSmallInteger(32) NOT NULL,
	RoleFactTypeId                          AutoCounter NOT NULL,
	RoleOrdinal                             UnsignedSmallInteger(32) NOT NULL,
	RoleConceptName                         VariableLengthText(64) NOT NULL,
	RoleConceptVocabularyName               VariableLengthText(64) NULL,
	LeadingAdjective                        VariableLengthText(64) NULL,
	TrailingAdjective                       VariableLengthText(64) NULL,
	PRIMARY KEY(RoleSequenceId, Ordinal)
)
GO

CREATE TABLE RoleSequence (
	RoleSequenceId                          AutoCounter NOT NULL,
	PRIMARY KEY(RoleSequenceId)
)
GO

CREATE TABLE RoleValue (
	PopulationName                          VariableLengthText(64) NOT NULL,
	PopulationVocabularyName                VariableLengthText(64) NULL,
	FactId                                  AutoCounter NOT NULL,
	InstanceId                              AutoCounter NOT NULL,
	RoleFactTypeId                          AutoCounter NOT NULL,
	RoleOrdinal                             UnsignedSmallInteger(32) NOT NULL,
	RoleConceptName                         VariableLengthText(64) NOT NULL,
	RoleConceptVocabularyName               VariableLengthText(64) NULL,
	PRIMARY KEY(InstanceId, FactId)
)
GO

CREATE TABLE SetComparisonRoles (
	SetComparisonConstraintId               AutoCounter NOT NULL,
	RoleSequenceId                          AutoCounter NOT NULL,
	PRIMARY KEY(SetComparisonConstraintId, RoleSequenceId)
)
GO

CREATE TABLE Unit (
	UnitId                                  AutoCounter NOT NULL,
	CoefficientIsPrecise                    BIT NULL,
	CoefficientNumerator                    Decimal NULL,
	CoefficientDenominator                  UnsignedInteger(32) NULL,
	Name                                    VariableLengthText(64) NOT NULL,
	IsFundamental                           BIT NOT NULL,
	PRIMARY KEY(UnitId)
)
GO

CREATE TABLE ValueRestriction (
	ValueRestrictionId                      AutoCounter NOT NULL,
	PRIMARY KEY(ValueRestrictionId)
)
GO

