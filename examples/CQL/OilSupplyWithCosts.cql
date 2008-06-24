vocabulary OilSupply;

/*
 * Value Types
 */
Cost is defined as Money();
Month is defined as VariableLengthText(3);
Product is defined as VariableLengthText(80);
Quantity is defined as UnsignedInteger(32);
RefineryName is defined as VariableLengthText(80);
Region is defined as VariableLengthText(80);
Season is defined as VariableLengthText(6) restricted to {'Spring', 'Summer', 'Autumn', 'Winter'};
TransportMethod is defined as VariableLengthText() restricted to {'Rail', 'Road', 'Sea'};
Year is defined as SignedInteger(32);

/*
 * Entity Types
 */
Refinery is identified by RefineryName:
	Refinery has exactly one RefineryName,
	RefineryName is of at most one Refinery;
TransportRoute is where
	TransportMethod transportation is available from Refinery to Region at at most one Cost per kL,
	TransportMethod transportation is available to Region from Refinery at Cost per kL;

SupplyPeriod is identified by Month and Year:
	SupplyPeriod is in exactly one Month,
	SupplyPeriod is in exactly one Year;
ProductionCommitment is where
	Refinery has committed to produce Quantity of Product in SupplyPeriod at at most one Cost;
RegionalDemand is where
	Region will need at most one Quantity of Product in SupplyPeriod;

/*
 * Fact Types
 */
AcceptableSubstitutes is where
	Product may be substituted by alternate-Product in Season [acyclic, intransitive],
	alternate-Product is an acceptable substitute for Product in Season;
Month is in exactly one Season;

