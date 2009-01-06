CREATE TABLE Person (
	PersonName                              VariableLengthText NOT NULL,
	AustralianTFN                           FixedLengthText(9) NULL,
	EmployeeID                              AutoCounter NULL,
	PRIMARY KEY(PersonName)
)
GO

