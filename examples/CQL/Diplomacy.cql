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
Diplomat represents one Country (as Represented Country);
Diplomat serves in one Country (as Served Country);

Language is identified by its Name;

LanguageUse is where
	Language is spoken in Country,
	Country uses at least one Language;

Ambassador is a kind of Diplomat;

Fluency is where
	Diplomat speaks at least one Language,
	Language is spoken by Diplomat;

Representation is where
	Ambassador is from Country (as Represented Country) to Country(2),
	Represented Country(1) is represented in Country(2) by one Ambassador;

/*
 * Constraints:
 */
for each Diplomat, Country at most one of these holds:
	Diplomat serves in Country,
	Diplomat represents Country;
Diplomat is an Ambassador that is from Country(1) to Country(2)
	only if Diplomat represents Country(1);
Diplomat is an Ambassador that is from Country(2) to Country(1)
	only if Diplomat serves in Country(1);
Diplomat serves in Country
	only if Diplomat speaks Language that is spoken in Country;
each Ambassador occurs at least one time in
	Ambassador is from Country to Country;
