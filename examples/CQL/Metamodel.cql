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
Bound = entity identified by Value and InclusiveBound:
	Bound has exactly one Value,
	Value is of at least one Bound,
	each Value is of some Bound,
	Bound (as InclusiveBound) is inclusive;

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

Reading = entity identified by Ordinal and FactType:
	Reading is in at most one Ordinal position,
	Ordinal reading for fact type is Reading,
	FactType has at least one Reading,
	each FactType has some Reading,
	Reading is for exactly one FactType;
Reading has exactly one ReadingText;

RingConstraint = subtype of Constraint;
RingConstraint is of exactly one RingType;

Role = entity identified by RoleId:
	Role has exactly one RoleId,
	RoleId is of at most one Role;
Role has at most one role-Name,
	role-Name is name of at least one Role,
	each role-Name is name of some Role;
Role is of RingConstraint,
	RingConstraint has at most one Role;
other-Role is of RingConstraint,
	RingConstraint has at most one other-Role;

RoleSequence = entity identified by RoleSequenceId:
	RoleSequence has exactly one RoleSequenceId,
	RoleSequenceId is of at most one RoleSequence;
Reading is in exactly one RoleSequence,
	RoleSequence is for Reading;
PresenceConstraint covers exactly one RoleSequence;

RoleValue = entity identified by Instance and Fact:
	Instance plays RoleValue,
	RoleValue is of exactly one Instance,
	RoleValue fulfils exactly one Fact,
	some RoleValue fulfils each Fact;
RoleValue is of exactly one Role;

SetConstraint = subtype of Constraint;

SubsetConstraint = subtype of SetConstraint;
SubsetConstraint covers exactly one superset-RoleSequence;
SubsetConstraint covers exactly one subset-RoleSequence;

UniquenessConstraint = subtype of PresenceConstraint;

Unit = entity identified by UnitId:
	Unit has exactly one UnitId,
	UnitId is of at most one Unit;
Unit has at most one Coefficient;
Name is of Unit,
	Unit is called exactly one Name;
Unit is fundamental;

UnitBasis = entity identified by base-Unit and Unit:
	Unit is derived from base-Unit [acyclic, intransitive];
UnitBasis has at most one Exponent;

ValueRange = entity identified by minimum-Bound and maximum-Bound:
	ValueRange has at most one minimum-Bound,
	ValueRange has at most one maximum-Bound;

ValueRestriction = entity identified by ValueRestrictionId:
	ValueRestriction has exactly one ValueRestrictionId,
	ValueRestrictionId is of at most one ValueRestriction;
AllowedRange = ValueRestriction allows at least one ValueRange,
	each ValueRestriction allows some ValueRange;
Role has at most one ValueRestriction,
	ValueRestriction applies to Role;

FrequencyConstraint = subtype of PresenceConstraint;

MandatoryConstraint = subtype of PresenceConstraint;

RoleRef = entity identified by RoleSequence and Ordinal:
	Role is in RoleSequence in at most one Ordinal place,
	RoleSequence includes at most one Role in Ordinal place,
	each RoleSequence includes some Role in some Ordinal place,
	Role has Ordinal place in RoleSequence;
RoleRef has at most one leading-Adjective;
RoleRef has at most one trailing-Adjective;

SetComparisonConstraint = subtype of SetConstraint;
SetComparisonRoles = SetComparisonConstraint covers at least one RoleSequence,
	each SetComparisonConstraint covers some RoleSequence;

SetEqualityConstraint = subtype of SetComparisonConstraint;

SetExclusionConstraint = subtype of SetComparisonConstraint;
SetExclusionConstraint is mandatory;

Feature = entity identified by Name and Vocabulary:
	Feature is called exactly one Name,
	Feature belongs to at most one Vocabulary,
	Vocabulary contains Feature;

Vocabulary = subtype of Feature;
parent-Vocabulary contains Vocabulary [acyclic, intransitive],
	Vocabulary extends at most one parent-Vocabulary;
Vocabulary contains Constraint,
	Constraint belongs to at most one Vocabulary;

Alias = subtype of Feature;

Concept = subtype of Feature;
Instance is of exactly one Concept;

EntityType = subtype of Concept;
EntityType is independent;
EntityType is personal;
EntityType nests at most one FactType,
	FactType is nested as at most one EntityType;

Import = entity identified by imported-Vocabulary and Vocabulary:
	Vocabulary imports imported-Vocabulary [acyclic];
Correspondence = in Import imported-Feature corresponds to at most one local-Feature;

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

TypeInheritance = subtype of FactType identified by EntityType and super-EntityType:
	super-EntityType is supertype of EntityType [acyclic],
	EntityType is subtype of super-EntityType;
TypeInheritance provides identification;

ValueType = subtype of Concept;
ValueType is subtype of at most one ValueType [acyclic],
	ValueType is supertype of ValueType;
ValueType has at most one Length,
	Length is of ValueType;
ValueType has at most one Scale,
	Scale is of ValueType;
ValueType has at most one ValueRestriction;
ValueType is of at most one Unit;

/*
Constraints:
	MandatoryExclusionConstraint ConceptMayNotBeBothValueTypeAndEntityType over EntityTypeIsASubtypeOfConcept(Concept), ValueTypeIsASubtypeOfConcept(Concept)
	MandatoryExclusionConstraint ConstraintMustBeOneConcreteType over RingConstraintIsASubtypeOfConstraint(Constraint), SetEqualityConstraintIsASubtypeOfSetComparisonConstraint(SetComparisonConstraint), SetExclusionConstraintIsASubtypeOfSetComparisonConstraint(SetComparisonConstraint), SubsetConstraintIsASubtypeOfSetConstraint(SetConstraint), PresenceConstraintIsASubtypeOfConstraint(Constraint)
	EachFactTypeHasAtLeastOneRole: in Role, each value (FactType) must occur at least 1 time
	MandatoryExclusionConstraint ExclusiveOrConstraint1 over UnitIsFundamental(Unit), UnitBasis(Unit)
	ExternalUniquenessConstraint1: each combination(NameIsOfConstraint.Name, VocabularyContainsConstraint.Vocabulary) may occur at most 1 time
	MandatoryExclusionConstraint FeatureMustBeVocabularyConceptOrRoleName over VocabularyIsASubtypeOfFeature(Feature), ConceptIsASubtypeOfFeature(Feature), AliasIsASubtypeOfFeature(Feature)
	OnlyOneSupertypeMayBePrimary: each combination(TypeInheritance.EntityType, TypeInheritanceDefinesPrimarySupertype.TypeInheritance) may occur at most 1 time
	SubsetConstraint PreferredIdentifierHasMaxFrequency PresenceConstraintHasMaxFrequency(PresenceConstraint) < PresenceConstraintIsPreferredIdentifier(PresenceConstraint)
	PresenceConstraintMustHaveFrequency: each combination(PresenceConstraintHasMinFrequency.PresenceConstraint, PresenceConstraintHasMaxFrequency.PresenceConstraint, PresenceConstraintIsMandatory.PresenceConstraint) must occur at least 1 time
	ValueRangeMustHaveAtLeastOneBound: each combination(ValueRangeHasMinimumBound.ValueRange, ValueRangeHasMaximumBound.ValueRange) must occur at least 1 time
	SubsetConstraint ValueTypeWithLengthMayHaveScale ValueTypeHasLength(ValueType) < ValueTypeHasScale(ValueType)
 */
