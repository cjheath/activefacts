vocabulary Orders;

/*
 * Value Types
 */
Description is defined as VariableLengthText(120);
Number is defined as UnsignedInteger(32);
OrderID is defined as AutoCounter();
SKUID is defined as AutoCounter();

/*
 * Entity Types
 */
Order is identified by OrderID where
	Order has exactly one OrderID,
	OrderID is of at most one Order;
OrderLine is where
	Order has line Number;
OrderLine is for at most one quantity-Number;

SKU is identified by SKUID where
	SKU has exactly one SKUID,
	SKUID is of at most one SKU;
OrderLine is for at most one SKU;
SKU has at most one Description;

