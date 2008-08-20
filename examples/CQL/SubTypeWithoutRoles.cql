vocabulary SubTypeWithoutRoles;

/*
 * Value Types
 */
Thing_ID is defined as AutoCounter();

/*
 * Entity Types
 */
Thing is identified by Thing_ID where
	Thing has exactly one Thing_ID,
	Thing_ID is of at most one Thing;

Thong is a kind of Thing;

