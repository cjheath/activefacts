vocabulary OddIdentifier;

/*
 * Value Types
 */
Ordinal is written as Signed Integer(32);
Text is written as String;
Thing ID is written as Auto Counter;

/*
 * Entity Types
 */
Thing is identified by its ID;

Thing Sequence is identified by Thing and Text where
	Thing has Ordinal occurrence,
	Thing Sequence has one Text;

