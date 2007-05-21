CREATE SCHEMA SimpleMandatory
GO

GO

CREATE TABLE SimpleMandatory.PhoneBookDelivery
(
	PhoneBookDeliveryDate BIGINT NOT NULL, 
	Address_Address_ID BIGINT NOT NULL, 
	CONSTRAINT InternalUniquenessConstraint1 PRIMARY KEY(PhoneBookDeliveryDate, Address_Address_ID)
)
GO


CREATE TABLE SimpleMandatory.Person
(
	FamilyName NATIONAL CHARACTER VARYING(20) NOT NULL, 
	GivenName NATIONAL CHARACTER VARYING(20) , 
	Address_Address_ID BIGINT , 
	CONSTRAINT PrsnIsKnwnByFmlyNmGvnNm PRIMARY KEY(FamilyName, GivenName)
)
GO


CREATE TABLE SimpleMandatory.Address
(
	Street_StreetLine1 NATIONAL CHARACTER VARYING(64) NOT NULL, 
	Street_StreetLine2 NATIONAL CHARACTER VARYING(64) NOT NULL, 
	City NATIONAL CHARACTER VARYING() NOT NULL, 
	Postcode NATIONAL CHARACTER VARYING() , 
	StreetNumber NATIONAL CHARACTER VARYING(10) , 
	Address_ID BIGINT IDENTITY (1, 1) NOT NULL, 
	CONSTRAINT InternalUniquenessConstraint4 PRIMARY KEY(Address_ID), 
	CONSTRAINT AddressIsKnownByContents UNIQUE(StreetNumber, Street_StreetLine1, Street_StreetLine2, City, Postcode)
)
GO


ALTER TABLE SimpleMandatory.PhoneBookDelivery ADD CONSTRAINT PhoneBookDelivery_Address_FK FOREIGN KEY (Address_Address_ID)  REFERENCES SimpleMandatory.Address (Address_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE SimpleMandatory.Person ADD CONSTRAINT Person_Address_FK FOREIGN KEY (Address_Address_ID)  REFERENCES SimpleMandatory.Address (Address_ID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO



GO