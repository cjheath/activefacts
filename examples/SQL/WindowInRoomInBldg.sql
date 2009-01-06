CREATE TABLE Window (
	RoomBuilding                            SignedInteger(32) NOT NULL,
	RoomNumber                              SignedInteger(32) NOT NULL,
	WallNumber                              SignedInteger(32) NOT NULL,
	WindowNumber                            UnsignedInteger(32) NOT NULL,
	PRIMARY KEY(RoomBuilding, RoomNumber, WallNumber, WindowNumber)
)
GO

