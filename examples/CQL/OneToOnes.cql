vocabulary OneToOnes;

/*
 * Value Types
 */
BoyID is written as AutoCounter;
GirlID is written as AutoCounter;

/*
 * Entity Types
 */
Boy is identified by its ID;

Girl is identified by its ID;
Girl is going out with at most one Boy,
	Boy is going out with at most one Girl;

