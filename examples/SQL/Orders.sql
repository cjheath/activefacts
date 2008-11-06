CREATE TABLE OrderLine (
	Number	int NOT NULL,
	OrderID	int NOT NULL,
	QuantityNumber	int NULL,
	SKUID	int NULL,
	UNIQUE(OrderID, Number)
)
GO

CREATE TABLE SKU (
	SKUID	int NOT NULL,
	Description	varchar(120) NULL,
	UNIQUE(SKUID)
)
GO

ALTER TABLE OrderLine
	ADD FOREIGN KEY(SKUID)
	REFERENCES SKU(SKUID)
GO

