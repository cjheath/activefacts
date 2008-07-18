vocabulary OilSupply;

/*
 * Value Types
 */
Month is defined as VariableLengthText(3);
Product is defined as VariableLengthText(80);
Quantity is defined as UnsignedInteger(32);
RefineryName is defined as VariableLengthText(80);
Region is defined as VariableLengthText(80);
Season is defined as VariableLengthText(6) restricted to {'Spring', 'Summer', 'Autumn', 'Winter'};
Transportation is defined as VariableLengthText();
Year is defined as UnsignedInteger(32);

/*
 * Entity Types
 */
Refinery is identified by RefineryName where
	Refinery has exactly one RefineryName,
	RefineryName is of at most one Refinery;
ProductionCommitment is where
	Refinery has committed by Month to produce Product in Quantity,
	in Month Refinery has committed to produce Quantity of Product;
TransportRoute is where
	Transportation is available from Refinery to Region,
	Transportation is available to Region from Refinery;

/*
 * Fact Types
 */
Month is in exactly one Season;
AcceptableSubstitutes is where
	Product may be substituted by alternate-Product in Season [acyclic, intransitive],
	alternate-Product is an acceptable substitute for Product in Season;
RegionalDemand is where
	Region in Month of Year will need Product in at most one Quantity;

