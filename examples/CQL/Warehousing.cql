vocabulary Warehousing;

/*
 * Value Types
 */
BinID is written as AutoCounter;
DispatchID is written as AutoCounter;
DispatchItemID is written as AutoCounter;
PartyID is written as AutoCounter;
ProductID is written as AutoCounter;
PurchaseOrderID is written as AutoCounter;
Quantity is written as UnsignedInteger(32);
ReceiptID is written as AutoCounter;
ReceivedItemID is written as AutoCounter;
SalesOrderID is written as AutoCounter;
TransferRequestID is written as AutoCounter;
WarehouseID is written as AutoCounter;

/*
 * Entity Types
 */
Bin is identified by its ID;
Bin contains one Quantity,
	Quantity is in Bin;

Dispatch is identified by its ID;

DispatchItem is identified by its ID;
Dispatch is of at least one DispatchItem,
	DispatchItem is for at most one Dispatch;
DispatchItem is in one Quantity;

Party is identified by its ID;

Product is identified by its ID;
DispatchItem is one Product;
Product is stocked in Bin,
	Bin contains at most one Product;

PurchaseOrder is identified by its ID;

PurchaseOrderItem is identified by PurchaseOrder and Product where
	PurchaseOrder includes PurchaseOrderItem,
	PurchaseOrderItem is part of one PurchaseOrder,
	PurchaseOrderItem is for one Product;
PurchaseOrderItem is in one Quantity;

Receipt is identified by its ID;

ReceivedItem is identified by its ID;
Receipt is of at least one ReceivedItem,
	ReceivedItem has at most one Receipt;
ReceivedItem is one Product;
ReceivedItem is for at most one PurchaseOrderItem;
ReceivedItem is in one Quantity;

SalesOrder is identified by its ID;

SalesOrderItem is identified by SalesOrder and Product where
	SalesOrder includes SalesOrderItem,
	SalesOrderItem is part of one SalesOrder,
	SalesOrderItem is for one Product;
DispatchItem is for at most one SalesOrderItem;
SalesOrderItem is in one Quantity;

Supplier is a kind of Party;
PurchaseOrder is to one Supplier,
	Supplier supplies PurchaseOrder;

TransferRequest is identified by its ID;
DispatchItem is for at most one TransferRequest;
ReceivedItem is for at most one TransferRequest;

Warehouse is identified by its ID;
PurchaseOrder is to one Warehouse;
SalesOrder is from one Warehouse;
TransferRequest is at most one from-Warehouse;
TransferRequest is at most one to-Warehouse;
Warehouse contains at least one Bin;

Customer is a kind of Party;
Customer made SalesOrder,
	SalesOrder was made by one Customer;

DirectOrderMatch is where
	PurchaseOrderItem matches SalesOrderItem;

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
