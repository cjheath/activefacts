vocabulary OilSupply;

/*
 * Value Types
 */
Cost = Money();
Month = VariableLengthText(3);
Product = VariableLengthText(80);
Quantity = UnsignedInteger(32);
RefineryName = VariableLengthText(80);
Region = VariableLengthText(80);
Season = VariableLengthText(6) restricted to {'Spring', 'Summer', 'Autumn', 'Winter'};
Transportation = VariableLengthText();
Year = UnsignedInteger(32);

/*
 * Entity Types
 */
AcceptableSubstitutes = entity known by Product and alternate-Product and Season:
	Product may be substituted by alternate-Product in Season [acyclic, intransitive],
	alternate-Product is an acceptable substitute for Product in Season;

Refinery = entity known by RefineryName:
	Refinery has exactly one RefineryName,
	RefineryName is of at most one Refinery;
TransportRoute = Transportation is available from Refinery to Region at at most one Cost per kL,
	Transportation is available to Region from Refinery at Cost per kL;
ProductionCommitment = Refinery has committed by Month to produce Product in Quantity at at most one Cost per kL in Year,
	in Month Refinery has committed to produce Quantity of Product at Cost per kL in Year;

RegionalDemand = entity known by Product and Year and Month and Region:
	Region in Month of Year will need Product in at most one Quantity;

/*
 * Fact Types
 */
Month is in exactly one Season;

