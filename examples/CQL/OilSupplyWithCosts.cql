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
Month is identified by MonthCode where
	Month has exactly one MonthCode,
	MonthCode is of at most one Month;
Month is in exactly one Season;

Product is identified by ProductName where
	Product has exactly one ProductName,
	ProductName is of at most one Product;
AcceptableSubstitutes is where
	Product may be substituted by alternate-Product in Season [acyclic, intransitive],
	alternate-Product is an acceptable substitute for Product in Season;

Refinery is identified by RefineryName where
	Refinery has exactly one RefineryName,
	RefineryName is of at most one Refinery;

Region is identified by RegionName where
	Region has exactly one RegionName,
	RegionName is of at most one Region;
TransportRoute is where
	TransportMethod transportation is available from Refinery to Region,
	TransportMethod transportation is available to Region from Refinery;
TransportRoute incurs at most one Cost per kl;

Year is identified by YearNr where
	Year has exactly one YearNr,
	YearNr is of at most one Year;

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

