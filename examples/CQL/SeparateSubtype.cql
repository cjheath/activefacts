vocabulary SeparateSubtype;

/*
 * Value Types
 */
ClaimID is written as AutoCounter();
DateTime is written as DateAndTime();
DriverName is written as VariableLengthText();

/*
 * Entity Types
 */
Claim is identified by its ID;

Driver is identified by its Name;

Incident is identified by Claim where
	Claim concerns at most one Incident;
Incident occurred on at most one DateTime;

VehicleIncident is a kind of Incident;
VehicleIncident occured while at most one Driver was in charge;

/*
 * Constraints:
 */
each Incident occurs one time in
	Claim concerns Incident;
