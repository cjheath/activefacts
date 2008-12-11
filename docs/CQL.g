grammar CQL;

cql
:	statement*
;

statement
:	definition ';'
|	query '?'
;

definition
:	'vocabulary' ID
|	import_def
|	unit_def
|	constraint
|	concept
;
	
import_def
:	'import' ID ( ',' 'alias' ID 'as' ID )*
;

unit_def
:	'unit' ID ( '=' ( REAL | DECIMAL '/' DECIMAL )? unit_derivation )?
;

unit_derivation
:	unit+ ( '/' unit+ )?
;

unit
:	ID ( '^' '-'? DIGIT )?
;

// External constraints
constraint
:	mandatory_or_exclusive_constraint
	| join_expression 'only' 'if' join_expression
	| join_expression 'if' 'and' 'only' 'if' join_expression
;

mandatory_or_exclusive_constraint
:	( 'for' 'each' role_list quantifier 'of' 'these' 'holds' ':'
	|  'each' role_list 'occurs' quantifier 'time' 'in'
	) join_expression
|	'either' join_expression 'or' join_expression 'but' 'not' 'both'
;

join_expression
:	reading ( 'and' reading )*
;

role_list
:	role_ref ( ',' role_ref )*
;

concept
:	entity_type
|	data_type
|	fact_type
;

entity_type
:	ID 'is' identification
|	ID 'is' supertypes identification?
;

supertypes
:	'a' ( 'subtype' | 'kind' ) 'of' ID ( ',' ID )*
;

identification
:	'identified' 'by' ( 'its' ID id_fact_types? | role_ref ( 'and' role_ref )* id_fact_types)
;

id_fact_types
:	( 'where' | ':' ) clause_list
;

role_ref
:	((ID '-') => (ID '-'))? ID (('-' | ID) => ('-'? ID))?
//:	(ID '-')? ID ('-'? ID)?
;

// Data Types
data_type
:	ID ( '=' | 'is' 'defined' 'as' ) ID parameter_list
	dt_details
;

dt_details
:	('in' unit)? restriction?
;

// Fact types
fact_type
:	( ID 'is' 'where' )?	// Nominalise the fact type?
	clause_list		// Alternate readings for the fact type
	derivation?
	returning?		// Default result constellation
;

clause_list
:	clause ( ',' clause )*
;

query
:	condition_list returning?
;

derivation	// Fact derivation conditions
:	( 'where' | ':' ) condition_list
;

condition_list
:	condition ( ',' condition )*
;

condition
:	clause
|	comparison
;

returning
:	'returning' return ( ',' return )*
;

return
:	role_ref
|	'by' ( 'ascending' | 'descending' ) role_ref
;

clause
:	'maybe'? reading qualifiers?
;

qualifiers
:	'[' qualifier ( ',' qualifier )* ']'
;

qualifier
:	'static' | 'transient' | 'intransitive' | 'transitive' | 'acyclic' | 'symmetric'
;

reading
:	(ID | fact_role)* (quantifier? fact_role)
;

fact_role
:	role_ref
//	function_call*
	role_name_def?
	values?
;

values
:	value | restriction
;

quantifier
:	'no'
|	'some'
|	'that'
|	'one'
|	'exactly' quantity
|	'at' 'least' quantity
|	'at' 'most' quantity
|	'at' 'least' quantity 'and' 'at' 'most' quantity
|	'from' DECIMAL 'to' DECIMAL
;

quantity
:	'one' | DECIMAL
;

leading_adjective
:	ID '-'?	// There may be no space between the ID and the '-', if present
;

trailing_adjective
:	'-'? ID	// There may be no space between the ID and the '-', if present
;

function_call
:	'.' ID parameter_list?
;

parameter_list
:	'(' ( parameter ( ',' parameter )* )? ')'
;

parameter
:	role_ref | value
;

role_name_def
:	'(' 'as' ID ')'
;

restriction
:	'restricted' 'to' '{' range ( ',' range )* '}'
;

// Expressions
comparison
:	expression comparator expression
;

comparator
:	'<=' | '<' | '=' | '>=' | '>'
;

expression
:	sum
;

sum
:	term ( ( '+' | '-' ) term )*
;

term
:	factor ( ( '*' | '/' | '%' ) factor )*
;

factor
:	number unit?
|	role_ref function_call*
|	'(' expression ')'
;

// Mostly lexical rules

range
:	numeric_range | string_range
;

numeric_range
:	'..' number
|	number ( '..' number? )?
;

string_range
:	'..' STRING
|	STRING ( '..' STRING? )?
;

value
:	'true' | 'false' | number | STRING
;

number
:	DECIMAL | OCTAL | HEXADECIMAL | REAL
;

DECIMAL :       '0' | SIGN? ('1'..'9') DIGIT*   // A decimal integer
;
OCTAL   :       '0' ('0'..'7')+         // An octal integer
;
HEXADECIMAL:    '0' 'x' HEXDIGIT+               // A hexadecimal integer
;
REAL    :       SIGN? ('0'..'9')+ '.' ('0'..'9')* EXPONENT?     // a real number
|       SIGN? ('0'..'9')+ EXPONENT
|       SIGN? '.' ('0'..'9')+ EXPONENT?
;
fragment SIGN:  ('+' | '-')
;
fragment EXPONENT
:       ('e'|'E') SIGN? ('0'..'9')+
;

STRING  :       '\'' ( CHARACTER )* '\''
;

fragment CHARACTER
:       ~('\'' | '\\')
|       '\\' ( 'b' | 'e' | 'f' | 'n' | 't' | 'r' | '\'' )
|       '\\' DIGIT DIGIT DIGIT
|       '\\' 'x' HEXDIGIT HEXDIGIT
|       '\\' 'u' HEXDIGIT HEXDIGIT HEXDIGIT HEXDIGIT
;

ID
:       LETTER (LETTER|DIGIT)*
;
fragment DIGIT  :       '0'..'9'
;
fragment HEXDIGIT:      DIGIT | 'a'..'f' | 'A'..'F'
;
fragment LETTER :       ('_'|'A'..'Z'|'a'..'z')
;

COMMENT
:       '/*' ( options {greedy=false;} : . )* '*/'
	{$channel=99;}
;

LINE_COMMENT
:       '//' ~('\n'|'\r')* '\r'? '\n' {$channel=99;}
;

WS
:       (' '|'\t'|'\r'|'\n'|'\u000C')+ {$channel = 99;}
;

