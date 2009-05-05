vocabulary WindowInRoomInBldg;

/*
 * Value Types
 */
Building is written as SignedInteger(32);
RoomNumber is written as SignedInteger(32);
WallNumber is written as SignedInteger(32);
WindowNumber is written as UnsignedInteger(32);

/*
 * Entity Types
 */
Room is identified by Building and RoomNumber where
	Room is in one Building,
	Room has one RoomNumber;

Window is identified by Room and WallNumber and WindowNumber where
	Window is in one Room,
	Window is located in one WallNumber,
	Window has one WindowNumber;

