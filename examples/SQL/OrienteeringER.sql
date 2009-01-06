CREATE TABLE Club (
	Code                                    FixedLengthText NOT NULL,
	ClubName                                VariableLengthText NOT NULL,
	PRIMARY KEY(Code)
)
GO

CREATE TABLE Event (
	EventID                                 AutoCounter NOT NULL,
	EventName                               VariableLengthText NOT NULL,
	ClubCode                                FixedLengthText NOT NULL,
	MapMapName                              VariableLengthText NOT NULL,
	Date                                    DateAndTime NOT NULL,
	Location                                VariableLengthText NOT NULL,
	SeriesEventSeriesName                   VariableLengthText NOT NULL,
	SeriesEventEventNumber                  SignedInteger(32) NOT NULL,
	PRIMARY KEY(EventID)
)
GO

CREATE TABLE EventControl (
	EventEventID                            AutoCounter NOT NULL,
	Control                                 UnsignedInteger(32) NOT NULL,
	PointValue                              UnsignedInteger(32) NOT NULL,
	PRIMARY KEY(EventEventID, Control)
)
GO

CREATE TABLE EventCourse (
	Course                                  FixedLengthText NOT NULL,
	EventEventID                            AutoCounter NOT NULL,
	PRIMARY KEY(Course, EventEventID)
)
GO

CREATE TABLE Map (
	MapName                                 VariableLengthText NOT NULL,
	Accessibility                           FixedLengthText NOT NULL,
	ClubCode                                FixedLengthText NOT NULL,
	PRIMARY KEY(MapName)
)
GO

