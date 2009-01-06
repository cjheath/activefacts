CREATE TABLE Playing (
	PersonName                              VariableLengthText NOT NULL,
	GameCode                                FixedLengthText NOT NULL,
	PRIMARY KEY(PersonName, GameCode)
)
GO

