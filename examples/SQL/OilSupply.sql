CREATE TABLE AcceptableSubstitution (
	-- Acceptable Substitution involves Product and Product has Product Name,
	AlternateProductName                    varchar NOT NULL,
	-- Acceptable Substitution involves Product and Product has Product Name,
	ProductName                             varchar NOT NULL,
	-- Acceptable Substitution involves Season,
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

CREATE TABLE Product (
	-- Product has Product Name,
	ProductName                             varchar NOT NULL,
	PRIMARY KEY(ProductName)
)
GO

CREATE TABLE ProductionForecast (
	-- maybe Production Forecast predicts Cost,
	Cost                                    decimal NULL,
	-- Production Forecast involves Product and Product has Product Name,
	ProductName                             varchar NOT NULL,
	-- Production Forecast involves Quantity,
	Quantity                                int NOT NULL,
	-- Production Forecast involves Refinery and Refinery has Refinery Name,
	RefineryName                            varchar(80) NOT NULL,
	-- Production Forecast involves Supply Period and Supply Period is in Month and Month has Month Nr,
	SupplyPeriodMonthNr                     int NOT NULL CHECK((SupplyPeriodMonthNr >= 1 AND SupplyPeriodMonthNr <= 12)),
	-- Production Forecast involves Supply Period and Supply Period is in Year and Year has Year Nr,
	SupplyPeriodYearNr                      int NOT NULL,
	PRIMARY KEY(RefineryName, SupplyPeriodYearNr, SupplyPeriodMonthNr, ProductName),
	FOREIGN KEY (SupplyPeriodMonthNr) REFERENCES Month (MonthNr),
	FOREIGN KEY (ProductName) REFERENCES Product (ProductName)
)
GO

CREATE TABLE Refinery (
	-- Refinery has Refinery Name,
	RefineryName                            varchar(80) NOT NULL,
	PRIMARY KEY(RefineryName)
)
GO

CREATE TABLE Region (
	-- Region has Region Name,
	RegionName                              varchar NOT NULL,
	PRIMARY KEY(RegionName)
)
GO

CREATE TABLE RegionalDemand (
	-- Regional Demand involves Product and Product has Product Name,
	ProductName                             varchar NOT NULL,
	-- Regional Demand involves Quantity,
	Quantity                                int NOT NULL,
	-- Regional Demand involves Region and Region has Region Name,
	RegionName                              varchar NOT NULL,
	-- Regional Demand involves Supply Period and Supply Period is in Month and Month has Month Nr,
	SupplyPeriodMonthNr                     int NOT NULL CHECK((SupplyPeriodMonthNr >= 1 AND SupplyPeriodMonthNr <= 12)),
	-- Regional Demand involves Supply Period and Supply Period is in Year and Year has Year Nr,
	SupplyPeriodYearNr                      int NOT NULL,
	PRIMARY KEY(RegionName, SupplyPeriodYearNr, SupplyPeriodMonthNr, ProductName),
	FOREIGN KEY (SupplyPeriodMonthNr) REFERENCES Month (MonthNr),
	FOREIGN KEY (ProductName) REFERENCES Product (ProductName),
	FOREIGN KEY (RegionName) REFERENCES Region (RegionName)
)
GO

CREATE TABLE TransportRoute (
	-- maybe Transport Route incurs Cost per kl,
	Cost                                    decimal NULL,
	-- Transport Route involves Refinery and Refinery has Refinery Name,
	RefineryName                            varchar(80) NOT NULL,
	-- Transport Route involves Region and Region has Region Name,
	RegionName                              varchar NOT NULL,
	-- Transport Route involves Transport Method,
	TransportMethod                         varchar NOT NULL CHECK(TransportMethod = 'Rail' OR TransportMethod = 'Road' OR TransportMethod = 'Sea'),
	PRIMARY KEY(TransportMethod, RefineryName, RegionName),
	FOREIGN KEY (RefineryName) REFERENCES Refinery (RefineryName),
	FOREIGN KEY (RegionName) REFERENCES Region (RegionName)
)
GO

ALTER TABLE AcceptableSubstitution
	ADD FOREIGN KEY (AlternateProductName) REFERENCES Product (ProductName)
GO

ALTER TABLE AcceptableSubstitution
	ADD FOREIGN KEY (ProductName) REFERENCES Product (ProductName)
GO

ALTER TABLE ProductionForecast
	ADD FOREIGN KEY (RefineryName) REFERENCES Refinery (RefineryName)
GO

