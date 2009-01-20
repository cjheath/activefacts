vocabulary RedundantDependency;

/*
 * Value Types
 */
AddressId is defined as AutoCounter();
DistrictNumber is defined as SignedInteger(32);
PoliticianId is defined as AutoCounter();
PostalCode is defined as SignedInteger(32);
StateOrProvinceId is defined as AutoCounter();

/*
 * Entity Types
 */
Address is identified by its Id;
Address is assigned at most one PostalCode;

Politician is identified by its Id;

StateOrProvince is identified by its Id;
Address is in at most one StateOrProvince;

LegislativeDistrict is identified by DistrictNumber and StateOrProvince where
	LegislativeDistrict has one DistrictNumber,
	LegislativeDistrict is for one StateOrProvince;
Address is in at most one LegislativeDistrict;
Politician represents at most one LegislativeDistrict,
	LegislativeDistrict is represented by one Politician;

/*
 * Constraints:
 */
Address is in LegislativeDistrict
	only if Address is in StateOrProvince and LegislativeDistrict is for StateOrProvince;
