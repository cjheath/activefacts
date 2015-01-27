CREATE TABLE Person (
	-- maybe Person is an Australian and maybe Australian has TFN,
	AustralianTFN                           char(9) NULL,
	-- maybe Person is an Employee and Employee has Employee ID,
	EmployeeID                              int NULL,
	-- Person has Person Name,
	PersonName                              varchar NOT NULL,
	PRIMARY KEY(PersonName)
)
GO

CREATE VIEW dbo.AustralianInPerson_TFN (AustralianTFN) WITH SCHEMABINDING AS
	SELECT AustralianTFN FROM dbo.Person
	WHERE	AustralianTFN IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_AustralianInPersonByAustralianTFN ON dbo.AustralianInPerson_TFN(AustralianTFN)
GO

CREATE VIEW dbo.EmployeeInPerson_ID (EmployeeID) WITH SCHEMABINDING AS
	SELECT EmployeeID FROM dbo.Person
	WHERE	EmployeeID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PK_EmployeeInPerson ON dbo.EmployeeInPerson_ID(EmployeeID)
GO

