CREATE TABLE Window (
	RoomBuilding	int NOT NULL,
	RoomRoomNumber	int NOT NULL,
	WallNumber	int NOT NULL,
	WindowNumber	int NOT NULL,
	UNIQUE(RoomBuilding, RoomRoomNumber, WallNumber, WindowNumber)
)
GO

