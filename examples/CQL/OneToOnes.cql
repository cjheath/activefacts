vocabulary OneToOnes;

/*
 * Value Types
 */
BoyID is defined as AutoCounter();
ClaimID is defined as AutoCounter();
DriverName is defined as VariableLengthText();
GirlID is defined as AutoCounter();

/*
 * Entity Types
 */
Boy is identified by its ID;

Claim is identified by its ID;

Driver is identified by its Name;

Girl is identified by its ID;
Girl is going out with at most one Boy;

Incident is identified by Claim where
	Claim concerns at most one Incident;

VehicleIncident is a kind of Incident;
VehicleIncident occured while at most one Driver was in charge;

/*
 * Constraints:
 */
each Boy occurs at most one time in
	Girl is going out with Boy;
each Incident occurs one time in
	Claim concerns Incident;
