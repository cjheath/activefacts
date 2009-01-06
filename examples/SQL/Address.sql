CREATE TABLE Company (
	CompanyName                             VariableLengthText NOT NULL,
	AddressStreetFirstStreetLine            VariableLengthText(64) NULL,
	AddressStreetSecondStreetLine           VariableLengthText(64) NULL,
	AddressStreetThirdStreetLine            VariableLengthText(64) NULL,
	AddressCity                             VariableLengthText(64) NULL,
	AddressPostcode                         VariableLengthText NULL,
	AddressStreetNumber                     VariableLengthText(12) NULL,
	PRIMARY KEY(CompanyName)
)
GO

CREATE TABLE Person (
	FamilyName                              VariableLengthText(20) NOT NULL,
	GivenNames                              VariableLengthText(20) NOT NULL,
	AddressStreetFirstStreetLine            VariableLengthText(64) NULL,
	AddressStreetSecondStreetLine           VariableLengthText(64) NULL,
	AddressStreetThirdStreetLine            VariableLengthText(64) NULL,
	AddressCity                             VariableLengthText(64) NULL,
	AddressPostcode                         VariableLengthText NULL,
	AddressStreetNumber                     VariableLengthText(12) NULL,
	PRIMARY KEY(FamilyName, GivenNames)
)
GO

