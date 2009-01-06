CREATE TABLE Person (
	PersonName                              VariableLengthText(40) NOT NULL,
	PersonCauseOfDeath                      VariableLengthText NULL,
	PRIMARY KEY(PersonName)
)
GO

