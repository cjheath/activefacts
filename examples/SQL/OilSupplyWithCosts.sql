CREATE TABLE Month (
	Season	varchar(6) NOT NULL,
	MonthCode	MonthCode NOT NULL,
	UNIQUE(MonthCode)
)
GO

CREATE TABLE TransportRoute (
	RefineryName	varchar(80) NOT NULL,
	RegionName	varchar NOT NULL,
	TransportMethod	varchar NOT NULL,
	Cost	Cost NULL,
	UNIQUE(TransportMethod, RefineryName, RegionName)
)
GO

CREATE TABLE ProductionForecast (
	RefineryName	varchar(80) NOT NULL,
	ProductName	varchar NOT NULL,
	SupplyPeriodMonthCode	MonthCode NOT NULL,
	SupplyPeriodYearNr	int NOT NULL,
	Quantity	int NOT NULL,
	Cost	Cost NULL,
	UNIQUE(RefineryName, ProductName, SupplyPeriodMonthCode, SupplyPeriodYearNr)
)
GO

CREATE TABLE RegionalDemand (
	RegionName	varchar NOT NULL,
	ProductName	varchar NOT NULL,
	SupplyPeriodMonthCode	MonthCode NOT NULL,
	SupplyPeriodYearNr	int NOT NULL,
	Quantity	int NULL,
	UNIQUE(RegionName, ProductName, SupplyPeriodMonthCode, SupplyPeriodYearNr)
)
GO

CREATE TABLE AcceptableSubstitutes (
	AlternateProductName	varchar NOT NULL,
	ProductName	varchar NOT NULL,
	Season	varchar(6) NOT NULL,
	UNIQUE(ProductName, AlternateProductName, Season)
)
GO

