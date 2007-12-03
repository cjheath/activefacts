CREATE SCHEMA SimpleMandatory
GO

GO

CREATE TABLE SimpleMandatory.PersonLivesAtAddress
(
	Person_Family_FamilyName NATIONAL CHARACTER VARYING(20) NOT NULL,
	Person_GivenNames NATIONAL CHARACTER VARYING(20) NOT NULL,
	Address_Street_StreetLine NATIONAL CHARACTER VARYING(64) NOT NULL,
	Address_Street_StreetLine NATIONAL CHARACTER VARYING(64) NOT NULL,
	Address_City NATIONAL CHARACTER VARYING(64) NOT NULL,
	Address_Postcode NATIONAL CHARACTER VARYING() NOT NULL,
	Address_StreetNumber NATIONAL CHARACTER VARYING(10) NOT NULL,
	CONSTRAINT InternalUniquenessConstraint1 PRIMARY KEY(Address_Street_StreetLine, Address_Street_StreetLine, Address_City, Address_Postcode, Address_StreetNumber, Person_Family_FamilyName, Person_GivenNames)
)
GO



GO