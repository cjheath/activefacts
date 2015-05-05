vocabulary Insurance;

/*
 * Value Types
 */
Alias is written as Char(3);
Application Nr is written as Signed Integer(32);
Asset ID is written as Auto Counter;
Badge is written as String;
Charge is written as String;
City is written as String;
Claim ID is written as Auto Counter;
Claim Sequence is written as Unsigned Integer(32) restricted to {1..999};
Colour is written as String;
Contact Method is written as Char(1) restricted to {'B', 'H', 'M'};
Count is written as Unsigned Integer(32);
Cover Type Code is written as Char;
Cover Type Name is written as String;
Date is written as Date;
Date Time is written as Date Time;
Description is written as String(1024);
Email is written as String;
Engine Number is written as String;
Hospital Name is written as String;
ITC Claimed is written as Decimal(18,2) restricted to {0.0..100.0};
Intoxication is written as String;
Liability Code is written as Char(1) restricted to {'D', 'L', 'R', 'U'};
License Number is written as String;
License Type is written as String;
Location is written as String;
Loss Type Code is written as Char;
Lost Item Nr is written as Signed Integer(32);
Make is written as String;
Model is written as String;
Name is written as String(256);
Occupation is written as String;
Party ID is written as Auto Counter;
Phone Nr is written as String;
Place is written as String;
Policy Serial is written as Unsigned Integer(32) restricted to {1..99999};
Policy Wording Text is written as String;
Postcode is written as String;
Price is written as Decimal(18,2);
Product Code is written as Unsigned Integer(8) restricted to {1..99};
Reason is written as String;
Registration Nr is written as Char(8);
Report Nr is written as Signed Integer(32);
State Code is written as Unsigned Integer(8) restricted to {0..9};
State Name is written as String(256);
Street is written as String(256);
Test Result is written as String;
Text is written as String;
Time is written as Time;
Title is written as String;
Underwriting Question ID is written as Auto Counter;
VIN is written as Unsigned Integer(32);
Year Nr is written as Signed Integer(32);

/*
 * Entity Types
 */
Application is identified by its Nr;

Asset is identified by its ID;

Claim is identified by its ID;
Claim has one Claim Sequence (as p_sequence),
	p_sequence is of Claim;

Cover Type is identified by its Code;
Cover Type has one Cover Type Name,
	Cover Type Name is of at most one Cover Type;

Hospital is identified by its Name;

Incident is identified by Claim where
	Claim concerns at most one Incident,
	Incident is of one Claim;
Incident relates to loss on one Date Time;

Liability is identified by its Code restricted to {'D', 'L', 'R', 'U'};

Loss Type is identified by its Code;
Loss Type implies at most one Liability;
Loss Type involves driving;
Loss Type is single vehicle incident;

Lost Item is identified by Incident and Lost Item Nr where
	Lost Item was lost in one Incident,
	Lost Item has one Lost Item Nr,
	Lost Item Nr is of Lost Item;
Description is of Lost Item,
	Lost Item has one Description;
Lost Item was purchased on at most one purchase-Date;
Lost Item was purchased at at most one purchase-Place;
Lost Item was purchased for at most one purchase-Price;

Party is identified by its ID;
Party is a company;

Person is a kind of Party;
Person has at most one Occupation;
Person has one Title;
Person has at most one birth-Date;
Person has one family-Name,
	family-Name is of Person;
Person has given-Name;  // Avoid ambiguity; this is a new fact type
Person has one given-Name,
	given-Name is of Person;

Phone is identified by its Nr;

Police Report is identified by Incident where
	Incident is covered by at most one Police Report,
	Police Report covers one Incident;
Police Report was to at most one officer-Name;
Police Report has at most one police-Report Nr;
Police Report was on at most one report-Date Time;
Police Report was by at most one reporter-Name;
Police Report was at at most one station-Name;

Policy Wording is identified by its Text;

Product is identified by its Code;
Alias is of at most one Product,
	Product has at most one Alias;
Description is of at most one Product,
	Product has at most one Description;

Registration is identified by its Nr;

State is independent identified by its Code;
State Name is of at most one State,
	State has at most one State Name;

Underwriting Question is identified by its ID;
Text is of at most one Underwriting Question,
	Underwriting Question has one Text;

Vehicle is a kind of Asset identified by VIN where
	Vehicle has one VIN,
	VIN is of at most one Vehicle;
Registration is of Vehicle,
	Vehicle has one Registration;
Vehicle is of at most one Colour;
Vehicle has at most one Engine Number;
Vehicle has commercial registration;

Vehicle Incident is a kind of Incident [separate];
Vehicle Incident has at most one Description;
Vehicle Incident resulted from at most one Loss Type;
Vehicle Incident was caused by at most one Reason;
Vehicle Incident involved at most one previous_damage-Description;
Vehicle Incident resulted in vehicle being towed to at most one towed-Location;
Vehicle Incident occurred during at most one weather-Description;

Vehicle Type is identified by Make and Model and Badge where
	Vehicle Type is of one Make,
	Vehicle Type is of one Model,
	Badge is of Vehicle Type,
	Vehicle Type has at most one Badge;
Vehicle is of one Vehicle Type;

Witness is identified by Incident and Name where
	Incident was independently witnessed by Witness,
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

Authorised Rep is a kind of Party;

Company is a kind of Party;
Company has one contact-Person,
	Person is contact for Company;

Contact Methods is identified by Person where
	Person has one Contact Methods,
	Contact Methods are for one Person;
Contact Methods includes at most one Email;
Contact Methods includes at most one business-Phone;
Contact Methods prefers at most one contact-Time;
Contact Methods includes at most one home-Phone;
Contact Methods includes at most one mobile-Phone;
Contact Methods has at most one preferred-Contact Method;

Contractor is a kind of Company;

Contractor Appointment is where
	Claim involves Contractor,
	Contractor is appointed to handle Claim;

Cover Wording is where
	Cover Type used Policy Wording from start-Date;

Dealer is a kind of Party;
Vehicle was sold by at most one Dealer;

Driving is where
	Vehicle Incident occurred while being driven;
Driving followed at most one Intoxication;
Driving resulted in at most one breath-Test Result;
Driving was without owners consent for at most one nonconsent-Reason;
Driving was unlicenced for at most one unlicensed-Reason;
Person was Driving,
	Driving was by one Person;

Driving Charge is where
	Driving resulted in at most one Charge;
Driving Charge is a warning;

Finance Institution is a kind of Company;
Vehicle is subject to finance with at most one Finance Institution;

Hospitalization is where
	Driving resulted in driver taken to at most one Hospital;
Hospitalization resulted in at most one blood-Test Result;

Insured is a kind of Party;

Insurer is a kind of Company;

Investigator is a kind of Contractor;

License is identified by Person where
	Person holds at most one License,
	License is held by one Person;
License has one License Number,
	License Number is of at most one License;
License is of one License Type,
	License Type has License instance;
License was granted in at most one Year restricted to {1990..2100};
License is international;

Lodgement is where
	Claim was lodged by one Person;
Lodgement was made at at most one Date Time;

Policy is identified by p_year and p_product and p_state and p_serial where
	Policy was issued in one Year (as p_year) restricted to {0..99},
	Policy is for product having one Product (as p_product),
	Policy issued in state having one State (as p_state),
	Policy has one Policy Serial (as p_serial);
Application is for Policy,
	Policy has one Application;
Claim is on one Policy,
	Policy has Claim;
ITC Claimed is for Policy,
	Policy has at most one ITC Claimed;
Policy was sold by at most one Authorised Rep,
	Authorised Rep sold Policy;
Policy belongs to one Insured,
	Insured has Policy;

Property Damage is identified by Incident and Address where
	Incident caused Property Damage,
	Property Damage was damaged in at most one Incident,
	Property Damage is at one Address,
	Address is of Property Damage;
Property Damage owner has contact at most one Phone;
Property Damage belongs to at most one owner-Name;

Repairer is a kind of Contractor;

Solicitor is a kind of Contractor;

Third Party is where
	Person was third party in Vehicle Incident;
Third Party is insured by at most one Insurer;
Third Party vehicle is of at most one Vehicle Type;
Third Party vehicle is of at most one model-Year;
Third Party drove at most one vehicle-Registration;

Underwriting Demerit is identified by Vehicle Incident and Underwriting Question where
	Vehicle Incident occurred despite Underwriting Demerit,
	Underwriting Demerit preceded one Vehicle Incident,
	Underwriting Demerit has one Underwriting Question,
	Underwriting Question is of Underwriting Demerit;
Underwriting Demerit occurred at most one occurrence-Count times;

Assessor is a kind of Contractor;

Cover is where
	Policy provides Cover Type over Asset,
	Cover Type over Asset is provided by Policy;

Motor Policy is a kind of Policy;

Single Motor Policy is a kind of Motor Policy;

Motor Fleet Policy is a kind of Motor Policy;

/*
 * Constraints:
 */
either Motor Policy is a Single Motor Policy or Motor Policy is a Motor Fleet Policy but not both;
Party is a Company that has contact Person
	if and only if
	Party is a company;
each Contact Methods occurs at least one time in
	Contact Methods includes mobile Phone(3),
	Contact Methods includes home Phone(2),
	Contact Methods includes business Phone(1),
	Contact Methods includes Email;
each combination Policy, Claim Sequence occurs at most one time in
	Claim is on Policy,
	Claim has Claim Sequence;
either Witness lives at Address or Witness has contact Phone;
