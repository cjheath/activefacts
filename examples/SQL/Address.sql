CREATE TABLE Person (
	AddressStreetFirstStreetLine	varchar(64) NULL,
	AddressStreetSecondStreetLine	varchar(64) NULL,
	AddressStreetThirdStreetLine	varchar(64) NULL,
	AddressCity	varchar(64) NULL,
	AddressPostcode	varchar NULL,
	AddressStreetNumber	varchar(12) NULL,
	FamilyName	varchar(20) NOT NULL,
	GivenNames	varchar(20) NOT NULL,
	UNIQUE(FamilyName, GivenNames)
)
GO

CREATE TABLE Company (
	AddressStreetFirstStreetLine	varchar(64) NULL,
	AddressStreetSecondStreetLine	varchar(64) NULL,
	AddressStreetThirdStreetLine	varchar(64) NULL,
	AddressCity	varchar(64) NULL,
	AddressPostcode	varchar NULL,
	AddressStreetNumber	varchar(12) NULL,
	CompanyName	varchar NOT NULL,
	UNIQUE(CompanyName)
)
GO

