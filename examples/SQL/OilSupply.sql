CREATE TABLE AcceptableSubstitutes (
	ProductName	varchar NOT NULL,
	AlternateProductName	varchar NOT NULL,
	Season	varchar(6) NOT NULL,
	PRIMARY KEY(ProductName, AlternateProductName, Season)
)
GO

CREATE TABLE Month (
	MonthCode	FixedLengthText NOT NULL,
	Season	varchar(6) NOT NULL,
	PRIMARY KEY(MonthCode)
)
GO

CREATE TABLE ProductionForecast (
	RefineryName	varchar(80) NOT NULL,
	ProductName	varchar NOT NULL,
	SupplyPeriodMonthCode	FixedLengthText NOT NULL,
	SupplyPeriodYearNr	int NOT NULL,
	Cost	Money NULL,
	Quantity	int NOT NULL,
	PRIMARY KEY(RefineryName, ProductName, SupplyPeriodMonthCode, SupplyPeriodYearNr)
)
GO

CREATE TABLE RegionalDemand (
	RegionName	varchar NOT NULL,
	ProductName	varchar NOT NULL,
	SupplyPeriodMonthCode	FixedLengthText NOT NULL,
	SupplyPeriodYearNr	int NOT NULL,
	Quantity	int NULL,
	PRIMARY KEY(RegionName, ProductName, SupplyPeriodMonthCode, SupplyPeriodYearNr)
)
GO

CREATE TABLE TransportRoute (
	TransportMethod	varchar NOT NULL,
	RefineryName	varchar(80) NOT NULL,
	RegionName	varchar NOT NULL,
	Cost	Money NULL,
	PRIMARY KEY(TransportMethod, RefineryName, RegionName)
)
GO

