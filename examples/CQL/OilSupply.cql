vocabulary OilSupply;

/*
 * Value Types
 */
Cost is written as Money;
MonthCode is written as FixedLengthText;
ProductName is written as VariableLengthText;
Quantity is written as UnsignedInteger(32);
RefineryName is written as VariableLengthText(80);
RegionName is written as VariableLengthText;
Season is written as VariableLengthText(6) restricted to {'Autumn', 'Spring', 'Summer', 'Winter'};
TransportMethod is written as VariableLengthText restricted to {'Rail', 'Road', 'Sea'};
YearNr is written as SignedInteger(32);

/*
 * Entity Types
 */
Month is identified by its Code;
Month is in one Season;

Product is identified by its Name;

Refinery is identified by its Name;

Region is identified by its Name;

TransportRoute is where
	TransportMethod transportation is available from Refinery to Region,
	TransportMethod transportation is available to Region from Refinery;
TransportRoute incurs at most one Cost per kl;

Year is identified by its Nr;

AcceptableSubstitutes is where
	Product may be substituted by alternate-Product in Season [acyclic, intransitive],
	alternate-Product is an acceptable substitute for Product in Season;

SupplyPeriod is identified by Year and Month where
	SupplyPeriod is in one Year,
	SupplyPeriod is in one Month;

ProductionForecast is where
	Refinery forecasts production of Product in SupplyPeriod;
ProductionForecast predicts at most one Cost;
ProductionForecast is for one Quantity;

RegionalDemand is where
	Region will need Product in SupplyPeriod;
RegionalDemand is for at most one Quantity;

