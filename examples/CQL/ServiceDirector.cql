vocabulary ServiceDirector;

/*
 * Value Types
 */
Company_Code is defined as FixedLengthText(5);
Credential_Nr is defined as SignedInteger(32);
DDMMYYYY is defined as Date();
DataStore_Name is defined as VariableLengthText(15);
EmailAddress is defined as VariableLengthText(50);
HHMMSS is defined as Time();
HostSystem_Name is defined as VariableLengthText(15);
IP is defined as VariableLengthText(16);
MDYHMS is defined as AutoTimestamp();
MessageData is defined as VariableLengthRawData(8000);
MessageHeader is defined as VariableLengthText(30);
Monitor_Id is defined as AutoCounter();
MonitoringApplication_Name is defined as VariableLengthText(10);
Name is defined as VariableLengthText(15);
Netmask is defined as VariableLengthText(16);
Network_Nr is defined as SignedInteger(32);
NotificationLevel_Nr is defined as SignedInteger(32);
NotificationType_Name is defined as VariableLengthText(20);
Password is defined as VariableLengthText();
Path is defined as VariableLengthText(20);
Port is defined as SignedInteger(32);
ProviderType_Id is defined as SignedSmallInteger(20);
RecurringSchedule_Id is defined as AutoCounter();
SatalliteMessage_Id is defined as UnsignedInteger(32);
Seconds is defined as UnsignedInteger(32);
SerialNumber is defined as VariableLengthText(20);
ServiceType is defined as VariableLengthText(15);
Subscription_Nr is defined as SignedInteger(32);
Switch_Id is defined as AutoCounter();
Transaction_Nr is defined as UnsignedInteger(32);
TruckPCID is defined as UnsignedInteger(32);
UserName is defined as VariableLengthText(20);
User_Name is defined as VariableLengthText(40);
Version is defined as FixedLengthText(5);

/*
 * Entity Types
 */
Company is identified by Company_Code where
	Company has exactly one Company_Code,
	Company_Code is of at most one Company;
Company has exactly one Operating-Name;
Company Is Client;
Company Is Vendor;

Credential is identified by Credential_Nr where
	Credential has exactly one Credential_Nr,
	Credential_Nr is of at most one Credential;
Credential has exactly one Password;
Credential has exactly one UserName;

DataStore is identified by DataStore_Name where
	DataStore has exactly one DataStore_Name,
	DataStore_Name is of at most one DataStore;
DataStore requires at least one Credential;
DataStore (as FriendlyName) has exactly one Friendly-Name;
DataStore has at most one HeartBeat-TruckPCID;
DataStore has exactly one Internal-Credential (as InternalCredential);
DataStore is exactly one Major-Version;
DataStore is exactly one Minor-Version;
DataStore is exactly one Revision-Version;

Date is identified by DDMMYYYY where
	Date has exactly one DDMMYYYY,
	DDMMYYYY is of at most one Date;
Credential has at most one Expiration-Date;

DateTime is identified by MDYHMS where
	DateTime has exactly one MDYHMS,
	MDYHMS is of at most one DateTime;

Duration is identified by Seconds where
	Duration has exactly one Seconds,
	Seconds is of at most one Duration;

GeocodeFile is identified by Path where
	GeocodeFile has exactly one Path,
	Path is of at most one GeocodeFile;
DataStore uses at most one GeocodeFile;

HostSystem is identified by HostSystem_Name where
	HostSystem has exactly one HostSystem_Name,
	HostSystem_Name is of at most one HostSystem;
DataStore is on exactly one Primary-HostSystem;
DataStore is on exactly one Secondary-HostSystem;

Monitor is identified by Monitor_Id where
	Monitor has exactly one Monitor_Id,
	Monitor_Id is of at most one Monitor;
Monitor Monitors exactly one DataStore;
Monitor Is Disabled;

MonitoringApplication is identified by MonitoringApplication_Name where
	MonitoringApplication has exactly one MonitoringApplication_Name,
	MonitoringApplication_Name is of at most one MonitoringApplication;
Monitor is owned by exactly one MonitoringApplication;

Network is identified by Network_Nr where
	Network has exactly one Network_Nr,
	Network_Nr is of at most one Network;
Company has at least one Origin-Network;
DataStore has TcpProxy-Network,
	TcpProxy-Network is in at most one DataStore;
HostSystem uses at least one Network,
	Network is used by at most one HostSystem;
Network uses at most one Domain-Name;
Network has at most one Ending-IP;
Network has exactly one Initial-IP;
Network uses at most one Netmask;
Network Is IP_Range;
Network Is IP_Single;
Network Is IP_Subnet;

NotificationLevel is identified by NotificationLevel_Nr where
	NotificationLevel has exactly one NotificationLevel_Nr,
	NotificationLevel_Nr is of at most one NotificationLevel;
NotificationLevel has exactly one InitialDelay-Duration;
NotificationLevel has exactly one Repeat-Duration;

NotificationType is identified by NotificationType_Name where
	NotificationType has exactly one NotificationType_Name,
	NotificationType_Name is of at most one NotificationType;
MonitorNotificationType is where
	Monitor has at least one NotificationType;
MonitorNotificationType Is Excluded;

ProviderType is identified by ProviderType_Id where
	ProviderType has exactly one ProviderType_Id,
	ProviderType_Id is of at most one ProviderType;

RecurringSchedule is identified by RecurringSchedule_Id where
	RecurringSchedule has exactly one RecurringSchedule_Id,
	RecurringSchedule_Id is of at most one RecurringSchedule;
Monitor has AllExclusion-RecurringSchedule,
	RecurringSchedule applies to at most one Monitor;
Monitor has IntegrationExclusion-RecurringSchedule,
	RecurringSchedule applies to at most one Monitor;
RecurringSchedule has exactly one Duration;
RecurringSchedule Friday;
RecurringSchedule Monday;
RecurringSchedule Saturday;
RecurringSchedule Sunday;
RecurringSchedule Thursday;
RecurringSchedule Tuesday;
RecurringSchedule Wednesday;

SatalliteMessage is identified by SatalliteMessage_Id where
	SatalliteMessage has exactly one SatalliteMessage_Id,
	SatalliteMessage_Id is of at most one SatalliteMessage;
SatalliteMessage Is Designated for exactly one DataStore;
SatalliteMessage exactly one Insertion-DateTime;
SatalliteMessage has at most one MessageData;
SatalliteMessage has at most one MessageHeader;
SatalliteMessage is of at most one ProviderType;
SatalliteMessage has exactly one SerialNumber;

Subscription is identified by Subscription_Nr where
	Subscription has exactly one Subscription_Nr,
	Subscription_Nr is of at most one Subscription;
Company (as DriverTechSubscription) has exactly one DriverTech-Subscription;
Subscription has Beginning exactly one Date;
Subscription has Ending at most one Date;
Subscription Is Enabled;

Switch is identified by Switch_Id where
	Switch has exactly one Switch_Id,
	Switch_Id is of at most one Switch;
DataStore has at most one Legacy-Switch;
Switch is exactly one Major-Version;
Switch is exactly one Minor-Version;
Switch has exactly one Monitoring-Port;
Switch has exactly one Operating-Port;
Switch is on Private-Network,
	Network connects to at most one Switch;
Switch is on at least one Public-Network,
	Network connects to at most one Switch;
Switch is exactly one Revision-Version;
Switch Is Backup Messages;
Switch Is Backup Updates;
Switch Is Send Disabled;
Switch Is Test Vectors Enabled;
HostSystemRunsSwitch is where
	HostSystem Runs Switch;

Time is identified by HHMMSS where
	Time has exactly one HHMMSS,
	HHMMSS is of at most one Time;
RecurringSchedule has exactly one Start-Time;

Transaction is identified by Transaction_Nr where
	Transaction has exactly one Transaction_Nr,
	Transaction_Nr is of at most one Transaction;
SatalliteMessage has at most one Group-Transaction;

User is identified by User_Name where
	User has exactly one User_Name,
	User_Name is of at most one User;
User has exactly one Primary-EmailAddress;
User has at most one Secondary-EmailAddress;
User is monitor notification disabled;
MonitorNotificationUser is where
	MonitorNotificationType has Notification-User;
MonitorNotificationUser has exactly one NotificationLevel;

Vendor is a kind of Company;
Vendor requires at least one Credential;

Client is a kind of Company;
Client has at most one default-DataStore;
DataStore belongs to exactly one Client,
	Client uses DataStore;

FileHostSystem is a kind of HostSystem;
FileHostSystem has exactly one Port;
DataStoreFileHostSystem is where
	DataStore has at most one FileHostSystem;
DataStoreFileHostSystem has exactly one Internal-Credential;

Service is identified by Vendor and ServiceType where
	Vendor provides Service,
	Service is of exactly one ServiceType;
DataStoreService is where
	DataStore has Service;
DataStoreService belongs to exactly one Client;
DataStoreService requires at least one Credential;
DataStoreService (as DataStoreServiceSubscription) has exactly one Subscription;

/*
 * Constraints:
for each Company exactly one of these holds:
	Company Is Client,
	Company Is Vendor;
for each Credential exactly one of these holds:
	DataStore requires Credential,
	DataStoreService requires Credential,
	Vendor requires Credential,
	DataStoreFileHostSystem has Internal-Credential,
	DataStore has Internal-Credential;
Network Is IP_Subnet
	if and only if
	Network uses Netmask;
Network has Ending-IP
	if and only if
	Network Is IP_Range;
for each Network at most one of these holds:
	Network Is IP_Single,
	Network has Ending-IP;
for each Network exactly one of these holds:
	HostSystem uses Network,
	Company has Origin-Network,
	DataStore has TcpProxy-Network;
for each Network exactly one of these holds:
	Network Is IP_Single,
	Network Is IP_Subnet,
	Network Is IP_Range;
Switch is on Private-Network
	if and only if
	DataStore has Legacy-Switch;
for each Switch exactly one of these holds:
	HostSystem Runs Switch,
	DataStore has Legacy-Switch;
Client has default-DataStore
	only if DataStore belongs to Client;
Network uses Domain-Name
	only if Network Is IP_Single;
DataStore has TcpProxy-Network
	only if Network Is IP_Single;
 */
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
	RecurringSchedule Monday,
	RecurringSchedule Tuesday,
	RecurringSchedule Wednesday,
	RecurringSchedule Thursday,
	RecurringSchedule Friday,
	RecurringSchedule Saturday,
	RecurringSchedule Sunday;
each Service occurs exactly one time in
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
