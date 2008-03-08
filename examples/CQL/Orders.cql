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
Order = entity known by OrderID:
	Order has exactly one OrderID,
	OrderID is of at most one Order;

OrderLine = entity known by Number and Order:
	Order has line Number;
OrderLine is for at most one quantity-Number;

SKU = entity known by SKUID:
	SKU has exactly one SKUID,
	SKUID is of at most one SKU;
OrderLine is for at most one SKU;
SKU has at most one Description;

