vocabulary Metamodel;

/*
 * Value Types
 */
Adjective is written as VariableLengthText(64);
AgentName is written as VariableLengthText;
Assimilation is written as VariableLengthText restricted to {'partitioned', 'separate'};
ConstraintId is written as AutoCounter;
ContextNoteId is written as AutoCounter;
ContextNoteKind is written as VariableLengthText restricted to {'as_opposed_to', 'because', 'so_that', 'to_avoid'};
Date is written as Date;
Denominator is written as UnsignedInteger(32);
Discussion is written as VariableLengthText;
DisplayRoleNamesSetting is written as VariableLengthText restricted to {'false', 'true'};
EnforcementCode is written as VariableLengthText(16);
EphemeraURL is written as VariableLengthText;
Exponent is written as SignedSmallInteger(32);
FactId is written as AutoCounter;
FactTypeId is written as AutoCounter;
Frequency is written as UnsignedInteger(32);
InstanceId is written as AutoCounter;
Length is written as UnsignedInteger(32);
Literal is written as VariableLengthText;
Name is written as VariableLengthText(64);
Numerator is written as Decimal;
Offset is written as Decimal;
Ordinal is written as UnsignedSmallInteger(32);
Pronoun is written as VariableLengthText(20) restricted to {'feminine', 'masculine', 'neuter', 'personal'};
RingType is written as VariableLengthText;
RoleSequenceId is written as AutoCounter;
RotationSetting is written as VariableLengthText restricted to {'left', 'right'};
Scale is written as UnsignedInteger(32);
ShapeId is written as AutoCounter;
Text is written as VariableLengthText(256);
UnitId is written as AutoCounter;
X is written as SignedInteger(32);
Y is written as SignedInteger(32);

/*
 * Entity Types
 */
Agent is identified by its Name;

Coefficient is identified by Numerator and Denominator and Coefficient is precise where
	Coefficient has one Numerator,
	Coefficient has one Denominator,
	Coefficient is precise;

Constraint is identified by its Id;
Name is of Constraint,
	Constraint is called at most one Name;

ContextNote is identified by its Id;
Constraint has ContextNote,
	ContextNote applies to at most one Constraint;
ContextNote has one ContextNoteKind,
	ContextNoteKind is of ContextNote;
ContextNote has one Discussion,
	Discussion is for ContextNote;

Enforcement is identified by Constraint where
	Constraint requires at most one Enforcement,
	Enforcement applies to one Constraint;
Enforcement notifies at most one Agent;
Enforcement has one EnforcementCode,
	EnforcementCode is of Enforcement;

Fact is identified by its Id;

FactType is identified by its Id;
Fact is of one FactType;
FactType has ContextNote,
	ContextNote applies to at most one FactType;

Instance is identified by its Id;
Instance objectifies at most one Fact,
	Fact is objectified as at most one Instance;

Position is identified by X and Y where
	Position is at one X,
	Position is at one Y;

PresenceConstraint is a kind of Constraint;
PresenceConstraint has at most one max-Frequency restricted to {1..};
PresenceConstraint has at most one min-Frequency restricted to {2..};
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

Role is where
	FactType has at least one Ordinal role;
Role is of RingConstraint,
	RingConstraint has at most one Role;
Role has at most one role-Name,
	role-Name is name of at least one Role;
other-Role is of RingConstraint;
other-Role is of RingConstraint,
	RingConstraint has at most one other-Role;

RoleSequence is identified by its Id;
PresenceConstraint covers one RoleSequence;
Reading is in one RoleSequence,
	RoleSequence is for Reading;
RoleSequence has unused dependency to force table in norma;

RoleValue is identified by Instance and Fact where
	Instance plays RoleValue,
	RoleValue is of one Instance,
	RoleValue fulfils one Fact,
	Fact includes at least one RoleValue;
RoleValue is of one Role;

SetConstraint is a kind of Constraint;

Shape is identified by its Id;
Shape is at at most one Position;
Shape is expanded;

SubsetConstraint is a kind of SetConstraint;
SubsetConstraint covers one subset-RoleSequence;
SubsetConstraint covers one superset-RoleSequence;

Unit is identified by its Id;
EphemeraURL provides Unit coefficient,
	Unit uses coefficient from at most one EphemeraURL;
Name is of Unit,
	Unit is called one Name;
Unit has at most one Coefficient;
Unit has at most one Offset;
Unit is ephemeral;
Unit is fundamental;

Value is identified by Literal and Value is a string and Unit where
	Value is represented by one Literal,
	Literal represents Value,
	Value is a string,
	Value is in at most one Unit,
	Unit is of Value;
Instance has at most one Value;

ValueConstraint is a kind of Constraint;
Role has at most one role-ValueConstraint,
	ValueConstraint applies to at most one Role;

Vocabulary is identified by Name where
	Vocabulary is called one Name;
Vocabulary contains Constraint,
	Constraint belongs to at most one Vocabulary;
Vocabulary includes Unit,
	Unit is in one Vocabulary;

Agreement is identified by ContextNote where
	ContextNote was added by at most one Agreement,
	Agreement covers one ContextNote;
Agreement was on at most one Date,
	Date is of Agreement;

Bound is identified by Value and Bound is inclusive where
	Bound has one Value,
	Value is of at least one Bound,
	Bound is inclusive;

Concept is identified by Vocabulary and Name where
	Concept belongs to one Vocabulary,
	Vocabulary contains Concept,
	Concept is called one Name;
Concept has ContextNote,
	ContextNote applies to at most one Concept;
Concept uses at most one Pronoun;
Concept plays Role,
	Role is played by one Concept;
Concept is independent;
Instance is of one Concept;

ConstraintShape is a kind of Shape;
ConstraintShape is for one Constraint;

ContextAccordingTo is where
	ContextNote is according to Agent,
	Agent claims ContextNote;

ContextAgreedBy is where
	Agreement was reached by Agent,
	Agent agreed on Agreement;

Derivation is where
	Unit (as DerivedUnit) is derived from base-Unit (as BaseUnit) [acyclic, intransitive];
Derivation has at most one Exponent;

Diagram is identified by Vocabulary and Name where
	Diagram is for one Vocabulary,
	Vocabulary contains Diagram,
	Diagram is called one Name,
	Name is of Diagram;
Shape is in one Diagram,
	Diagram includes Shape;

EntityType is a kind of Concept;
EntityType nests at most one FactType,
	FactType is nested as at most one EntityType;

FactTypeShape is a kind of Shape;
FactTypeShape has at most one DisplayRoleNamesSetting;
FactTypeShape is for one FactType,
	FactType has FactTypeShape;
FactTypeShape has at most one RotationSetting;

ModelNoteShape is a kind of Shape;
ModelNoteShape is for one ContextNote;

ObjectTypeShape is a kind of Shape;
ObjectTypeShape is for one Concept,
	Concept has ObjectTypeShape;
ObjectTypeShape has expanded reference mode;

ObjectifiedFactTypeNameShape is a kind of Shape identified by FactTypeShape where
	ObjectifiedFactTypeNameShape is for one FactTypeShape,
	FactTypeShape has at most one ObjectifiedFactTypeNameShape;

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

ReadingShape is a kind of Shape identified by FactTypeShape where
	FactTypeShape has at most one ReadingShape,
	ReadingShape is for one FactTypeShape;
ReadingShape is for one Reading,
	Reading has ReadingShape;

RingConstraintShape is a kind of ConstraintShape;
RingConstraintShape is attached to one FactType;

RoleDisplay is where
	FactTypeShape displays Role in Ordinal position,
	FactTypeShape displays in Ordinal position at most one Role;

RoleNameShape is a kind of Shape;
RoleNameShape is for one RoleDisplay,
	RoleDisplay has at most one RoleNameShape;

RoleRef is where
	RoleSequence in Ordinal position includes at most one Role,
	Role is in RoleSequence in at most one Ordinal place,
	RoleSequence includes Role in Ordinal place,
	Role has Ordinal place in RoleSequence;
RoleRef has at most one leading-Adjective;
RoleRef has at most one trailing-Adjective;

SetComparisonConstraint is a kind of SetConstraint;

SetComparisonRoles is where
	SetComparisonConstraint has in Ordinal position at most one RoleSequence,
	RoleSequence is Ordinal in SetComparisonConstraint,
	in Ordinal position SetComparisonConstraint has RoleSequence,
	SetComparisonConstraint has RoleSequence in at most one Ordinal position;

SetEqualityConstraint is a kind of SetComparisonConstraint;

SetExclusionConstraint is a kind of SetComparisonConstraint;
SetExclusionConstraint is mandatory;

TypeInheritance is a kind of FactType identified by Subtype and Supertype where
	EntityType (as Subtype) is subtype of super-EntityType (as Supertype) [acyclic],
	Supertype is supertype of Subtype;
Assimilation applies to TypeInheritance,
	TypeInheritance uses at most one Assimilation;
TypeInheritance provides identification;

ValueConstraintShape is a kind of ConstraintShape;
RoleDisplay has at most one ValueConstraintShape,
	ValueConstraintShape is for at most one RoleDisplay;
ValueConstraintShape is for at most one ObjectTypeShape,
	ObjectTypeShape has ValueConstraintShape;

ValueRange is identified by minimum-Bound and maximum-Bound where
	ValueRange has at most one minimum-Bound,
	ValueRange has at most one maximum-Bound;

ValueType is a kind of Concept;
ValueType has at most one Length,
	Length is of ValueType;
ValueType has at most one Scale,
	Scale is of ValueType;
ValueType is of at most one Unit;
ValueType has at most one ValueConstraint,
	ValueConstraint constrains at most one ValueType;
ValueType is subtype of at most one super-ValueType (as Supertype) [acyclic],
	Supertype is supertype of ValueType;

AllowedRange is where
	ValueConstraint allows at least one ValueRange;

Join is where
	RoleRef has Ordinal (as JoinStep) join;
Join traverses at most one Concept,
	Concept is traversed by Join;
Join has at most one input-Role;
is anti Join;
Join has at most one output-Role;
Join is outer;

Parameter is where
	Name is a parameter of ValueType,
	ValueType has parameter called Name;

ParamValue is where
	Value for Parameter applies to at most one ValueType;

/*
 * Constraints:
 */
either Concept is an EntityType or Concept is a ValueType but not both;
for each Constraint exactly one of these holds:
	PresenceConstraint is a kind of Constraint,
	SetConstraint is a kind of Constraint,
	RingConstraint is a kind of Constraint;
for each ContextNote exactly one of these holds:
	Concept has ContextNote,
	FactType has ContextNote,
	Constraint has ContextNote;
for each Instance at most one of these holds:
	Instance has Value,
	Instance objectifies Fact;
Instance plays RoleValue and Instance is of Concept
	if and only if
	RoleValue is of Role and Concept plays Role;
RoleValue fulfils Fact and Fact is of FactType
	if and only if
	RoleValue is of Role and FactType has Ordinal role;
either SetComparisonConstraint is a SetExclusionConstraint or SetComparisonConstraint is a SetEqualityConstraint but not both;
either SetConstraint is a SetComparisonConstraint or SetConstraint is a SubsetConstraint but not both;
either Unit is fundamental or Unit is derived from base-Unit but not both;
either Unit uses coefficient from EphemeraURL or Unit has Coefficient but not both;
either ValueConstraintShape is for ObjectTypeShape or ValueConstraintShape is for RoleDisplay but not both;
either ValueConstraint constrains ValueType or ValueConstraint applies to Role but not both;
PresenceConstraint is preferred identifier
	only if PresenceConstraint has max-Frequency;
ValueType has Scale
	only if ValueType has Length;
either Agreement was reached by Agent or Agreement was on Date;
each combination Diagram, Position occurs at most one time in
	Shape is in Diagram,
	Shape is at Position;
each combination EntityType, TypeInheritance occurs at most one time in
	EntityType is subtype of super-EntityType,
	TypeInheritance provides identification;
either Join has input-Role or Join has output-Role;
each PresenceConstraint occurs at least one time in
	PresenceConstraint has min-Frequency,
	PresenceConstraint has max-Frequency,
	PresenceConstraint is mandatory;
each RoleSequence occurs at least one time in
	RoleSequence in Ordinal position includes Role;
each SetComparisonConstraint occurs at least 2 times in
	SetComparisonConstraint has in Ordinal position RoleSequence;
either ValueRange has minimum-Bound or ValueRange has maximum-Bound;
each combination Vocabulary, Name occurs at most one time in
	Vocabulary contains Constraint,
	Name is of Constraint;
each combination Vocabulary, Name occurs at most one time in
	Vocabulary includes Unit,
	Name is of Unit;
