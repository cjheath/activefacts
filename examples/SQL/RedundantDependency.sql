CREATE TABLE Address (
	-- Address has AddressId,
	AddressId                               AutoCounter IDENTITY NOT NULL,
	-- maybe Address is assigned PostalCode,
	PostalCode                              SignedInteger(32) NULL,
	-- maybe Address is in StateOrProvince and StateOrProvince has StateOrProvinceId,
	StateOrProvinceId                       AutoCounter NULL,
	-- maybe Address is in LegislativeDistrict and LegislativeDistrict has DistrictNumber,
	LegislativeDistrictDistrictNumber       SignedInteger(32) NULL,
	-- maybe Address is in LegislativeDistrict and LegislativeDistrict is for StateOrProvince and StateOrProvince has StateOrProvinceId,
	LegislativeDistrictStateOrProvinceId    AutoCounter NULL,
	PRIMARY KEY(AddressId)
)
GO

CREATE TABLE LegislativeDistrict (
	-- LegislativeDistrict is for StateOrProvince and StateOrProvince has StateOrProvinceId,
	StateOrProvinceId                       AutoCounter NOT NULL,
	-- LegislativeDistrict has DistrictNumber,
	DistrictNumber                          SignedInteger(32) NOT NULL,
	-- Politician represents LegislativeDistrict and Politician has PoliticianId,
	PoliticianId                            AutoCounter NOT NULL,
	PRIMARY KEY(DistrictNumber, StateOrProvinceId),
	UNIQUE(PoliticianId)
)
GO

CREATE TABLE StateOrProvince (
	-- StateOrProvince has StateOrProvinceId,
	StateOrProvinceId                       AutoCounter IDENTITY NOT NULL,
	PRIMARY KEY(StateOrProvinceId)
)
GO

ALTER TABLE Address
	ADD FOREIGN KEY (StateOrProvinceId) REFERENCES StateOrProvince (StateOrProvinceId)
GO

ALTER TABLE Address
	ADD FOREIGN KEY (LegislativeDistrictDistrictNumber, LegislativeDistrictStateOrProvinceId) REFERENCES LegislativeDistrict (DistrictNumber, StateOrProvinceId)
GO

ALTER TABLE LegislativeDistrict
	ADD FOREIGN KEY (StateOrProvinceId) REFERENCES StateOrProvince (StateOrProvinceId)
GO

