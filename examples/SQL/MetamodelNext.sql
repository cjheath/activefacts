CREATE TABLE AllowedRange (
	-- AllowedRange is where ValueConstraint allows ValueRange and ValueConstraint has ValueConstraintId,
	ValueConstraintId                       int NOT NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has maximum-Bound and Bound is inclusive,
	ValueRangeMaximumBoundIsInclusive       bit NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has maximum-Bound and Bound has Value and Value is a string,
	ValueRangeMaximumBoundValueIsAString    bit NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has maximum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMaximumBoundValueLiteral      varchar NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has maximum-Bound and Bound has Value and maybe Value is in Unit and Unit has UnitId,
	ValueRangeMaximumBoundValueUnitId       int NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has minimum-Bound and Bound is inclusive,
	ValueRangeMinimumBoundIsInclusive       bit NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has minimum-Bound and Bound has Value and Value is a string,
	ValueRangeMinimumBoundValueIsAString    bit NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has minimum-Bound and Bound has Value and Value is represented by Literal,
	ValueRangeMinimumBoundValueLiteral      varchar NULL,
	-- AllowedRange is where ValueConstraint allows ValueRange and maybe ValueRange has minimum-Bound and Bound has Value and maybe Value is in Unit and Unit has UnitId,
	ValueRangeMinimumBoundValueUnitId       int NULL,
	UNIQUE(ValueConstraintId, ValueRangeMinimumBoundValueUnitId, ValueRangeMinimumBoundValueLiteral, ValueRangeMinimumBoundValueIsAString, ValueRangeMinimumBoundIsInclusive, ValueRangeMaximumBoundValueUnitId, ValueRangeMaximumBoundValueLiteral, ValueRangeMaximumBoundValueIsAString, ValueRangeMaximumBoundIsInclusive)
)
GO

CREATE TABLE [Constraint] (
	-- Constraint has ConstraintId,
	ConstraintId                            int IDENTITY NOT NULL,
	-- maybe Constraint requires Enforcement,
	Enforcement                             varchar(16) NULL,
	-- maybe Name is of Constraint,
	Name                                    varchar(64) NULL,
	-- maybe PresenceConstraint is a kind of Constraint and PresenceConstraint is mandatory,
	PresenceConstraintIsMandatory           bit NULL,
	-- maybe PresenceConstraint is a kind of Constraint and PresenceConstraint is preferred identifier,
	PresenceConstraintIsPreferredIdentifier bit NULL,
	-- maybe PresenceConstraint is a kind of Constraint and maybe PresenceConstraint has max-Frequency,
	PresenceConstraintMaxFrequency          int NULL CHECK(PresenceConstraintMaxFrequency >= 1),
	-- maybe PresenceConstraint is a kind of Constraint and maybe PresenceConstraint has min-Frequency,
	PresenceConstraintMinFrequency          int NULL CHECK(PresenceConstraintMinFrequency >= 2),
	-- maybe PresenceConstraint is a kind of Constraint and PresenceConstraint covers RoleSequence and RoleSequence has RoleSequenceId,
	PresenceConstraintRoleSequenceId        int NULL,
	-- maybe RingConstraint is a kind of Constraint and maybe other-Role is of RingConstraint and Role is where FactType has Ordinal role and FactType has FactTypeId,
	RingConstraintOtherRoleFactTypeId       int NULL,
	-- maybe RingConstraint is a kind of Constraint and maybe other-Role is of RingConstraint and Role is where FactType has Ordinal role,
	RingConstraintOtherRoleOrdinal          int NULL,
	-- maybe RingConstraint is a kind of Constraint and RingConstraint is of RingType,
	RingConstraintRingType                  varchar NULL,
	-- maybe RingConstraint is a kind of Constraint and maybe Role is of RingConstraint and Role is where FactType has Ordinal role and FactType has FactTypeId,
	RingConstraintRoleFactTypeId            int NULL,
	-- maybe RingConstraint is a kind of Constraint and maybe Role is of RingConstraint and Role is where FactType has Ordinal role,
	RingConstraintRoleOrdinal               int NULL,
	-- maybe SetConstraint is a kind of Constraint and maybe SetComparisonConstraint is a kind of SetConstraint and maybe SetExclusionConstraint is a kind of SetComparisonConstraint and SetExclusionConstraint is mandatory,
	SetExclusionConstraintIsMandatory       bit NULL,
	-- maybe SetConstraint is a kind of Constraint and maybe SubsetConstraint is a kind of SetConstraint and SubsetConstraint covers subset-RoleSequence and RoleSequence has RoleSequenceId,
	SubsetConstraintSubsetRoleSequenceId    int NULL,
	-- maybe SetConstraint is a kind of Constraint and maybe SubsetConstraint is a kind of SetConstraint and SubsetConstraint covers superset-RoleSequence and RoleSequence has RoleSequenceId,
	SubsetConstraintSupersetRoleSequenceId  int NULL,
	-- maybe Vocabulary contains Constraint and Vocabulary is called Name,
	VocabularyName                          varchar(64) NULL,
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
	ContextNoteId                           int NOT NULL,
	-- maybe ContextAccordingTo lodged on Date,
	Date                                    datetime NULL,
	-- ContextAccordingTo is where ContextNote is according to Person and Person has PersonName,
	PersonName                              varchar NOT NULL,
	PRIMARY KEY(ContextNoteId, PersonName)
)
GO

CREATE TABLE ContextAgreedBy (
	-- ContextAgreedBy is where Agreement was reached by Person and ContextNote has ContextNoteId,
	AgreementContextNoteId                  int NOT NULL,
	-- ContextAgreedBy is where Agreement was reached by Person and Person has PersonName,
	PersonName                              varchar NOT NULL,
	PRIMARY KEY(AgreementContextNoteId, PersonName)
)
GO

CREATE TABLE ContextNote (
	-- maybe ContextNote was added by Agreement and maybe Agreement was on Date,
	AgreementDate                           datetime NULL,
	-- maybe Constraint has ContextNote and Constraint has ConstraintId,
	ConstraintId                            int NULL,
	-- ContextNote has ContextNoteId,
	ContextNoteId                           int IDENTITY NOT NULL,
	-- ContextNote has ContextNoteKind,
	ContextNoteKind                         varchar NOT NULL CHECK(ContextNoteKind = 'as_opposed_to' OR ContextNoteKind = 'because' OR ContextNoteKind = 'so_that' OR ContextNoteKind = 'to_avoid'),
	-- ContextNote has Discussion,
	Discussion                              varchar NOT NULL,
	-- maybe FactType has ContextNote and FactType has FactTypeId,
	FactTypeId                              int NULL,
	-- maybe ObjectType has ContextNote and Term is where Vocabulary contains Name,
	ObjectTypeName                          varchar(64) NULL,
	-- maybe ObjectType has ContextNote and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NULL,
	PRIMARY KEY(ContextNoteId),
	FOREIGN KEY (ConstraintId) REFERENCES [Constraint] (ConstraintId)
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
	-- Fact is of FactType and FactType has FactTypeId,
	FactTypeId                              int NOT NULL,
	-- Population includes Fact and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Fact and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	PRIMARY KEY(FactId)
)
GO

CREATE TABLE FactType (
	-- maybe EntityType nests FactType and Term is where Vocabulary contains Name,
	EntityTypeName                          varchar(64) NULL,
	-- maybe EntityType nests FactType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	EntityTypeVocabularyName                varchar(64) NULL,
	-- FactType has FactTypeId,
	FactTypeId                              int IDENTITY NOT NULL,
	-- maybe TypeInheritance is a kind of FactType and maybe Assimilation applies to TypeInheritance,
	TypeInheritanceAssimilation             varchar NULL CHECK(TypeInheritanceAssimilation = 'partitioned' OR TypeInheritanceAssimilation = 'separate'),
	-- maybe TypeInheritance is a kind of FactType and TypeInheritance provides identification,
	TypeInheritanceProvidesIdentification   bit NULL,
	-- maybe TypeInheritance is a kind of FactType and TypeInheritance is where Subtype is subtype of Supertype and Term is where Vocabulary contains Name,
	TypeInheritanceSubtypeName              varchar(64) NULL,
	-- maybe TypeInheritance is a kind of FactType and TypeInheritance is where Subtype is subtype of Supertype and Term is where Vocabulary contains Name and Vocabulary is called Name,
	TypeInheritanceSubtypeVocabularyName    varchar(64) NULL,
	-- maybe TypeInheritance is a kind of FactType and TypeInheritance is where Subtype is subtype of Supertype and Term is where Vocabulary contains Name,
	TypeInheritanceSupertypeName            varchar(64) NULL,
	-- maybe TypeInheritance is a kind of FactType and TypeInheritance is where Subtype is subtype of Supertype and Term is where Vocabulary contains Name and Vocabulary is called Name,
	TypeInheritanceSupertypeVocabularyName  varchar(64) NULL,
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
	FactId                                  int NULL,
	-- Instance has InstanceId,
	InstanceId                              int IDENTITY NOT NULL,
	-- Instance is of ObjectType and Term is where Vocabulary contains Name,
	ObjectTypeName                          varchar(64) NOT NULL,
	-- Instance is of ObjectType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NOT NULL,
	-- Population includes Instance and Population has Name,
	PopulationName                          varchar(64) NOT NULL,
	-- Population includes Instance and maybe Vocabulary includes Population and Vocabulary is called Name,
	PopulationVocabularyName                varchar(64) NULL,
	-- maybe Instance has Value and Value is a string,
	ValueIsAString                          bit NULL,
	-- maybe Instance has Value and Value is represented by Literal,
	ValueLiteral                            varchar NULL,
	-- maybe Instance has Value and maybe Value is in Unit and Unit has UnitId,
	ValueUnitId                             int NULL,
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
	InputRoleFactTypeId                     int NULL,
	-- maybe Join has input-Role and Role is where FactType has Ordinal role,
	InputRoleOrdinal                        int NULL,
	-- is anti-Join,
	[Is]                                    bit NOT NULL,
	-- Join is outer,
	IsOuter                                 bit NOT NULL,
	-- Join is where RoleRef has JoinStep join,
	JoinStep                                int NOT NULL,
	-- maybe Join traverses ObjectType and Term is where Vocabulary contains Name,
	ObjectTypeName                          varchar(64) NULL,
	-- maybe Join traverses ObjectType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NULL,
	-- maybe Join has output-Role and Role is where FactType has Ordinal role and FactType has FactTypeId,
	OutputRoleFactTypeId                    int NULL,
	-- maybe Join has output-Role and Role is where FactType has Ordinal role,
	OutputRoleOrdinal                       int NULL,
	-- Join is where RoleRef has JoinStep join and RoleRef is where RoleSequence in Ordinal position includes Role,
	RoleRefOrdinal                          int NOT NULL,
	-- Join is where RoleRef has JoinStep join and RoleRef is where RoleSequence in Ordinal position includes Role and RoleSequence has RoleSequenceId,
	RoleRefRoleSequenceId                   int NOT NULL,
	PRIMARY KEY(RoleRefRoleSequenceId, RoleRefOrdinal, JoinStep)
)
GO

CREATE TABLE ParamValue (
	-- ParamValue is where Value for Parameter applies to ValueType and Parameter is where Name is a parameter of ValueType,
	ParameterName                           varchar(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Parameter is where Name is a parameter of ValueType and Term is where Vocabulary contains Name,
	ParameterValueTypeName                  varchar(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Parameter is where Name is a parameter of ValueType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ParameterValueTypeVocabularyName        varchar(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Value is a string,
	ValueIsAString                          bit NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Value is represented by Literal,
	ValueLiteral                            varchar NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Term is where Vocabulary contains Name,
	ValueTypeName                           varchar(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ValueTypeVocabularyName                 varchar(64) NOT NULL,
	-- ParamValue is where Value for Parameter applies to ValueType and maybe Value is in Unit and Unit has UnitId,
	ValueUnitId                             int NULL,
	UNIQUE(ValueUnitId, ValueLiteral, ValueIsAString, ParameterName, ParameterValueTypeVocabularyName, ParameterValueTypeName)
)
GO

CREATE TABLE Reading (
	-- FactType has Reading and FactType has FactTypeId,
	FactTypeId                              int NOT NULL,
	-- Reading is in Ordinal position,
	Ordinal                                 int NOT NULL,
	-- Reading is in RoleSequence and RoleSequence has RoleSequenceId,
	RoleSequenceId                          int NOT NULL,
	-- Reading has Text,
	Text                                    varchar(256) NOT NULL,
	PRIMARY KEY(FactTypeId, Ordinal),
	FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId)
)
GO

CREATE TABLE Role (
	-- Role is where FactType has Ordinal role and FactType has FactTypeId,
	FactTypeId                              int NOT NULL,
	-- ObjectType plays Role and Term is where Vocabulary contains Name,
	ObjectTypeName                          varchar(64) NOT NULL,
	-- ObjectType plays Role and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NOT NULL,
	-- Role is where FactType has Ordinal role,
	Ordinal                                 int NOT NULL,
	-- maybe Role has role-ValueConstraint and ValueConstraint has ValueConstraintId,
	RoleValueConstraintId                   int NULL,
	PRIMARY KEY(FactTypeId, Ordinal),
	FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId)
)
GO

CREATE TABLE RoleRef (
	-- maybe RoleRef has leading-Adjective,
	LeadingAdjective                        varchar(64) NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role,
	Ordinal                                 int NOT NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and Role is where FactType has Ordinal role and FactType has FactTypeId,
	RoleFactTypeId                          int NOT NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and Role is where FactType has Ordinal role,
	RoleOrdinal                             int NOT NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and RoleSequence has RoleSequenceId,
	RoleSequenceId                          int NOT NULL,
	-- maybe RoleRef has role-Term and Term is where Vocabulary contains Name,
	RoleTermName                            varchar(64) NULL,
	-- maybe RoleRef has role-Term and Term is where Vocabulary contains Name and Vocabulary is called Name,
	RoleTermVocabularyName                  varchar(64) NULL,
	-- maybe RoleRef has trailing-Adjective,
	TrailingAdjective                       varchar(64) NULL,
	PRIMARY KEY(RoleSequenceId, Ordinal),
	UNIQUE(RoleFactTypeId, RoleOrdinal, RoleSequenceId),
	FOREIGN KEY (RoleFactTypeId, RoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
)
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
	-- RoleValue is of Role and Role is where FactType has Ordinal role and FactType has FactTypeId,
	RoleFactTypeId                          int NOT NULL,
	-- RoleValue is of Role and Role is where FactType has Ordinal role,
	RoleOrdinal                             int NOT NULL,
	PRIMARY KEY(InstanceId, FactId),
	FOREIGN KEY (FactId) REFERENCES Fact (FactId),
	FOREIGN KEY (InstanceId) REFERENCES Instance (InstanceId),
	FOREIGN KEY (RoleFactTypeId, RoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
)
GO

CREATE TABLE SetComparisonRoles (
	-- SetComparisonRoles is where SetComparisonConstraint has in Ordinal position RoleSequence,
	Ordinal                                 int NOT NULL,
	-- SetComparisonRoles is where SetComparisonConstraint has in Ordinal position RoleSequence and RoleSequence has RoleSequenceId,
	RoleSequenceId                          int NOT NULL,
	-- SetComparisonRoles is where SetComparisonConstraint has in Ordinal position RoleSequence and Constraint has ConstraintId,
	SetComparisonConstraintId               int NOT NULL,
	PRIMARY KEY(SetComparisonConstraintId, Ordinal),
	UNIQUE(SetComparisonConstraintId, RoleSequenceId),
	FOREIGN KEY (SetComparisonConstraintId) REFERENCES [Constraint] (ConstraintId),
	FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
)
GO

CREATE TABLE Term (
	-- Term is where Vocabulary contains Name,
	Name                                    varchar(64) NOT NULL,
	-- maybe Term designates ObjectType and ObjectType is independent,
	ObjectTypeIsIndependent                 bit NULL,
	-- maybe Term is secondary for ObjectType and Term is where Vocabulary contains Name,
	ObjectTypeName                          varchar(64) NULL,
	-- maybe Term designates ObjectType and maybe ObjectType uses Pronoun,
	ObjectTypePronoun                       varchar(20) NULL CHECK(ObjectTypePronoun = 'feminine' OR ObjectTypePronoun = 'masculine' OR ObjectTypePronoun = 'neuter' OR ObjectTypePronoun = 'personal'),
	-- maybe Term is secondary for ObjectType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ObjectTypeVocabularyName                varchar(64) NULL,
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType has Length,
	ValueTypeLength                         int NULL,
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType has Scale,
	ValueTypeScale                          int NULL,
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType is subtype of Supertype and Term is where Vocabulary contains Name,
	ValueTypeSupertypeName                  varchar(64) NULL,
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType is subtype of Supertype and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ValueTypeSupertypeVocabularyName        varchar(64) NULL,
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType is of Unit and Unit has UnitId,
	ValueTypeUnitId                         int NULL,
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType has ValueConstraint and ValueConstraint has ValueConstraintId,
	ValueTypeValueConstraintId              int NULL,
	-- Term is where Vocabulary contains Name and Vocabulary is called Name,
	VocabularyName                          varchar(64) NOT NULL,
	PRIMARY KEY(VocabularyName, Name),
	FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES Term (Name, VocabularyName),
	FOREIGN KEY (ValueTypeSupertypeName, ValueTypeSupertypeVocabularyName) REFERENCES Term (Name, VocabularyName)
)
GO

CREATE TABLE Unit (
	-- maybe Unit has Coefficient and Coefficient has Denominator,
	CoefficientDenominator                  int NULL,
	-- maybe Unit has Coefficient and Coefficient is precise,
	CoefficientIsPrecise                    bit NULL,
	-- maybe Unit has Coefficient and Coefficient has Numerator,
	CoefficientNumerator                    decimal NULL,
	-- maybe Ephemera provides Unit coefficient,
	Ephemera                                varchar NULL,
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

CREATE TABLE ValueConstraint (
	-- ValueConstraint has ValueConstraintId,
	ValueConstraintId                       int IDENTITY NOT NULL,
	PRIMARY KEY(ValueConstraintId)
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

ALTER TABLE Reading
	ADD FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
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

