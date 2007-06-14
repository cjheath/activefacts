CREATE SCHEMA Orienteering
GO

GO

CREATE TABLE Orienteering.Visit
(
	"Time" BIGINT NOT NULL, 
	EventControl_ID BIGINT NOT NULL, 
	EventControl_Control BIGINT CONSTRAINT Control_Chk CHECK (EventControl_Control BETWEEN 1 AND 1000) NOT NULL, 
	Entrant_EntrantID BIGINT NOT NULL, 
	CONSTRAINT EntrntVstdEchCntrlAtEchTmOnc PRIMARY KEY(EventControl_ID, EventControl_Control, Entrant_EntrantID, "Time")
)
GO


CREATE TABLE Orienteering.Event
(
	EventName NATIONAL CHARACTER VARYING(50) , 
	StartLocation NATIONAL CHARACTER VARYING(200) NOT NULL, 
	ID BIGINT NOT NULL, 
	"Date" BIGINT NOT NULL, 
	RunByClub_Code NATIONAL CHARACTER VARYING(6) NOT NULL, 
	Map_MapName NATIONAL CHARACTER VARYING(80) NOT NULL, 
	CONSTRAINT EventNameIsOfOneEvent UNIQUE(EventName), 
	CONSTRAINT EventIDIsOfOneEvent PRIMARY KEY(ID)
)
GO


CREATE TABLE Orienteering.Club
(
	ClubName NATIONAL CHARACTER VARYING(32) NOT NULL, 
	Code NATIONAL CHARACTER VARYING(6) NOT NULL, 
	CONSTRAINT ClubNameIsOfOneClub UNIQUE(ClubName), 
	CONSTRAINT ClubCodeIsOfOneClub PRIMARY KEY(Code)
)
GO


CREATE TABLE Orienteering.Map
(
	MapName NATIONAL CHARACTER VARYING(80) NOT NULL, 
	Accessibility NATIONAL CHARACTER(1) CONSTRAINT Accessibility_Chk CHECK ((LEN(LTRIM(RTRIM(Accessibility)))) >= 1) , 
	Owner_Code NATIONAL CHARACTER VARYING(6) , 
	CONSTRAINT NameIsOfOneMap PRIMARY KEY(MapName)
)
GO


CREATE TABLE Orienteering.Entrant
(
	IsTeam BIT , 
	EntrantID BIGINT IDENTITY (1, 1) NOT NULL, 
	GivenName NATIONAL CHARACTER VARYING(48) NOT NULL, 
	Competitor_FamilyName NATIONAL CHARACTER VARYING(48) , 
	Competitor_Gender NATIONAL CHARACTER(1) CONSTRAINT Gender_Chk CHECK ((LEN(LTRIM(RTRIM(Competitor_Gender)))) >= 1 AND 
Competitor_Gender IN ('M', 'F')) , 
	Competitor_BirthYear BIGINT CONSTRAINT Year_Chk CHECK (Competitor_BirthYear BETWEEN 1900 AND 3000) , 
	Competitor_PostCode BIGINT , 
	MemberOfClub_Code NATIONAL CHARACTER VARYING(6) , 
	CONSTRAINT EntrantIDIsOfOneEntrant PRIMARY KEY(EntrantID), 
	CONSTRAINT Cmpttr_CmpttrHsDstnctNm UNIQUE(Competitor_FamilyName), 
	CONSTRAINT CompetitorHasDistinctName UNIQUE(GivenName)
)
GO


CREATE TABLE Orienteering.TeamMember
(
	EventCourse_ID BIGINT NOT NULL, 
	EventCourse_Course NATIONAL CHARACTER VARYING(16) CONSTRAINT Course_Chk CHECK (EventCourse_Course IN ('PW')) NOT NULL, 
	Competitor_EntrantID BIGINT NOT NULL, 
	Team_EntrantID BIGINT NOT NULL, 
	CONSTRAINT TeamLoyalty PRIMARY KEY(EventCourse_ID, EventCourse_Course, Competitor_EntrantID)
)
GO


CREATE TABLE Orienteering.PunchPlacement
(
	Punch_PunchID BIGINT NOT NULL, 
	EventControl_ID BIGINT NOT NULL, 
	EventControl_Control BIGINT CONSTRAINT Control_Chk CHECK (EventControl_Control BETWEEN 1 AND 1000) NOT NULL, 
	Event_ID BIGINT NOT NULL, 
	CONSTRAINT PunchIsAtOneEventControl PRIMARY KEY(Punch_PunchID, Event_ID)
)
GO


CREATE TABLE Orienteering.EventControl
(
	Control BIGINT CONSTRAINT Control_Chk CHECK (Control BETWEEN 1 AND 1000) NOT NULL, 
	PointValue BIGINT , 
	Event_ID BIGINT NOT NULL, 
	CONSTRAINT EventHasEachControlOnce PRIMARY KEY(Event_ID, Control)
)
GO


CREATE TABLE Orienteering.EventCourse
(
	ScoringMethod NATIONAL CHARACTER VARYING(32) CONSTRAINT ScoringMethod_Chk CHECK (ScoringMethod IN ('Score', 'Scatter', 'Special')) , 
	Course NATIONAL CHARACTER VARYING(16) CONSTRAINT Course_Chk CHECK (Course IN ('PW')) NOT NULL, 
	Individual BIT , 
	Event_ID BIGINT NOT NULL, 
	CONSTRAINT EventIncludesEachCourseOnce PRIMARY KEY(Event_ID, Course)
)
GO


CREATE TABLE Orienteering.Entry
(
	Score BIGINT , 
	EntryID BIGINT IDENTITY (1, 1) NOT NULL, 
	FinishOrder BIGINT , 
	EventCourse_ID BIGINT NOT NULL, 
	EventCourse_Course NATIONAL CHARACTER VARYING(16) CONSTRAINT Course_Chk CHECK (EventCourse_Course IN ('PW')) NOT NULL, 
	Entrant_EntrantID BIGINT NOT NULL, 
	CONSTRAINT EntryIDIsOfOneEntry PRIMARY KEY(EntryID), 
	CONSTRAINT EntryIsForEventCourseOnce UNIQUE(Entrant_EntrantID, EventCourse_ID, EventCourse_Course)
)
GO


CREATE TABLE Orienteering.SeriesEvent
(
	Number BIGINT CONSTRAINT Number_Chk CHECK (Number BETWEEN 1 AND 100) NOT NULL, 
	Series_SeriesName NATIONAL CHARACTER VARYING(40) NOT NULL, 
	Event_ID BIGINT NOT NULL, 
	CONSTRAINT SeriesNumberIsOfOneEvent PRIMARY KEY(Number, Series_SeriesName)
)
GO


ALTER TABLE Orienteering.Visit ADD CONSTRAINT Visit_EventControl_FK FOREIGN KEY (EventControl_ID, EventControl_Control)  REFERENCES Orienteering.EventControl (ID, Control)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Visit ADD CONSTRAINT Visit_Entrant_FK FOREIGN KEY (Entrant_EntrantID)  REFERENCES Orienteering.Entrant (EntrantID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Event ADD CONSTRAINT Event_RunByClub_FK FOREIGN KEY (RunByClub_Code)  REFERENCES Orienteering.Club (Code)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Event ADD CONSTRAINT Event_Map_FK FOREIGN KEY (Map_MapName)  REFERENCES Orienteering.Map (MapName)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Map ADD CONSTRAINT Map_Owner_FK FOREIGN KEY (Owner_Code)  REFERENCES Orienteering.Club (Code)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Entrant ADD CONSTRAINT Entrant_MemberOfClub_FK FOREIGN KEY (MemberOfClub_Code)  REFERENCES Orienteering.Club (Code)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.TeamMember ADD CONSTRAINT TeamMember_EventCourse_FK FOREIGN KEY (EventCourse_ID, EventCourse_Course)  REFERENCES Orienteering.EventCourse (ID, Course)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.TeamMember ADD CONSTRAINT TeamMember_Competitor_FK FOREIGN KEY (Competitor_EntrantID)  REFERENCES Orienteering.Entrant (EntrantID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.TeamMember ADD CONSTRAINT TeamMember_Team_FK FOREIGN KEY (Team_EntrantID)  REFERENCES Orienteering.Entrant (EntrantID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.PunchPlacement ADD CONSTRAINT PunchPlacement_EventControl_FK FOREIGN KEY (EventControl_ID, EventControl_Control)  REFERENCES Orienteering.EventControl (ID, Control)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.PunchPlacement ADD CONSTRAINT PunchPlacement_Event_FK FOREIGN KEY (Event_ID)  REFERENCES Orienteering.Event (ID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.EventControl ADD CONSTRAINT EventControl_Event_FK FOREIGN KEY (Event_ID)  REFERENCES Orienteering.Event (ID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.EventCourse ADD CONSTRAINT EventCourse_Event_FK FOREIGN KEY (Event_ID)  REFERENCES Orienteering.Event (ID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Entry ADD CONSTRAINT Entry_EventCourse_FK FOREIGN KEY (EventCourse_ID, EventCourse_Course)  REFERENCES Orienteering.EventCourse (ID, Course)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Entry ADD CONSTRAINT Entry_Entrant_FK FOREIGN KEY (Entrant_EntrantID)  REFERENCES Orienteering.Entrant (EntrantID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.SeriesEvent ADD CONSTRAINT SeriesEvent_Event_FK FOREIGN KEY (Event_ID)  REFERENCES Orienteering.Event (ID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO



GO