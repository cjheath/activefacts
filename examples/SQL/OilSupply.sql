CREATE TABLE AcceptableSubstitutes (
	-- Acceptable Substitutes is where Product may be substituted by alternate-Product in Season and Product has Product Name,
	AlternateProductName                    varchar NOT NULL,
	-- Acceptable Substitutes is where Product may be substituted by alternate-Product in Season and Product has Product Name,
	ProductName                             varchar NOT NULL,
	-- Acceptable Substitutes is where Product may be substituted by alternate-Product in Season,
	Season                                  varchar(6) NOT NULL CHECK(Season = 'Autumn' OR Season = 'Spring' OR Season = 'Summer' OR Season = 'Winter'),
	PRIMARY KEY(ProductName, AlternateProductName, Season)
)
GO

CREATE TABLE Month (
	-- Month has Month Nr,
	MonthNr                                 int NOT NULL CHECK((MonthNr >= 1 AND MonthNr <= 12)),
	-- Month is in Season,
	Season                                  varchar(6) NOT NULL CHECK(Season = 'Autumn' OR Season = 'Spring' OR Season = 'Summer' OR Season = 'Winter'),
	PRIMARY KEY(MonthNr)
)
GO

CREATE TABLE ProductionForecast (
	-- maybe Production Forecast predicts Cost,
	Cost                                    decimal NULL,
	-- Production Forecast is where Refinery forecasts production of Product in Supply Period and Product has Product Name,
	ProductName                             varchar NOT NULL,
	-- Production Forecast is for Quantity,
	Quantity                                int NOT NULL,
	-- Production Forecast is where Refinery forecasts production of Product in Supply Period and Refinery has Refinery Name,
	RefineryName                            varchar(80) NOT NULL,
	-- Production Forecast is where Refinery forecasts production of Product in Supply Period and Supply Period is in Month and Month has Month Nr,
	SupplyPeriodMonthNr                     int NOT NULL CHECK((SupplyPeriodMonthNr >= 1 AND SupplyPeriodMonthNr <= 12)),
	-- Production Forecast is where Refinery forecasts production of Product in Supply Period and Supply Period is in Year and Year has Year Nr,
	SupplyPeriodYearNr                      int NOT NULL,
	PRIMARY KEY(RefineryName, ProductName, SupplyPeriodYearNr, SupplyPeriodMonthNr)
)
GO

CREATE TABLE RegionalDemand (
	-- Regional Demand is where Region will need Product in Supply Period and Product has Product Name,
	ProductName                             varchar NOT NULL,
	-- maybe Regional Demand is for Quantity,
	Quantity                                int NULL,
	-- Regional Demand is where Region will need Product in Supply Period and Region has Region Name,
	RegionName                              varchar NOT NULL,
	-- Regional Demand is where Region will need Product in Supply Period and Supply Period is in Month and Month has Month Nr,
	SupplyPeriodMonthNr                     int NOT NULL CHECK((SupplyPeriodMonthNr >= 1 AND SupplyPeriodMonthNr <= 12)),
	-- Regional Demand is where Region will need Product in Supply Period and Supply Period is in Year and Year has Year Nr,
	SupplyPeriodYearNr                      int NOT NULL,
	PRIMARY KEY(RegionName, ProductName, SupplyPeriodYearNr, SupplyPeriodMonthNr)
)
GO

CREATE TABLE TransportRoute (
	-- maybe Transport Route incurs Cost per kl,
	Cost                                    decimal NULL,
	-- Transport Route is where Transport Method transportation is available from Refinery to Region and Refinery has Refinery Name,
	RefineryName                            varchar(80) NOT NULL,
	-- Transport Route is where Transport Method transportation is available from Refinery to Region and Region has Region Name,
	RegionName                              varchar NOT NULL,
	-- Transport Route is where Transport Method transportation is available from Refinery to Region,
	TransportMethod                         varchar NOT NULL CHECK(TransportMethod = 'Rail' OR TransportMethod = 'Road' OR TransportMethod = 'Sea'),
	PRIMARY KEY(TransportMethod, RefineryName, RegionName)
)
GO

