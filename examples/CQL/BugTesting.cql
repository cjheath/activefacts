vocabulary BugTesting;

/*
 * Value Types
 */
BugNr is defined as SignedInteger(32);
TestCaseId is defined as AutoCounter();
TesterName is defined as VariableLengthText();

/*
 * Entity Types
 */
Bug is identified by its Nr;

TestCase is identified by its Id;

Tester is identified by its Name;
BugReport is where
	Tester logged Bug;
BugReport is logged against exactly one TestCase,
	TestCase demonstrates BugReport;

/*
 * Constraints:
 */
each Bug occurs at least one time in
	Tester logged Bug;
