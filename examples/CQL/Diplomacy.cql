vocabulary Diplomacy;

/*
 * Value Types
 */
CountryName is written as String;
DiplomatName is written as String;
LanguageName is written as String;

/*
 * Entity Types
 */
Country is identified by its Name;

Diplomat is identified by its Name;
Diplomat represents one Country;
Diplomat serves in one Country;

Language is identified by its Name;

LanguageUse is where
	Language is spoken in Country,
	Country uses at least one Language;

Ambassador is a kind of Diplomat;

Fluency is where
	Diplomat speaks at least one Language,
	Language is spoken by Diplomat;

Representation is where
	Ambassador is from Country(1) to Country(2),
	Country(1) is represented in Country(2) by one Ambassador;

/*
 * Constraints:
 */
for each Diplomat, Country at most one of these holds:
	Diplomat serves in Country,
	Diplomat represents Country;
Ambassador is from Country(1) to Country(2)
	only if Ambassador is a Diplomat that represents Country(1);
Ambassador is from Country(1) to Country(2)
	only if Diplomat serves in Country(2);
Diplomat serves in Country
	only if Diplomat speaks Language that is spoken in Country;
