CREATE TABLE Entrant (
	CompetitorFamilyName	varchar NULL,
	TeamID	int NULL,
	EntrantID	int NOT NULL,
	UNIQUE(EntrantID)
)
GO

CREATE TABLE EntrantHasGivenName (
	EntrantID	int NOT NULL,
	GivenName	varchar NOT NULL,
	UNIQUE(EntrantID, GivenName)
)
GO

