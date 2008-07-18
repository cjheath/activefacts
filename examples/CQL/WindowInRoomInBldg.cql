vocabulary WindowInRoomInBldg;

/*
 * Value Types
 */
Building is defined as SignedInteger(32);
RoomNumber is defined as SignedInteger(32);
WallNumber is defined as SignedInteger(32);
WindowNumber is defined as UnsignedInteger(32);

/*
 * Entity Types
 */
Room is identified by Building and RoomNumber where
	Room is in exactly one Building,
	Room has exactly one RoomNumber;

Window is identified by Room and WallNumber and WindowNumber where
	Window is in exactly one Room,
	Window is located in exactly one WallNumber,
	Window has exactly one WindowNumber;

