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

CREATE TABLE LegislativeDistrict (
	-- Legislative District has District Number,
	DistrictNumber                          int NOT NULL,
	-- Politician represents Legislative District and Politician has Politician Id,
	PoliticianId                            int NOT NULL,
	-- Legislative District is for State Or Province and State Or Province has State Or Province Id,
	StateOrProvinceId                       int NOT NULL,
	PRIMARY KEY(DistrictNumber, StateOrProvinceId),
	UNIQUE(PoliticianId)
)
GO

CREATE TABLE StateOrProvince (
	-- State Or Province has State Or Province Id,
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

