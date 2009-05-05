vocabulary PersonPlaysGame;

/*
 * Value Types
 */
GameCode is written as FixedLengthText();
PersonName is written as VariableLengthText();

/*
 * Entity Types
 */
Game is identified by its Code;

Person is identified by its Name;
Playing is where
	Person plays Game;

