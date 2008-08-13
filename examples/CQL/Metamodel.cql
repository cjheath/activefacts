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
RoleSequenceId is defined as AutoCounter();
Scale is defined as UnsignedInteger(32);
UnitId is defined as AutoCounter();
Value is defined as VariableLengthText(256);
ValueRestrictionId is defined as AutoCounter();

/*
 * Entity Types
 */
Bound is identified by Value and Bound where
	Bound has exactly one Value,
	Value is of at least one Bound,
	Bound is inclusive;

Coefficient is identified by Numerator and Denominator where
	Coefficient has exactly one Numerator,
	Coefficient has exactly one Denominator;
Coefficient is precise;

Constraint is identified by ConstraintId where
	Constraint has exactly one ConstraintId,
	ConstraintId is of at most one Constraint;
Constraint requires at most one Enforcement,
	Enforcement applies to Constraint;
Name is of Constraint,
	Constraint is called at most one Name;

Fact is identified by FactId where
	Fact has exactly one FactId,
	FactId is of at most one Fact;

FactType is identified by FactTypeId where
	FactType has exactly one FactTypeId,
	FactTypeId is of at most one FactType;
Fact is of exactly one FactType;

Instance is identified by InstanceId where
	Instance has exactly one InstanceId,
	InstanceId is of at most one Instance;
Instance has at most one Value;

PresenceConstraint is a kind of Constraint;
PresenceConstraint has at most one max-Frequency;
PresenceConstraint has at most one min-Frequency;
PresenceConstraint is mandatory;
PresenceConstraint is preferred identifier;

Reading is identified by FactType and Ordinal where
	FactType has at least one Reading,
	Reading is for exactly one FactType,
	Reading is in at most one Ordinal position,
	Ordinal reading for fact type is Reading;
Reading has exactly one ReadingText;

RingConstraint is a kind of Constraint;
RingConstraint is of exactly one RingType;

RoleSequence is identified by RoleSequenceId where
	RoleSequence has exactly one RoleSequenceId,
	RoleSequenceId is of at most one RoleSequence;
PresenceConstraint covers exactly one RoleSequence;
Reading is in exactly one RoleSequence,
	RoleSequence is for Reading;

RoleValue is identified by Instance and Fact where
	Instance plays RoleValue,
	RoleValue is of exactly one Instance,
	RoleValue fulfils exactly one Fact,
	Fact includes at least one RoleValue;

SetConstraint is a kind of Constraint;

SubsetConstraint is a kind of SetConstraint;
SubsetConstraint covers exactly one subset-RoleSequence;
SubsetConstraint covers exactly one superset-RoleSequence;

UniquenessConstraint is a kind of PresenceConstraint;

Unit is identified by UnitId where
	Unit has exactly one UnitId,
	UnitId is of at most one Unit;
Name is of Unit,
	Unit is called exactly one Name;
Unit has at most one Coefficient;
Unit is fundamental;
UnitBasis is where
	Unit (as DerivedUnit) is derived from base-Unit (as BaseUnit) [acyclic, intransitive];
UnitBasis has at most one Exponent;

ValueRange is identified by minimum-Bound and maximum-Bound where
	ValueRange has at most one minimum-Bound,
	ValueRange has at most one maximum-Bound;

ValueRestriction is identified by ValueRestrictionId where
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

Feature is identified by Name and Vocabulary where
	Feature is called exactly one Name,
	Feature belongs to at most one Vocabulary,
	Vocabulary contains Feature;

Vocabulary is a kind of Feature;
Vocabulary contains Constraint,
	Constraint belongs to at most one Vocabulary;
Vocabulary extends at most one parent-Vocabulary [acyclic, intransitive],
	parent-Vocabulary contains Vocabulary;
Import is where
	Vocabulary imports imported-Vocabulary [acyclic];
Correspondence is where
	in Import imported-Feature corresponds to at most one local-Feature;

Alias is a kind of Feature;

Concept is a kind of Feature;
Instance is of exactly one Concept;
Role is where
	FactType has Ordinal role played by Concept,
	Concept plays role in FactType in Ordinal place,
	Concept plays Ordinal role in FactType;
Role is of RingConstraint,
	RingConstraint has at most one Role;
Role has at most one role-Name,
	role-Name is name of at least one Role;
Role has at most one role-ValueRestriction,
	ValueRestriction applies to Role;
RoleValue is of exactly one Role;
other-Role is of RingConstraint,
	RingConstraint has at most one other-Role;
RoleRef is where
	Role is in RoleSequence in at most one Ordinal place,
	RoleSequence includes at most one Role in Ordinal place,
	Role has Ordinal place in RoleSequence;
RoleRef has at most one leading-Adjective;
RoleRef has at most one trailing-Adjective;

EntityType is a kind of Concept;
EntityType nests at most one FactType,
	FactType is nested as at most one EntityType;
EntityType is independent;
EntityType is personal;
TypeInheritance is a kind of FactType identified by Subtype and Supertype where
	EntityType (as Subtype) is subtype of super-EntityType (as Supertype) [acyclic],
	Supertype is supertype of Subtype;
TypeInheritance provides identification;

Population is identified by Vocabulary and Name where
	Vocabulary includes Population,
	Population belongs to at most one Vocabulary,
	Population has exactly one Name,
	Name is of Population;
Population includes Fact,
	Fact belongs to exactly one Population;
Population includes Instance,
	Instance belongs to exactly one Population;
Population includes RoleValue,
	RoleValue belongs to exactly one Population;

ValueType is a kind of Concept;
ValueType has at most one Length,
	Length is of ValueType;
ValueType has at most one Scale,
	Scale is of ValueType;
ValueType is of at most one Unit;
ValueType has at most one ValueRestriction;
ValueType is subtype of at most one super-ValueType (as Supertype) [acyclic],
	Supertype is supertype of ValueType;

/*
 * Constraints:
for each Concept exactly one of these holds:
	EntityType is a subtype of Concept,
	ValueType is a subtype of Concept;
for each Constraint exactly one of these holds:
	some RingConstraint is a subtype of that Constraint,
	some SetEqualityConstraint is a subtype of that Constraint,
	some SetExclusionConstraint is a subtype of that Constraint,
	some SubsetConstraint is a subtype of that Constraint,
	some PresenceConstraint is a subtype of that Constraint;
each RoleSequence occurs at least one time in
	Role is in RoleSequence in Ordinal place;
Instance plays RoleValue and Instance is of Concept
	if and only if
	RoleValue is of Role and FactType has Ordinal role played by Concept;
RoleValue fulfils Fact and Fact is of FactType
	if and only if
	RoleValue is of Role and FactType has Ordinal role played by Concept;
for each Unit exactly one of these holds:
	Unit is fundamental,
	that Unit is derived from some base-Unit;
each combination Name, Vocabulary occurs at most one time in
	Name is of Constraint,
	Vocabulary contains Constraint;
for each Feature exactly one of these holds:
	Vocabulary is a subtype of Feature,
	Concept is a subtype of Feature,
	Alias is a subtype of Feature;
each combination EntityType, TypeInheritance occurs at most one time in
	EntityType is subtype of super-EntityType,
	TypeInheritance provides identification;
PresenceConstraint is preferred identifier
	only if PresenceConstraint has max-Frequency;
each PresenceConstraint occurs at least one time in
	PresenceConstraint has min-Frequency,
	PresenceConstraint has max-Frequency,
	PresenceConstraint is mandatory;
each FactType occurs at least one time in
	FactType has Ordinal role played by Concept;
each ValueRange occurs at least one time in
	ValueRange has minimum-Bound,
	ValueRange has maximum-Bound;
ValueType has Scale
	only if ValueType has Length;
 */
