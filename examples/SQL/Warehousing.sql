CREATE TABLE Bin (
	BinID	int NOT NULL,
	WarehouseID	int NULL,
	UNIQUE(BinID)
)
GO

CREATE TABLE DirectOrderMatch (
	PurchaseOrderItemProductID	int NOT NULL,
	PurchaseOrderItemPurchaseOrderID	int NOT NULL,
	SalesOrderItemProductID	int NOT NULL,
	SalesOrderItemSalesOrderID	int NOT NULL,
	UNIQUE(PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID, SalesOrderItemSalesOrderID, SalesOrderItemProductID)
)
GO

CREATE TABLE DispatchItem (
	DispatchItemID	int NOT NULL,
	DispatchID	int NULL,
	ProductID	int NOT NULL,
	Quantity	int NOT NULL,
	SalesOrderItemProductID	int NULL,
	SalesOrderItemSalesOrderID	int NULL,
	TransferRequestID	int NULL,
	UNIQUE(DispatchItemID)
)
GO

CREATE TABLE Party (
	PartyID	int NOT NULL,
	UNIQUE(PartyID)
)
GO

CREATE TABLE Product (
	ProductID	int NOT NULL,
	UNIQUE(ProductID)
)
GO

CREATE TABLE PurchaseOrder (
	PurchaseOrderID	int NOT NULL,
	SupplierID	int NOT NULL,
	WarehouseID	int NOT NULL,
	UNIQUE(PurchaseOrderID)
)
GO

CREATE TABLE PurchaseOrderItem (
	ProductID	int NOT NULL,
	PurchaseOrderID	int NOT NULL,
	Quantity	int NOT NULL,
	UNIQUE(PurchaseOrderID, ProductID)
)
GO

CREATE TABLE ReceivedItem (
	ReceivedItemID	int NOT NULL,
	ProductID	int NOT NULL,
	PurchaseOrderItemProductID	int NULL,
	PurchaseOrderItemPurchaseOrderID	int NULL,
	Quantity	int NOT NULL,
	ReceiptID	int NULL,
	TransferRequestID	int NULL,
	UNIQUE(ReceivedItemID)
)
GO

CREATE TABLE SalesOrder (
	SalesOrderID	int NOT NULL,
	CustomerID	int NOT NULL,
	WarehouseID	int NOT NULL,
	UNIQUE(SalesOrderID)
)
GO

CREATE TABLE SalesOrderItem (
	ProductID	int NOT NULL,
	SalesOrderID	int NOT NULL,
	Quantity	int NOT NULL,
	UNIQUE(SalesOrderID, ProductID)
)
GO

CREATE TABLE StockedProduct (
	BinID	int NOT NULL,
	ProductID	int NOT NULL,
	Quantity	int NOT NULL,
	UNIQUE(BinID, ProductID)
)
GO

CREATE TABLE TransferRequest (
	TransferRequestID	int NOT NULL,
	FromWarehouseID	int NULL,
	ToWarehouseID	int NULL,
	UNIQUE(TransferRequestID)
)
GO

CREATE TABLE Warehouse (
	WarehouseID	int NOT NULL,
	UNIQUE(WarehouseID)
)
GO

