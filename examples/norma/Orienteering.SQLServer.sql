CREATE SCHEMA Orienteering
GO

GO

CREATE TABLE Orienteering.Event
(
	EventName NATIONAL CHARACTER VARYING(50) , 
	Location NATIONAL CHARACTER VARYING(200) NOT NULL, 
	ID BIGINT NOT NULL, 
	"Date" BIGINT NOT NULL, 
	Club_Code NATIONAL CHARACTER VARYING(6) NOT NULL, 
	Map_Name NATIONAL CHARACTER VARYING(80) NOT NULL, 
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
	Name NATIONAL CHARACTER VARYING(80) NOT NULL, 
	Accessibility NATIONAL CHARACTER(1) CONSTRAINT Accessibility_Chk CHECK ((LEN(LTRIM(RTRIM(Accessibility)))) >= 1) , 
	Club_Code NATIONAL CHARACTER VARYING(6) , 
	CONSTRAINT NameIsOfOneMap PRIMARY KEY(Name)
)
GO


CREATE TABLE Orienteering.Entrant
(
	IsTeam BIT NOT NULL, 
	EntrantID BIGINT IDENTITY (1, 1) NOT NULL, 
	GivenName NATIONAL CHARACTER VARYING(48) NOT NULL, 
	Competitor_FamilyName NATIONAL CHARACTER VARYING(48) , 
	Competitor_Gender NATIONAL CHARACTER(1) CONSTRAINT Gender_Chk CHECK ((LEN(LTRIM(RTRIM(Competitor_Gender)))) >= 1) , 
	Competitor_BirthYear BIGINT , 
	Competitor_EntrantPostCode BIGINT , 
	Club_Code NATIONAL CHARACTER VARYING(6) , 
	CONSTRAINT EntrantIDIsOfOneEntrant PRIMARY KEY(EntrantID), 
	CONSTRAINT Cmpttr_CmpttrHsDstnctNm UNIQUE(Competitor_FamilyName), 
	CONSTRAINT CompetitorHasDistinctName UNIQUE(GivenName)
)
GO


CREATE TABLE Orienteering.TeamMember
(
	EventCourse_ID BIGINT NOT NULL, 
	EventCourse_Course NATIONAL CHARACTER VARYING(16) NOT NULL, 
	Competitor_EntrantID BIGINT NOT NULL, 
	Team_EntrantID BIGINT NOT NULL, 
	CONSTRAINT TeamLoyalty PRIMARY KEY(EventCourse_ID, EventCourse_Course, Competitor_EntrantID)
)
GO


CREATE TABLE Orienteering.PunchPlacement
(
	Punch_PunchID BIGINT NOT NULL, 
	EventControl_ID BIGINT NOT NULL, 
	EventControl_Control BIGINT NOT NULL, 
	Event_ID BIGINT NOT NULL, 
	CONSTRAINT PunchIsAtOneEventControl PRIMARY KEY(Punch_PunchID, Event_ID)
)
GO


CREATE TABLE Orienteering.EventControl
(
	Control BIGINT NOT NULL, 
	Points BIGINT , 
	Event_ID BIGINT NOT NULL, 
	CONSTRAINT EventHasEachControlOnce PRIMARY KEY(Event_ID, Control)
)
GO


CREATE TABLE Orienteering.EventCourse
(
	ScoringMethod NATIONAL CHARACTER VARYING(32) , 
	Course NATIONAL CHARACTER VARYING(16) NOT NULL, 
	Individual BIT NOT NULL, 
	Event_ID BIGINT NOT NULL, 
	CONSTRAINT EventIncludesEachCourseOnce PRIMARY KEY(Event_ID, Course)
)
GO


CREATE TABLE Orienteering.Entry
(
	Score BIGINT , 
	EntryID BIGINT IDENTITY (1, 1) NOT NULL, 
	EventCourse_ID BIGINT NOT NULL, 
	EventCourse_Course NATIONAL CHARACTER VARYING(16) NOT NULL, 
	Entrant_EntrantID BIGINT NOT NULL, 
	CONSTRAINT EntryIDIsOfOneEntry PRIMARY KEY(EntryID), 
	CONSTRAINT EntryIsForEventCourseOnce UNIQUE(Entrant_EntrantID, EventCourse_ID, EventCourse_Course)
)
GO


CREATE TABLE Orienteering.SeriesEvent
(
	Number BIGINT NOT NULL, 
	Series_SeriesName NATIONAL CHARACTER VARYING(40) NOT NULL, 
	Event_ID BIGINT NOT NULL, 
	CONSTRAINT SeriesNumberIsOfOneEvent PRIMARY KEY(Number, Series_SeriesName)
)
GO


ALTER TABLE Orienteering.Event ADD CONSTRAINT Event_Club_FK FOREIGN KEY (Club_Code)  REFERENCES Orienteering.Club (Code)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Event ADD CONSTRAINT Event_Map_FK FOREIGN KEY (Map_Name)  REFERENCES Orienteering.Map (Name)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Map ADD CONSTRAINT Map_Club_FK FOREIGN KEY (Club_Code)  REFERENCES Orienteering.Club (Code)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Orienteering.Entrant ADD CONSTRAINT Entrant_Club_FK FOREIGN KEY (Club_Code)  REFERENCES Orienteering.Club (Code)  ON DELETE NO ACTION ON UPDATE NO ACTION
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



CREATE PROCEDURE Orienteering.InsertEvent
(
	@EventName NATIONAL CHARACTER VARYING(50) , 
	@Location NATIONAL CHARACTER VARYING(200) , 
	@ID BIGINT , 
	@"Date" BIGINT , 
	@Club_Code NATIONAL CHARACTER VARYING(6) , 
	@Map_Name NATIONAL CHARACTER VARYING(80) 
)
AS
	INSERT INTO Orienteering.Event(EventName, Location, ID, "Date", Club_Code, Map_Name)
	VALUES (@EventName, @Location, @ID, @"Date", @Club_Code, @Map_Name)
GO


CREATE PROCEDURE Orienteering.DeleteEvent
(
	@ID BIGINT 
)
AS
	DELETE FROM Orienteering.Event
	WHERE ID = @ID
GO


CREATE PROCEDURE Orienteering.UpdateEventEventName
(
	@old_ID BIGINT , 
	@EventName NATIONAL CHARACTER VARYING(50) 
)
AS
	UPDATE Orienteering.Event
SET EventName = @EventName
	WHERE ID = @old_ID
GO


CREATE PROCEDURE Orienteering.UpdateEventLocation
(
	@old_ID BIGINT , 
	@Location NATIONAL CHARACTER VARYING(200) 
)
AS
	UPDATE Orienteering.Event
SET Location = @Location
	WHERE ID = @old_ID
GO


CREATE PROCEDURE Orienteering.UpdateEventID
(
	@old_ID BIGINT , 
	@ID BIGINT 
)
AS
	UPDATE Orienteering.Event
SET ID = @ID
	WHERE ID = @old_ID
GO


CREATE PROCEDURE Orienteering."UpdateEvent""Date"""
(
	@old_ID BIGINT , 
	@"Date" BIGINT 
)
AS
	UPDATE Orienteering.Event
SET "Date" = @"Date"
	WHERE ID = @old_ID
GO


CREATE PROCEDURE Orienteering.UpdateEventClub_Code
(
	@old_ID BIGINT , 
	@Club_Code NATIONAL CHARACTER VARYING(6) 
)
AS
	UPDATE Orienteering.Event
SET Club_Code = @Club_Code
	WHERE ID = @old_ID
GO


CREATE PROCEDURE Orienteering.UpdateEventMap_Name
(
	@old_ID BIGINT , 
	@Map_Name NATIONAL CHARACTER VARYING(80) 
)
AS
	UPDATE Orienteering.Event
SET Map_Name = @Map_Name
	WHERE ID = @old_ID
GO


CREATE PROCEDURE Orienteering.InsertClub
(
	@ClubName NATIONAL CHARACTER VARYING(32) , 
	@Code NATIONAL CHARACTER VARYING(6) 
)
AS
	INSERT INTO Orienteering.Club(ClubName, Code)
	VALUES (@ClubName, @Code)
GO


CREATE PROCEDURE Orienteering.DeleteClub
(
	@Code NATIONAL CHARACTER VARYING(6) 
)
AS
	DELETE FROM Orienteering.Club
	WHERE Code = @Code
GO


CREATE PROCEDURE Orienteering.UpdateClubClubName
(
	@old_Code NATIONAL CHARACTER VARYING(6) , 
	@ClubName NATIONAL CHARACTER VARYING(32) 
)
AS
	UPDATE Orienteering.Club
SET ClubName = @ClubName
	WHERE Code = @old_Code
GO


CREATE PROCEDURE Orienteering.UpdateClubCode
(
	@old_Code NATIONAL CHARACTER VARYING(6) , 
	@Code NATIONAL CHARACTER VARYING(6) 
)
AS
	UPDATE Orienteering.Club
SET Code = @Code
	WHERE Code = @old_Code
GO


CREATE PROCEDURE Orienteering.InsertMap
(
	@Name NATIONAL CHARACTER VARYING(80) , 
	@Accessibility NATIONAL CHARACTER(1) , 
	@Club_Code NATIONAL CHARACTER VARYING(6) 
)
AS
	INSERT INTO Orienteering.Map(Name, Accessibility, Club_Code)
	VALUES (@Name, @Accessibility, @Club_Code)
GO


CREATE PROCEDURE Orienteering.DeleteMap
(
	@Name NATIONAL CHARACTER VARYING(80) 
)
AS
	DELETE FROM Orienteering.Map
	WHERE Name = @Name
GO


CREATE PROCEDURE Orienteering.UpdateMapName
(
	@old_Name NATIONAL CHARACTER VARYING(80) , 
	@Name NATIONAL CHARACTER VARYING(80) 
)
AS
	UPDATE Orienteering.Map
SET Name = @Name
	WHERE Name = @old_Name
GO


CREATE PROCEDURE Orienteering.UpdateMapAccessibility
(
	@old_Name NATIONAL CHARACTER VARYING(80) , 
	@Accessibility NATIONAL CHARACTER(1) 
)
AS
	UPDATE Orienteering.Map
SET Accessibility = @Accessibility
	WHERE Name = @old_Name
GO


CREATE PROCEDURE Orienteering.UpdateMapClub_Code
(
	@old_Name NATIONAL CHARACTER VARYING(80) , 
	@Club_Code NATIONAL CHARACTER VARYING(6) 
)
AS
	UPDATE Orienteering.Map
SET Club_Code = @Club_Code
	WHERE Name = @old_Name
GO


CREATE PROCEDURE Orienteering.InsertEntrant
(
	@IsTeam BIT , 
	@EntrantID BIGINT , 
	@GivenName NATIONAL CHARACTER VARYING(48) , 
	@Competitor_FamilyName NATIONAL CHARACTER VARYING(48) , 
	@Competitor_Gender NATIONAL CHARACTER(1) , 
	@Competitor_BirthYear BIGINT , 
	@Competitor_EntrantPostCode BIGINT , 
	@Club_Code NATIONAL CHARACTER VARYING(6) 
)
AS
	INSERT INTO Orienteering.Entrant(IsTeam, EntrantID, GivenName, Competitor_FamilyName, Competitor_Gender, Competitor_BirthYear, Competitor_EntrantPostCode, Club_Code)
	VALUES (@IsTeam, @EntrantID, @GivenName, @Competitor_FamilyName, @Competitor_Gender, @Competitor_BirthYear, @Competitor_EntrantPostCode, @Club_Code)
GO


CREATE PROCEDURE Orienteering.DeleteEntrant
(
	@EntrantID BIGINT 
)
AS
	DELETE FROM Orienteering.Entrant
	WHERE EntrantID = @EntrantID
GO


CREATE PROCEDURE Orienteering.UpdateEntrantIsTeam
(
	@old_EntrantID BIGINT , 
	@IsTeam BIT 
)
AS
	UPDATE Orienteering.Entrant
SET IsTeam = @IsTeam
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE Orienteering.UpdateEntrantGivenName
(
	@old_EntrantID BIGINT , 
	@GivenName NATIONAL CHARACTER VARYING(48) 
)
AS
	UPDATE Orienteering.Entrant
SET GivenName = @GivenName
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE Orienteering.UpdtEntrntCmpttr_FmlyNm
(
	@old_EntrantID BIGINT , 
	@Competitor_FamilyName NATIONAL CHARACTER VARYING(48) 
)
AS
	UPDATE Orienteering.Entrant
SET Competitor_FamilyName = @Competitor_FamilyName
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE Orienteering.UpdateEntrantCompetitor_Gender
(
	@old_EntrantID BIGINT , 
	@Competitor_Gender NATIONAL CHARACTER(1) 
)
AS
	UPDATE Orienteering.Entrant
SET Competitor_Gender = @Competitor_Gender
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE Orienteering.UpdtEntrntCmpttr_BrthYr
(
	@old_EntrantID BIGINT , 
	@Competitor_BirthYear BIGINT 
)
AS
	UPDATE Orienteering.Entrant
SET Competitor_BirthYear = @Competitor_BirthYear
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE Orienteering.UpdtEntrntCmpttr_EntrntPstCd
(
	@old_EntrantID BIGINT , 
	@Competitor_EntrantPostCode BIGINT 
)
AS
	UPDATE Orienteering.Entrant
SET Competitor_EntrantPostCode = @Competitor_EntrantPostCode
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE Orienteering.UpdateEntrantClub_Code
(
	@old_EntrantID BIGINT , 
	@Club_Code NATIONAL CHARACTER VARYING(6) 
)
AS
	UPDATE Orienteering.Entrant
SET Club_Code = @Club_Code
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE Orienteering.InsertTeamMember
(
	@EventCourse_ID BIGINT , 
	@EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@Competitor_EntrantID BIGINT , 
	@Team_EntrantID BIGINT 
)
AS
	INSERT INTO Orienteering.TeamMember(EventCourse_ID, EventCourse_Course, Competitor_EntrantID, Team_EntrantID)
	VALUES (@EventCourse_ID, @EventCourse_Course, @Competitor_EntrantID, @Team_EntrantID)
GO


CREATE PROCEDURE Orienteering.DeleteTeamMember
(
	@EventCourse_ID BIGINT , 
	@EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@Competitor_EntrantID BIGINT 
)
AS
	DELETE FROM Orienteering.TeamMember
	WHERE EventCourse_ID = @EventCourse_ID AND 
EventCourse_Course = @EventCourse_Course AND 
Competitor_EntrantID = @Competitor_EntrantID
GO


CREATE PROCEDURE Orienteering.UpdateTeamMemberEventCourse_ID
(
	@old_EventCourse_ID BIGINT , 
	@old_EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@old_Competitor_EntrantID BIGINT , 
	@EventCourse_ID BIGINT 
)
AS
	UPDATE Orienteering.TeamMember
SET EventCourse_ID = @EventCourse_ID
	WHERE EventCourse_ID = @old_EventCourse_ID AND 
EventCourse_Course = @old_EventCourse_Course AND 
Competitor_EntrantID = @old_Competitor_EntrantID
GO


CREATE PROCEDURE Orienteering.UpdtTmMmbrEvntCrs_Crs
(
	@old_EventCourse_ID BIGINT , 
	@old_EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@old_Competitor_EntrantID BIGINT , 
	@EventCourse_Course NATIONAL CHARACTER VARYING(16) 
)
AS
	UPDATE Orienteering.TeamMember
SET EventCourse_Course = @EventCourse_Course
	WHERE EventCourse_ID = @old_EventCourse_ID AND 
EventCourse_Course = @old_EventCourse_Course AND 
Competitor_EntrantID = @old_Competitor_EntrantID
GO


CREATE PROCEDURE Orienteering.UpdtTmMmbrCmpttr_EntrntID
(
	@old_EventCourse_ID BIGINT , 
	@old_EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@old_Competitor_EntrantID BIGINT , 
	@Competitor_EntrantID BIGINT 
)
AS
	UPDATE Orienteering.TeamMember
SET Competitor_EntrantID = @Competitor_EntrantID
	WHERE EventCourse_ID = @old_EventCourse_ID AND 
EventCourse_Course = @old_EventCourse_Course AND 
Competitor_EntrantID = @old_Competitor_EntrantID
GO


CREATE PROCEDURE Orienteering.UpdateTeamMemberTeam_EntrantID
(
	@old_EventCourse_ID BIGINT , 
	@old_EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@old_Competitor_EntrantID BIGINT , 
	@Team_EntrantID BIGINT 
)
AS
	UPDATE Orienteering.TeamMember
SET Team_EntrantID = @Team_EntrantID
	WHERE EventCourse_ID = @old_EventCourse_ID AND 
EventCourse_Course = @old_EventCourse_Course AND 
Competitor_EntrantID = @old_Competitor_EntrantID
GO


CREATE PROCEDURE Orienteering.InsertPunchPlacement
(
	@Punch_PunchID BIGINT , 
	@EventControl_ID BIGINT , 
	@EventControl_Control BIGINT , 
	@Event_ID BIGINT 
)
AS
	INSERT INTO Orienteering.PunchPlacement(Punch_PunchID, EventControl_ID, EventControl_Control, Event_ID)
	VALUES (@Punch_PunchID, @EventControl_ID, @EventControl_Control, @Event_ID)
GO


CREATE PROCEDURE Orienteering.DeletePunchPlacement
(
	@Punch_PunchID BIGINT , 
	@Event_ID BIGINT 
)
AS
	DELETE FROM Orienteering.PunchPlacement
	WHERE Punch_PunchID = @Punch_PunchID AND 
Event_ID = @Event_ID
GO


CREATE PROCEDURE Orienteering.UpdtPnchPlcmntPnch_PnchID
(
	@old_Punch_PunchID BIGINT , 
	@old_Event_ID BIGINT , 
	@Punch_PunchID BIGINT 
)
AS
	UPDATE Orienteering.PunchPlacement
SET Punch_PunchID = @Punch_PunchID
	WHERE Punch_PunchID = @old_Punch_PunchID AND 
Event_ID = @old_Event_ID
GO


CREATE PROCEDURE Orienteering.UpdtPnchPlcmntEvntCntrl_ID
(
	@old_Punch_PunchID BIGINT , 
	@old_Event_ID BIGINT , 
	@EventControl_ID BIGINT 
)
AS
	UPDATE Orienteering.PunchPlacement
SET EventControl_ID = @EventControl_ID
	WHERE Punch_PunchID = @old_Punch_PunchID AND 
Event_ID = @old_Event_ID
GO


CREATE PROCEDURE Orienteering.UpdtPnchPlcmntEvntCntrl_Cntrl
(
	@old_Punch_PunchID BIGINT , 
	@old_Event_ID BIGINT , 
	@EventControl_Control BIGINT 
)
AS
	UPDATE Orienteering.PunchPlacement
SET EventControl_Control = @EventControl_Control
	WHERE Punch_PunchID = @old_Punch_PunchID AND 
Event_ID = @old_Event_ID
GO


CREATE PROCEDURE Orienteering.UpdatePunchPlacementEvent_ID
(
	@old_Punch_PunchID BIGINT , 
	@old_Event_ID BIGINT , 
	@Event_ID BIGINT 
)
AS
	UPDATE Orienteering.PunchPlacement
SET Event_ID = @Event_ID
	WHERE Punch_PunchID = @old_Punch_PunchID AND 
Event_ID = @old_Event_ID
GO


CREATE PROCEDURE Orienteering.InsertEventControl
(
	@Control BIGINT , 
	@Points BIGINT , 
	@Event_ID BIGINT 
)
AS
	INSERT INTO Orienteering.EventControl(Control, Points, Event_ID)
	VALUES (@Control, @Points, @Event_ID)
GO


CREATE PROCEDURE Orienteering.DeleteEventControl
(
	@Event_ID BIGINT , 
	@Control BIGINT 
)
AS
	DELETE FROM Orienteering.EventControl
	WHERE Event_ID = @Event_ID AND 
Control = @Control
GO


CREATE PROCEDURE Orienteering.UpdateEventControlControl
(
	@old_Event_ID BIGINT , 
	@old_Control BIGINT , 
	@Control BIGINT 
)
AS
	UPDATE Orienteering.EventControl
SET Control = @Control
	WHERE Event_ID = @old_Event_ID AND 
Control = @old_Control
GO


CREATE PROCEDURE Orienteering.UpdateEventControlPoints
(
	@old_Event_ID BIGINT , 
	@old_Control BIGINT , 
	@Points BIGINT 
)
AS
	UPDATE Orienteering.EventControl
SET Points = @Points
	WHERE Event_ID = @old_Event_ID AND 
Control = @old_Control
GO


CREATE PROCEDURE Orienteering.UpdateEventControlEvent_ID
(
	@old_Event_ID BIGINT , 
	@old_Control BIGINT , 
	@Event_ID BIGINT 
)
AS
	UPDATE Orienteering.EventControl
SET Event_ID = @Event_ID
	WHERE Event_ID = @old_Event_ID AND 
Control = @old_Control
GO


CREATE PROCEDURE Orienteering.InsertEventCourse
(
	@ScoringMethod NATIONAL CHARACTER VARYING(32) , 
	@Course NATIONAL CHARACTER VARYING(16) , 
	@Individual BIT , 
	@Event_ID BIGINT 
)
AS
	INSERT INTO Orienteering.EventCourse(ScoringMethod, Course, Individual, Event_ID)
	VALUES (@ScoringMethod, @Course, @Individual, @Event_ID)
GO


CREATE PROCEDURE Orienteering.DeleteEventCourse
(
	@Event_ID BIGINT , 
	@Course NATIONAL CHARACTER VARYING(16) 
)
AS
	DELETE FROM Orienteering.EventCourse
	WHERE Event_ID = @Event_ID AND 
Course = @Course
GO


CREATE PROCEDURE Orienteering.UpdateEventCourseScoringMethod
(
	@old_Event_ID BIGINT , 
	@old_Course NATIONAL CHARACTER VARYING(16) , 
	@ScoringMethod NATIONAL CHARACTER VARYING(32) 
)
AS
	UPDATE Orienteering.EventCourse
SET ScoringMethod = @ScoringMethod
	WHERE Event_ID = @old_Event_ID AND 
Course = @old_Course
GO


CREATE PROCEDURE Orienteering.UpdateEventCourseCourse
(
	@old_Event_ID BIGINT , 
	@old_Course NATIONAL CHARACTER VARYING(16) , 
	@Course NATIONAL CHARACTER VARYING(16) 
)
AS
	UPDATE Orienteering.EventCourse
SET Course = @Course
	WHERE Event_ID = @old_Event_ID AND 
Course = @old_Course
GO


CREATE PROCEDURE Orienteering.UpdateEventCourseIndividual
(
	@old_Event_ID BIGINT , 
	@old_Course NATIONAL CHARACTER VARYING(16) , 
	@Individual BIT 
)
AS
	UPDATE Orienteering.EventCourse
SET Individual = @Individual
	WHERE Event_ID = @old_Event_ID AND 
Course = @old_Course
GO


CREATE PROCEDURE Orienteering.UpdateEventCourseEvent_ID
(
	@old_Event_ID BIGINT , 
	@old_Course NATIONAL CHARACTER VARYING(16) , 
	@Event_ID BIGINT 
)
AS
	UPDATE Orienteering.EventCourse
SET Event_ID = @Event_ID
	WHERE Event_ID = @old_Event_ID AND 
Course = @old_Course
GO


CREATE PROCEDURE Orienteering.InsertEntry
(
	@Score BIGINT , 
	@EntryID BIGINT , 
	@EventCourse_ID BIGINT , 
	@EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@Entrant_EntrantID BIGINT 
)
AS
	INSERT INTO Orienteering.Entry(Score, EntryID, EventCourse_ID, EventCourse_Course, Entrant_EntrantID)
	VALUES (@Score, @EntryID, @EventCourse_ID, @EventCourse_Course, @Entrant_EntrantID)
GO


CREATE PROCEDURE Orienteering.DeleteEntry
(
	@EntryID BIGINT 
)
AS
	DELETE FROM Orienteering.Entry
	WHERE EntryID = @EntryID
GO


CREATE PROCEDURE Orienteering.UpdateEntryScore
(
	@old_EntryID BIGINT , 
	@Score BIGINT 
)
AS
	UPDATE Orienteering.Entry
SET Score = @Score
	WHERE EntryID = @old_EntryID
GO


CREATE PROCEDURE Orienteering.UpdateEntryEventCourse_ID
(
	@old_EntryID BIGINT , 
	@EventCourse_ID BIGINT 
)
AS
	UPDATE Orienteering.Entry
SET EventCourse_ID = @EventCourse_ID
	WHERE EntryID = @old_EntryID
GO


CREATE PROCEDURE Orienteering.UpdateEntryEventCourse_Course
(
	@old_EntryID BIGINT , 
	@EventCourse_Course NATIONAL CHARACTER VARYING(16) 
)
AS
	UPDATE Orienteering.Entry
SET EventCourse_Course = @EventCourse_Course
	WHERE EntryID = @old_EntryID
GO


CREATE PROCEDURE Orienteering.UpdateEntryEntrant_EntrantID
(
	@old_EntryID BIGINT , 
	@Entrant_EntrantID BIGINT 
)
AS
	UPDATE Orienteering.Entry
SET Entrant_EntrantID = @Entrant_EntrantID
	WHERE EntryID = @old_EntryID
GO


CREATE PROCEDURE Orienteering.InsertSeriesEvent
(
	@Number BIGINT , 
	@Series_SeriesName NATIONAL CHARACTER VARYING(40) , 
	@Event_ID BIGINT 
)
AS
	INSERT INTO Orienteering.SeriesEvent(Number, Series_SeriesName, Event_ID)
	VALUES (@Number, @Series_SeriesName, @Event_ID)
GO


CREATE PROCEDURE Orienteering.DeleteSeriesEvent
(
	@Number BIGINT , 
	@Series_SeriesName NATIONAL CHARACTER VARYING(40) 
)
AS
	DELETE FROM Orienteering.SeriesEvent
	WHERE Number = @Number AND 
Series_SeriesName = @Series_SeriesName
GO


CREATE PROCEDURE Orienteering.UpdateSeriesEventNumber
(
	@old_Number BIGINT , 
	@old_Series_SeriesName NATIONAL CHARACTER VARYING(40) , 
	@Number BIGINT 
)
AS
	UPDATE Orienteering.SeriesEvent
SET Number = @Number
	WHERE Number = @old_Number AND 
Series_SeriesName = @old_Series_SeriesName
GO


CREATE PROCEDURE Orienteering.UpdtSrsEvntSrs_SrsNm
(
	@old_Number BIGINT , 
	@old_Series_SeriesName NATIONAL CHARACTER VARYING(40) , 
	@Series_SeriesName NATIONAL CHARACTER VARYING(40) 
)
AS
	UPDATE Orienteering.SeriesEvent
SET Series_SeriesName = @Series_SeriesName
	WHERE Number = @old_Number AND 
Series_SeriesName = @old_Series_SeriesName
GO


CREATE PROCEDURE Orienteering.UpdateSeriesEventEvent_ID
(
	@old_Number BIGINT , 
	@old_Series_SeriesName NATIONAL CHARACTER VARYING(40) , 
	@Event_ID BIGINT 
)
AS
	UPDATE Orienteering.SeriesEvent
SET Event_ID = @Event_ID
	WHERE Number = @old_Number AND 
Series_SeriesName = @old_Series_SeriesName
GO


GO