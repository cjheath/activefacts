CREATE TABLE Person (
	-- Person has PersonName,
	PersonName                              varchar NOT NULL,
	-- maybe Australian is a subtype of Person and maybe Australian has TFN,
	AustralianTFN                           char(9) NULL,
	-- maybe Employee is a subtype of Person and Employee has EmployeeID,
	EmployeeID                              int NULL,
	PRIMARY KEY(PersonName),
	FOREIGN KEY () REFERENCES Person ()
)
GO

CREATE VIEW dbo.EmployeeInPerson_ID (EmployeeID) WITH SCHEMABINDING AS
	SELECT EmployeeID FROM dbo.Person
	WHERE	EmployeeID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PK_EmployeeInPerson ON dbo.EmployeeInPerson_ID(EmployeeID)
GO

CREATE VIEW dbo.AustralianInPerson_TFN (AustralianTFN) WITH SCHEMABINDING AS
	SELECT AustralianTFN FROM dbo.Person
	WHERE	AustralianTFN IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_AustralianInPersonByAustralianTFN ON dbo.AustralianInPerson_TFN(AustralianTFN)
GO

