CREATE TABLE AstronomicalObject (
	-- AstronomicalObject has AstronomicalObject Code,
	AstronomicalObjectCode                  varchar(12) NOT NULL,
	-- Orbit is where AstronomicalObject is in orbit,
	IsInOrbit                               bit NULL,
	-- maybe AstronomicalObject has Mass,
	Mass                                    Real(32) NULL,
	-- maybe Moon is a kind of AstronomicalObject and Moon has Moon Name,
	MoonName                                varchar(256) NULL,
	-- Orbit is where AstronomicalObject is in orbit and Orbit is around AstronomicalObject and AstronomicalObject has AstronomicalObject Code,
	OrbitCenterAstronomicalObjectCode       varchar(12) NULL,
	-- Orbit is where AstronomicalObject is in orbit and maybe Orbit has a synodic period of Nr Days,
	OrbitNrDays                             Real(32) NULL,
	-- maybe Planet is a kind of AstronomicalObject and Planet has Planet Name,
	PlanetName                              varchar(256) NULL,
	PRIMARY KEY(AstronomicalObjectCode),
	FOREIGN KEY (OrbitCenterAstronomicalObjectCode) REFERENCES AstronomicalObject (AstronomicalObjectCode)
)
GO

CREATE VIEW dbo.MoonInAstronomicalObject_Name (MoonName) WITH SCHEMABINDING AS
	SELECT MoonName FROM dbo.AstronomicalObject
	WHERE	MoonName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PK_MoonInAstronomicalObject ON dbo.MoonInAstronomicalObject_Name(MoonName)
GO

CREATE VIEW dbo.PlanetInAstronomicalObject_Name (PlanetName) WITH SCHEMABINDING AS
	SELECT PlanetName FROM dbo.AstronomicalObject
	WHERE	PlanetName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PK_PlanetInAstronomicalObject ON dbo.PlanetInAstronomicalObject_Name(PlanetName)
GO

