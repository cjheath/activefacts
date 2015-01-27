CREATE TABLE Playing (
	-- Playing (in which Person plays Game) and Game has Game Code,
	GameCode                                char NOT NULL,
	-- Playing (in which Person plays Game) and Person has Person Name,
	PersonName                              varchar NOT NULL,
	PRIMARY KEY(PersonName, GameCode)
)
GO

