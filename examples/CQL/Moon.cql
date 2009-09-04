vocabulary Moon;

/*
 * Value Types
 */
MoonName is written as VariableLengthText;
NrDaysNr is written as SignedInteger(32);
PlanetName is written as VariableLengthText;

/*
 * Entity Types
 */
Moon is identified by its Name;

NrDays is identified by its Nr;

Orbit is where
	Moon is in orbit;
Orbit has a synodic period of at most one NrDays;

Planet is identified by its Name;
Orbit is around one Planet;

