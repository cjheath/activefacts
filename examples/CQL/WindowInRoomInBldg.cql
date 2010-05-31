vocabulary WindowInRoomInBldg;

/*
 * Value Types
 */
Building is written as Signed Integer(32);
Room Number is written as Signed Integer(32);
Wall Number is written as Signed Integer(32);
Window Number is written as Unsigned Integer(32);

/*
 * Entity Types
 */
Room is identified by Building and Room Number where
	Room is in one Building,
	Room has one Room Number;

Window is identified by Room and Wall Number and Window Number where
	Window is in one Room,
	Window is located in one Wall Number,
	Window has one Window Number;

