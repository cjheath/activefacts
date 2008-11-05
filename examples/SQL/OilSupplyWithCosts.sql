CREATE TABLE AcceptableSubstitutes (
	AlternateProductName	varchar NOT NULL,
	ProductName	varchar NOT NULL,
	Season	varchar(6) NOT NULL,
	UNIQUE(ProductName, AlternateProductName, Season)
)
GO

CREATE TABLE Month (
	MonthCode	FixedLengthText NOT NULL,
	Season	varchar(6) NOT NULL,
	UNIQUE(MonthCode)
)
GO

CREATE TABLE ProductionForecast (
	ProductName	varchar NOT NULL,
	RefineryName	varchar(80) NOT NULL,
	SupplyPeriodMonthCode	FixedLengthText NOT NULL,
	SupplyPeriodYearNr	int NOT NULL,
	Cost	Money NULL,
	Quantity	int NOT NULL,
	UNIQUE(RefineryName, ProductName, SupplyPeriodMonthCode, SupplyPeriodYearNr)
)
GO

CREATE TABLE RegionalDemand (
	ProductName	varchar NOT NULL,
	RegionName	varchar NOT NULL,
	SupplyPeriodMonthCode	FixedLengthText NOT NULL,
	SupplyPeriodYearNr	int NOT NULL,
	Quantity	int NULL,
	UNIQUE(RegionName, ProductName, SupplyPeriodMonthCode, SupplyPeriodYearNr)
)
GO

CREATE TABLE TransportRoute (
	RefineryName	varchar(80) NOT NULL,
	RegionName	varchar NOT NULL,
	TransportMethod	varchar NOT NULL,
	Cost	Money NULL,
	UNIQUE(TransportMethod, RefineryName, RegionName)
)
GO

