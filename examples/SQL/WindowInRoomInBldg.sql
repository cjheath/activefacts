CREATE TABLE Window (
	RoomBuilding                            int NOT NULL,
	RoomNumber                              int NOT NULL,
	WallNumber                              int NOT NULL,
	WindowNumber                            int NOT NULL,
	PRIMARY KEY(RoomBuilding, RoomNumber, WallNumber, WindowNumber)
)
GO

