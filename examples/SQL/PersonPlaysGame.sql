CREATE TABLE Playing (
	-- Playing is where Person plays Game and Game has GameCode,
	GameCode                                char NOT NULL,
	-- Playing is where Person plays Game and Person has PersonName,
	PersonName                              varchar NOT NULL,
	PRIMARY KEY(PersonName, GameCode)
)
GO

