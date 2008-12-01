vocabulary OddTernary;

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
ThingSequence is where
	Thing has Ordinal occurrence;
ThingSequence has at most one Text;

/*
 * Constraints:
 */
each combination Thing, Text occurs at most one time in
	Thing has Ordinal occurrence,
	ThingSequence has Text;
