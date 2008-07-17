vocabulary Metamodel;

/*
 * Value Types
 */
Adjective is defined as VariableLengthText(64);
ConstraintId is defined as AutoCounter();
Denominator is defined as UnsignedInteger(32);
Enforcement is defined as VariableLengthText(16);
Exponent is defined as SignedSmallInteger(32);
FactId is defined as AutoCounter();
FactTypeId is defined as AutoCounter();
Frequency is defined as UnsignedInteger(32);
InstanceId is defined as AutoCounter();
Length is defined as UnsignedInteger(32);
Name is defined as VariableLengthText(64);
Numerator is defined as Decimal();
Ordinal is defined as UnsignedSmallInteger(32);
ReadingText is defined as VariableLengthText(256);
RingType is defined as VariableLengthText();
RoleId is defined as AutoCounter();
RoleSequenceId is defined as AutoCounter();
Scale is defined as UnsignedInteger(32);
UnitId is defined as AutoCounter();
Value is defined as VariableLengthText(256);
ValueRestrictionId is defined as AutoCounter();

/*
 * Entity Types
 */
Bound is identified by Value and Bound:
	Bound has exactly one Value,
	Value is of at least one Bound,
	Bound is inclusive;

Coefficient is identified by Numerator and Denominator:
	Coefficient has exactly one Numerator,
	Coefficient has exactly one Denominator;
Coefficient is precise;

Constraint is identified by ConstraintId:
	Constraint has exactly one ConstraintId,
	ConstraintId is of at most one Constraint;
Name is of Constraint,
	Constraint is called at most one Name;
Constraint requires at most one Enforcement,
	Enforcement applies to Constraint;

Fact is identified by FactId:
	Fact has exactly one FactId,
	FactId is of at most one Fact;

FactType is identified by FactTypeId:
	FactType has exactly one FactTypeId,
	FactTypeId is of at most one FactType;
Fact is of exactly one FactType;

Instance is identified by InstanceId:
	Instance has exactly one InstanceId,
	InstanceId is of at most one Instance;
Instance has at most one Value;

PresenceConstraint is a kind of Constraint;
PresenceConstraint has at most one max-Frequency;
PresenceConstraint has at most one min-Frequency;
PresenceConstraint is preferred identifier;
PresenceConstraint is mandatory;

Reading is identified by FactType and Ordinal:
	FactType has at least one Reading,
	Reading is for exactly one FactType,
	Reading is in at most one Ordinal position,
	Ordinal reading for fact type is Reading;
Reading has exactly one ReadingText;

RingConstraint is a kind of Constraint;
RingConstraint is of exactly one RingType;

RoleSequence is identified by RoleSequenceId:
	RoleSequence has exactly one RoleSequenceId,
	RoleSequenceId is of at most one RoleSequence;
Reading is in exactly one RoleSequence,
	RoleSequence is for Reading;
PresenceConstraint covers exactly one RoleSequence;

RoleValue is identified by Instance and Fact:
	Instance plays RoleValue,
	RoleValue is of exactly one Instance,
	RoleValue fulfils exactly one Fact;

SetConstraint is a kind of Constraint;

SubsetConstraint is a kind of SetConstraint;
SubsetConstraint covers exactly one superset-RoleSequence;
SubsetConstraint covers exactly one subset-RoleSequence;

UniquenessConstraint is a kind of PresenceConstraint;

Unit is identified by UnitId:
	Unit has exactly one UnitId,
	UnitId is of at most one Unit;
UnitBasis is where
	Unit (as DerivedUnit) is derived from base-Unit (as BaseUnit) [acyclic, intransitive];
Unit has at most one Coefficient;
Name is of Unit,
	Unit is called exactly one Name;
Unit is fundamental;
UnitBasis has at most one Exponent;

ValueRange is identified by minimum-Bound and maximum-Bound:
	ValueRange has at most one minimum-Bound,
	ValueRange has at most one maximum-Bound;

ValueRestriction is identified by ValueRestrictionId:
	ValueRestriction has exactly one ValueRestrictionId,
	ValueRestrictionId is of at most one ValueRestriction;
AllowedRange is where
	ValueRestriction allows at least one ValueRange;

FrequencyConstraint is a kind of PresenceConstraint;

MandatoryConstraint is a kind of PresenceConstraint;

SetComparisonConstraint is a kind of SetConstraint;
SetComparisonRoles is where
	SetComparisonConstraint covers at least one RoleSequence;

SetEqualityConstraint is a kind of SetComparisonConstraint;

SetExclusionConstraint is a kind of SetComparisonConstraint;
SetExclusionConstraint is mandatory;

Feature is identified by Name and Vocabulary:
	Feature is called exactly one Name,
	Feature belongs to at most one Vocabulary,
	Vocabulary contains Feature;

Vocabulary is a kind of Feature;
Vocabulary extends at most one parent-Vocabulary [acyclic, intransitive],
	parent-Vocabulary contains Vocabulary;
Import is where
	Vocabulary imports imported-Vocabulary [acyclic];
Vocabulary contains Constraint,
	Constraint belongs to at most one Vocabulary;
Correspondence is where
	in Import imported-Feature corresponds to at most one local-Feature;

Alias is a kind of Feature;

Concept is a kind of Feature;
Role is identified by RoleId:
	Role has exactly one RoleId,
	RoleId is of at most one Role,
	Concept plays role in FactType;
Role has at most one role-Name,
	role-Name is name of at least one Role;
Role has at most one role-ValueRestriction,
	ValueRestriction applies to Role;
Role is of RingConstraint,
	RingConstraint has at most one Role;
other-Role is of RingConstraint,
	RingConstraint has at most one other-Role;
RoleRef is where
	Role is in RoleSequence in at most one Ordinal place,
	RoleSequence includes at most one Role in Ordinal place,
	Role has Ordinal place in RoleSequence;
RoleValue is of exactly one Role;
RoleRef has at most one leading-Adjective;
RoleRef has at most one trailing-Adjective;
Instance is of exactly one Concept;

EntityType is a kind of Concept;
TypeInheritance is a kind of FactType where
	EntityType (as Subtype) is subtype of super-EntityType (as Supertype) [acyclic],
	Supertype is supertype of Subtype;
EntityType is independent;
EntityType is personal;
EntityType nests at most one FactType,
	FactType is nested as at most one EntityType;
TypeInheritance provides identification;

Population is identified by Vocabulary and Name:
	Vocabulary includes Population,
	Population belongs to at most one Vocabulary,
	Population has exactly one Name,
	Name is of Population;
Population includes Instance,
	Instance belongs to exactly one Population;
Population includes RoleValue,
	RoleValue belongs to exactly one Population;
Population includes Fact,
	Fact belongs to exactly one Population;

ValueType is a kind of Concept;
ValueType is subtype of at most one super-ValueType (as Supertype) [acyclic],
	Supertype is supertype of ValueType;
ValueType has at most one Length,
	Length is of ValueType;
ValueType has at most one Scale,
	Scale is of ValueType;
ValueType has at most one ValueRestriction;
ValueType is of at most one Unit;

/*
Constraints:
	REVISIT: mandatory exclusion over (Concept) in 'EntityType is a kind of Concept', (Concept) in 'ValueType is a kind of Concept'
	REVISIT: mandatory exclusion over (Constraint) in 'RingConstraint is a kind of Constraint', (SetComparisonConstraint) in 'SetEqualityConstraint is a kind of SetComparisonConstraint', (SetComparisonConstraint) in 'SetExclusionConstraint is a kind of SetComparisonConstraint', (SetConstraint) in 'SubsetConstraint is a kind of SetConstraint', (Constraint) in 'PresenceConstraint is a kind of Constraint'
	REVISIT: each (Fact) occurs at least one time in 'RoleValue fulfils Fact'
	REVISIT: each (FactType) occurs at least one time in 'Concept plays role in FactType'
	REVISIT: each (RoleSequence) occurs at least one time in 'Role is in RoleSequence in Ordinal place'
	REVISIT: equality over (Vocabulary) in 'Vocabulary imports imported-Vocabulary', (Feature) in 'in Import imported-Feature corresponds to local-Feature'
	REVISIT: equality over (Vocabulary) in 'Vocabulary imports imported-Vocabulary', (Feature) in 'in Import imported-Feature corresponds to local-Feature'
	REVISIT: mandatory exclusion over (Unit) in 'Unit is fundamental', (Unit) in 'DerivedUnit is derived from BaseUnit'
	REVISIT: at most one Constraint exists for each 'Name is of Constraint', 'Vocabulary contains Constraint'
	REVISIT: mandatory exclusion over (Feature) in 'Vocabulary is a kind of Feature', (Feature) in 'Concept is a kind of Feature', (Feature) in 'Alias is a kind of Feature'
	REVISIT: at most one UNKNOWN exists for each 'Subtype is subtype of Supertype', 'TypeInheritance provides identification'
	REVISIT: 'PresenceConstraint is preferred identifier' only if 'PresenceConstraint has max-Frequency'
	REVISIT: PresenceConstraint must play at least one of 'PresenceConstraint has min-Frequency', 'PresenceConstraint has max-Frequency', 'PresenceConstraint is mandatory'
	REVISIT: ValueRange must play at least one of 'ValueRange has minimum-Bound', 'ValueRange has maximum-Bound'
	REVISIT: 'ValueType has Scale' only if 'ValueType has Length'
 */
