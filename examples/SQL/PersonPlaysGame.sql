CREATE TABLE Playing (
	-- Playing involves Game and Game has Game Code,
	GameCode                                char NOT NULL,
	-- Playing involves Person and Person has Person Name,
	PersonName                              varchar NOT NULL,
	PRIMARY KEY(PersonName, GameCode)
)
GO

