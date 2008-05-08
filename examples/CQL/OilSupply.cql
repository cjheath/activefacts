vocabulary OilSupply;

/*
 * Value Types
 */
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
Refinery = entity identified by RefineryName:
	Refinery has exactly one RefineryName,
	RefineryName is of at most one Refinery;
TransportRoute = Transportation is available from Refinery to Region,
	Transportation is available to Region from Refinery;
ProductionCommitment = Refinery has committed by Month to produce Product in Quantity,
	in Month Refinery has committed to produce Quantity of Product;

/*
 * Fact Types
 */
Month is in exactly one Season;
RegionalDemand = Region in Month of Year will need Product in at most one Quantity;
AcceptableSubstitutes = Product may be substituted by alternate-Product in Season [acyclic, intransitive],
	alternate-Product is an acceptable substitute for Product in Season;

