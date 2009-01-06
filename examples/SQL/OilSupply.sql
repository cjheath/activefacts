CREATE TABLE AcceptableSubstitutes (
	ProductName                             VariableLengthText NOT NULL,
	AlternateProductName                    VariableLengthText NOT NULL,
	Season                                  VariableLengthText(6) NOT NULL CHECK(REVISIT: valid value),
	PRIMARY KEY(ProductName, AlternateProductName, Season)
)
GO

CREATE TABLE Month (
	Season                                  VariableLengthText(6) NOT NULL CHECK(REVISIT: valid value),
	MonthCode                               FixedLengthText NOT NULL,
	PRIMARY KEY(MonthCode)
)
GO

CREATE TABLE ProductionForecast (
	RefineryName                            VariableLengthText(80) NOT NULL,
	ProductName                             VariableLengthText NOT NULL,
	SupplyPeriodYearNr                      SignedInteger(32) NOT NULL,
	SupplyPeriodMonthCode                   FixedLengthText NOT NULL,
	Quantity                                UnsignedInteger(32) NOT NULL,
	Cost                                    Money NULL,
	PRIMARY KEY(RefineryName, ProductName, SupplyPeriodYearNr, SupplyPeriodMonthCode)
)
GO

CREATE TABLE RegionalDemand (
	RegionName                              VariableLengthText NOT NULL,
	ProductName                             VariableLengthText NOT NULL,
	SupplyPeriodYearNr                      SignedInteger(32) NOT NULL,
	SupplyPeriodMonthCode                   FixedLengthText NOT NULL,
	Quantity                                UnsignedInteger(32) NULL,
	PRIMARY KEY(RegionName, ProductName, SupplyPeriodYearNr, SupplyPeriodMonthCode)
)
GO

CREATE TABLE TransportRoute (
	TransportMethod                         VariableLengthText NOT NULL CHECK(REVISIT: valid value),
	RefineryName                            VariableLengthText(80) NOT NULL,
	RegionName                              VariableLengthText NOT NULL,
	Cost                                    Money NULL,
	PRIMARY KEY(TransportMethod, RefineryName, RegionName)
)
GO

