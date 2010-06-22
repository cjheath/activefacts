CREATE TABLE Moon (
	-- Moon has Moon Name,
	MoonName                                varchar NOT NULL,
	-- Orbit is where Moon is in orbit and maybe Orbit has a synodic period of Nr Days and Nr Days has Nr Days Nr,
	OrbitNrDaysNr                           int NULL,
	-- Orbit is where Moon is in orbit and Orbit is around Planet and Planet has Planet Name,
	OrbitPlanetName                         varchar NOT NULL,
	PRIMARY KEY(MoonName)
)
GO

