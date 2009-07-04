vocabulary NonRoleId;

/*
 * Value Types
 */
ComparisonId is written as AutoCounter;
Ordinal is written as AutoCounter;

/*
 * Entity Types
 */
Comparison is identified by its Id where
	Ordinal comes before larger-Ordinal;

