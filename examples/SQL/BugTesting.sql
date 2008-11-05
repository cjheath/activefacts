CREATE TABLE BugReport (
	Bug_Nr	int NOT NULL,
	Tester_Name	varchar NOT NULL,
	TestCase_Id	int NOT NULL,
	UNIQUE(Tester_Name, Bug_Nr)
)
GO

