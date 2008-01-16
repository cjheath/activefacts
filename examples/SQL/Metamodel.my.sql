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
;

CREATE TABLE BaseUnit (
	BaseForUnitID		int NOT NULL,
	BaseUnitID		int NOT NULL,
	Exponent		int NOT NULL DEFAULT 1
)
;

CREATE TABLE Concept (
	ConceptID		int NOT NULL,
	Name			nvarchar (64) NOT NULL,
	VocabularyID		int NOT NULL,
	NestsFactTypeID		int NULL,
	IsIndependent		bit NOT NULL DEFAULT 0,
	IsPersonal		bit NOT NULL DEFAULT 0,
	CONSTRAINT PK_Concept PRIMARY KEY (
			ConceptID
		)
)
;

CREATE TABLE Fact (
	FactID			int NOT NULL,
	PopulationID		int NOT NULL,
	FactTypeID		int NOT NULL,
	CONSTRAINT PK_Fact PRIMARY KEY (
			FactID
		)
)
;

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
;

CREATE TABLE FactType (
	FactTypeID		int NOT NULL,
	Name			nvarchar (64) NULL,
	CONSTRAINT PK_FactType PRIMARY KEY (
			FactTypeID
		)
)
;

CREATE TABLE Import (
	VocabularyID		int NOT NULL,
	ImportedID		int NOT NULL,
	CONSTRAINT PK_Import PRIMARY KEY (
			VocabularyID,
			ImportedID
		)
)
;

CREATE TABLE Instance (
	InstanceID		int NOT NULL,
	PopulationID		int NOT NULL,
	ConceptID		int NOT NULL,
	Value			nvarchar (256) NULL,
	CONSTRAINT PK_Instance PRIMARY KEY (
			InstanceID
		)
)
;

CREATE TABLE Population (
	PopulationID		int NOT NULL,
	VocabularyID		int NOT NULL,
	Name			nvarchar (64) NOT NULL,
	CONSTRAINT PK_Population PRIMARY KEY (
			PopulationID
		),
	CONSTRAINT UQ_Population UNIQUE NONCLUSTERED (
			Name
		)
)
;

CREATE TABLE PresenceConstraint (
	PresenceConstraintID	int NOT NULL,
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
;

CREATE TABLE Reading (
	ReadingID		int NOT NULL,
	FactTypeID		int NOT NULL,
	RoleSequenceID		int NOT NULL,
	Text			nvarchar (256) NOT NULL,
	CONSTRAINT PK_Reading PRIMARY KEY (
			ReadingID
		)
)
;

CREATE TABLE RingConstraint (
	RingConstraintID	int NOT NULL,
	Name			nvarchar (64) NOT NULL,
	Enforcement		char (1) NULL DEFAULT 'M',
	RingType		int NOT NULL,
	RoleID			int NOT NULL,
	OtherRoleID		int NOT NULL,
	CONSTRAINT PK_RingConstraint PRIMARY KEY (
			RingConstraintID
		)
)
;

CREATE TABLE Role (
	RoleID			int NOT NULL,
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
;

CREATE TABLE RoleSequence (
	RoleSequenceID		int NOT NULL,
	CONSTRAINT PK_RoleSequence PRIMARY KEY (
			RoleSequenceID
		)
)
;

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
;

CREATE TABLE SetConstraint (
	SetConstraintID		int NOT NULL,
	SetConstraintTypeID	int NOT NULL DEFAULT 1,
	Name			nvarchar (64) NOT NULL,
	Enforcement		char (1) NULL DEFAULT 'M',
	CONSTRAINT PK_SetConstraint PRIMARY KEY (
		SetConstraintID
	)
)
;

CREATE TABLE SetConstraintSequence (
	SetConstraintID		int NOT NULL,
	RoleSequenceID		int NOT NULL,
	CONSTRAINT PK_SetConstraintSequence PRIMARY KEY (
			SetConstraintID,
			RoleSequenceID
		)
)
;

CREATE TABLE SetConstraintType (
	SetConstraintTypeID	int NOT NULL,
	SetConstraintTypeName	char (10) NOT NULL,
	CONSTRAINT PK_SetConstraintType PRIMARY KEY (
			SetConstraintTypeID
		)
)
;

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
;

CREATE TABLE SubsetConstraint (
	SubsetConstraintId	int NOT NULL,
	Name			nvarchar (64) NOT NULL,
	Enforcement		char NOT NULL DEFAULT 'M',
	SupersetSequenceID	int NOT NULL,
	SubsetSequenceId	int NOT NULL,
	CONSTRAINT PK_SubsetConstraint PRIMARY KEY (
			SubsetConstraintId
		)
)
;

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
;

CREATE TABLE ValueRange (
	ValueRangeID		int NOT NULL,
	ValueRestrictionID	int NOT NULL,
	MinimumValue		nvarchar (256) NULL,
	MaximumValue		nvarchar (256) NULL,
	IncludesMinimum		bit NOT NULL DEFAULT 1,
	IncludesMaximum		bit NOT NULL DEFAULT 1,
	CONSTRAINT PK_ValueRange PRIMARY KEY (
			ValueRangeID
		)
)
;

CREATE TABLE ValueRestriction (
	ValueRestrictionID	int NOT NULL,
	CONSTRAINT PK_ValueRestriction PRIMARY KEY (
			ValueRestrictionID
		)
)
;

CREATE TABLE ValueType (
	ConceptID		int NOT NULL,
	SuperTypeID		int NULL,
	Length			int NULL,
	Scale			int NULL,
	ValueRestrictionID	int NULL,
	UnitID			int NULL,
	CONSTRAINT PK_ValueType PRIMARY KEY (
			ConceptID
		)
)
;

CREATE TABLE Vocabulary (
	VocabularyID		int NOT NULL,
	Name			nvarchar (64) NOT NULL,
	PartOfVocabularyID	int NULL,
	CONSTRAINT PK_Vocabulary PRIMARY KEY (
			VocabularyID
		),
	CONSTRAINT UQ_Vocabulary UNIQUE NONCLUSTERED (
			Name
		)
)
;

ALTER TABLE Alias ADD
	CONSTRAINT FK_Alias_Vocabulary
		FOREIGN KEY (VocabularyID)
		REFERENCES Vocabulary (VocabularyID)
;
ALTER TABLE Alias ADD
	CONSTRAINT FK_Alias_Imported
		FOREIGN KEY (ImportedID)
		REFERENCES Vocabulary (VocabularyID)
;

ALTER TABLE BaseUnit ADD
	CONSTRAINT FK_BaseUnit_ForUnit
		FOREIGN KEY (BaseForUnitID)
		REFERENCES Unit (UnitID)
;
ALTER TABLE BaseUnit ADD
	CONSTRAINT FK_BaseUnit_Unit
		FOREIGN KEY (BaseUnitID)
		REFERENCES Unit (UnitID)
;

ALTER TABLE Concept ADD
	CONSTRAINT FK_Concept_FactType
		FOREIGN KEY (NestsFactTypeID)
		REFERENCES FactType (FactTypeID)
;
ALTER TABLE Concept ADD
	CONSTRAINT FK_Concept_Vocabulary
		FOREIGN KEY (VocabularyID)
		REFERENCES Vocabulary (VocabularyID)
;

ALTER TABLE Fact ADD
	CONSTRAINT FK_Fact_FactType
		FOREIGN KEY (FactTypeID)
		REFERENCES FactType (FactTypeID)
;
ALTER TABLE Fact ADD
	CONSTRAINT FK_Fact_Population
		FOREIGN KEY (PopulationID)
		REFERENCES Population (PopulationID)
;

ALTER TABLE RoleValue ADD
	CONSTRAINT FK_RoleValue_Fact
		FOREIGN KEY (FactID)
		REFERENCES Fact (FactID)
;
ALTER TABLE RoleValue ADD
	CONSTRAINT FK_RoleValue_Instance
		FOREIGN KEY (InstanceID)
		REFERENCES Instance (InstanceID)
;
ALTER TABLE RoleValue ADD
	CONSTRAINT FK_RoleValue_Population
		FOREIGN KEY (PopulationID)
		REFERENCES Population (PopulationID)
;
ALTER TABLE RoleValue ADD
	CONSTRAINT FK_RoleValue_Role
		FOREIGN KEY (RoleID)
		REFERENCES Role (RoleID)
;

ALTER TABLE Import ADD
	CONSTRAINT FK_Import_Vocabulary
		FOREIGN KEY (VocabularyID)
		REFERENCES Vocabulary (VocabularyID)
;
ALTER TABLE Import ADD
	CONSTRAINT FK_Import_Imported
		FOREIGN KEY (ImportedID)
		REFERENCES Vocabulary (VocabularyID)
;

ALTER TABLE Instance ADD
	CONSTRAINT FK_Instance_Concept
		FOREIGN KEY (ConceptID)
		REFERENCES Concept (ConceptID)
;
ALTER TABLE Instance ADD
	CONSTRAINT FK_Instance_Population
		FOREIGN KEY (PopulationID)
		REFERENCES Population (PopulationID)
;

ALTER TABLE Population ADD
	CONSTRAINT FK_Population_Vocabulary
		FOREIGN KEY (VocabularyID)
		REFERENCES Vocabulary (VocabularyID)
;

ALTER TABLE PresenceConstraint ADD
	CONSTRAINT FK_PresenceConstraint_RoleSequence
		FOREIGN KEY (RoleSequenceID)
		REFERENCES RoleSequence (RoleSequenceID)
;

ALTER TABLE Reading ADD
	CONSTRAINT FK_Reading_FactType
		FOREIGN KEY (FactTypeID)
		REFERENCES FactType (FactTypeID)
;
ALTER TABLE Reading ADD
	CONSTRAINT FK_Reading_RoleSequence
		FOREIGN KEY (RoleSequenceID)
		REFERENCES RoleSequence (RoleSequenceID)
;

ALTER TABLE RingConstraint ADD
	CONSTRAINT FK_RingConstraint_Role
		FOREIGN KEY (RoleID)
		REFERENCES Role (RoleID)
;
ALTER TABLE RingConstraint ADD
	CONSTRAINT FK_RingConstraint_OtherRole
		FOREIGN KEY (OtherRoleID)
		REFERENCES Role (RoleID)
;

ALTER TABLE Role ADD
	CONSTRAINT FK_Role_FactType
		FOREIGN KEY (FactTypeID)
		REFERENCES FactType (FactTypeID)
;
ALTER TABLE Role ADD
	CONSTRAINT FK_Role_Concept
		FOREIGN KEY (ConceptID)
		REFERENCES Concept (ConceptID)
;
ALTER TABLE Role ADD
	CONSTRAINT FK_Role_ValueRestriction
		FOREIGN KEY (RoleValueRestrictionID)
		REFERENCES ValueRestriction (ValueRestrictionID)
;

ALTER TABLE RoleSequenceRole ADD
	CONSTRAINT FK_RoleSequenceRole_Role
		FOREIGN KEY (RoleID)
		REFERENCES Role (RoleID)
;
ALTER TABLE RoleSequenceRole ADD
	CONSTRAINT FK_RoleSequenceRole_RoleSequence
		FOREIGN KEY (RoleSequenceId)
		REFERENCES RoleSequence (RoleSequenceID)
;

ALTER TABLE SetConstraint ADD
	CONSTRAINT FK_SetConstraint_SetConstraintType
		FOREIGN KEY (SetConstraintTypeID)
		REFERENCES SetConstraintType (SetConstraintTypeID)
;

ALTER TABLE SetConstraintSequence ADD
	CONSTRAINT FK_Sequence_SetConstraint
		FOREIGN KEY (SetConstraintID)
		REFERENCES SetConstraint (SetConstraintID)
;
ALTER TABLE SetConstraintSequence ADD
	CONSTRAINT FK_SetConstraintSequence_RoleSequence
		FOREIGN KEY (RoleSequenceID)
		REFERENCES RoleSequence (RoleSequenceID)
;

ALTER TABLE SubType ADD
	CONSTRAINT FK_SubType_FactType
		FOREIGN KEY (SubTypeFactTypeID)
		REFERENCES FactType (FactTypeID)
;
ALTER TABLE SubType ADD
	CONSTRAINT FK_SuperType_Concept
		FOREIGN KEY (SuperTypeID)
		REFERENCES Concept (ConceptID)
;
ALTER TABLE SubType ADD
	CONSTRAINT FK_SubType_Concept
		FOREIGN KEY (SubTypeID)
		REFERENCES Concept (ConceptID)
;

ALTER TABLE SubsetConstraint ADD
	CONSTRAINT FK_SubsetConstraint_RoleSequence
		FOREIGN KEY (SubsetConstraintId)
		REFERENCES RoleSequence (RoleSequenceID)
;
ALTER TABLE SubsetConstraint ADD
	CONSTRAINT FK_SupersetConstraint_RoleSequence
		FOREIGN KEY (SupersetSequenceID)
		REFERENCES RoleSequence (RoleSequenceID)
;

ALTER TABLE ValueRange ADD
	CONSTRAINT FK_ValueRange_ValueRestriction
		FOREIGN KEY (ValueRestrictionID)
		REFERENCES ValueRestriction (ValueRestrictionID)
;

ALTER TABLE ValueType ADD
	CONSTRAINT FK_ValueType_Concept
		FOREIGN KEY (ConceptID)
		REFERENCES Concept (ConceptID)
;
ALTER TABLE ValueType ADD
	CONSTRAINT FK_ValueType_Unit
		FOREIGN KEY (UnitID)
		REFERENCES Unit (UnitID)
;
ALTER TABLE ValueType ADD
	CONSTRAINT FK_ValueType_ValueRestriction
		FOREIGN KEY (ValueRestrictionID)
		REFERENCES ValueRestriction (ValueRestrictionID)
;
ALTER TABLE ValueType ADD
	CONSTRAINT FK_ValueType_ValueType
		FOREIGN KEY (SuperTypeID)
		REFERENCES ValueType (ConceptID)
;

ALTER TABLE Vocabulary ADD
	CONSTRAINT FK_Vocabulary_PartOfVocabulary
		FOREIGN KEY (PartOfVocabularyID)
		REFERENCES Vocabulary (VocabularyID)
;

