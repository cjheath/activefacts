CREATE TABLE Address (
	-- Address has Address Id,
	AddressId                               int IDENTITY NOT NULL,
	-- maybe Address is in Legislative District and Legislative District has District Number,
	LegislativeDistrictNumber               int NULL,
	-- maybe Address is in Legislative District and Legislative District is for State Or Province and State Or Province has State Or Province Id,
	LegislativeDistrictStateOrProvinceId    int NULL,
	-- maybe Address is assigned Postal Code,
	PostalCode                              int NULL,
	-- maybe Address is in State Or Province and State Or Province has State Or Province Id,
	StateOrProvinceId                       int NULL,
	PRIMARY KEY(AddressId)
)
GO

CREATE TABLE Politician (
	-- maybe Politician represents Legislative District and Legislative District has District Number,
	LegislativeDistrictNumber               int NULL,
	-- maybe Politician represents Legislative District and Legislative District is for State Or Province and State Or Province has State Or Province Id,
	LegislativeDistrictStateOrProvinceId    int NULL,
	-- Politician has Politician Id,
	PoliticianId                            int IDENTITY NOT NULL,
	PRIMARY KEY(PoliticianId)
)
GO

CREATE VIEW dbo.Politician_LegislativeDistrictNumberLegislativeDistrictStateOrProvinceId (LegislativeDistrictNumber, LegislativeDistrictStateOrProvinceId) WITH SCHEMABINDING AS
	SELECT LegislativeDistrictNumber, LegislativeDistrictStateOrProvinceId FROM dbo.Politician
	WHERE	LegislativeDistrictNumber IS NOT NULL
	  AND	LegislativeDistrictStateOrProvinceId IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_PoliticianByLegislativeDistrictNumberLegislativeDistrictStateOrProvinceId ON dbo.Politician_LegislativeDistrictNumberLegislativeDistrictStateOrProvinceId(LegislativeDistrictNumber, LegislativeDistrictStateOrProvinceId)
GO

CREATE TABLE StateOrProvince (
	-- State Or Province has State Or Province Id,
	StateOrProvinceId                       int IDENTITY NOT NULL,
	PRIMARY KEY(StateOrProvinceId)
)
GO

ALTER TABLE Address
	ADD FOREIGN KEY (LegislativeDistrictStateOrProvinceId) REFERENCES StateOrProvince (StateOrProvinceId)
GO

ALTER TABLE Address
	ADD FOREIGN KEY (StateOrProvinceId) REFERENCES StateOrProvince (StateOrProvinceId)
GO

ALTER TABLE Politician
	ADD FOREIGN KEY (LegislativeDistrictStateOrProvinceId) REFERENCES StateOrProvince (StateOrProvinceId)
GO

