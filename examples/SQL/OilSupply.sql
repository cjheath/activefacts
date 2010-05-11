CREATE TABLE AcceptableSubstitutes (
	-- AcceptableSubstitutes is where Product may be substituted by alternate-Product in Season and Product has ProductName,
	AlternateProductName                    VariableLengthText NOT NULL,
	-- AcceptableSubstitutes is where Product may be substituted by alternate-Product in Season and Product has ProductName,
	ProductName                             VariableLengthText NOT NULL,
	-- AcceptableSubstitutes is where Product may be substituted by alternate-Product in Season,
	Season                                  VariableLengthText(6) NOT NULL CHECK(Season = 'Autumn' OR Season = 'Spring' OR Season = 'Summer' OR Season = 'Winter'),
	PRIMARY KEY(ProductName, AlternateProductName, Season)
)
GO

CREATE TABLE Month (
	-- Month has MonthNr,
	MonthNr                                 SignedInteger(32) NOT NULL CHECK((MonthNr >= 1 AND MonthNr <= 12)),
	-- Month is in Season,
	Season                                  VariableLengthText(6) NOT NULL CHECK(Season = 'Autumn' OR Season = 'Spring' OR Season = 'Summer' OR Season = 'Winter'),
	PRIMARY KEY(MonthNr)
)
GO

CREATE TABLE ProductionForecast (
	-- maybe ProductionForecast predicts Cost,
	Cost                                    Money NULL,
	-- ProductionForecast is where Refinery forecasts production of Product in SupplyPeriod and Product has ProductName,
	ProductName                             VariableLengthText NOT NULL,
	-- ProductionForecast is for Quantity,
	Quantity                                UnsignedInteger(32) NOT NULL,
	-- ProductionForecast is where Refinery forecasts production of Product in SupplyPeriod and Refinery has RefineryName,
	RefineryName                            VariableLengthText(80) NOT NULL,
	-- ProductionForecast is where Refinery forecasts production of Product in SupplyPeriod and SupplyPeriod is in Month and Month has MonthNr,
	SupplyPeriodMonthNr                     SignedInteger(32) NOT NULL CHECK((SupplyPeriodMonthNr >= 1 AND SupplyPeriodMonthNr <= 12)),
	-- ProductionForecast is where Refinery forecasts production of Product in SupplyPeriod and SupplyPeriod is in Year and Year has YearNr,
	SupplyPeriodYearNr                      SignedInteger(32) NOT NULL,
	PRIMARY KEY(RefineryName, ProductName, SupplyPeriodYearNr, SupplyPeriodMonthNr)
)
GO

CREATE TABLE RegionalDemand (
	-- RegionalDemand is where Region will need Product in SupplyPeriod and Product has ProductName,
	ProductName                             VariableLengthText NOT NULL,
	-- maybe RegionalDemand is for Quantity,
	Quantity                                UnsignedInteger(32) NULL,
	-- RegionalDemand is where Region will need Product in SupplyPeriod and Region has RegionName,
	RegionName                              VariableLengthText NOT NULL,
	-- RegionalDemand is where Region will need Product in SupplyPeriod and SupplyPeriod is in Month and Month has MonthNr,
	SupplyPeriodMonthNr                     SignedInteger(32) NOT NULL CHECK((SupplyPeriodMonthNr >= 1 AND SupplyPeriodMonthNr <= 12)),
	-- RegionalDemand is where Region will need Product in SupplyPeriod and SupplyPeriod is in Year and Year has YearNr,
	SupplyPeriodYearNr                      SignedInteger(32) NOT NULL,
	PRIMARY KEY(RegionName, ProductName, SupplyPeriodYearNr, SupplyPeriodMonthNr)
)
GO

CREATE TABLE TransportRoute (
	-- maybe TransportRoute incurs Cost per kl,
	Cost                                    Money NULL,
	-- TransportRoute is where TransportMethod transportation is available from Refinery to Region and Refinery has RefineryName,
	RefineryName                            VariableLengthText(80) NOT NULL,
	-- TransportRoute is where TransportMethod transportation is available from Refinery to Region and Region has RegionName,
	RegionName                              VariableLengthText NOT NULL,
	-- TransportRoute is where TransportMethod transportation is available from Refinery to Region,
	TransportMethod                         VariableLengthText NOT NULL CHECK(TransportMethod = 'Rail' OR TransportMethod = 'Road' OR TransportMethod = 'Sea'),
	PRIMARY KEY(TransportMethod, RefineryName, RegionName)
)
GO

