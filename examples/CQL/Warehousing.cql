vocabulary Warehousing;

/*
 * Value Types
 */
Bin ID is written as Auto Counter;
Dispatch ID is written as Auto Counter;
Dispatch Item ID is written as Auto Counter;
Party ID is written as Auto Counter;
Product ID is written as Auto Counter;
Purchase Order ID is written as Auto Counter;
Quantity is written as Unsigned Integer(32);
Receipt ID is written as Auto Counter;
Received Item ID is written as Auto Counter;
Sales Order ID is written as Auto Counter;
Transfer Request ID is written as Auto Counter;
Warehouse ID is written as Auto Counter;

/*
 * Entity Types
 */
Bin is identified by its ID;
Bin contains one Quantity,
	Quantity is in Bin;

Dispatch is identified by its ID;

Dispatch Item is identified by its ID;
Dispatch is of at least one Dispatch Item,
	Dispatch Item is for at most one Dispatch;
Dispatch Item is in one Quantity;

Party is identified by its ID;

Product is identified by its ID;
Dispatch Item is one Product;
Product is stocked in Bin,
	Bin contains at most one Product;

Purchase Order is identified by its ID;

Purchase Order Item is identified by Purchase Order and Product where
	Purchase Order includes Purchase Order Item,
	Purchase Order Item is part of one Purchase Order,
	Purchase Order Item is for one Product,
	Product is in Purchase Order Item;
Purchase Order Item is in one Quantity;

Receipt is identified by its ID;

Received Item is identified by its ID;
Receipt is of at least one Received Item,
	Received Item has at most one Receipt;
Received Item is one Product;
Received Item is for at most one Purchase Order Item;
Received Item is in one Quantity;

Sales Order is identified by its ID;

Sales Order Item is identified by Sales Order and Product where
	Sales Order includes Sales Order Item,
	Sales Order Item is part of one Sales Order,
	Sales Order Item is for one Product,
	Product is in Sales Order Item;
Dispatch Item is for at most one Sales Order Item;
Sales Order Item is in one Quantity;

Supplier is a kind of Party;
Purchase Order is to one Supplier,
	Supplier supplies Purchase Order;

Transfer Request is identified by its ID;
Dispatch Item is for at most one Transfer Request;
Received Item is for at most one Transfer Request;
Transfer Request is for one Product;
Transfer Request is for one Quantity;

Warehouse is identified by its ID;
Purchase Order is to one Warehouse;
Sales Order is from one Warehouse;
Transfer Request is from one Warehouse (as From Warehouse);
Transfer Request is to one Warehouse (as To Warehouse);
Warehouse contains at least one Bin;

Back Order Allocation is where
	Purchase Order Item is allocated to Sales Order Item;
Back Order Allocation is for one Quantity;

Customer is a kind of Party;
Customer made Sales Order,
	Sales Order was made by one Customer;

/*
 * Constraints:
 */
either Dispatch Item is for Transfer Request or Dispatch Item is for Sales Order Item but not both;
either Received Item is for Purchase Order Item or Received Item is for Transfer Request but not both;
Purchase Order Item is allocated to Sales Order Item
	only if Purchase Order Item is for Product that is in Sales Order Item;
each Bin occurs at most one time in
	Warehouse contains Bin;
