CREATE TABLE Marriage (
	HusbandGivenName                        varchar NOT NULL,
	HusbandFamilyName                       varchar NOT NULL,
	WifeGivenName                           varchar NOT NULL,
	WifeFamilyName                          varchar NOT NULL,
	PRIMARY KEY(HusbandGivenName, HusbandFamilyName, WifeGivenName, WifeFamilyName)
)
GO

CREATE TABLE Person (
	GivenName                               varchar NOT NULL,
	FamilyName                              varchar NOT NULL,
	PRIMARY KEY(GivenName, FamilyName)
)
GO

ALTER TABLE Marriage
	ADD FOREIGN KEY (HusbandGivenName, HusbandFamilyName) REFERENCES Person (GivenName, FamilyName)
GO

ALTER TABLE Marriage
	ADD FOREIGN KEY (WifeGivenName, WifeFamilyName) REFERENCES Person (GivenName, FamilyName)
GO

