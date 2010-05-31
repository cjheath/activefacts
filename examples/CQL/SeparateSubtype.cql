vocabulary SeparateSubtype;

/*
 * Value Types
 */
Claim ID is written as Auto Counter;
Date Time is written as Date And Time;
Driver Name is written as Variable Length Text;

/*
 * Entity Types
 */
Claim is identified by its ID;

Driver is identified by its Name;

Incident is identified by Claim where
	Claim concerns at most one Incident;
Incident occurred on at most one Date Time;

Vehicle Incident is a kind of Incident [separate];
Vehicle Incident occured while at most one Driver was in charge;

/*
 * Constraints:
 */
each Incident occurs one time in
	Claim concerns Incident;
