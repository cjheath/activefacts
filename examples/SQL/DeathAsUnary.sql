CREATE TABLE Person (
	PersonName	varchar(40) NOT NULL,
	IsDead	bit NOT NULL,
	DeathCauseOfDeath	varchar NULL,
	UNIQUE(PersonName)
)
GO

