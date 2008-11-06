CREATE TABLE Marriage (
	HusbandFamilyName	varchar NOT NULL,
	HusbandGivenName	varchar NOT NULL,
	WifeFamilyName	varchar NOT NULL,
	WifeGivenName	varchar NOT NULL,
	UNIQUE(HusbandGivenName, HusbandFamilyName, WifeGivenName, WifeFamilyName)
)
GO

CREATE TABLE Person (
	FamilyName	varchar NOT NULL,
	GivenName	varchar NOT NULL,
	UNIQUE(GivenName, FamilyName)
)
GO

ALTER TABLE Marriage
	ADD FOREIGN KEY(HusbandGivenName, HusbandFamilyName)
	REFERENCES Person(GivenName, FamilyName)
GO

ALTER TABLE Marriage
	ADD FOREIGN KEY(WifeGivenName, WifeFamilyName)
	REFERENCES Person(GivenName, FamilyName)
GO

