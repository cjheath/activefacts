vocabulary Moon;

/*
 * Value Types
 */
Moon Name is written as String;
Nr Days Nr is written as Signed Integer(32);
Planet Name is written as String;

/*
 * Entity Types
 */
Moon is identified by its Name;

Nr Days is identified by its Nr;

Orbit is where
	Moon is in orbit;
Orbit has a synodic period of at most one Nr Days;

Planet is identified by its Name;
Orbit is around one Planet;

