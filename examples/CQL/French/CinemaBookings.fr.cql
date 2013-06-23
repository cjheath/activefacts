vocabulaire RéservationsCinéma;

/*
 * Valeur Types
 */
chaque Cinéma ID est écrit en un Serial;
chaque Date Heure Valeur est écrit en une DateHeure;
chaque Film ID est écrit en un Serial;
chaque Nom est écrit en un String;
chaque Nombre est écrit en un Integer(16) limité à {1..};
chaque Personne ID est écrit en un Serial;
chaque Rangée Nombre est écrit en un Char(2);
chaque Siège Nombre est écrit en un Integer(16);
chaque Section Nom est écrit en un String;
chaque Nom de Connexion est écrit en un String;

/*
 * Entity Types
 */
chaque Cinéma est identifié par son ID;

chaque Date Heure est identifié par sa Valeur;

chaque Film est identifié par son ID;
Film a au plus une Nom;

chaque Personne est identifié par son ID;
Personne a un Nom de Connexion,
	Nom de Connexion est de au plus une Personne;

chaque Rangée est identifié par un Cinéma et un Rangée Nombre où
	cette Rangée est dans un Cinéma,
	ce Cinéma contient cette Rangée,
	cette Rangée a un Rangée Nombre,
	ce Rangée Nombre est de cette Rangée;

chaque Siège est identifié par un Rangée et un Siège Nombre où
	ce Siège est dans une Rangée,
	cette Rangée contient ce Siège,
	ce Siège a un Siège Nombre,
	ce Siège Nombre est de ce Siège;

chaque Section est identifié par son Nom;
Siège est dans au plus une Section,
	cette Section contient ce Siège;

chaque Projection existe si
	Cinéma transmet Film à Date Heure,
	Film est transmis à Date Heure à Cinéma;

chaque Réservation existe si
	Personne a réservé Projection pour un Nombre de siège,
	cette Personne a réservée ce Nombre de sièges pour cette Projection;
Réservation est confirmée;

chaque Siège Attribution existe si
	Réservation a Siège -attribué;

un certaine Réservation
    (dans laquelle une certaine Personne a réservée un certain Nombre de sièges pour une certaine Projection
	(dans laquelle un certain Film est transmis à une certaine Date Heure à un certain Cinéma))
    a un Siège attribué
    que si ce Siège est dans un certaine Rangée que est dans ce Cinéma;
