vocabulary Warehousing;

/*
 * Value Types
 */
BinID is defined as AutoCounter();
DispatchID is defined as AutoCounter();
DispatchItemID is defined as AutoCounter();
PartyID is defined as AutoCounter();
ProductID is defined as AutoCounter();
PurchaseOrderID is defined as AutoCounter();
ReceiptID is defined as AutoCounter();
ReceivedItemID is defined as AutoCounter();
SalesOrderID is defined as AutoCounter();
TransferRequestID is defined as AutoCounter();
WarehouseID is defined as AutoCounter();

/*
 * Entity Types
 */
Bin is identified by BinID where
	Bin has exactly one BinID,
	BinID is of at most one Bin;

Dispatch is identified by DispatchID where
	Dispatch has exactly one DispatchID,
	DispatchID is of at most one Dispatch;

DispatchItem is identified by DispatchItemID where
	DispatchItem has exactly one DispatchItemID,
	DispatchItemID is of at most one DispatchItem;
Dispatch is of at least one DispatchItem,
	DispatchItem is for at most one Dispatch;

Party is identified by PartyID where
	Party has exactly one PartyID,
	PartyID is of at most one Party;

Product is identified by ProductID where
	Product has exactly one ProductID,
	ProductID is of at most one Product;
DispatchItem is exactly one Product;

PurchaseOrder is identified by PurchaseOrderID where
	PurchaseOrder has exactly one PurchaseOrderID,
	PurchaseOrderID is of at most one PurchaseOrder;

PurchaseOrderItem is identified by PurchaseOrder and Product where
	PurchaseOrder includes PurchaseOrderItem,
	PurchaseOrderItem is part of exactly one PurchaseOrder,
	PurchaseOrderItem is for exactly one Product;

Receipt is identified by ReceiptID where
	Receipt has exactly one ReceiptID,
	ReceiptID is of at most one Receipt;

ReceivedItem is identified by ReceivedItemID where
	ReceivedItem has exactly one ReceivedItemID,
	ReceivedItemID is of at most one ReceivedItem;
Receipt is of at least one ReceivedItem,
	ReceivedItem has at most one Receipt;
ReceivedItem is exactly one Product;
ReceivedItem is for at most one PurchaseOrderItem;

SalesOrder is identified by SalesOrderID where
	SalesOrder has exactly one SalesOrderID,
	SalesOrderID is of at most one SalesOrder;

SalesOrderItem is identified by SalesOrder and Product where
	SalesOrder includes SalesOrderItem,
	SalesOrderItem is part of exactly one SalesOrder,
	SalesOrderItem is for exactly one Product;
DispatchItem is for at most one SalesOrderItem;
DirectOrderMatch is where
	PurchaseOrderItem matches SalesOrderItem;

Supplier is a kind of Party;
PurchaseOrder is to exactly one Supplier,
	Supplier supplies PurchaseOrder;

TransferRequest is identified by TransferRequestID where
	TransferRequest has exactly one TransferRequestID,
	TransferRequestID is of at most one TransferRequest;
DispatchItem is for at most one TransferRequest;
ReceivedItem is for at most one TransferRequest;

Warehouse is identified by WarehouseID where
	Warehouse has exactly one WarehouseID,
	WarehouseID is of at most one Warehouse;
PurchaseOrder is to at most one Warehouse;
SalesOrder is from at most one Warehouse;
TransferRequest is from at most one Warehouse;
TransferRequest is to at most one Warehouse;
Warehouse contains exactly one Bin;
StockedProduct is where
	Warehouse contains Product;
StockedProduct is in Bin,
	Bin contains at most one StockedProduct;

Customer is a kind of Party;
Customer made SalesOrder,
	SalesOrder was made by exactly one Customer;

/*
 * Constraints:
 */
for each ReceivedItem exactly one of these holds:
	ReceivedItem is for PurchaseOrderItem,
	ReceivedItem is for TransferRequest;
for each DispatchItem exactly one of these holds:
	DispatchItem is for TransferRequest,
	DispatchItem is for SalesOrderItem;
