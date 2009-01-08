CREATE TABLE Entrant (
	-- Entrant has EntrantID,
	EntrantID                               int IDENTITY NOT NULL,
	-- maybe Competitor is a subtype of Entrant and Competitor has FamilyName,
	CompetitorFamilyName                    varchar NULL,
	-- maybe Team is a subtype of Entrant and Team has TeamID,
	TeamID                                  int NULL,
	PRIMARY KEY(EntrantID)
)
GO

CREATE TABLE EntrantHasGivenName (
	-- EntrantHasGivenName is where Entrant has GivenName and Entrant has EntrantID,
	EntrantID                               int NOT NULL,
	-- EntrantHasGivenName is where Entrant has GivenName,
	GivenName                               varchar NOT NULL,
	PRIMARY KEY(EntrantID, GivenName),
	FOREIGN KEY (EntrantID) REFERENCES Entrant (EntrantID)
)
GO

