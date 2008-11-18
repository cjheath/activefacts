CREATE TABLE BugReport (
	BugNr	int NOT NULL,
	TesterName	varchar NOT NULL,
	TestCaseId	int NOT NULL,
	UNIQUE(TesterName, BugNr)
)
GO

