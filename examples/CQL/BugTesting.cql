vocabulary BugTesting;

/*
 * Value Types
 */
Bug_Nr is defined as SignedInteger(32);
TestCase_Id is defined as AutoCounter();
Tester_Name is defined as VariableLengthText();

/*
 * Entity Types
 */
Bug is identified by Bug_Nr where
	Bug has exactly one Bug_Nr,
	Bug_Nr is of at most one Bug;

TestCase is identified by TestCase_Id where
	TestCase has exactly one TestCase_Id,
	TestCase_Id is of at most one TestCase;

Tester is identified by Tester_Name where
	Tester has exactly one Tester_Name,
	Tester_Name is of at most one Tester;
BugReport is where
	Tester logged Bug;
BugReport is logged against exactly one TestCase,
	TestCase demonstrates BugReport;

/*
Constraints:
	REVISIT: each (Bug) occurs at least one time in 'Tester logged Bug'
 */
