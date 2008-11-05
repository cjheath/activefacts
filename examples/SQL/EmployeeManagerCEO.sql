CREATE TABLE Person (
	PersonName	varchar NOT NULL,
	EmployeeIsManager	bit NULL,
	EmployeeManagerName	varchar NULL,
	ManagerIsCeo	bit NULL,
	UNIQUE(PersonName)
)
GO

