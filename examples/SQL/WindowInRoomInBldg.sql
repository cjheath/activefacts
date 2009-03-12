CREATE TABLE Window (
	-- Window is in Room and Room has RoomNumber,
	RoomNumber                              int NOT NULL,
	-- Window is in Room and Room is in Building,
	RoomBuilding                            int NOT NULL,
	-- Window is located in WallNumber,
	WallNumber                              int NOT NULL,
	-- Window has WindowNumber,
	WindowNumber                            int NOT NULL,
	PRIMARY KEY(RoomBuilding, RoomNumber, WallNumber, WindowNumber)
)
GO

