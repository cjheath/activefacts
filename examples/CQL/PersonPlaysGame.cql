vocabulary PersonPlaysGame;

/*
 * Value Types
 */
GameCode is defined as FixedLengthText();
PersonName is defined as VariableLengthText();

/*
 * Entity Types
 */
Game is identified by its Code;

Person is identified by its Name;
Playing is where
	Person plays Game;

