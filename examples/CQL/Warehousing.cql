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
Bin is identified by BinID:
	Bin has exactly one BinID,
	BinID is of at most one Bin;

Dispatch is identified by DispatchID:
	Dispatch has exactly one DispatchID,
	DispatchID is of at most one Dispatch;

DispatchItem is identified by DispatchItemID:
	DispatchItem has exactly one DispatchItemID,
	DispatchItemID is of at most one DispatchItem;
Dispatch is of at least one DispatchItem;

Party is identified by PartyID:
	Party has exactly one PartyID,
	PartyID is of at most one Party;

Product is identified by ProductID:
	Product has exactly one ProductID,
	ProductID is of at most one Product;
DispatchItem is exactly one Product;

PurchaseOrder is identified by PurchaseOrderID:
	PurchaseOrder has exactly one PurchaseOrderID,
	PurchaseOrderID is of at most one PurchaseOrder;

PurchaseOrderItem is identified by PurchaseOrder and Product:
	PurchaseOrder includes PurchaseOrderItem,
	PurchaseOrderItem is part of exactly one PurchaseOrder,
	PurchaseOrderItem is for exactly one Product;

Receipt is identified by ReceiptID:
	Receipt has exactly one ReceiptID,
	ReceiptID is of at most one Receipt;

ReceivedItem is identified by ReceivedItemID:
	ReceivedItem has exactly one ReceivedItemID,
	ReceivedItemID is of at most one ReceivedItem;
ReceivedItem is for at most one PurchaseOrderItem;
ReceivedItem is exactly one Product;
Receipt is of at least one ReceivedItem;

SalesOrder is identified by SalesOrderID:
	SalesOrder has exactly one SalesOrderID,
	SalesOrderID is of at most one SalesOrder;

SalesOrderItem is identified by SalesOrder and Product:
	SalesOrder includes SalesOrderItem,
	SalesOrderItem is part of exactly one SalesOrder,
	SalesOrderItem is for exactly one Product;
DirectOrderMatch is where
	PurchaseOrderItem matches SalesOrderItem;
DispatchItem is for at most one SalesOrderItem;

Supplier is a kind of Party;
PurchaseOrder is to exactly one Supplier,
	Supplier supplies PurchaseOrder;

TransferRequest is identified by TransferRequestID:
	TransferRequest has exactly one TransferRequestID,
	TransferRequestID is of at most one TransferRequest;
ReceivedItem is for at most one TransferRequest;
DispatchItem is for at most one TransferRequest;

Warehouse is identified by WarehouseID:
	Warehouse has exactly one WarehouseID,
	WarehouseID is of at most one Warehouse;
PurchaseOrder is to at most one Warehouse;
SalesOrder is from Warehouse;
StockedProduct is where
	Warehouse contains Product;
Warehouse contains exactly one Bin;
TransferRequest is from at most one Warehouse;
TransferRequest is to at most one Warehouse;
StockedProduct is in Bin,
	Bin contains at most one StockedProduct;

Customer is a kind of Party;
Customer made SalesOrder;

/*
Constraints:
	REVISIT: Verbalise SetExclusionConstraint ExclusiveOrConstraint1 REVISIT: Unhandled constraint type
	REVISIT: Verbalise SetExclusionConstraint ExclusiveOrConstraint2 REVISIT: Unhandled constraint type
	REVISIT: Verbalise PresenceConstraint InternalUniquenessConstraint16 min 1 max 1 mandatory over (SalesOrder)
	REVISIT: Verbalise PresenceConstraint InternalUniquenessConstraint22 min 0 max 1 over (Warehouse)
	REVISIT: Verbalise PresenceConstraint InternalUniquenessConstraint49 min 0 max 1 over (ReceivedItem)
	REVISIT: Verbalise PresenceConstraint InternalUniquenessConstraint52 min 0 max 1 over (DispatchItem)
 */
