/*
 * Object Role Modeling Metamodel
 */

CREATE TABLE [Schema] (
	SchemaID		int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	PartOfSchemaID		int NULL,
	CONSTRAINT PK_Schema
		PRIMARY KEY CLUSTERED (SchemaID),
	CONSTRAINT UQ_Schema
		UNIQUE(Name),
	CONSTRAINT FK_Schema_PartOfSchema
		FOREIGN KEY (PartOfSchemaID)
		REFERENCES [Schema](SchemaID)
)
GO

-- Definition of Units
CREATE TABLE Unit (
	UnitID			int IDENTITY NOT NULL,
	UnitName		nvarchar (64) NOT NULL,
	Numerator		decimal(38,19) NULL,
	Denominator		int NULL,
	IsPrecise		bit NOT NULL DEFAULT 1,
	CONSTRAINT PK_Unit
		PRIMARY KEY CLUSTERED (UnitID)
)
GO

-- All the BaseUnits that are for a Unit form the Unit's definition
CREATE TABLE BaseUnit (
	BaseForUnitID		int NOT NULL,
	BaseUnitID		int NOT NULL,
	Exponent		int NULL,
	CONSTRAINT PK_BaseUnit
		PRIMARY KEY CLUSTERED (BaseForUnitID, BaseUnitID)
)
GO

CREATE TABLE ValueRestriction (
	ValueRestrictionID	int IDENTITY NOT NULL,
	CONSTRAINT PK_ValueRestriction
		PRIMARY KEY CLUSTERED (ValueRestrictionID)
)
GO

CREATE TABLE ValueRange (
	ValueRangeID		int IDENTITY NOT NULL,
	ValueRestrictionID	int NOT NULL,
	Minimum			nvarchar (256) NULL,	-- Lexical representation of value
	Maximum			nvarchar (256) NULL,	-- Lexical representation of value
	Clusivity		int DEFAULT 1,		-- Bitmask, 1=Min, 2=Max
	CONSTRAINT PK_ValueRange
		PRIMARY KEY CLUSTERED (ValueRangeID),
	CONSTRAINT FK_ValueRange_ValueRestriction
		FOREIGN KEY (ValueRestrictionID)
		REFERENCES ValueRestriction(ValueRestrictionID)
)
GO

-- A DataType's representation maps to a programming language or storage type
-- If a DataType has no ValueRestrictionID, all values of the base type are allowed
CREATE TABLE DataType (
	DataTypeID		int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	Representation		nvarchar (64) NOT NULL,
	Length			int NULL,
	Scale			int NULL,
	ValueRestrictionID	int NULL,
	UnitID			int NULL,
	CONSTRAINT PK_DataType
		PRIMARY KEY CLUSTERED (DataTypeID),
	CONSTRAINT UQ_DataType
		UNIQUE(Name),
	CONSTRAINT FK_DataType_Unit
		FOREIGN KEY (UnitID)
		REFERENCES Unit(UnitID),
	CONSTRAINT FK_DataType_ValueRestriction
		FOREIGN KEY (ValueRestrictionID)
		REFERENCES ValueRestriction(ValueRestrictionID)
)
GO

CREATE TABLE FactType (
	FactTypeID		int IDENTITY NOT NULL,
	Name			nvarchar (64) NULL,
	CONSTRAINT PK_FactType
		PRIMARY KEY CLUSTERED (FactTypeID)
--	CONSTRAINT UQ_FactType UNIQUE(Name)		-- There may be multiple NULLs
)
GO

CREATE TABLE ObjectType (
	ObjectTypeID		int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	SchemaID		int NOT NULL,
	DataTypeID		int NULL,		-- Only if a ValueType
	NestsFactType		int NULL,		-- Only if an ObjectifiedType
	IsIndependent		bit NOT NULL DEFAULT 0,
	IsPersonal		bit NOT NULL DEFAULT 0,
	CONSTRAINT PK_ObjectType
		PRIMARY KEY CLUSTERED (ObjectTypeID),
--	CONSTRAINT UQ_ObjectType UNIQUE(Name),		-- There may be multiple NULLs
	CONSTRAINT FK_ObjectType_DataType
		FOREIGN KEY (DataTypeID)
		REFERENCES DataType(DataTypeID),
	CONSTRAINT FK_ObjectType_FactType
		FOREIGN KEY (NestsFactType)
		REFERENCES FactType(FactTypeID),
	CONSTRAINT FK_ObjectType_Schema
		FOREIGN KEY (SchemaID)
		REFERENCES [Schema](SchemaID),
)
GO

CREATE TABLE SubType (
	SubTypeID		int NOT NULL,
	SuperTypeID		int NOT NULL,
	SubTypeFactTypeID	int NOT NULL,
	CONSTRAINT PK_SubType
		PRIMARY KEY CLUSTERED (SubTypeID, SuperTypeID),
	CONSTRAINT FK_SubType_ObjectType
		FOREIGN KEY (SuperTypeID)
		REFERENCES ObjectType(ObjectTypeID),
	CONSTRAINT FK_SubType_SubType
		FOREIGN KEY (SubTypeID)
		REFERENCES ObjectType(ObjectTypeID),
	CONSTRAINT FK_SubType_FactType
		FOREIGN KEY (SubTypeFactTypeID)
		REFERENCES FactType(FactTypeID)
)
GO

CREATE TABLE Role (
	RoleID			int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	FactTypeID		int NOT NULL,
	ObjectTypeID		int NOT NULL,
	DataSubTypeID		int NULL,	-- Must be a subtype of Object's DataType
	CONSTRAINT PK_Role
		PRIMARY KEY CLUSTERED (RoleID),
	CONSTRAINT UQ_Role
		UNIQUE(FactTypeID, ObjectTypeID),
	CONSTRAINT FK_Role_FactType
		FOREIGN KEY (FactTypeID)
		REFERENCES FactType(FactTypeID),
	CONSTRAINT FK_Role_ObjectType
		FOREIGN KEY (ObjectTypeID)
		REFERENCES ObjectType(ObjectTypeID),
	CONSTRAINT FK_Role_DataType
		FOREIGN KEY (DataSubTypeID)
		REFERENCES DataType(DataTypeID),
)
GO

CREATE TABLE RoleSequence (
	RoleSequenceID		int IDENTITY NOT NULL,
	CONSTRAINT PK_RoleSequence
		PRIMARY KEY CLUSTERED (RoleSequenceID)
)
GO

CREATE TABLE Reading (
	ReadingID		int IDENTITY NOT NULL,
	FactTypeID		int NOT NULL,
	RoleSequenceID		int NOT NULL,
	Text			nvarchar (256) NOT NULL,
	CONSTRAINT PK_Reading
		PRIMARY KEY CLUSTERED (ReadingID),
	CONSTRAINT FK_Reading_FactType
		FOREIGN KEY (FactTypeID)
		REFERENCES FactType(FactTypeID),
	CONSTRAINT FK_Reading_RoleSequence
		FOREIGN KEY (RoleSequenceID)
		REFERENCES RoleSequence(RoleSequenceID)
)
GO

CREATE TABLE RoleSequenceRole (
	RoleSequenceId		int NOT NULL,
	RoleID			int NOT NULL,
	Sequence		int NOT NULL,		-- Consecutive from 1
	CONSTRAINT PK_RoleSequenceRole
		PRIMARY KEY CLUSTERED (RoleSequenceId, RoleID),
	CONSTRAINT UQ_RoleSequenceRole
		UNIQUE(RoleSequenceId, Sequence),
	CONSTRAINT FK_RoleSequenceRole_Role
		FOREIGN KEY (RoleID)
		REFERENCES Role(RoleID),
	CONSTRAINT FK_RoleSequenceRole_RoleSequence
		FOREIGN KEY (RoleSequenceId)
		REFERENCES RoleSequence(RoleSequenceID)
)
GO

/*
 * Constraints
 */
CREATE TABLE PresenceConstraint (
	PresenceConstraintID	int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	Enforcement		char(1) default 'M',
	RoleSequenceID		int NOT NULL,
	MinOccurs		int NULL,
	MaxOccurs		int NULL,
	IsMandatory		bit NOT NULL,
	IsPreferredIdentifier	bit NULL,
	CONSTRAINT PK_PresenceConstraint
		PRIMARY KEY CLUSTERED (PresenceConstraintID),
	CONSTRAINT FK_PresenceConstraint_RoleSequence
		FOREIGN KEY (RoleSequenceID)
		REFERENCES RoleSequence(RoleSequenceID)
)
GO

CREATE TABLE SubsetConstraint (
	SubsetConstraintID	int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	Enforcement		char(1) default 'M',
	FromRoleSequenceID	int NOT NULL,
	ToRoleSequenceID	int NOT NULL,
	CONSTRAINT PK_SubsetConstraint
		PRIMARY KEY CLUSTERED (SubsetConstraintID),
	CONSTRAINT FK_SubsetConstraint_FromRoleSequence
		FOREIGN KEY (FromRoleSequenceID)
		REFERENCES RoleSequence(RoleSequenceID),
	CONSTRAINT FK_SubsetConstraint_ToRoleSequence
		FOREIGN KEY (ToRoleSequenceID)
		REFERENCES RoleSequence(RoleSequenceID)
)
GO

CREATE TABLE EqualityConstraint (
	EqualityConstraintID int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	Enforcement		char(1) default 'M',
	CONSTRAINT PK_EqualityConstraint
		PRIMARY KEY CLUSTERED (EqualityConstraintID)
)
GO

CREATE TABLE EqualitySequence (
	EqualityConstraintID	int NOT NULL,
	RoleSequenceID		int NOT NULL,
	CONSTRAINT PK_EqualitySequence
		PRIMARY KEY CLUSTERED (EqualityConstraintID, RoleSequenceID),
	CONSTRAINT FK_EqualitySequence_EqualityConstraint
		FOREIGN KEY (EqualityConstraintID)
		REFERENCES EqualityConstraint(EqualityConstraintID),
	CONSTRAINT FK_EqualitySequence_RoleSequence
		FOREIGN KEY (RoleSequenceID)
		REFERENCES RoleSequence(RoleSequenceID)
)
GO

CREATE TABLE ExclusionConstraint (
	ExclusionConstraintID int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	Enforcement		char(1) default 'M',
	CONSTRAINT PK_ExclusionConstraint
		PRIMARY KEY CLUSTERED (ExclusionConstraintID)
)
GO

CREATE TABLE ExclusionSequence (
	ExclusionConstraintID	int NOT NULL,
	RoleSequenceID		int NOT NULL,
	CONSTRAINT PK_ExclusionSequence
		PRIMARY KEY CLUSTERED (ExclusionConstraintID, RoleSequenceID),
	CONSTRAINT FK_ExclusionSequence_ExclusionConstraint
		FOREIGN KEY (ExclusionConstraintID)
		REFERENCES ExclusionConstraint(ExclusionConstraintID),
	CONSTRAINT FK_ExclusionSequence_RoleSequence
		FOREIGN KEY (RoleSequenceID)
		REFERENCES RoleSequence(RoleSequenceID)
)
GO

CREATE TABLE RingConstraint (
	RingConstraintID	int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	Enforcement		char(1) default 'M',
	RingType		int NOT NULL,
	FromRoleID		int NOT NULL,
	ToRoleID		int NOT NULL,
	CONSTRAINT PK_RingConstraint
		PRIMARY KEY CLUSTERED (RingConstraintID),
	CONSTRAINT FK_RingConstraint_FromRole
		FOREIGN KEY (FromRoleID)
		REFERENCES Role(RoleID),
	CONSTRAINT FK_RingConstraint_ToRole
		FOREIGN KEY (ToRoleID)
		REFERENCES Role(RoleID)
)
GO

/*
 * Sample Populations
 */
CREATE TABLE Population (
	PopulationID	int IDENTITY NOT NULL,
	SchemaID	int NOT NULL ,
	Name		nvarchar (64) NOT NULL,
	CONSTRAINT PK_Population
		PRIMARY KEY CLUSTERED (PopulationID),
	CONSTRAINT UQ_Population
		UNIQUE (Name),
	CONSTRAINT FK_Population_Schema
		FOREIGN KEY (SchemaID)
		REFERENCES [Schema](SchemaID)
)
GO

CREATE TABLE Instance (
	InstanceID		int IDENTITY NOT NULL,
	PopulationID		int NOT NULL,
	ObjectTypeID		int NOT NULL,
	[Value]			nvarchar (256) NULL,	-- Only if ObjectType has DataType
	CONSTRAINT PK_Instance
		PRIMARY KEY CLUSTERED (InstanceID),
	CONSTRAINT FK_Instance_ObjectType
		FOREIGN KEY (ObjectTypeID)
		REFERENCES ObjectType(ObjectTypeID),
	CONSTRAINT FK_Instance_Population
		FOREIGN KEY (PopulationID)
		REFERENCES Population (PopulationID)
)
GO

CREATE TABLE Fact (
	FactID			int IDENTITY NOT NULL,
	PopulationID		int NOT NULL,
	FactTypeID		int NOT NULL,
	CONSTRAINT PK_Fact
		PRIMARY KEY CLUSTERED (FactID),
	CONSTRAINT FK_Fact_Population
		FOREIGN KEY (PopulationID)
		REFERENCES Population (PopulationID),
	CONSTRAINT FK_Fact_FactType
		FOREIGN KEY (FactTypeID)
		REFERENCES FactType(FactTypeID)
)
GO

CREATE TABLE FactRole (
	FactID			int NOT NULL,
	RoleID			int NOT NULL,
	PopulationID		int NOT NULL,
	InstanceID		int NOT NULL,
	CONSTRAINT PK_FactRole
		PRIMARY KEY CLUSTERED (FactID, RoleID),
	CONSTRAINT FK_FactRole_Population
		FOREIGN KEY (PopulationID)
		REFERENCES Population (PopulationID),
	CONSTRAINT FK_FactRole_Fact
		FOREIGN KEY (FactID)
		REFERENCES Fact(FactID),
	CONSTRAINT FK_FactRole_Role
		FOREIGN KEY (RoleID)
		REFERENCES Role(RoleID),
	CONSTRAINT FK_FactRole_Instance
		FOREIGN KEY (InstanceID)
		REFERENCES Instance(InstanceID)
)
GO
