CREATE SCHEMA Orienteering
GO

GO


CREATE TABLE Orienteering.Event
(
	eventID INTEGER IDENTITY (1, 1) NOT NULL,
	startLocation NATIONAL CHARACTER VARYING(200) NOT NULL,
	startTime DATETIME NOT NULL,
	mapID INTEGER NOT NULL,
	clubCode NATIONAL CHARACTER VARYING(6) NOT NULL,
	number INTEGER CHECK (number >= 0 AND number BETWEEN 1 AND 100),
	eventName NATIONAL CHARACTER VARYING(50),
	seriesID INTEGER,
	CONSTRAINT EventNameIsOfOneEvent UNIQUE(eventName),
	CONSTRAINT EventIDIsOfOneEvent PRIMARY KEY(eventID),
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
	mapID INTEGER IDENTITY (1, 1) NOT NULL,
	mapName NATIONAL CHARACTER VARYING(80) NOT NULL,
	owner NATIONAL CHARACTER VARYING(6) NOT NULL,
	accessibility NATIONAL CHARACTER(1) CHECK (accessibility BETWEEN N'A' AND N'D'),
	CONSTRAINT NameIsOfOneMap UNIQUE(mapName),
	CONSTRAINT InternalUniquenessConstraint26 PRIMARY KEY(mapID)
)
GO


CREATE TABLE Orienteering.Person
(
	personID INTEGER IDENTITY (1, 1) NOT NULL,
	familyName NATIONAL CHARACTER VARYING(48) NOT NULL,
	givenName NATIONAL CHARACTER VARYING(48) NOT NULL,
	gender NATIONAL CHARACTER(1) CHECK (gender IN (N'M', N'F')),
	birthYear INTEGER CHECK (birthYear >= 0 AND birthYear BETWEEN 1900 AND 3000),
	postCode INTEGER CHECK (postCode >= 0),
	clubCode NATIONAL CHARACTER VARYING(6),
	CONSTRAINT CompetitorHasDistinctName UNIQUE(givenName, familyName),
	CONSTRAINT InternalUniquenessConstraint3 PRIMARY KEY(personID)
)
GO


CREATE TABLE Orienteering.Series
(
	seriesID INTEGER IDENTITY (1, 1) NOT NULL,
	name NATIONAL CHARACTER VARYING(40) NOT NULL,
	CONSTRAINT NameIsOfOneSeries UNIQUE(name),
	CONSTRAINT InternalUniquenessConstraint18 PRIMARY KEY(seriesID)
)
GO


CREATE TABLE Orienteering.Visit
(
	punchID INTEGER IDENTITY (1, 1) NOT NULL,
	"time" DATETIME NOT NULL,
	entryID INTEGER NOT NULL,
	CONSTRAINT EntrantVisitedEachControlAtEachTimeOnce PRIMARY KEY(punchID, entryID, "time")
)
GO


CREATE TABLE Orienteering.Entry
(
	entryID INTEGER IDENTITY (1, 1) NOT NULL,
	personID INTEGER NOT NULL,
	eventID INTEGER NOT NULL,
	course NATIONAL CHARACTER VARYING(16) CHECK (course IN (N'PW') OR course BETWEEN N'A' AND N'E') NOT NULL,
	score INTEGER,
	finishPlacing INTEGER CHECK (finishPlacing >= 0),
	CONSTRAINT PersonMayEnterEventOnce UNIQUE(personID, eventID),
	CONSTRAINT EntryHasOneEntryID PRIMARY KEY(entryID)
)
GO


CREATE TABLE Orienteering.EventScoringMethod
(
	course NATIONAL CHARACTER VARYING(16) CHECK (course IN (N'PW') OR course BETWEEN N'A' AND N'E') NOT NULL,
	eventID INTEGER NOT NULL,
	scoringMethod NATIONAL CHARACTER VARYING(32) CHECK (scoringMethod IN (N'Score', N'Scatter', N'Special')) NOT NULL,
	CONSTRAINT OnlyOneScoringMethodForEachEventAndCourse PRIMARY KEY(course, eventID)
)
GO


CREATE TABLE Orienteering.PunchPlacement
(
	punchID INTEGER IDENTITY (1, 1) NOT NULL,
	controlNumber INTEGER CHECK (controlNumber >= 0 AND controlNumber BETWEEN 1 AND 1000) NOT NULL,
	eventID INTEGER NOT NULL,
	CONSTRAINT InternalUniquenessConstraint31 PRIMARY KEY(controlNumber, eventID, punchID)
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


ALTER TABLE Orienteering.Event ADD CONSTRAINT Event_FK1 FOREIGN KEY (mapID) REFERENCES Orienteering.Map (mapID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Event ADD CONSTRAINT Event_FK2 FOREIGN KEY (seriesID) REFERENCES Orienteering.Series (seriesID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Event ADD CONSTRAINT Event_FK3 FOREIGN KEY (clubCode) REFERENCES Orienteering.Club (clubCode) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Map ADD CONSTRAINT Map_FK FOREIGN KEY (owner) REFERENCES Orienteering.Club (clubCode) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Person ADD CONSTRAINT Person_FK FOREIGN KEY (clubCode) REFERENCES Orienteering.Club (clubCode) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Visit ADD CONSTRAINT Visit_FK FOREIGN KEY (entryID) REFERENCES Orienteering.Entry (entryID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Entry ADD CONSTRAINT Entry_FK1 FOREIGN KEY (personID) REFERENCES Orienteering.Person (personID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Entry ADD CONSTRAINT Entry_FK2 FOREIGN KEY (eventID) REFERENCES Orienteering.Event (eventID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.EventScoringMethod ADD CONSTRAINT EventScoringMethod_FK FOREIGN KEY (eventID) REFERENCES Orienteering.Event (eventID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.PunchPlacement ADD CONSTRAINT PunchPlacement_FK FOREIGN KEY (controlNumber, eventID) REFERENCES Orienteering.EventControl (controlNumber, eventID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.EventControl ADD CONSTRAINT EventControl_FK FOREIGN KEY (eventID) REFERENCES Orienteering.Event (eventID) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


GO