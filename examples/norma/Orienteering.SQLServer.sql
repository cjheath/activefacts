
CREATE TABLE Event
(
	EventName NATIONAL CHARACTER VARYING(50) , 
	StartLocation NATIONAL CHARACTER VARYING(200) NOT NULL, 
	ID BIGINT NOT NULL, 
	"Date" BIGINT NOT NULL, 
	RunByClub_Code NATIONAL CHARACTER VARYING(6) NOT NULL, 
	Map_Name NATIONAL CHARACTER VARYING(80) NOT NULL, 
	CONSTRAINT EventNameIsOfOneEvent UNIQUE(EventName), 
	CONSTRAINT EventIDIsOfOneEvent PRIMARY KEY(ID)
)
GO


CREATE TABLE Club
(
	ClubName NATIONAL CHARACTER VARYING(32) NOT NULL, 
	Code NATIONAL CHARACTER VARYING(6) NOT NULL, 
	CONSTRAINT ClubNameIsOfOneClub UNIQUE(ClubName), 
	CONSTRAINT ClubCodeIsOfOneClub PRIMARY KEY(Code)
)
GO


CREATE TABLE Map
(
	Name NATIONAL CHARACTER VARYING(80) NOT NULL, 
	Accessibility NATIONAL CHARACTER(1) CONSTRAINT Accessibility_Chk CHECK ((LEN(LTRIM(RTRIM(Accessibility)))) >= 1) , 
	Owner_Code NATIONAL CHARACTER VARYING(6) , 
	CONSTRAINT NameIsOfOneMap PRIMARY KEY(Name)
)
GO


CREATE TABLE Entrant
(
	IsTeam BIT NOT NULL, 
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


CREATE TABLE TeamMember
(
	EventCourse_ID BIGINT NOT NULL, 
	EventCourse_Course NATIONAL CHARACTER VARYING(16) CONSTRAINT Course_Chk CHECK (EventCourse_Course IN ('PW')) NOT NULL, 
	Competitor_EntrantID BIGINT NOT NULL, 
	Team_EntrantID BIGINT NOT NULL, 
	CONSTRAINT TeamLoyalty PRIMARY KEY(EventCourse_ID, EventCourse_Course, Competitor_EntrantID)
)
GO


CREATE TABLE Visit
(
	"Time" BIGINT NOT NULL, 
	Checked BIT NOT NULL, 
	EventControl_ID BIGINT NOT NULL, 
	EventControl_Control BIGINT CONSTRAINT Control_Chk CHECK (EventControl_Control BETWEEN 1 AND 1000) NOT NULL, 
	Entrant_EntrantID BIGINT NOT NULL, 
	CONSTRAINT EntrntVstdEchCntrlAtEchTmOnc PRIMARY KEY(EventControl_ID, EventControl_Control, Entrant_EntrantID, "Time")
)
GO


CREATE TABLE PunchPlacement
(
	Punch_PunchID BIGINT NOT NULL, 
	EventControl_ID BIGINT NOT NULL, 
	EventControl_Control BIGINT CONSTRAINT Control_Chk2 CHECK (EventControl_Control BETWEEN 1 AND 1000) NOT NULL, 
	Event_ID BIGINT NOT NULL, 
	CONSTRAINT PunchIsAtOneEventControl PRIMARY KEY(Punch_PunchID, Event_ID)
)
GO


CREATE TABLE EventControl
(
	Control BIGINT CONSTRAINT Control_Chk3 CHECK (Control BETWEEN 1 AND 1000) NOT NULL, 
	Points BIGINT , 
	Event_ID BIGINT NOT NULL, 
	CONSTRAINT EventHasEachControlOnce PRIMARY KEY(Event_ID, Control)
)
GO


CREATE TABLE EventCourse
(
	ScoringMethod NATIONAL CHARACTER VARYING(32) CONSTRAINT ScoringMethod_Chk CHECK (ScoringMethod IN ('Score', 'Scatter', 'Special')) , 
	Course NATIONAL CHARACTER VARYING(16) CONSTRAINT Course_Chk2 CHECK (Course IN ('PW')) NOT NULL, 
	Individual BIT NOT NULL, 
	Event_ID BIGINT NOT NULL, 
	CONSTRAINT EventIncludesEachCourseOnce PRIMARY KEY(Event_ID, Course)
)
GO


CREATE TABLE Entry
(
	Score BIGINT , 
	EntryID BIGINT IDENTITY (1, 1) NOT NULL, 
	FinishOrder BIGINT , 
	EventCourse_ID BIGINT NOT NULL, 
	EventCourse_Course NATIONAL CHARACTER VARYING(16) CONSTRAINT Course_Chk3 CHECK (EventCourse_Course IN ('PW')) NOT NULL, 
	Entrant_EntrantID BIGINT NOT NULL, 
	CONSTRAINT EntryIDIsOfOneEntry PRIMARY KEY(EntryID), 
	CONSTRAINT EntryIsForEventCourseOnce UNIQUE(Entrant_EntrantID, EventCourse_ID, EventCourse_Course)
)
GO


CREATE TABLE SeriesEvent
(
	Number BIGINT CONSTRAINT Number_Chk CHECK (Number BETWEEN 1 AND 100) NOT NULL, 
	Series_SeriesName NATIONAL CHARACTER VARYING(40) NOT NULL, 
	Event_ID BIGINT NOT NULL, 
	CONSTRAINT SeriesNumberIsOfOneEvent PRIMARY KEY(Number, Series_SeriesName)
)
GO


ALTER TABLE Event ADD CONSTRAINT Event_RunByClub_FK FOREIGN KEY (RunByClub_Code)  REFERENCES Club (Code)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Event ADD CONSTRAINT Event_Map_FK FOREIGN KEY (Map_Name)  REFERENCES Map (Name)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Map ADD CONSTRAINT Map_Owner_FK FOREIGN KEY (Owner_Code)  REFERENCES Club (Code)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Entrant ADD CONSTRAINT Entrant_MemberOfClub_FK FOREIGN KEY (MemberOfClub_Code)  REFERENCES Club (Code)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE TeamMember ADD CONSTRAINT TeamMember_EventCourse_FK FOREIGN KEY (EventCourse_ID, EventCourse_Course)  REFERENCES EventCourse (Event_ID, Course)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE TeamMember ADD CONSTRAINT TeamMember_Competitor_FK FOREIGN KEY (Competitor_EntrantID)  REFERENCES Entrant (EntrantID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE TeamMember ADD CONSTRAINT TeamMember_Team_FK FOREIGN KEY (Team_EntrantID)  REFERENCES Entrant (EntrantID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Visit ADD CONSTRAINT Visit_EventControl_FK FOREIGN KEY (EventControl_ID, EventControl_Control)  REFERENCES EventControl (Event_ID, Control)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Visit ADD CONSTRAINT Visit_Entrant_FK FOREIGN KEY (Entrant_EntrantID)  REFERENCES Entrant (EntrantID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE PunchPlacement ADD CONSTRAINT PunchPlacement_EventControl_FK FOREIGN KEY (EventControl_ID, EventControl_Control)  REFERENCES EventControl (Event_ID, Control)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE PunchPlacement ADD CONSTRAINT PunchPlacement_Event_FK FOREIGN KEY (Event_ID)  REFERENCES Event (ID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE EventControl ADD CONSTRAINT EventControl_Event_FK FOREIGN KEY (Event_ID)  REFERENCES Event (ID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE EventCourse ADD CONSTRAINT EventCourse_Event_FK FOREIGN KEY (Event_ID)  REFERENCES Event (ID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Entry ADD CONSTRAINT Entry_EventCourse_FK FOREIGN KEY (EventCourse_ID, EventCourse_Course)  REFERENCES EventCourse (Event_ID, Course)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Entry ADD CONSTRAINT Entry_Entrant_FK FOREIGN KEY (Entrant_EntrantID)  REFERENCES Entrant (EntrantID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE SeriesEvent ADD CONSTRAINT SeriesEvent_Event_FK FOREIGN KEY (Event_ID)  REFERENCES Event (ID)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO



CREATE PROCEDURE InsertEvent
(
	@EventName NATIONAL CHARACTER VARYING(50) , 
	@StartLocation NATIONAL CHARACTER VARYING(200) , 
	@ID BIGINT , 
	@"Date" BIGINT , 
	@RunByClub_Code NATIONAL CHARACTER VARYING(6) , 
	@Map_Name NATIONAL CHARACTER VARYING(80) 
)
AS
	INSERT INTO Event(EventName, StartLocation, ID, "Date", RunByClub_Code, Map_Name)
	VALUES (@EventName, @StartLocation, @ID, @"Date", @RunByClub_Code, @Map_Name)
GO


CREATE PROCEDURE DeleteEvent
(
	@ID BIGINT 
)
AS
	DELETE FROM Event
	WHERE ID = @ID
GO


CREATE PROCEDURE UpdateEventEventName
(
	@old_ID BIGINT , 
	@EventName NATIONAL CHARACTER VARYING(50) 
)
AS
	UPDATE Event
SET EventName = @EventName
	WHERE ID = @old_ID
GO


CREATE PROCEDURE UpdateEventStartLocation
(
	@old_ID BIGINT , 
	@StartLocation NATIONAL CHARACTER VARYING(200) 
)
AS
	UPDATE Event
SET StartLocation = @StartLocation
	WHERE ID = @old_ID
GO


CREATE PROCEDURE UpdateEventID
(
	@old_ID BIGINT , 
	@ID BIGINT 
)
AS
	UPDATE Event
SET ID = @ID
	WHERE ID = @old_ID
GO


CREATE PROCEDURE "UpdateEvent""Date"""
(
	@old_ID BIGINT , 
	@"Date" BIGINT 
)
AS
	UPDATE Event
SET "Date" = @"Date"
	WHERE ID = @old_ID
GO


CREATE PROCEDURE UpdateEventRunByClub_Code
(
	@old_ID BIGINT , 
	@RunByClub_Code NATIONAL CHARACTER VARYING(6) 
)
AS
	UPDATE Event
SET RunByClub_Code = @RunByClub_Code
	WHERE ID = @old_ID
GO


CREATE PROCEDURE UpdateEventMap_Name
(
	@old_ID BIGINT , 
	@Map_Name NATIONAL CHARACTER VARYING(80) 
)
AS
	UPDATE Event
SET Map_Name = @Map_Name
	WHERE ID = @old_ID
GO


CREATE PROCEDURE InsertClub
(
	@ClubName NATIONAL CHARACTER VARYING(32) , 
	@Code NATIONAL CHARACTER VARYING(6) 
)
AS
	INSERT INTO Club(ClubName, Code)
	VALUES (@ClubName, @Code)
GO


CREATE PROCEDURE DeleteClub
(
	@Code NATIONAL CHARACTER VARYING(6) 
)
AS
	DELETE FROM Club
	WHERE Code = @Code
GO


CREATE PROCEDURE UpdateClubClubName
(
	@old_Code NATIONAL CHARACTER VARYING(6) , 
	@ClubName NATIONAL CHARACTER VARYING(32) 
)
AS
	UPDATE Club
SET ClubName = @ClubName
	WHERE Code = @old_Code
GO


CREATE PROCEDURE UpdateClubCode
(
	@old_Code NATIONAL CHARACTER VARYING(6) , 
	@Code NATIONAL CHARACTER VARYING(6) 
)
AS
	UPDATE Club
SET Code = @Code
	WHERE Code = @old_Code
GO


CREATE PROCEDURE InsertMap
(
	@Name NATIONAL CHARACTER VARYING(80) , 
	@Accessibility NATIONAL CHARACTER(1) , 
	@Owner_Code NATIONAL CHARACTER VARYING(6) 
)
AS
	INSERT INTO Map(Name, Accessibility, Owner_Code)
	VALUES (@Name, @Accessibility, @Owner_Code)
GO


CREATE PROCEDURE DeleteMap
(
	@Name NATIONAL CHARACTER VARYING(80) 
)
AS
	DELETE FROM Map
	WHERE Name = @Name
GO


CREATE PROCEDURE UpdateMapName
(
	@old_Name NATIONAL CHARACTER VARYING(80) , 
	@Name NATIONAL CHARACTER VARYING(80) 
)
AS
	UPDATE Map
SET Name = @Name
	WHERE Name = @old_Name
GO


CREATE PROCEDURE UpdateMapAccessibility
(
	@old_Name NATIONAL CHARACTER VARYING(80) , 
	@Accessibility NATIONAL CHARACTER(1) 
)
AS
	UPDATE Map
SET Accessibility = @Accessibility
	WHERE Name = @old_Name
GO


CREATE PROCEDURE UpdateMapOwner_Code
(
	@old_Name NATIONAL CHARACTER VARYING(80) , 
	@Owner_Code NATIONAL CHARACTER VARYING(6) 
)
AS
	UPDATE Map
SET Owner_Code = @Owner_Code
	WHERE Name = @old_Name
GO


CREATE PROCEDURE InsertEntrant
(
	@IsTeam BIT , 
	@EntrantID BIGINT , 
	@GivenName NATIONAL CHARACTER VARYING(48) , 
	@Competitor_FamilyName NATIONAL CHARACTER VARYING(48) , 
	@Competitor_Gender NATIONAL CHARACTER(1) , 
	@Competitor_BirthYear BIGINT , 
	@Competitor_PostCode BIGINT , 
	@MemberOfClub_Code NATIONAL CHARACTER VARYING(6) 
)
AS
	INSERT INTO Entrant(IsTeam, EntrantID, GivenName, Competitor_FamilyName, Competitor_Gender, Competitor_BirthYear, Competitor_PostCode, MemberOfClub_Code)
	VALUES (@IsTeam, @EntrantID, @GivenName, @Competitor_FamilyName, @Competitor_Gender, @Competitor_BirthYear, @Competitor_PostCode, @MemberOfClub_Code)
GO


CREATE PROCEDURE DeleteEntrant
(
	@EntrantID BIGINT 
)
AS
	DELETE FROM Entrant
	WHERE EntrantID = @EntrantID
GO


CREATE PROCEDURE UpdateEntrantIsTeam
(
	@old_EntrantID BIGINT , 
	@IsTeam BIT 
)
AS
	UPDATE Entrant
SET IsTeam = @IsTeam
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE UpdateEntrantGivenName
(
	@old_EntrantID BIGINT , 
	@GivenName NATIONAL CHARACTER VARYING(48) 
)
AS
	UPDATE Entrant
SET GivenName = @GivenName
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE UpdtEntrntCmpttr_FmlyNm
(
	@old_EntrantID BIGINT , 
	@Competitor_FamilyName NATIONAL CHARACTER VARYING(48) 
)
AS
	UPDATE Entrant
SET Competitor_FamilyName = @Competitor_FamilyName
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE UpdateEntrantCompetitor_Gender
(
	@old_EntrantID BIGINT , 
	@Competitor_Gender NATIONAL CHARACTER(1) 
)
AS
	UPDATE Entrant
SET Competitor_Gender = @Competitor_Gender
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE UpdtEntrntCmpttr_BrthYr
(
	@old_EntrantID BIGINT , 
	@Competitor_BirthYear BIGINT 
)
AS
	UPDATE Entrant
SET Competitor_BirthYear = @Competitor_BirthYear
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE UpdtEntrntCmpttr_PstCd
(
	@old_EntrantID BIGINT , 
	@Competitor_PostCode BIGINT 
)
AS
	UPDATE Entrant
SET Competitor_PostCode = @Competitor_PostCode
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE UpdateEntrantMemberOfClub_Code
(
	@old_EntrantID BIGINT , 
	@MemberOfClub_Code NATIONAL CHARACTER VARYING(6) 
)
AS
	UPDATE Entrant
SET MemberOfClub_Code = @MemberOfClub_Code
	WHERE EntrantID = @old_EntrantID
GO


CREATE PROCEDURE InsertTeamMember
(
	@EventCourse_ID BIGINT , 
	@EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@Competitor_EntrantID BIGINT , 
	@Team_EntrantID BIGINT 
)
AS
	INSERT INTO TeamMember(EventCourse_ID, EventCourse_Course, Competitor_EntrantID, Team_EntrantID)
	VALUES (@EventCourse_ID, @EventCourse_Course, @Competitor_EntrantID, @Team_EntrantID)
GO


CREATE PROCEDURE DeleteTeamMember
(
	@EventCourse_ID BIGINT , 
	@EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@Competitor_EntrantID BIGINT 
)
AS
	DELETE FROM TeamMember
	WHERE EventCourse_ID = @EventCourse_ID AND 
EventCourse_Course = @EventCourse_Course AND 
Competitor_EntrantID = @Competitor_EntrantID
GO


CREATE PROCEDURE UpdateTeamMemberEventCourse_ID
(
	@old_EventCourse_ID BIGINT , 
	@old_EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@old_Competitor_EntrantID BIGINT , 
	@EventCourse_ID BIGINT 
)
AS
	UPDATE TeamMember
SET EventCourse_ID = @EventCourse_ID
	WHERE EventCourse_ID = @old_EventCourse_ID AND 
EventCourse_Course = @old_EventCourse_Course AND 
Competitor_EntrantID = @old_Competitor_EntrantID
GO


CREATE PROCEDURE UpdtTmMmbrEvntCrs_Crs
(
	@old_EventCourse_ID BIGINT , 
	@old_EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@old_Competitor_EntrantID BIGINT , 
	@EventCourse_Course NATIONAL CHARACTER VARYING(16) 
)
AS
	UPDATE TeamMember
SET EventCourse_Course = @EventCourse_Course
	WHERE EventCourse_ID = @old_EventCourse_ID AND 
EventCourse_Course = @old_EventCourse_Course AND 
Competitor_EntrantID = @old_Competitor_EntrantID
GO


CREATE PROCEDURE UpdtTmMmbrCmpttr_EntrntID
(
	@old_EventCourse_ID BIGINT , 
	@old_EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@old_Competitor_EntrantID BIGINT , 
	@Competitor_EntrantID BIGINT 
)
AS
	UPDATE TeamMember
SET Competitor_EntrantID = @Competitor_EntrantID
	WHERE EventCourse_ID = @old_EventCourse_ID AND 
EventCourse_Course = @old_EventCourse_Course AND 
Competitor_EntrantID = @old_Competitor_EntrantID
GO


CREATE PROCEDURE UpdateTeamMemberTeam_EntrantID
(
	@old_EventCourse_ID BIGINT , 
	@old_EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@old_Competitor_EntrantID BIGINT , 
	@Team_EntrantID BIGINT 
)
AS
	UPDATE TeamMember
SET Team_EntrantID = @Team_EntrantID
	WHERE EventCourse_ID = @old_EventCourse_ID AND 
EventCourse_Course = @old_EventCourse_Course AND 
Competitor_EntrantID = @old_Competitor_EntrantID
GO


CREATE PROCEDURE InsertVisit
(
	@"Time" BIGINT , 
	@Checked BIT , 
	@EventControl_ID BIGINT , 
	@EventControl_Control BIGINT , 
	@Entrant_EntrantID BIGINT 
)
AS
	INSERT INTO Visit("Time", Checked, EventControl_ID, EventControl_Control, Entrant_EntrantID)
	VALUES (@"Time", @Checked, @EventControl_ID, @EventControl_Control, @Entrant_EntrantID)
GO


CREATE PROCEDURE DeleteVisit
(
	@EventControl_ID BIGINT , 
	@EventControl_Control BIGINT , 
	@Entrant_EntrantID BIGINT , 
	@"Time" BIGINT 
)
AS
	DELETE FROM Visit
	WHERE EventControl_ID = @EventControl_ID AND 
EventControl_Control = @EventControl_Control AND 
Entrant_EntrantID = @Entrant_EntrantID AND 
"Time" = @"Time"
GO


CREATE PROCEDURE "UpdateVisit""Time"""
(
	@old_EventControl_ID BIGINT , 
	@old_EventControl_Control BIGINT , 
	@old_Entrant_EntrantID BIGINT , 
	@"old_""Time""" BIGINT , 
	@"Time" BIGINT 
)
AS
	UPDATE Visit
SET "Time" = @"Time"
	WHERE EventControl_ID = @old_EventControl_ID AND 
EventControl_Control = @old_EventControl_Control AND 
Entrant_EntrantID = @old_Entrant_EntrantID AND 
"Time" = @"old_""Time"""
GO


CREATE PROCEDURE UpdateVisitChecked
(
	@old_EventControl_ID BIGINT , 
	@old_EventControl_Control BIGINT , 
	@old_Entrant_EntrantID BIGINT , 
	@"old_""Time""" BIGINT , 
	@Checked BIT 
)
AS
	UPDATE Visit
SET Checked = @Checked
	WHERE EventControl_ID = @old_EventControl_ID AND 
EventControl_Control = @old_EventControl_Control AND 
Entrant_EntrantID = @old_Entrant_EntrantID AND 
"Time" = @"old_""Time"""
GO


CREATE PROCEDURE UpdateVisitEventControl_ID
(
	@old_EventControl_ID BIGINT , 
	@old_EventControl_Control BIGINT , 
	@old_Entrant_EntrantID BIGINT , 
	@"old_""Time""" BIGINT , 
	@EventControl_ID BIGINT 
)
AS
	UPDATE Visit
SET EventControl_ID = @EventControl_ID
	WHERE EventControl_ID = @old_EventControl_ID AND 
EventControl_Control = @old_EventControl_Control AND 
Entrant_EntrantID = @old_Entrant_EntrantID AND 
"Time" = @"old_""Time"""
GO


CREATE PROCEDURE UpdtVstEvntCntrl_Cntrl
(
	@old_EventControl_ID BIGINT , 
	@old_EventControl_Control BIGINT , 
	@old_Entrant_EntrantID BIGINT , 
	@"old_""Time""" BIGINT , 
	@EventControl_Control BIGINT 
)
AS
	UPDATE Visit
SET EventControl_Control = @EventControl_Control
	WHERE EventControl_ID = @old_EventControl_ID AND 
EventControl_Control = @old_EventControl_Control AND 
Entrant_EntrantID = @old_Entrant_EntrantID AND 
"Time" = @"old_""Time"""
GO


CREATE PROCEDURE UpdateVisitEntrant_EntrantID
(
	@old_EventControl_ID BIGINT , 
	@old_EventControl_Control BIGINT , 
	@old_Entrant_EntrantID BIGINT , 
	@"old_""Time""" BIGINT , 
	@Entrant_EntrantID BIGINT 
)
AS
	UPDATE Visit
SET Entrant_EntrantID = @Entrant_EntrantID
	WHERE EventControl_ID = @old_EventControl_ID AND 
EventControl_Control = @old_EventControl_Control AND 
Entrant_EntrantID = @old_Entrant_EntrantID AND 
"Time" = @"old_""Time"""
GO


CREATE PROCEDURE InsertPunchPlacement
(
	@Punch_PunchID BIGINT , 
	@EventControl_ID BIGINT , 
	@EventControl_Control BIGINT , 
	@Event_ID BIGINT 
)
AS
	INSERT INTO PunchPlacement(Punch_PunchID, EventControl_ID, EventControl_Control, Event_ID)
	VALUES (@Punch_PunchID, @EventControl_ID, @EventControl_Control, @Event_ID)
GO


CREATE PROCEDURE DeletePunchPlacement
(
	@Punch_PunchID BIGINT , 
	@Event_ID BIGINT 
)
AS
	DELETE FROM PunchPlacement
	WHERE Punch_PunchID = @Punch_PunchID AND 
Event_ID = @Event_ID
GO


CREATE PROCEDURE UpdtPnchPlcmntPnch_PnchID
(
	@old_Punch_PunchID BIGINT , 
	@old_Event_ID BIGINT , 
	@Punch_PunchID BIGINT 
)
AS
	UPDATE PunchPlacement
SET Punch_PunchID = @Punch_PunchID
	WHERE Punch_PunchID = @old_Punch_PunchID AND 
Event_ID = @old_Event_ID
GO


CREATE PROCEDURE UpdtPnchPlcmntEvntCntrl_ID
(
	@old_Punch_PunchID BIGINT , 
	@old_Event_ID BIGINT , 
	@EventControl_ID BIGINT 
)
AS
	UPDATE PunchPlacement
SET EventControl_ID = @EventControl_ID
	WHERE Punch_PunchID = @old_Punch_PunchID AND 
Event_ID = @old_Event_ID
GO


CREATE PROCEDURE UpdtPnchPlcmntEvntCntrl_Cntrl
(
	@old_Punch_PunchID BIGINT , 
	@old_Event_ID BIGINT , 
	@EventControl_Control BIGINT 
)
AS
	UPDATE PunchPlacement
SET EventControl_Control = @EventControl_Control
	WHERE Punch_PunchID = @old_Punch_PunchID AND 
Event_ID = @old_Event_ID
GO


CREATE PROCEDURE UpdatePunchPlacementEvent_ID
(
	@old_Punch_PunchID BIGINT , 
	@old_Event_ID BIGINT , 
	@Event_ID BIGINT 
)
AS
	UPDATE PunchPlacement
SET Event_ID = @Event_ID
	WHERE Punch_PunchID = @old_Punch_PunchID AND 
Event_ID = @old_Event_ID
GO


CREATE PROCEDURE InsertEventControl
(
	@Control BIGINT , 
	@Points BIGINT , 
	@Event_ID BIGINT 
)
AS
	INSERT INTO EventControl(Control, Points, Event_ID)
	VALUES (@Control, @Points, @Event_ID)
GO


CREATE PROCEDURE DeleteEventControl
(
	@Event_ID BIGINT , 
	@Control BIGINT 
)
AS
	DELETE FROM EventControl
	WHERE Event_ID = @Event_ID AND 
Control = @Control
GO


CREATE PROCEDURE UpdateEventControlControl
(
	@old_Event_ID BIGINT , 
	@old_Control BIGINT , 
	@Control BIGINT 
)
AS
	UPDATE EventControl
SET Control = @Control
	WHERE Event_ID = @old_Event_ID AND 
Control = @old_Control
GO


CREATE PROCEDURE UpdateEventControlPoints
(
	@old_Event_ID BIGINT , 
	@old_Control BIGINT , 
	@Points BIGINT 
)
AS
	UPDATE EventControl
SET Points = @Points
	WHERE Event_ID = @old_Event_ID AND 
Control = @old_Control
GO


CREATE PROCEDURE UpdateEventControlEvent_ID
(
	@old_Event_ID BIGINT , 
	@old_Control BIGINT , 
	@Event_ID BIGINT 
)
AS
	UPDATE EventControl
SET Event_ID = @Event_ID
	WHERE Event_ID = @old_Event_ID AND 
Control = @old_Control
GO


CREATE PROCEDURE InsertEventCourse
(
	@ScoringMethod NATIONAL CHARACTER VARYING(32) , 
	@Course NATIONAL CHARACTER VARYING(16) , 
	@Individual BIT , 
	@Event_ID BIGINT 
)
AS
	INSERT INTO EventCourse(ScoringMethod, Course, Individual, Event_ID)
	VALUES (@ScoringMethod, @Course, @Individual, @Event_ID)
GO


CREATE PROCEDURE DeleteEventCourse
(
	@Event_ID BIGINT , 
	@Course NATIONAL CHARACTER VARYING(16) 
)
AS
	DELETE FROM EventCourse
	WHERE Event_ID = @Event_ID AND 
Course = @Course
GO


CREATE PROCEDURE UpdateEventCourseScoringMethod
(
	@old_Event_ID BIGINT , 
	@old_Course NATIONAL CHARACTER VARYING(16) , 
	@ScoringMethod NATIONAL CHARACTER VARYING(32) 
)
AS
	UPDATE EventCourse
SET ScoringMethod = @ScoringMethod
	WHERE Event_ID = @old_Event_ID AND 
Course = @old_Course
GO


CREATE PROCEDURE UpdateEventCourseCourse
(
	@old_Event_ID BIGINT , 
	@old_Course NATIONAL CHARACTER VARYING(16) , 
	@Course NATIONAL CHARACTER VARYING(16) 
)
AS
	UPDATE EventCourse
SET Course = @Course
	WHERE Event_ID = @old_Event_ID AND 
Course = @old_Course
GO


CREATE PROCEDURE UpdateEventCourseIndividual
(
	@old_Event_ID BIGINT , 
	@old_Course NATIONAL CHARACTER VARYING(16) , 
	@Individual BIT 
)
AS
	UPDATE EventCourse
SET Individual = @Individual
	WHERE Event_ID = @old_Event_ID AND 
Course = @old_Course
GO


CREATE PROCEDURE UpdateEventCourseEvent_ID
(
	@old_Event_ID BIGINT , 
	@old_Course NATIONAL CHARACTER VARYING(16) , 
	@Event_ID BIGINT 
)
AS
	UPDATE EventCourse
SET Event_ID = @Event_ID
	WHERE Event_ID = @old_Event_ID AND 
Course = @old_Course
GO


CREATE PROCEDURE InsertEntry
(
	@Score BIGINT , 
	@EntryID BIGINT , 
	@FinishOrder BIGINT , 
	@EventCourse_ID BIGINT , 
	@EventCourse_Course NATIONAL CHARACTER VARYING(16) , 
	@Entrant_EntrantID BIGINT 
)
AS
	INSERT INTO Entry(Score, EntryID, FinishOrder, EventCourse_ID, EventCourse_Course, Entrant_EntrantID)
	VALUES (@Score, @EntryID, @FinishOrder, @EventCourse_ID, @EventCourse_Course, @Entrant_EntrantID)
GO


CREATE PROCEDURE DeleteEntry
(
	@EntryID BIGINT 
)
AS
	DELETE FROM Entry
	WHERE EntryID = @EntryID
GO


CREATE PROCEDURE UpdateEntryScore
(
	@old_EntryID BIGINT , 
	@Score BIGINT 
)
AS
	UPDATE Entry
SET Score = @Score
	WHERE EntryID = @old_EntryID
GO


CREATE PROCEDURE UpdateEntryFinishOrder
(
	@old_EntryID BIGINT , 
	@FinishOrder BIGINT 
)
AS
	UPDATE Entry
SET FinishOrder = @FinishOrder
	WHERE EntryID = @old_EntryID
GO


CREATE PROCEDURE UpdateEntryEventCourse_ID
(
	@old_EntryID BIGINT , 
	@EventCourse_ID BIGINT 
)
AS
	UPDATE Entry
SET EventCourse_ID = @EventCourse_ID
	WHERE EntryID = @old_EntryID
GO


CREATE PROCEDURE UpdateEntryEventCourse_Course
(
	@old_EntryID BIGINT , 
	@EventCourse_Course NATIONAL CHARACTER VARYING(16) 
)
AS
	UPDATE Entry
SET EventCourse_Course = @EventCourse_Course
	WHERE EntryID = @old_EntryID
GO


CREATE PROCEDURE UpdateEntryEntrant_EntrantID
(
	@old_EntryID BIGINT , 
	@Entrant_EntrantID BIGINT 
)
AS
	UPDATE Entry
SET Entrant_EntrantID = @Entrant_EntrantID
	WHERE EntryID = @old_EntryID
GO


CREATE PROCEDURE InsertSeriesEvent
(
	@Number BIGINT , 
	@Series_SeriesName NATIONAL CHARACTER VARYING(40) , 
	@Event_ID BIGINT 
)
AS
	INSERT INTO SeriesEvent(Number, Series_SeriesName, Event_ID)
	VALUES (@Number, @Series_SeriesName, @Event_ID)
GO


CREATE PROCEDURE DeleteSeriesEvent
(
	@Number BIGINT , 
	@Series_SeriesName NATIONAL CHARACTER VARYING(40) 
)
AS
	DELETE FROM SeriesEvent
	WHERE Number = @Number AND 
Series_SeriesName = @Series_SeriesName
GO


CREATE PROCEDURE UpdateSeriesEventNumber
(
	@old_Number BIGINT , 
	@old_Series_SeriesName NATIONAL CHARACTER VARYING(40) , 
	@Number BIGINT 
)
AS
	UPDATE SeriesEvent
SET Number = @Number
	WHERE Number = @old_Number AND 
Series_SeriesName = @old_Series_SeriesName
GO


CREATE PROCEDURE UpdtSrsEvntSrs_SrsNm
(
	@old_Number BIGINT , 
	@old_Series_SeriesName NATIONAL CHARACTER VARYING(40) , 
	@Series_SeriesName NATIONAL CHARACTER VARYING(40) 
)
AS
	UPDATE SeriesEvent
SET Series_SeriesName = @Series_SeriesName
	WHERE Number = @old_Number AND 
Series_SeriesName = @old_Series_SeriesName
GO


CREATE PROCEDURE UpdateSeriesEventEvent_ID
(
	@old_Number BIGINT , 
	@old_Series_SeriesName NATIONAL CHARACTER VARYING(40) , 
	@Event_ID BIGINT 
)
AS
	UPDATE SeriesEvent
SET Event_ID = @Event_ID
	WHERE Number = @old_Number AND 
Series_SeriesName = @old_Series_SeriesName
GO


GO