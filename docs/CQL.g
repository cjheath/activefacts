grammar CQL;

cql
:	( definition ';' )*
;

definition
:	'vocabulary' ID
|	import
|	unit
|	constraint
|	concept
;

import
:	'import' ID ( ',' 'alias' ID 'as' ID )*
;

unit
:	'unit' ID ( '=' ( REAL | DECIMAL '/' DECIMAL ) units_raised )?
;

units_raised
:	unit_raised+ ( '/' unit_raised+ )?
;

unit_raised
:	ID ( '^' '-'? DIGIT )?
;

/* External constraints */
constraint
:	( 'for' 'each' role_list quantifier 'of' 'these' 'holds' ':'
	| 'each' role_list 'occurs' quantifier 'time' 'in'
	) reading_list		/* roles in readings may need 'some' and 'that' */
	| reading_list 'only' 'if' reading_list
;

reading_list
:	reading ( 'and' reading )*
;

role_list
:	role_name ( ',' role_name )*
;

concept
:	base_type
|	subtype
|	data_type
|	fact_type
;

base_type
:	ID 'is' identification ( 'where' | ':' ) clause_list
;

subtype
:	ID kind_of ID ( ',' ID )* identification? ( ( 'where' | ':' ) clause_list )?
;

kind_of
:	'is'  'a' 'subtype' 'of'
|	'is'  'a' 'kind' 'of'
;

identification
:	'identified' 'by' role_name ( 'and' role_name )*
;

role_name
:	ID ( '-'? ID )?
;

/* Data Types */
data_type
:	ID ( '=' | 'is' 'defined' 'as' ) ID parameter_list
	dt_details?
;

dt_details
:	units_raised? restriction?
;

/* Fact types */
fact_type
:	( ID 'is' 'where' )?	/* Nominalise the fact type? */
	clause_list		/* Alternate readings for the fact type */
	derivation?
;

derivation
:	( ( 'where' | ':' )	/* Fact derivation conditions */
	  condition_list
	)?
	returning?	/* Default result constellation */
;

clause_list
:	clause ( ',' clause )*
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
:	role_name
|	'by' ( 'ascending' | 'descending' ) role_name
;

/* Fact clauses (readings with embedded constraints). Plenty of ambiguity here! */
clause
:	qualifier? reading post_qualifiers?
;

qualifier
:	'maybe' | 'definitely'
;

post_qualifiers
:	'[' post_qualifier ( ',' post_qualifier )* ']'
;

post_qualifier
:	'static' | 'transient' | 'intransitive' | 'transitive' | 'acyclic' | 'symmetric'
;

reading
:	( ID | fact_role )+
;

fact_role
:	quantifier?
	leading_adjective?
	ID
	trailing_adjective?
	function_call*
	role_name_def?
	( value | restriction )?
;

role
:	quantifier?
	leading_adjective?
	ID
	trailing_adjective?
	role_name_def?
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
:	ID '-'?	/* There may be no space between the ID and the '-', if present */
;

trailing_adjective
:	'-'? ID	/* There may be no space between the ID and the '-', if present */
;

function_call
:	'.' ID parameter_list?
;

parameter_list
:	'(' ( parameter ( ',' parameter )* )? ')'
;

parameter
:	role_name | value
;

role_name_def
:	'(' 'as' ID ')'
;

restriction
:	'restricted' 'to' '{' range ( ',' range )* '}'
;

/* Expressions */
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
:	number unit_power?
|	role_name function_call*
|	'(' expression ')'
;

/* Mostly lexical rules */

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

