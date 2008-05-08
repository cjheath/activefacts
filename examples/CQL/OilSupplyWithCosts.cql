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
TransportMethod = VariableLengthText() restricted to {'Rail', 'Road', 'Sea'};
Year = SignedInteger(32);

/*
 * Entity Types
 */
Refinery = entity identified by RefineryName:
	Refinery has exactly one RefineryName,
	RefineryName is of at most one Refinery;
TransportRoute = TransportMethod transportation is available from Refinery to Region at at most one Cost per kL,
	TransportMethod transportation is available to Region from Refinery at Cost per kL;

SupplyPeriod = entity identified by Month and Year:
	SupplyPeriod is in exactly one Month,
	SupplyPeriod is in exactly one Year;
ProductionCommitment = Refinery has committed to produce Quantity of Product in SupplyPeriod at at most one Cost;
RegionalDemand = Region will need at most one Quantity of Product in SupplyPeriod;

/*
 * Fact Types
 */
Month is in exactly one Season;
AcceptableSubstitutes = Product may be substituted by alternate-Product in Season [acyclic, intransitive],
	alternate-Product is an acceptable substitute for Product in Season;

