CREATE TABLE Asset (
	-- Asset has Asset ID,
	AssetID                                 int IDENTITY NOT NULL,
	-- maybe Asset is a Vehicle and maybe Vehicle is of Colour,
	VehicleColour                           varchar NULL,
	-- maybe Asset is a Vehicle and maybe Vehicle was sold by Dealer and Dealer is a kind of Party and Party has Party ID,
	VehicleDealerID                         int NULL,
	-- maybe Asset is a Vehicle and maybe Vehicle has Engine Number,
	VehicleEngineNumber                     varchar NULL,
	-- maybe Asset is a Vehicle and maybe Vehicle is subject to finance with Finance Institution and Finance Institution is a kind of Company and Company is a kind of Party and Party has Party ID,
	VehicleFinanceInstitutionID             int NULL,
	-- maybe Asset is a Vehicle and Vehicle has commercial registration Boolean,
	VehicleHasCommercialRegistration        bit NULL,
	-- maybe Asset is a Vehicle and Vehicle is of model-Year and Year has Year Nr,
	VehicleModelYearNr                      int NULL,
	-- maybe Asset is a Vehicle and Vehicle has Registration and Registration has Registration Nr,
	VehicleRegistrationNr                   char(8) NULL,
	-- maybe Asset is a Vehicle and Vehicle is of Vehicle Type and maybe Vehicle Type has Badge,
	VehicleTypeBadge                        varchar NULL,
	-- maybe Asset is a Vehicle and Vehicle is of Vehicle Type and Vehicle Type is of Make,
	VehicleTypeMake                         varchar NULL,
	-- maybe Asset is a Vehicle and Vehicle is of Vehicle Type and Vehicle Type is of Model,
	VehicleTypeModel                        varchar NULL,
	-- maybe Asset is a Vehicle and Vehicle has VIN,
	VehicleVIN                              int NULL,
	PRIMARY KEY(AssetID)
)
GO

CREATE VIEW dbo.VehicleInAsset_VIN (VehicleVIN) WITH SCHEMABINDING AS
	SELECT VehicleVIN FROM dbo.Asset
	WHERE	VehicleVIN IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX VehiclePK ON dbo.VehicleInAsset_VIN(VehicleVIN)
GO

CREATE TABLE Claim (
	-- Claim has Claim ID,
	ClaimID                                 int IDENTITY NOT NULL,
	-- maybe Claim concerns Incident and Incident relates to loss at Address and Address is in City,
	IncidentAddressCity                     varchar NULL,
	-- maybe Claim concerns Incident and Incident relates to loss at Address and maybe Address is in Postcode,
	IncidentAddressPostcode                 varchar NULL,
	-- maybe Claim concerns Incident and Incident relates to loss at Address and maybe Address is in State and State has State Code,
	IncidentAddressStateCode                tinyint NULL CHECK((IncidentAddressStateCode >= 0 AND IncidentAddressStateCode <= 9)),
	-- maybe Claim concerns Incident and Incident relates to loss at Address and Address is at Street,
	IncidentAddressStreet                   varchar(256) NULL,
	-- maybe Claim concerns Incident and Incident relates to loss on Date Time,
	IncidentDateTime                        datetime NULL,
	-- maybe Claim concerns Incident and maybe Incident is covered by Police Report and maybe Police Report was to officer-Name,
	IncidentOfficerName                     varchar(256) NULL,
	-- maybe Claim concerns Incident and maybe Incident is covered by Police Report and maybe Police Report has police-Report Nr,
	IncidentPoliceReportNr                  int NULL,
	-- maybe Claim concerns Incident and maybe Incident is covered by Police Report and maybe Police Report was on report-Date Time,
	IncidentReportDateTime                  datetime NULL,
	-- maybe Claim concerns Incident and maybe Incident is covered by Police Report and maybe Police Report was by reporter-Name,
	IncidentReporterName                    varchar(256) NULL,
	-- maybe Claim concerns Incident and maybe Incident is covered by Police Report and maybe Police Report was at station-Name,
	IncidentStationName                     varchar(256) NULL,
	-- Claim is involved in Lodgement and maybe Lodgement was made at Date Time,
	LodgementDateTime                       datetime NULL,
	-- Claim is involved in Lodgement and Lodgement involves Person and Person is a kind of Party and Party has Party ID,
	LodgementPersonID                       int NOT NULL,
	-- Claim has Claim Sequence,
	PSequence                               int NOT NULL CHECK((PSequence >= 1 AND PSequence <= 999)),
	-- Claim is on Policy and Policy is for product having Product and Product has Product Code,
	PolicyPProductCode                      tinyint NOT NULL,
	-- Claim is on Policy and Policy has Policy Serial,
	PolicyPSerial                           int NOT NULL,
	-- Claim is on Policy and Policy issued in state having State and State has State Code,
	PolicyPStateCode                        tinyint NOT NULL,
	-- Claim is on Policy and Policy was issued in Year and Year has Year Nr,
	PolicyPYearNr                           int NOT NULL,
	PRIMARY KEY(ClaimID),
	UNIQUE(PolicyPYearNr, PolicyPProductCode, PolicyPStateCode, PolicyPSerial, PSequence)
)
GO

CREATE TABLE ContractorAppointment (
	-- Contractor Appointment involves Claim and Claim has Claim ID,
	ClaimID                                 int NOT NULL,
	-- Contractor Appointment involves Contractor and Contractor is a kind of Company and Company is a kind of Party and Party has Party ID,
	ContractorID                            int NOT NULL,
	PRIMARY KEY(ClaimID, ContractorID),
	FOREIGN KEY (ClaimID) REFERENCES Claim (ClaimID)
)
GO

CREATE TABLE Cover (
	-- Cover involves Asset and Asset has Asset ID,
	AssetID                                 int NOT NULL,
	-- Cover involves Cover Type and Cover Type has Cover Type Code,
	CoverTypeCode                           char NOT NULL,
	-- Cover involves Policy and Policy is for product having Product and Product has Product Code,
	PolicyPProductCode                      tinyint NOT NULL,
	-- Cover involves Policy and Policy has Policy Serial,
	PolicyPSerial                           int NOT NULL,
	-- Cover involves Policy and Policy issued in state having State and State has State Code,
	PolicyPStateCode                        tinyint NOT NULL,
	-- Cover involves Policy and Policy was issued in Year and Year has Year Nr,
	PolicyPYearNr                           int NOT NULL,
	PRIMARY KEY(PolicyPYearNr, PolicyPProductCode, PolicyPStateCode, PolicyPSerial, CoverTypeCode, AssetID),
	FOREIGN KEY (AssetID) REFERENCES Asset (AssetID)
)
GO

CREATE TABLE CoverType (
	-- Cover Type has Cover Type Code,
	CoverTypeCode                           char NOT NULL,
	-- Cover Type has Cover Type Name,
	CoverTypeName                           varchar NOT NULL,
	PRIMARY KEY(CoverTypeCode),
	UNIQUE(CoverTypeName)
)
GO

CREATE TABLE CoverWording (
	-- Cover Wording involves Cover Type and Cover Type has Cover Type Code,
	CoverTypeCode                           char NOT NULL,
	-- Cover Wording involves Policy Wording and Policy Wording has Policy Wording Text,
	PolicyWordingText                       varchar NOT NULL,
	-- Cover Wording involves Date,
	StartDate                               datetime NOT NULL,
	PRIMARY KEY(CoverTypeCode, PolicyWordingText, StartDate),
	FOREIGN KEY (CoverTypeCode) REFERENCES CoverType (CoverTypeCode)
)
GO

CREATE TABLE LossType (
	-- Loss Type involves driving Boolean,
	InvolvesDriving                         bit NULL,
	-- Loss Type is single vehicle incident Boolean,
	IsSingleVehicleIncident                 bit NULL,
	-- maybe Loss Type implies Liability and Liability has Liability Code,
	LiabilityCode                           char(1) NULL CHECK(LiabilityCode = 'D' OR LiabilityCode = 'L' OR LiabilityCode = 'R' OR LiabilityCode = 'U'),
	-- Loss Type has Loss Type Code,
	LossTypeCode                            char NOT NULL,
	PRIMARY KEY(LossTypeCode)
)
GO

CREATE TABLE LostItem (
	-- Lost Item has Description,
	Description                             varchar(1024) NOT NULL,
	-- Lost Item was lost in Incident and Incident is of Claim and Claim has Claim ID,
	IncidentClaimID                         int NOT NULL,
	-- Lost Item has Lost Item Nr,
	LostItemNr                              int NOT NULL,
	-- maybe Lost Item was purchased on purchase-Date,
	PurchaseDate                            datetime NULL,
	-- maybe Lost Item was purchased at purchase-Place,
	PurchasePlace                           varchar NULL,
	-- maybe Lost Item was purchased for purchase-Price,
	PurchasePrice                           decimal(18, 2) NULL,
	PRIMARY KEY(IncidentClaimID, LostItemNr),
	FOREIGN KEY (IncidentClaimID) REFERENCES Claim (ClaimID)
)
GO

CREATE TABLE Party (
	-- maybe Party is a Company and Company has contact-Person and Person is a kind of Party and Party has Party ID,
	CompanyContactPersonID                  int NULL,
	-- Party is a company Boolean,
	IsACompany                              bit NULL,
	-- Party has Party ID,
	PartyID                                 int IDENTITY NOT NULL,
	-- maybe Party is a Person and maybe Person lives at Address and Address is in City,
	PersonAddressCity                       varchar NULL,
	-- maybe Party is a Person and maybe Person lives at Address and maybe Address is in Postcode,
	PersonAddressPostcode                   varchar NULL,
	-- maybe Party is a Person and maybe Person lives at Address and maybe Address is in State and State has State Code,
	PersonAddressStateCode                  tinyint NULL CHECK((PersonAddressStateCode >= 0 AND PersonAddressStateCode <= 9)),
	-- maybe Party is a Person and maybe Person lives at Address and Address is at Street,
	PersonAddressStreet                     varchar(256) NULL,
	-- maybe Party is a Person and maybe Person has birth-Date,
	PersonBirthDate                         datetime NULL,
	-- maybe Party is a Person and Person has Contact Methods and maybe Contact Methods includes business-Phone and Phone has Phone Nr,
	PersonBusinessPhoneNr                   varchar NULL,
	-- maybe Party is a Person and Person has Contact Methods and maybe Contact Methods prefers contact-Time,
	PersonContactTime                       datetime NULL,
	-- maybe Party is a Person and Person has Contact Methods and maybe Contact Methods includes Email,
	PersonEmail                             varchar NULL,
	-- maybe Party is a Person and Person has family-Name,
	PersonFamilyName                        varchar(256) NULL,
	-- maybe Party is a Person and Person has given-Name,
	PersonGivenName                         varchar(256) NULL,
	-- maybe Party is a Person and Person has Contact Methods and maybe Contact Methods includes home-Phone and Phone has Phone Nr,
	PersonHomePhoneNr                       varchar NULL,
	-- maybe Party is a Person and maybe Person holds License and License is international Boolean,
	PersonIsInternational                   bit NULL,
	-- maybe Party is a Person and maybe Person holds License and License has License Number,
	PersonLicenseNumber                     varchar NULL,
	-- maybe Party is a Person and maybe Person holds License and License is of License Type,
	PersonLicenseType                       varchar NULL,
	-- maybe Party is a Person and Person has Contact Methods and maybe Contact Methods includes mobile-Phone and Phone has Phone Nr,
	PersonMobilePhoneNr                     varchar NULL,
	-- maybe Party is a Person and maybe Person has Occupation,
	PersonOccupation                        varchar NULL,
	-- maybe Party is a Person and Person has Contact Methods and maybe Contact Methods has preferred-Contact Method,
	PersonPreferredContactMethod            char(1) NULL CHECK(PersonPreferredContactMethod = 'B' OR PersonPreferredContactMethod = 'H' OR PersonPreferredContactMethod = 'M'),
	-- maybe Party is a Person and Person has Title,
	PersonTitle                             varchar NULL,
	-- maybe Party is a Person and maybe Person holds License and maybe License was granted in Year and Year has Year Nr,
	PersonYearNr                            int NULL,
	-- maybe Party has postal-Address and Address is in City,
	PostalAddressCity                       varchar NULL,
	-- maybe Party has postal-Address and maybe Address is in Postcode,
	PostalAddressPostcode                   varchar NULL,
	-- maybe Party has postal-Address and maybe Address is in State and State has State Code,
	PostalAddressStateCode                  tinyint NULL CHECK((PostalAddressStateCode >= 0 AND PostalAddressStateCode <= 9)),
	-- maybe Party has postal-Address and Address is at Street,
	PostalAddressStreet                     varchar(256) NULL,
	PRIMARY KEY(PartyID),
	FOREIGN KEY (CompanyContactPersonID) REFERENCES Party (PartyID)
)
GO

CREATE VIEW dbo.LicenseInParty_PersonLicenseNumber (PersonLicenseNumber) WITH SCHEMABINDING AS
	SELECT PersonLicenseNumber FROM dbo.Party
	WHERE	PersonLicenseNumber IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_LicenseInPartyByPersonLicenseNumber ON dbo.LicenseInParty_PersonLicenseNumber(PersonLicenseNumber)
GO

CREATE TABLE Policy (
	-- Policy has Application and Application has Application Nr,
	ApplicationNr                           int NOT NULL,
	-- maybe Policy was sold by Authorised Rep and Authorised Rep is a kind of Party and Party has Party ID,
	AuthorisedRepID                         int NULL,
	-- maybe Policy has ITC Claimed,
	ITCClaimed                              decimal(18, 2) NULL CHECK((ITCClaimed >= 0.0 AND ITCClaimed <= 100.0)),
	-- Policy belongs to Insured and Insured is a kind of Party and Party has Party ID,
	InsuredID                               int NOT NULL,
	-- Policy is for product having Product and Product has Product Code,
	PProductCode                            tinyint NOT NULL,
	-- Policy has Policy Serial,
	PSerial                                 int NOT NULL CHECK((PSerial >= 1 AND PSerial <= 99999)),
	-- Policy issued in state having State and State has State Code,
	PStateCode                              tinyint NOT NULL,
	-- Policy was issued in Year and Year has Year Nr,
	PYearNr                                 int NOT NULL,
	PRIMARY KEY(PYearNr, PProductCode, PStateCode, PSerial),
	FOREIGN KEY (AuthorisedRepID) REFERENCES Party (PartyID),
	FOREIGN KEY (InsuredID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE Product (
	-- maybe Product has Alias,
	Alias                                   char(3) NULL,
	-- maybe Product has Description,
	Description                             varchar(1024) NULL,
	-- Product has Product Code,
	ProductCode                             tinyint NOT NULL CHECK((ProductCode >= 1 AND ProductCode <= 99)),
	PRIMARY KEY(ProductCode)
)
GO

CREATE VIEW dbo.Product_Alias (Alias) WITH SCHEMABINDING AS
	SELECT Alias FROM dbo.Product
	WHERE	Alias IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ProductByAlias ON dbo.Product_Alias(Alias)
GO

CREATE VIEW dbo.Product_Description (Description) WITH SCHEMABINDING AS
	SELECT Description FROM dbo.Product
	WHERE	Description IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ProductByDescription ON dbo.Product_Description(Description)
GO

CREATE TABLE PropertyDamage (
	-- Property Damage is at Address and Address is in City,
	AddressCity                             varchar NOT NULL,
	-- Property Damage is at Address and maybe Address is in Postcode,
	AddressPostcode                         varchar NULL,
	-- Property Damage is at Address and maybe Address is in State and State has State Code,
	AddressStateCode                        tinyint NULL CHECK((AddressStateCode >= 0 AND AddressStateCode <= 9)),
	-- Property Damage is at Address and Address is at Street,
	AddressStreet                           varchar(256) NOT NULL,
	-- maybe Property Damage was damaged in Incident and Incident is of Claim and Claim has Claim ID,
	IncidentClaimID                         int NULL,
	-- maybe Property Damage belongs to owner-Name,
	OwnerName                               varchar(256) NULL,
	-- maybe Property Damage owner has contact Phone and Phone has Phone Nr,
	PhoneNr                                 varchar NULL,
	UNIQUE(IncidentClaimID, AddressStreet, AddressCity, AddressPostcode, AddressStateCode),
	FOREIGN KEY (IncidentClaimID) REFERENCES Claim (ClaimID)
)
GO

CREATE TABLE State (
	-- State has State Code,
	StateCode                               tinyint NOT NULL CHECK((StateCode >= 0 AND StateCode <= 9)),
	-- maybe State has State Name,
	StateName                               varchar(256) NULL,
	PRIMARY KEY(StateCode)
)
GO

CREATE VIEW dbo.State_Name (StateName) WITH SCHEMABINDING AS
	SELECT StateName FROM dbo.State
	WHERE	StateName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_StateByStateName ON dbo.State_Name(StateName)
GO

CREATE TABLE ThirdParty (
	-- maybe Third Party is insured by Insurer and Insurer is a kind of Company and Company is a kind of Party and Party has Party ID,
	InsurerID                               int NULL,
	-- maybe Third Party vehicle is of model-Year and Year has Year Nr,
	ModelYearNr                             int NULL,
	-- Third Party involves Person and Person is a kind of Party and Party has Party ID,
	PersonID                                int NOT NULL,
	-- Third Party involves Vehicle Incident and Vehicle Incident is a kind of Incident and Incident is of Claim and Claim has Claim ID,
	VehicleIncidentClaimID                  int NOT NULL,
	-- maybe Third Party drove vehicle-Registration and Registration has Registration Nr,
	VehicleRegistrationNr                   char(8) NULL,
	-- maybe Third Party vehicle is of Vehicle Type and maybe Vehicle Type has Badge,
	VehicleTypeBadge                        varchar NULL,
	-- maybe Third Party vehicle is of Vehicle Type and Vehicle Type is of Make,
	VehicleTypeMake                         varchar NULL,
	-- maybe Third Party vehicle is of Vehicle Type and Vehicle Type is of Model,
	VehicleTypeModel                        varchar NULL,
	PRIMARY KEY(PersonID, VehicleIncidentClaimID),
	FOREIGN KEY (InsurerID) REFERENCES Party (PartyID),
	FOREIGN KEY (PersonID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE UnderwritingDemerit (
	-- maybe Underwriting Demerit occurred occurrence-Count times,
	OccurrenceCount                         int NULL,
	-- Underwriting Demerit has Underwriting Question and Underwriting Question has Underwriting Question ID,
	UnderwritingQuestionID                  int NOT NULL,
	-- Underwriting Demerit preceded Vehicle Incident and Vehicle Incident is a kind of Incident and Incident is of Claim and Claim has Claim ID,
	VehicleIncidentClaimID                  int NOT NULL,
	PRIMARY KEY(VehicleIncidentClaimID, UnderwritingQuestionID)
)
GO

CREATE TABLE UnderwritingQuestion (
	-- Underwriting Question has Text,
	Text                                    varchar NOT NULL,
	-- Underwriting Question has Underwriting Question ID,
	UnderwritingQuestionID                  int IDENTITY NOT NULL,
	PRIMARY KEY(UnderwritingQuestionID),
	UNIQUE(Text)
)
GO

CREATE TABLE VehicleIncident (
	-- maybe Vehicle Incident has Description,
	Description                             varchar(1024) NULL,
	-- Vehicle Incident is involved in Driving and maybe Driving is involved in Hospitalization and maybe Hospitalization resulted in blood-Test Result,
	DrivingBloodTestResult                  varchar NULL,
	-- Vehicle Incident is involved in Driving and maybe Driving resulted in breath-Test Result,
	DrivingBreathTestResult                 varchar NULL,
	-- Vehicle Incident is involved in Driving and maybe Driving is involved in Driving Charge and Driving Charge involves Charge,
	DrivingCharge                           varchar NULL,
	-- Vehicle Incident is involved in Driving and maybe Driving is involved in Hospitalization and Hospitalization involves Hospital and Hospital has Hospital Name,
	DrivingHospitalName                     varchar NULL,
	-- Vehicle Incident is involved in Driving and maybe Driving followed Intoxication,
	DrivingIntoxication                     varchar NULL,
	-- Vehicle Incident is involved in Driving and maybe Driving is involved in Driving Charge and Driving Charge is a warning Boolean,
	DrivingIsAWarning                       bit NULL,
	-- Vehicle Incident is involved in Driving and maybe Driving was without owners consent for nonconsent-Reason,
	DrivingNonconsentReason                 varchar NULL,
	-- Vehicle Incident is involved in Driving and Driving was by Person and Person is a kind of Party and Party has Party ID,
	DrivingPersonID                         int NULL,
	-- Vehicle Incident is involved in Driving and maybe Driving was unlicenced for unlicensed-Reason,
	DrivingUnlicensedReason                 varchar NULL,
	-- Vehicle Incident is a kind of Incident and Incident is of Claim and Claim has Claim ID,
	IncidentClaimID                         int NOT NULL,
	-- maybe Vehicle Incident resulted from Loss Type and Loss Type has Loss Type Code,
	LossTypeCode                            char NULL,
	-- Vehicle Incident is involved in Driving,
	OccurredWhileBeingDriven                bit NULL,
	-- maybe Vehicle Incident involved previous_damage-Description,
	PreviousDamageDescription               varchar(1024) NULL,
	-- maybe Vehicle Incident was caused by Reason,
	Reason                                  varchar NULL,
	-- maybe Vehicle Incident resulted in vehicle being towed to towed-Location,
	TowedLocation                           varchar NULL,
	-- maybe Vehicle Incident occurred during weather-Description,
	WeatherDescription                      varchar(1024) NULL,
	PRIMARY KEY(IncidentClaimID),
	FOREIGN KEY (IncidentClaimID) REFERENCES Claim (ClaimID),
	FOREIGN KEY (LossTypeCode) REFERENCES LossType (LossTypeCode),
	FOREIGN KEY (DrivingPersonID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE Witness (
	-- maybe Witness lives at Address and Address is in City,
	AddressCity                             varchar NULL,
	-- maybe Witness lives at Address and maybe Address is in Postcode,
	AddressPostcode                         varchar NULL,
	-- maybe Witness lives at Address and maybe Address is in State and State has State Code,
	AddressStateCode                        tinyint NULL CHECK((AddressStateCode >= 0 AND AddressStateCode <= 9)),
	-- maybe Witness lives at Address and Address is at Street,
	AddressStreet                           varchar(256) NULL,
	-- maybe Witness has contact-Phone and Phone has Phone Nr,
	ContactPhoneNr                          varchar NULL,
	-- Witness saw Incident and Incident is of Claim and Claim has Claim ID,
	IncidentClaimID                         int NOT NULL,
	-- Witness is called Name,
	Name                                    varchar(256) NOT NULL,
	PRIMARY KEY(IncidentClaimID, Name),
	FOREIGN KEY (IncidentClaimID) REFERENCES Claim (ClaimID),
	FOREIGN KEY (AddressStateCode) REFERENCES State (StateCode)
)
GO

ALTER TABLE Asset
	ADD FOREIGN KEY (VehicleDealerID) REFERENCES Party (PartyID)
GO

ALTER TABLE Asset
	ADD FOREIGN KEY (VehicleFinanceInstitutionID) REFERENCES Party (PartyID)
GO

ALTER TABLE Claim
	ADD FOREIGN KEY (LodgementPersonID) REFERENCES Party (PartyID)
GO

ALTER TABLE Claim
	ADD FOREIGN KEY (PolicyPYearNr, PolicyPProductCode, PolicyPStateCode, PolicyPSerial) REFERENCES Policy (PYearNr, PProductCode, PStateCode, PSerial)
GO

ALTER TABLE Claim
	ADD FOREIGN KEY (IncidentAddressStateCode) REFERENCES State (StateCode)
GO

ALTER TABLE ContractorAppointment
	ADD FOREIGN KEY (ContractorID) REFERENCES Party (PartyID)
GO

ALTER TABLE Cover
	ADD FOREIGN KEY (CoverTypeCode) REFERENCES CoverType (CoverTypeCode)
GO

ALTER TABLE Cover
	ADD FOREIGN KEY (PolicyPYearNr, PolicyPProductCode, PolicyPStateCode, PolicyPSerial) REFERENCES Policy (PYearNr, PProductCode, PStateCode, PSerial)
GO

ALTER TABLE Party
	ADD FOREIGN KEY (PersonAddressStateCode) REFERENCES State (StateCode)
GO

ALTER TABLE Party
	ADD FOREIGN KEY (PostalAddressStateCode) REFERENCES State (StateCode)
GO

ALTER TABLE Policy
	ADD FOREIGN KEY (PProductCode) REFERENCES Product (ProductCode)
GO

ALTER TABLE Policy
	ADD FOREIGN KEY (PStateCode) REFERENCES State (StateCode)
GO

ALTER TABLE PropertyDamage
	ADD FOREIGN KEY (AddressStateCode) REFERENCES State (StateCode)
GO

ALTER TABLE ThirdParty
	ADD FOREIGN KEY (VehicleIncidentClaimID) REFERENCES VehicleIncident (IncidentClaimID)
GO

ALTER TABLE UnderwritingDemerit
	ADD FOREIGN KEY (UnderwritingQuestionID) REFERENCES UnderwritingQuestion (UnderwritingQuestionID)
GO

ALTER TABLE UnderwritingDemerit
	ADD FOREIGN KEY (VehicleIncidentClaimID) REFERENCES VehicleIncident (IncidentClaimID)
GO

