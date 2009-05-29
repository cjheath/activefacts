CREATE TABLE Address (
	-- Address has AddressId,
	AddressId                               int IDENTITY NOT NULL,
	-- maybe Address is in LegislativeDistrict and LegislativeDistrict has DistrictNumber,
	LegislativeDistrictNumber               int NULL,
	-- maybe Address is in LegislativeDistrict and LegislativeDistrict is for StateOrProvince and StateOrProvince has StateOrProvinceId,
	LegislativeDistrictStateOrProvinceId    int NULL,
	-- maybe Address is assigned PostalCode,
	PostalCode                              int NULL,
	-- maybe Address is in StateOrProvince and StateOrProvince has StateOrProvinceId,
	StateOrProvinceId                       int NULL,
	PRIMARY KEY(AddressId)
)
GO

CREATE TABLE Politician (
	-- maybe Politician represents LegislativeDistrict and LegislativeDistrict has DistrictNumber,
	LegislativeDistrictNumber               int NULL,
	-- maybe Politician represents LegislativeDistrict and LegislativeDistrict is for StateOrProvince and StateOrProvince has StateOrProvinceId,
	LegislativeDistrictStateOrProvinceId    int NULL,
	-- Politician has PoliticianId,
	PoliticianId                            int IDENTITY NOT NULL,
	PRIMARY KEY(PoliticianId)
)
GO

CREATE VIEW dbo.Politician_LegislativeDistrictStateOrProvinceIdLegislativeDistrictNumber (LegislativeDistrictStateOrProvinceId, LegislativeDistrictNumber) WITH SCHEMABINDING AS
	SELECT LegislativeDistrictStateOrProvinceId, LegislativeDistrictNumber FROM dbo.Politician
	WHERE	LegislativeDistrictStateOrProvinceId IS NOT NULL
	  AND	LegislativeDistrictNumber IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_PoliticianByLegislativeDistrictStateOrProvinceIdLegislativeDistrictNumber ON dbo.Politician_LegislativeDistrictStateOrProvinceIdLegislativeDistrictNumber(LegislativeDistrictStateOrProvinceId, LegislativeDistrictNumber)
GO

CREATE TABLE StateOrProvince (
	-- StateOrProvince has StateOrProvinceId,
	StateOrProvinceId                       int IDENTITY NOT NULL,
	PRIMARY KEY(StateOrProvinceId)
)
GO

ALTER TABLE Address
	ADD FOREIGN KEY (StateOrProvinceId) REFERENCES StateOrProvince (StateOrProvinceId)
GO

