CREATE TABLE Company (
	-- Company is run by CEO and CEO is a kind of Manager and Manager is a kind of Employee and Employee works for Company and Company has CompanyName,
	CEOCompanyName                          varchar NOT NULL,
	-- Company is run by CEO and CEO is a kind of Manager and Manager is a kind of Employee and Employee has EmployeeNr,
	CEOEmployeeNr                           int NOT NULL,
	-- Company has CompanyName,
	CompanyName                             varchar NOT NULL,
	PRIMARY KEY(CompanyName)
)
GO

CREATE TABLE Employee (
	-- Employee works for Company and Company has CompanyName,
	CompanyName                             varchar NOT NULL,
	-- Employee has EmployeeNr,
	EmployeeNr                              int NOT NULL,
	-- maybe Employee reports to Manager and Manager is a kind of Employee and Employee works for Company and Company has CompanyName,
	ManagerCompanyName                      varchar NULL,
	-- maybe Employee reports to Manager and Manager is a kind of Employee and Employee has EmployeeNr,
	ManagerEmployeeNr                       int NULL,
	PRIMARY KEY(CompanyName, EmployeeNr),
	FOREIGN KEY (CompanyName) REFERENCES Company (CompanyName),
	FOREIGN KEY (ManagerCompanyName, ManagerEmployeeNr) REFERENCES Employee (CompanyName, EmployeeNr)
)
GO

ALTER TABLE Company
	ADD FOREIGN KEY (CEOCompanyName, CEOEmployeeNr) REFERENCES Employee (CompanyName, EmployeeNr)
GO

