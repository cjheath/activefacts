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
Diplomat is from at most one Country;
Diplomat serves in at most one Country;

Language is identified by its Name;

LanguageUse is where
	Language is spoken in Country,
	Country uses at least one Language;

Ambassador is a kind of Diplomat;
Ambassador is to at most one Country,
	Country receives at most one Ambassador;

Fluency is where
	Diplomat speaks at least one Language,
	Language is spoken by Diplomat;

/*
 * Constraints:
 */
for each Diplomat and Country at most one of these holds:
	Diplomat serves in Country,
	Diplomat is from Country;
Ambassador is to Country
	only if Ambassador is a Diplomat that serves in Country;
Diplomat serves in Country
	only if Diplomat speaks Language that is spoken in Country;
