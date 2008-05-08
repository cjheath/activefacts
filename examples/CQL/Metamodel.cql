vocabulary Metamodel;

/*
 * Value Types
 */
Adjective = VariableLengthText(64);
ConstraintId = AutoCounter();
Denominator = UnsignedInteger(32);
Enforcement = VariableLengthText(16);
Exponent = SignedSmallInteger(32);
FactId = AutoCounter();
FactTypeId = AutoCounter();
Frequency = UnsignedInteger(32);
InstanceId = AutoCounter();
Length = UnsignedInteger(32);
Name = VariableLengthText(64);
Numerator = Decimal();
Ordinal = UnsignedSmallInteger(32);
ReadingText = VariableLengthText(256);
RingType = VariableLengthText();
RoleId = AutoCounter();
RoleSequenceId = AutoCounter();
Scale = UnsignedInteger(32);
UnitId = AutoCounter();
Value = VariableLengthText(256);
ValueRestrictionId = AutoCounter();

/*
 * Entity Types
 */
Bound = entity identified by Value and Bound:
	Bound has exactly one Value,
	Value is of at least one Bound,
	Bound is inclusive;

Coefficient = entity identified by Numerator and Denominator:
	Coefficient has exactly one Numerator,
	Coefficient has exactly one Denominator;
Coefficient is precise;

Constraint = entity identified by ConstraintId:
	Constraint has exactly one ConstraintId,
	ConstraintId is of at most one Constraint;
Name is of Constraint,
	Constraint is called at most one Name;
Constraint requires at most one Enforcement,
	Enforcement applies to Constraint;

Fact = entity identified by FactId:
	Fact has exactly one FactId,
	FactId is of at most one Fact;

FactType = entity identified by FactTypeId:
	FactType has exactly one FactTypeId,
	FactTypeId is of at most one FactType;
Fact is of exactly one FactType;

Instance = entity identified by InstanceId:
	Instance has exactly one InstanceId,
	InstanceId is of at most one Instance;
Instance has at most one Value;

PresenceConstraint = subtype of Constraint;
PresenceConstraint has at most one max-Frequency;
PresenceConstraint has at most one min-Frequency;
PresenceConstraint is preferred identifier;
PresenceConstraint is mandatory;

Reading = entity identified by FactType and Ordinal:
	FactType has at least one Reading,
	Reading is for exactly one FactType,
	Reading is in at most one Ordinal position,
	Ordinal reading for fact type is Reading;
Reading has exactly one ReadingText;

RingConstraint = subtype of Constraint;
RingConstraint is of exactly one RingType;

RoleSequence = entity identified by RoleSequenceId:
	RoleSequence has exactly one RoleSequenceId,
	RoleSequenceId is of at most one RoleSequence;
Reading is in exactly one RoleSequence,
	RoleSequence is for Reading;
PresenceConstraint covers exactly one RoleSequence;

RoleValue = entity identified by Instance and Fact:
	Instance plays RoleValue,
	RoleValue is of exactly one Instance,
	RoleValue fulfils exactly one Fact;
RoleValue fulfils Fact;

SetConstraint = subtype of Constraint;

SubsetConstraint = subtype of SetConstraint;
SubsetConstraint covers exactly one superset-RoleSequence;
SubsetConstraint covers exactly one subset-RoleSequence;

UniquenessConstraint = subtype of PresenceConstraint;

Unit = entity identified by UnitId:
	Unit has exactly one UnitId,
	UnitId is of at most one Unit;
UnitBasis = Unit (as DerivedUnit) is derived from base-Unit (as BaseUnit) [acyclic, intransitive];
Unit has at most one Coefficient;
Name is of Unit,
	Unit is called exactly one Name;
Unit is fundamental;
UnitBasis has at most one Exponent;

ValueRange = entity identified by minimum-Bound and maximum-Bound:
	ValueRange has at most one minimum-Bound,
	ValueRange has at most one maximum-Bound;

ValueRestriction = entity identified by ValueRestrictionId:
	ValueRestriction has exactly one ValueRestrictionId,
	ValueRestrictionId is of at most one ValueRestriction;
AllowedRange = ValueRestriction allows at least one ValueRange;

FrequencyConstraint = subtype of PresenceConstraint;

MandatoryConstraint = subtype of PresenceConstraint;

SetComparisonConstraint = subtype of SetConstraint;
SetComparisonRoles = SetComparisonConstraint covers at least one RoleSequence;

SetEqualityConstraint = subtype of SetComparisonConstraint;

SetExclusionConstraint = subtype of SetComparisonConstraint;
SetExclusionConstraint is mandatory;

Feature = entity identified by Name and Vocabulary:
	Feature is called exactly one Name,
	Feature belongs to at most one Vocabulary,
	Vocabulary contains Feature;

Vocabulary = subtype of Feature;
Vocabulary extends at most one parent-Vocabulary [acyclic, intransitive],
	Vocabulary contains sub-Vocabulary;
Import = Vocabulary imports imported-Vocabulary [acyclic];
Vocabulary contains Constraint,
	Constraint belongs to at most one Vocabulary;
Correspondence = in Import imported-Feature corresponds to at most one local-Feature;

Alias = subtype of Feature;

Concept = subtype of Feature;
Role = entity identified by RoleId:
	Role has exactly one RoleId,
	RoleId is of at most one Role;
Role has at most one role-Name,
	role-Name is name of at least one Role;
Role has role at most one ValueRestriction,
	ValueRestriction applies to Role;
Role is of RingConstraint,
	RingConstraint has at most one Role;
other-Role is of RingConstraint,
	RingConstraint has at most one other-Role;
RoleRef = Role is in RoleSequence in at most one Ordinal place,
	RoleSequence includes at most one Role in Ordinal place,
	Role has Ordinal place in RoleSequence;
RoleValue is of exactly one Role;
RoleRef has at most one leading-Adjective;
RoleRef has at most one trailing-Adjective;
Instance is of exactly one Concept;

EntityType = subtype of Concept;
TypeInheritance = EntityType (as Subtype) is subtype of super-EntityType (as Supertype) [acyclic],
	Supertype is supertype of sub-Subtype;
EntityType is independent;
EntityType is personal;
EntityType nests at most one FactType,
	FactType is nested as at most one EntityType;
TypeInheritance provides identification;

Population = entity identified by Vocabulary and Name:
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

ValueType = subtype of Concept;
ValueType is subtype of at most one ValueType (as supertype) [acyclic],
	supertype is supertype of ValueType;
ValueType has at most one Length,
	Length is of ValueType;
ValueType has at most one Scale,
	Scale is of ValueType;
ValueType has at most one ValueRestriction;
ValueType is of at most one Unit;

/*
Constraints:
	REVISIT: Verbalise SetExclusionConstraint ConceptMayNotBeBothValueTypeAndEntityType REVISIT: Unhandled constraint type
	REVISIT: Verbalise SetExclusionConstraint ConstraintMustBeOneConcreteType REVISIT: Unhandled constraint type
	REVISIT: Verbalise PresenceConstraint EachFactHasAtLeastOneRoleValue min 1 mandatory over (Fact)
	REVISIT: Verbalise PresenceConstraint EachFactTypeHasAtLeastOneRole min 1 mandatory over (FactType)
	REVISIT: Verbalise PresenceConstraint EachRoleSequenceHasAtLeastOneRole min 1 mandatory over (RoleSequence)
	REVISIT: Verbalise SetExclusionConstraint ExclusiveOrConstraint1 REVISIT: Unhandled constraint type
	REVISIT: Verbalise PresenceConstraint ExternalUniquenessConstraint1 min 0 max 1 over (Name, Vocabulary)
	REVISIT: Verbalise SetExclusionConstraint FeatureMustBeVocabularyConceptOrRoleName REVISIT: Unhandled constraint type
	REVISIT: Verbalise PresenceConstraint OnlyOneSupertypeMayBePrimary min 0 max 1 over (Subtype, TypeInheritance)
	REVISIT: Verbalise SubsetConstraint PreferredIdentifierHasMaxFrequency REVISIT: Unhandled constraint type
	REVISIT: Verbalise PresenceConstraint PresenceConstraintMustHaveFrequency min 1 mandatory over (PresenceConstraint, PresenceConstraint, PresenceConstraint)
	REVISIT: Verbalise PresenceConstraint ValueRangeMustHaveAtLeastOneBound min 1 mandatory over (ValueRange, ValueRange)
	REVISIT: Verbalise SubsetConstraint ValueTypeWithLengthMayHaveScale REVISIT: Unhandled constraint type
 */
