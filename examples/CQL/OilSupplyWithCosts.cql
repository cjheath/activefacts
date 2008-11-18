vocabulary OilSupply;

/*
 * Value Types
 */
Cost is defined as Money();
MonthCode is defined as FixedLengthText();
ProductName is defined as VariableLengthText();
Quantity is defined as UnsignedInteger(32);
RefineryName is defined as VariableLengthText(80);
RegionName is defined as VariableLengthText();
Season is defined as VariableLengthText(6) restricted to {'Spring', 'Summer', 'Autumn', 'Winter'};
TransportMethod is defined as VariableLengthText() restricted to {'Rail', 'Road', 'Sea'};
YearNr is defined as SignedInteger(32);

/*
 * Entity Types
 */
Month is identified by its Code;
Month is in exactly one Season;

Product is identified by its Name;
AcceptableSubstitutes is where
	Product may be substituted by alternate-Product in Season [acyclic, intransitive],
	alternate-Product is an acceptable substitute for Product in Season;

Refinery is identified by its Name;

Region is identified by its Name;
TransportRoute is where
	TransportMethod transportation is available from Refinery to Region,
	TransportMethod transportation is available to Region from Refinery;
TransportRoute incurs at most one Cost per kl;

Year is identified by its Nr;

SupplyPeriod is identified by Month and Year where
	SupplyPeriod is in exactly one Month,
	SupplyPeriod is in exactly one Year;
ProductionForecast is where
	Refinery forecasts production of Product in SupplyPeriod;
RegionalDemand is where
	Region will need Product in SupplyPeriod;
ProductionForecast predicts at most one Cost;
ProductionForecast is for exactly one Quantity;
RegionalDemand is for at most one Quantity;

