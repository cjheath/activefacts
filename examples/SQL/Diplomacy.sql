CREATE TABLE Country (
	-- Country has CountryName,
	CountryName                             varchar NOT NULL,
	PRIMARY KEY(CountryName)
)
GO

CREATE TABLE Diplomat (
	-- Diplomat has DiplomatName,
	DiplomatName                            varchar NOT NULL,
	-- Diplomat represents Country and Country has CountryName,
	RepresentedCountryName                  varchar NOT NULL,
	-- Diplomat serves in Country and Country has CountryName,
	ServedCountryName                       varchar NOT NULL,
	PRIMARY KEY(DiplomatName),
	FOREIGN KEY (RepresentedCountryName) REFERENCES Country (CountryName),
	FOREIGN KEY (ServedCountryName) REFERENCES Country (CountryName)
)
GO

CREATE TABLE Fluency (
	-- Fluency involves Diplomat and Diplomat has DiplomatName,
	DiplomatName                            varchar NOT NULL,
	-- Fluency involves Language and Language has LanguageName,
	LanguageName                            varchar NOT NULL,
	PRIMARY KEY(DiplomatName, LanguageName),
	FOREIGN KEY (DiplomatName) REFERENCES Diplomat (DiplomatName)
)
GO

CREATE TABLE Language (
	-- Language has LanguageName,
	LanguageName                            varchar NOT NULL,
	PRIMARY KEY(LanguageName)
)
GO

CREATE TABLE LanguageUse (
	-- LanguageUse involves Country and Country has CountryName,
	CountryName                             varchar NOT NULL,
	-- LanguageUse involves Language and Language has LanguageName,
	LanguageName                            varchar NOT NULL,
	PRIMARY KEY(LanguageName, CountryName),
	FOREIGN KEY (CountryName) REFERENCES Country (CountryName),
	FOREIGN KEY (LanguageName) REFERENCES Language (LanguageName)
)
GO

CREATE TABLE Representation (
	-- Representation involves Ambassador and Ambassador is a kind of Diplomat and Diplomat has DiplomatName,
	AmbassadorName                          varchar NOT NULL,
	-- Representation involves Country and Country has CountryName,
	CountryName                             varchar NOT NULL,
	-- Representation involves Country and Country has CountryName,
	RepresentedCountryName                  varchar NOT NULL,
	PRIMARY KEY(RepresentedCountryName, CountryName),
	FOREIGN KEY (CountryName) REFERENCES Country (CountryName),
	FOREIGN KEY (RepresentedCountryName) REFERENCES Country (CountryName),
	FOREIGN KEY (AmbassadorName) REFERENCES Diplomat (DiplomatName)
)
GO

ALTER TABLE Fluency
	ADD FOREIGN KEY (LanguageName) REFERENCES Language (LanguageName)
GO

