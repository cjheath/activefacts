CREATE SCHEMA Orienteering
GO

GO


CREATE TABLE Orienteering.Event
(
	EventID INTEGER IDENTITY (1, 1) NOT NULL,
	startLocation NATIONAL CHARACTER VARYING(200) NOT NULL,
	startTime DATETIME NOT NULL,
	mapID INTEGER NOT NULL,
	clubCode NATIONAL CHARACTER VARYING(6) NOT NULL,
	number INTEGER CHECK (number >= 0 AND number BETWEEN 1 AND 100),
	eventName NATIONAL CHARACTER VARYING(50),
	seriesID INTEGER,
	CONSTRAINT EventNameIsOfOneEvent UNIQUE(eventName),
	CONSTRAINT EventIDIsOfOneEvent PRIMARY KEY(EventID),
	CONSTRAINT ExternalUniquenessConstraint1 UNIQUE(seriesID, number)
)
GO


CREATE TABLE Orienteering.Club
(
	clubCode NATIONAL CHARACTER VARYING(6) NOT NULL,
	clubName NATIONAL CHARACTER VARYING(32) NOT NULL,
	CONSTRAINT ClubNameIsOfOneClub UNIQUE(clubName),
	CONSTRAINT ClubCodeIsOfOneClub PRIMARY KEY(clubCode)
)
GO


CREATE TABLE Orienteering.Map
(
	MapID INTEGER IDENTITY (1, 1) NOT NULL,
	mapName NATIONAL CHARACTER VARYING(80) NOT NULL,
	owner NATIONAL CHARACTER VARYING(6) NOT NULL,
	accessibility NATIONAL CHARACTER(1) CHECK (accessibility BETWEEN 'A' AND 'D'),
	CONSTRAINT NameIsOfOneMap UNIQUE(mapName),
	CONSTRAINT InternalUniquenessConstraint26 PRIMARY KEY(MapID)
)
GO


CREATE TABLE Orienteering.Person
(
	PersonID INTEGER IDENTITY (1, 1) NOT NULL,
	familyName NATIONAL CHARACTER VARYING(48) NOT NULL,
	givenName NATIONAL CHARACTER VARYING(48) NOT NULL,
	gender NATIONAL CHARACTER(1) CHECK (gender IN ('M', 'F')),
	birthYear INTEGER CHECK (birthYear >= 0 AND birthYear BETWEEN 1900 AND 3000),
	postCode INTEGER CHECK (postCode >= 0),
	clubCode NATIONAL CHARACTER VARYING(6),
	CONSTRAINT CompetitorHasDistinctName UNIQUE(givenName, familyName),
	CONSTRAINT InternalUniquenessConstraint3 PRIMARY KEY(PersonID)
)
GO


CREATE TABLE Orienteering.Series
(
	SeriesID INTEGER IDENTITY (1, 1) NOT NULL,
	name NATIONAL CHARACTER VARYING(40) NOT NULL,
	CONSTRAINT NameIsOfOneSeries UNIQUE(name),
	CONSTRAINT InternalUniquenessConstraint18 PRIMARY KEY(SeriesID)
)
GO


CREATE TABLE Orienteering.Visit
(
	PunchID INTEGER IDENTITY (1, 1) NOT NULL,
	"time" DATETIME NOT NULL,
	entryID INTEGER NOT NULL,
	CONSTRAINT EntrantVisitedEachControlAtEachTimeOnce PRIMARY KEY(PunchID, entryID, "time")
)
GO


CREATE TABLE Orienteering.Entry
(
	EntryID INTEGER IDENTITY (1, 1) NOT NULL,
	personID INTEGER NOT NULL,
	eventID INTEGER NOT NULL,
	entry NATIONAL CHARACTER VARYING(16) CHECK (entry IN ('PW') OR entry BETWEEN 'A' AND 'E') NOT NULL,
	score INTEGER,
	finishPlacing INTEGER CHECK (finishPlacing >= 0),
	CONSTRAINT PersonMayEnterEventOnce UNIQUE(personID, eventID),
	CONSTRAINT EntryHasOneEntryID PRIMARY KEY(EntryID)
)
GO


CREATE TABLE Orienteering.EventScoringMethod
(
	course NATIONAL CHARACTER VARYING(16) CHECK (course IN ('PW') OR course BETWEEN 'A' AND 'E') NOT NULL,
	eventID INTEGER NOT NULL,
	scoringMethod NATIONAL CHARACTER VARYING(32) CHECK (scoringMethod IN ('Score', 'Scatter', 'Special')) NOT NULL,
	CONSTRAINT OnlyOneScoringMethodForEachEventAndCourse PRIMARY KEY(course, eventID)
)
GO


CREATE TABLE Orienteering.PunchPlacement
(
	PunchID INTEGER IDENTITY (1, 1) NOT NULL,
	controlNumber INTEGER CHECK (controlNumber >= 0 AND controlNumber BETWEEN 1 AND 1000) NOT NULL,
	eventID INTEGER NOT NULL,
	CONSTRAINT InternalUniquenessConstraint31 PRIMARY KEY(controlNumber, PunchID)
)
GO


CREATE TABLE Orienteering.EventControl
(
	controlNumber INTEGER CHECK (controlNumber >= 0 AND controlNumber BETWEEN 1 AND 1000) NOT NULL,
	eventID INTEGER NOT NULL,
	pointValue INTEGER CHECK (pointValue >= 0),
	CONSTRAINT InternalUniquenessConstraint10 PRIMARY KEY(controlNumber, eventID)
)
GO


ALTER TABLE Orienteering.Event ADD CONSTRAINT Event_FK1 FOREIGN KEY (mapID) REFERENCES Orienteering.Map (MapID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Event ADD CONSTRAINT Event_FK2 FOREIGN KEY (seriesID) REFERENCES Orienteering.Series (SeriesID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Event ADD CONSTRAINT Event_FK3 FOREIGN KEY (clubCode) REFERENCES Orienteering.Club (clubCode) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Map ADD CONSTRAINT Map_FK FOREIGN KEY (owner) REFERENCES Orienteering.Club (clubCode) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Person ADD CONSTRAINT Person_FK FOREIGN KEY (clubCode) REFERENCES Orienteering.Club (clubCode) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Visit ADD CONSTRAINT Visit_FK FOREIGN KEY (entryID) REFERENCES Orienteering.Entry (EntryID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Entry ADD CONSTRAINT Entry_FK1 FOREIGN KEY (personID) REFERENCES Orienteering.Person (PersonID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Entry ADD CONSTRAINT Entry_FK2 FOREIGN KEY (eventID) REFERENCES Orienteering.Event (EventID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.EventScoringMethod ADD CONSTRAINT EventScoringMethod_FK FOREIGN KEY (eventID) REFERENCES Orienteering.Event (EventID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.PunchPlacement ADD CONSTRAINT PunchPlacement_FK FOREIGN KEY (controlNumber, eventID) REFERENCES Orienteering.EventControl (controlNumber, eventID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.EventControl ADD CONSTRAINT EventControl_FK FOREIGN KEY (eventID) REFERENCES Orienteering.Event (EventID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


GO