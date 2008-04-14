vocabulary BugTesting;

/*
 * Value Types
 */
Bug_Nr = SignedInteger(32);
TestCase_Id = AutoCounter();
Tester_Name = VariableLengthText();

/*
 * Entity Types
 */
Bug = entity identified by Bug_Nr:
	Bug has exactly one Bug_Nr,
	Bug_Nr is of at most one Bug;

TestCase = entity identified by TestCase_Id:
	TestCase has exactly one TestCase_Id,
	TestCase_Id is of at most one TestCase;

Tester = entity identified by Tester_Name:
	Tester has exactly one Tester_Name,
	Tester_Name is of at most one Tester;
BugReport = Tester logged Bug;
BugReport is logged against exactly one TestCase,
	TestCase demonstrates BugReport;
