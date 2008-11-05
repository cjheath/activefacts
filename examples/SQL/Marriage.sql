CREATE TABLE Marriage (
	HusbandFamilyName	varchar NOT NULL,
	HusbandGivenName	varchar NOT NULL,
	WifeFamilyName	varchar NOT NULL,
	WifeGivenName	varchar NOT NULL,
	UNIQUE(HusbandGivenName, HusbandFamilyName, WifeGivenName, WifeFamilyName)
)
GO

