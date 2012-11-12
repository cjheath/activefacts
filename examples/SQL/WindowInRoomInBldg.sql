CREATE TABLE Window (
	-- Window is located in Wall and Wall has Wall Number,
	WallNumber                              int NOT NULL,
	-- Window is located in Wall and Wall is in Room and Room is in Building and Building has Building Number,
	WallRoomBuildingNumber                  int NOT NULL,
	-- Window is located in Wall and Wall is in Room and Room has Room Number,
	WallRoomNumber                          int NOT NULL,
	-- Window has Window Number,
	WindowNumber                            int NOT NULL,
	PRIMARY KEY(WallRoomBuildingNumber, WallRoomNumber, WallNumber, WindowNumber)
)
GO

