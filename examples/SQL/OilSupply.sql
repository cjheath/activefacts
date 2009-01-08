CREATE TABLE AcceptableSubstitutes (
	-- AcceptableSubstitutes is where Product may be substituted by alternate-Product in Season and Product has ProductName,
	ProductName                             varchar NOT NULL,
	-- AcceptableSubstitutes is where Product may be substituted by alternate-Product in Season and Product has ProductName,
	AlternateProductName                    varchar NOT NULL,
	-- AcceptableSubstitutes is where Product may be substituted by alternate-Product in Season,
	Season                                  varchar(6) NOT NULL CHECK(Season = 'Spring' OR Season = 'Summer' OR Season = 'Autumn' OR Season = 'Winter'),
	PRIMARY KEY(ProductName, AlternateProductName, Season)
)
GO

CREATE TABLE Month (
	-- Month is in Season,
	Season                                  varchar(6) NOT NULL CHECK(Season = 'Spring' OR Season = 'Summer' OR Season = 'Autumn' OR Season = 'Winter'),
	-- Month has MonthCode,
	MonthCode                               char NOT NULL,
	PRIMARY KEY(MonthCode)
)
GO

CREATE TABLE ProductionForecast (
	-- ProductionForecast is where Refinery forecasts production of Product in SupplyPeriod and Refinery has RefineryName,
	RefineryName                            varchar(80) NOT NULL,
	-- ProductionForecast is where Refinery forecasts production of Product in SupplyPeriod and Product has ProductName,
	ProductName                             varchar NOT NULL,
	-- ProductionForecast is where Refinery forecasts production of Product in SupplyPeriod and SupplyPeriod is in Year and Year has YearNr,
	SupplyPeriodYearNr                      int NOT NULL,
	-- ProductionForecast is where Refinery forecasts production of Product in SupplyPeriod and SupplyPeriod is in Month and Month has MonthCode,
	SupplyPeriodMonthCode                   char NOT NULL,
	-- ProductionForecast is for Quantity,
	Quantity                                int NOT NULL,
	-- maybe ProductionForecast predicts Cost,
	Cost                                    decimal NULL,
	PRIMARY KEY(RefineryName, ProductName, SupplyPeriodYearNr, SupplyPeriodMonthCode)
)
GO

CREATE TABLE RegionalDemand (
	-- RegionalDemand is where Region will need Product in SupplyPeriod and Region has RegionName,
	RegionName                              varchar NOT NULL,
	-- RegionalDemand is where Region will need Product in SupplyPeriod and Product has ProductName,
	ProductName                             varchar NOT NULL,
	-- RegionalDemand is where Region will need Product in SupplyPeriod and SupplyPeriod is in Year and Year has YearNr,
	SupplyPeriodYearNr                      int NOT NULL,
	-- RegionalDemand is where Region will need Product in SupplyPeriod and SupplyPeriod is in Month and Month has MonthCode,
	SupplyPeriodMonthCode                   char NOT NULL,
	-- maybe RegionalDemand is for Quantity,
	Quantity                                int NULL,
	PRIMARY KEY(RegionName, ProductName, SupplyPeriodYearNr, SupplyPeriodMonthCode)
)
GO

CREATE TABLE TransportRoute (
	-- TransportRoute is where TransportMethod transportation is available from Refinery to Region,
	TransportMethod                         varchar NOT NULL CHECK(TransportMethod = 'Rail' OR TransportMethod = 'Road' OR TransportMethod = 'Sea'),
	-- TransportRoute is where TransportMethod transportation is available from Refinery to Region and Refinery has RefineryName,
	RefineryName                            varchar(80) NOT NULL,
	-- TransportRoute is where TransportMethod transportation is available from Refinery to Region and Region has RegionName,
	RegionName                              varchar NOT NULL,
	-- maybe TransportRoute incurs Cost per kl,
	Cost                                    decimal NULL,
	PRIMARY KEY(TransportMethod, RefineryName, RegionName)
)
GO

