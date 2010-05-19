CREATE TABLE AcceptableSubstitutes (
	-- AcceptableSubstitutes is where Product may be substituted by alternate-Product in Season and Product has ProductName,
	AlternateProductName                    varchar NOT NULL,
	-- AcceptableSubstitutes is where Product may be substituted by alternate-Product in Season and Product has ProductName,
	ProductName                             varchar NOT NULL,
	-- AcceptableSubstitutes is where Product may be substituted by alternate-Product in Season,
	Season                                  varchar(6) NOT NULL CHECK(Season = 'Autumn' OR Season = 'Spring' OR Season = 'Summer' OR Season = 'Winter'),
	PRIMARY KEY(ProductName, AlternateProductName, Season)
)
GO

CREATE TABLE Month (
	-- Month has MonthNr,
	MonthNr                                 int NOT NULL CHECK((MonthNr >= 1 AND MonthNr <= 12)),
	-- Month is in Season,
	Season                                  varchar(6) NOT NULL CHECK(Season = 'Autumn' OR Season = 'Spring' OR Season = 'Summer' OR Season = 'Winter'),
	PRIMARY KEY(MonthNr)
)
GO

CREATE TABLE ProductionForecast (
	-- maybe ProductionForecast predicts Cost,
	Cost                                    decimal NULL,
	-- ProductionForecast is where Refinery forecasts production of Product in SupplyPeriod and Product has ProductName,
	ProductName                             varchar NOT NULL,
	-- ProductionForecast is for Quantity,
	Quantity                                int NOT NULL,
	-- ProductionForecast is where Refinery forecasts production of Product in SupplyPeriod and Refinery has RefineryName,
	RefineryName                            varchar(80) NOT NULL,
	-- ProductionForecast is where Refinery forecasts production of Product in SupplyPeriod and SupplyPeriod is in Month and Month has MonthNr,
	SupplyPeriodMonthNr                     int NOT NULL CHECK((SupplyPeriodMonthNr >= 1 AND SupplyPeriodMonthNr <= 12)),
	-- ProductionForecast is where Refinery forecasts production of Product in SupplyPeriod and SupplyPeriod is in Year and Year has YearNr,
	SupplyPeriodYearNr                      int NOT NULL,
	PRIMARY KEY(RefineryName, ProductName, SupplyPeriodYearNr, SupplyPeriodMonthNr)
)
GO

CREATE TABLE RegionalDemand (
	-- RegionalDemand is where Region will need Product in SupplyPeriod and Product has ProductName,
	ProductName                             varchar NOT NULL,
	-- maybe RegionalDemand is for Quantity,
	Quantity                                int NULL,
	-- RegionalDemand is where Region will need Product in SupplyPeriod and Region has RegionName,
	RegionName                              varchar NOT NULL,
	-- RegionalDemand is where Region will need Product in SupplyPeriod and SupplyPeriod is in Month and Month has MonthNr,
	SupplyPeriodMonthNr                     int NOT NULL CHECK((SupplyPeriodMonthNr >= 1 AND SupplyPeriodMonthNr <= 12)),
	-- RegionalDemand is where Region will need Product in SupplyPeriod and SupplyPeriod is in Year and Year has YearNr,
	SupplyPeriodYearNr                      int NOT NULL,
	PRIMARY KEY(RegionName, ProductName, SupplyPeriodYearNr, SupplyPeriodMonthNr)
)
GO

CREATE TABLE TransportRoute (
	-- maybe TransportRoute incurs Cost per kl,
	Cost                                    decimal NULL,
	-- TransportRoute is where TransportMethod transportation is available from Refinery to Region and Refinery has RefineryName,
	RefineryName                            varchar(80) NOT NULL,
	-- TransportRoute is where TransportMethod transportation is available from Refinery to Region and Region has RegionName,
	RegionName                              varchar NOT NULL,
	-- TransportRoute is where TransportMethod transportation is available from Refinery to Region,
	TransportMethod                         varchar NOT NULL CHECK(TransportMethod = 'Rail' OR TransportMethod = 'Road' OR TransportMethod = 'Sea'),
	PRIMARY KEY(TransportMethod, RefineryName, RegionName)
)
GO

