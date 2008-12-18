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
RingType is defined as VariableLengthText();
RoleSequenceId is defined as AutoCounter();
Scale is defined as UnsignedInteger(32);
Text is defined as VariableLengthText(256);
UnitId is defined as AutoCounter();
Value is defined as VariableLengthText(256);
ValueRestrictionId is defined as AutoCounter();

/*
 * Entity Types
 */
Bound is identified by Value and Bound is inclusive where
	Bound has one Value,
	Value is of at least one Bound,
	Bound is inclusive;

Coefficient is identified by Numerator and Denominator and Coefficient is precise where
	Coefficient has one Numerator,
	Coefficient has one Denominator,
	Coefficient is precise;

Constraint is identified by its Id;
Constraint requires at most one Enforcement,
	Enforcement applies to Constraint;
Name is of Constraint,
	Constraint is called at most one Name;

Fact is identified by its Id;

FactType is identified by its Id;
Fact is of one FactType;

Instance is identified by its Id;
Instance has at most one Value;

PresenceConstraint is a kind of Constraint;
PresenceConstraint has at most one max-Frequency;
PresenceConstraint has at most one min-Frequency;
PresenceConstraint is mandatory;
PresenceConstraint is preferred identifier;

Reading is identified by FactType and Ordinal where
	FactType has at least one Reading,
	Reading is for one FactType,
	Reading is in one Ordinal position,
	Ordinal reading for fact type is Reading;
Reading has one Text;

RingConstraint is a kind of Constraint;
RingConstraint is of one RingType;

RoleSequence is identified by its Id;
PresenceConstraint covers one RoleSequence;
Reading is in one RoleSequence,
	RoleSequence is for Reading;

RoleValue is identified by Instance and Fact where
	Instance plays RoleValue,
	RoleValue is of one Instance,
	RoleValue fulfils one Fact,
	Fact includes at least one RoleValue;

SetConstraint is a kind of Constraint;

SubsetConstraint is a kind of SetConstraint;
SubsetConstraint covers one subset-RoleSequence;
SubsetConstraint covers one superset-RoleSequence;

Unit is identified by its Id;
Name is of Unit,
	Unit is called one Name;
Unit has at most one Coefficient;
Unit is fundamental;
Derivation is where
	Unit (as DerivedUnit) is derived from base-Unit (as BaseUnit) [acyclic, intransitive];
Derivation has at most one Exponent;

ValueRange is identified by minimum-Bound and maximum-Bound where
	ValueRange has at most one minimum-Bound,
	ValueRange has at most one maximum-Bound;

ValueRestriction is identified by its Id;
AllowedRange is where
	ValueRestriction allows at least one ValueRange;

Vocabulary is identified by Name where
	Vocabulary is called one Name;
Vocabulary contains Constraint,
	Constraint belongs to at most one Vocabulary;
Import is where
	Vocabulary imports imported-Vocabulary [acyclic];

Feature is identified by Name and Vocabulary where
	Feature is called one Name,
	Feature belongs to at most one Vocabulary,
	Vocabulary contains Feature;
Correspondence is where
	in Import imported-Feature corresponds to at most one local-Feature;

Population is identified by Vocabulary and Name where
	Vocabulary includes Population,
	Population belongs to at most one Vocabulary,
	Population has one Name,
	Name is of Population;
Population includes Fact,
	Fact belongs to one Population;
Population includes Instance,
	Instance belongs to one Population;
Population includes RoleValue,
	RoleValue belongs to one Population;

SetComparisonConstraint is a kind of SetConstraint;
SetComparisonRoles is where
	SetComparisonConstraint covers at least one RoleSequence;

SetEqualityConstraint is a kind of SetComparisonConstraint;

SetExclusionConstraint is a kind of SetComparisonConstraint;
SetExclusionConstraint is mandatory;

Alias is a kind of Feature;

Concept is a kind of Feature;
Concept is independent;
Concept is personal;
Instance is of one Concept;
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
RoleValue is of one Role;
other-Role is of RingConstraint,
	RingConstraint has at most one other-Role;
RoleRef is where
	RoleSequence in Ordinal position includes at most one Role,
	Role is in RoleSequence in at most one Ordinal place,
	RoleSequence includes Role in Ordinal place,
	Role has Ordinal place in RoleSequence;
RoleRef has at most one leading-Adjective;
RoleRef has at most one trailing-Adjective;
JoinPath is where
	RoleRef has Ordinal (as JoinStep) path;
JoinPath traverses at most one Concept,
	Concept is traversed by JoinPath;
JoinPath has one input-Role;
JoinPath has one output-Role;

EntityType is a kind of Concept;
EntityType nests at most one FactType,
	FactType is nested as at most one EntityType;
TypeInheritance is a kind of FactType identified by Subtype and Supertype where
	EntityType (as Subtype) is subtype of super-EntityType (as Supertype) [acyclic],
	Supertype is supertype of Subtype;
TypeInheritance provides identification;

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
 */
for each Concept exactly one of these holds:
	EntityType is a subtype of Concept,
	ValueType is a subtype of Concept;
for each Constraint exactly one of these holds:
	PresenceConstraint is a subtype of Constraint,
	SetConstraint is a subtype of Constraint,
	RingConstraint is a subtype of Constraint;
for each Feature exactly one of these holds:
	Concept is a subtype of Feature,
	Alias is a subtype of Feature;
Instance plays RoleValue and Instance is of Concept
	if and only if
	RoleValue is of Role and FactType has Ordinal role played by Concept;
RoleValue fulfils Fact and Fact is of FactType
	if and only if
	RoleValue is of Role and FactType has Ordinal role played by Concept;
for each SetComparisonConstraint exactly one of these holds:
	SetExclusionConstraint is a subtype of SetComparisonConstraint,
	SetEqualityConstraint is a subtype of SetComparisonConstraint;
for each SetConstraint exactly one of these holds:
	SetComparisonConstraint is a subtype of SetConstraint,
	SubsetConstraint is a subtype of SetConstraint;
for each Unit exactly one of these holds:
	Unit is fundamental,
	that Unit is derived from some base-Unit;
PresenceConstraint is preferred identifier
	only if PresenceConstraint has max-Frequency;
ValueType has Scale
	only if ValueType has Length;
each combination EntityType, TypeInheritance occurs at most one time in
	EntityType is subtype of super-EntityType,
	TypeInheritance provides identification;
each FactType occurs at least one time in
	FactType has Ordinal role played by Concept;
each combination Name, Vocabulary occurs at most one time in
	Name is of Constraint,
	Vocabulary contains Constraint;
each PresenceConstraint occurs at least one time in
	PresenceConstraint has min-Frequency,
	PresenceConstraint has max-Frequency,
	PresenceConstraint is mandatory;
each RoleSequence occurs at least one time in
	RoleSequence in Ordinal position includes Role;
each ValueRange occurs at least one time in
	ValueRange has minimum-Bound,
	ValueRange has maximum-Bound;
