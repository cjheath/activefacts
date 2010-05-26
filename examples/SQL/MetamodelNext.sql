CREATE TABLE AllowedRange (
	-- AllowedRange is where ValueConstraint allows ValueRange and Constraint has ConstraintId,
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
	-- maybe Constraint requires Enforcement and maybe Enforcement notifies Agent and Agent has AgentName,
	EnforcementAgentName                    varchar NULL,
	-- maybe Constraint requires Enforcement and Enforcement has EnforcementCode,
	EnforcementCode                         varchar(16) NULL,
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
	-- maybe ValueConstraint is a kind of Constraint and maybe Role has role-ValueConstraint and Role is where FactType has Ordinal role and FactType has FactTypeId,
	ValueConstraintRoleFactTypeId           int NULL,
	-- maybe ValueConstraint is a kind of Constraint and maybe Role has role-ValueConstraint and Role is where FactType has Ordinal role,
	ValueConstraintRoleOrdinal              int NULL,
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

CREATE VIEW dbo.ValueConstraintInConstraint_RoleFactTypeIdRoleOrdinal (ValueConstraintRoleFactTypeId, ValueConstraintRoleOrdinal) WITH SCHEMABINDING AS
	SELECT ValueConstraintRoleFactTypeId, ValueConstraintRoleOrdinal FROM dbo.[Constraint]
	WHERE	ValueConstraintRoleFactTypeId IS NOT NULL
	  AND	ValueConstraintRoleOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX RoleHasOneRoleValueConstraint ON dbo.ValueConstraintInConstraint_RoleFactTypeIdRoleOrdinal(ValueConstraintRoleFactTypeId, ValueConstraintRoleOrdinal)
GO

CREATE VIEW dbo.Constraint_VocabularyNameName (VocabularyName, Name) WITH SCHEMABINDING AS
	SELECT VocabularyName, Name FROM dbo.[Constraint]
	WHERE	VocabularyName IS NOT NULL
	  AND	Name IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ConstraintByVocabularyNameName ON dbo.Constraint_VocabularyNameName(VocabularyName, Name)
GO

CREATE TABLE ContextAccordingTo (
	-- ContextAccordingTo is where ContextNote is according to Agent and Agent has AgentName,
	AgentName                               varchar NOT NULL,
	-- ContextAccordingTo is where ContextNote is according to Agent and ContextNote has ContextNoteId,
	ContextNoteId                           int NOT NULL,
	-- maybe ContextAccordingTo was lodged on Date,
	Date                                    datetime NULL,
	PRIMARY KEY(ContextNoteId, AgentName)
)
GO

CREATE TABLE ContextAgreedBy (
	-- ContextAgreedBy is where Agreement was reached by Agent and Agent has AgentName,
	AgentName                               varchar NOT NULL,
	-- ContextAgreedBy is where Agreement was reached by Agent and ContextNote has ContextNoteId,
	AgreementContextNoteId                  int NOT NULL,
	PRIMARY KEY(AgreementContextNoteId, AgentName)
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
	-- is anti Join,
	IsAnti                                  bit NOT NULL,
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
	PRIMARY KEY(FactTypeId, Ordinal),
	FOREIGN KEY (FactTypeId) REFERENCES FactType (FactTypeId)
)
GO

CREATE TABLE RoleDisplay (
	-- RoleDisplay is where FactTypeShape displays Role in Ordinal position and Shape has ShapeId,
	FactTypeShapeId                         int NOT NULL,
	-- RoleDisplay is where FactTypeShape displays Role in Ordinal position,
	Ordinal                                 int NOT NULL,
	-- RoleDisplay is where FactTypeShape displays Role in Ordinal position and Role is where FactType has Ordinal role and FactType has FactTypeId,
	RoleFactTypeId                          int NOT NULL,
	-- RoleDisplay is where FactTypeShape displays Role in Ordinal position and Role is where FactType has Ordinal role,
	RoleOrdinal                             int NOT NULL,
	PRIMARY KEY(FactTypeShapeId, Ordinal),
	FOREIGN KEY (RoleFactTypeId, RoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
)
GO

CREATE TABLE RoleRef (
	-- maybe RoleRef has leading-Adjective,
	LeadingAdjective                        varchar(64) NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role,
	Ordinal                                 int NOT NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and Role is where FactType has Ordinal role and FactType has FactTypeId,
	RoleFactTypeId                          int NOT NULL,
	-- maybe RoleName is name of RoleRef and Term is where Vocabulary contains Name,
	RoleName                                varchar(64) NULL,
	-- maybe RoleName is name of RoleRef and Term is where Vocabulary contains Name and Vocabulary is called Name,
	RoleNameVocabularyName                  varchar(64) NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and Role is where FactType has Ordinal role,
	RoleOrdinal                             int NOT NULL,
	-- RoleRef is where RoleSequence in Ordinal position includes Role and RoleSequence has RoleSequenceId,
	RoleSequenceId                          int NOT NULL,
	-- maybe RoleRef has trailing-Adjective,
	TrailingAdjective                       varchar(64) NULL,
	PRIMARY KEY(RoleSequenceId, Ordinal),
	UNIQUE(RoleFactTypeId, RoleOrdinal, RoleSequenceId),
	FOREIGN KEY (RoleFactTypeId, RoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
)
GO

CREATE TABLE RoleSequence (
	-- RoleSequence has unused dependency to force table in norma,
	HasUnusedDependencyToForceTableInNorma  bit NOT NULL,
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

CREATE TABLE Shape (
	-- maybe ConstraintShape is a kind of Shape and ConstraintShape is for Constraint and Constraint has ConstraintId,
	ConstraintShapeConstraintId             int NULL,
	-- Shape is in Diagram and Diagram is called Name,
	DiagramName                             varchar(64) NOT NULL,
	-- Shape is in Diagram and Diagram is for Vocabulary and Vocabulary is called Name,
	DiagramVocabularyName                   varchar(64) NOT NULL,
	-- maybe FactTypeShape is a kind of Shape and maybe FactTypeShape has DisplayRoleNamesSetting,
	FactTypeShapeDisplayRoleNamesSetting    varchar NULL CHECK(FactTypeShapeDisplayRoleNamesSetting = 'false' OR FactTypeShapeDisplayRoleNamesSetting = 'true'),
	-- maybe FactTypeShape is a kind of Shape and FactTypeShape is for FactType and FactType has FactTypeId,
	FactTypeShapeFactTypeId                 int NULL,
	-- maybe FactTypeShape is a kind of Shape and maybe ObjectifiedFactTypeNameShape is for FactTypeShape and ObjectifiedFactTypeNameShape is a kind of Shape and Shape has ShapeId,
	FactTypeShapeId                         int NULL,
	-- maybe FactTypeShape is a kind of Shape and maybe FactTypeShape has ReadingShape and ReadingShape is a kind of Shape and Shape has ShapeId,
	FactTypeShapeId                         int NULL,
	-- maybe FactTypeShape is a kind of Shape and maybe FactTypeShape has ReadingShape and ReadingShape is for Reading and FactType has Reading and FactType has FactTypeId,
	FactTypeShapeReadingFactTypeId          int NULL,
	-- maybe FactTypeShape is a kind of Shape and maybe FactTypeShape has ReadingShape and ReadingShape is for Reading and Reading is in Ordinal position,
	FactTypeShapeReadingOrdinal             int NULL,
	-- maybe FactTypeShape is a kind of Shape and maybe FactTypeShape has RotationSetting,
	FactTypeShapeRotationSetting            varchar NULL CHECK(FactTypeShapeRotationSetting = 'left' OR FactTypeShapeRotationSetting = 'right'),
	-- Shape is expanded,
	IsExpanded                              bit NOT NULL,
	-- maybe ModelNoteShape is a kind of Shape and ModelNoteShape is for ContextNote and ContextNote has ContextNoteId,
	ModelNoteShapeContextNoteId             int NULL,
	-- maybe ObjectTypeShape is a kind of Shape and ObjectTypeShape has expanded reference mode,
	ObjectTypeShapeHasExpandedReferenceMode bit NULL,
	-- maybe ObjectTypeShape is a kind of Shape and ObjectTypeShape is for ObjectType and Term is where Vocabulary contains Name,
	ObjectTypeShapeObjectTypeName           varchar(64) NULL,
	-- maybe ObjectTypeShape is a kind of Shape and ObjectTypeShape is for ObjectType and Term is where Vocabulary contains Name and Vocabulary is called Name,
	ObjectTypeShapeObjectTypeVocabularyName varchar(64) NULL,
	-- maybe Shape is at Position and Position is at X,
	PositionX                               int NULL,
	-- maybe Shape is at Position and Position is at Y,
	PositionY                               int NULL,
	-- maybe ConstraintShape is a kind of Shape and maybe RingConstraintShape is a kind of ConstraintShape and RingConstraintShape is attached to FactType and FactType has FactTypeId,
	RingConstraintShapeFactTypeId           int NULL,
	-- maybe RoleNameShape is a kind of Shape and RoleNameShape is for RoleDisplay and RoleDisplay is where FactTypeShape displays Role in Ordinal position and Shape has ShapeId,
	RoleNameShapeRoleDisplayFactTypeShapeId int NULL,
	-- maybe RoleNameShape is a kind of Shape and RoleNameShape is for RoleDisplay and RoleDisplay is where FactTypeShape displays Role in Ordinal position,
	RoleNameShapeRoleDisplayOrdinal         int NULL,
	-- Shape has ShapeId,
	ShapeId                                 int IDENTITY NOT NULL,
	-- maybe ConstraintShape is a kind of Shape and maybe ValueConstraintShape is a kind of ConstraintShape and maybe ValueConstraintShape is for ObjectTypeShape and Shape has ShapeId,
	ValueConstraintShapeObjectTypeShapeId   int NULL,
	-- maybe ConstraintShape is a kind of Shape and maybe ValueConstraintShape is a kind of ConstraintShape and maybe RoleDisplay has ValueConstraintShape and RoleDisplay is where FactTypeShape displays Role in Ordinal position and Shape has ShapeId,
	ValueConstraintShapeRoleDisplayFactTypeShapeId int NULL,
	-- maybe ConstraintShape is a kind of Shape and maybe ValueConstraintShape is a kind of ConstraintShape and maybe RoleDisplay has ValueConstraintShape and RoleDisplay is where FactTypeShape displays Role in Ordinal position,
	ValueConstraintShapeRoleDisplayOrdinal  int NULL,
	PRIMARY KEY(ShapeId),
	FOREIGN KEY (ConstraintShapeConstraintId) REFERENCES [Constraint] (ConstraintId),
	FOREIGN KEY (ModelNoteShapeContextNoteId) REFERENCES ContextNote (ContextNoteId),
	FOREIGN KEY (RingConstraintShapeFactTypeId) REFERENCES FactType (FactTypeId),
	FOREIGN KEY (FactTypeShapeFactTypeId) REFERENCES FactType (FactTypeId),
	FOREIGN KEY (FactTypeShapeReadingFactTypeId, FactTypeShapeReadingOrdinal) REFERENCES Reading (FactTypeId, Ordinal),
	FOREIGN KEY (ValueConstraintShapeRoleDisplayFactTypeShapeId, ValueConstraintShapeRoleDisplayOrdinal) REFERENCES RoleDisplay (FactTypeShapeId, Ordinal),
	FOREIGN KEY (RoleNameShapeRoleDisplayFactTypeShapeId, RoleNameShapeRoleDisplayOrdinal) REFERENCES RoleDisplay (FactTypeShapeId, Ordinal),
	FOREIGN KEY (ValueConstraintShapeObjectTypeShapeId) REFERENCES Shape (ShapeId),
	FOREIGN KEY (FactTypeShapeId) REFERENCES Shape (ShapeId),
	FOREIGN KEY (FactTypeShapeId) REFERENCES Shape (ShapeId)
)
GO

CREATE VIEW dbo.Shape_DiagramVocabularyNameDiagramNamePositionXPositionY (DiagramVocabularyName, DiagramName, PositionX, PositionY) WITH SCHEMABINDING AS
	SELECT DiagramVocabularyName, DiagramName, PositionX, PositionY FROM dbo.Shape
	WHERE	PositionX IS NOT NULL
	  AND	PositionY IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ShapeByDiagramVocabularyNameDiagramNamePositionXPositionY ON dbo.Shape_DiagramVocabularyNameDiagramNamePositionXPositionY(DiagramVocabularyName, DiagramName, PositionX, PositionY)
GO

CREATE VIEW dbo.ReadingShapeInShape_FactTypeShapeId (FactTypeShapeId) WITH SCHEMABINDING AS
	SELECT FactTypeShapeId FROM dbo.Shape
	WHERE	FactTypeShapeId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ReadingShapeInShapeByFactTypeShapeId ON dbo.ReadingShapeInShape_FactTypeShapeId(FactTypeShapeId)
GO

CREATE VIEW dbo.ObjectifiedFactTypeNameShapeInShape_FactTypeShapeId (FactTypeShapeId) WITH SCHEMABINDING AS
	SELECT FactTypeShapeId FROM dbo.Shape
	WHERE	FactTypeShapeId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ObjectifiedFactTypeNameShapeInShapeByFactTypeShapeId ON dbo.ObjectifiedFactTypeNameShapeInShape_FactTypeShapeId(FactTypeShapeId)
GO

CREATE VIEW dbo.RoleNameShapeInShape_RoleDisplayFactTypeShapeIdRoleDisplayOrdinal (RoleNameShapeRoleDisplayFactTypeShapeId, RoleNameShapeRoleDisplayOrdinal) WITH SCHEMABINDING AS
	SELECT RoleNameShapeRoleDisplayFactTypeShapeId, RoleNameShapeRoleDisplayOrdinal FROM dbo.Shape
	WHERE	RoleNameShapeRoleDisplayFactTypeShapeId IS NOT NULL
	  AND	RoleNameShapeRoleDisplayOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_RoleNameShapeInShapeByRoleNameShapeRoleDisplayFactTypeShapeIdRoleNameShapeRoleDisplayOrdinal ON dbo.RoleNameShapeInShape_RoleDisplayFactTypeShapeIdRoleDisplayOrdinal(RoleNameShapeRoleDisplayFactTypeShapeId, RoleNameShapeRoleDisplayOrdinal)
GO

CREATE VIEW dbo.ValueConstraintShapeInShape_RoleDisplayFactTypeShapeIdRoleDisplayOrdinal (ValueConstraintShapeRoleDisplayFactTypeShapeId, ValueConstraintShapeRoleDisplayOrdinal) WITH SCHEMABINDING AS
	SELECT ValueConstraintShapeRoleDisplayFactTypeShapeId, ValueConstraintShapeRoleDisplayOrdinal FROM dbo.Shape
	WHERE	ValueConstraintShapeRoleDisplayFactTypeShapeId IS NOT NULL
	  AND	ValueConstraintShapeRoleDisplayOrdinal IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueConstraintShapeInShapeByValueConstraintShapeRoleDisplayFactTypeShapeIdValueConstraintShapeRoleDisplayOrdinal ON dbo.ValueConstraintShapeInShape_RoleDisplayFactTypeShapeIdRoleDisplayOrdinal(ValueConstraintShapeRoleDisplayFactTypeShapeId, ValueConstraintShapeRoleDisplayOrdinal)
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
	-- maybe Term designates ObjectType and maybe ValueType is a kind of ObjectType and maybe ValueType has ValueConstraint and Constraint has ConstraintId,
	ValueTypeValueConstraintId              int NULL,
	-- Term is where Vocabulary contains Name and Vocabulary is called Name,
	VocabularyName                          varchar(64) NOT NULL,
	PRIMARY KEY(VocabularyName, Name),
	FOREIGN KEY (ValueTypeValueConstraintId) REFERENCES [Constraint] (ConstraintId),
	FOREIGN KEY (ObjectTypeName, ObjectTypeVocabularyName) REFERENCES Term (Name, VocabularyName),
	FOREIGN KEY (ValueTypeSupertypeName, ValueTypeSupertypeVocabularyName) REFERENCES Term (Name, VocabularyName)
)
GO

CREATE VIEW dbo.ValueTypeInTerm_ValueConstraintId (ValueTypeValueConstraintId) WITH SCHEMABINDING AS
	SELECT ValueTypeValueConstraintId FROM dbo.Term
	WHERE	ValueTypeValueConstraintId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ValueTypeInTermByValueTypeValueConstraintId ON dbo.ValueTypeInTerm_ValueConstraintId(ValueTypeValueConstraintId)
GO

CREATE TABLE Unit (
	-- maybe Unit has Coefficient and Coefficient has Denominator,
	CoefficientDenominator                  int NULL,
	-- maybe Unit has Coefficient and Coefficient is precise,
	CoefficientIsPrecise                    bit NULL,
	-- maybe Unit has Coefficient and Coefficient has Numerator,
	CoefficientNumerator                    decimal NULL,
	-- maybe EphemeraURL provides Unit coefficient,
	EphemeraURL                             varchar NULL,
	-- Unit is fundamental,
	IsFundamental                           bit NOT NULL,
	-- Name is of Unit,
	Name                                    varchar(64) NOT NULL,
	-- maybe Unit has Offset,
	Offset                                  decimal NULL,
	-- maybe Unit has plural-Name,
	PluralName                              varchar(64) NULL,
	-- Unit has UnitId,
	UnitId                                  int IDENTITY NOT NULL,
	-- Vocabulary includes Unit and Vocabulary is called Name,
	VocabularyName                          varchar(64) NOT NULL,
	PRIMARY KEY(UnitId),
	UNIQUE(VocabularyName, Name)
)
GO

ALTER TABLE AllowedRange
	ADD FOREIGN KEY (ValueConstraintId) REFERENCES [Constraint] (ConstraintId)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (RingConstraintOtherRoleFactTypeId, RingConstraintOtherRoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (RingConstraintRoleFactTypeId, RingConstraintRoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
GO

ALTER TABLE [Constraint]
	ADD FOREIGN KEY (ValueConstraintRoleFactTypeId, ValueConstraintRoleOrdinal) REFERENCES Role (FactTypeId, Ordinal)
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

ALTER TABLE RoleDisplay
	ADD FOREIGN KEY (FactTypeShapeId) REFERENCES Shape (ShapeId)
GO

ALTER TABLE RoleRef
	ADD FOREIGN KEY (RoleSequenceId) REFERENCES RoleSequence (RoleSequenceId)
GO

ALTER TABLE RoleRef
	ADD FOREIGN KEY (RoleName, RoleNameVocabularyName) REFERENCES Term (Name, VocabularyName)
GO

ALTER TABLE Shape
	ADD FOREIGN KEY (ObjectTypeShapeObjectTypeName, ObjectTypeShapeObjectTypeVocabularyName) REFERENCES Term (Name, VocabularyName)
GO

ALTER TABLE Term
	ADD FOREIGN KEY (ValueTypeUnitId) REFERENCES Unit (UnitId)
GO

