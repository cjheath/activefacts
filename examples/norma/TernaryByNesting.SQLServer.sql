CREATE SCHEMA TernaryByNesting
GO

GO

CREATE TABLE TernaryByNesting.BoardAttendance
(
	Director_Person_Person_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	Director_Company_Company_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	"Date" BIGINT NOT NULL, 
	CONSTRAINT InternalUniquenessConstraint1 PRIMARY KEY("Date", Director_Person_Person_Name, Director_Company_Company_Name)
)
GO



CREATE PROCEDURE TernaryByNesting.InsertBoardAttendance
(
	@Director_Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@Director_Company_Company_Name NATIONAL CHARACTER VARYING() , 
	@"Date" BIGINT 
)
AS
	INSERT INTO TernaryByNesting.BoardAttendance(Director_Person_Person_Name, Director_Company_Company_Name, "Date")
	VALUES (@Director_Person_Person_Name, @Director_Company_Company_Name, @"Date")
GO


CREATE PROCEDURE TernaryByNesting.DeleteBoardAttendance
(
	@"Date" BIGINT , 
	@Director_Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@Director_Company_Company_Name NATIONAL CHARACTER VARYING() 
)
AS
	DELETE FROM TernaryByNesting.BoardAttendance
	WHERE "Date" = @"Date" AND 
Director_Person_Person_Name = @Director_Person_Person_Name AND 
Director_Company_Company_Name = @Director_Company_Company_Name
GO


CREATE PROCEDURE TernaryByNesting.UBADPPN
(
	@"old_""Date""" BIGINT , 
	@Old_Drctr_Prsn_Prsn_Nm NATIONAL CHARACTER VARYING() , 
	@Old_Drctr_Cmpny_Cmpny_Nm NATIONAL CHARACTER VARYING() , 
	@Director_Person_Person_Name NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE TernaryByNesting.BoardAttendance
SET Director_Person_Person_Name = @Director_Person_Person_Name
	WHERE "Date" = @"old_""Date""" AND 
Director_Person_Person_Name = @Old_Drctr_Prsn_Prsn_Nm AND 
Director_Company_Company_Name = @Old_Drctr_Cmpny_Cmpny_Nm
GO


CREATE PROCEDURE TernaryByNesting.UBADCCN
(
	@"old_""Date""" BIGINT , 
	@Old_Drctr_Prsn_Prsn_Nm NATIONAL CHARACTER VARYING() , 
	@Old_Drctr_Cmpny_Cmpny_Nm NATIONAL CHARACTER VARYING() , 
	@Director_Company_Company_Name NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE TernaryByNesting.BoardAttendance
SET Director_Company_Company_Name = @Director_Company_Company_Name
	WHERE "Date" = @"old_""Date""" AND 
Director_Person_Person_Name = @Old_Drctr_Prsn_Prsn_Nm AND 
Director_Company_Company_Name = @Old_Drctr_Cmpny_Cmpny_Nm
GO


CREATE PROCEDURE TernaryByNesting."UpdateBoardAttendance""Date"""
(
	@"old_""Date""" BIGINT , 
	@Old_Drctr_Prsn_Prsn_Nm NATIONAL CHARACTER VARYING() , 
	@Old_Drctr_Cmpny_Cmpny_Nm NATIONAL CHARACTER VARYING() , 
	@"Date" BIGINT 
)
AS
	UPDATE TernaryByNesting.BoardAttendance
SET "Date" = @"Date"
	WHERE "Date" = @"old_""Date""" AND 
Director_Person_Person_Name = @Old_Drctr_Prsn_Prsn_Nm AND 
Director_Company_Company_Name = @Old_Drctr_Cmpny_Cmpny_Nm
GO


GO