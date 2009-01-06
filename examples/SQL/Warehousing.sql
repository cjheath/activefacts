CREATE TABLE Bin (
	ProductID                               AutoCounter NULL,
	BinID                                   AutoCounter NOT NULL,
	WarehouseID                             AutoCounter NULL,
	Quantity                                UnsignedInteger(32) NOT NULL,
	PRIMARY KEY(BinID)
)
GO

CREATE TABLE DirectOrderMatch (
	PurchaseOrderItemPurchaseOrderID        AutoCounter NOT NULL,
	PurchaseOrderItemProductID              AutoCounter NOT NULL,
	SalesOrderItemSalesOrderID              AutoCounter NOT NULL,
	SalesOrderItemProductID                 AutoCounter NOT NULL,
	PRIMARY KEY(PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID, SalesOrderItemSalesOrderID, SalesOrderItemProductID)
)
GO

CREATE TABLE DispatchItem (
	ProductID                               AutoCounter NOT NULL,
	TransferRequestID                       AutoCounter NULL,
	SalesOrderItemSalesOrderID              AutoCounter NULL,
	SalesOrderItemProductID                 AutoCounter NULL,
	DispatchItemID                          AutoCounter NOT NULL,
	DispatchID                              AutoCounter NULL,
	Quantity                                UnsignedInteger(32) NOT NULL,
	PRIMARY KEY(DispatchItemID)
)
GO

CREATE TABLE Party (
	PartyID                                 AutoCounter NOT NULL,
	PRIMARY KEY(PartyID)
)
GO

CREATE TABLE Product (
	ProductID                               AutoCounter NOT NULL,
	PRIMARY KEY(ProductID)
)
GO

CREATE TABLE PurchaseOrder (
	SupplierID                              AutoCounter NOT NULL,
	PurchaseOrderID                         AutoCounter NOT NULL,
	WarehouseID                             AutoCounter NOT NULL,
	PRIMARY KEY(PurchaseOrderID)
)
GO

CREATE TABLE PurchaseOrderItem (
	ProductID                               AutoCounter NOT NULL,
	PurchaseOrderID                         AutoCounter NOT NULL,
	Quantity                                UnsignedInteger(32) NOT NULL,
	PRIMARY KEY(PurchaseOrderID, ProductID)
)
GO

CREATE TABLE ReceivedItem (
	PurchaseOrderItemPurchaseOrderID        AutoCounter NULL,
	PurchaseOrderItemProductID              AutoCounter NULL,
	TransferRequestID                       AutoCounter NULL,
	ProductID                               AutoCounter NOT NULL,
	ReceivedItemID                          AutoCounter NOT NULL,
	ReceiptID                               AutoCounter NULL,
	Quantity                                UnsignedInteger(32) NOT NULL,
	PRIMARY KEY(ReceivedItemID)
)
GO

CREATE TABLE SalesOrder (
	SalesOrderID                            AutoCounter NOT NULL,
	CustomerID                              AutoCounter NOT NULL,
	WarehouseID                             AutoCounter NOT NULL,
	PRIMARY KEY(SalesOrderID)
)
GO

CREATE TABLE SalesOrderItem (
	ProductID                               AutoCounter NOT NULL,
	SalesOrderID                            AutoCounter NOT NULL,
	Quantity                                UnsignedInteger(32) NOT NULL,
	PRIMARY KEY(SalesOrderID, ProductID)
)
GO

CREATE TABLE TransferRequest (
	TransferRequestID                       AutoCounter NOT NULL,
	FromWarehouseID                         AutoCounter NULL,
	ToWarehouseID                           AutoCounter NULL,
	PRIMARY KEY(TransferRequestID)
)
GO

CREATE TABLE Warehouse (
	WarehouseID                             AutoCounter NOT NULL,
	PRIMARY KEY(WarehouseID)
)
GO

