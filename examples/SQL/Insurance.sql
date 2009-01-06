CREATE TABLE Asset (
	AssetID                                 AutoCounter NOT NULL,
	VehicleVIN                              UnsignedInteger(32) NULL,
	VehicleModelYearNr                      SignedInteger(32) NULL,
	VehicleTypeModel                        VariableLengthText NULL,
	VehicleTypeMake                         VariableLengthText NULL,
	VehicleTypeBadge                        VariableLengthText NULL,
	VehicleEngineNumber                     VariableLengthText NULL,
	VehicleHasCommercialRegistration        BIT NULL,
	VehicleFinanceInstitutionID             AutoCounter NULL,
	VehicleDealerID                         AutoCounter NULL,
	VehicleRegistrationNr                   FixedLengthText(8) NULL,
	VehicleColour                           VariableLengthText NULL,
	PRIMARY KEY(AssetID)
)
GO

CREATE TABLE Claim (
	PolicyP_yearNr                          SignedInteger(32) NOT NULL,
	PolicyP_productCode                     UnsignedTinyInteger(32) NOT NULL CHECK(REVISIT: valid value),
	PolicyP_stateCode                       UnsignedTinyInteger(32) NOT NULL CHECK(REVISIT: valid value),
	PolicyP_serial                          UnsignedInteger(32) NOT NULL CHECK(REVISIT: valid value),
	P_sequence                              UnsignedInteger(32) NOT NULL CHECK(REVISIT: valid value),
	LodgementPersonID                       AutoCounter NULL,
	LodgementDateTime                       DateAndTime NULL,
	IncidentDateTime                        DateAndTime NULL,
	IncidentAddressStreet                   VariableLengthText(256) NULL,
	IncidentAddressCity                     VariableLengthText NULL,
	IncidentAddressPostcode                 VariableLengthText NULL,
	IncidentAddressStateCode                UnsignedTinyInteger(32) NULL CHECK(REVISIT: valid value),
	IncidentDateTime                        DateAndTime NULL,
	IncidentReporterName                    VariableLengthText(256) NULL,
	IncidentStationName                     VariableLengthText(256) NULL,
	IncidentPoliceReportNr                  SignedInteger(32) NULL,
	IncidentOfficerName                     VariableLengthText(256) NULL,
	ClaimID                                 AutoCounter NOT NULL,
	PRIMARY KEY(ClaimID)
)
GO

CREATE TABLE ContractorAppointment (
	ContractorID                            AutoCounter NOT NULL,
	ClaimID                                 AutoCounter NOT NULL,
	PRIMARY KEY(ClaimID, ContractorID)
)
GO

CREATE TABLE Cover (
	PolicyP_yearNr                          SignedInteger(32) NOT NULL,
	PolicyP_productCode                     UnsignedTinyInteger(32) NOT NULL CHECK(REVISIT: valid value),
	PolicyP_stateCode                       UnsignedTinyInteger(32) NOT NULL CHECK(REVISIT: valid value),
	PolicyP_serial                          UnsignedInteger(32) NOT NULL CHECK(REVISIT: valid value),
	CoverTypeCode                           FixedLengthText NOT NULL,
	AssetID                                 AutoCounter NOT NULL,
	PRIMARY KEY(PolicyP_yearNr, PolicyP_productCode, PolicyP_stateCode, PolicyP_serial, AssetID, CoverTypeCode)
)
GO

CREATE TABLE CoverType (
	CoverTypeName                           VariableLengthText NOT NULL,
	CoverTypeCode                           FixedLengthText NOT NULL,
	PRIMARY KEY(CoverTypeCode)
)
GO

CREATE TABLE CoverWording (
	CoverTypeCode                           FixedLengthText NOT NULL,
	PolicyWordingText                       LargeLengthText NOT NULL,
	StartDate                               Date NOT NULL,
	PRIMARY KEY(CoverTypeCode, PolicyWordingText, StartDate)
)
GO

CREATE TABLE DamagedProperty (
	OwnerName                               VariableLengthText(256) NULL,
	AddressStreet                           VariableLengthText(256) NOT NULL,
	AddressCity                             VariableLengthText NOT NULL,
	AddressPostcode                         VariableLengthText NULL,
	AddressStateCode                        UnsignedTinyInteger(32) NULL CHECK(REVISIT: valid value),
	IncidentID                              AutoCounter NULL,
	PhoneNr                                 VariableLengthText NULL,
	UNIQUE(IncidentID, AddressStreet, AddressCity, AddressPostcode, AddressStateCode)
)
GO

CREATE TABLE DemeritKind (
	DemeritKindName                         VariableLengthText NOT NULL,
	PRIMARY KEY(DemeritKindName)
)
GO

CREATE TABLE LossType (
	LossTypeCode                            FixedLengthText NOT NULL,
	LiabilityCode                           FixedLengthText(1) NULL CHECK(REVISIT: valid value),
	IsSingleVehicleIncident                 BIT NOT NULL,
	InvolvesDriving                         BIT NOT NULL,
	PRIMARY KEY(LossTypeCode)
)
GO

CREATE TABLE LostItem (
	LostItemNr                              SignedInteger(32) NOT NULL,
	IncidentID                              AutoCounter NOT NULL,
	Description                             VariableLengthText(1024) NOT NULL,
	PurchasePlace                           VariableLengthText NULL,
	PurchasePrice                           Decimal(18, 2) NULL,
	PurchaseDate                            Date NULL,
	PRIMARY KEY(IncidentID, LostItemNr)
)
GO

CREATE TABLE Party (
	PartyID                                 AutoCounter NOT NULL,
	IsACompany                              BIT NOT NULL,
	PostalAddressStreet                     VariableLengthText(256) NULL,
	PostalAddressCity                       VariableLengthText NULL,
	PostalAddressPostcode                   VariableLengthText NULL,
	PostalAddressStateCode                  UnsignedTinyInteger(32) NULL CHECK(REVISIT: valid value),
	PersonGivenName                         VariableLengthText(256) NULL,
	PersonFamilyName                        VariableLengthText(256) NULL,
	PersonTitle                             VariableLengthText NULL,
	PersonBirthDate                         Date NULL,
	PersonOccupation                        VariableLengthText NULL,
	PersonAddressStreet                     VariableLengthText(256) NULL,
	PersonAddressCity                       VariableLengthText NULL,
	PersonAddressPostcode                   VariableLengthText NULL,
	PersonAddressStateCode                  UnsignedTinyInteger(32) NULL CHECK(REVISIT: valid value),
	PersonMobilePhoneNr                     VariableLengthText NULL,
	PersonHomePhoneNr                       VariableLengthText NULL,
	PersonBusinessPhoneNr                   VariableLengthText NULL,
	PersonEmail                             VariableLengthText NULL,
	PersonContactTime                       Time NULL,
	PersonPreferredContactMethod            FixedLengthText(1) NULL CHECK(REVISIT: valid value),
	DriverLicenseNumber                     VariableLengthText NULL,
	DriverLicenseType                       VariableLengthText NULL,
	DriverIsInternational                   BIT NULL,
	DriverYearNr                            SignedInteger(32) NULL,
	CompanyContactPersonID                  AutoCounter NULL,
	PRIMARY KEY(PartyID)
)
GO

CREATE TABLE Policy (
	AuthorisedRepID                         AutoCounter NULL,
	ClientID                                AutoCounter NOT NULL,
	P_yearNr                                SignedInteger(32) NOT NULL,
	P_productCode                           UnsignedTinyInteger(32) NOT NULL CHECK(REVISIT: valid value),
	P_stateCode                             UnsignedTinyInteger(32) NOT NULL CHECK(REVISIT: valid value),
	P_serial                                UnsignedInteger(32) NOT NULL CHECK(REVISIT: valid value),
	ITCClaimed                              Decimal(18, 2) NULL CHECK(REVISIT: valid value),
	ApplicationNr                           SignedInteger(32) NOT NULL,
	PRIMARY KEY(P_yearNr, P_productCode, P_stateCode, P_serial)
)
GO

CREATE TABLE Product (
	ProductCode                             UnsignedTinyInteger(32) NOT NULL CHECK(REVISIT: valid value),
	Alias                                   FixedLengthText(3) NULL,
	ProdDescription                         VariableLengthText(80) NULL,
	PRIMARY KEY(ProductCode)
)
GO

CREATE TABLE State (
	StateCode                               UnsignedTinyInteger(32) NOT NULL CHECK(REVISIT: valid value),
	StateName                               VariableLengthText(256) NULL,
	PRIMARY KEY(StateCode)
)
GO

CREATE TABLE ThirdParty (
	PersonID                                AutoCounter NOT NULL,
	VehicleIncidentID                       AutoCounter NOT NULL,
	InsurerID                               AutoCounter NULL,
	VehicleRegistrationNr                   FixedLengthText(8) NULL,
	ModelYearNr                             SignedInteger(32) NULL,
	VehicleTypeModel                        VariableLengthText NULL,
	VehicleTypeMake                         VariableLengthText NULL,
	VehicleTypeBadge                        VariableLengthText NULL,
	PRIMARY KEY(PersonID, VehicleIncidentID)
)
GO

CREATE TABLE UnderwritingDemerit (
	VehicleIncidentID                       AutoCounter NOT NULL,
	DemeritKindName                         VariableLengthText NOT NULL,
	OccurrenceCount                         UnsignedInteger(32) NULL,
	PRIMARY KEY(VehicleIncidentID, DemeritKindName)
)
GO

CREATE TABLE VehicleIncident (
	IncidentID                              AutoCounter NOT NULL,
	DrivingDriverID                         AutoCounter NULL,
	DrivingNonconsentReason                 VariableLengthText NULL,
	DrivingUnlicensedReason                 VariableLengthText NULL,
	DrivingIntoxication                     VariableLengthText NULL,
	DrivingHospitalName                     VariableLengthText(256) NULL,
	DrivingBreathTestResult                 VariableLengthText NULL,
	DrivingBloodTestResult                  VariableLengthText NULL,
	DrivingCharge                           VariableLengthText NULL,
	DrivingIsWarning                        BIT NULL,
	TowedLocation                           VariableLengthText NULL,
	Description                             VariableLengthText(1024) NULL,
	LossTypeCode                            FixedLengthText NULL,
	Reason                                  VariableLengthText NULL,
	Previous_damageDescription              VariableLengthText(1024) NULL,
	WeatherDescription                      VariableLengthText(1024) NULL,
	PRIMARY KEY(IncidentID)
)
GO

CREATE TABLE Witness (
	IncidentID                              AutoCounter NOT NULL,
	Name                                    VariableLengthText(256) NOT NULL,
	AddressStreet                           VariableLengthText(256) NULL,
	AddressCity                             VariableLengthText NULL,
	AddressPostcode                         VariableLengthText NULL,
	AddressStateCode                        UnsignedTinyInteger(32) NULL CHECK(REVISIT: valid value),
	ContactPhoneNr                          VariableLengthText NULL,
	PRIMARY KEY(IncidentID, Name)
)
GO

