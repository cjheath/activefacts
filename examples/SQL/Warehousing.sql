CREATE TABLE BackOrderAllocation (
	-- Back Order Allocation involves Purchase Order Item and Purchase Order Item is for Product and Product has Product ID,
	PurchaseOrderItemProductID              int NOT NULL,
	-- Back Order Allocation involves Purchase Order Item and Purchase Order Item is part of Purchase Order and Purchase Order has Purchase Order ID,
	PurchaseOrderItemPurchaseOrderID        int NOT NULL,
	-- Back Order Allocation is for Quantity,
	Quantity                                int NOT NULL,
	-- Back Order Allocation involves Sales Order Item and Sales Order Item is for Product and Product has Product ID,
	SalesOrderItemProductID                 int NOT NULL,
	-- Back Order Allocation involves Sales Order Item and Sales Order Item is part of Sales Order and Sales Order has Sales Order ID,
	SalesOrderItemSalesOrderID              int NOT NULL,
	PRIMARY KEY(PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID, SalesOrderItemSalesOrderID, SalesOrderItemProductID)
)
GO

CREATE TABLE Bin (
	-- Bin has Bin ID,
	BinID                                   int IDENTITY NOT NULL,
	-- maybe Bin contains Product and Product has Product ID,
	ProductID                               int NULL,
	-- Bin contains Quantity,
	Quantity                                int NOT NULL,
	-- maybe Warehouse contains Bin and Warehouse has Warehouse ID,
	WarehouseID                             int NULL,
	PRIMARY KEY(BinID)
)
GO

CREATE TABLE DispatchItem (
	-- maybe Dispatch Item is for Dispatch and Dispatch has Dispatch ID,
	DispatchID                              int NULL,
	-- Dispatch Item has Dispatch Item ID,
	DispatchItemID                          int IDENTITY NOT NULL,
	-- Dispatch Item is Product and Product has Product ID,
	ProductID                               int NOT NULL,
	-- Dispatch Item is in Quantity,
	Quantity                                int NOT NULL,
	-- maybe Dispatch Item is for Sales Order Item and Sales Order Item is for Product and Product has Product ID,
	SalesOrderItemProductID                 int NULL,
	-- maybe Dispatch Item is for Sales Order Item and Sales Order Item is part of Sales Order and Sales Order has Sales Order ID,
	SalesOrderItemSalesOrderID              int NULL,
	-- maybe Dispatch Item is for Transfer Request and Transfer Request has Transfer Request ID,
	TransferRequestID                       int NULL,
	PRIMARY KEY(DispatchItemID)
)
GO

CREATE TABLE Party (
	-- Party has Party ID,
	PartyID                                 int IDENTITY NOT NULL,
	PRIMARY KEY(PartyID)
)
GO

CREATE TABLE Product (
	-- Product has Product ID,
	ProductID                               int IDENTITY NOT NULL,
	PRIMARY KEY(ProductID)
)
GO

CREATE TABLE PurchaseOrder (
	-- Purchase Order has Purchase Order ID,
	PurchaseOrderID                         int IDENTITY NOT NULL,
	-- Purchase Order is to Supplier and Supplier is a kind of Party and Party has Party ID,
	SupplierID                              int NOT NULL,
	-- Purchase Order is to Warehouse and Warehouse has Warehouse ID,
	WarehouseID                             int NOT NULL,
	PRIMARY KEY(PurchaseOrderID),
	FOREIGN KEY (SupplierID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE PurchaseOrderItem (
	-- Purchase Order Item is for Product and Product has Product ID,
	ProductID                               int NOT NULL,
	-- Purchase Order Item is part of Purchase Order and Purchase Order has Purchase Order ID,
	PurchaseOrderID                         int NOT NULL,
	-- Purchase Order Item is in Quantity,
	Quantity                                int NOT NULL,
	PRIMARY KEY(PurchaseOrderID, ProductID),
	FOREIGN KEY (ProductID) REFERENCES Product (ProductID),
	FOREIGN KEY (PurchaseOrderID) REFERENCES PurchaseOrder (PurchaseOrderID)
)
GO

CREATE TABLE ReceivedItem (
	-- Received Item is Product and Product has Product ID,
	ProductID                               int NOT NULL,
	-- maybe Received Item is for Purchase Order Item and Purchase Order Item is for Product and Product has Product ID,
	PurchaseOrderItemProductID              int NULL,
	-- maybe Received Item is for Purchase Order Item and Purchase Order Item is part of Purchase Order and Purchase Order has Purchase Order ID,
	PurchaseOrderItemPurchaseOrderID        int NULL,
	-- Received Item is in Quantity,
	Quantity                                int NOT NULL,
	-- maybe Received Item has Receipt and Receipt has Receipt ID,
	ReceiptID                               int NULL,
	-- Received Item has Received Item ID,
	ReceivedItemID                          int IDENTITY NOT NULL,
	-- maybe Received Item is for Transfer Request and Transfer Request has Transfer Request ID,
	TransferRequestID                       int NULL,
	PRIMARY KEY(ReceivedItemID),
	FOREIGN KEY (ProductID) REFERENCES Product (ProductID),
	FOREIGN KEY (PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID) REFERENCES PurchaseOrderItem (PurchaseOrderID, ProductID)
)
GO

CREATE TABLE SalesOrder (
	-- Sales Order was made by Customer and Customer is a kind of Party and Party has Party ID,
	CustomerID                              int NOT NULL,
	-- Sales Order has Sales Order ID,
	SalesOrderID                            int IDENTITY NOT NULL,
	-- Sales Order is from Warehouse and Warehouse has Warehouse ID,
	WarehouseID                             int NOT NULL,
	PRIMARY KEY(SalesOrderID),
	FOREIGN KEY (CustomerID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE SalesOrderItem (
	-- Sales Order Item is for Product and Product has Product ID,
	ProductID                               int NOT NULL,
	-- Sales Order Item is in Quantity,
	Quantity                                int NOT NULL,
	-- Sales Order Item is part of Sales Order and Sales Order has Sales Order ID,
	SalesOrderID                            int NOT NULL,
	PRIMARY KEY(SalesOrderID, ProductID),
	FOREIGN KEY (ProductID) REFERENCES Product (ProductID),
	FOREIGN KEY (SalesOrderID) REFERENCES SalesOrder (SalesOrderID)
)
GO

CREATE TABLE TransferRequest (
	-- Transfer Request is from Warehouse and Warehouse has Warehouse ID,
	FromWarehouseID                         int NOT NULL,
	-- Transfer Request is for Product and Product has Product ID,
	ProductID                               int NOT NULL,
	-- Transfer Request is for Quantity,
	Quantity                                int NOT NULL,
	-- Transfer Request is to Warehouse and Warehouse has Warehouse ID,
	ToWarehouseID                           int NOT NULL,
	-- Transfer Request has Transfer Request ID,
	TransferRequestID                       int IDENTITY NOT NULL,
	PRIMARY KEY(TransferRequestID),
	FOREIGN KEY (ProductID) REFERENCES Product (ProductID)
)
GO

CREATE TABLE Warehouse (
	-- Warehouse has Warehouse ID,
	WarehouseID                             int IDENTITY NOT NULL,
	PRIMARY KEY(WarehouseID)
)
GO

ALTER TABLE BackOrderAllocation
	ADD FOREIGN KEY (PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID) REFERENCES PurchaseOrderItem (PurchaseOrderID, ProductID)
GO

ALTER TABLE BackOrderAllocation
	ADD FOREIGN KEY (SalesOrderItemSalesOrderID, SalesOrderItemProductID) REFERENCES SalesOrderItem (SalesOrderID, ProductID)
GO

ALTER TABLE Bin
	ADD FOREIGN KEY (ProductID) REFERENCES Product (ProductID)
GO

ALTER TABLE Bin
	ADD FOREIGN KEY (WarehouseID) REFERENCES Warehouse (WarehouseID)
GO

ALTER TABLE DispatchItem
	ADD FOREIGN KEY (ProductID) REFERENCES Product (ProductID)
GO

ALTER TABLE DispatchItem
	ADD FOREIGN KEY (SalesOrderItemSalesOrderID, SalesOrderItemProductID) REFERENCES SalesOrderItem (SalesOrderID, ProductID)
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

