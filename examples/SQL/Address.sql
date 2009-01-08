CREATE TABLE Company (
	-- Company has CompanyName,
	CompanyName                             varchar NOT NULL,
	-- maybe Company has head office at Address and Address is at Street and Street includes first-StreetLine,
	AddressStreetFirstStreetLine            varchar(64) NULL,
	-- maybe Company has head office at Address and Address is at Street and maybe Street includes second-StreetLine,
	AddressStreetSecondStreetLine           varchar(64) NULL,
	-- maybe Company has head office at Address and Address is at Street and maybe Street includes third-StreetLine,
	AddressStreetThirdStreetLine            varchar(64) NULL,
	-- maybe Company has head office at Address and Address is in City,
	AddressCity                             varchar(64) NULL,
	-- maybe Company has head office at Address and maybe Address is in Postcode,
	AddressPostcode                         varchar NULL,
	-- maybe Company has head office at Address and maybe Address is at street-Number,
	AddressStreetNumber                     varchar(12) NULL,
	PRIMARY KEY(CompanyName)
)
GO

CREATE TABLE Person (
	-- Person is of Family and Family has FamilyName,
	FamilyName                              varchar(20) NOT NULL,
	-- Person has GivenNames,
	GivenNames                              varchar(20) NOT NULL,
	-- maybe Person lives at Address and Address is at Street and Street includes first-StreetLine,
	AddressStreetFirstStreetLine            varchar(64) NULL,
	-- maybe Person lives at Address and Address is at Street and maybe Street includes second-StreetLine,
	AddressStreetSecondStreetLine           varchar(64) NULL,
	-- maybe Person lives at Address and Address is at Street and maybe Street includes third-StreetLine,
	AddressStreetThirdStreetLine            varchar(64) NULL,
	-- maybe Person lives at Address and Address is in City,
	AddressCity                             varchar(64) NULL,
	-- maybe Person lives at Address and maybe Address is in Postcode,
	AddressPostcode                         varchar NULL,
	-- maybe Person lives at Address and maybe Address is at street-Number,
	AddressStreetNumber                     varchar(12) NULL,
	PRIMARY KEY(FamilyName, GivenNames)
)
GO

