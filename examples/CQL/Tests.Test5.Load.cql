vocabulary ORMModel1;

/*
 * Value Types
 */
AccuracyLevel is written as SignedInteger(32);
PartyId is written as AutoCounter;
PartyName is written as VariableLengthText;
ymd is written as Date;

/*
 * Entity Types
 */
Accuracy is identified by its Level restricted to {1..5};

EventDate is identified by ymd where
	EventDate has one ymd,
	ymd is of at most one EventDate;

Party is identified by its Id [independent];

PartyMoniker is where
	Party is called at most one PartyName;
PartyMoniker has one Accuracy;

Person is a kind of Party;

Birth is where
	Person was born on one EventDate;

Death is where
	Person died;
Death occurred on at most one death-EventDate;

Doctor is a kind of Person;
Birth was assisted by at most one attending-Doctor,
	Doctor attended Birth;

