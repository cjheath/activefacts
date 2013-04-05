CREATE TABLE Person (
	-- Death is where Person is dead and maybe Death was due to Cause Of Death,
	DeathCauseOfDeath                       varchar NULL,
	-- Death is where Person is dead,
	IsDead                                  bit NULL,
	-- Person has Person Name,
	PersonName                              varchar(40) NOT NULL,
	PRIMARY KEY(PersonName)
)
GO

