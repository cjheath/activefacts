CREATE SCHEMA SimpleMandatory
GO

GO

CREATE TABLE SimpleMandatory.Person
(
	Family_FamilyName NATIONAL CHARACTER VARYING(20) NOT NULL,
	GivenNames NATIONAL CHARACTER VARYING(20) NOT NULL,
	Address_AddressID BIGINT,
	CONSTRAINT PersonIsKnownByFamilyNameGivenName PRIMARY KEY(Family_FamilyName, GivenNames)
)
GO


CREATE TABLE SimpleMandatory.Address
(
	Street_StreetLine NATIONAL CHARACTER VARYING(64) NOT NULL,
	Street_StreetLine NATIONAL CHARACTER VARYING(64) NOT NULL,
	Street_StreetLine NATIONAL CHARACTER VARYING(64) NOT NULL,
	City NATIONAL CHARACTER VARYING(64) NOT NULL,
	Postcode NATIONAL CHARACTER VARYING(),
	StreetNumber NATIONAL CHARACTER VARYING(10),
	AddressID BIGINT IDENTITY (1, 1) NOT NULL,
	CONSTRAINT InternalUniquenessConstraint2 PRIMARY KEY(AddressID),
	CONSTRAINT AddressIsKnownByContents UNIQUE(StreetNumber, Street_StreetLine, Street_StreetLine, Street_StreetLine, City, Postcode)
)
GO


ALTER TABLE SimpleMandatory.Person ADD CONSTRAINT Person_Address_FK FOREIGN KEY (Address_AddressID) REFERENCES SimpleMandatory.Address (AddressID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO



GO