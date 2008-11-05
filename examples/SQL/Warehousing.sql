CREATE TABLE Party (
	PartyID	int NOT NULL,
	UNIQUE(PartyID)
)
GO

CREATE TABLE PurchaseOrder (
	SupplierID	int NOT NULL,
	WarehouseID	int NOT NULL,
	PurchaseOrderID	int NOT NULL,
	UNIQUE(PurchaseOrderID)
)
GO

CREATE TABLE PurchaseOrderItem (
	PurchaseOrderID	int NOT NULL,
	ProductID	int NOT NULL,
	Quantity	int NOT NULL,
	UNIQUE(PurchaseOrderID, ProductID)
)
GO

CREATE TABLE Product (
	ProductID	int NOT NULL,
	UNIQUE(ProductID)
)
GO

CREATE TABLE SalesOrder (
	CustomerID	int NOT NULL,
	WarehouseID	int NOT NULL,
	SalesOrderID	int NOT NULL,
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

CREATE TABLE Warehouse (
	WarehouseID	int NOT NULL,
	UNIQUE(WarehouseID)
)
GO

CREATE TABLE Bin (
	WarehouseID	int NULL,
	BinID	int NOT NULL,
	UNIQUE(BinID)
)
GO

CREATE TABLE ReceivedItem (
	PurchaseOrderItemPurchaseOrderID	int NULL,
	PurchaseOrderItemProductID	int NULL,
	ProductID	int NOT NULL,
	TransferRequestID	int NULL,
	ReceiptID	int NULL,
	ReceivedItemID	int NOT NULL,
	Quantity	int NOT NULL,
	UNIQUE(ReceivedItemID)
)
GO

CREATE TABLE TransferRequest (
	FromWarehouseID	int NULL,
	ToWarehouseID	int NULL,
	TransferRequestID	int NOT NULL,
	UNIQUE(TransferRequestID)
)
GO

CREATE TABLE DispatchItem (
	ProductID	int NOT NULL,
	SalesOrderItemSalesOrderID	int NULL,
	SalesOrderItemProductID	int NULL,
	TransferRequestID	int NULL,
	DispatchID	int NULL,
	DispatchItemID	int NOT NULL,
	Quantity	int NOT NULL,
	UNIQUE(DispatchItemID)
)
GO

CREATE TABLE StockedProduct (
	ProductID	int NOT NULL,
	BinID	int NOT NULL,
	Quantity	int NOT NULL,
	UNIQUE(BinID, ProductID)
)
GO

CREATE TABLE DirectOrderMatch (
	PurchaseOrderItemPurchaseOrderID	int NOT NULL,
	PurchaseOrderItemProductID	int NOT NULL,
	SalesOrderItemSalesOrderID	int NOT NULL,
	SalesOrderItemProductID	int NOT NULL,
	UNIQUE(PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID, SalesOrderItemSalesOrderID, SalesOrderItemProductID)
)
GO

