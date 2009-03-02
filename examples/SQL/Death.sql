CREATE TABLE Person (
	-- Death is where Person is dead and maybe Death was due to CauseOfDeath,
	DeathCauseOfDeath                       varchar NULL,
	-- Person has PersonName,
	PersonName                              varchar(40) NOT NULL,
	PRIMARY KEY(PersonName)
)
GO

