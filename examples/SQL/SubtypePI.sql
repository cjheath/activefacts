CREATE TABLE Entrant (
	EntrantID	int NOT NULL,
	CompetitorFamilyName	varchar NULL,
	TeamID	int NULL,
	PRIMARY KEY(EntrantID)
)
GO

CREATE TABLE EntrantHasGivenName (
	EntrantID	int NOT NULL,
	GivenName	varchar NOT NULL,
	PRIMARY KEY(EntrantID, GivenName),
	FOREIGN KEY(EntrantID)
	REFERENCES Entrant(EntrantID)
)
GO

