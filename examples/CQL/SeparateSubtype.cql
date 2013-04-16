vocabulary SeparateSubtype;

/*
 * Value Types
 */
Claim ID is written as Auto Counter;
Date Time is written as Date Time;
Person Name is written as String;

/*
 * Entity Types
 */
Claim is identified by its ID;

Incident is identified by Claim where
	Claim concerns at most one Incident,
	Incident resulted in one Claim;
Incident occurred on at most one Date Time;

Person is identified by its Name;

Vehicle Incident is a kind of Incident [separate];

Witness is a kind of Person;
Witness saw Incident,
	Incident was seen by at most one Witness;

Driver is a kind of Person;
Vehicle Incident occured while at most one Driver was in charge;

