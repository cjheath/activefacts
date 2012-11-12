vocabulary WindowInRoomInBldg;

/*
 * Value Types
 */
Building Number is written as Signed Integer(32);
Room Number is written as Signed Integer(32);
Wall Number is written as Signed Integer(32);
Window Number is written as Unsigned Integer(32);

/*
 * Entity Types
 */
Building is identified by its Number;

Room is identified by Building and Room Number where
	Room is in one Building,
	Room has one Room Number;

Wall is identified by Room and Wall Number where
	Wall is in one Room,
	Room contains Wall,
	Wall has one Wall Number;

Window is identified by Wall and Window Number where
	Window is located in one Wall,
	Window has one Window Number;

