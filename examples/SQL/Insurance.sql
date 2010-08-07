CREATE TABLE Asset (
	-- Asset has Asset ID,
	AssetID                                 int IDENTITY NOT NULL,
	-- maybe Vehicle is a kind of Asset and maybe Vehicle is of Colour,
	VehicleColour                           varchar NULL,
	-- maybe Vehicle is a kind of Asset and maybe Vehicle was sold by Dealer and Party has Party ID,
	VehicleDealerID                         int NULL,
	-- maybe Vehicle is a kind of Asset and maybe Vehicle has Engine Number,
	VehicleEngineNumber                     varchar NULL,
	-- maybe Vehicle is a kind of Asset and maybe Vehicle is subject to finance with Finance Institution and Party has Party ID,
	VehicleFinanceInstitutionID             int NULL,
	-- maybe Vehicle is a kind of Asset and Vehicle has commercial registration,
	VehicleHasCommercialRegistration        bit NULL,
	-- maybe Vehicle is a kind of Asset and Vehicle is of model-Year and Year has Year Nr,
	VehicleModelYearNr                      int NULL,
	-- maybe Vehicle is a kind of Asset and Registration is of Vehicle and Registration has Registration Nr,
	VehicleRegistrationNr                   char(8) NULL,
	-- maybe Vehicle is a kind of Asset and Vehicle is of Vehicle Type and maybe Badge is of Vehicle Type,
	VehicleTypeBadge                        varchar NULL,
	-- maybe Vehicle is a kind of Asset and Vehicle is of Vehicle Type and Vehicle Type is of Make,
	VehicleTypeMake                         varchar NULL,
	-- maybe Vehicle is a kind of Asset and Vehicle is of Vehicle Type and Vehicle Type is of Model,
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
	-- maybe Lodgement is where Claim was lodged by Person and maybe Lodgement was made at Date Time,
	LodgementDateTime                       datetime NULL,
	-- maybe Lodgement is where Claim was lodged by Person and Lodgement is where Claim was lodged by Person and Party has Party ID,
	LodgementPersonID                       int NULL,
	-- Claim has Claim Sequence (as p_sequence),
	PSequence                               int NOT NULL CHECK((PSequence >= 1 AND PSequence <= 999)),
	-- Claim is on Policy and Policy is for product having Product (as p_product) and Product has Product Code,
	PolicyPProductCode                      tinyint NOT NULL,
	-- Claim is on Policy and Policy has Policy Serial (as p_serial),
	PolicyPSerial                           int NOT NULL,
	-- Claim is on Policy and Policy issued in state having State (as p_state) and State has State Code,
	PolicyPStateCode                        tinyint NOT NULL,
	-- Claim is on Policy and Policy was issued in Year (as p_year) and Year has Year Nr,
	PolicyPYearNr                           int NOT NULL,
	PRIMARY KEY(ClaimID),
	UNIQUE(PolicyPYearNr, PolicyPProductCode, PolicyPStateCode, PolicyPSerial, PSequence)
)
GO

CREATE TABLE ContractorAppointment (
	-- Contractor Appointment is where Claim involves Contractor and Claim has Claim ID,
	ClaimID                                 int NOT NULL,
	-- Contractor Appointment is where Claim involves Contractor and Party has Party ID,
	ContractorID                            int NOT NULL,
	PRIMARY KEY(ClaimID, ContractorID),
	FOREIGN KEY (ClaimID) REFERENCES Claim (ClaimID)
)
GO

CREATE TABLE Cover (
	-- Cover is where Policy provides Cover Type over Asset and Asset has Asset ID,
	AssetID                                 int NOT NULL,
	-- Cover is where Policy provides Cover Type over Asset and Cover Type has Cover Type Code,
	CoverTypeCode                           char NOT NULL,
	-- Cover is where Policy provides Cover Type over Asset and Policy is for product having Product (as p_product) and Product has Product Code,
	PolicyPProductCode                      tinyint NOT NULL,
	-- Cover is where Policy provides Cover Type over Asset and Policy has Policy Serial (as p_serial),
	PolicyPSerial                           int NOT NULL,
	-- Cover is where Policy provides Cover Type over Asset and Policy issued in state having State (as p_state) and State has State Code,
	PolicyPStateCode                        tinyint NOT NULL,
	-- Cover is where Policy provides Cover Type over Asset and Policy was issued in Year (as p_year) and Year has Year Nr,
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
	-- Cover Wording is where Cover Type used Policy Wording from start-Date and Cover Type has Cover Type Code,
	CoverTypeCode                           char NOT NULL,
	-- Cover Wording is where Cover Type used Policy Wording from start-Date and Policy Wording has Policy Wording Text,
	PolicyWordingText                       varchar NOT NULL,
	-- Cover Wording is where Cover Type used Policy Wording from start-Date,
	StartDate                               datetime NOT NULL,
	PRIMARY KEY(CoverTypeCode, PolicyWordingText, StartDate),
	FOREIGN KEY (CoverTypeCode) REFERENCES CoverType (CoverTypeCode)
)
GO

CREATE TABLE DemeritKind (
	-- Demerit Kind has Demerit Kind Name,
	DemeritKindName                         varchar NOT NULL,
	PRIMARY KEY(DemeritKindName)
)
GO

CREATE TABLE LossType (
	-- Loss Type involves driving,
	InvolvesDriving                         bit NOT NULL,
	-- Loss Type is single vehicle incident,
	IsSingleVehicleIncident                 bit NOT NULL,
	-- maybe Loss Type implies Liability and Liability has Liability Code,
	LiabilityCode                           char(1) NULL CHECK(LiabilityCode = 'D' OR LiabilityCode = 'L' OR LiabilityCode = 'R' OR LiabilityCode = 'U'),
	-- Loss Type has Loss Type Code,
	LossTypeCode                            char NOT NULL,
	PRIMARY KEY(LossTypeCode)
)
GO

CREATE TABLE LostItem (
	-- Description is of Lost Item,
	Description                             varchar(1024) NOT NULL,
	-- Lost Item was lost in Incident and Claim has Claim ID,
	IncidentID                              int NOT NULL,
	-- Lost Item has Lost Item Nr,
	LostItemNr                              int NOT NULL,
	-- maybe Lost Item was purchased on purchase-Date,
	PurchaseDate                            datetime NULL,
	-- maybe Lost Item was purchased at purchase-Place,
	PurchasePlace                           varchar NULL,
	-- maybe Lost Item was purchased for purchase-Price,
	PurchasePrice                           decimal(18, 2) NULL,
	PRIMARY KEY(IncidentID, LostItemNr),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID)
)
GO

CREATE TABLE Party (
	-- maybe Company is a kind of Party and Company has contact-Person and Party has Party ID,
	CompanyContactPersonID                  int NULL,
	-- maybe Person is a kind of Party and maybe Driver is a kind of Person and maybe Driver holds License and License is international,
	DriverIsInternational                   bit NULL,
	-- maybe Person is a kind of Party and maybe Driver is a kind of Person and maybe Driver holds License and License has License Number,
	DriverLicenseNumber                     varchar NULL,
	-- maybe Person is a kind of Party and maybe Driver is a kind of Person and maybe Driver holds License and License is of License Type,
	DriverLicenseType                       varchar NULL,
	-- maybe Person is a kind of Party and maybe Driver is a kind of Person and maybe Driver holds License and maybe License was granted in Year and Year has Year Nr,
	DriverYearNr                            int NULL,
	-- Party is a company,
	IsACompany                              bit NOT NULL,
	-- Party has Party ID,
	PartyID                                 int IDENTITY NOT NULL,
	-- maybe Person is a kind of Party and maybe Person lives at Address and Address is in City,
	PersonAddressCity                       varchar NULL,
	-- maybe Person is a kind of Party and maybe Person lives at Address and maybe Address is in Postcode,
	PersonAddressPostcode                   varchar NULL,
	-- maybe Person is a kind of Party and maybe Person lives at Address and maybe Address is in State and State has State Code,
	PersonAddressStateCode                  tinyint NULL CHECK((PersonAddressStateCode >= 0 AND PersonAddressStateCode <= 9)),
	-- maybe Person is a kind of Party and maybe Person lives at Address and Address is at Street,
	PersonAddressStreet                     varchar(256) NULL,
	-- maybe Person is a kind of Party and maybe Person has birth-Date,
	PersonBirthDate                         datetime NULL,
	-- maybe Person is a kind of Party and Person has Contact Methods and maybe Contact Methods includes business-Phone and Phone has Phone Nr,
	PersonBusinessPhoneNr                   varchar NULL,
	-- maybe Person is a kind of Party and Person has Contact Methods and maybe Contact Methods prefers contact-Time,
	PersonContactTime                       datetime NULL,
	-- maybe Person is a kind of Party and Person has Contact Methods and maybe Contact Methods includes Email,
	PersonEmail                             varchar NULL,
	-- maybe Person is a kind of Party and Person has family-Name,
	PersonFamilyName                        varchar(256) NULL,
	-- maybe Person is a kind of Party and Person has given-Name,
	PersonGivenName                         varchar(256) NULL,
	-- maybe Person is a kind of Party and Person has Contact Methods and maybe Contact Methods includes home-Phone and Phone has Phone Nr,
	PersonHomePhoneNr                       varchar NULL,
	-- maybe Person is a kind of Party and Person has Contact Methods and maybe Contact Methods includes mobile-Phone and Phone has Phone Nr,
	PersonMobilePhoneNr                     varchar NULL,
	-- maybe Person is a kind of Party and maybe Person has Occupation,
	PersonOccupation                        varchar NULL,
	-- maybe Person is a kind of Party and Person has Contact Methods and maybe Contact Methods has preferred-Contact Method,
	PersonPreferredContactMethod            char(1) NULL CHECK(PersonPreferredContactMethod = 'B' OR PersonPreferredContactMethod = 'H' OR PersonPreferredContactMethod = 'M'),
	-- maybe Person is a kind of Party and Person has Title,
	PersonTitle                             varchar NULL,
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
	-- Application is for Policy and Application has Application Nr,
	ApplicationNr                           int NOT NULL,
	-- maybe Policy was sold by Authorised Rep and Party has Party ID,
	AuthorisedRepID                         int NULL,
	-- Policy belongs to Client and Party has Party ID,
	ClientID                                int NOT NULL,
	-- maybe ITC Claimed is for Policy,
	ITCClaimed                              decimal(18, 2) NULL CHECK((ITCClaimed >= 0.0 AND ITCClaimed <= 100.0)),
	-- Policy is for product having Product (as p_product) and Product has Product Code,
	PProductCode                            tinyint NOT NULL,
	-- Policy has Policy Serial (as p_serial),
	PSerial                                 int NOT NULL CHECK((PSerial >= 1 AND PSerial <= 99999)),
	-- Policy issued in state having State (as p_state) and State has State Code,
	PStateCode                              tinyint NOT NULL,
	-- Policy was issued in Year (as p_year) and Year has Year Nr,
	PYearNr                                 int NOT NULL,
	PRIMARY KEY(PYearNr, PProductCode, PStateCode, PSerial),
	FOREIGN KEY (AuthorisedRepID) REFERENCES Party (PartyID),
	FOREIGN KEY (ClientID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE Product (
	-- maybe Alias is of Product,
	Alias                                   char(3) NULL,
	-- maybe Prod Description is of Product,
	ProdDescription                         varchar(80) NULL,
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

CREATE VIEW dbo.Product_ProdDescription (ProdDescription) WITH SCHEMABINDING AS
	SELECT ProdDescription FROM dbo.Product
	WHERE	ProdDescription IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_ProductByProdDescription ON dbo.Product_ProdDescription(ProdDescription)
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
	-- maybe Incident caused Property Damage and Claim has Claim ID,
	IncidentID                              int NULL,
	-- maybe Property Damage belongs to owner-Name,
	OwnerName                               varchar(256) NULL,
	-- maybe Property Damage owner has contact Phone and Phone has Phone Nr,
	PhoneNr                                 varchar NULL,
	UNIQUE(IncidentID, AddressStreet, AddressCity, AddressPostcode, AddressStateCode),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID)
)
GO

CREATE TABLE State (
	-- State has State Code,
	StateCode                               tinyint NOT NULL CHECK((StateCode >= 0 AND StateCode <= 9)),
	-- maybe State Name is of State,
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
	-- maybe Third Party is insured by Insurer and Party has Party ID,
	InsurerID                               int NULL,
	-- maybe Third Party vehicle is of model-Year and Year has Year Nr,
	ModelYearNr                             int NULL,
	-- Third Party is where Person was third party in Vehicle Incident and Party has Party ID,
	PersonID                                int NOT NULL,
	-- Third Party is where Person was third party in Vehicle Incident and Vehicle Incident is a kind of Incident and Claim has Claim ID,
	VehicleIncidentID                       int NOT NULL,
	-- maybe Third Party drove vehicle-Registration and Registration has Registration Nr,
	VehicleRegistrationNr                   char(8) NULL,
	-- maybe Third Party vehicle is of Vehicle Type and maybe Badge is of Vehicle Type,
	VehicleTypeBadge                        varchar NULL,
	-- maybe Third Party vehicle is of Vehicle Type and Vehicle Type is of Make,
	VehicleTypeMake                         varchar NULL,
	-- maybe Third Party vehicle is of Vehicle Type and Vehicle Type is of Model,
	VehicleTypeModel                        varchar NULL,
	PRIMARY KEY(PersonID, VehicleIncidentID),
	FOREIGN KEY (InsurerID) REFERENCES Party (PartyID),
	FOREIGN KEY (PersonID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE UnderwritingDemerit (
	-- Underwriting Demerit has Demerit Kind and Demerit Kind has Demerit Kind Name,
	DemeritKindName                         varchar NOT NULL,
	-- maybe Underwriting Demerit occurred occurrence-Count times,
	OccurrenceCount                         int NULL,
	-- Vehicle Incident occurred despite Underwriting Demerit and Vehicle Incident is a kind of Incident and Claim has Claim ID,
	VehicleIncidentID                       int NOT NULL,
	PRIMARY KEY(VehicleIncidentID, DemeritKindName),
	FOREIGN KEY (DemeritKindName) REFERENCES DemeritKind (DemeritKindName)
)
GO

CREATE TABLE VehicleIncident (
	-- maybe Vehicle Incident has Description,
	Description                             varchar(1024) NULL,
	-- maybe Driving is where Vehicle Incident involves Driver and maybe Driving resulted in blood-Test Result,
	DrivingBloodTestResult                  varchar NULL,
	-- maybe Driving is where Vehicle Incident involves Driver and maybe Driving resulted in breath-Test Result,
	DrivingBreathTestResult                 varchar NULL,
	-- maybe Driving is where Vehicle Incident involves Driver and maybe Driving Charge is where Driving resulted in Charge and Driving Charge is where Driving resulted in Charge,
	DrivingCharge                           varchar NULL,
	-- maybe Driving is where Vehicle Incident involves Driver and Driving is where Vehicle Incident involves Driver and Party has Party ID,
	DrivingDriverID                         int NULL,
	-- maybe Driving is where Vehicle Incident involves Driver and maybe Driving (as driver_hospitalised) resulted in driver taken to hospital-Name,
	DrivingHospitalName                     varchar(256) NULL,
	-- maybe Driving is where Vehicle Incident involves Driver and maybe Driving followed Intoxication,
	DrivingIntoxication                     varchar NULL,
	-- maybe Driving is where Vehicle Incident involves Driver and maybe Driving Charge is where Driving resulted in Charge and Driving Charge is a warning,
	DrivingIsAWarning                       bit NULL,
	-- maybe Driving is where Vehicle Incident involves Driver and maybe Driving was without owners consent for nonconsent-Reason,
	DrivingNonconsentReason                 varchar NULL,
	-- maybe Driving is where Vehicle Incident involves Driver and maybe Driving was unlicenced for unlicensed-Reason,
	DrivingUnlicensedReason                 varchar NULL,
	-- Vehicle Incident is a kind of Incident and Claim has Claim ID,
	IncidentID                              int IDENTITY NOT NULL,
	-- maybe Vehicle Incident resulted from Loss Type and Loss Type has Loss Type Code,
	LossTypeCode                            char NULL,
	-- maybe Vehicle Incident involved previous_damage-Description,
	PreviousDamageDescription               varchar(1024) NULL,
	-- maybe Vehicle Incident was caused by Reason,
	Reason                                  varchar NULL,
	-- maybe Vehicle Incident resulted in vehicle being towed to towed-Location,
	TowedLocation                           varchar NULL,
	-- maybe Vehicle Incident occurred during weather-Description,
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
	-- maybe Witness lives at Address and maybe Address is in State and State has State Code,
	AddressStateCode                        tinyint NULL CHECK((AddressStateCode >= 0 AND AddressStateCode <= 9)),
	-- maybe Witness lives at Address and Address is at Street,
	AddressStreet                           varchar(256) NULL,
	-- maybe Witness has contact-Phone and Phone has Phone Nr,
	ContactPhoneNr                          varchar NULL,
	-- Incident was seen by Witness and Claim has Claim ID,
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

