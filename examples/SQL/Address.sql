CREATE TABLE Company (
	CompanyName	varchar NOT NULL,
	AddressCity	varchar(64) NULL,
	AddressPostcode	varchar NULL,
	AddressStreetFirstStreetLine	varchar(64) NULL,
	AddressStreetNumber	varchar(12) NULL,
	AddressStreetSecondStreetLine	varchar(64) NULL,
	AddressStreetThirdStreetLine	varchar(64) NULL,
	PRIMARY KEY(CompanyName)
)
GO

CREATE TABLE Person (
	FamilyName	varchar(20) NOT NULL,
	GivenNames	varchar(20) NOT NULL,
	AddressCity	varchar(64) NULL,
	AddressPostcode	varchar NULL,
	AddressStreetFirstStreetLine	varchar(64) NULL,
	AddressStreetNumber	varchar(12) NULL,
	AddressStreetSecondStreetLine	varchar(64) NULL,
	AddressStreetThirdStreetLine	varchar(64) NULL,
	PRIMARY KEY(FamilyName, GivenNames)
)
GO

