vocabulary Metamodel;

/*
 * Value Types
 */
Adjective is written as String(64);
Agent Name is written as String;
Assimilation is written as String restricted to {'partitioned', 'separate'};
Constraint Id is written as Auto Counter;
Context Note Id is written as Auto Counter;
Context Note Kind is written as String restricted to {'as_opposed_to', 'because', 'so_that', 'to_avoid'};
Date is written as Date;
Denominator is written as Unsigned Integer(32);
Discussion is written as String;
Display Role Names Setting is written as String restricted to {'false', 'true'};
Enforcement Code is written as String(16);
Ephemera URL is written as String;
Exponent is written as Signed Integer(16);
Fact Id is written as Auto Counter;
Fact Type Id is written as Auto Counter;
Frequency is written as Unsigned Integer(32);
Instance Id is written as Auto Counter;
Join Id is written as Auto Counter;
Length is written as Unsigned Integer(32);
Literal is written as String;
Name is written as String(64);
Numerator is written as Decimal;
Offset is written as Decimal;
Ordinal is written as Unsigned Integer(16);
Pronoun is written as String(20) restricted to {'feminine', 'masculine', 'neuter', 'personal'};
Ring Type is written as String;
Role Sequence Id is written as Auto Counter;
Rotation Setting is written as String restricted to {'left', 'right'};
Scale is written as Unsigned Integer(32);
Shape Id is written as Auto Counter;
Subscript is written as Unsigned Integer(16);
Text is written as String(256);
Transaction Timing is written as String restricted to {'assert', 'commit'};
Unit Id is written as Auto Counter;
X is written as Signed Integer(32);
Y is written as Signed Integer(32);

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

Context Note is identified by its Id;
Constraint has Context Note,
	Context Note applies to at most one Constraint;
Context Note has one Context Note Kind,
	Context Note Kind is of Context Note;
Context Note has one Discussion,
	Discussion is for Context Note;

Enforcement is identified by Constraint where
	Constraint requires at most one Enforcement,
	Enforcement applies to one Constraint;
Enforcement notifies at most one Agent;
Enforcement has one Enforcement Code,
	Enforcement Code is of Enforcement;

Fact is identified by its Id;

Fact Type is identified by its Id;
Fact is of one Fact Type;
Fact Type has Context Note,
	Context Note applies to at most one Fact Type;

Implicit Fact Type is a kind of Fact Type;

Instance is identified by its Id;
Instance objectifies at most one Fact,
	Fact is objectified as at most one Instance;

Join is identified by its Id;

Join Node is identified by Join and Ordinal where
	Join includes Join Node,
	Join Node is in one Join,
	Join Node has one Ordinal position;
Join Node has at most one Subscript,
	Subscript is of Join Node;
Join Node has at most one role-Name,
	Name is of Join Node;

Position is identified by X and Y where
	Position is at one X,
	Position is at one Y;

Presence Constraint is a kind of Constraint;
Presence Constraint has at most one max-Frequency restricted to {1..};
Presence Constraint has at most one min-Frequency restricted to {2..};
Presence Constraint is mandatory;
Presence Constraint is preferred identifier;

Reading is identified by Fact Type and Ordinal where
	Fact Type has Reading,
	Reading is for one Fact Type,
	Reading is in one Ordinal position,
	Ordinal reading for fact type is Reading;
Reading has one Text;

Ring Constraint is a kind of Constraint;
Ring Constraint is of one Ring Type;

Role is where
	Fact Type has at least one Ordinal role;
Implicit Fact Type is implied by one Role (as Implying Role),
	Implying Role implies at most one Implicit Fact Type;
Ring Constraint has at most one other-Role,
	other-Role is of Ring Constraint;
Role is of Ring Constraint;  // Avoid ambiguity; this is a new fact type
Role is of Ring Constraint,
	Ring Constraint has at most one Role;
Role has at most one role-Name,
	role-Name is name of at least one Role;

Role Sequence is identified by its Id;
Presence Constraint covers one Role Sequence;
Reading is in one Role Sequence,
	Role Sequence is for Reading;
Role Sequence has unused dependency to force table in norma;

Role Value is identified by Instance and Fact where
	Instance plays Role Value,
	Role Value is of one Instance,
	Role Value fulfils one Fact,
	Fact includes at least one Role Value;
Role Value is of one Role;

Set Constraint is a kind of Constraint;

Shape is identified by its Id;
Shape is at at most one Position;
Shape is expanded;

Subset Constraint is a kind of Set Constraint;
Subset Constraint covers one subset-Role Sequence;
Subset Constraint covers one superset-Role Sequence;

Unit is identified by its Id;
Ephemera URL provides Unit coefficient,
	Unit uses coefficient from at most one Ephemera URL;
Name is of Unit,
	Unit is called one Name;
Unit has at most one Coefficient;
Unit has at most one Offset;
Unit has at most one plural-Name;
Unit is fundamental;

Value is identified by Literal and Value is a string and Unit where
	Value is represented by one Literal,
	Literal represents Value,
	Value is a string,
	Value is in at most one Unit,
	Unit is of Value;
Instance has at most one Value;
Join Node has at most one Value;

Value Constraint is a kind of Constraint;
Role has at most one role-Value Constraint,
	Value Constraint applies to at most one Role;

Vocabulary is identified by Name where
	Vocabulary is called one Name;
Vocabulary contains Constraint,
	Constraint belongs to at most one Vocabulary;
Vocabulary includes Unit,
	Unit is in one Vocabulary;

Agreement is identified by Context Note where
	Context Note was added by at most one Agreement,
	Agreement covers one Context Note;
Agreement was on at most one Date,
	Date is of Agreement;

Bound is identified by Value and Bound is inclusive where
	Bound has one Value,
	Value is of at least one Bound,
	Bound is inclusive;

Constraint Shape is a kind of Shape;
Constraint Shape is for one Constraint;

Context According To is where
	Context Note is according to Agent,
	Agent claims Context Note;
Context According To was lodged on at most one Date;

Context Agreed By is where
	Agreement was reached by Agent,
	Agent agreed on Agreement;

Derivation is where
	Unit (as Derived Unit) is derived from base-Unit (as Base Unit) [acyclic, intransitive];
Derivation has at most one Exponent;

Diagram is identified by Vocabulary and Name where
	Diagram is for one Vocabulary,
	Vocabulary contains Diagram,
	Diagram is called one Name,
	Name is of Diagram;
Shape is in one Diagram,
	Diagram includes Shape;

Fact Type Shape is a kind of Shape;
Fact Type Shape has at most one Display Role Names Setting;
Fact Type Shape is for one Fact Type,
	Fact Type has Fact Type Shape;
Fact Type Shape has at most one Rotation Setting;

Join Role is independent where
	Join Node includes at least one Role,
	Role connects to Join Node;

Join Step is identified by input-Join Role and output-Join Role where
	Join Step has one input-Join Role,
	Join Step has one output-Join Role;
Join Step traverses one Fact Type,
	Fact Type directs Join Step;
Join Step involves incidental-Join Role,
	Join Role is incidentally involved in at most one Join Step;
is anti Join Step;
Join Step is outer;

Model Note Shape is a kind of Shape;
Model Note Shape is for one Context Note;

Object Type is identified by Vocabulary and Name where
	Object Type belongs to one Vocabulary,
	Vocabulary contains Object Type,
	Object Type is called one Name;
Instance is of one Object Type;
Join Node is for one Object Type,
	Object Type is referenced in Join Node;
Object Type has Context Note,
	Context Note applies to at most one Object Type;
Object Type uses at most one Pronoun;
Object Type plays Role,
	Role is played by one Object Type;
Object Type is independent;

Object Type Shape is a kind of Shape;
Object Type Shape is for one Object Type,
	Object Type has Object Type Shape;
Object Type Shape has expanded reference mode;

Objectified Fact Type Name Shape is a kind of Shape identified by Fact Type Shape where
	Objectified Fact Type Name Shape is for one Fact Type Shape,
	Fact Type Shape has at most one Objectified Fact Type Name Shape;

Population is identified by Vocabulary and Name where
	Vocabulary includes Population,
	Population belongs to at most one Vocabulary,
	Population has one Name,
	Name is of Population;
Population includes Fact,
	Fact belongs to one Population;
Population includes Instance,
	Instance belongs to one Population;
Population includes Role Value,
	Role Value belongs to one Population;

Reading Shape is a kind of Shape identified by Fact Type Shape where
	Fact Type Shape has at most one Reading Shape,
	Reading Shape is for one Fact Type Shape;
Reading Shape is for one Reading,
	Reading has Reading Shape;

Ring Constraint Shape is a kind of Constraint Shape;
Ring Constraint Shape is attached to one Fact Type;

Role Display is where
	Fact Type Shape displays Role in Ordinal position,
	Fact Type Shape displays in Ordinal position one Role;

Role Name Shape is a kind of Shape;
Role Name Shape is for one Role Display,
	Role Display has at most one Role Name Shape;

Role Ref is where
	Role Sequence in Ordinal position includes one Role,
	Role is in Role Sequence in one Ordinal place,
	Role Sequence includes Role in Ordinal place,
	Role has Ordinal place in Role Sequence;
Join Role projects at most one Role Ref;
Role Ref has at most one leading-Adjective;
Role Ref has at most one trailing-Adjective;

Set Comparison Constraint is a kind of Set Constraint;

Set Comparison Roles is where
	Set Comparison Constraint has in Ordinal position one Role Sequence,
	Role Sequence is Ordinal in Set Comparison Constraint,
	in Ordinal position Set Comparison Constraint has Role Sequence,
	Set Comparison Constraint has Role Sequence in one Ordinal position;

Set Equality Constraint is a kind of Set Comparison Constraint;

Set Exclusion Constraint is a kind of Set Comparison Constraint;
Set Exclusion Constraint is mandatory;

Value Constraint Shape is a kind of Constraint Shape;
Role Display has at most one Value Constraint Shape,
	Value Constraint Shape is for at most one Role Display;
Value Constraint Shape is for at most one Object Type Shape,
	Object Type Shape has Value Constraint Shape;

Value Range is identified by minimum-Bound and maximum-Bound where
	Value Range has at most one minimum-Bound,
	Value Range has at most one maximum-Bound;

Value Type is a kind of Object Type;
Value Type has at most one Length,
	Length is of Value Type;
Value Type has at most one Scale,
	Scale is of Value Type;
Value Type is of at most one Unit;
Value Type has at most one Value Constraint,
	Value Constraint constrains at most one Value Type;
Value Type has at most one auto- assigned Transaction Timing;
Value Type is subtype of at most one super-Value Type (as Supertype) [acyclic],
	Supertype is supertype of Value Type;

Allowed Range is where
	Value Constraint allows at least one Value Range;

Entity Type is a kind of Object Type;
Entity Type nests at most one Fact Type,
	Fact Type is nested as at most one Entity Type;

Facet is where
	Value Type has facet called Name,
	Name is a facet of Value Type;

Facet Value is where
	Value Type defines Facet as having one Value,
	Value for Facet applies to Value Type;

Implicit Boolean Value Type is a kind of Value Type;

Type Inheritance is a kind of Fact Type identified by Subtype and Supertype where
	Entity Type (as Subtype) is subtype of super-Entity Type (as Supertype) [acyclic, intransitive],
	Supertype is supertype of Subtype;
Assimilation applies to Type Inheritance,
	Type Inheritance uses at most one Assimilation;
Type Inheritance provides identification;

/*
 * Constraints:
 */
for each Constraint exactly one of these holds:
	Constraint is a Presence Constraint,
	Constraint is a Set Constraint,
	Constraint is a Ring Constraint;
for each Context Note exactly one of these holds:
	Context Note applies to Object Type,
	Context Note applies to Fact Type,
	Context Note applies to Constraint;
either Object Type is an Entity Type or Object Type is a Value Type but not both;
for each Role Sequence exactly one of these holds:
	Role Sequence is for Reading,
	Presence Constraint covers Role Sequence,
	Subset Constraint(1) covers subset-Role Sequence,
	Subset Constraint(2) covers superset-Role Sequence,
	Role Sequence is Ordinal in Set Comparison Constraint;
either Set Comparison Constraint is a Set Exclusion Constraint or Set Comparison Constraint is a Set Equality Constraint but not both;
either Set Constraint is a Set Comparison Constraint or Set Constraint is a Subset Constraint but not both;
either Unit uses coefficient from Ephemera URL or Unit has Coefficient but not both;
either Unit is fundamental or Unit is derived from base-Unit but not both;
either Value Constraint Shape is for Object Type Shape or Value Constraint Shape is for Role Display but not both;
either Value Constraint constrains Value Type or Value Constraint applies to Role but not both;
for each Instance at most one of these holds:
	Instance has Value,
	Instance objectifies Fact;
for each Join Role at most one of these holds:
	Join Step(1) has input-Join Role,
	Join Role is incidentally involved in Join Step;
for each Join Role at most one of these holds:
	Join Step(1) has output-Join Role,
	Join Role is incidentally involved in Join Step;
Join Node is for Object Type that plays Role
	if and only if
	Join Node includes Role;
Role Value is of Instance that is of Object Type
	if and only if
	Role Value is of Role that is played by Object Type;
Role Value fulfils Fact that is of Fact Type
	if and only if
	Role Value is of Role (where Fact Type has Ordinal role);
Presence Constraint is preferred identifier
	only if Presence Constraint has max Frequency;
Value Type has Scale
	only if Value Type has Length;
either Agreement was reached by Agent or Agreement was on Date;
each combination Diagram, Position occurs at most one time in
	Shape is in Diagram,
	Shape is at Position;
each combination Entity Type(1), Type Inheritance occurs at most one time in
	Entity Type(1) is subtype of super Entity Type(2),
	Type Inheritance provides identification;
each Presence Constraint occurs at least one time in
	Presence Constraint has min Frequency(2),
	Presence Constraint has max Frequency(1),
	Presence Constraint is mandatory;
each Role Ref occurs at most one time in
	Join Role projects Role Ref;
each Role Sequence occurs at least one time in
	Role Sequence in Ordinal position includes Role;
each Set Comparison Constraint occurs at least 2 times in
	Set Comparison Constraint has in Ordinal position Role Sequence;
either Value Range has minimum Bound(2) or Value Range has maximum Bound(1);
each combination Vocabulary, Name occurs at most one time in
	Constraint belongs to Vocabulary,
	Constraint is called Name;
each combination Vocabulary, Name occurs at most one time in
	Unit is in Vocabulary,
	Unit is called Name;
