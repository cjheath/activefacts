vocabulary OneToOnes;

/*
 * Value Types
 */
ClaimID is defined as AutoCounter();
DriverName is defined as VariableLengthText();

/*
 * Entity Types
 */
Claim is identified by its ID;

Driver is identified by its Name;

Incident is identified by Claim where
	Claim concerns at most one Incident;

VehicleIncident is a kind of Incident;
VehicleIncident occured while at most one Driver was in charge;

/*
 * Constraints:
 */
each Incident occurs one time in
	Claim concerns Incident;
