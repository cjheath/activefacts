CREATE TABLE Company (
	-- maybe Company has head office at Address and Address is in City,
	AddressCity                             varchar(64) NULL,
	-- maybe Company has head office at Address and maybe Address is in Postcode,
	AddressPostcode                         varchar NULL CHECK((AddressPostcode >= 1000 AND AddressPostcode <= 9999)),
	-- maybe Company has head office at Address and Address is at Street and Street includes first-Street Line,
	AddressStreetFirstStreetLine            varchar(64) NULL,
	-- maybe Company has head office at Address and maybe Address is at street-Number,
	AddressStreetNumber                     varchar(12) NULL,
	-- maybe Company has head office at Address and Address is at Street and maybe Street includes second-Street Line,
	AddressStreetSecondStreetLine           varchar(64) NULL,
	-- maybe Company has head office at Address and Address is at Street and maybe Street includes third-Street Line,
	AddressStreetThirdStreetLine            varchar(64) NULL,
	-- Company has Company Name,
	CompanyName                             varchar NOT NULL,
	PRIMARY KEY(CompanyName)
)
GO

CREATE TABLE Person (
	-- maybe Person lives at Address and Address is in City,
	AddressCity                             varchar(64) NULL,
	-- maybe Person lives at Address and maybe Address is in Postcode,
	AddressPostcode                         varchar NULL CHECK((AddressPostcode >= 1000 AND AddressPostcode <= 9999)),
	-- maybe Person lives at Address and Address is at Street and Street includes first-Street Line,
	AddressStreetFirstStreetLine            varchar(64) NULL,
	-- maybe Person lives at Address and maybe Address is at street-Number,
	AddressStreetNumber                     varchar(12) NULL,
	-- maybe Person lives at Address and Address is at Street and maybe Street includes second-Street Line,
	AddressStreetSecondStreetLine           varchar(64) NULL,
	-- maybe Person lives at Address and Address is at Street and maybe Street includes third-Street Line,
	AddressStreetThirdStreetLine            varchar(64) NULL,
	-- Person is of Family and Family has Family Name,
	FamilyName                              varchar(20) NOT NULL,
	-- Person has Given Names,
	GivenNames                              varchar(20) NOT NULL,
	PRIMARY KEY(FamilyName, GivenNames)
)
GO

