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
Bug is identified by its _Nr;

TestCase is identified by its _Id;

Tester is identified by its _Name;
BugReport is where
	Tester logged Bug;
BugReport is logged against exactly one TestCase,
	TestCase demonstrates BugReport;

/*
 * Constraints:
 */
each Bug occurs at least one time in
	Tester logged Bug;
