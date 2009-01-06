CREATE TABLE Entrant (
	EntrantID                               AutoCounter NOT NULL,
	CompetitorFamilyName                    VariableLengthText NULL,
	TeamID                                  AutoCounter NULL,
	PRIMARY KEY(EntrantID)
)
GO

CREATE TABLE EntrantHasGivenName (
	EntrantID                               AutoCounter NOT NULL,
	GivenName                               VariableLengthText NOT NULL,
	PRIMARY KEY(EntrantID, GivenName)
)
GO

