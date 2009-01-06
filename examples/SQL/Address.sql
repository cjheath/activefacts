CREATE TABLE Company (
	CompanyName                             varchar NOT NULL,
	AddressStreetFirstStreetLine            varchar(64) NULL,
	AddressStreetSecondStreetLine           varchar(64) NULL,
	AddressStreetThirdStreetLine            varchar(64) NULL,
	AddressCity                             varchar(64) NULL,
	AddressPostcode                         varchar NULL,
	AddressStreetNumber                     varchar(12) NULL,
	PRIMARY KEY(CompanyName)
)
GO

CREATE TABLE Person (
	FamilyName                              varchar(20) NOT NULL,
	GivenNames                              varchar(20) NOT NULL,
	AddressStreetFirstStreetLine            varchar(64) NULL,
	AddressStreetSecondStreetLine           varchar(64) NULL,
	AddressStreetThirdStreetLine            varchar(64) NULL,
	AddressCity                             varchar(64) NULL,
	AddressPostcode                         varchar NULL,
	AddressStreetNumber                     varchar(12) NULL,
	PRIMARY KEY(FamilyName, GivenNames)
)
GO

