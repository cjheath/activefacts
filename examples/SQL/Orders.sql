CREATE TABLE SKU (
	SKUID	int NOT NULL,
	Description	varchar(120) NULL,
	UNIQUE(SKUID)
)
GO

CREATE TABLE OrderLine (
	OrderID	int NOT NULL,
	SKUID	int NULL,
	Number	int NOT NULL,
	QuantityNumber	int NULL,
	UNIQUE(OrderID, Number)
)
GO

