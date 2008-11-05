CREATE TABLE Person (
	EmployeeIsManager	bit NULL,
	ManagerIsCeo	bit NULL,
	EmployeeManagerName	varchar NULL,
	PersonName	varchar NOT NULL,
	UNIQUE(PersonName)
)
GO

