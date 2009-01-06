CREATE TABLE Bin (
	ProductID                               int NULL,
	BinID                                   int IDENTITY NOT NULL,
	WarehouseID                             int NULL,
	Quantity                                int NOT NULL,
	PRIMARY KEY(BinID)
)
GO

CREATE TABLE DirectOrderMatch (
	PurchaseOrderItemPurchaseOrderID        int NOT NULL,
	PurchaseOrderItemProductID              int NOT NULL,
	SalesOrderItemSalesOrderID              int NOT NULL,
	SalesOrderItemProductID                 int NOT NULL,
	PRIMARY KEY(PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID, SalesOrderItemSalesOrderID, SalesOrderItemProductID)
)
GO

CREATE TABLE DispatchItem (
	ProductID                               int NOT NULL,
	TransferRequestID                       int NULL,
	SalesOrderItemSalesOrderID              int NULL,
	SalesOrderItemProductID                 int NULL,
	DispatchItemID                          int IDENTITY NOT NULL,
	DispatchID                              int NULL,
	Quantity                                int NOT NULL,
	PRIMARY KEY(DispatchItemID)
)
GO

CREATE TABLE Party (
	PartyID                                 int IDENTITY NOT NULL,
	PRIMARY KEY(PartyID)
)
GO

CREATE TABLE Product (
	ProductID                               int IDENTITY NOT NULL,
	PRIMARY KEY(ProductID)
)
GO

CREATE TABLE PurchaseOrder (
	SupplierID                              int NOT NULL,
	PurchaseOrderID                         int IDENTITY NOT NULL,
	WarehouseID                             int NOT NULL,
	PRIMARY KEY(PurchaseOrderID),
	FOREIGN KEY (SupplierID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE PurchaseOrderItem (
	ProductID                               int NOT NULL,
	PurchaseOrderID                         int NOT NULL,
	Quantity                                int NOT NULL,
	PRIMARY KEY(PurchaseOrderID, ProductID),
	FOREIGN KEY (ProductID) REFERENCES Product (ProductID),
	FOREIGN KEY (PurchaseOrderID) REFERENCES PurchaseOrder (PurchaseOrderID)
)
GO

CREATE TABLE ReceivedItem (
	PurchaseOrderItemPurchaseOrderID        int NULL,
	PurchaseOrderItemProductID              int NULL,
	TransferRequestID                       int NULL,
	ProductID                               int NOT NULL,
	ReceivedItemID                          int IDENTITY NOT NULL,
	ReceiptID                               int NULL,
	Quantity                                int NOT NULL,
	PRIMARY KEY(ReceivedItemID),
	FOREIGN KEY (PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID) REFERENCES PurchaseOrderItem (PurchaseOrderID, ProductID),
	FOREIGN KEY (ProductID) REFERENCES Product (ProductID)
)
GO

CREATE TABLE SalesOrder (
	SalesOrderID                            int IDENTITY NOT NULL,
	CustomerID                              int NOT NULL,
	WarehouseID                             int NOT NULL,
	PRIMARY KEY(SalesOrderID),
	FOREIGN KEY (CustomerID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE SalesOrderItem (
	ProductID                               int NOT NULL,
	SalesOrderID                            int NOT NULL,
	Quantity                                int NOT NULL,
	PRIMARY KEY(SalesOrderID, ProductID),
	FOREIGN KEY (ProductID) REFERENCES Product (ProductID),
	FOREIGN KEY (SalesOrderID) REFERENCES SalesOrder (SalesOrderID)
)
GO

CREATE TABLE TransferRequest (
	TransferRequestID                       int IDENTITY NOT NULL,
	FromWarehouseID                         int NULL,
	ToWarehouseID                           int NULL,
	PRIMARY KEY(TransferRequestID)
)
GO

CREATE TABLE Warehouse (
	WarehouseID                             int IDENTITY NOT NULL,
	PRIMARY KEY(WarehouseID)
)
GO

ALTER TABLE Bin
	ADD FOREIGN KEY (ProductID) REFERENCES Product (ProductID)
GO

ALTER TABLE Bin
	ADD FOREIGN KEY (WarehouseID) REFERENCES Warehouse (WarehouseID)
GO

ALTER TABLE DirectOrderMatch
	ADD FOREIGN KEY (PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID) REFERENCES PurchaseOrderItem (PurchaseOrderID, ProductID)
GO

ALTER TABLE DirectOrderMatch
	ADD FOREIGN KEY (SalesOrderItemSalesOrderID, SalesOrderItemProductID) REFERENCES SalesOrderItem (SalesOrderID, ProductID)
GO

ALTER TABLE DispatchItem
	ADD FOREIGN KEY (ProductID) REFERENCES Product (ProductID)
GO

ALTER TABLE DispatchItem
	ADD FOREIGN KEY (TransferRequestID) REFERENCES TransferRequest (TransferRequestID)
GO

ALTER TABLE DispatchItem
	ADD FOREIGN KEY (SalesOrderItemSalesOrderID, SalesOrderItemProductID) REFERENCES SalesOrderItem (SalesOrderID, ProductID)
GO

ALTER TABLE PurchaseOrder
	ADD FOREIGN KEY (WarehouseID) REFERENCES Warehouse (WarehouseID)
GO

ALTER TABLE ReceivedItem
	ADD FOREIGN KEY (TransferRequestID) REFERENCES TransferRequest (TransferRequestID)
GO

ALTER TABLE SalesOrder
	ADD FOREIGN KEY (WarehouseID) REFERENCES Warehouse (WarehouseID)
GO

ALTER TABLE TransferRequest
	ADD FOREIGN KEY (FromWarehouseID) REFERENCES Warehouse (WarehouseID)
GO

ALTER TABLE TransferRequest
	ADD FOREIGN KEY (ToWarehouseID) REFERENCES Warehouse (WarehouseID)
GO

