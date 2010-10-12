vocabulary OneToOnes;

/*
 * Value Types
 */
Boy ID is written as Auto Counter;
Girl ID is written as Auto Counter;

/*
 * Entity Types
 */
Boy is independent identified by its ID;

Girl is independent identified by its ID;
Girl is going out with at most one Boy,
	Boy is going out with at most one Girl;

