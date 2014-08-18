CREATE TABLE AllocatableCinemaSection (
	-- AllocatableCinemaSection is where Cinema provides allocated seating in Section and Cinema has Cinema ID,
	CinemaID                                int NOT NULL,
	-- AllocatableCinemaSection is where Cinema provides allocated seating in Section and Section has Section Name,
	SectionName                             varchar NOT NULL,
	PRIMARY KEY(CinemaID, SectionName)
)
GO

CREATE TABLE Booking (
	-- maybe tickets for Booking are being mailed to Address and Address has Address Text,
	AddressText                             text NULL,
	-- Booking has Booking Nr,
	BookingNr                               int NOT NULL,
	-- maybe Booking has Collection Code,
	CollectionCode                          int NULL,
	-- Booking is where Person booked Session for Number of places,
	Number                                  smallint NOT NULL CHECK(Number >= 1),
	-- Booking is where Person booked Session for Number of places and Person has Person ID,
	PersonID                                int NOT NULL,
	-- maybe Booking is for seats in Section and Section has Section Name,
	SectionName                             varchar NULL,
	-- Booking is where Person booked Session for Number of places and Session is where Cinema shows Film on Session Time and Cinema has Cinema ID,
	SessionCinemaID                         int NOT NULL,
	-- Booking is where Person booked Session for Number of places and Session is where Cinema shows Film on Session Time and Session Time is on Day,
	SessionTimeDay                          int NOT NULL,
	-- Booking is where Person booked Session for Number of places and Session is where Cinema shows Film on Session Time and Session Time is at Hour,
	SessionTimeHour                         int NOT NULL,
	-- Booking is where Person booked Session for Number of places and Session is where Cinema shows Film on Session Time and Session Time is at Minute,
	SessionTimeMinute                       int NOT NULL,
	-- Booking is where Person booked Session for Number of places and Session is where Cinema shows Film on Session Time and Session Time is in Month and Month has Month Nr,
	SessionTimeMonthNr                      int NOT NULL,
	-- Booking is where Person booked Session for Number of places and Session is where Cinema shows Film on Session Time and Session Time is in Year and Year has Year Nr,
	SessionTimeYearNr                       int NOT NULL,
	-- tickets for Booking have been issued,
	TicketsForHaveBeenIssued                bit NULL,
	PRIMARY KEY(BookingNr),
	UNIQUE(PersonID, SessionCinemaID, SessionTimeYearNr, SessionTimeMonthNr, SessionTimeDay, SessionTimeHour, SessionTimeMinute)
)
GO

CREATE TABLE Cinema (
	-- Cinema has Cinema ID,
	CinemaID                                int IDENTITY NOT NULL,
	-- Cinema has Name,
	Name                                    varchar NOT NULL,
	PRIMARY KEY(CinemaID),
	UNIQUE(Name)
)
GO

CREATE TABLE Film (
	-- Film has Film ID,
	FilmID                                  int IDENTITY NOT NULL,
	-- Film has Name,
	Name                                    varchar NOT NULL,
	-- maybe Film was made in Year and Year has Year Nr,
	YearNr                                  int NULL CHECK((YearNr >= 1900 AND YearNr <= 9999)),
	PRIMARY KEY(FilmID)
)
GO

CREATE VIEW dbo.Film_NameYearNr (Name, YearNr) WITH SCHEMABINDING AS
	SELECT Name, YearNr FROM dbo.Film
	WHERE	YearNr IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_FilmByNameYearNr ON dbo.Film_NameYearNr(Name, YearNr)
GO

CREATE TABLE Person (
	-- maybe Person has Encrypted Password,
	EncryptedPassword                       varchar NULL,
	-- maybe Person has login-Name,
	LoginName                               varchar NULL,
	-- Person has Person ID,
	PersonID                                int IDENTITY NOT NULL,
	PRIMARY KEY(PersonID)
)
GO

CREATE VIEW dbo.Person_LoginName (LoginName) WITH SCHEMABINDING AS
	SELECT LoginName FROM dbo.Person
	WHERE	LoginName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_PersonByLoginName ON dbo.Person_LoginName(LoginName)
GO

CREATE TABLE PlacesPaid (
	-- Places Paid is where Number of places for Booking have been paid for by Payment Method and Booking has Booking Nr,
	BookingNr                               int NOT NULL,
	-- Places Paid is where Number of places for Booking have been paid for by Payment Method,
	Number                                  smallint NOT NULL CHECK(Number >= 1),
	-- Places Paid is where Number of places for Booking have been paid for by Payment Method and Payment Method has Payment Method Code,
	PaymentMethodCode                       varchar NOT NULL CHECK(PaymentMethodCode = 'Card' OR PaymentMethodCode = 'Cash' OR PaymentMethodCode = 'Gift Voucher' OR PaymentMethodCode = 'Loyalty Voucher'),
	PRIMARY KEY(BookingNr, PaymentMethodCode),
	FOREIGN KEY (BookingNr) REFERENCES Booking (BookingNr)
)
GO

CREATE TABLE Seat (
	-- Seat is in Row and Row is in Cinema and Cinema has Cinema ID,
	RowCinemaID                             int NOT NULL,
	-- Seat is in Row and Row has Row Nr,
	RowNr                                   char(2) NOT NULL,
	-- Seat has Seat Number,
	SeatNumber                              smallint NOT NULL,
	-- maybe Seat is in Section and Section has Section Name,
	SectionName                             varchar NULL,
	PRIMARY KEY(RowCinemaID, RowNr, SeatNumber),
	FOREIGN KEY (RowCinemaID) REFERENCES Cinema (CinemaID)
)
GO

CREATE TABLE SeatAllocation (
	-- Seat Allocation is where Booking has allocated-Seat and Seat has Seat Number,
	AllocatedSeatNumber                     smallint NOT NULL,
	-- Seat Allocation is where Booking has allocated-Seat and Seat is in Row and Row is in Cinema and Cinema has Cinema ID,
	AllocatedSeatRowCinemaID                int NOT NULL,
	-- Seat Allocation is where Booking has allocated-Seat and Seat is in Row and Row has Row Nr,
	AllocatedSeatRowNr                      char(2) NOT NULL,
	-- Seat Allocation is where Booking has allocated-Seat and Booking has Booking Nr,
	BookingNr                               int NOT NULL,
	PRIMARY KEY(BookingNr, AllocatedSeatRowCinemaID, AllocatedSeatRowNr, AllocatedSeatNumber),
	FOREIGN KEY (BookingNr) REFERENCES Booking (BookingNr),
	FOREIGN KEY (AllocatedSeatRowCinemaID, AllocatedSeatRowNr, AllocatedSeatNumber) REFERENCES Seat (RowCinemaID, RowNr, SeatNumber)
)
GO

CREATE TABLE Session (
	-- Session is where Cinema shows Film on Session Time and Cinema has Cinema ID,
	CinemaID                                int NOT NULL,
	-- Session is where Cinema shows Film on Session Time and Film has Film ID,
	FilmID                                  int NOT NULL,
	-- Session is high-demand,
	IsHighDemand                            bit NULL,
	-- Session is where Cinema shows Film on Session Time and Session Time is on Day,
	SessionTimeDay                          int NOT NULL CHECK((SessionTimeDay >= 1 AND SessionTimeDay <= 31)),
	-- Session is where Cinema shows Film on Session Time and Session Time is at Hour,
	SessionTimeHour                         int NOT NULL CHECK((SessionTimeHour >= 0 AND SessionTimeHour <= 23)),
	-- Session is where Cinema shows Film on Session Time and Session Time is at Minute,
	SessionTimeMinute                       int NOT NULL CHECK((SessionTimeMinute >= 0 AND SessionTimeMinute <= 59)),
	-- Session is where Cinema shows Film on Session Time and Session Time is in Month and Month has Month Nr,
	SessionTimeMonthNr                      int NOT NULL CHECK((SessionTimeMonthNr >= 1 AND SessionTimeMonthNr <= 12)),
	-- Session is where Cinema shows Film on Session Time and Session Time is in Year and Year has Year Nr,
	SessionTimeYearNr                       int NOT NULL CHECK((SessionTimeYearNr >= 1900 AND SessionTimeYearNr <= 9999)),
	-- Session uses allocated seating,
	UsesAllocatedSeating                    bit NULL,
	PRIMARY KEY(CinemaID, SessionTimeYearNr, SessionTimeMonthNr, SessionTimeDay, SessionTimeHour, SessionTimeMinute),
	FOREIGN KEY (CinemaID) REFERENCES Cinema (CinemaID),
	FOREIGN KEY (FilmID) REFERENCES Film (FilmID)
)
GO

CREATE TABLE TicketPricing (
	-- Ticket Pricing is where tickets on Session Time at Cinema in Section for High Demand have Price and Cinema has Cinema ID,
	CinemaID                                int NOT NULL,
	-- Ticket Pricing is where tickets on Session Time at Cinema in Section for High Demand have Price,
	HighDemand                              Boolean NOT NULL,
	-- Ticket Pricing is where tickets on Session Time at Cinema in Section for High Demand have Price,
	Price                                   decimal NOT NULL,
	-- Ticket Pricing is where tickets on Session Time at Cinema in Section for High Demand have Price and Section has Section Name,
	SectionName                             varchar NOT NULL,
	-- Ticket Pricing is where tickets on Session Time at Cinema in Section for High Demand have Price and Session Time is on Day,
	SessionTimeDay                          int NOT NULL CHECK((SessionTimeDay >= 1 AND SessionTimeDay <= 31)),
	-- Ticket Pricing is where tickets on Session Time at Cinema in Section for High Demand have Price and Session Time is at Hour,
	SessionTimeHour                         int NOT NULL CHECK((SessionTimeHour >= 0 AND SessionTimeHour <= 23)),
	-- Ticket Pricing is where tickets on Session Time at Cinema in Section for High Demand have Price and Session Time is at Minute,
	SessionTimeMinute                       int NOT NULL CHECK((SessionTimeMinute >= 0 AND SessionTimeMinute <= 59)),
	-- Ticket Pricing is where tickets on Session Time at Cinema in Section for High Demand have Price and Session Time is in Month and Month has Month Nr,
	SessionTimeMonthNr                      int NOT NULL CHECK((SessionTimeMonthNr >= 1 AND SessionTimeMonthNr <= 12)),
	-- Ticket Pricing is where tickets on Session Time at Cinema in Section for High Demand have Price and Session Time is in Year and Year has Year Nr,
	SessionTimeYearNr                       int NOT NULL CHECK((SessionTimeYearNr >= 1900 AND SessionTimeYearNr <= 9999)),
	PRIMARY KEY(SessionTimeYearNr, SessionTimeMonthNr, SessionTimeDay, SessionTimeHour, SessionTimeMinute, CinemaID, SectionName, HighDemand),
	FOREIGN KEY (CinemaID) REFERENCES Cinema (CinemaID)
)
GO

ALTER TABLE AllocatableCinemaSection
	ADD FOREIGN KEY (CinemaID) REFERENCES Cinema (CinemaID)
GO

ALTER TABLE Booking
	ADD FOREIGN KEY (PersonID) REFERENCES Person (PersonID)
GO

ALTER TABLE Booking
	ADD FOREIGN KEY (SessionCinemaID, SessionTimeYearNr, SessionTimeMonthNr, SessionTimeDay, SessionTimeHour, SessionTimeMinute) REFERENCES Session (CinemaID, SessionTimeYearNr, SessionTimeMonthNr, SessionTimeDay, SessionTimeHour, SessionTimeMinute)
GO

