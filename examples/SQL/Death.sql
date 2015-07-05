CREATE TABLE Person (
	-- Person is involved in Death and maybe Death was due to Cause Of Death,
	DeathCauseOfDeath                       varchar NULL,
	-- Person is involved in Death,
	IsDead                                  bit NULL,
	-- Person has Person Name,
	PersonName                              varchar(40) NOT NULL,
	PRIMARY KEY(PersonName)
)
GO

