vocabulary RedundantDependency;

/*
 * Value Types
 */
Address Id is written as Auto Counter;
District Number is written as Signed Integer(32);
Politician Id is written as Auto Counter;
Postal Code is written as Signed Integer(32);
State Or Province Id is written as Auto Counter;

/*
 * Entity Types
 */
Address is identified by its Id;
Address is assigned at most one Postal Code;

Politician is identified by its Id;

State Or Province is identified by its Id;
Address is in at most one State Or Province;

Legislative District is identified by District Number and State Or Province where
	Legislative District has one District Number,
	Legislative District is for one State Or Province;
Address is in at most one Legislative District;
Politician represents at most one Legislative District,
	Legislative District is represented by one Politician;

/*
 * Constraints:
 */
Address is in Legislative District
	only if Address is in State Or Province and Legislative District is for State Or Province;
