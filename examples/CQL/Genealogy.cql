vocabulary Genealogy;

/*
 * Value Types
 */
Address = VariableLengthText(128);
Certificate = VariableLengthText(64);
Day = UnsignedInteger(32) restricted to {1..31};
Email = VariableLengthText(64);
EventID = AutoCounter();
EventLocation = VariableLengthText(128);
EventRoleName = VariableLengthText() restricted to {'Subject', 'Father', 'Mother', 'Husband', 'Wife', 'Celebrant'};
EventTypeID = AutoCounter();
EventTypeName = VariableLengthText(16) restricted to {'Birth', 'Christening', 'Marriage', 'Divorce', 'Death', 'Burial'};
Gender = FixedLengthText(1) restricted to {'M', 'F'};
Month = UnsignedInteger(32) restricted to {1..12};
Name = VariableLengthText(128);
Occupation = VariableLengthText(128);
Official = VariableLengthText(64);
PersonID = AutoCounter();
Picture = PictureRawData(20);
RoleID = AutoCounter();
SourceID = AutoCounter();
SourceName = VariableLengthText(128);
UserID = AutoCounter();
Year = UnsignedInteger(32);

/*
 * Entity Types
 */
Event = entity identified by EventID:
	Event has exactly one EventID,
	EventID is of at most one Event;
Event occurred at at most one EventLocation;
Event is certified by at most one Certificate;
Event was confirmed by at most one Official;

EventDate = entity identified by Year and Year and Month and Day:
	EventDate occurred in or after at most one Year,
	EventDate occurred in or before at most one Year,
	EventDate occurred in at most one Month,
	EventDate occurred on at most one Day;
Event occurred on at most one EventDate;

EventType = entity identified by EventTypeID:
	EventType has exactly one EventTypeID,
	EventTypeID is of at most one EventType;
EventType is called exactly one EventTypeName,
	EventTypeName is name of at most one EventType;
Event is of at most one EventType;

Person = entity identified by PersonID:
	Person has exactly one PersonID,
	PersonID is of at most one Person;
Person is of at most one Gender;
given-Name is name of Person,
	Person is called at most one given-Name;
Person is called at most one family-Name,
	family-Name is of Person;
Occupation is of Person,
	Person is employed in at most one Occupation;
Address is of Person,
	Person lives at at most one Address;
preferred-Picture is of Person,
	Person has at most one preferred-Picture;
Email is of Person,
	Person has at most one Email;

Role = entity identified by RoleID:
	Role has exactly one RoleID,
	RoleID is of at most one Role;
Role is called exactly one EventRoleName,
	EventRoleName is name of exactly one Role;

Source = entity identified by SourceID:
	Source has exactly one SourceID,
	SourceID is of at most one Source;
Source has exactly one SourceName,
	SourceName is of at most one Source;
Participation = Person played Role in Event according to Source,
	each Person played some Role in some Event according to some Source,
	some Person played some Role in each Event according to some Source,
	Person was involved in Event according to Source in Role,
	Source claims Person played Role in Event;

User = entity identified by UserID:
	User has exactly one UserID,
	UserID is of at most one User;
User provided Source,
	Source was provided by exactly one User;
Email is of User,
	User has at most one Email;

Friend = entity identified by other-User and User:
	User is friend of other-User [symmetric];
Friend is confirmed;

/*
Constraints:
	InclusiveOrConstraint1: each combination(EventDateOccurredInOrAfterYear.EventDate, EventDateOccurredInOrBeforeYear.EventDate, EventDateOccurredInMonth.EventDate, EventDateOccurredOnDay.EventDate) must occur at least 1 time
 */
