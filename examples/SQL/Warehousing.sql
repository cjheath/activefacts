CREATE TABLE Bin (
	-- Bin has BinID,
	BinID                                   int IDENTITY NOT NULL,
	-- maybe Product is stocked in Bin and Product has ProductID,
	ProductID                               int NULL,
	-- Bin contains Quantity,
	Quantity                                int NOT NULL,
	-- maybe Warehouse contains Bin and Warehouse has WarehouseID,
	WarehouseID                             int NULL,
	PRIMARY KEY(BinID)
)
GO

CREATE TABLE DirectOrderMatch (
	-- DirectOrderMatch is where PurchaseOrderItem matches SalesOrderItem and PurchaseOrderItem is for Product and Product has ProductID,
	PurchaseOrderItemProductID              int NOT NULL,
	-- DirectOrderMatch is where PurchaseOrderItem matches SalesOrderItem and PurchaseOrder includes PurchaseOrderItem and PurchaseOrder has PurchaseOrderID,
	PurchaseOrderItemPurchaseOrderID        int NOT NULL,
	-- DirectOrderMatch is where PurchaseOrderItem matches SalesOrderItem and SalesOrderItem is for Product and Product has ProductID,
	SalesOrderItemProductID                 int NOT NULL,
	-- DirectOrderMatch is where PurchaseOrderItem matches SalesOrderItem and SalesOrder includes SalesOrderItem and SalesOrder has SalesOrderID,
	SalesOrderItemSalesOrderID              int NOT NULL,
	PRIMARY KEY(PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID, SalesOrderItemSalesOrderID, SalesOrderItemProductID)
)
GO

CREATE TABLE DispatchItem (
	-- maybe Dispatch is of DispatchItem and Dispatch has DispatchID,
	DispatchID                              int NULL,
	-- DispatchItem has DispatchItemID,
	DispatchItemID                          int IDENTITY NOT NULL,
	-- DispatchItem is Product and Product has ProductID,
	ProductID                               int NOT NULL,
	-- DispatchItem is in Quantity,
	Quantity                                int NOT NULL,
	-- maybe DispatchItem is for SalesOrderItem and SalesOrderItem is for Product and Product has ProductID,
	SalesOrderItemProductID                 int NULL,
	-- maybe DispatchItem is for SalesOrderItem and SalesOrder includes SalesOrderItem and SalesOrder has SalesOrderID,
	SalesOrderItemSalesOrderID              int NULL,
	-- maybe DispatchItem is for TransferRequest and TransferRequest has TransferRequestID,
	TransferRequestID                       int NULL,
	PRIMARY KEY(DispatchItemID)
)
GO

CREATE TABLE Party (
	-- Party has PartyID,
	PartyID                                 int IDENTITY NOT NULL,
	PRIMARY KEY(PartyID)
)
GO

CREATE TABLE Product (
	-- Product has ProductID,
	ProductID                               int IDENTITY NOT NULL,
	PRIMARY KEY(ProductID)
)
GO

CREATE TABLE PurchaseOrder (
	-- PurchaseOrder has PurchaseOrderID,
	PurchaseOrderID                         int IDENTITY NOT NULL,
	-- PurchaseOrder is to Supplier and Party has PartyID,
	SupplierID                              int NOT NULL,
	-- PurchaseOrder is to Warehouse and Warehouse has WarehouseID,
	WarehouseID                             int NOT NULL,
	PRIMARY KEY(PurchaseOrderID),
	FOREIGN KEY (SupplierID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE PurchaseOrderItem (
	-- PurchaseOrderItem is for Product and Product has ProductID,
	ProductID                               int NOT NULL,
	-- PurchaseOrder includes PurchaseOrderItem and PurchaseOrder has PurchaseOrderID,
	PurchaseOrderID                         int NOT NULL,
	-- PurchaseOrderItem is in Quantity,
	Quantity                                int NOT NULL,
	PRIMARY KEY(PurchaseOrderID, ProductID),
	FOREIGN KEY (ProductID) REFERENCES Product (ProductID),
	FOREIGN KEY (PurchaseOrderID) REFERENCES PurchaseOrder (PurchaseOrderID)
)
GO

CREATE TABLE ReceivedItem (
	-- ReceivedItem is Product and Product has ProductID,
	ProductID                               int NOT NULL,
	-- maybe ReceivedItem is for PurchaseOrderItem and PurchaseOrderItem is for Product and Product has ProductID,
	PurchaseOrderItemProductID              int NULL,
	-- maybe ReceivedItem is for PurchaseOrderItem and PurchaseOrder includes PurchaseOrderItem and PurchaseOrder has PurchaseOrderID,
	PurchaseOrderItemPurchaseOrderID        int NULL,
	-- ReceivedItem is in Quantity,
	Quantity                                int NOT NULL,
	-- maybe Receipt is of ReceivedItem and Receipt has ReceiptID,
	ReceiptID                               int NULL,
	-- ReceivedItem has ReceivedItemID,
	ReceivedItemID                          int IDENTITY NOT NULL,
	-- maybe ReceivedItem is for TransferRequest and TransferRequest has TransferRequestID,
	TransferRequestID                       int NULL,
	PRIMARY KEY(ReceivedItemID),
	FOREIGN KEY (ProductID) REFERENCES Product (ProductID),
	FOREIGN KEY (PurchaseOrderItemProductID, PurchaseOrderItemPurchaseOrderID) REFERENCES PurchaseOrderItem (ProductID, PurchaseOrderID)
)
GO

CREATE TABLE SalesOrder (
	-- Customer made SalesOrder and Party has PartyID,
	CustomerID                              int NOT NULL,
	-- SalesOrder has SalesOrderID,
	SalesOrderID                            int IDENTITY NOT NULL,
	-- SalesOrder is from Warehouse and Warehouse has WarehouseID,
	WarehouseID                             int NOT NULL,
	PRIMARY KEY(SalesOrderID),
	FOREIGN KEY (CustomerID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE SalesOrderItem (
	-- SalesOrderItem is for Product and Product has ProductID,
	ProductID                               int NOT NULL,
	-- SalesOrderItem is in Quantity,
	Quantity                                int NOT NULL,
	-- SalesOrder includes SalesOrderItem and SalesOrder has SalesOrderID,
	SalesOrderID                            int NOT NULL,
	PRIMARY KEY(SalesOrderID, ProductID),
	FOREIGN KEY (ProductID) REFERENCES Product (ProductID),
	FOREIGN KEY (SalesOrderID) REFERENCES SalesOrder (SalesOrderID)
)
GO

CREATE TABLE TransferRequest (
	-- maybe TransferRequest is from-Warehouse and Warehouse has WarehouseID,
	FromWarehouseID                         int NULL,
	-- maybe TransferRequest is to-Warehouse and Warehouse has WarehouseID,
	ToWarehouseID                           int NULL,
	-- TransferRequest has TransferRequestID,
	TransferRequestID                       int IDENTITY NOT NULL,
	PRIMARY KEY(TransferRequestID)
)
GO

CREATE TABLE Warehouse (
	-- Warehouse has WarehouseID,
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
	ADD FOREIGN KEY (PurchaseOrderItemProductID, PurchaseOrderItemPurchaseOrderID) REFERENCES PurchaseOrderItem (ProductID, PurchaseOrderID)
GO

ALTER TABLE DirectOrderMatch
	ADD FOREIGN KEY (SalesOrderItemProductID, SalesOrderItemSalesOrderID) REFERENCES SalesOrderItem (ProductID, SalesOrderID)
GO

ALTER TABLE DispatchItem
	ADD FOREIGN KEY (ProductID) REFERENCES Product (ProductID)
GO

ALTER TABLE DispatchItem
	ADD FOREIGN KEY (SalesOrderItemProductID, SalesOrderItemSalesOrderID) REFERENCES SalesOrderItem (ProductID, SalesOrderID)
GO

ALTER TABLE DispatchItem
	ADD FOREIGN KEY (TransferRequestID) REFERENCES TransferRequest (TransferRequestID)
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

