CREATE TABLE Playing (
	PersonName	varchar NOT NULL,
	GameCode	FixedLengthText NOT NULL,
	PRIMARY KEY(PersonName, GameCode)
)
GO

