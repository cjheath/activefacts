vocabulary Insurance;

/*
 * Value Types
 */
Alias is written as FixedLengthText(3);
ApplicationNr is written as SignedInteger(32);
AssetID is written as AutoCounter;
Badge is written as VariableLengthText;
Charge is written as VariableLengthText;
City is written as VariableLengthText;
ClaimID is written as AutoCounter;
ClaimSequence is written as UnsignedInteger(32) restricted to {1..999};
Colour is written as VariableLengthText;
ContactMethod is written as FixedLengthText(1) restricted to {'B', 'H', 'M'};
Count is written as UnsignedInteger(32);
CoverTypeCode is written as FixedLengthText;
CoverTypeName is written as VariableLengthText;
DateTime is written as DateAndTime;
DemeritKindName is written as VariableLengthText;
Description is written as VariableLengthText(1024);
Email is written as VariableLengthText;
EngineNumber is written as VariableLengthText;
ITCClaimed is written as Decimal(18,2) restricted to {0.0..100.0};
Intoxication is written as VariableLengthText;
LiabilityCode is written as FixedLengthText(1) restricted to {'D', 'L', 'R', 'U'};
LicenseNumber is written as VariableLengthText;
LicenseType is written as VariableLengthText;
Location is written as VariableLengthText;
LossTypeCode is written as FixedLengthText;
LostItemNr is written as SignedInteger(32);
Make is written as VariableLengthText;
Model is written as VariableLengthText;
Name is written as VariableLengthText(256);
Occupation is written as VariableLengthText;
PartyID is written as AutoCounter;
PhoneNr is written as VariableLengthText;
Place is written as VariableLengthText;
PolicySerial is written as UnsignedInteger(32) restricted to {1..99999};
PolicyWordingText is written as VariableLengthText;
Postcode is written as VariableLengthText;
Price is written as Decimal(18,2);
ProdDescription is written as VariableLengthText(80);
ProductCode is written as UnsignedTinyInteger(32) restricted to {1..99};
Reason is written as VariableLengthText;
RegistrationNr is written as FixedLengthText(8);
ReportNr is written as SignedInteger(32);
StateCode is written as UnsignedTinyInteger(32) restricted to {0..9};
StateName is written as VariableLengthText(256);
Street is written as VariableLengthText(256);
TestResult is written as VariableLengthText;
Title is written as VariableLengthText;
VIN is written as UnsignedInteger(32);
YearNr is written as SignedInteger(32);

/*
 * Entity Types
 */
Application is identified by its Nr;

Asset is identified by its ID;

Claim is identified by its ID;
Claim has one ClaimSequence (as p_sequence),
	p_sequence is of Claim;

CoverType is identified by its Code;
CoverType has one CoverTypeName,
	CoverTypeName is of at most one CoverType;

DemeritKind is identified by its Name [independent];

Incident is identified by Claim where
	Claim concerns at most one Incident,
	Incident is of one Claim;
Incident relates to loss on one DateTime;

Liability is identified by its Code restricted to {'D', 'L', 'R', 'U'};

LossType is identified by its Code;
LossType implies at most one Liability;
LossType involves driving;
LossType is single vehicle incident;

LostItem is identified by Incident and LostItemNr where
	LostItem was lost in one Incident,
	LostItem has one LostItemNr,
	LostItemNr is of LostItem;
Description is of LostItem,
	LostItem has one Description;
LostItem was purchased on at most one purchase-Date;
LostItem was purchased at at most one purchase-Place;
LostItem was purchased for at most one purchase-Price;

Party is identified by its ID;
Party is a company;

Person is a kind of Party;
Person has at most one Occupation;
Person has one Title;
Person has at most one birth-Date;
Person has one family-Name;
Person has one given-Name;

Phone is identified by its Nr;

PoliceReport is identified by Incident where
	Incident is covered by at most one PoliceReport,
	PoliceReport covers one Incident;
PoliceReport was to at most one officer-Name;
PoliceReport has at most one police-ReportNr;
PoliceReport was on at most one report-DateTime;
PoliceReport was by at most one reporter-Name;
PoliceReport was at at most one station-Name;

PolicyWording is identified by its Text;

Product is identified by its Code restricted to {1..99};
Alias is of at most one Product,
	Product has at most one Alias;
ProdDescription is of at most one Product,
	Product has at most one ProdDescription;

Registration is identified by its Nr;

State is identified by its Code restricted to {0..9} [independent];
StateName is of at most one State,
	State has at most one StateName;

Vehicle is a kind of Asset identified by VIN where
	Vehicle has one VIN,
	VIN is of at most one Vehicle;
Registration is of Vehicle,
	Vehicle has one Registration;
Vehicle is of at most one Colour;
Vehicle has at most one EngineNumber;
Vehicle has commercial registration;

VehicleIncident is a kind of Incident [separate];
VehicleIncident has at most one Description;
VehicleIncident resulted from at most one LossType;
VehicleIncident was caused by at most one Reason;
VehicleIncident involved at most one previous_damage-Description;
VehicleIncident resulted in vehicle being towed to at most one towed-Location;
VehicleIncident occurred during at most one weather-Description;

VehicleType is identified by Make and Model and Badge where
	VehicleType is of one Make,
	VehicleType is of one Model,
	Badge is of VehicleType,
	VehicleType has at most one Badge;
Vehicle is of one VehicleType;

Witness is identified by Incident and Name where
	Incident was seen by Witness,
	Witness saw one Incident,
	Witness is called one Name;
Witness has at most one contact-Phone;

Year is identified by its Nr;
Vehicle is of one model-Year restricted to {1900..2100};

Address is identified by Street and City and Postcode and State where
	Address is at one Street,
	Address is in one City,
	Address is in at most one Postcode,
	Address is in at most one State;
Incident relates to loss at one Address;
Party has at most one postal-Address;
Person lives at at most one Address;
Witness lives at at most one Address;

AuthorisedRep is a kind of Party;

Client is a kind of Party;

Company is a kind of Party;
Company has one contact-Person,
	Person is contact for Company;

ContactMethods is identified by Person where
	Person has one ContactMethods,
	ContactMethods are for one Person;
ContactMethods includes at most one Email;
ContactMethods includes at most one business-Phone;
ContactMethods prefers at most one contact-Time;
ContactMethods includes at most one home-Phone;
ContactMethods includes at most one mobile-Phone;
ContactMethods has at most one preferred-ContactMethod;

Contractor is a kind of Company;

ContractorAppointment is where
	Claim involves Contractor,
	Contractor is appointed to handle Claim;

CoverWording is where
	CoverType used PolicyWording from start-Date (as startDate);

DamagedProperty is identified by Incident and Address where
	Incident caused DamagedProperty,
	DamagedProperty was damaged in at most one Incident,
	DamagedProperty is at one Address;
DamagedProperty owner has contact at most one Phone;
DamagedProperty belongs to at most one owner-Name;

Dealer is a kind of Party;
Vehicle was sold by at most one Dealer;

Driver is a kind of Person;

Driving is where
	VehicleIncident involves at most one Driver,
	Driver drove covered vehicle in at least one VehicleIncident;
Driving followed at most one Intoxication;
Driving resulted in at most one blood-TestResult;
Driving resulted in at most one breath-TestResult;
Driving (as driver_hospitalised) resulted in driver taken to at most one hospital-Name;
Driving was without owners consent for at most one nonconsent-Reason;
Driving was unlicenced for at most one unlicensed-Reason;

DrivingCharge is where
	Driving resulted in at most one Charge;
DrivingCharge is warning;

FinanceInstitution is a kind of Company;
Vehicle is subject to finance with at most one FinanceInstitution;

Insurer is a kind of Company;

Investigator is a kind of Contractor;

License is identified by Driver where
	Driver holds at most one License,
	License is held by one Driver;
License has one LicenseNumber,
	LicenseNumber is of at most one License;
License is of one LicenseType,
	LicenseType has License instance;
License was granted in at most one Year restricted to {1990..2100};
License is international;

Lodgement is where
	Claim was lodged by at most one Person;
Lodgement was made at at most one DateTime;

Policy is identified by p_year and p_product and p_state and p_serial where
	Policy was issued in one Year (as p_year) restricted to {0..99},
	Policy is for product having one Product (as p_product),
	Policy issued in state having one State (as p_state),
	Policy has one PolicySerial (as p_serial);
Application is for Policy,
	Policy has one Application;
Claim is on one Policy,
	Policy has Claim;
ITCClaimed is for Policy,
	Policy has at most one ITCClaimed;
Policy was sold by at most one AuthorisedRep,
	AuthorisedRep sold Policy;
Policy belongs to one Client,
	Client has Policy;

Repairer is a kind of Contractor;

Solicitor is a kind of Contractor;

ThirdParty is where
	Person was third party in VehicleIncident;
ThirdParty is insured by at most one Insurer;
ThirdParty vehicle is of at most one VehicleType;
ThirdParty vehicle is of at most one model-Year;
ThirdParty drove at most one vehicle-Registration;

UnderwritingDemerit is identified by VehicleIncident and DemeritKind where
	VehicleIncident occurred despite UnderwritingDemerit,
	UnderwritingDemerit preceded one VehicleIncident,
	UnderwritingDemerit has one DemeritKind,
	DemeritKind is of UnderwritingDemerit;
UnderwritingDemerit occurred at most one occurrence-Count times;

Assessor is a kind of Contractor;

Cover is where
	Policy provides CoverType over Asset,
	CoverType over Asset is provided by Policy;

MotorPolicy is a kind of Policy;

SingleMotorPolicy is a kind of MotorPolicy;

MotorFleetPolicy is a kind of MotorPolicy;

/*
 * Constraints:
 */
for each MotorPolicy exactly one of these holds:
	SingleMotorPolicy is a subtype of MotorPolicy,
	MotorFleetPolicy is a subtype of MotorPolicy;
Party is a company
	if and only if
	Party is a Company and Company has contact-Person;
each ContactMethods occurs at least one time in
	ContactMethods includes mobile-Phone,
	ContactMethods includes home-Phone,
	ContactMethods includes business-Phone,
	ContactMethods includes Email;
each combination Policy, ClaimSequence occurs at most one time in
	Claim is on Policy,
	Claim has ClaimSequence;
each Witness occurs at least one time in
	Witness lives at Address,
	Witness has contact-Phone;
