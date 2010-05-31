CREATE TABLE Playing (
	-- Playing is where Person plays Game and Game has Game Code,
	GameCode                                char NOT NULL,
	-- Playing is where Person plays Game and Person has Person Name,
	PersonName                              varchar NOT NULL,
	PRIMARY KEY(PersonName, GameCode)
)
GO

