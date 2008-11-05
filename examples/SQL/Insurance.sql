CREATE TABLE Party (
	IsACompany	bit NOT NULL,
	DriverYearNr	int NULL,
	DriverIsInternational	bit NULL,
	DriverLicenseNumber	varchar NULL,
	DriverLicenseType	varchar NULL,
	PersonAddressStateCode	StateCode(32) NULL,
	PersonAddressStreet	varchar(256) NULL,
	PersonAddressCity	varchar NULL,
	PersonAddressPostcode	varchar NULL,
	PersonMobilePhoneNr	varchar NULL,
	PersonHomePhoneNr	varchar NULL,
	PersonBusinessPhoneNr	varchar NULL,
	PersonEmail	varchar NULL,
	PersonContactTime	Time NULL,
	PersonPreferredContactMethod	ContactMethod(1) NULL,
	PersonTitle	varchar NULL,
	PersonBirthDate	datetime NULL,
	PersonOccupation	varchar NULL,
	PersonGivenName	varchar(256) NULL,
	PersonFamilyName	varchar(256) NULL,
	PostalAddressStateCode	StateCode(32) NULL,
	PostalAddressStreet	varchar(256) NULL,
	PostalAddressCity	varchar NULL,
	PostalAddressPostcode	varchar NULL,
	CompanyContactPersonID	int NULL,
	PartyID	int NOT NULL,
	UNIQUE(PartyID)
)
GO

CREATE TABLE Policy (
	ClientID	int NOT NULL,
	P_yearNr	int NOT NULL,
	P_stateCode	StateCode(32) NOT NULL,
	P_productCode	ProductCode(32) NOT NULL,
	AuthorisedRepID	int NULL,
	ApplicationNr	int NOT NULL,
	P_serial	int NOT NULL,
	ITCClaimed	decimal(18, 2) NULL,
	UNIQUE(P_yearNr, P_productCode, P_stateCode, P_serial)
)
GO

CREATE TABLE Claim (
	PolicyP_yearNr	int NOT NULL,
	PolicyP_productCode	ProductCode(32) NOT NULL,
	PolicyP_stateCode	StateCode(32) NOT NULL,
	PolicyP_serial	int NOT NULL,
	IncidentAddressStateCode	StateCode(32) NULL,
	IncidentAddressStreet	varchar(256) NULL,
	IncidentAddressCity	varchar NULL,
	IncidentAddressPostcode	varchar NULL,
	VehicleIncidentLossTypeCode	LossTypeCode NULL,
	VehicleIncidentReason	varchar NULL,
	VehicleIncidentTowedLocation	varchar NULL,
	VehicleIncidentDescription	varchar(1024) NULL,
	VehicleIncidentPrevious_damageDescription	varchar(1024) NULL,
	VehicleIncidentWeatherDescription	varchar(1024) NULL,
	VehicleIncidentDrivingDriverID	int NULL,
	VehicleIncidentDrivingNonconsentReason	varchar NULL,
	VehicleIncidentDrivingUnlicensedReason	varchar NULL,
	VehicleIncidentDrivingIntoxication	varchar NULL,
	VehicleIncidentDrivingBreathTestResult	varchar NULL,
	VehicleIncidentDrivingBloodTestResult	varchar NULL,
	VehicleIncidentDrivingHospitalName	varchar(256) NULL,
	VehicleIncidentDrivingCharge	varchar NULL,
	VehicleIncidentDrivingIsWarning	bit NULL,
	IncidentDateTime	DateTime NULL,
	IncidentName	varchar(256) NULL,
	IncidentStationName	varchar(256) NULL,
	IncidentOfficerName	varchar(256) NULL,
	IncidentPoliceReportNr	int NULL,
	IncidentDateTime	DateTime NULL,
	P_sequence	int NOT NULL,
	ClaimID	int NOT NULL,
	LodgementPersonID	int NOT NULL,
	LodgementDateTime	DateTime NULL,
	UNIQUE(ClaimID)
)
GO

CREATE TABLE CoverType (
	CoverTypeName	varchar NOT NULL,
	CoverTypeCode	CoverTypeCode NOT NULL,
	UNIQUE(CoverTypeCode)
)
GO

CREATE TABLE State (
	StateName	varchar(256) NULL,
	StateCode	StateCode(32) NOT NULL,
	UNIQUE(StateCode)
)
GO

CREATE TABLE Product (
	ProductCode	ProductCode(32) NOT NULL,
	Alias	Alias(3) NULL,
	ProdDescription	varchar(80) NULL,
	UNIQUE(ProductCode)
)
GO

CREATE TABLE Asset (
	VehicleDealerID	int NULL,
	VehicleHasCommercialRegistration	bit NULL,
	VehicleModelYearNr	int NULL,
	VehicleVehicleTypeMake	varchar NULL,
	VehicleVehicleTypeModel	varchar NULL,
	VehicleVehicleTypeBadge	varchar NULL,
	VehicleFinanceInstitutionID	int NULL,
	VehicleRegistrationNr	RegistrationNr(8) NULL,
	VehicleVIN	int NULL,
	VehicleEngineNumber	varchar NULL,
	VehicleColour	varchar NULL,
	AssetID	int NOT NULL,
	UNIQUE(AssetID)
)
GO

CREATE TABLE UnderwritingDemerit (
	DemeritKindName	varchar NOT NULL,
	VehicleIncidentClaimID	int NOT NULL,
	OccurrenceCount	int NULL,
	UNIQUE(VehicleIncidentClaimID, DemeritKindName)
)
GO

CREATE TABLE DemeritKind (
	DemeritKindName	varchar NOT NULL,
	UNIQUE(DemeritKindName)
)
GO

CREATE TABLE DamagedProperty (
	AddressStateCode	StateCode(32) NULL,
	AddressStreet	varchar(256) NOT NULL,
	AddressCity	varchar NOT NULL,
	AddressPostcode	varchar NULL,
	PhoneNr	varchar NULL,
	IncidentClaimID	int NULL,
	OwnerName	varchar(256) NULL,
	UNIQUE(IncidentClaimID, AddressStreet, AddressCity, AddressPostcode, AddressStateCode)
)
GO

CREATE TABLE Witness (
	AddressStateCode	StateCode(32) NULL,
	AddressStreet	varchar(256) NULL,
	AddressCity	varchar NULL,
	AddressPostcode	varchar NULL,
	ContactPhoneNr	varchar NULL,
	IncidentClaimID	int NOT NULL,
	Name	varchar(256) NOT NULL,
	UNIQUE(IncidentClaimID, Name)
)
GO

CREATE TABLE LossType (
	IsSingleVehicleIncident	bit NOT NULL,
	InvolvesDriving	bit NOT NULL,
	LiabilityCode	LiabilityCode(1) NULL,
	LossTypeCode	LossTypeCode NOT NULL,
	UNIQUE(LossTypeCode)
)
GO

CREATE TABLE LostItem (
	IncidentClaimID	int NOT NULL,
	PurchaseDate	datetime NULL,
	Description	varchar(1024) NOT NULL,
	LostItemNr	int NOT NULL,
	PurchasePrice	decimal(18, 2) NULL,
	PurchasePlace	varchar NULL,
	UNIQUE(IncidentClaimID, LostItemNr)
)
GO

CREATE TABLE ContractorAppointment (
	ClaimID	int NOT NULL,
	ContractorID	int NOT NULL,
	UNIQUE(ClaimID, ContractorID)
)
GO

CREATE TABLE ThirdParty (
	PersonID	int NOT NULL,
	ModelYearNr	int NULL,
	VehicleTypeMake	varchar NULL,
	VehicleTypeModel	varchar NULL,
	VehicleTypeBadge	varchar NULL,
	InsurerID	int NULL,
	VehicleRegistrationNr	RegistrationNr(8) NULL,
	VehicleIncidentClaimID	int NOT NULL,
	UNIQUE(PersonID, VehicleIncidentClaimID)
)
GO

CREATE TABLE CoverWording (
	CoverTypeCode	CoverTypeCode NOT NULL,
	PolicyWordingText	PolicyWordingText NOT NULL,
	StartDate	datetime NOT NULL,
	UNIQUE(CoverTypeCode, PolicyWordingText, StartDate)
)
GO

CREATE TABLE Cover (
	PolicyP_yearNr	int NOT NULL,
	PolicyP_productCode	ProductCode(32) NOT NULL,
	PolicyP_stateCode	StateCode(32) NOT NULL,
	PolicyP_serial	int NOT NULL,
	CoverTypeCode	CoverTypeCode NOT NULL,
	AssetID	int NOT NULL,
	UNIQUE(PolicyP_yearNr, PolicyP_productCode, PolicyP_stateCode, PolicyP_serial, AssetID, CoverTypeCode)
)
GO

