vocabulary OddIdentifier;

/*
 * Value Types
 */
Ordinal is written as SignedInteger(32);
Text is written as VariableLengthText;
ThingID is written as AutoCounter;

/*
 * Entity Types
 */
Thing is identified by its ID;

ThingSequence is identified by Thing and Text where
	Thing has Ordinal occurrence,
	ThingSequence has one Text;

