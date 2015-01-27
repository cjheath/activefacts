CREATE TABLE Person (
	-- Death (in which Person is dead) and maybe Death was due to Cause Of Death,
	DeathCauseOfDeath                       varchar NULL,
	-- Person is dead,
	IsDead                                  bit NULL,
	-- Person has Person Name,
	PersonName                              varchar(40) NOT NULL,
	PRIMARY KEY(PersonName)
)
GO

