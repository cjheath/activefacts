CREATE TABLE Person (
	-- Person has PersonName,
	PersonName                              varchar(40) NOT NULL,
	-- Death is where Person is dead and maybe Death was due to CauseOfDeath,
	PersonCauseOfDeath                      varchar NULL,
	PRIMARY KEY(PersonName)
)
GO

