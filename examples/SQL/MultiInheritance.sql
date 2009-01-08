CREATE TABLE Person (
	-- Person has PersonName,
	PersonName                              varchar NOT NULL,
	-- maybe Australian is a subtype of Person and maybe Australian has TFN,
	AustralianTFN                           char(9) NULL,
	-- maybe Employee is a subtype of Person and Employee has EmployeeID,
	EmployeeID                              int NULL,
	PRIMARY KEY(PersonName)
)
GO

