CREATE TABLE AcceptableSubstitutes (
	AlternateProduct	varchar(80) NOT NULL,
	Product	varchar(80) NOT NULL,
	Season	varchar(6) NOT NULL,
	PRIMARY KEY(Product, AlternateProduct, Season)
)
GO

CREATE TABLE Month (
	MonthValue	varchar(3) NULL,
	Season	varchar(6) NOT NULL,
	PRIMARY KEY(Month)
)
GO

CREATE TABLE ProductionCommitment (
	Month	varchar(3) NOT NULL,
	Product	varchar(80) NOT NULL,
	RefineryName	varchar(80) NOT NULL,
	Quantity	int NOT NULL,
	UNIQUE(RefineryName, Month, Product),
	FOREIGN KEY()
	REFERENCES Month()
)
GO

CREATE TABLE RegionalDemand (
	Month	varchar(3) NOT NULL,
	Product	varchar(80) NOT NULL,
	Region	varchar(80) NOT NULL,
	Year	int NOT NULL,
	Quantity	int NOT NULL,
	PRIMARY KEY(Region, Month, Year, Product),
	FOREIGN KEY()
	REFERENCES Month()
)
GO

CREATE TABLE TransportRoute (
	RefineryName	varchar(80) NOT NULL,
	Region	varchar(80) NOT NULL,
	Transportation	varchar NOT NULL,
	UNIQUE(Transportation, RefineryName, Region)
)
GO

