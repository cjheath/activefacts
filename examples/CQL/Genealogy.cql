vocabulary Genealogy;

/*
 * Value Types
 */
Address is written as VariableLengthText(128);
Certificate is written as VariableLengthText(64);
Day is written as UnsignedInteger(32) restricted to {1..31};
Email is written as VariableLengthText(64);
EventID is written as AutoCounter;
EventLocation is written as VariableLengthText(128);
EventRoleName is written as VariableLengthText restricted to {'Celebrant', 'Father', 'Husband', 'Mother', 'Subject', 'Wife'};
EventTypeID is written as AutoCounter;
EventTypeName is written as VariableLengthText(16) restricted to {'Birth', 'Burial', 'Christening', 'Death', 'Divorce', 'Marriage'};
Gender is written as FixedLengthText(1) restricted to {'F', 'M'};
Month is written as UnsignedInteger(32) restricted to {1..12};
Name is written as VariableLengthText(128);
Occupation is written as VariableLengthText(128);
Official is written as VariableLengthText(64);
PersonID is written as AutoCounter;
Picture is written as PictureRawData(20);
RoleID is written as AutoCounter;
SourceID is written as AutoCounter;
SourceName is written as VariableLengthText(128);
UserID is written as AutoCounter;
Year is written as UnsignedInteger(32);

/*
 * Entity Types
 */
Event is identified by its ID;
Event is certified by at most one Certificate;
Event occurred at at most one EventLocation;
Event was confirmed by at most one Official;

EventDate is identified by min-Year and max-Year and Month and Day where
	EventDate wasnt before at most one min-Year,
	EventDate wasnt after at most one max-Year,
	EventDate occurred in at most one Month,
	EventDate occurred on at most one Day;
Event occurred on at most one EventDate;

EventType is identified by its ID;
Event is of at most one EventType;
EventType is called one EventTypeName,
	EventTypeName is name of at most one EventType;

Person is identified by its ID;
Address is of Person,
	Person lives at at most one Address;
Email is of Person,
	Person has at most one Email;
Occupation is of Person,
	Person is employed in at most one Occupation;
Person is of at most one Gender;
Person is called at most one family-Name,
	family-Name is of Person;
given-Name is name of Person,
	Person is called at most one given-Name;
preferred-Picture is of Person,
	Person has at most one preferred-Picture;

Role is identified by its ID;
Role is called one EventRoleName,
	EventRoleName is name of one Role;

Source is identified by its ID;
Source has one SourceName,
	SourceName is of at most one Source;
Participation is where
	Person played Role in Event according to Source,
	Person was involved in Event according to Source in Role,
	Source claims Person played Role in Event;

User is identified by its ID;
Email is of User,
	User has at most one Email;
User provided Source,
	Source was provided by one User;
Friend is where
	User is friend of other-User [symmetric];
Friend is confirmed;

/*
 * Constraints:
 */
each Event occurs at least one time in
	Person played Role in Event according to Source;
each EventDate occurs at least one time in
	EventDate wasnt before min-Year,
	EventDate wasnt after max-Year,
	EventDate occurred in Month,
	EventDate occurred on Day;
each Person occurs at least one time in
	Person played Role in Event according to Source;
