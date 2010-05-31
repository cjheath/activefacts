vocabulary OneToOnes;

/*
 * Value Types
 */
Boy ID is written as Auto Counter;
Girl ID is written as Auto Counter;

/*
 * Entity Types
 */
Boy is identified by its ID [independent];

Girl is identified by its ID [independent];
Girl is going out with at most one Boy,
	Boy is going out with at most one Girl;

