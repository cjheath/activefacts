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
Order is identified by its ID;
OrderLine is where
	Order has line Number;
OrderLine is for at most one quantity-Number;

SKU is identified by its ID;
OrderLine is for at most one SKU;
SKU has at most one Description;

