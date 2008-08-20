
CREATE TABLE Feature
(
	featureId INTEGER IDENTITY (1, 1) NOT NULL,
	name NATIONAL CHARACTER VARYING(64) NOT NULL,
	vocabularyId INTEGER,
	entityTypeFactTypeId INTEGER,
	vocabularyParentVocabularyId INTEGER,
	valueTypeLength INTEGER CHECK (valueTypeLength >= 0),
	valueTypeScale INTEGER CHECK (valueTypeScale >= 0),
	valueTypeValueRestrictionId INTEGER ,
	valueTypeSupertype INTEGER,
	valueTypeUnitId INTEGER,
	entityTypeIsIndependent BIT,
	entityTypeIsPersonal BIT,
	CONSTRAINT Feature_PK PRIMARY KEY(featureId)
)
GO

CREATE UNIQUE  INDEX NameIsUniqueInVocabulary_UCIndex ON Feature(name, vocabularyId)
GO

CREATE UNIQUE  INDEX FactTypeIsNestedAsOneEntityType_UCIndex ON Feature(entityTypeFactTypeId)
GO


CREATE TABLE FactType
(
	factTypeId INTEGER IDENTITY (1, 1) NOT NULL,
	typeInheritanceProvidesIdentification BIT,
	typeInheritanceSupertype INTEGER,
	typeInheritanceSubtype INTEGER,
	CONSTRAINT FactType_PK PRIMARY KEY(factTypeId),
	CONSTRAINT FactType_TypeInheritance_MandatoryGroup CHECK (typeInheritanceSubtype IS NOT NULL AND typeInheritanceSupertype IS NOT NULL OR typeInheritanceProvidesIdentification IS NULL AND typeInheritanceSubtype IS NULL AND typeInheritanceSupertype IS NULL)
)
GO


CREATE UNIQUE  INDEX FactType_UCIndex ON FactType(typeInheritanceSubtype, typeInheritanceSupertype)
GO


CREATE UNIQUE  INDEX OnlyOneSupertypeMayBePrimary_UCIndex ON FactType(typeInheritanceSubtype, typeInheritanceProvidesIdentification)
GO


CREATE TABLE AllowedRange
(
	valueRestrictionId INTEGER IDENTITY (1, 1) NOT NULL,
	minimumBoundValue NATIONAL CHARACTER VARYING(256),
	minimumBoundIsInclusive BIT,
	maximumBoundValue NATIONAL CHARACTER VARYING(256),
	maximumBoundIsInclusive BIT
)
GO


CREATE TABLE Unit
(
	unitId INTEGER IDENTITY (1, 1) NOT NULL,
	name NATIONAL CHARACTER VARYING(64) NOT NULL,
	isFundamental BIT,
	numerator DECIMAL(38,38),
	denominator INTEGER CHECK (denominator >= 0),
	CONSTRAINT Unit_PK PRIMARY KEY(unitId),
	CONSTRAINT Unit_Coefficient_MandatoryGroup CHECK (numerator IS NOT NULL AND denominator IS NOT NULL OR numerator IS NULL AND denominator IS NULL)
)
GO


CREATE TABLE UnitBasis
(
	derivedUnit INTEGER NOT NULL,
	baseUnit INTEGER NOT NULL,
	exponent SMALLINT NOT NULL,
	CONSTRAINT UnitIsBaseForEachUnitOnceOnly_PK PRIMARY KEY(baseUnit, derivedUnit)
)
GO


CREATE TABLE Coefficient
(
	numerator DECIMAL(38,38) NOT NULL,
	denominator INTEGER CHECK (denominator >= 0) NOT NULL,
	isPrecise BIT,
	CONSTRAINT CoefficientIsKnownByNumeratorAndDenominator_PK PRIMARY KEY(numerator, denominator)
)
GO


CREATE TABLE Reading
(
	factTypeId INTEGER NOT NULL,
	ordinal SMALLINT CHECK (ordinal >= 0),
	readingText NATIONAL CHARACTER VARYING(256) NOT NULL,
	roleSequenceId INTEGER IDENTITY (1, 1) NOT NULL
)
GO


CREATE TABLE RingConstraint
(
	ringConstraintId INTEGER NOT NULL,
	ringType NATIONAL CHARACTER VARYING(24) NOT NULL,
	otherRoleFactTypeId INTEGER,
	otherRoleOrdinal SMALLINT CHECK (otherRoleOrdinal >= 0),
	otherRoleConceptId INTEGER,
	roleFactTypeId INTEGER,
	roleOrdinal SMALLINT CHECK (roleOrdinal >= 0),
	roleConceptId INTEGER,
	CONSTRAINT RingConstraint_PK PRIMARY KEY(ringConstraintId),
	CONSTRAINT RingConstraint_Role1_MandatoryGroup CHECK (roleConceptId IS NOT NULL AND roleOrdinal IS NOT NULL AND roleFactTypeId IS NOT NULL OR roleConceptId IS NULL AND roleOrdinal IS NULL AND roleFactTypeId IS NULL),
	CONSTRAINT RingConstraint_Role2_MandatoryGroup CHECK (otherRoleConceptId IS NOT NULL AND otherRoleOrdinal IS NOT NULL AND otherRoleFactTypeId IS NOT NULL OR otherRoleConceptId IS NULL AND otherRoleOrdinal IS NULL AND otherRoleFactTypeId IS NULL)
)
GO


CREATE TABLE "Constraint"
(
	constraintId INTEGER IDENTITY (1, 1) NOT NULL,
	name NATIONAL CHARACTER VARYING(64),
	vocabularyId INTEGER,
	enforcement NATIONAL CHARACTER VARYING(16),
	CONSTRAINT Constraint_PK PRIMARY KEY(constraintId)
)
GO



CREATE UNIQUE  INDEX Constraint_UCIndex ON [Constraint](name, vocabularyId)
GO


CREATE TABLE PresenceConstraint
(
	presenceConstraintId INTEGER NOT NULL,
	roleSequenceId INTEGER IDENTITY (1, 1) NOT NULL,
	minFrequency INTEGER CHECK (minFrequency >= 0),
	maxFrequency INTEGER CHECK (maxFrequency >= 0),
	isPreferredIdentifier BIT,
	isMandatory BIT,
	CONSTRAINT PresenceConstraint_PK PRIMARY KEY(presenceConstraintId),
	CONSTRAINT PresenceConstraint_minFrequency_RoleValueConstraint1 CHECK (minFrequency >= 2),
	CONSTRAINT PresenceConstraint_maxFrequency_RoleValueConstraint2 CHECK (maxFrequency >= 1)
)
GO


CREATE TABLE SetComparisonRoles
(
	roleSequenceId INTEGER IDENTITY (1, 1) NOT NULL,
	setComparisonConstraintId INTEGER NOT NULL,
	CONSTRAINT SetComparisonRoles_PK PRIMARY KEY(setComparisonConstraintId, roleSequenceId)
)
GO


CREATE TABLE RoleRef
(
	roleSequenceId INTEGER IDENTITY (1, 1) NOT NULL,
	ordinal SMALLINT CHECK (ordinal >= 0) NOT NULL,
	roleFactTypeId INTEGER NOT NULL,
	roleOrdinal SMALLINT CHECK (roleOrdinal >= 0) NOT NULL,
	conceptId INTEGER NOT NULL,
	leadingAdjective NATIONAL CHARACTER VARYING(64),
	trailingAdjective NATIONAL CHARACTER VARYING(64),
	CONSTRAINT RoleRef_UC UNIQUE(roleFactTypeId, roleOrdinal, conceptId, roleSequenceId),
	CONSTRAINT RoleRef_PK PRIMARY KEY(roleSequenceId, ordinal)
)
GO


CREATE TABLE SubsetConstraint
(
	subsetConstraintId INTEGER IDENTITY (1, 1) NOT NULL,
	supersetRoleSequenceId INTEGER NOT NULL,
	subsetRoleSequenceId INTEGER  NOT NULL,
	CONSTRAINT SubsetConstraint_PK PRIMARY KEY(subsetConstraintId)
)
GO


CREATE TABLE Instance
(
	instanceId INTEGER IDENTITY (1, 1) NOT NULL,
	name NATIONAL CHARACTER VARYING(64) NOT NULL,
	conceptId INTEGER NOT NULL,
	"value" NATIONAL CHARACTER VARYING(256),
	vocabularyId INTEGER,
	CONSTRAINT Instance_PK PRIMARY KEY(instanceId)
)
GO


CREATE TABLE Fact
(
	factId INTEGER IDENTITY (1, 1) NOT NULL,
	name NATIONAL CHARACTER VARYING(64) NOT NULL,
	factTypeId INTEGER NOT NULL,
	vocabularyId INTEGER,
	CONSTRAINT Fact_PK PRIMARY KEY(factId)
)
GO


CREATE TABLE RoleValue
(
	factId INTEGER NOT NULL,
	instanceId INTEGER NOT NULL,
	name NATIONAL CHARACTER VARYING(64) NOT NULL,
	factTypeId INTEGER NOT NULL,
	ordinal SMALLINT CHECK (ordinal >= 0) NOT NULL,
	conceptId INTEGER NOT NULL,
	vocabularyId INTEGER,
	CONSTRAINT RoleValueIsKnownByInstanceAndFact_PK PRIMARY KEY(instanceId, factId)
)
GO


CREATE TABLE SetConstraint
(
	setConstraintId INTEGER NOT NULL,
	setExclusionConstraintIsMandatory BIT,
	CONSTRAINT SetConstraint_PK PRIMARY KEY(setConstraintId)
)
GO


CREATE TABLE Correspondence
(
	vocabularyId1 INTEGER NOT NULL,
	vocabularyId2 INTEGER NOT NULL,
	featureId2 INTEGER NOT NULL,
	featureId1 INTEGER NOT NULL,
	CONSTRAINT Correspondence_PK PRIMARY KEY(featureId2, vocabularyId1, vocabularyId2)
)
GO


CREATE TABLE Role
(
	ordinal SMALLINT CHECK (ordinal >= 0) NOT NULL,
	conceptId INTEGER NOT NULL,
	factTypeId INTEGER NOT NULL,
	roleName NATIONAL CHARACTER VARYING(64),
	roleValueRestrictionId INTEGER IDENTITY (1, 1),
	CONSTRAINT Role_PK PRIMARY KEY(factTypeId, ordinal, conceptId)
)
GO


ALTER TABLE Feature ADD CONSTRAINT Feature_FK1 FOREIGN KEY (vocabularyId) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Feature ADD CONSTRAINT Feature_FK2 FOREIGN KEY (vocabularyParentVocabularyId) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Feature ADD CONSTRAINT Feature_FK3 FOREIGN KEY (valueTypeSupertype) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Feature ADD CONSTRAINT Feature_FK4 FOREIGN KEY (valueTypeUnitId) REFERENCES Unit (unitId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Feature ADD CONSTRAINT Feature_FK5 FOREIGN KEY (entityTypeFactTypeId) REFERENCES FactType (factTypeId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE FactType ADD CONSTRAINT FactType_FK1 FOREIGN KEY (typeInheritanceSupertype) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE FactType ADD CONSTRAINT FactType_FK2 FOREIGN KEY (typeInheritanceSubtype) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Unit ADD CONSTRAINT Unit_FK FOREIGN KEY (numerator, denominator) REFERENCES Coefficient (numerator, denominator) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE UnitBasis ADD CONSTRAINT UnitBasis_FK1 FOREIGN KEY (derivedUnit) REFERENCES Unit (unitId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE UnitBasis ADD CONSTRAINT UnitBasis_FK2 FOREIGN KEY (baseUnit) REFERENCES Unit (unitId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Reading ADD CONSTRAINT Reading_FK FOREIGN KEY (factTypeId) REFERENCES FactType (factTypeId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE RingConstraint ADD CONSTRAINT RingConstraint_FK1 FOREIGN KEY (otherRoleFactTypeId, otherRoleOrdinal, otherRoleConceptId) REFERENCES Role (factTypeId, ordinal, conceptId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE RingConstraint ADD CONSTRAINT RingConstraint_FK2 FOREIGN KEY (roleFactTypeId, roleOrdinal, roleConceptId) REFERENCES Role (factTypeId, ordinal, conceptId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE RingConstraint ADD CONSTRAINT RingConstraint_FK3 FOREIGN KEY (ringConstraintId) REFERENCES "Constraint" (constraintId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE "Constraint" ADD CONSTRAINT Constraint_FK FOREIGN KEY (vocabularyId) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE PresenceConstraint ADD CONSTRAINT PresenceConstraint_FK FOREIGN KEY (presenceConstraintId) REFERENCES "Constraint" (constraintId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE SetComparisonRoles ADD CONSTRAINT SetComparisonRoles_FK FOREIGN KEY (setComparisonConstraintId) REFERENCES SetConstraint (setConstraintId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE RoleRef ADD CONSTRAINT RoleRef_FK FOREIGN KEY (roleFactTypeId, roleOrdinal, conceptId) REFERENCES Role (factTypeId, ordinal, conceptId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE SubsetConstraint ADD CONSTRAINT SubsetConstraint_FK FOREIGN KEY (subsetConstraintId) REFERENCES SetConstraint (setConstraintId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Instance ADD CONSTRAINT Instance_FK1 FOREIGN KEY (conceptId) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Instance ADD CONSTRAINT Instance_FK2 FOREIGN KEY (vocabularyId) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Fact ADD CONSTRAINT Fact_FK1 FOREIGN KEY (factTypeId) REFERENCES FactType (factTypeId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Fact ADD CONSTRAINT Fact_FK2 FOREIGN KEY (vocabularyId) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE RoleValue ADD CONSTRAINT RoleValue_FK1 FOREIGN KEY (vocabularyId) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE RoleValue ADD CONSTRAINT RoleValue_FK2 FOREIGN KEY (factId) REFERENCES Fact (factId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE RoleValue ADD CONSTRAINT RoleValue_FK3 FOREIGN KEY (instanceId) REFERENCES Instance (instanceId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE RoleValue ADD CONSTRAINT RoleValue_FK4 FOREIGN KEY (factTypeId, ordinal, conceptId) REFERENCES Role (factTypeId, ordinal, conceptId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE SetConstraint ADD CONSTRAINT SetConstraint_FK FOREIGN KEY (setConstraintId) REFERENCES "Constraint" (constraintId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Correspondence ADD CONSTRAINT Correspondence_FK1 FOREIGN KEY (vocabularyId1) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Correspondence ADD CONSTRAINT Correspondence_FK2 FOREIGN KEY (vocabularyId2) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Correspondence ADD CONSTRAINT Correspondence_FK3 FOREIGN KEY (featureId1) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Correspondence ADD CONSTRAINT Correspondence_FK4 FOREIGN KEY (featureId2) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Role ADD CONSTRAINT Role_FK1 FOREIGN KEY (conceptId) REFERENCES Feature (featureId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


ALTER TABLE Role ADD CONSTRAINT Role_FK2 FOREIGN KEY (factTypeId) REFERENCES FactType (factTypeId) ON DELETE NO ACTION ON UPDATE NO ACTION
GO


GO