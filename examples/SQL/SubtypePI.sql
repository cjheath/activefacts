CREATE TABLE Entrant (
	EntrantID	int NOT NULL,
	CompetitorFamilyName	varchar NULL,
	TeamID	int NULL,
	UNIQUE(EntrantID)
)
GO

CREATE TABLE EntrantHasGivenName (
	EntrantID	int NOT NULL,
	GivenName	varchar NOT NULL,
	UNIQUE(EntrantID, GivenName),
	FOREIGN KEY(EntrantID)
	REFERENCES Entrant(EntrantID)
)
GO

