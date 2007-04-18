CREATE SCHEMA SimpleMandatory
GO

GO

CREATE TABLE SimpleMandatory.Person
(
	FamilyName NATIONAL CHARACTER VARYING(20) NOT NULL, 
	GivenName NATIONAL CHARACTER VARYING(20) , 
	Address_Street_StreetLine1 NATIONAL CHARACTER VARYING(64) , 
	Address_Street_StreetLine2 NATIONAL CHARACTER VARYING(64) , 
	Address_City NATIONAL CHARACTER VARYING() , 
	Address_Postcode NATIONAL CHARACTER VARYING() , 
	Address_StreetNumber NATIONAL CHARACTER VARYING(10) , 
	CONSTRAINT PrsnIsKnwnByFmlyNmGvnNm PRIMARY KEY(FamilyName, GivenName)
)
GO



CREATE PROCEDURE SimpleMandatory.InsertPerson
(
	@FamilyName NATIONAL CHARACTER VARYING(20) , 
	@GivenName NATIONAL CHARACTER VARYING(20) , 
	@Address_Street_StreetLine1 NATIONAL CHARACTER VARYING(64) , 
	@Address_Street_StreetLine2 NATIONAL CHARACTER VARYING(64) , 
	@Address_City NATIONAL CHARACTER VARYING() , 
	@Address_Postcode NATIONAL CHARACTER VARYING() , 
	@Address_StreetNumber NATIONAL CHARACTER VARYING(10) 
)
AS
	INSERT INTO SimpleMandatory.Person(FamilyName, GivenName, Address_Street_StreetLine1, Address_Street_StreetLine2, Address_City, Address_Postcode, Address_StreetNumber)
	VALUES (@FamilyName, @GivenName, @Address_Street_StreetLine1, @Address_Street_StreetLine2, @Address_City, @Address_Postcode, @Address_StreetNumber)
GO


CREATE PROCEDURE SimpleMandatory.DeletePerson
(
	@FamilyName NATIONAL CHARACTER VARYING(20) , 
	@GivenName NATIONAL CHARACTER VARYING(20) 
)
AS
	DELETE FROM SimpleMandatory.Person
	WHERE FamilyName = @FamilyName AND 
GivenName = @GivenName
GO


CREATE PROCEDURE SimpleMandatory.UpdatePersonFamilyName
(
	@old_FamilyName NATIONAL CHARACTER VARYING(20) , 
	@old_GivenName NATIONAL CHARACTER VARYING(20) , 
	@FamilyName NATIONAL CHARACTER VARYING(20) 
)
AS
	UPDATE SimpleMandatory.Person
SET FamilyName = @FamilyName
	WHERE FamilyName = @old_FamilyName AND 
GivenName = @old_GivenName
GO


CREATE PROCEDURE SimpleMandatory.UpdatePersonGivenName
(
	@old_FamilyName NATIONAL CHARACTER VARYING(20) , 
	@old_GivenName NATIONAL CHARACTER VARYING(20) , 
	@GivenName NATIONAL CHARACTER VARYING(20) 
)
AS
	UPDATE SimpleMandatory.Person
SET GivenName = @GivenName
	WHERE FamilyName = @old_FamilyName AND 
GivenName = @old_GivenName
GO


CREATE PROCEDURE SimpleMandatory.UpdtPrsnAddrss_Strt_StrtLn1
(
	@old_FamilyName NATIONAL CHARACTER VARYING(20) , 
	@old_GivenName NATIONAL CHARACTER VARYING(20) , 
	@Address_Street_StreetLine1 NATIONAL CHARACTER VARYING(64) 
)
AS
	UPDATE SimpleMandatory.Person
SET Address_Street_StreetLine1 = @Address_Street_StreetLine1
	WHERE FamilyName = @old_FamilyName AND 
GivenName = @old_GivenName
GO


CREATE PROCEDURE SimpleMandatory.UpdtPrsnAddrss_Strt_StrtLn2
(
	@old_FamilyName NATIONAL CHARACTER VARYING(20) , 
	@old_GivenName NATIONAL CHARACTER VARYING(20) , 
	@Address_Street_StreetLine2 NATIONAL CHARACTER VARYING(64) 
)
AS
	UPDATE SimpleMandatory.Person
SET Address_Street_StreetLine2 = @Address_Street_StreetLine2
	WHERE FamilyName = @old_FamilyName AND 
GivenName = @old_GivenName
GO


CREATE PROCEDURE SimpleMandatory.UpdatePersonAddress_City
(
	@old_FamilyName NATIONAL CHARACTER VARYING(20) , 
	@old_GivenName NATIONAL CHARACTER VARYING(20) , 
	@Address_City NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE SimpleMandatory.Person
SET Address_City = @Address_City
	WHERE FamilyName = @old_FamilyName AND 
GivenName = @old_GivenName
GO


CREATE PROCEDURE SimpleMandatory.UpdatePersonAddress_Postcode
(
	@old_FamilyName NATIONAL CHARACTER VARYING(20) , 
	@old_GivenName NATIONAL CHARACTER VARYING(20) , 
	@Address_Postcode NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE SimpleMandatory.Person
SET Address_Postcode = @Address_Postcode
	WHERE FamilyName = @old_FamilyName AND 
GivenName = @old_GivenName
GO


CREATE PROCEDURE SimpleMandatory.UpdtPrsnAddrss_StrtNmbr
(
	@old_FamilyName NATIONAL CHARACTER VARYING(20) , 
	@old_GivenName NATIONAL CHARACTER VARYING(20) , 
	@Address_StreetNumber NATIONAL CHARACTER VARYING(10) 
)
AS
	UPDATE SimpleMandatory.Person
SET Address_StreetNumber = @Address_StreetNumber
	WHERE FamilyName = @old_FamilyName AND 
GivenName = @old_GivenName
GO


GO