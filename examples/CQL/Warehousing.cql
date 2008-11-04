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
Quantity is defined as UnsignedInteger(32);
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
DispatchItem is in exactly one Quantity;

Party is identified by PartyID where
	Party has exactly one PartyID,
	PartyID is of at most one Party;

Product is identified by ProductID where
	Product has exactly one ProductID,
	ProductID is of at most one Product;
DispatchItem is exactly one Product;
StockedProduct is where
	Product is stocked in Bin;
StockedProduct is in exactly one Quantity;

PurchaseOrder is identified by PurchaseOrderID where
	PurchaseOrder has exactly one PurchaseOrderID,
	PurchaseOrderID is of at most one PurchaseOrder;

PurchaseOrderItem is identified by PurchaseOrder and Product where
	PurchaseOrder includes PurchaseOrderItem,
	PurchaseOrderItem is part of exactly one PurchaseOrder,
	PurchaseOrderItem is for exactly one Product;
PurchaseOrderItem is in exactly one Quantity;

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
ReceivedItem is in exactly one Quantity;

SalesOrder is identified by SalesOrderID where
	SalesOrder has exactly one SalesOrderID,
	SalesOrderID is of at most one SalesOrder;

SalesOrderItem is identified by SalesOrder and Product where
	SalesOrder includes SalesOrderItem,
	SalesOrderItem is part of exactly one SalesOrder,
	SalesOrderItem is for exactly one Product;
DispatchItem is for at most one SalesOrderItem;
SalesOrderItem is in exactly one Quantity;
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
PurchaseOrder is to exactly one Warehouse;
SalesOrder is from exactly one Warehouse;
TransferRequest is at most one from-Warehouse;
TransferRequest is at most one to-Warehouse;
Warehouse contains at least one Bin;

Customer is a kind of Party;
Customer made SalesOrder,
	SalesOrder was made by exactly one Customer;

/*
 * Constraints:
 */
for each DispatchItem exactly one of these holds:
	DispatchItem is for TransferRequest,
	DispatchItem is for SalesOrderItem;
for each ReceivedItem exactly one of these holds:
	ReceivedItem is for PurchaseOrderItem,
	ReceivedItem is for TransferRequest;
PurchaseOrderItem matches SalesOrderItem
	only if PurchaseOrderItem is for Product and SalesOrderItem is for Product;
each Bin occurs at most one time in
	Warehouse contains Bin;
