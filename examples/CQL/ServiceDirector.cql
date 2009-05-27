vocabulary ServiceDirector;

/*
 * Value Types
 */
Company_Code is written as FixedLengthText(5);
Credential_Nr is written as SignedInteger(32);
DDMMYYYY is written as Date;
DataStore_Name is written as VariableLengthText(15);
EmailAddress is written as VariableLengthText(50);
HHMMSS is written as Time;
HostSystem_Name is written as VariableLengthText(15);
IP is written as VariableLengthText(16);
MDYHMS is written as AutoTimestamp;
MessageData is written as VariableLengthRawData(8000);
MessageHeader is written as VariableLengthText(30);
Monitor_Id is written as AutoCounter;
MonitoringApplication_Name is written as VariableLengthText(10);
Name is written as VariableLengthText(15);
Netmask is written as VariableLengthText(16);
Network_Nr is written as SignedInteger(32);
NotificationLevel_Nr is written as SignedInteger(32);
NotificationType_Name is written as VariableLengthText(20);
Password is written as VariableLengthText;
Path is written as VariableLengthText(20);
Port is written as SignedInteger(32);
ProviderType_Id is written as SignedSmallInteger(20);
RecurringSchedule_Id is written as AutoCounter;
SatalliteMessage_Id is written as UnsignedInteger(32);
Seconds is written as UnsignedInteger(32);
SerialNumber is written as VariableLengthText(20);
ServiceType is written as VariableLengthText(15);
Subscription_Nr is written as SignedInteger(32);
Switch_Id is written as AutoCounter;
Transaction_Nr is written as UnsignedInteger(32);
TruckPCID is written as UnsignedInteger(32);
UserName is written as VariableLengthText(20);
User_Name is written as VariableLengthText(40);
Version is written as FixedLengthText(5);

/*
 * Entity Types
 */
Company is identified by its _Code;
Company has one Operating-Name;
Company is client;
Company is vendor;

Credential is identified by its _Nr;
Credential has one Password;
Credential has one UserName;

DataStore is identified by its _Name;
DataStore requires at least one Credential;
DataStore has one Friendly-Name;
DataStore has at most one HeartBeat-TruckPCID;
DataStore has one Internal-Credential (as InternalCredential);
DataStore is one Major-Version;
DataStore is one Minor-Version;
DataStore is one Revision-Version;

Date is identified by DDMMYYYY where
	Date has one DDMMYYYY,
	DDMMYYYY is of at most one Date;
Credential has at most one Expiration-Date;

DateTime is identified by MDYHMS where
	DateTime has one MDYHMS,
	MDYHMS is of at most one DateTime;

Duration is identified by Seconds where
	Duration has one Seconds,
	Seconds is of at most one Duration;

GeocodeFile is identified by Path where
	GeocodeFile has one Path,
	Path is of at most one GeocodeFile;
DataStore uses at most one GeocodeFile;

HostSystem is identified by its _Name;
DataStore is on one Primary-HostSystem;
DataStore is on one Secondary-HostSystem;

Monitor is identified by its _Id;
Monitor monitors one DataStore;
Monitor is disabled;

MonitoringApplication is identified by its _Name;
Monitor is owned by one MonitoringApplication;

Network is identified by its _Nr;
Company has at least one Origin-Network;
DataStore has TcpProxy-Network,
	TcpProxy-Network is in at most one DataStore;
HostSystem uses at least one Network,
	Network is used by at most one HostSystem;
Network uses at most one Domain-Name;
Network has at most one Ending-IP;
Network has one Initial-IP;
Network uses at most one Netmask;
Network is ip_range;
Network is ip_single;
Network is ip_subnet;

NotificationLevel is identified by its _Nr;
NotificationLevel has one InitialDelay-Duration;
NotificationLevel has one Repeat-Duration;

NotificationType is identified by its _Name;

ProviderType is identified by its _Id;

RecurringSchedule is identified by its _Id;
Monitor (as MonitorAllExclusion) has AllExclusion-RecurringSchedule,
	AllExclusion-RecurringSchedule applies to at most one MonitorAllExclusion;
Monitor (as MonitorIntegrationExclusion) has IntegrationExclusion-RecurringSchedule,
	IntegrationExclusion-RecurringSchedule applies to at most one MonitorIntegrationExclusion;
RecurringSchedule has one Duration;
RecurringSchedule friday;
RecurringSchedule monday;
RecurringSchedule saturday;
RecurringSchedule sunday;
RecurringSchedule thursday;
RecurringSchedule tuesday;
RecurringSchedule wednesday;

SatalliteMessage is identified by its _Id;
SatalliteMessage is designated for one DataStore;
SatalliteMessage one Insertion-DateTime;
SatalliteMessage has at most one MessageData;
SatalliteMessage has at most one MessageHeader;
SatalliteMessage is of at most one ProviderType;
SatalliteMessage has one SerialNumber;

Subscription is identified by its _Nr;
Company (as DriverTechSubscription) has one DriverTech-Subscription;
Subscription has one Beginning-Date;
Subscription has at most one Ending-Date;
Subscription is enabled;

Switch is identified by its _Id;
DataStore has at most one Legacy-Switch;
Switch is one Major-Version;
Switch is one Minor-Version;
Switch has one Monitoring-Port;
Switch has one Operating-Port;
Switch (as PrivateInterfaceSwitch) is on Private-Network,
	Private-Network connects to at most one PrivateInterfaceSwitch;
Switch (as PublicInterfaceSwitch) is on at least one Public-Network,
	Network connects to at most one PublicInterfaceSwitch;
Switch is one Revision-Version;
Switch is backup messages;
Switch is backup updates;
Switch is send disabled;
Switch is test vectors enabled;

Time is identified by HHMMSS where
	Time has one HHMMSS,
	HHMMSS is of at most one Time;
RecurringSchedule has one Start-Time;

Transaction is identified by its _Nr;
SatalliteMessage has at most one Group-Transaction;

User is identified by its _Name;
User has one Primary-EmailAddress;
User has at most one Secondary-EmailAddress;
User is monitor notification disabled;

Vendor is a kind of Company;
Vendor requires at least one Credential;

Client is a kind of Company;
Client has at most one default-DataStore;
DataStore belongs to one Client,
	Client uses DataStore;

FileHostSystem is a kind of HostSystem;
FileHostSystem has one Port;

HostSystemRunsSwitch is where
	HostSystem runs Switch;

MonitorNotificationType is where
	Monitor has at least one NotificationType;
MonitorNotificationType is excluded;

MonitorNotificationUser is where
	MonitorNotificationType has Notification-User;
MonitorNotificationUser has one NotificationLevel;

Service is identified by Vendor and ServiceType where
	Vendor provides Service,
	Service is of one ServiceType;

DataStoreFileHostSystem is where
	DataStore has at most one FileHostSystem;
DataStoreFileHostSystem has one Internal-Credential;

DataStoreService is where
	DataStore has Service;
DataStoreService belongs to one Client;
DataStoreService requires at least one Credential;
DataStoreService (as DataStoreServiceSubscription) has one Subscription;

/*
 * Constraints:
 */
for each Company exactly one of these holds:
	Company is client,
	Company is vendor;
for each Credential exactly one of these holds:
	DataStore requires Credential,
	DataStoreService requires Credential,
	Vendor requires Credential,
	DataStoreFileHostSystem has Internal-Credential,
	DataStore has Internal-Credential;
Network is ip_subnet
	if and only if
	Network uses Netmask;
Network has Ending-IP
	if and only if
	Network is ip_range;
for each Network at most one of these holds:
	Network is ip_single,
	Network has Ending-IP;
for each Network exactly one of these holds:
	HostSystem uses Network,
	Company has Origin-Network,
	DataStore has TcpProxy-Network;
for each Network exactly one of these holds:
	Network is ip_single,
	Network is ip_subnet,
	Network is ip_range;
Switch is on Private-Network
	if and only if
	DataStore has Legacy-Switch;
for each Switch exactly one of these holds:
	HostSystem runs Switch,
	DataStore has Legacy-Switch;
Client has default-DataStore
	only if DataStore belongs to Client;
Network uses Domain-Name
	only if Network is ip_single;
DataStore has TcpProxy-Network
	only if Network is ip_single;
each Credential occurs at most one time in
	DataStore requires Credential;
each Credential occurs at most one time in
	Vendor requires Credential;
each Credential occurs at most one time in
	DataStoreFileHostSystem has Internal-Credential;
each Credential occurs at most one time in
	DataStore has Internal-Credential;
each Credential occurs at most one time in
	DataStoreService requires Credential;
each IP occurs at most one time in
	Network has Initial-IP;
each IP occurs at most one time in
	Network has Ending-IP;
each Name occurs at most one time in
	DataStore has Friendly-Name;
each Network occurs at most one time in
	Company has Origin-Network;
each Port occurs at most one time in
	Switch has Monitoring-Port;
each RecurringSchedule occurs at least one time in
	RecurringSchedule monday,
	RecurringSchedule tuesday,
	RecurringSchedule wednesday,
	RecurringSchedule thursday,
	RecurringSchedule friday,
	RecurringSchedule saturday,
	RecurringSchedule sunday;
each Service occurs one time in
	Vendor provides Service;
each Service occurs at least one time in
	DataStore has Service;
each Subscription occurs at most one time in
	DataStoreService has Subscription;
each Subscription occurs at most one time in
	Company has DriverTech-Subscription;
each Switch occurs at most one time in
	DataStore has Legacy-Switch;
each combination UserName, Vendor, DataStoreService, DataStore occurs at most one time in
	Credential has UserName,
	Vendor requires Credential,
	DataStoreService requires Credential,
	DataStore requires Credential;
