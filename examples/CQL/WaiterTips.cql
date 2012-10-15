vocabulary WaiterTips;

/*
 * Value Types
 */
AUDValue is written as Money;
MealId is written as Auto Counter;
WaiterNr is written as Signed Integer(32);

/*
 * Entity Types
 */
Amount is identified by AUDValue where
	Amount has one AUDValue,
	AUDValue is of at most one Amount;

Meal is identified by its Id;

Waiter is identified by its Nr;

WaiterTip is where
	Waiter for serving Meal reported a tip of one Amount;

Service is where
	Waiter served Meal;
Service earned a tip of at most one Amount;

/*
 * Constraints:
 */
Service (in which Waiter served Meal) earned a tip of Amount
	if and only if
	Waiter for serving Meal reported a tip of Amount;
