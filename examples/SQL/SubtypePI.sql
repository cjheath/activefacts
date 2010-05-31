CREATE TABLE Entrant (
	-- maybe Competitor is a kind of Entrant and Competitor has Family Name,
	CompetitorFamilyName                    varchar NULL,
	-- Entrant has Entrant ID,
	EntrantID                               int IDENTITY NOT NULL,
	-- maybe Team is a kind of Entrant and Team has Team ID,
	TeamID                                  int NULL,
	PRIMARY KEY(EntrantID)
)
GO

CREATE VIEW dbo.CompetitorInEntrant_FamilyName (CompetitorFamilyName) WITH SCHEMABINDING AS
	SELECT CompetitorFamilyName FROM dbo.Entrant
	WHERE	CompetitorFamilyName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX FamilyAndGivenNamesAreUnique ON dbo.CompetitorInEntrant_FamilyName(CompetitorFamilyName)
GO

CREATE VIEW dbo.TeamInEntrant_ID (TeamID) WITH SCHEMABINDING AS
	SELECT TeamID FROM dbo.Entrant
	WHERE	TeamID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PK_TeamInEntrant ON dbo.TeamInEntrant_ID(TeamID)
GO

CREATE TABLE EntrantGivenName (
	-- Entrant Given Name is where Entrant has Given Name and Entrant has Entrant ID,
	EntrantID                               int NOT NULL,
	-- Entrant Given Name is where Entrant has Given Name,
	GivenName                               varchar NOT NULL,
	PRIMARY KEY(EntrantID, GivenName),
	UNIQUE(GivenName),
	FOREIGN KEY (EntrantID) REFERENCES Entrant (EntrantID)
)
GO

