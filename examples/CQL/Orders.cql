vocabulary Orders;

/*
 * Value Types
 */
Description = VariableLengthText(120);
Number = UnsignedInteger(32);
OrderID = AutoCounter();
SKUID = AutoCounter();

/*
 * Entity Types
 */
Order = entity identified by OrderID:
	Order has exactly one OrderID,
	OrderID is of at most one Order;
OrderLine = Order has line Number;
OrderLine is for at most one quantity-Number;

SKU = entity identified by SKUID:
	SKU has exactly one SKUID,
	SKUID is of at most one SKU;
OrderLine is for at most one SKU;
SKU has at most one Description;

