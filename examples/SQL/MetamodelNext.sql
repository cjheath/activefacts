CREATE TABLE AllowedRange (
	-- AllowedRange is where ValueConstraint allows ValueRange and ValueConstraint has ValueConstraintId,
	ValueConstraintId                       AutoCounter NOT NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has maximum-Bound and Bound is inclusive,
	ValueRangeMaximumBoundIsInclusive       BIT NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has maximum-Bound and Bound has Value and Value is a string,
	ValueRangeMaximumBoundValueIsAString    BIT NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has maximum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMaximumBoundValueLiteral      VariableLengthText NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has maximum-Bound and Bound has Value and maybe Value is in Unit and Unit has UnitId,
	ValueRangeMaximumBoundValueUnitId       AutoCounter NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has minimum-Bound and Bound is inclusive,
	ValueRangeMinimumBoundIsInclusive       BIT NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has minimum-Bound and Bound has Value and Value is a string,
	ValueRangeMinimumBoundValueIsAString    BIT NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has minimum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMinimumBoundValueLiteral      VariableLengthText NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has minimum-Bound and Bound has Value and maybe Value is in Unit and Unit has UnitId,
	ValueRangeMinimumBoundValueUnitId       AutoCounter NULL,
	UNIQUE(ValueConstraintId, ValueRangeMinimumBoundValueUnitId, ValueRangeMinimumBoundValueLiteral, ValueRangeMinimumBoundValueIsAString, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValueUnitId, ValueRangeMaximumBoundValueLiteral, ValueRangeMaximumBoundValueIsAString, ValueRangeMaximumBoundIsInclusive)
)
GO

CREATE TABLE [Constraint] (
	-- Constraint has ConstraintId,
	ConstraintId                            AutoCounter IDENTITY NOT NULL,
	-- maybe Constraint requires Enforcement,
	Enforcement                             VariableLengthText(16) NULL,
	-- maybe Name is of Constraint,
	Name                                    VariableLengthText(64) NULL,
	-- maybe PresenceConstraint is a kind of Constraint and PresenceConstraint is mandatory,
	PresenceConstraintIsMandatory           BIT NULL,
	-- maybe PresenceConstraint is a kind of Constraint and PresenceConstraint is preferred identifier,
	PresenceConstraintIsPreferredIdentifier BIT NULL,
	-- maybe PresenceConstraint is a kind of Constraint and maybe PresenceConstraint has max-Frequency,
	PresenceConstraintMaxFrequency          UnsignedInteger(32) NULL CHECK(PresenceConstraintMaxFrequency >= 1),
	-- maybe PresenceConstraint is a kind of Constraint and maybe PresenceConstraint has min-Frequency,
	PresenceConstraintMinFrequency          UnsignedInteger(32) NULL CHECK(PresenceConstraintMinFrequency >= 2),
	-- maybe PresenceConstraint is a kind of Constraint and PresenceConstraint covers RoleSequence and RoleSequence has RoleSequenceId,
	PresenceConstraintRoleSequenceId        AutoCounter NULL,
	-- maybe RingConstraint is a kind of Constraint and maybe other-Role is of RingConstraint and Role is where FactType has Ordinal role and FactType has FactTypeId,
	RingConstraintOtherRoleFactTypeId       AutoCounter NULL,
	-- maybe RingConstraint is a kind of Constraint and maybe other-Role is of RingConstraint and Role is where FactType has Ordinal role,
	RingConstraintOtherRoleOrdinal          UnsignedSmallInteger(32) NULL,
	-- maybe RingConstraint is a kind of Constraint and RingConstraint is of RingType,
	RingConstraintRingType                  VariableLengthText NULL,
	-- maybe RingConstraint is a kind of Constraint and maybe Role is of RingConstraint and Role is where FactType has Ordinal role and FactType has FactTypeId,
	RingConstraintRoleFactTypeId            AutoCounter NULL,
	-- maybe RingConstraint is a kind of Constraint and maybe Role is of RingConstraint and Role is where FactType has Ordinal role,
	RingConstraintRoleOrdinal               UnsignedSmallInteger(32) NULL,
	-- maybe SetConstraint is a kind of Constraint and maybe SetComparisonConstraint is a kind of SetConstraint and maybe SetExclusionConstraint is a kind of SetComparisonConstraint and SetExclusionConstraint is mandatory,
	SetExclusionConstraintIsMandatory       BIT NULL,
	-- maybe SetConstraint is a kind of Constraint and maybe SubsetConstraint is a kind of SetConstraint and SubsetConstraint covers subset-RoleSequence and RoleSequence has RoleSequenceId,
	SubsetConstraintSubsetRoleSequenceId    AutoCounter NULL,
	-- maybe SetConstraint is a kind of Constraint and maybe SubsetConstraint is a kind of SetConstraint and SubsetConstraint covers superset-RoleSequence and RoleSequence has RoleSequenceId,
	SubsetConstraintSupersetRoleSequenceId  AutoCounter NULL,
	-- maybe Vocabulary contains Constraint and Vocabulary is called Name,
	VocabularyName                          VariableLengthText(64) NULL,
	PRIMARY KEY(ConstraintId)
)
GO

CREATE VIEW dbo.SubsetConstraintInConstraint_SubsetRoleSequenceIdSupersetRoleSequenceId (SubsetConstraintSubsetRoleSequenceId, SubsetConstraintSupersetRoleSequenceId) WITH SCHEMABINDING AS
	SELECT SubsetConstraintSubsetRoleSequenceId, SubsetConstraintSupersetRoleSequenceId FROM dbo.[Constraint]
	WHERE	SubsetConstraintSubsetRoleSequenceId IS NOT NULL
	  AND	SubsetConstraintSupersetRoleSequenceId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_SubsetConstraintInConstraintBySubsetConstraintSubsetRoleSequenceIdSubsetConstraintSupersetRoleSequenceId ON dbo.SubsetConstraintInConstraint_SubsetRoleSequenceIdSupersetRoleSequenceId(SubsetConstraintSubsetRoleSequenceId, SubsetConstraintSupersetRoleSequenceId)
GO

CREATE VIEW dbo.Constraint_VocabularyNameName (VocabularyName, Name) WITH SCHEMABINDING AS
	SELECT VocabularyName, Name FROM dbo.[Constraint]
	WHERE	VocabularyName IS NOT NULL
	  AND	Name IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ConstraintByVocabularyNameName ON dbo.Constraint_VocabularyNameName(VocabularyName, Name)
GO

CREATE TABLE ContextAccordingTo (
	-- ContextAccordingTo is where ContextNote is according to Person and ContextNote has ContextNoteId,
	ContextNoteId                           AutoCounter NOT NULL,
	-- maybe ContextAccordingTo lodged on Date,
	Date                                    Date NULL,
	-- ContextAccordingTo is where ContextNote is according to Person and Person has PersonName,
	PersonName                              VariableLengthText NOT NULL,
	PRIMARY KEY(ContextNoteId, PersonName)
)
GO

CREATE TABLE ContextAgreedBy (
	-- ContextAgreedBy is where Agreement was reached by Person and ContextNote has ContextNoteId,
	AgreementContextNoteId                  AutoCounter NOT NULL,
	-- ContextAgreedBy is where Agreement was reached by Person and Person has PersonName,
	PersonName                              VariableLengthText NOT NULL,
	PRIMARY KEY(AgreementContextNoteId, PersonName)
)
GO

CREATE TABLE ContextNote (
	-- maybe ContextNote was added by Agreement and maybe Agreement was on Date,
	AgreementDate                           Date NULL,
	-- maybe Constraint has ContextNote and Constraint has ConstraintId,
	ConstraintId                            AutoCounter NULL,
	-- ContextNote has ContextNoteId,
	ContextNoteId                           AutoCounter IDENTITY NOT NULL,
	-- ContextNote has ContextNoteKind,
	ContextNoteKind                         VariableLengthText NOT NULL CHECK(ContextNoteKind = 'as_opposed_to' OR ContextNoteKind = 'because' OR ContextNoteKind = 'so_that' OR ContextNoteKind = 'to_avoid'),
	-- ContextNote has Discussion,
	Discussion                              VariableLengthText NOT NULL,
	-- maybe FactType has ContextNote and FactType has FactTypeId,
	FactTypeId                              AutoCounter NULL,
	-- maybe ObjectType has ContextNote and Term is where Vocabulary contains Name,
	ObjectTypeName                          VariableLengthText(64) NULL,
	-- maybe ObjectType has ContextNote and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ObjectTypeVocabularyName                VariableLengthText(64) NULL,
	PRIMARY KEY(ContextNoteId),
	FOREIGN KEY (ConstraintId) REFERENCES [Constraint] (ConstraintId)
)
GO

CREATE TABLE Derivation (
	-- Derivation is where DerivedUnit is derived from BaseUnit and Unit has UnitId,
	BaseUnitId                              AutoCounter NOT NULL,
	-- Derivation is where DerivedUnit is derived from BaseUnit and Unit has UnitId,
	DerivedUnitId                           AutoCounter NOT NULL,
	-- maybe Derivation has Exponent,
	Exponent                                SignedSmallInteger(32) NULL,
	PRIMARY KEY(DerivedUnitId, BaseUnitId)
)
GO

CREATE TABLE Fact (
	-- Fact has FactId,
	FactId                                  AutoCounter IDENTITY NOT NULL,
	-- Fact is of FactType and FactType has FactTypeId,
	FactTypeId                              AutoCounter NOT NULL,
	-- Population includes Fact and Population has Name,
	PopulationName                          VariableLengthText(64) NOT NULL,
	-- Population includes Fact and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                VariableLengthText(64) NULL,
	PRIMARY KEY(FactId)
)
GO

CREATE TABLE FactType (
	-- maybe EntityType nests FactType and Term is where Vocabulary contains Name,
	EntityTypeName                          VariableLengthText(64) NULL,
	-- maybe EntityType nests FactType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	EntityTypeVocabularyName                VariableLengthText(64) NULL,
	-- FactType has FactTypeId,
	FactTypeId                              AutoCounter IDENTITY NOT NULL,
	-- maybe TypeInheritance is a kind of FactType and maybe Assimilation applies to TypeInheritance,
	TypeInheritanceAssimilation             VariableLengthText NULL CHECK(TypeInheritanceAssimilation = 'partitioned' OR TypeInheritanceAssimilation = 'separate'),
	-- maybe TypeInheritance is a kind of FactType and TypeInheritance provides identification,
	TypeInheritanceProvidesIdentification   BIT NULL,
	-- maybe TypeInheritance is a kind of FactType and TypeInheritance is where Subtype is subtype of Supertype and Term is where Vocabulary contains Name,
	TypeInheritanceSubtypeName              VariableLengthText(64) NULL,
	-- maybe TypeInheritance is a kind of FactType and TypeInheritance is where Subtype is subtype of Supertype and Term is where Vocabulary contains Name and Vocabulary is called Name,
	TypeInheritanceSubtypeVocabularyName    VariableLengthText(64) NULL,
	-- maybe TypeInheritance is a kind of FactType and TypeInheritance is where Subtype is subtype of Supertype and Term is where Vocabulary contains Name,
	TypeInheritanceSupertypeName            VariableLengthText(64) NULL,
	-- maybe TypeInheritance is a kind of FactType and TypeInheritance is where Subtype is subtype of Supertype and Term is where Vocabulary contains Name and Vocabulary is called Name,
	TypeInheritanceSupertypeVocabularyName  VariableLengthText(64) NULL,
	PRIMARY KEY(FactTypeId)
)
GO

CREATE VIEW dbo.FactType_EntityTypeVocabularyNameEntityTypeName (EntityTypeVocabularyName, EntityTypeName) WITH SCHEMABINDING AS
	SELECT EntityTypeVocabularyName, EntityTypeName FROM dbo.FactType
	WHERE	EntityTypeVocabularyName IS NOT NULL
	  AND	EntityTypeName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX EntityTypeNestsOneFactType ON dbo.FactType_EntityTypeVocabularyNameEntityTypeName(EntityTypeVocabularyName, EntityTypeName)
GO

CREATE VIEW dbo.TypeInheritanceInFactType_SubtypeVocabularyNameSubtypeNameProvidesIdentification (TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceProvidesIdentification) WITH SCHEMABINDING AS
	SELECT TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceProvidesIdentification FROM dbo.FactType
	WHERE	TypeInheritanceSubtypeVocabularyName IS NOT NULL
	  AND	TypeInheritanceSubtypeName IS NOT NULL
	  AND	TypeInheritanceProvidesIdentification IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX OnlyOneSupertypeMayBePrimary ON dbo.TypeInheritanceInFactType_SubtypeVocabularyNameSubtypeNameProvidesIdentification(TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceProvidesIdentification)
GO

CREATE VIEW dbo.TypeInheritanceInFactType_SubtypeVocabularyNameSubtypeNameSupertypeVocabularyNameSupertypeName (TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceSupertypeVocabularyName, TypeInheritanceSupertypeName) WITH SCHEMABINDING AS
	SELECT TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceSupertypeVocabularyName, TypeInheritanceSupertypeName FROM dbo.FactType
	WHERE	TypeInheritanceSubtypeVocabularyName IS NOT NULL
	  AND	TypeInheritanceSubtypeName IS NOT NULL
	  AND	TypeInheritanceSupertypeVocabularyName IS NOT NULL
	  AND	TypeInheritanceSupertypeName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PK_TypeInheritanceInFactType ON dbo.TypeInheritanceInFactType_SubtypeVocabularyNameSubtypeNameSupertypeVocabularyNameSupertypeName(TypeInheritanceSubtypeVocabularyName, TypeInheritanceSubtypeName, TypeInheritanceSupertypeVocabularyName, TypeInheritanceSupertypeName)
GO

CREATE TABLE Instance (
	-- maybe Instance objectifies Fact and Fact has FactId,
	FactId                                  AutoCounter NULL,
	-- Instance has InstanceId,
	InstanceId                              AutoCounter IDENTITY NOT NULL,
	-- Instance is of ObjectType and Term is where Vocabulary contains Name,
	ObjectTypeName                          VariableLengthText(64) NOT NULL,
	-- Instance is of ObjectType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ObjectTypeVocabularyName                VariableLengthText(64) NOT NULL,
	-- Population includes Instance and Population has Name,
	PopulationName                          VariableLengthText(64) NOT NULL,
	-- Population includes Instance and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                VariableLengthText(64) NULL,
	-- maybe Instance has Value and Value is a string,
	ValueIsAString                          BIT NULL,
	-- maybe Instance has Value and Value is represented by Literal,
	ValueLiteral                            VariableLengthText NULL,
	-- maybe Instance has Value and maybe Value is in Unit and Unit has UnitId,
	ValueUnitId                             AutoCounter NULL,
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

CREATE TABLE [Join] (
	-- maybe Join has input-Role and Role is where FactType has Ordinal role and FactType has FactTypeId,
	InputRoleFactTypeId                     AutoCounter NULL,
	-- maybe Join has input-Role and Role is where FactType has Ordinal role,
	InputRoleOrdinal                        UnsignedSmallInteger(32) NULL,
	-- is anti-Join,
	[Is]                                    BIT NOT NULL,
	-- Join is outer,
	IsOuter                                 BIT NOT NULL,
	-- Join is where RoleRef has JoinStep join,
	JoinStep                                UnsignedSmallInteger(32) NOT NULL,
	-- maybe Join traverses ObjectType and Term is where Vocabulary contains Name,
	ObjectTypeName                          VariableLengthText(64) NULL,
	-- maybe Join traverses ObjectType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ObjectTypeVocabularyName                VariableLengthText(64) NULL,
	-- maybe Join has output-Role and Role is where FactType has Ordinal role and FactType has FactTypeId,
	OutputRoleFactTypeId                    AutoCounter NULL,
	-- maybe Join has output-Role and Role is where FactType has Ordinal role,
	OutputRoleOrdinal                       UnsignedSmallInteger(32) NULL,
	-- Join is where RoleRef has JoinStep join and RoleRef is where RoleSequence in Ordinal position includes Role,
	RoleRefOrdinal                          UnsignedSmallInteger(32) NOT NULL,
	-- Join is where RoleRef has JoinStep join and RoleRef is where RoleSequence in Ordinal position includes Role and RoleSequence has RoleSequenceId,
	RoleRefRoleSequenceId                   AutoCounter NOT NULL,
	PRIMARY KEY(RoleRefRoleSequenceId, RoleRefOrdinal, JoinStep)
)
GO

CREATE TABLE ParamValue (
	-- ParamValue is where Value for Parameter applies to ValueType and Parameter is where Name is a parameter of ValueType,
	ParameterName                           VariableLengthText(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Parameter is where Name is a parameter of ValueType and Term is where Vocabulary contains Name,
	ParameterValueTypeName                  VariableLengthText(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Parameter is where Name is a parameter of ValueType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ParameterValueTypeVocabularyName        VariableLengthText(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Value is a string,
	ValueIsAString                          BIT NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Value is represented by Literal,
	ValueLiteral                            VariableLengthText NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Term is where Vocabulary contains Name,
	ValueTypeName                           VariableLengthText(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ValueTypeVocabularyName                 VariableLengthText(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and maybe Value is in Unit and Unit has UnitId,
	ValueUnitId                             AutoCounter NULL,
	UNIQUE(ValueUnitId, ValueLiteral, ValueIsAString, ParameterName, ParameterValueTypeVocabularyName, ParameterValueTypeName)
)
GO

CREATE TABLE Role (
	-- Role is where FactType has Ordinal role and FactType has FactTypeId,
	FactTypeId                              AutoCounter NOT NULL,
	-- ObjectType plays Role and Term is where Vocabulary contains Name,
	ObjectTypeName                          VariableLengthText(64) NOT NULL,
	-- ObjectType plays Role and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ObjectTypeVocabularyName                VariableLengthText(64) NOT NULL,
	-- Role is where FactType has Ordinal role,
	Ordinal                                 UnsignedSmallInteger(32) NOT NULL,
	-- maybe Role has role-ValueConstraint and ValueConstraint has ValueConstraintId,
	RoleValueConstraintId                   AutoCounter NULL,
	PRIMARY KEY(FactTypeId, Ordinal),
	FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId)
)
GO

CREATE TABLE RoleRef (
	-- maybe RoleRef has leading-Adjective,
	LeadingAdjective                        VariableLengthText(64) NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role,
	Ordinal                                 UnsignedSmallInteger(32) NOT NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and Role is where FactType has Ordinal role and FactType has FactTypeId,
	RoleFactTypeId                          AutoCounter NOT NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and Role is where FactType has Ordinal role,
	RoleOrdinal                             UnsignedSmallInteger(32) NOT NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and RoleSequence has RoleSequenceId,
	RoleSequenceId                          AutoCounter NOT NULL,
	-- maybe RoleRef has role-Term and Term is where Vocabulary contains Name,
	RoleTermName                            VariableLengthText(64) NULL,
	-- maybe RoleRef has role-Term and Term is where Vocabulary contains Name and Vocabulary is called Name,
	RoleTermVocabularyName                  VariableLengthText(64) NULL,
	-- maybe RoleRef has trailing-Adjective,
	TrailingAdjective                       VariableLengthText(64) NULL,
	PRIMARY KEY(RoleSequenceId, Ordinal),
	UNIQUE(RoleFactTypeId, RoleOrdinal, RoleSequenceId),
	FOREIGN KEY (RoleFactTypeId, RoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
)
GO

CREATE TABLE RoleSequence (
	-- RoleSequence has RoleSequenceId,
	RoleSequenceId                          AutoCounter IDENTITY NOT NULL,
	PRIMARY KEY(RoleSequenceId)
)
GO

CREATE TABLE RoleValue (
	-- RoleValue fulfils Fact and Fact has FactId,
	FactId                                  AutoCounter NOT NULL,
	-- Instance plays RoleValue and Instance has InstanceId,
	InstanceId                              AutoCounter NOT NULL,
	-- Population includes RoleValue and Population has Name,
	PopulationName                          VariableLengthText(64) NOT NULL,
	-- Population includes RoleValue and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                VariableLengthText(64) NULL,
	-- RoleValue is of Role and Role is where FactType has Ordinal role and FactType has FactTypeId,
	RoleFactTypeId                          AutoCounter NOT NULL,
	-- RoleValue is of Role and Role is where FactType has Ordinal role,
	RoleOrdinal                             UnsignedSmallInteger(32) NOT NULL,
	PRIMARY KEY(InstanceId, FactId),
	FOREIGN KEY (FactId) REFERENCES Fact (FactId),
	FOREIGN KEY (InstanceId) REFERENCES Instance (InstanceId),
	FOREIGN KEY (RoleFactTypeId, RoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
)
GO

CREATE TABLE SetComparisonRoles (
	-- SetComparisonRoles is where SetComparisonConstraint has in Ordinal position RoleSequence,
	Ordinal                                 UnsignedSmallInteger(32) NOT NULL,
	-- SetComparisonRoles is where SetComparisonConstraint has in Ordinal position RoleSequence and RoleSequence has RoleSequenceId,
	RoleSequenceId                          AutoCounter NOT NULL,
	-- SetComparisonRoles is where SetComparisonConstraint has in Ordinal position RoleSequence and Constraint has ConstraintId,
	SetComparisonConstraintId               AutoCounter NOT NULL,
	PRIMARY KEY(SetComparisonConstraintId, Ordinal),
	UNIQUE(SetComparisonConstraintId, RoleSequenceId),
	FOREIGN KEY (SetComparisonConstraintId) REFERENCES [Constraint] (ConstraintId),
	FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
)
GO

CREATE TABLE Term (
	-- Term is where Vocabulary contains Name,
	Name                                    VariableLengthText(64) NOT NULL,
	-- maybe Term designates ObjectType and ObjectType is independent,
	ObjectTypeIsIndependent                 BIT NULL,
	-- maybe Term is secondary for ObjectType and Term is where Vocabulary contains Name,
	ObjectTypeName                          VariableLengthText(64) NULL,
	-- maybe Term designates ObjectType and maybe ObjectType uses Pronoun,
	ObjectTypePronoun                       VariableLengthText(20) NULL CHECK(ObjectTypePronoun = 'feminine' OR ObjectTypePronoun = 'masculine' OR ObjectTypePronoun = 'neuter' OR ObjectTypePronoun = 'personal'),
	-- maybe Term is secondary for ObjectType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ObjectTypeVocabularyName                VariableLengthText(64) NULL,
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType has Length,
	ValueTypeLength                         UnsignedInteger(32) NULL,
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType has Scale,
	ValueTypeScale                          UnsignedInteger(32) NULL,
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType is subtype of Supertype and Term is where Vocabulary contains Name,
	ValueTypeSupertypeName                  VariableLengthText(64) NULL,
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType is subtype of Supertype and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ValueTypeSupertypeVocabularyName        VariableLengthText(64) NULL,
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType is of Unit and Unit has UnitId,
	ValueTypeUnitId                         AutoCounter NULL,
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType has ValueConstraint and ValueConstraint has ValueConstraintId,
	ValueTypeValueConstraintId              AutoCounter NULL,
	-- Term is where Vocabulary contains Name and Vocabulary is called Name,
	VocabularyName                          VariableLengthText(64) NOT NULL,
	PRIMARY KEY(VocabularyName, Name),
	FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES Term (Name, VocabularyName),
	FOREIGN KEY (ValueTypeSupertypeName, ValueTypeSupertypeVocabularyName) REFERENCES Term (Name, VocabularyName)
)
GO

CREATE TABLE Unit (
	-- maybe Unit has Coefficient and Coefficient has Denominator,
	CoefficientDenominator                  UnsignedInteger(32) NULL,
	-- maybe Unit has Coefficient and Coefficient is precise,
	CoefficientIsPrecise                    BIT NULL,
	-- maybe Unit has Coefficient and Coefficient has Numerator,
	CoefficientNumerator                    Decimal NULL,
	-- maybe Ephemera provides Unit coefficient,
	Ephemera                                VariableLengthText NULL,
	-- Unit is fundamental,
	IsFundamental                           BIT NOT NULL,
	-- Name is of Unit,
	Name                                    VariableLengthText(64) NOT NULL,
	-- maybe Unit has Offset,
	Offset                                  Decimal NULL,
	-- Unit has UnitId,
	UnitId                                  AutoCounter IDENTITY NOT NULL,
	-- Vocabulary includes Unit and Vocabulary is called Name,
	VocabularyName                          VariableLengthText(64) NOT NULL,
	PRIMARY KEY(UnitId),
	UNIQUE(VocabularyName, Name)
)
GO

CREATE TABLE ValueConstraint (
	-- ValueConstraint has ValueConstraintId,
	ValueConstraintId                       AutoCounter IDENTITY NOT NULL,
	PRIMARY KEY(ValueConstraintId)
)
GO

CREATE TABLE less (
	-- FactType has less and FactType has FactTypeId,
	FactTypeId                              AutoCounter NOT NULL,
	-- less is in Ordinal position,
	Ordinal                                 UnsignedSmallInteger(32) NOT NULL,
	-- less is in RoleSequence and RoleSequence has RoleSequenceId,
	RoleSequenceId                          AutoCounter NOT NULL,
	-- less has Text,
	Text                                    VariableLengthText(256) NOT NULL,
	PRIMARY KEY(FactTypeId, Ordinal),
	FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId),
	FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueConstraintId) REFERENCES ValueConstraint (ValueConstraintId)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (RingConstraintOtherRoleFactTypeId, RingConstraintOtherRoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (RingConstraintRoleFactTypeId, RingConstraintRoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
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
	ADD FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES Term (Name, VocabularyName)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (BaseUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE Derivation
	ADD FOREIGN KEY (DerivedUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE Fact
	ADD FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId)
GO

ALTER TABLE FactType
	ADD FOREIGN KEY (EntityTypeName, EntityTypeVocabularyName) REFERENCES Term (Name, VocabularyName)
GO

ALTER TABLE FactType
	ADD FOREIGN KEY (TypeInheritanceSubtypeName, TypeInheritanceSubtypeVocabularyName) REFERENCES Term (Name, VocabularyName)
GO

ALTER TABLE FactType
	ADD FOREIGN KEY (TypeInheritanceSupertypeName, TypeInheritanceSupertypeVocabularyName) REFERENCES Term (Name, VocabularyName)
GO

ALTER TABLE Instance
	ADD FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES Term (Name, VocabularyName)
GO

ALTER TABLE [Join]
	ADD FOREIGN KEY (InputRoleFactTypeId, InputRoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
GO

ALTER TABLE [Join]
	ADD FOREIGN KEY (OutputRoleFactTypeId, OutputRoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
GO

ALTER TABLE [Join]
	ADD FOREIGN KEY (RoleRefOrdinal, RoleRefRoleSequenceId) REFERENCES RoleRef (Ordinal, RoleSequenceId)
GO

ALTER TABLE [Join]
	ADD FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES Term (Name, VocabularyName)
GO

ALTER TABLE ParamValue
	ADD FOREIGN KEY (ValueTypeName, ValueTypeVocabularyName) REFERENCES Term (Name, VocabularyName)
GO

ALTER TABLE Role
	ADD FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES Term (Name, VocabularyName)
GO

ALTER TABLE Role
	ADD FOREIGN KEY (RoleValueConstraintId) REFERENCES ValueConstraint (ValueConstraintId)
GO

ALTER TABLE RoleRef
	ADD FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
GO

ALTER TABLE RoleRef
	ADD FOREIGN KEY (RoleTermName, RoleTermVocabularyName) REFERENCES Term (Name, VocabularyName)
GO

ALTER TABLE Term
	ADD FOREIGN KEY (ValueTypeUnitId) REFERENCES Unit (UnitId)
GO

ALTER TABLE Term
	ADD FOREIGN KEY (ValueTypeValueConstraintId) REFERENCES ValueConstraint (ValueConstraintId)
GO

