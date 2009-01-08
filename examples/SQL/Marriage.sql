CREATE TABLE Marriage (
	-- Marriage is by Husband and Person has given-Name,
	HusbandGivenName                        varchar NOT NULL,
	-- Marriage is by Husband and Person has family-Name,
	HusbandFamilyName                       varchar NOT NULL,
	-- Marriage is of Wife and Person has given-Name,
	WifeGivenName                           varchar NOT NULL,
	-- Marriage is of Wife and Person has family-Name,
	WifeFamilyName                          varchar NOT NULL,
	PRIMARY KEY(HusbandGivenName, HusbandFamilyName, WifeGivenName, WifeFamilyName)
)
GO

CREATE TABLE Person (
	-- Person has given-Name,
	GivenName                               varchar NOT NULL,
	-- Person has family-Name,
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

