vocabulary NewModel;

/*
 * Value Types
 */
Building = SignedInteger(32);
RoomNumber = SignedInteger(32);
WallNumber = SignedInteger(32);
WindowNumber = UnsignedInteger(32);

/*
 * Entity Types
 */
Room = entity known by Building and RoomNumber:
	Room is in exactly one Building,
	Room has exactly one RoomNumber;

Window = entity known by Room and WallNumber and WindowNumber:
	Window is in exactly one Room,
	Window is located in exactly one WallNumber,
	Window has exactly one WindowNumber;

