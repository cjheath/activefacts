vocabulary Metamodel;

/*
 * Value Types
 */
Adjective is written as String(64);
Agent Name is written as String;
Assimilation is written as String restricted to {'absorbed', 'partitioned', 'separate'};
Context Note Kind is written as String restricted to {'as_opposed_to', 'because', 'so_that', 'to_avoid'};
Date is written as Date;
Denominator is written as Unsigned Integer(32);
Discussion is written as String;
Display Role Names Setting is written as String restricted to {'false', 'true'};
Enforcement Code is written as String(16);
Ephemera URL is written as String;
Exponent is written as Signed Integer(16);
Frequency is written as Unsigned Integer(32);
GUID is written as String;
Language Code is written as Char(3);
Length is written as Unsigned Integer(32);
Literal is written as String;
Name is written as String(64);
Numerator is written as Decimal;
Offset is written as Decimal;
Position is written as Unsigned Integer(16);
Pronoun is written as String(20) restricted to {'feminine', 'masculine', 'neuter', 'personal'};
Ring Type is written as String;
Rotation Setting is written as String restricted to {'left', 'right'};
SID is written as GUID;
Scale is written as Unsigned Integer(32);
Subscript is written as Unsigned Integer(16);
Text is written as String(256);
Transaction Timing is written as String restricted to {'assert', 'commit'};
Unit Code is written as Char;
X is written as Signed Integer(32);
Y is written as Signed Integer(32);

/*
 * Entity Types
 */
Agent is identified by its Name;

Alternatives is identified by GUID where
	Alternatives has one GUID,
	GUID is of at most one Alternatives;
Alternatives are exclusive;

Coefficient is identified by Numerator and Denominator and Coefficient is precise where
	Coefficient has one Numerator,
	Coefficient has one Denominator,
	Coefficient is precise;

Concept is identified by SID where
	Concept has one SID,
	SID is of at most one Concept;
Concept has at most one model-Name;

Constraint is a kind of Concept [separate];
Name is of Constraint,
	Constraint is called at most one Name;

Context Note is identified by SID where
	Context Note has one SID,
	SID is of at most one Context Note;
Concept has Context Note,
	Context Note applies to at most one Concept;
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

Fact is a kind of Concept [separate];

Fact Type is a kind of Concept [separate];
Fact is of one Fact Type;

Implicit Fact Type is a kind of Fact Type;

Instance is a kind of Concept;
Instance objectifies at most one Fact,
	Fact is objectified as at most one Instance;

Language is identified by its Code;

Location is identified by X and Y where
	Location is at one X,
	Location is at one Y;

ObjectType is a kind of Concept;
Instance is of one ObjectType;
ObjectType is independent;

Presence Constraint is a kind of Constraint [partitioned];
Presence Constraint has at most one max-Frequency restricted to {1..};
Presence Constraint has at most one min-Frequency restricted to {2..};
Presence Constraint is mandatory;
Presence Constraint is preferred identifier;

Query is independent identified by GUID where
	Query has one GUID,
	GUID is of at most one Query;

Reading is identified by Fact Type and Position where
	Fact Type has Reading,
	Reading is for one Fact Type,
	Reading is in one Position,
	Position is of Reading;
Reading has one leading-Text;

Ring Constraint is a kind of Constraint [partitioned];
Ring Constraint is of one Ring Type;

Role is a kind of Concept identified by Fact Type and Position [separate] where
	Fact Type includes role of at least one ObjectType,
	ObjectType plays role in Fact Type,
	Role is in at most one Position,
	Position is occupied by at least one Role;
Implicit Fact Type is implied by one Role (as Implying Role),
	Implying Role implies at most one Implicit Fact Type;
Ring Constraint has at most one other-Role,
	other-Role is of Ring Constraint;
Role is of Ring Constraint;  // Avoid ambiguity; this is a new fact type
Role is of Ring Constraint,
	Ring Constraint has at most one Role;

Role Sequence is identified by GUID where
	Role Sequence has one GUID,
	GUID is of at most one Role Sequence;
Presence Constraint covers one Role Sequence;
Role Sequence has unused dependency to force table in norma;

Role Value is identified by Instance and Fact where
	Instance plays Role Value,
	Role Value is of one Instance,
	Role Value fulfils one Fact,
	Fact includes Role Value;
Role Value is of one Role;

Set Constraint is a kind of Constraint [partitioned];

Shape is identified by SID where
	Shape has one SID,
	SID is of at most one Shape;
Shape is at at most one Location;
Shape is expanded;

Subset Constraint is a kind of Set Constraint;
Subset Constraint covers one subset-Role Sequence;
Subset Constraint covers one superset-Role Sequence;

Topic is identified by Name where
	Topic has one Name,
	Name is of at most one Topic;

Unit is identified by its Code;
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
Instance has at most one Value,
	Value is of Instance;

Value Constraint is a kind of Constraint [partitioned];
Role has at most one role-Value Constraint,
	Value Constraint applies to at most one Role;

Variable is identified by Query and Position where
	Query includes Variable,
	Variable is in one Query,
	Variable occupies one Position,
	Position is occupied by Variable;
Variable references one ObjectType,
	ObjectType is referenced in Variable;
Variable projects at most one Role;
Variable has at most one Subscript,
	Subscript is of Variable;
Variable is bound to at most one Value;
Variable has at most one role-Name,
	Name is of Variable;

Vocabulary is identified by Topic and Language where
	Topic is described in Vocabulary,
	Vocabulary describes one Topic,
	Language provides Vocabulary,
	Vocabulary uses at most one Language;
Reading is for at most one Vocabulary,
	Vocabulary contains Reading;
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

Data Type is a kind of ObjectType;

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

Domain Object Type is a kind of ObjectType;
Domain Object Type uses at most one Pronoun;

Entity Type is a kind of Domain Object Type;
Entity Type objectifies at most one Fact Type,
	Fact Type is objectified as at most one Entity Type;
Entity Type results from implicit objectification;

Fact Type Shape is a kind of Shape;
Fact Type Shape has at most one Display Role Names Setting;
Fact Type Shape is for one Fact Type,
	Fact Type has Fact Type Shape;
Fact Type Shape has at most one Rotation Setting;

Model Note Shape is a kind of Shape;
Model Note Shape is for one Context Note;

Object Type Shape is a kind of Shape;
Object Type Shape is for one Domain Object Type,
	Domain Object Type has Object Type Shape;
Object Type Shape has expanded reference mode;

Objectified Fact Type Name Shape is a kind of Shape identified by Fact Type Shape where
	Objectified Fact Type Name Shape is for one Fact Type Shape,
	Fact Type Shape has at most one Objectified Fact Type Name Shape;

Population is identified by Topic and Name where
	Topic includes Population,
	Population belongs to at most one Topic,
	Population has one Name,
	Name is of Population;
Population includes Fact,
	Fact belongs to one Population;
Population includes Instance,
	Instance belongs to one Population;
Population includes Role Value,
	Role Value belongs to one Population;

ReadingRole is where
	Role has Position in Reading;
ReadingRole has at most one following-Text;
ReadingRole has at most one leading-Adjective;
ReadingRole has at most one trailing-Adjective;

Reading Shape is a kind of Shape identified by Fact Type Shape where
	Fact Type Shape has at most one Reading Shape,
	Reading Shape is for one Fact Type Shape;
Reading Shape is for one Reading,
	Reading has Reading Shape;

Ring Constraint Shape is a kind of Constraint Shape;
Ring Constraint Shape is attached to one Fact Type;

Role Display is where
	Fact Type Shape displays Role in Position,
	Fact Type Shape fills Position with one Role;

Role Name Shape is a kind of Shape;
Role Name Shape is for one Role Display,
	Role Display has at most one Role Name Shape;

Role Ref is where
	Role Sequence fills Position with one Role,
	Role Sequence places Role in one Position,
	Role occupies Position in Role Sequence;

Set Comparison Constraint is a kind of Set Constraint;

Set Comparison Roles is where
	Set Comparison Constraint fills Position with one Role Sequence,
	Role Sequence occupies Position in Set Comparison Constraint,
	Position in Set Comparison Constraint is occupied by Role Sequence,
	Set Comparison Constraint places Role Sequence in one Position;

Set Equality Constraint is a kind of Set Comparison Constraint;

Set Exclusion Constraint is a kind of Set Comparison Constraint;
Set Exclusion Constraint is mandatory;

Span is independent where
	Variable allows players of at least one Role,
	Role populates Variable;

Step is identified by input-Span and output-Span where
	Step has one input-Span,
	Step has one output-Span;
Alternatives include at least one Step,
	Step has at most one Alternatives;
Step traverses one Fact Type,
	Fact Type directs Step;
Step involves incidental-Span,
	Span is incidentally involved in at most one Step;
Step is disallowed;
Step is optional;

Term is where
	Vocabulary uses Name,
	Name applies in Vocabulary;
Term applies to at most one Domain Object Type;
Term applies to at most one Instance;
Term (as Role Name) is name of Role,
	Role has at most one Role Name;
Term is preferred;

Type Inheritance is where
	Entity Type (as Subtype) is subtype of super-Entity Type (as Supertype) [acyclic, intransitive],
	Supertype is supertype of Subtype;
Assimilation applies to Type Inheritance,
	Type Inheritance uses at most one Assimilation;
Type Inheritance implies one Fact Type,
	Fact Type is implied by at most one Type Inheritance;
Type Inheritance provides identification;

Value Constraint Shape is a kind of Constraint Shape;
Role Display has at most one Value Constraint Shape,
	Value Constraint Shape is for at most one Role Display;
Value Constraint Shape is for at most one Object Type Shape,
	Object Type Shape has Value Constraint Shape;

Value Range is identified by minimum-Bound and maximum-Bound where
	Value Range has at most one minimum-Bound,
	Value Range has at most one maximum-Bound;

Value Type is a kind of Domain Object Type;
Value Type maps to at most one Data Type;
Value Type has at most one Length,
	Length is of Value Type;
Value Type has at most one Scale,
	Scale is of Value Type;
Value Type is of at most one Unit;
Value Type has at most one Value Constraint,
	Value Constraint constrains at most one Value Type;
Value Type is at most one auto-- assigned at Transaction Timing;
Value Type is subtype of at most one super-Value Type (as Supertype) [acyclic, intransitive],
	Supertype is supertype of Value Type;

Allowed Range is where
	Value Constraint allows at least one Value Range;

Facet is where
	Value Type has facet called Name,
	Name is a facet of Value Type;
Facet has values of at most one facet-Value Type;

Facet Value is where
	Value Type defines Facet as having one Value,
	Value for Facet applies to Value Type;

Implicit Boolean Value Type is a kind of Value Type;

/*
 * Constraints:
 */
for each Concept exactly one of these holds:
	Concept is a Fact Type,
	Concept is a Constraint,
	Concept is a Role,
	Concept is a Fact,
	Concept is an Instance,
	Concept is an ObjectType;
for each Constraint exactly one of these holds:
	Constraint is a Presence Constraint,
	Constraint is a Set Constraint,
	Constraint is a Ring Constraint,
	Constraint is a Value Constraint;
either Domain Object Type is an Entity Type or Domain Object Type is a Value Type but not both;
for each Role Sequence exactly one of these holds:
	Presence Constraint covers Role Sequence,
	Subset Constraint (1) covers subset-Role Sequence,
	Subset Constraint (2) covers superset-Role Sequence,
	Role Sequence occupies Position in Set Comparison Constraint;
either Set Comparison Constraint is a Set Exclusion Constraint or Set Comparison Constraint is a Set Equality Constraint but not both;
either Set Constraint is a Set Comparison Constraint or Set Constraint is a Subset Constraint but not both;
either Unit uses coefficient from Ephemera URL or Unit has Coefficient but not both;
either Unit is fundamental or Unit is derived from base-Unit but not both;
either Value Constraint Shape is for Object Type Shape or Value Constraint Shape is for Role Display but not both;
either Value Constraint constrains Value Type or Value Constraint applies to Role but not both;
for each Instance at most one of these holds:
	Instance has Value,
	Instance objectifies Fact;
for each Span at most one of these holds:
	Step (1) has input-Span,
	Span is incidentally involved in Step;
for each Span at most one of these holds:
	Step (1) has output-Span,
	Span is incidentally involved in Step;
for each Term at most one of these holds:
	Term applies to Domain Object Type,
	Term is name of Role;
Entity Type results from implicit objectification
	only if Entity Type objectifies Fact Type;
Presence Constraint is preferred identifier
	only if Presence Constraint has max Frequency;
Value Type has Scale
	only if Value Type has Length;
either Agreement was reached by Agent or Agreement was on Date;
each combination Diagram, Location occurs at most one time in
	Shape is in Diagram,
	Shape is at Location;
each combination Entity Type(1), Type Inheritance occurs at most one time in
	Entity Type(1) is subtype of super Entity Type(2),
	Type Inheritance provides identification;
each Presence Constraint occurs at least one time in
	Presence Constraint has min Frequency(2),
	Presence Constraint has max Frequency(1),
	Presence Constraint is mandatory;
each combination Reading, Position occurs one time in
	Role has Position in Reading;
each combination Reading, Role occurs one time in
	Role has Position in Reading;
each Role Sequence occurs at least one time in
	Role Sequence fills Position with Role;
each Role occurs at most one time in
	Variable projects Role;
each Set Comparison Constraint occurs at least 2 times in
	Set Comparison Constraint fills Position with Role Sequence;
either Value Range has minimum Bound(2) or Value Range has maximum Bound(1);
either Value Type(1) maps to Data Type or Value Type(1) is subtype of super Value Type(2);
each combination Vocabulary, Name occurs at most one time in
	Constraint belongs to Vocabulary,
	Constraint is called Name;
each combination Vocabulary, Name occurs at most one time in
	Unit is in Vocabulary,
	Unit is called Name;
/*
each combination Vocabulary, Term, Domain Object Type occurs at most one time in
	Vocabulary uses Name,
	Term is preferred,
	Term applies to Domain Object Type;
*/
