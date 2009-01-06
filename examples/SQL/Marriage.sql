CREATE TABLE Marriage (
	HusbandGivenName                        VariableLengthText NOT NULL,
	HusbandFamilyName                       VariableLengthText NOT NULL,
	WifeGivenName                           VariableLengthText NOT NULL,
	WifeFamilyName                          VariableLengthText NOT NULL,
	PRIMARY KEY(HusbandGivenName, HusbandFamilyName, WifeGivenName, WifeFamilyName)
)
GO

CREATE TABLE Person (
	GivenName                               VariableLengthText NOT NULL,
	FamilyName                              VariableLengthText NOT NULL,
	PRIMARY KEY(GivenName, FamilyName)
)
GO

