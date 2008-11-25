vocabulary Insurance;

/*
 * Value Types
 */
Alias is defined as FixedLengthText(3);
ApplicationNr is defined as SignedInteger(32);
AssetID is defined as AutoCounter();
Badge is defined as VariableLengthText();
Charge is defined as VariableLengthText();
City is defined as VariableLengthText();
ClaimID is defined as AutoCounter();
ClaimSequence is defined as UnsignedInteger(32) restricted to {1..999};
Colour is defined as VariableLengthText();
ContactMethod is defined as FixedLengthText(1) restricted to {'H', 'B', 'M'};
Count is defined as UnsignedInteger(32);
CoverTypeCode is defined as FixedLengthText();
CoverTypeName is defined as VariableLengthText();
DateTime is defined as DateAndTime();
DemeritKindName is defined as VariableLengthText();
Description is defined as VariableLengthText(1024);
Email is defined as VariableLengthText();
EngineNumber is defined as VariableLengthText();
ITCClaimed is defined as Decimal(18,2) restricted to {0..100};
Intoxication is defined as VariableLengthText();
LiabilityCode is defined as FixedLengthText(1) restricted to {'L', 'R', 'U', 'D'};
LicenseNumber is defined as VariableLengthText();
LicenseType is defined as VariableLengthText();
Location is defined as VariableLengthText();
LossTypeCode is defined as FixedLengthText();
LostItemNr is defined as SignedInteger(32);
Make is defined as VariableLengthText();
Model is defined as VariableLengthText();
Name is defined as VariableLengthText(256);
Occupation is defined as VariableLengthText();
PartyID is defined as AutoCounter();
PhoneNr is defined as VariableLengthText();
Place is defined as VariableLengthText();
PolicySerial is defined as UnsignedInteger(32) restricted to {1..99999};
PolicyWordingText is defined as LargeLengthText();
Postcode is defined as VariableLengthText();
Price is defined as Decimal(18,2);
ProdDescription is defined as VariableLengthText(80);
ProductCode is defined as UnsignedTinyInteger(32) restricted to {1..99};
Reason is defined as VariableLengthText();
RegistrationNr is defined as FixedLengthText(8);
ReportNr is defined as SignedInteger(32);
StateCode is defined as UnsignedTinyInteger(32) restricted to {0..9};
StateName is defined as VariableLengthText(256);
Street is defined as VariableLengthText(256);
TestResult is defined as VariableLengthText();
Title is defined as VariableLengthText();
VIN is defined as UnsignedInteger(32);
YearNr is defined as SignedInteger(32);

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

DemeritKind is identified by its Name;

Incident is identified by Claim where
	Claim concerns at most one Incident,
	Incident is of one Claim;
Incident relates to loss on one DateTime;

Liability is identified by its Code;

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
Lodgement is where
	Claim was lodged by at most one Person;
Lodgement was made at at most one DateTime;

Phone is identified by its Nr;

PoliceReport is identified by Incident where
	Incident is covered by at most one PoliceReport,
	PoliceReport covers one Incident;
PoliceReport was on at most one DateTime;
PoliceReport was to at most one officer-Name;
PoliceReport has at most one police-ReportNr;
PoliceReport was by at most one reporter-Name;
PoliceReport was at at most one station-Name;

PolicyWording is identified by its Text;
CoverWording is where
	CoverType used PolicyWording from start-Date (as startDate);

Product is identified by its Code;
Alias is of at most one Product,
	Product has at most one Alias;
ProdDescription is of at most one Product,
	Product has at most one ProdDescription;

Registration is identified by its Nr;

State is identified by its Code;
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

VehicleIncident is a kind of Incident;
VehicleIncident has at most one Description;
VehicleIncident resulted from at most one LossType;
VehicleIncident was caused by at most one Reason;
VehicleIncident involved at most one previous_damage-Description;
VehicleIncident resulted in vehicle being towed to at most one towed-Location;
VehicleIncident occurred during at most one weather-Description;
ThirdParty is where
	Person was third party in VehicleIncident;
ThirdParty drove at most one vehicle-Registration;

VehicleType is identified by Make and Model and Badge where
	VehicleType is of one Make,
	VehicleType is of one Model,
	Badge is of VehicleType,
	VehicleType has at most one Badge;
ThirdParty vehicle is of at most one VehicleType;
Vehicle is of one VehicleType;

Witness is identified by Incident and Name where
	Incident was seen by Witness,
	Witness saw one Incident,
	Witness is called one Name;
Witness has at most one contact-Phone;

Year is identified by its Nr;
ThirdParty vehicle is of at most one model-Year;
Vehicle is of one model-Year;

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
	Contractor is appointed to handle Claim,
	Claim involves Contractor;

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
Driving (as hospitalised) resulted in driver taken to at most one hospital-Name;
Driving was without owners consent for at most one nonconsent-Reason;
Driving drove unlicenced for at most one unlicensed-Reason;
DrivingCharge is where
	Driving resulted in at most one Charge;
DrivingCharge is warning;

FinanceInstitution is a kind of Company;
Vehicle is subject to finance with at most one FinanceInstitution;

Insurer is a kind of Company;
ThirdParty is insured by at most one Insurer;

Investigator is a kind of Contractor;

License is identified by Driver where
	Driver holds at most one License,
	License is held by one Driver;
License has one LicenseNumber,
	LicenseNumber is of at most one License;
License is of one LicenseType,
	LicenseType has License instance;
License was granted in at most one Year;
License is international;

Policy is identified by p_year and p_product and p_state and p_serial where
	Policy was issued in one Year (as p_year),
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
Cover is where
	Policy provides CoverType over Asset,
	CoverType over Asset is provided by Policy;

Repairer is a kind of Contractor;

Solicitor is a kind of Contractor;

UnderwritingDemerit is identified by VehicleIncident and DemeritKind where
	VehicleIncident occurred despite UnderwritingDemerit,
	UnderwritingDemerit preceded one VehicleIncident,
	UnderwritingDemerit has one DemeritKind,
	DemeritKind is of UnderwritingDemerit;
UnderwritingDemerit occurred at most one occurrence-Count times;

Assessor is a kind of Contractor;

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
	Company has contact-Person;
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
