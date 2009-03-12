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

CREATE TABLE LegislativeDistrict (
	-- LegislativeDistrict has DistrictNumber,
	DistrictNumber                          int NOT NULL,
	-- Politician represents LegislativeDistrict and Politician has PoliticianId,
	PoliticianId                            int NOT NULL,
	-- LegislativeDistrict is for StateOrProvince and StateOrProvince has StateOrProvinceId,
	StateOrProvinceId                       int NOT NULL,
	PRIMARY KEY(DistrictNumber, StateOrProvinceId),
	UNIQUE(PoliticianId)
)
GO

CREATE TABLE StateOrProvince (
	-- StateOrProvince has StateOrProvinceId,
	StateOrProvinceId                       int IDENTITY NOT NULL,
	PRIMARY KEY(StateOrProvinceId)
)
GO

ALTER TABLE Address
	ADD FOREIGN KEY (LegislativeDistrictNumber, LegislativeDistrictStateOrProvinceId) REFERENCES LegislativeDistrict (DistrictNumber, StateOrProvinceId)
GO

ALTER TABLE Address
	ADD FOREIGN KEY (StateOrProvinceId) REFERENCES StateOrProvince (StateOrProvinceId)
GO

ALTER TABLE LegislativeDistrict
	ADD FOREIGN KEY (StateOrProvinceId) REFERENCES StateOrProvince (StateOrProvinceId)
GO

