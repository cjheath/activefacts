CREATE TABLE Asset (
	-- Asset has AssetID,
	AssetID                                 int IDENTITY NOT NULL,
	-- maybe Vehicle is a kind of Asset and maybe Vehicle is of Colour,
	VehicleColour                           varchar NULL,
	-- maybe Vehicle is a kind of Asset and maybe Vehicle was sold by Dealer and Party has PartyID,
	VehicleDealerID                         int NULL,
	-- maybe Vehicle is a kind of Asset and maybe Vehicle has EngineNumber,
	VehicleEngineNumber                     varchar NULL,
	-- maybe Vehicle is a kind of Asset and maybe Vehicle is subject to finance with FinanceInstitution and Party has PartyID,
	VehicleFinanceInstitutionID             int NULL,
	-- maybe Vehicle is a kind of Asset and Vehicle has commercial registration,
	VehicleHasCommercialRegistration        bit NULL,
	-- maybe Vehicle is a kind of Asset and Vehicle is of model-Year restricted to {1900..2100} and Year has YearNr,
	VehicleModelYearNr                      int NULL,
	-- maybe Vehicle is a kind of Asset and Registration is of Vehicle and Registration has RegistrationNr,
	VehicleRegistrationNr                   char(8) NULL,
	-- maybe Vehicle is a kind of Asset and Vehicle is of VehicleType and maybe Badge is of VehicleType,
	VehicleTypeBadge                        varchar NULL,
	-- maybe Vehicle is a kind of Asset and Vehicle is of VehicleType and VehicleType is of Make,
	VehicleTypeMake                         varchar NULL,
	-- maybe Vehicle is a kind of Asset and Vehicle is of VehicleType and VehicleType is of Model,
	VehicleTypeModel                        varchar NULL,
	-- maybe Vehicle is a kind of Asset and Vehicle has VIN,
	VehicleVIN                              int NULL,
	PRIMARY KEY(AssetID)
)
GO

CREATE VIEW dbo.VehicleInAsset_VIN (VehicleVIN) WITH SCHEMABINDING AS
	SELECT VehicleVIN FROM dbo.Asset
	WHERE	VehicleVIN IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PK_VehicleInAsset ON dbo.VehicleInAsset_VIN(VehicleVIN)
GO

CREATE TABLE Claim (
	-- Claim has ClaimID,
	ClaimID                                 int IDENTITY NOT NULL,
	-- maybe Claim concerns Incident and Incident relates to loss at Address and Address is in City,
	IncidentAddressCity                     varchar NULL,
	-- maybe Claim concerns Incident and Incident relates to loss at Address and maybe Address is in Postcode,
	IncidentAddressPostcode                 varchar NULL,
	-- maybe Claim concerns Incident and Incident relates to loss at Address and maybe Address is in State and State has StateCode,
	IncidentAddressStateCode                int NULL CHECK((IncidentAddressStateCode >= 0 AND IncidentAddressStateCode <= 9)),
	-- maybe Claim concerns Incident and Incident relates to loss at Address and Address is at Street,
	IncidentAddressStreet                   varchar(256) NULL,
	-- maybe Claim concerns Incident and Incident relates to loss on DateTime,
	IncidentDateTime                        datetime NULL,
	-- maybe Claim concerns Incident and maybe Incident is covered by PoliceReport and maybe PoliceReport was to officer-Name,
	IncidentOfficerName                     varchar(256) NULL,
	-- maybe Claim concerns Incident and maybe Incident is covered by PoliceReport and maybe PoliceReport has police-ReportNr,
	IncidentPoliceReportNr                  int NULL,
	-- maybe Claim concerns Incident and maybe Incident is covered by PoliceReport and maybe PoliceReport was on report-DateTime,
	IncidentReportDateTime                  datetime NULL,
	-- maybe Claim concerns Incident and maybe Incident is covered by PoliceReport and maybe PoliceReport was by reporter-Name,
	IncidentReporterName                    varchar(256) NULL,
	-- maybe Claim concerns Incident and maybe Incident is covered by PoliceReport and maybe PoliceReport was at station-Name,
	IncidentStationName                     varchar(256) NULL,
	-- maybe Lodgement is where Claim was lodged by Person and maybe Lodgement was made at DateTime,
	LodgementDateTime                       datetime NULL,
	-- maybe Lodgement is where Claim was lodged by Person and Lodgement is where Claim was lodged by Person and Party has PartyID,
	LodgementPersonID                       int NULL,
	-- Claim has p_sequence,
	PSequence                               int NOT NULL CHECK((PSequence >= 1 AND PSequence <= 999)),
	-- Claim is on Policy and Policy is for product having p_product and Product has ProductCode,
	PolicyPProductCode                      int NOT NULL,
	-- Claim is on Policy and Policy has p_serial,
	PolicyPSerial                           int NOT NULL,
	-- Claim is on Policy and Policy issued in state having p_state and State has StateCode,
	PolicyPStateCode                        int NOT NULL,
	-- Claim is on Policy and Policy was issued in p_year restricted to {0..99} and Year has YearNr,
	PolicyPYearNr                           int NOT NULL,
	PRIMARY KEY(ClaimID),
	UNIQUE(PolicyPYearNr, PolicyPProductCode, PolicyPStateCode, PolicyPSerial, PSequence)
)
GO

CREATE TABLE ContractorAppointment (
	-- ContractorAppointment is where Claim involves Contractor and Claim has ClaimID,
	ClaimID                                 int NOT NULL,
	-- ContractorAppointment is where Claim involves Contractor and Party has PartyID,
	ContractorID                            int NOT NULL,
	PRIMARY KEY(ClaimID, ContractorID),
	FOREIGN KEY (ClaimID) REFERENCES Claim (ClaimID)
)
GO

CREATE TABLE Cover (
	-- Cover is where Policy provides CoverType over Asset and Asset has AssetID,
	AssetID                                 int NOT NULL,
	-- Cover is where Policy provides CoverType over Asset and CoverType has CoverTypeCode,
	CoverTypeCode                           char NOT NULL,
	-- Cover is where Policy provides CoverType over Asset and Policy is for product having p_product and Product has ProductCode,
	PolicyPProductCode                      int NOT NULL,
	-- Cover is where Policy provides CoverType over Asset and Policy has p_serial,
	PolicyPSerial                           int NOT NULL,
	-- Cover is where Policy provides CoverType over Asset and Policy issued in state having p_state and State has StateCode,
	PolicyPStateCode                        int NOT NULL,
	-- Cover is where Policy provides CoverType over Asset and Policy was issued in p_year restricted to {0..99} and Year has YearNr,
	PolicyPYearNr                           int NOT NULL,
	PRIMARY KEY(PolicyPYearNr, PolicyPProductCode, PolicyPStateCode, PolicyPSerial, CoverTypeCode, AssetID),
	FOREIGN KEY (AssetID) REFERENCES Asset (AssetID)
)
GO

CREATE TABLE CoverType (
	-- CoverType has CoverTypeCode,
	CoverTypeCode                           char NOT NULL,
	-- CoverType has CoverTypeName,
	CoverTypeName                           varchar NOT NULL,
	PRIMARY KEY(CoverTypeCode),
	UNIQUE(CoverTypeName)
)
GO

CREATE TABLE CoverWording (
	-- CoverWording is where CoverType used PolicyWording from startDate and CoverType has CoverTypeCode,
	CoverTypeCode                           char NOT NULL,
	-- CoverWording is where CoverType used PolicyWording from startDate and PolicyWording has PolicyWordingText,
	PolicyWordingText                       varchar NOT NULL,
	-- CoverWording is where CoverType used PolicyWording from startDate,
	StartDate                               datetime NOT NULL,
	PRIMARY KEY(CoverTypeCode, PolicyWordingText, StartDate),
	FOREIGN KEY (CoverTypeCode) REFERENCES CoverType (CoverTypeCode)
)
GO

CREATE TABLE DamagedProperty (
	-- DamagedProperty is at Address and Address is in City,
	AddressCity                             varchar NOT NULL,
	-- DamagedProperty is at Address and maybe Address is in Postcode,
	AddressPostcode                         varchar NULL,
	-- DamagedProperty is at Address and maybe Address is in State and State has StateCode,
	AddressStateCode                        int NULL CHECK((AddressStateCode >= 0 AND AddressStateCode <= 9)),
	-- DamagedProperty is at Address and Address is at Street,
	AddressStreet                           varchar(256) NOT NULL,
	-- maybe Incident caused DamagedProperty and Claim has ClaimID,
	IncidentID                              int NULL,
	-- maybe DamagedProperty belongs to owner-Name,
	OwnerName                               varchar(256) NULL,
	-- maybe DamagedProperty owner has contact Phone and Phone has PhoneNr,
	PhoneNr                                 varchar NULL,
	UNIQUE(IncidentID, AddressStreet, AddressCity, AddressPostcode, AddressStateCode),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID)
)
GO

CREATE TABLE DemeritKind (
	-- DemeritKind has DemeritKindName,
	DemeritKindName                         varchar NOT NULL,
	PRIMARY KEY(DemeritKindName)
)
GO

CREATE TABLE LossType (
	-- LossType involves driving,
	InvolvesDriving                         bit NOT NULL,
	-- LossType is single vehicle incident,
	IsSingleVehicleIncident                 bit NOT NULL,
	-- maybe LossType implies Liability and Liability has LiabilityCode,
	LiabilityCode                           char(1) NULL CHECK(LiabilityCode = 'D' OR LiabilityCode = 'L' OR LiabilityCode = 'R' OR LiabilityCode = 'U'),
	-- LossType has LossTypeCode,
	LossTypeCode                            char NOT NULL,
	PRIMARY KEY(LossTypeCode)
)
GO

CREATE TABLE LostItem (
	-- Description is of LostItem,
	Description                             varchar(1024) NOT NULL,
	-- LostItem was lost in Incident and Claim has ClaimID,
	IncidentID                              int NOT NULL,
	-- LostItem has LostItemNr,
	LostItemNr                              int NOT NULL,
	-- maybe LostItem was purchased on purchase-Date,
	PurchaseDate                            datetime NULL,
	-- maybe LostItem was purchased at purchase-Place,
	PurchasePlace                           varchar NULL,
	-- maybe LostItem was purchased for purchase-Price,
	PurchasePrice                           decimal(18, 2) NULL,
	PRIMARY KEY(IncidentID, LostItemNr),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID)
)
GO

CREATE TABLE Party (
	-- maybe Company is a kind of Party and Company has contact-Person and Party has PartyID,
	CompanyContactPersonID                  int NULL,
	-- maybe Person is a kind of Party and maybe Driver is a kind of Person and maybe Driver holds License and License is international,
	DriverIsInternational                   bit NULL,
	-- maybe Person is a kind of Party and maybe Driver is a kind of Person and maybe Driver holds License and License has LicenseNumber,
	DriverLicenseNumber                     varchar NULL,
	-- maybe Person is a kind of Party and maybe Driver is a kind of Person and maybe Driver holds License and License is of LicenseType,
	DriverLicenseType                       varchar NULL,
	-- maybe Person is a kind of Party and maybe Driver is a kind of Person and maybe Driver holds License and maybe License was granted in Year restricted to {1990..2100} and Year has YearNr,
	DriverYearNr                            int NULL,
	-- Party is a company,
	IsACompany                              bit NOT NULL,
	-- Party has PartyID,
	PartyID                                 int IDENTITY NOT NULL,
	-- maybe Person is a kind of Party and maybe Person lives at Address and Address is in City,
	PersonAddressCity                       varchar NULL,
	-- maybe Person is a kind of Party and maybe Person lives at Address and maybe Address is in Postcode,
	PersonAddressPostcode                   varchar NULL,
	-- maybe Person is a kind of Party and maybe Person lives at Address and maybe Address is in State and State has StateCode,
	PersonAddressStateCode                  int NULL CHECK((PersonAddressStateCode >= 0 AND PersonAddressStateCode <= 9)),
	-- maybe Person is a kind of Party and maybe Person lives at Address and Address is at Street,
	PersonAddressStreet                     varchar(256) NULL,
	-- maybe Person is a kind of Party and maybe Person has birth-Date,
	PersonBirthDate                         datetime NULL,
	-- maybe Person is a kind of Party and Person has ContactMethods and maybe ContactMethods includes business-Phone and Phone has PhoneNr,
	PersonBusinessPhoneNr                   varchar NULL,
	-- maybe Person is a kind of Party and Person has ContactMethods and maybe ContactMethods prefers contact-Time,
	PersonContactTime                       datetime NULL,
	-- maybe Person is a kind of Party and Person has ContactMethods and maybe ContactMethods includes Email,
	PersonEmail                             varchar NULL,
	-- maybe Person is a kind of Party and Person has family-Name,
	PersonFamilyName                        varchar(256) NULL,
	-- maybe Person is a kind of Party and Person has given-Name,
	PersonGivenName                         varchar(256) NULL,
	-- maybe Person is a kind of Party and Person has ContactMethods and maybe ContactMethods includes home-Phone and Phone has PhoneNr,
	PersonHomePhoneNr                       varchar NULL,
	-- maybe Person is a kind of Party and Person has ContactMethods and maybe ContactMethods includes mobile-Phone and Phone has PhoneNr,
	PersonMobilePhoneNr                     varchar NULL,
	-- maybe Person is a kind of Party and maybe Person has Occupation,
	PersonOccupation                        varchar NULL,
	-- maybe Person is a kind of Party and Person has ContactMethods and maybe ContactMethods has preferred-ContactMethod,
	PersonPreferredContactMethod            char(1) NULL CHECK(PersonPreferredContactMethod = 'B' OR PersonPreferredContactMethod = 'H' OR PersonPreferredContactMethod = 'M'),
	-- maybe Person is a kind of Party and Person has Title,
	PersonTitle                             varchar NULL,
	-- maybe Party has postal-Address and Address is in City,
	PostalAddressCity                       varchar NULL,
	-- maybe Party has postal-Address and maybe Address is in Postcode,
	PostalAddressPostcode                   varchar NULL,
	-- maybe Party has postal-Address and maybe Address is in State and State has StateCode,
	PostalAddressStateCode                  int NULL CHECK((PostalAddressStateCode >= 0 AND PostalAddressStateCode <= 9)),
	-- maybe Party has postal-Address and Address is at Street,
	PostalAddressStreet                     varchar(256) NULL,
	PRIMARY KEY(PartyID),
	FOREIGN KEY (CompanyContactPersonID) REFERENCES Party (PartyID)
)
GO

CREATE VIEW dbo.LicenseInParty_DriverLicenseNumber (DriverLicenseNumber) WITH SCHEMABINDING AS
	SELECT DriverLicenseNumber FROM dbo.Party
	WHERE	DriverLicenseNumber IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_LicenseInPartyByDriverLicenseNumber ON dbo.LicenseInParty_DriverLicenseNumber(DriverLicenseNumber)
GO

CREATE VIEW dbo.LicenseInParty_DriverLicenseNumberDriverLicenseTypeDriverYearNr (DriverLicenseNumber, DriverLicenseType, DriverYearNr) WITH SCHEMABINDING AS
	SELECT DriverLicenseNumber, DriverLicenseType, DriverYearNr FROM dbo.Party
	WHERE	DriverLicenseNumber IS NOT NULL
	  AND	DriverLicenseType IS NOT NULL
	  AND	DriverYearNr IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_LicenseInPartyByDriverLicenseNumberDriverLicenseTypeDriverYearNr ON dbo.LicenseInParty_DriverLicenseNumberDriverLicenseTypeDriverYearNr(DriverLicenseNumber, DriverLicenseType, DriverYearNr)
GO

CREATE TABLE Policy (
	-- Application is for Policy and Application has ApplicationNr,
	ApplicationNr                           int NOT NULL,
	-- maybe Policy was sold by AuthorisedRep and Party has PartyID,
	AuthorisedRepID                         int NULL,
	-- Policy belongs to Client and Party has PartyID,
	ClientID                                int NOT NULL,
	-- maybe ITCClaimed is for Policy,
	ITCClaimed                              decimal(18, 2) NULL CHECK((ITCClaimed >= 0.0 AND ITCClaimed <= 100.0)),
	-- Policy is for product having p_product and Product has ProductCode,
	PProductCode                            int NOT NULL,
	-- Policy has p_serial,
	PSerial                                 int NOT NULL CHECK((PSerial >= 1 AND PSerial <= 99999)),
	-- Policy issued in state having p_state and State has StateCode,
	PStateCode                              int NOT NULL,
	-- Policy was issued in p_year restricted to {0..99} and Year has YearNr,
	PYearNr                                 int NOT NULL,
	PRIMARY KEY(PYearNr, PProductCode, PStateCode, PSerial),
	FOREIGN KEY (AuthorisedRepID) REFERENCES Party (PartyID),
	FOREIGN KEY (ClientID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE Product (
	-- maybe Alias is of Product,
	Alias                                   char(3) NULL,
	-- maybe ProdDescription is of Product,
	ProdDescription                         varchar(80) NULL,
	-- Product has ProductCode,
	ProductCode                             int NOT NULL CHECK((ProductCode >= 1 AND ProductCode <= 99)),
	PRIMARY KEY(ProductCode)
)
GO

CREATE VIEW dbo.Product_Alias (Alias) WITH SCHEMABINDING AS
	SELECT Alias FROM dbo.Product
	WHERE	Alias IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ProductByAlias ON dbo.Product_Alias(Alias)
GO

CREATE VIEW dbo.Product_ProdDescription (ProdDescription) WITH SCHEMABINDING AS
	SELECT ProdDescription FROM dbo.Product
	WHERE	ProdDescription IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ProductByProdDescription ON dbo.Product_ProdDescription(ProdDescription)
GO

CREATE TABLE State (
	-- State has StateCode,
	StateCode                               int NOT NULL CHECK((StateCode >= 0 AND StateCode <= 9)),
	-- maybe StateName is of State,
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
	-- maybe ThirdParty is insured by Insurer and Party has PartyID,
	InsurerID                               int NULL,
	-- maybe ThirdParty vehicle is of model-Year and Year has YearNr,
	ModelYearNr                             int NULL,
	-- ThirdParty is where Person was third party in VehicleIncident and Party has PartyID,
	PersonID                                int NOT NULL,
	-- ThirdParty is where Person was third party in VehicleIncident and VehicleIncident is a kind of Incident and Claim has ClaimID,
	VehicleIncidentID                       int NOT NULL,
	-- maybe ThirdParty drove vehicle-Registration and Registration has RegistrationNr,
	VehicleRegistrationNr                   char(8) NULL,
	-- maybe ThirdParty vehicle is of VehicleType and maybe Badge is of VehicleType,
	VehicleTypeBadge                        varchar NULL,
	-- maybe ThirdParty vehicle is of VehicleType and VehicleType is of Make,
	VehicleTypeMake                         varchar NULL,
	-- maybe ThirdParty vehicle is of VehicleType and VehicleType is of Model,
	VehicleTypeModel                        varchar NULL,
	PRIMARY KEY(PersonID, VehicleIncidentID),
	FOREIGN KEY (InsurerID) REFERENCES Party (PartyID),
	FOREIGN KEY (PersonID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE UnderwritingDemerit (
	-- UnderwritingDemerit has DemeritKind and DemeritKind has DemeritKindName,
	DemeritKindName                         varchar NOT NULL,
	-- maybe UnderwritingDemerit occurred occurrence-Count times,
	OccurrenceCount                         int NULL,
	-- VehicleIncident occurred despite UnderwritingDemerit and VehicleIncident is a kind of Incident and Claim has ClaimID,
	VehicleIncidentID                       int NOT NULL,
	PRIMARY KEY(VehicleIncidentID, DemeritKindName),
	FOREIGN KEY (DemeritKindName) REFERENCES DemeritKind (DemeritKindName)
)
GO

CREATE TABLE VehicleIncident (
	-- maybe VehicleIncident has Description,
	Description                             varchar(1024) NULL,
	-- maybe Driving is where VehicleIncident involves Driver and maybe Driving resulted in blood-TestResult,
	DrivingBloodTestResult                  varchar NULL,
	-- maybe Driving is where VehicleIncident involves Driver and maybe Driving resulted in breath-TestResult,
	DrivingBreathTestResult                 varchar NULL,
	-- maybe Driving is where VehicleIncident involves Driver and maybe DrivingCharge is where Driving resulted in Charge and DrivingCharge is where Driving resulted in Charge,
	DrivingCharge                           varchar NULL,
	-- maybe Driving is where VehicleIncident involves Driver and Driving is where VehicleIncident involves Driver and Party has PartyID,
	DrivingDriverID                         int NULL,
	-- maybe Driving is where VehicleIncident involves Driver and maybe driver_hospitalised resulted in driver taken to hospital-Name,
	DrivingHospitalName                     varchar(256) NULL,
	-- maybe Driving is where VehicleIncident involves Driver and maybe Driving followed Intoxication,
	DrivingIntoxication                     varchar NULL,
	-- maybe Driving is where VehicleIncident involves Driver and maybe DrivingCharge is where Driving resulted in Charge and DrivingCharge is warning,
	DrivingIsWarning                        bit NULL,
	-- maybe Driving is where VehicleIncident involves Driver and maybe Driving was without owners consent for nonconsent-Reason,
	DrivingNonconsentReason                 varchar NULL,
	-- maybe Driving is where VehicleIncident involves Driver and maybe Driving was unlicenced for unlicensed-Reason,
	DrivingUnlicensedReason                 varchar NULL,
	-- VehicleIncident is a kind of Incident and Claim has ClaimID,
	IncidentID                              int IDENTITY NOT NULL,
	-- maybe VehicleIncident resulted from LossType and LossType has LossTypeCode,
	LossTypeCode                            char NULL,
	-- maybe VehicleIncident involved previous_damage-Description,
	PreviousDamageDescription               varchar(1024) NULL,
	-- maybe VehicleIncident was caused by Reason,
	Reason                                  varchar NULL,
	-- maybe VehicleIncident resulted in vehicle being towed to towed-Location,
	TowedLocation                           varchar NULL,
	-- maybe VehicleIncident occurred during weather-Description,
	WeatherDescription                      varchar(1024) NULL,
	PRIMARY KEY(IncidentID),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID),
	FOREIGN KEY (LossTypeCode) REFERENCES LossType (LossTypeCode),
	FOREIGN KEY (DrivingDriverID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE Witness (
	-- maybe Witness lives at Address and Address is in City,
	AddressCity                             varchar NULL,
	-- maybe Witness lives at Address and maybe Address is in Postcode,
	AddressPostcode                         varchar NULL,
	-- maybe Witness lives at Address and maybe Address is in State and State has StateCode,
	AddressStateCode                        int NULL CHECK((AddressStateCode >= 0 AND AddressStateCode <= 9)),
	-- maybe Witness lives at Address and Address is at Street,
	AddressStreet                           varchar(256) NULL,
	-- maybe Witness has contact-Phone and Phone has PhoneNr,
	ContactPhoneNr                          varchar NULL,
	-- Incident was seen by Witness and Claim has ClaimID,
	IncidentID                              int NOT NULL,
	-- Witness is called Name,
	Name                                    varchar(256) NOT NULL,
	PRIMARY KEY(IncidentID, Name),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID)
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
	ADD FOREIGN KEY (PolicyPProductCode, PolicyPSerial, PolicyPStateCode, PolicyPYearNr) REFERENCES Policy (PProductCode, PSerial, PStateCode, PYearNr)
GO

ALTER TABLE ContractorAppointment
	ADD FOREIGN KEY (ContractorID) REFERENCES Party (PartyID)
GO

ALTER TABLE Cover
	ADD FOREIGN KEY (CoverTypeCode) REFERENCES CoverType (CoverTypeCode)
GO

ALTER TABLE Cover
	ADD FOREIGN KEY (PolicyPProductCode, PolicyPSerial, PolicyPStateCode, PolicyPYearNr) REFERENCES Policy (PProductCode, PSerial, PStateCode, PYearNr)
GO

ALTER TABLE Policy
	ADD FOREIGN KEY (PProductCode) REFERENCES Product (ProductCode)
GO

ALTER TABLE Policy
	ADD FOREIGN KEY (PStateCode) REFERENCES State (StateCode)
GO

ALTER TABLE ThirdParty
	ADD FOREIGN KEY (VehicleIncidentID) REFERENCES VehicleIncident (IncidentID)
GO

ALTER TABLE UnderwritingDemerit
	ADD FOREIGN KEY (VehicleIncidentID) REFERENCES VehicleIncident (IncidentID)
GO

