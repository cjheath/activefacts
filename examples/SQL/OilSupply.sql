CREATE TABLE AcceptableSubstitutes (
	ProductName                             varchar NOT NULL,
	AlternateProductName                    varchar NOT NULL,
	Season                                  varchar(6) NOT NULL CHECK(Season = 'Spring' OR Season = 'Summer' OR Season = 'Autumn' OR Season = 'Winter'),
	PRIMARY KEY(ProductName, AlternateProductName, Season)
)
GO

CREATE TABLE Month (
	Season                                  varchar(6) NOT NULL CHECK(Season = 'Spring' OR Season = 'Summer' OR Season = 'Autumn' OR Season = 'Winter'),
	MonthCode                               char NOT NULL,
	PRIMARY KEY(MonthCode)
)
GO

CREATE TABLE ProductionForecast (
	RefineryName                            varchar(80) NOT NULL,
	ProductName                             varchar NOT NULL,
	SupplyPeriodYearNr                      int NOT NULL,
	SupplyPeriodMonthCode                   char NOT NULL,
	Quantity                                int NOT NULL,
	Cost                                    decimal NULL,
	PRIMARY KEY(RefineryName, ProductName, SupplyPeriodYearNr, SupplyPeriodMonthCode)
)
GO

CREATE TABLE RegionalDemand (
	RegionName                              varchar NOT NULL,
	ProductName                             varchar NOT NULL,
	SupplyPeriodYearNr                      int NOT NULL,
	SupplyPeriodMonthCode                   char NOT NULL,
	Quantity                                int NULL,
	PRIMARY KEY(RegionName, ProductName, SupplyPeriodYearNr, SupplyPeriodMonthCode)
)
GO

CREATE TABLE TransportRoute (
	TransportMethod                         varchar NOT NULL CHECK(TransportMethod = 'Rail' OR TransportMethod = 'Road' OR TransportMethod = 'Sea'),
	RefineryName                            varchar(80) NOT NULL,
	RegionName                              varchar NOT NULL,
	Cost                                    decimal NULL,
	PRIMARY KEY(TransportMethod, RefineryName, RegionName)
)
GO

