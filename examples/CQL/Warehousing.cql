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
Bin is identified by its ID;
Bin contains exactly one Quantity,
	Quantity is in Bin;

Dispatch is identified by its ID;

DispatchItem is identified by its ID;
Dispatch is of at least one DispatchItem,
	DispatchItem is for at most one Dispatch;
DispatchItem is in exactly one Quantity;

Party is identified by its ID;

Product is identified by its ID;
DispatchItem is exactly one Product;
Product is stocked in Bin,
	Bin contains at most one Product;

PurchaseOrder is identified by its ID;

PurchaseOrderItem is identified by PurchaseOrder and Product where
	PurchaseOrder includes PurchaseOrderItem,
	PurchaseOrderItem is part of exactly one PurchaseOrder,
	PurchaseOrderItem is for exactly one Product;
PurchaseOrderItem is in exactly one Quantity;

Receipt is identified by its ID;

ReceivedItem is identified by its ID;
Receipt is of at least one ReceivedItem,
	ReceivedItem has at most one Receipt;
ReceivedItem is exactly one Product;
ReceivedItem is for at most one PurchaseOrderItem;
ReceivedItem is in exactly one Quantity;

SalesOrder is identified by its ID;

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

TransferRequest is identified by its ID;
DispatchItem is for at most one TransferRequest;
ReceivedItem is for at most one TransferRequest;

Warehouse is identified by its ID;
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
