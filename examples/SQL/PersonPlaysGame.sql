CREATE TABLE Playing (
	GameCode	FixedLengthText NOT NULL,
	PersonName	varchar NOT NULL,
	UNIQUE(PersonName, GameCode)
)
GO

