vocabulary ServiceDirector;

/*
 * Value Types
 */
Company Code is written as Char(5);
Credential Nr is written as Signed Integer(32);
Data Store Name is written as String(15);
Date is written as String;
Date Time is written as String;
Email Address is written as String(50);
Host System Name is written as String(15);
IP is written as String(16);
Message Data is written as Blob(8000);
Message Header is written as String(30);
Monitor Id is written as Auto Counter;
Monitoring Application Name is written as String(10);
Name is written as String(15);
Netmask is written as String(16);
Network Nr is written as Signed Integer(32);
Notification Level Nr is written as Signed Integer(32);
Notification Type Name is written as String(20);
Password is written as String;
Path is written as String(20);
Port is written as Signed Integer(32);
Provider Type Id is written as Signed Integer(20);
Recurring Schedule Id is written as Auto Counter;
Satellite Message Id is written as Unsigned Integer(32);
Seconds is written as Unsigned Integer(32);
Serial Number is written as String(20);
Service Type [independent] is written as String(15);
Subscription Nr is written as Signed Integer(32);
Switch Id is written as Auto Counter;
Time is written as String;
Transaction Nr is written as Unsigned Integer(32);
Truck PCID is written as Unsigned Integer(32);
User Name is written as String(20);
Version is written as Char(5);

/*
 * Entity Types
 */
Company is identified by its Code;
Company has one Operating-Name;
Company is client;
Company is vendor;

Credential is identified by its Nr;
Credential has at most one Expiration-Date;
Credential has one Password;
Credential has one User Name;

Data Store is identified by its Name;
Data Store requires at least one Credential;
Data Store has one Friendly-Name;
Data Store has at most one HeartBeat-Truck PCID;
Data Store has one Internal-Credential;
Data Store is one Major-Version;
Data Store is one Minor-Version;
Data Store is one Revision-Version;

Duration is identified by Seconds where
	Duration has one Seconds,
	Seconds is of at most one Duration;

Geocode File is identified by Path where
	Geocode File has one Path,
	Path is of at most one Geocode File;
Data Store uses at most one Geocode File;

Host System is identified by its Name;
Data Store is on one Primary-Host System;
Data Store is on one Secondary-Host System;

Monitor is identified by its Id;
Monitor monitors one Data Store;
Monitor is disabled;

Monitoring Application is independent identified by its Name;
Monitor is owned by one Monitoring Application;

Network is identified by its Nr;
Company has at least one Origin-Network;
Data Store has TcpProxy-Network,
	TcpProxy-Network is in at most one Data Store;
Host System uses at least one Network,
	Network is used by at most one Host System;
Network uses at most one Domain-Name;
Network has at most one Ending-IP;
Network has one Initial-IP;
Network uses at most one Netmask;
Network is ip_range;
Network is ip_single;
Network is ip_subnet;

Notification Level is identified by its Nr;
Notification Level has one InitialDelay-Duration;
Notification Level has one Repeat-Duration;

Notification Type is independent identified by its Name;

Provider Type is identified by its Id;

Recurring Schedule is identified by its Id;
Monitor has AllExclusion-Recurring Schedule,
	AllExclusion-Recurring Schedule applies to at most one Monitor;
Monitor (as IntegratingMonitor) has IntegrationExclusion-Recurring Schedule;  // Avoid ambiguity; this is a new fact type
Monitor (as IntegratingMonitor) has IntegrationExclusion-Recurring Schedule,
	IntegrationExclusion-Recurring Schedule applies to at most one IntegratingMonitor;
Recurring Schedule has one Duration;
Recurring Schedule has one Start-Time;
Recurring Schedule friday;
Recurring Schedule monday;
Recurring Schedule saturday;
Recurring Schedule sunday;
Recurring Schedule thursday;
Recurring Schedule tuesday;
Recurring Schedule wednesday;

Satellite Message is identified by its Id;
Satellite Message is designated for one Data Store;
Satellite Message has at most one Message Data;
Satellite Message has at most one Message Header;
Satellite Message is of at most one Provider Type;
Satellite Message has one Serial Number;
Satellite Message has one insertion-Date Time;

Subscription is identified by its Nr;
Company has one DriverTech-Subscription;
Subscription has one Beginning-Date;
Subscription has at most one Ending-Date;
Subscription is enabled;

Switch is identified by its Id;
Data Store has at most one Legacy-Switch;
Switch is one Major-Version;
Switch is one Minor-Version;
Switch has one Operating-Port;
Switch is one Revision-Version;
Switch has one monitoring-Port;
Switch (as Private Interface Switch) is on private-Network,
	private-Network connects to at most one Private Interface Switch;
Switch (as Public Interface Switch) is on public-Network;  // Avoid ambiguity; this is a new fact type
Switch (as Public Interface Switch) is on at least one public-Network,
	Network connects to at most one Public Interface Switch;
Switch is backup messages;
Switch is backup updates;
Switch is send disabled;
Switch is test vectors enabled;

Transaction is identified by its Nr;
Satellite Message has at most one Group-Transaction;

User is identified by its Name;
User has one Primary-Email Address;
User has at most one Secondary-Email Address;
User is monitor notification disabled;

Vendor is a kind of Company [separate];
Vendor requires at least one Credential;

Client is a kind of Company [separate];
Client has at most one default-Data Store;
Data Store belongs to one Client,
	Client uses Data Store;

File Host System is a kind of Host System;
File Host System has one Port;

Host System Runs Switch is where
	Host System runs Switch;

Monitor Notification Type is where
	Monitor has at least one Notification Type;
Monitor Notification Type is excluded;

Monitor Notification User is where
	Monitor Notification Type has notification-User;
Monitor Notification User has one Notification Level;

Service is identified by Vendor and Service Type where
	Vendor provides Service,
	Service is of one Service Type;

Data Store File Host System is where
	Data Store has one File Host System;
Data Store File Host System has one Internal-Credential;

Data Store Service is where
	Service is from at least one Data Store,
	Data Store has Service;
Data Store Service belongs to one Client;
Data Store Service requires at least one Credential;
Data Store Service has one Subscription;

/*
 * Constraints:
 */
either Company is client or Company is vendor but not both;
for each Credential exactly one of these holds:
	Data Store (2) requires Credential,
	Data Store Service requires Credential,
	Vendor requires Credential,
	Data Store File Host System has Internal-Credential,
	Data Store (1) has Internal-Credential;
for each Network exactly one of these holds:
	Network is used by Host System,
	Company has Origin-Network,
	TcpProxy-Network is in Data Store;
for each Network exactly one of these holds:
	Network is ip_single,
	Network is ip_subnet,
	Network is ip_range;
either Host System runs Switch or Data Store has Legacy-Switch but not both;
for each Network at most one of these holds:
	Network is ip_single,
	Network has Ending-IP;
Data Store Service (in which Service is from Data Store) belongs to Client
	if and only if
	Client has default Data Store;
Network has Ending IP
	if and only if
	Network is ip_range;
Network is ip_subnet
	if and only if
	Network uses Netmask;
Switch is on private Network
	if and only if
	Data Store has Legacy Switch;
Client has default Data Store
	only if Client uses Data Store;
TcpProxy Network is in Data Store
	only if Network is ip_single;
Network uses Domain Name
	only if Network is ip_single;
each Credential occurs at most one time in
	Data Store File Host System has Internal Credential;
each Credential occurs at most one time in
	Data Store Service requires Credential;
each Credential occurs at most one time in
	Data Store has Internal Credential;
each Credential occurs at most one time in
	Data Store requires Credential;
each Credential occurs at most one time in
	Vendor requires Credential;
each IP occurs at most one time in
	Network has Ending IP;
each IP occurs at most one time in
	Network has Initial IP;
each Name occurs at most one time in
	Data Store has Friendly Name;
each Network occurs at most one time in
	Company has Origin Network;
each Port occurs at most one time in
	Switch has monitoring Port;
each Recurring Schedule occurs at least one time in
	Recurring Schedule monday,
	Recurring Schedule tuesday,
	Recurring Schedule wednesday,
	Recurring Schedule thursday,
	Recurring Schedule friday,
	Recurring Schedule saturday,
	Recurring Schedule sunday;
each Service occurs one time in
	Vendor provides Service;
each Subscription occurs at most one time in
	Company has DriverTech Subscription;
each Subscription occurs at most one time in
	Data Store Service has Subscription;
each Switch occurs at most one time in
	Data Store has Legacy Switch;
each combination User Name, Vendor, Data Store Service, Data Store occurs at most one time in
	Credential has User Name,
	Vendor requires Credential,
	Data Store Service requires Credential,
	Data Store requires Credential;
