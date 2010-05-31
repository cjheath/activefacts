vocabulary Genealogy;

/*
 * Value Types
 */
Address is written as Variable Length Text(128);
Certificate is written as Variable Length Text(64);
Day is written as Unsigned Integer(32) restricted to {1..31};
Email is written as Variable Length Text(64);
Event ID is written as Auto Counter;
Event Location is written as Variable Length Text(128);
Event Role Name is written as Variable Length Text restricted to {'Celebrant', 'Father', 'Husband', 'Mother', 'Subject', 'Wife'};
Event Type ID is written as Auto Counter;
Event Type Name is written as Variable Length Text(16) restricted to {'Birth', 'Burial', 'Christening', 'Death', 'Divorce', 'Marriage'};
Gender is written as Fixed Length Text(1) restricted to {'F', 'M'};
Month is written as Unsigned Integer(32) restricted to {1..12};
Name is written as Variable Length Text(128);
Occupation is written as Variable Length Text(128);
Official is written as Variable Length Text(64);
Person ID is written as Auto Counter;
Picture is written as Picture Raw Data(20);
Role ID is written as Auto Counter;
Source ID is written as Auto Counter;
Source Name is written as Variable Length Text(128);
User ID is written as Auto Counter;
Year is written as Unsigned Integer(32);

/*
 * Entity Types
 */
Event is identified by its ID;
Event is certified by at most one Certificate;
Event occurred at at most one Event Location;
Event was confirmed by at most one Official;

Event Date is identified by min-Year and max-Year and Month and Day where
	Event Date wasnt before at most one min-Year,
	Event Date wasnt after at most one max-Year,
	Event Date occurred in at most one Month,
	Event Date occurred on at most one Day;
Event occurred on at most one Event Date;

Event Type is identified by its ID;
Event is of at most one Event Type;
Event Type is called one Event Type Name,
	Event Type Name is name of at most one Event Type;

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
Role is called one Event Role Name,
	Event Role Name is name of one Role;

Source is identified by its ID;
Source has one Source Name,
	Source Name is of at most one Source;

User is identified by its ID;
Email is of User,
	User has at most one Email;
User provided Source,
	Source was provided by one User;

Friend is where
	User is friend of other-User [symmetric];
Friend is confirmed;

Participation is where
	Person played Role in Event according to Source,
	Person was involved in Event according to Source in Role,
	Source claims Person played Role in Event;

/*
 * Constraints:
 */
each Event Date occurs at least one time in
	Event Date wasnt before min-Year,
	Event Date wasnt after max-Year,
	Event Date occurred in Month,
	Event Date occurred on Day;
each Event occurs at least one time in
	Person played Role in Event according to Source;
each Person occurs at least one time in
	Person played Role in Event according to Source;
