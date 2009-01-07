vocabulary OddIdentifier;

/*
 * Value Types
 */
Ordinal is defined as SignedInteger(32);
Text is defined as VariableLengthText();
ThingID is defined as AutoCounter();

/*
 * Entity Types
 */
Thing is identified by its ID;
ThingSequence is identified by Thing and Text where
	Thing has Ordinal occurrence,
	ThingSequence has at most one Text;
