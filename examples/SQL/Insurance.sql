CREATE TABLE Asset (
	AssetID                                 int IDENTITY NOT NULL,
	VehicleVIN                              int NULL,
	VehicleModelYearNr                      int NULL,
	VehicleTypeModel                        varchar NULL,
	VehicleTypeMake                         varchar NULL,
	VehicleTypeBadge                        varchar NULL,
	VehicleEngineNumber                     varchar NULL,
	VehicleHasCommercialRegistration        bit NULL,
	VehicleFinanceInstitutionID             int NULL,
	VehicleDealerID                         int NULL,
	VehicleRegistrationNr                   char(8) NULL,
	VehicleColour                           varchar NULL,
	PRIMARY KEY(AssetID)
)
GO

CREATE TABLE Claim (
	PolicyP_yearNr                          int NOT NULL,
	PolicyP_productCode                     tinyint(32) NOT NULL,
	PolicyP_stateCode                       tinyint(32) NOT NULL,
	PolicyP_serial                          int NOT NULL,
	P_sequence                              int NOT NULL CHECK((P_sequence >= 1 AND P_sequence <= 999)),
	LodgementPersonID                       int NULL,
	LodgementDateTime                       datetime NULL,
	IncidentDateTime                        datetime NULL,
	IncidentAddressStreet                   varchar(256) NULL,
	IncidentAddressCity                     varchar NULL,
	IncidentAddressPostcode                 varchar NULL,
	IncidentAddressStateCode                tinyint(32) NULL CHECK((IncidentAddressStateCode >= 0 AND IncidentAddressStateCode <= 9)),
	IncidentDateTime                        datetime NULL,
	IncidentReporterName                    varchar(256) NULL,
	IncidentStationName                     varchar(256) NULL,
	IncidentPoliceReportNr                  int NULL,
	IncidentOfficerName                     varchar(256) NULL,
	ClaimID                                 int IDENTITY NOT NULL,
	PRIMARY KEY(ClaimID)
)
GO

CREATE TABLE ContractorAppointment (
	ContractorID                            int NOT NULL,
	ClaimID                                 int NOT NULL,
	PRIMARY KEY(ClaimID, ContractorID),
	FOREIGN KEY (ClaimID) REFERENCES Claim (ClaimID)
)
GO

CREATE TABLE Cover (
	PolicyP_yearNr                          int NOT NULL,
	PolicyP_productCode                     tinyint(32) NOT NULL,
	PolicyP_stateCode                       tinyint(32) NOT NULL,
	PolicyP_serial                          int NOT NULL,
	CoverTypeCode                           char NOT NULL,
	AssetID                                 int NOT NULL,
	PRIMARY KEY(PolicyP_yearNr, PolicyP_productCode, PolicyP_stateCode, PolicyP_serial, AssetID, CoverTypeCode),
	FOREIGN KEY (AssetID) REFERENCES Asset (AssetID)
)
GO

CREATE TABLE CoverType (
	CoverTypeName                           varchar NOT NULL,
	CoverTypeCode                           char NOT NULL,
	PRIMARY KEY(CoverTypeCode)
)
GO

CREATE TABLE CoverWording (
	CoverTypeCode                           char NOT NULL,
	PolicyWordingText                       text NOT NULL,
	StartDate                               datetime NOT NULL,
	PRIMARY KEY(CoverTypeCode, PolicyWordingText, StartDate),
	FOREIGN KEY (CoverTypeCode) REFERENCES CoverType (CoverTypeCode)
)
GO

CREATE TABLE DamagedProperty (
	OwnerName                               varchar(256) NULL,
	AddressStreet                           varchar(256) NOT NULL,
	AddressCity                             varchar NOT NULL,
	AddressPostcode                         varchar NULL,
	AddressStateCode                        tinyint(32) NULL CHECK((AddressStateCode >= 0 AND AddressStateCode <= 9)),
	IncidentID                              int NULL,
	PhoneNr                                 varchar NULL,
	UNIQUE(IncidentID, AddressStreet, AddressCity, AddressPostcode, AddressStateCode),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID)
)
GO

CREATE TABLE DemeritKind (
	DemeritKindName                         varchar NOT NULL,
	PRIMARY KEY(DemeritKindName)
)
GO

CREATE TABLE LossType (
	LossTypeCode                            char NOT NULL,
	LiabilityCode                           char(1) NULL CHECK(LiabilityCode = 'L' OR LiabilityCode = 'R' OR LiabilityCode = 'U' OR LiabilityCode = 'D'),
	IsSingleVehicleIncident                 bit NOT NULL,
	InvolvesDriving                         bit NOT NULL,
	PRIMARY KEY(LossTypeCode)
)
GO

CREATE TABLE LostItem (
	LostItemNr                              int NOT NULL,
	IncidentID                              int NOT NULL,
	Description                             varchar(1024) NOT NULL,
	PurchasePlace                           varchar NULL,
	PurchasePrice                           decimal(18, 2) NULL,
	PurchaseDate                            datetime NULL,
	PRIMARY KEY(IncidentID, LostItemNr),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID)
)
GO

CREATE TABLE Party (
	PartyID                                 int IDENTITY NOT NULL,
	IsACompany                              bit NOT NULL,
	PostalAddressStreet                     varchar(256) NULL,
	PostalAddressCity                       varchar NULL,
	PostalAddressPostcode                   varchar NULL,
	PostalAddressStateCode                  tinyint(32) NULL CHECK((PostalAddressStateCode >= 0 AND PostalAddressStateCode <= 9)),
	PersonGivenName                         varchar(256) NULL,
	PersonFamilyName                        varchar(256) NULL,
	PersonTitle                             varchar NULL,
	PersonBirthDate                         datetime NULL,
	PersonOccupation                        varchar NULL,
	PersonAddressStreet                     varchar(256) NULL,
	PersonAddressCity                       varchar NULL,
	PersonAddressPostcode                   varchar NULL,
	PersonAddressStateCode                  tinyint(32) NULL CHECK((PersonAddressStateCode >= 0 AND PersonAddressStateCode <= 9)),
	PersonMobilePhoneNr                     varchar NULL,
	PersonHomePhoneNr                       varchar NULL,
	PersonBusinessPhoneNr                   varchar NULL,
	PersonEmail                             varchar NULL,
	PersonContactTime                       datetime NULL,
	PersonPreferredContactMethod            char(1) NULL CHECK(PersonPreferredContactMethod = 'H' OR PersonPreferredContactMethod = 'B' OR PersonPreferredContactMethod = 'M'),
	DriverLicenseNumber                     varchar NULL,
	DriverLicenseType                       varchar NULL,
	DriverIsInternational                   bit NULL,
	DriverYearNr                            int NULL,
	CompanyContactPersonID                  int NULL,
	PRIMARY KEY(PartyID)
)
GO

CREATE TABLE Policy (
	AuthorisedRepID                         int NULL,
	ClientID                                int NOT NULL,
	P_yearNr                                int NOT NULL,
	P_productCode                           tinyint(32) NOT NULL,
	P_stateCode                             tinyint(32) NOT NULL,
	P_serial                                int NOT NULL CHECK((P_serial >= 1 AND P_serial <= 99999)),
	ITCClaimed                              decimal(18, 2) NULL CHECK((ITCClaimed >= 0.0 AND ITCClaimed <= 100.0)),
	ApplicationNr                           int NOT NULL,
	PRIMARY KEY(P_yearNr, P_productCode, P_stateCode, P_serial),
	FOREIGN KEY (AuthorisedRepID) REFERENCES Party (PartyID),
	FOREIGN KEY (ClientID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE Product (
	ProductCode                             tinyint(32) NOT NULL CHECK((ProductCode >= 1 AND ProductCode <= 99)),
	Alias                                   char(3) NULL,
	ProdDescription                         varchar(80) NULL,
	PRIMARY KEY(ProductCode)
)
GO

CREATE TABLE State (
	StateCode                               tinyint(32) NOT NULL CHECK((StateCode >= 0 AND StateCode <= 9)),
	StateName                               varchar(256) NULL,
	PRIMARY KEY(StateCode)
)
GO

CREATE TABLE ThirdParty (
	PersonID                                int NOT NULL,
	VehicleIncidentID                       int NOT NULL,
	InsurerID                               int NULL,
	VehicleRegistrationNr                   char(8) NULL,
	ModelYearNr                             int NULL,
	VehicleTypeModel                        varchar NULL,
	VehicleTypeMake                         varchar NULL,
	VehicleTypeBadge                        varchar NULL,
	PRIMARY KEY(PersonID, VehicleIncidentID),
	FOREIGN KEY (PersonID) REFERENCES Party (PartyID),
	FOREIGN KEY (InsurerID) REFERENCES Party (PartyID)
)
GO

CREATE TABLE UnderwritingDemerit (
	VehicleIncidentID                       int NOT NULL,
	DemeritKindName                         varchar NOT NULL,
	OccurrenceCount                         int NULL,
	PRIMARY KEY(VehicleIncidentID, DemeritKindName),
	FOREIGN KEY (DemeritKindName) REFERENCES DemeritKind (DemeritKindName)
)
GO

CREATE TABLE VehicleIncident (
	IncidentID                              int IDENTITY NOT NULL,
	DrivingDriverID                         int NULL,
	DrivingNonconsentReason                 varchar NULL,
	DrivingUnlicensedReason                 varchar NULL,
	DrivingIntoxication                     varchar NULL,
	DrivingHospitalName                     varchar(256) NULL,
	DrivingBreathTestResult                 varchar NULL,
	DrivingBloodTestResult                  varchar NULL,
	DrivingCharge                           varchar NULL,
	DrivingIsWarning                        bit NULL,
	TowedLocation                           varchar NULL,
	Description                             varchar(1024) NULL,
	LossTypeCode                            char NULL,
	Reason                                  varchar NULL,
	Previous_damageDescription              varchar(1024) NULL,
	WeatherDescription                      varchar(1024) NULL,
	PRIMARY KEY(IncidentID),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID),
	FOREIGN KEY (LossTypeCode) REFERENCES LossType (LossTypeCode)
)
GO

CREATE TABLE Witness (
	IncidentID                              int NOT NULL,
	Name                                    varchar(256) NOT NULL,
	AddressStreet                           varchar(256) NULL,
	AddressCity                             varchar NULL,
	AddressPostcode                         varchar NULL,
	AddressStateCode                        tinyint(32) NULL CHECK((AddressStateCode >= 0 AND AddressStateCode <= 9)),
	ContactPhoneNr                          varchar NULL,
	PRIMARY KEY(IncidentID, Name),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID)
)
GO

ALTER TABLE Claim
	ADD FOREIGN KEY (PolicyP_yearNr, PolicyP_productCode, PolicyP_stateCode, PolicyP_serial) REFERENCES Policy (P_yearNr, P_productCode, P_stateCode, P_serial)
GO

ALTER TABLE ContractorAppointment
	ADD FOREIGN KEY (ContractorID) REFERENCES Party (PartyID)
GO

ALTER TABLE Cover
	ADD FOREIGN KEY (PolicyP_yearNr, PolicyP_productCode, PolicyP_stateCode, PolicyP_serial) REFERENCES Policy (P_yearNr, P_productCode, P_stateCode, P_serial)
GO

ALTER TABLE Cover
	ADD FOREIGN KEY (CoverTypeCode) REFERENCES CoverType (CoverTypeCode)
GO

ALTER TABLE Policy
	ADD FOREIGN KEY (P_productCode) REFERENCES Product (ProductCode)
GO

ALTER TABLE Policy
	ADD FOREIGN KEY (P_stateCode) REFERENCES State (StateCode)
GO

ALTER TABLE ThirdParty
	ADD FOREIGN KEY (VehicleIncidentID) REFERENCES VehicleIncident (IncidentID)
GO

ALTER TABLE UnderwritingDemerit
	ADD FOREIGN KEY (VehicleIncidentID) REFERENCES VehicleIncident (IncidentID)
GO

