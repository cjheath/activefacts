CREATE TABLE Diplomat (
	-- Diplomat has DiplomatName,
	DiplomatName                            varchar NOT NULL,
	-- Diplomat represents Country (as Represented Country) and Country has CountryName,
	RepresentedCountryName                  varchar NOT NULL,
	-- Diplomat serves in Country (as Served Country) and Country has CountryName,
	ServedCountryName                       varchar NOT NULL,
	PRIMARY KEY(DiplomatName)
)
GO

CREATE TABLE Fluency (
	-- Fluency is where Diplomat speaks Language and Diplomat has DiplomatName,
	DiplomatName                            varchar NOT NULL,
	-- Fluency is where Diplomat speaks Language and Language has LanguageName,
	LanguageName                            varchar NOT NULL,
	PRIMARY KEY(DiplomatName, LanguageName),
	FOREIGN KEY (DiplomatName) REFERENCES Diplomat (DiplomatName)
)
GO

CREATE TABLE LanguageUse (
	-- LanguageUse is where Language is spoken in Country and Country has CountryName,
	CountryName                             varchar NOT NULL,
	-- LanguageUse is where Language is spoken in Country and Language has LanguageName,
	LanguageName                            varchar NOT NULL,
	PRIMARY KEY(LanguageName, CountryName)
)
GO

CREATE TABLE Representation (
	-- Representation is where Ambassador is from Country (as Represented Country) to Country and Diplomat has DiplomatName,
	AmbassadorName                          varchar NOT NULL,
	-- Representation is where Ambassador is from Country (as Represented Country) to Country and Country has CountryName,
	CountryName                             varchar NOT NULL,
	-- Representation is where Ambassador is from Country (as Represented Country) to Country and Country has CountryName,
	RepresentedCountryName                  varchar NOT NULL,
	PRIMARY KEY(RepresentedCountryName, CountryName),
	FOREIGN KEY (AmbassadorName) REFERENCES Diplomat (DiplomatName)
)
GO

