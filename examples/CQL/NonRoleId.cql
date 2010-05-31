vocabulary NonRoleId;

/*
 * Value Types
 */
Comparison Id is written as Auto Counter;
Ordinal is written as Auto Counter;

/*
 * Entity Types
 */
Comparison is identified by its Id where
	Ordinal comes before larger-Ordinal;

