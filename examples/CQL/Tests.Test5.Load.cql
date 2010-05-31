vocabulary ORMModel1;

/*
 * Value Types
 */
Accuracy Level is written as Signed Integer(32);
Date is written as Date;
Party Id is written as Auto Counter;
Party Name is written as Variable Length Text;
ymd is written as Date;

/*
 * Entity Types
 */
Accuracy is identified by its Level restricted to {1..5};

Event Date is identified by ymd where
	Event Date has one ymd,
	ymd is of at most one Event Date;

Party is identified by its Id [independent];

Party Moniker is where
	Party is called at most one Party Name;
Party Moniker has one Accuracy;

Person is a kind of Party;

Birth is where
	Person was born on one Event Date;

Death is where
	Person died;
Death occurred on at most one death-Event Date;

Doctor is a kind of Person;
Birth was assisted by at most one attending-Doctor,
	Doctor attended Birth;

