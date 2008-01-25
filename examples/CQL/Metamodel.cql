vocabulary Metamodel;

/*
 * Value Types
 */
Adjective = VariableLengthText();
Constraint_Id = AutoCounter();
Denominator = UnsignedInteger(32);
Enforcement = VariableLengthText();
Exponent = SignedSmallInteger(32);
FactType_Id = AutoCounter();
Fact_Id = AutoCounter();
Frequency = UnsignedInteger(32);
Instance_Id = AutoCounter();
Length = UnsignedInteger(32);
Name = VariableLengthText();
Numerator = Decimal();
Ordinal = UnsignedSmallInteger(32);
ReadingText = VariableLengthText();
RingType = VariableLengthText();
RoleSequence_Id = AutoCounter();
Role_Id = AutoCounter();
Scale = UnsignedInteger(32);
Unit_Id = AutoCounter();
Value = VariableLengthText();
ValueRestriction_Id = AutoCounter();

/*
 * Entity Types
 */
Bound = entity known by Value and Bound:
	Bound has exactly one Value,
	Value is of at least one Bound,
	each Value is of some Bound,
	Bound is inclusive;

Coefficient = entity known by Numerator and Denominator:
	Coefficient has exactly one Numerator,
	Coefficient has exactly one Denominator;

Constraint = entity known by Constraint_Id:
	Constraint has exactly one Constraint_Id,
	Constraint_Id is of at most one Constraint;

Fact = entity known by Fact_Id:
	Fact has exactly one Fact_Id,
	Fact_Id is of at most one Fact;

FactType = entity known by FactType_Id:
	FactType has exactly one FactType_Id,
	FactType_Id is of at most one FactType;

Instance = entity known by Instance_Id:
	Instance has exactly one Instance_Id,
	Instance_Id is of at most one Instance;

PresenceConstraint = subtype of Constraint;

Reading = entity known by Ordinal and FactType:
	Reading is in at most one Ordinal position,
	Ordinal reading for fact type is Reading,
	FactType has at least one Reading,
	each FactType has some Reading,
	Reading is for exactly one FactType;

RingConstraint = subtype of Constraint;

Role = entity known by Role_Id:
	Role has exactly one Role_Id,
	Role_Id is of at most one Role;

RoleSequence = entity known by RoleSequence_Id:
	RoleSequence has exactly one RoleSequence_Id,
	RoleSequence_Id is of at most one RoleSequence;

RoleValue = entity known by Instance and Fact:
	Instance plays RoleValue,
	RoleValue is of exactly one Instance,
	RoleValue fulfils exactly one Fact,
	some RoleValue fulfils each Fact;

SetConstraint = subtype of Constraint;

SubsetConstraint = subtype of SetConstraint;

UniquenessConstraint = subtype of PresenceConstraint;

Unit = entity known by Unit_Id:
	Unit has exactly one Unit_Id,
	Unit_Id is of at most one Unit;

ValueRange = entity known by minimum-Bound and maximum-Bound:
	ValueRange has at most one minimum-Bound,
	ValueRange has at most one maximum-Bound;

ValueRestriction = entity known by ValueRestriction_Id:
	ValueRestriction has exactly one ValueRestriction_Id,
	ValueRestriction_Id is of at most one ValueRestriction;

BaseUnit = entity known by base-Unit and Unit:
	Unit is derived from base-Unit [acyclic, intransitive];

MandatoryConstraint = subtype of PresenceConstraint;

ReadingRole = entity known by Role and Reading:
	ReadingRole is for exactly one Role,
	Role has place in at least one ReadingRole,
	each Role has place in some ReadingRole,
	Reading includes at least one ReadingRole,
	each Reading includes some ReadingRole,
	ReadingRole is for exactly one Reading;

SetComparisonConstraint = subtype of SetConstraint;

SetEqualityConstraint = subtype of SetComparisonConstraint;

SetExclusionConstraint = subtype of SetComparisonConstraint;

FrequencyConstraint = subtype of MandatoryConstraint;

NamedObject = entity known by Name and Vocabulary:
	NamedObject is called exactly one Name,
	NamedObject belongs to at most one Vocabulary,
	Vocabulary contains NamedObject;

Vocabulary = subtype of NamedObject;

Alias = subtype of NamedObject;

Concept = subtype of NamedObject;

EntityType = subtype of Concept;

Import = entity known by imported-Vocabulary and Vocabulary:
	Vocabulary imports imported-Vocabulary [acyclic];

Population = entity known by Vocabulary and Name:
	Vocabulary includes Population,
	Population belongs to at most one Vocabulary,
	Population has exactly one Name,
	Name is of Population;

RoleName = subtype of NamedObject;

TypeInheritance = subtype of FactType known by EntityType and super-EntityType:
	super-EntityType is supertype of EntityType [acyclic],
	EntityType is subtype of super-EntityType;

ValueType = subtype of Concept;

/*
 * Fact Types
 */
parent-Vocabulary contains Vocabulary [acyclic, intransitive],
	Vocabulary extends at most one parent-Vocabulary;
ValueType is subtype of at most one ValueType [acyclic],
	ValueType is supertype of ValueType;
TypeInheritance defines primary supertype;
Role has at most one RoleName,
	RoleName is name of Role;
ValueType has at most one Length,
	Length is of ValueType;
ValueType has at most one Scale,
	Scale is of ValueType;
ValueType has at most one ValueRestriction;
ValueRestrictionAllowsValueRange = ValueRestriction allows at least one ValueRange,
	each ValueRestriction allows some ValueRange;
ValueType is of at most one Unit;
BaseUnit has at most one Exponent;
Coefficient is precise;
Unit has at most one Coefficient;
Role has at most one ValueRestriction,
	ValueRestriction applies to Role;
EntityType is independent;
EntityType is personal;
Name is of Unit,
	Unit is called exactly one Name;
EntityType nests at most one FactType,
	FactType is nested as at most one EntityType;
ReadingRole has at most one leading-Adjective;
ReadingRole has at most one trailing-Adjective;
Reading has exactly one ReadingText;
Role is of RingConstraint,
	RingConstraint has at most one Role;
other-Role is of RingConstraint,
	RingConstraint has at most one other-Role;
Name is of Constraint,
	Constraint is called at most one Name;
Constraint requires at most one Enforcement;
SetComparisonConstraintCoversRoleSequence = SetComparisonConstraint covers at least one RoleSequence,
	each SetComparisonConstraint covers some RoleSequence;
PresenceConstraint covers exactly one RoleSequence;
RoleInSequence = RoleSequence includes in at most one Ordinal place at most one Role,
	each RoleSequence includes in some Ordinal place some Role,
	Role has Ordinal place in RoleSequence;
SubsetConstraint covers exactly one superset-RoleSequence;
SubsetConstraint covers exactly one subset-RoleSequence;
RingConstraint is of exactly one RingType;
PresenceConstraint has at most one max-Frequency;
PresenceConstraint has at most one min-Frequency;
Instance has at most one Value;
Instance is of exactly one Concept;
Population includes Instance,
	Instance belongs to exactly one Population;
Fact is of exactly one FactType;
Population includes RoleValue,
	RoleValue belongs to exactly one Population;
RoleValue is of exactly one Role;
Population includes Fact,
	Fact belongs to exactly one Population;
Bound is inclusive;
PresenceConstraint is preferred identifier;
PresenceConstraint is mandatory;
SetExclusionConstraint is mandatory;
Name has Alias,
	Alias is for exactly one Name;
Import includes Alias,
	Alias is for exactly one Import;

/*
Constraints:
	MandatoryExclusionConstraint ConceptMayNotBeBothValueTypeAndEntityType over EntityTypeIsASubtypeOfConcept(Concept), ValueTypeIsASubtypeOfConcept(Concept)
	MandatoryExclusionConstraint ConstraintMustBeOneConcreteType over RingConstraintIsASubtypeOfConstraint(Constraint), SetEqualityConstraintIsASubtypeOfSetComparisonConstraint(SetComparisonConstraint), SetExclusionConstraintIsASubtypeOfSetComparisonConstraint(SetComparisonConstraint), SubsetConstraintIsASubtypeOfSetConstraint(SetConstraint), PresenceConstraintIsASubtypeOfConstraint(Constraint)
	EachFactTypeHasAtLeastOneRole: in Role, each value (FactType) must occur at least 1 time
	EachRoleIsAtOneOrdinalPositionInFactType: in Role, each combination (FactType, Ordinal) may occur at most 1 time
	ExternalUniquenessConstraint1: each combination(NameHasAlias.Name, ImportIncludesAlias.Import) may occur at most 1 time
	MandatoryExclusionConstraint NamedObjectMustBeVocabularyConceptOrRoleName over VocabularyIsASubtypeOfNamedObject(NamedObject), ConceptIsASubtypeOfNamedObject(NamedObject), RoleNameIsASubtypeOfNamedObject(NamedObject), AliasIsASubtypeOfNamedObject(NamedObject)
	OnlyOneSupertypeMayBePrimary: each combination(TypeInheritance.EntityType, TypeInheritanceDefinesPrimarySupertype.TypeInheritance) may occur at most 1 time
	SubsetConstraint PreferredIdentifierHasMaxFrequency PresenceConstraintHasMaxFrequency(PresenceConstraint) < PresenceConstraintIsPreferredIdentifier(PresenceConstraint)
	PresenceConstraintMustHaveFrequency: each combination(PresenceConstraintHasMinFrequency.PresenceConstraint, PresenceConstraintHasMaxFrequency.PresenceConstraint, PresenceConstraintIsMandatory.PresenceConstraint) must occur at least 1 time
	ValueRangeMustHaveAtLeastOneBound: each combination(ValueRangeHasMinimumBound.ValueRange, ValueRangeHasMaximumBound.ValueRange) must occur at least 1 time
	SubsetConstraint ValueTypeWithLengthMayHaveScale ValueTypeHasLength(ValueType) < ValueTypeHasScale(ValueType)
 */
