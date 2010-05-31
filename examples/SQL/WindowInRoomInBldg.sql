CREATE TABLE Window (
	-- Window is in Room and Room is in Building,
	RoomBuilding                            int NOT NULL,
	-- Window is in Room and Room has Room Number,
	RoomNumber                              int NOT NULL,
	-- Window is located in Wall Number,
	WallNumber                              int NOT NULL,
	-- Window has Window Number,
	WindowNumber                            int NOT NULL,
	PRIMARY KEY(RoomBuilding, RoomNumber, WallNumber, WindowNumber)
)
GO

