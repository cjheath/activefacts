CREATE TABLE Marriage (
	HusbandGivenName	varchar NOT NULL,
	HusbandFamilyName	varchar NOT NULL,
	WifeGivenName	varchar NOT NULL,
	WifeFamilyName	varchar NOT NULL,
	UNIQUE(HusbandGivenName, HusbandFamilyName, WifeGivenName, WifeFamilyName)
)
GO

