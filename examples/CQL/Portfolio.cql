vocabulary Portfolio;

/*
 * Value Types
 */
Amount is written as Decimal(12,4);
AttachmentId is written as AutoCounter;
BorrowerName is written as VariableLengthText;
City is written as VariableLengthText(60);
Code is written as VariableLengthText(16);
CurrencyName is written as VariableLengthText;
Date is written as DateAndTime;
DepreciationScheduleId is written as AutoCounter;
Description is written as VariableLengthText;
DisplayName is written as VariableLengthText;
DisposalId is written as AutoCounter;
EntityId is written as AutoCounter;
ExchangeCode is written as FixedLengthText;
ExpenditureId is written as AutoCounter;
Filename is written as VariableLengthText;
ItemType is written as VariableLengthText;
Note is written as VariableLengthText;
Number is written as SignedInteger(32);
OwnedItemId is written as AutoCounter;
Percent is written as Decimal(6,4);
PostCode is written as UnsignedInteger(32);
Quantity is written as Decimal;
RevenueId is written as AutoCounter;
StreetLine is written as VariableLengthText;
StreetNumber is written as VariableLengthText;
TenantName is written as VariableLengthText;
TransactionId is written as AutoCounter;
Type is written as VariableLengthText restricted to {'Image', 'Note', 'URL', 'Video'};
ValuationId is written as AutoCounter;
YearNr is written as SignedInteger(32);

/*
 * Entity Types
 */
Attachment is identified by its Id;
Attachment is stored in at most one Filename;
Attachment is of at most one Type;

Borrower is identified by its Name;

Currency is identified by its Name;

DepreciationSchedule is identified by its Id;
DepreciationSchedule has Attachment;

Entity is identified by its Id;

Exchange is identified by its Code;

OwnedItem is identified by its Id;
Amount is of OwnedItem,
	OwnedItem was purchased at one perunit-Amount;
Entity (as Owner) owns OwnedItem,
	OwnedItem is owned by one Owner;
OwnedItem has Attachment;
OwnedItem was purchased using at most one Currency;
OwnedItem depreciates according to at most one DepreciationSchedule;
OwnedItem is called one DisplayName,
	DisplayName is of OwnedItem;
OwnedItem is of one ItemType,
	ItemType is of OwnedItem;
OwnedItem is in one Quantity,
	Quantity applies to OwnedItem;
OwnedItem was acquired on one acquisition-Date,
	Date is when OwnedItem was acquired;
OwnedItem costs estimated at most one monthlycost-Amount,
	monthlycost-Amount is estimated for OwnedItem;
OwnedItem returns estimated at most one monthlyreturn-Amount,
	monthlyreturn-Amount is estimated for OwnedItem;
OwnedItem is at most one owned-Percent,
	owned-Percent applies to OwnedItem;

Security is identified by Exchange and Code where
	Security is traded on one Exchange,
	Security has one Code;

Share is a kind of OwnedItem;
Share is in one Security;

Street is identified by first-StreetLine and second-StreetLine and third-StreetLine where
	Street has one first-StreetLine,
	Street has at most one second-StreetLine,
	Street has at most one third-StreetLine;

Tenant is identified by its Name;

Transaction is identified by its Id;
Note is on Transaction,
	Transaction has at most one Note;
Transaction has one taxable-Date;

Valuation is identified by its Id where
	OwnedItem was valued at Amount;
Valuation has Attachment;
Valuation has at most one Description;
Valuation is in at most one alternate-Currency;
Valuation applied at at most one valuation-Date;

Year is identified by its Nr;

Address is identified by StreetNumber and Street and City and PostCode where
	Address is at at most one StreetNumber,
	Address is in one Street,
	Address is in at most one City,
	Address is in at most one PostCode;

AnnualDepreciation is where
	DepreciationSchedule is at Percent in Year;

Disposal is a kind of Transaction identified by its Id [partitioned];
Disposal has Attachment;
Disposal was of one Number units;
Disposal is for one unit-Amount,
	Amount is of Disposal;
OwnedItem was subject to Disposal;

Expenditure is a kind of Transaction identified by its Id [partitioned];
Expenditure is of at most one Amount;
Expenditure has Attachment;
OwnedItem incurred Expenditure;

Liability is a kind of OwnedItem;
Liability is due on at most one Date;
Liability incurs interest at at most one Percent;

LocatedItem is a kind of OwnedItem;
LocatedItem is at at most one Address;

MiscAsset is a kind of OwnedItem;

Person is a kind of LocatedItem;

RealProperty is a kind of LocatedItem;
RealProperty is occupied by at most one Tenant;
RealProperty attracts weekly at most one rental-Amount (as weekly_rental);

Revenue is a kind of Transaction identified by its Id [partitioned];
OwnedItem earned Revenue;
Revenue is of at most one Amount;
Revenue has Attachment;

Collateral is where
	OwnedItem is security for Liability,
	Liability is secured by OwnedItem;

Lending is a kind of LocatedItem;
Lending is to one Borrower;
Lending has probability of at most one default-Percent;
Lending incurs at most one interest-Percent;
Lending is due on one repayment-Date;

/*
 * Constraints:
 */
for each Attachment exactly one of these holds:
	OwnedItem has Attachment,
	Valuation has Attachment,
	Disposal has Attachment,
	Revenue has Attachment,
	Expenditure has Attachment,
	DepreciationSchedule has Attachment;
for each LocatedItem exactly one of these holds:
	RealProperty is a subtype of LocatedItem,
	Person is a subtype of LocatedItem,
	Lending is a subtype of LocatedItem;
for each Transaction exactly one of these holds:
	Revenue is a subtype of Transaction,
	Expenditure is a subtype of Transaction,
	Disposal is a subtype of Transaction;
each Attachment occurs at most one time in
	OwnedItem has Attachment;
each Attachment occurs at most one time in
	Revenue has Attachment;
each Attachment occurs at most one time in
	Disposal has Attachment;
each Attachment occurs at most one time in
	Valuation has Attachment;
each Attachment occurs at most one time in
	Expenditure has Attachment;
each Attachment occurs at most one time in
	DepreciationSchedule has Attachment;
each DepreciationSchedule occurs at least one time in
	DepreciationSchedule is at Percent in Year;
each combination DepreciationSchedule, Year occurs at most one time in
	DepreciationSchedule is at Percent in Year;
each Disposal occurs one time in
	OwnedItem was subject to Disposal;
each Expenditure occurs one time in
	OwnedItem incurred Expenditure;
each Revenue occurs one time in
	OwnedItem earned Revenue;
each Year occurs at least one time in
	DepreciationSchedule is at Percent in Year;
