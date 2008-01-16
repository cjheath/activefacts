CREATE TABLE Alias (
	VocabularyID		int NOT NULL,
	ImportedId		int NOT NULL,
	AliasName		nvarchar (64) NOT NULL,
	FromName		nvarchar (64) NOT NULL,
	CONSTRAINT PK_Alias PRIMARY KEY (
			VocabularyID,
			ImportedId,
			AliasName
		)
)
GO

CREATE TABLE BaseUnit (
	BaseForUnitID		int NOT NULL,
	BaseUnitID		int NOT NULL,
	Exponent		int NOT NULL DEFAULT 1
)
GO

CREATE TABLE Concept (
	ConceptID		int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	VocabularyID		int NOT NULL,
	NestsFactTypeID		int NULL,
	IsIndependent		bit NOT NULL DEFAULT 0,
	IsPersonal		bit NOT NULL DEFAULT 0,
	CONSTRAINT PK_Concept PRIMARY KEY (
			ConceptID
		)
)
GO

CREATE TABLE Fact (
	FactID			int IDENTITY NOT NULL,
	PopulationID		int NOT NULL,
	FactTypeID		int NOT NULL,
	CONSTRAINT PK_Fact PRIMARY KEY (
			FactID
		)
)
GO

CREATE TABLE RoleValue (
	FactID			int NOT NULL,
	RoleID			int NOT NULL,
	PopulationID		int NOT NULL,
	InstanceID		int NOT NULL,
	CONSTRAINT PK_RoleValue PRIMARY KEY (
			FactID,
			RoleID
		)
)
GO

CREATE TABLE FactType (
	FactTypeID		int IDENTITY NOT NULL,
	Name			nvarchar (64) NULL,
	CONSTRAINT PK_FactType PRIMARY KEY (
			FactTypeID
		)
)
GO

CREATE TABLE Import (
	VocabularyID		int NOT NULL,
	ImportedID		int NOT NULL,
	CONSTRAINT PK_Import PRIMARY KEY (
			VocabularyID,
			ImportedID
		)
)
GO

CREATE TABLE Instance (
	InstanceID		int IDENTITY NOT NULL,
	PopulationID		int NOT NULL,
	ConceptID		int NOT NULL,
	Value			nvarchar (256) NULL,
	CONSTRAINT PK_Instance PRIMARY KEY (
			InstanceID
		)
)
GO

CREATE TABLE Population (
	PopulationID		int IDENTITY NOT NULL,
	VocabularyID		int NOT NULL,
	Name			nvarchar (64) NOT NULL,
	CONSTRAINT PK_Population PRIMARY KEY (
			PopulationID
		),
	CONSTRAINT UQ_Population UNIQUE NONCLUSTERED (
			Name
		)
)
GO

CREATE TABLE PresenceConstraint (
	PresenceConstraintID	int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	Enforcement		char (1) NULL DEFAULT 'M',
	RoleSequenceID		int NOT NULL,
	MinOccurs		int NULL,
	MaxOccurs		int NULL,
	IsMandatory		bit NOT NULL,
	IsPreferredIdentifier	bit NOT NULL,
	CONSTRAINT PK_PresenceConstraint PRIMARY KEY (
			PresenceConstraintID
		)
)
GO

CREATE TABLE Reading (
	ReadingID		int IDENTITY NOT NULL,
	FactTypeID		int NOT NULL,
	RoleSequenceID		int NOT NULL,
	Text			nvarchar (256) NOT NULL,
	CONSTRAINT PK_Reading PRIMARY KEY (
			ReadingID
		)
)
GO

CREATE TABLE RingConstraint (
	RingConstraintID	int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	Enforcement		char (1) NULL DEFAULT 'M',
	RingType		int NOT NULL,
	RoleID			int NOT NULL,
	OtherRoleID		int NOT NULL,
	CONSTRAINT PK_RingConstraint PRIMARY KEY (
			RingConstraintID
		)
)
GO

CREATE TABLE Role (
	RoleID			int IDENTITY NOT NULL,
	RoleName		nvarchar (64) NOT NULL,
	FactTypeID		int NOT NULL,
	ConceptID		int NOT NULL,
	RoleValueRestrictionID	int NULL,
	CONSTRAINT PK_Role PRIMARY KEY (
			RoleID
		),
	CONSTRAINT UQ_Role UNIQUE NONCLUSTERED (
			FactTypeID,
			ConceptID
		)
)
GO

CREATE TABLE RoleSequence (
	RoleSequenceID		int IDENTITY NOT NULL,
	CONSTRAINT PK_RoleSequence PRIMARY KEY (
			RoleSequenceID
		)
)
GO

CREATE TABLE RoleSequenceRole (
	RoleSequenceId		int NOT NULL,
	RoleID			int NOT NULL,
	Ordinal			int NOT NULL,
	LeadingAdjective	nvarchar (64) NULL,
	TrailingAdjective	nvarchar (64) NULL,
	CONSTRAINT PK_RoleSequenceRole PRIMARY KEY (
			RoleSequenceId,
			RoleID
		),
	CONSTRAINT UQ_RoleSequenceRole UNIQUE (
			RoleSequenceId,
			Ordinal
		)
)
GO

CREATE TABLE SetConstraint (
	SetConstraintID		int IDENTITY NOT NULL,
	SetConstraintTypeID	int NOT NULL DEFAULT 1,
	Name			nvarchar (64) NOT NULL,
	Enforcement		char (1) NULL DEFAULT 'M',
	CONSTRAINT PK_SetConstraint PRIMARY KEY (
		SetConstraintID
	)
)
GO

CREATE TABLE SetConstraintSequence (
	SetConstraintID		int NOT NULL,
	RoleSequenceID		int NOT NULL
	CONSTRAINT PK_SetConstraintSequence PRIMARY KEY (
			SetConstraintID,
			RoleSequenceID
		)
)
GO

CREATE TABLE SetConstraintType (
	SetConstraintTypeID	int IDENTITY NOT NULL,
	SetConstraintTypeName	char (10) NOT NULL,
	CONSTRAINT PK_SetConstraintType PRIMARY KEY (
			SetConstraintTypeID
		)
)
GO

CREATE TABLE SubType (
	SubTypeID		int NOT NULL,
	SuperTypeID		int NOT NULL,
	SubTypeFactTypeID	int NOT NULL,
	IsPrimary		bit NOT NULL,
	CONSTRAINT PK_SubType PRIMARY KEY (
			SubTypeID,
			SuperTypeID
		)
)
GO

CREATE TABLE SubsetConstraint (
	SubsetConstraintId	int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	Enforcement		bit NOT NULL DEFAULT 'M',
	SupersetSequenceID	int NOT NULL,
	SubsetSequenceId	int NOT NULL
	CONSTRAINT PK_SubsetConstraint PRIMARY KEY (
			SubsetConstraintId
		)
)
GO

CREATE TABLE Unit (
	UnitID			int NOT NULL,
	UnitName		char (48) NULL,
	Numerator		decimal(18, 8) NULL,
	Denominator		int NOT NULL DEFAULT 1,
	IsPrecise		bit NOT NULL DEFAULT 1,
	CONSTRAINT PK_Unit PRIMARY KEY (
			UnitID
		)
)
GO

CREATE TABLE ValueRange (
	ValueRangeID		int IDENTITY NOT NULL,
	ValueRestrictionID	int NOT NULL,
	MinimumValue		nvarchar (256) NULL,
	MaximumValue		nvarchar (256) NULL,
	IncludesMinimum		bit NOT NULL DEFAULT 1,
	IncludesMaximum		bit NOT NULL DEFAULT 1,
	CONSTRAINT PK_ValueRange PRIMARY KEY (
			ValueRangeID
		)
)
GO

CREATE TABLE ValueRestriction (
	ValueRestrictionID	int IDENTITY NOT NULL,
	CONSTRAINT PK_ValueRestriction PRIMARY KEY (
			ValueRestrictionID
		)
)
GO

CREATE TABLE ValueType (
	ConceptID		int IDENTITY NOT NULL,
	SuperTypeID		int NULL,
	Length			int NULL,
	Scale			int NULL,
	ValueRestrictionID	int NULL,
	UnitID			int NULL,
	CONSTRAINT PK_ValueType PRIMARY KEY (
			ConceptID
		)
)
GO

CREATE TABLE Vocabulary (
	VocabularyID		int IDENTITY NOT NULL,
	Name			nvarchar (64) NOT NULL,
	PartOfVocabularyID	int NULL,
	CONSTRAINT PK_Vocabulary PRIMARY KEY (
			VocabularyID
		),
	CONSTRAINT UQ_Vocabulary UNIQUE NONCLUSTERED (
			Name
		)
)
GO

ALTER TABLE Alias ADD
	CONSTRAINT FK_Alias_Vocabulary
		FOREIGN KEY (VocabularyID)
		REFERENCES Vocabulary (VocabularyID),
	CONSTRAINT FK_Alias_Imported
		FOREIGN KEY (ImportedID)
		REFERENCES Vocabulary (VocabularyID)
GO

ALTER TABLE BaseUnit ADD
	CONSTRAINT FK_BaseUnit_ForUnit
		FOREIGN KEY (BaseForUnitID)
		REFERENCES Unit (UnitID),
	CONSTRAINT FK_BaseUnit_Unit
		FOREIGN KEY (BaseUnitID)
		REFERENCES Unit (UnitID)
GO

ALTER TABLE Concept ADD
	CONSTRAINT FK_Concept_FactType
		FOREIGN KEY (NestsFactTypeID)
		REFERENCES FactType (FactTypeID),
	CONSTRAINT FK_Concept_Vocabulary
		FOREIGN KEY (VocabularyID)
		REFERENCES Vocabulary (VocabularyID)
GO

ALTER TABLE Fact ADD
	CONSTRAINT FK_Fact_FactType
		FOREIGN KEY (FactTypeID)
		REFERENCES FactType (FactTypeID),
	CONSTRAINT FK_Fact_Population
		FOREIGN KEY (PopulationID)
		REFERENCES Population (PopulationID)
GO

ALTER TABLE RoleValue ADD
	CONSTRAINT FK_RoleValue_Fact
		FOREIGN KEY (FactID)
		REFERENCES Fact (FactID),
	CONSTRAINT FK_RoleValue_Instance
		FOREIGN KEY (InstanceID)
		REFERENCES Instance (InstanceID),
	CONSTRAINT FK_RoleValue_Population
		FOREIGN KEY (PopulationID)
		REFERENCES Population (PopulationID),
	CONSTRAINT FK_RoleValue_Role
		FOREIGN KEY (RoleID)
		REFERENCES Role (RoleID)
GO

ALTER TABLE Import ADD
	CONSTRAINT FK_Import_Vocabulary
		FOREIGN KEY (VocabularyID)
		REFERENCES Vocabulary (VocabularyID),
	CONSTRAINT FK_Import_Imported
		FOREIGN KEY (ImportedID)
		REFERENCES Vocabulary (VocabularyID)
GO

ALTER TABLE Instance ADD
	CONSTRAINT FK_Instance_Concept
		FOREIGN KEY (ConceptID)
		REFERENCES Concept (ConceptID),
	CONSTRAINT FK_Instance_Population
		FOREIGN KEY (PopulationID)
		REFERENCES Population (PopulationID)
GO

ALTER TABLE Population ADD
	CONSTRAINT FK_Population_Vocabulary
		FOREIGN KEY (VocabularyID)
		REFERENCES Vocabulary (VocabularyID)
GO

ALTER TABLE PresenceConstraint ADD
	CONSTRAINT FK_PresenceConstraint_RoleSequence
		FOREIGN KEY (RoleSequenceID)
		REFERENCES RoleSequence (RoleSequenceID)
GO

ALTER TABLE Reading ADD
	CONSTRAINT FK_Reading_FactType
		FOREIGN KEY (FactTypeID)
		REFERENCES FactType (FactTypeID),
	CONSTRAINT FK_Reading_RoleSequence
		FOREIGN KEY (RoleSequenceID)
		REFERENCES RoleSequence (RoleSequenceID)
GO

ALTER TABLE RingConstraint ADD
	CONSTRAINT FK_RingConstraint_Role
		FOREIGN KEY (RoleID)
		REFERENCES Role (RoleID),
	CONSTRAINT FK_RingConstraint_OtherRole
		FOREIGN KEY (OtherRoleID)
		REFERENCES Role (RoleID)
GO

ALTER TABLE Role ADD
	CONSTRAINT FK_Role_FactType
		FOREIGN KEY (FactTypeID)
		REFERENCES FactType (FactTypeID),
	CONSTRAINT FK_Role_Concept
		FOREIGN KEY (ConceptID)
		REFERENCES Concept (ConceptID),
	CONSTRAINT FK_Role_ValueRestriction
		FOREIGN KEY (RoleValueRestrictionID)
		REFERENCES ValueRestriction (ValueRestrictionID)
GO

ALTER TABLE RoleSequenceRole ADD
	CONSTRAINT FK_RoleSequenceRole_Role
		FOREIGN KEY (RoleID)
		REFERENCES Role (RoleID),
	CONSTRAINT FK_RoleSequenceRole_RoleSequence
		FOREIGN KEY (RoleSequenceId)
		REFERENCES RoleSequence (RoleSequenceID)
GO

ALTER TABLE SetConstraint ADD
	CONSTRAINT FK_SetConstraint_SetConstraintType
		FOREIGN KEY (SetConstraintTypeID)
		REFERENCES SetConstraintType (SetConstraintTypeID)
GO

ALTER TABLE SetConstraintSequence ADD
	CONSTRAINT FK_Sequence_SetConstraint
		FOREIGN KEY (SetConstraintID)
		REFERENCES SetConstraint (SetConstraintID),
	CONSTRAINT FK_SetConstraintSequence_RoleSequence
		FOREIGN KEY (RoleSequenceID)
		REFERENCES RoleSequence (RoleSequenceID)
GO

ALTER TABLE SubType ADD
	CONSTRAINT FK_SubType_FactType
		FOREIGN KEY (SubTypeFactTypeID)
		REFERENCES FactType (FactTypeID),
	CONSTRAINT FK_SuperType_Concept
		FOREIGN KEY (SuperTypeID)
		REFERENCES Concept (ConceptID),
	CONSTRAINT FK_SubType_Concept
		FOREIGN KEY (SubTypeID)
		REFERENCES Concept (ConceptID)
GO

ALTER TABLE SubsetConstraint ADD
	CONSTRAINT FK_SubsetConstraint_RoleSequence
		FOREIGN KEY (SubsetConstraintId)
		REFERENCES RoleSequence (RoleSequenceID),
	CONSTRAINT FK_SupersetConstraint_RoleSequence
		FOREIGN KEY (SupersetSequenceID)
		REFERENCES RoleSequence (RoleSequenceID)
GO

ALTER TABLE ValueRange ADD
	CONSTRAINT FK_ValueRange_ValueRestriction
		FOREIGN KEY (ValueRestrictionID)
		REFERENCES ValueRestriction (ValueRestrictionID)
GO

ALTER TABLE ValueType ADD
	CONSTRAINT FK_ValueType_Concept
		FOREIGN KEY (ConceptID)
		REFERENCES Concept (ConceptID),
	CONSTRAINT FK_ValueType_Unit
		FOREIGN KEY (UnitID)
		REFERENCES Unit (UnitID),
	CONSTRAINT FK_ValueType_ValueRestriction
		FOREIGN KEY (ValueRestrictionID)
		REFERENCES ValueRestriction (ValueRestrictionID),
	CONSTRAINT FK_ValueType_ValueType
		FOREIGN KEY (SuperTypeID)
		REFERENCES ValueType (ConceptID)
GO

ALTER TABLE Vocabulary ADD
	CONSTRAINT FK_Vocabulary_PartOfVocabulary
		FOREIGN KEY (PartOfVocabularyID)
		REFERENCES Vocabulary (VocabularyID)
GO

