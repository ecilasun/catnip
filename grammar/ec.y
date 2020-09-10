%{
// 1st revisioon: Based on https://www.lysator.liu.se/c/ANSI-C-grammar-l.html
// 2nd revision: Based on https://gist.github.com/codebrainz/2933703

#include <stdio.h>
#include <stdlib.h>
#include <stack>
#include <string>
#include <map>
#include <vector>

extern int yylex(void);
void yyerror(const char *);
int yyparse(void);

extern FILE *yyin;
extern char *yytext;
extern FILE *fp;
int err=0;

uint32_t HashString(const char *_str)
{
	size_t Val = 2166136261U;

	if(_str == nullptr)
		return (uint32_t)Val;

	char *pStr = (char *)_str;
	while(*pStr)
	{
		Val = 16777619U * Val ^ (size_t)*pStr;
		++pStr;
	}

	return (uint32_t)(Val);
}

struct SParserContext
{
	SParserContext()
	{
	}
	std::stack<std::string> m_StringStack;
};

SParserContext g_context;

class SBaseASTNode
{
public:
	SBaseASTNode() { m_Value = "."; }
	SBaseASTNode(std::string str) { m_Value = str; printf("%s ", str.c_str()); }

	std::string m_Value;
};

void PushString(const std::string &str)
{
	g_context.m_StringStack.push(str);
}

bool StringStackEmpty()
{
	return g_context.m_StringStack.size() == 0 ? true : false;
}

std::string PopString()
{
	if (StringStackEmpty())
		printf("ERROR: string stack underflow\n");
	std::string str = g_context.m_StringStack.top();
	g_context.m_StringStack.pop();
	return str;
}

%}

%union
{
	char string[128];
	unsigned int numeric;
	class SBaseASTNode *astnode;
}

%token <string> IDENTIFIER
%token <numeric> CONSTANT
%token <string> STRING_LITERAL

%token SIZEOF
%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LESS_OP GREATER_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN TYPE_NAME

%token TYPEDEF EXTERN STATIC AUTO REGISTER INLINE RESTRICT
%token CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token STRUCT UNION ENUM ELLIPSIS

%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%type <astnode> postfix_expression
%type <astnode> assignment_expression
%type <astnode> init_declarator
%type <astnode> unary_operator
%type <astnode> multiplicative_expression
%type <astnode> additive_expression
%type <astnode> direct_abstract_declarator
%type <astnode> designator
%type <astnode> direct_declarator
%type <astnode> parameter_list
%type <astnode> declarator

%start translation_unit
%%

primary_expression
	: IDENTIFIER																			{
																								PushString($1);
																							}
	| CONSTANT																				{
																								std::string tmp;
																								tmp = std::to_string($1);
																								PushString(tmp);
																							}
	| STRING_LITERAL																		{
																								PushString($1);
																							}
	| '(' expression ')'
	;

postfix_expression
	: primary_expression																	{ $$ = new SBaseASTNode(PopString()); }
	| postfix_expression '[' expression ']'													{ $$ = new SBaseASTNode("[read]"); }
	| postfix_expression '(' ')'															{ $$ = new SBaseASTNode("<-call"); }
	| postfix_expression '(' argument_expression_list ')'									{ $$ = new SBaseASTNode("<-call(..)"); }
	| postfix_expression '.' IDENTIFIER														{ $$ = new SBaseASTNode(); }
	| postfix_expression PTR_OP IDENTIFIER													{ $$ = new SBaseASTNode(); }
	| postfix_expression INC_OP																{ $$ = new SBaseASTNode(); }
	| postfix_expression DEC_OP																{ $$ = new SBaseASTNode(); }
	| '(' type_name ')' '{' initializer_list '}'											{ $$ = new SBaseASTNode(); }
	| '(' type_name ')' '{' initializer_list ',' '}'										{ $$ = new SBaseASTNode(); }
	;

argument_expression_list
	: assignment_expression
	| argument_expression_list ',' assignment_expression
	;

unary_expression
	: postfix_expression
	| INC_OP unary_expression
	| DEC_OP unary_expression
	| unary_operator cast_expression
	| SIZEOF unary_expression
	| SIZEOF '(' type_name ')'
	;

unary_operator
	: '&'																					{ $$ = new SBaseASTNode("&"); }
	| '*'																					{ $$ = new SBaseASTNode("*"); }
	| '+'																					{ $$ = new SBaseASTNode("+"); }
	| '-'																					{ $$ = new SBaseASTNode("-"); }
	| '~'																					{ $$ = new SBaseASTNode("~"); }
	| '!'																					{ $$ = new SBaseASTNode("!"); }
	;

cast_expression
	: unary_expression
	| '(' type_name ')' cast_expression
	;

multiplicative_expression
	: cast_expression																		{
																								// Looks like here I can decide on final value of a variable, constant or function return value
																								$$ = new SBaseASTNode("^");
																							}
	| multiplicative_expression '*' cast_expression											{ $$ = new SBaseASTNode("MUL"); }
	| multiplicative_expression '/' cast_expression											{ $$ = new SBaseASTNode("DIV"); }
	| multiplicative_expression '%' cast_expression											{ $$ = new SBaseASTNode("MOD"); }
	;

additive_expression
	: multiplicative_expression																{ $$ = new SBaseASTNode("MulExp"); }
	| additive_expression '+' multiplicative_expression										{ $$ = new SBaseASTNode("ADD"); }
	| additive_expression '-' multiplicative_expression										{ $$ = new SBaseASTNode("SUB"); }
	;

shift_expression
	: additive_expression
	| shift_expression LEFT_OP additive_expression
	| shift_expression RIGHT_OP additive_expression
	;

relational_expression
	: shift_expression
	| relational_expression LESS_OP shift_expression
	| relational_expression GREATER_OP shift_expression
	| relational_expression LE_OP shift_expression
	| relational_expression GE_OP shift_expression
	;

equality_expression
	: relational_expression
	| equality_expression EQ_OP relational_expression
	| equality_expression NE_OP relational_expression
	;

and_expression
	: equality_expression
	| and_expression '&' equality_expression
	;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression
	;

inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression
	;

logical_and_expression
	: inclusive_or_expression
	| logical_and_expression AND_OP inclusive_or_expression
	;

logical_or_expression
	: logical_and_expression
	| logical_or_expression OR_OP logical_and_expression
	;

conditional_expression
	: logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression
	;

assignment_expression
	: conditional_expression												{ $$ = new SBaseASTNode("CndExp"); }
	| unary_expression assignment_operator assignment_expression			{ $$ = new SBaseASTNode("AsnExp"); }
	;

assignment_operator
	: '='
	| MUL_ASSIGN
	| DIV_ASSIGN
	| MOD_ASSIGN
	| ADD_ASSIGN
	| SUB_ASSIGN
	| LEFT_ASSIGN
	| RIGHT_ASSIGN
	| AND_ASSIGN
	| XOR_ASSIGN
	| OR_ASSIGN
	;

expression
	: assignment_expression
	| expression ',' assignment_expression
	;

constant_expression
	: conditional_expression
	;

declaration
	: declaration_specifiers ';'
	| declaration_specifiers init_declarator_list ';'
	;

declaration_specifiers
	: storage_class_specifier
	| storage_class_specifier declaration_specifiers
	| type_specifier
	| type_specifier declaration_specifiers
	| type_qualifier
	| type_qualifier declaration_specifiers
	| function_specifier
	| function_specifier declaration_specifiers
	;

init_declarator_list
	: init_declarator
	| init_declarator_list ',' init_declarator
	;

init_declarator
	: declarator													{ $$ = new SBaseASTNode("DECL " + PopString()); }
	| declarator '=' initializer									{ $$ = new SBaseASTNode("DECL= " + PopString()); }
	;

storage_class_specifier
	: TYPEDEF
	| EXTERN
	| STATIC
	| AUTO
	| REGISTER
	;

type_specifier
	: VOID
	| CHAR
	| SHORT
	| INT
	| LONG
	| FLOAT
	| DOUBLE
	| SIGNED
	| UNSIGNED
	| struct_or_union_specifier
	| enum_specifier
	| TYPE_NAME
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}'
	| struct_or_union '{' struct_declaration_list '}'
	| struct_or_union IDENTIFIER
	;

struct_or_union
	: STRUCT
	| UNION
	;

struct_declaration_list
	: struct_declaration
	| struct_declaration_list struct_declaration
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';'
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list
	| type_specifier
	| type_qualifier specifier_qualifier_list
	| type_qualifier
	;

struct_declarator_list
	: struct_declarator
	| struct_declarator_list ',' struct_declarator
	;

struct_declarator
	: declarator
	| ':' constant_expression
	| declarator ':' constant_expression
	;

enum_specifier
	: ENUM '{' enumerator_list '}'
	| ENUM IDENTIFIER '{' enumerator_list '}'
	| ENUM '{' enumerator_list ',' '}'
	| ENUM IDENTIFIER '{' enumerator_list ',' '}'
	| ENUM IDENTIFIER
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator
	;

enumerator
	: IDENTIFIER
	| IDENTIFIER '=' constant_expression
	;

type_qualifier
	: CONST
	| RESTRICT
	| VOLATILE
	;

function_specifier
	: INLINE
	;

declarator
	: pointer direct_declarator																	{ $$ = new SBaseASTNode("PTR"); }
	| direct_declarator
	;

direct_declarator
	: IDENTIFIER																				{
																									PushString($1);
																								}
	| '(' declarator ')'																		{ $$ = new SBaseASTNode("(d)"); }
	| direct_declarator '[' type_qualifier_list assignment_expression ']'						{ $$ = new SBaseASTNode("dd[ta]"); }
	| direct_declarator '[' type_qualifier_list ']'												{ $$ = new SBaseASTNode("dd[t]"); }
	| direct_declarator '[' assignment_expression ']'											{ $$ = new SBaseASTNode("DIM"); }
	| direct_declarator '[' STATIC type_qualifier_list assignment_expression ']'				{ $$ = new SBaseASTNode("dd[sta]"); }
	| direct_declarator '[' type_qualifier_list STATIC assignment_expression ']'				{ $$ = new SBaseASTNode("dd[tsa]"); }
	| direct_declarator '[' type_qualifier_list '*' ']'											{ $$ = new SBaseASTNode("dd[t*]"); }
	| direct_declarator '[' '*' ']'																{ $$ = new SBaseASTNode("dd[*]"); }
	| direct_declarator '[' ']'																	{ $$ = new SBaseASTNode("dd[]"); }
	| direct_declarator '(' parameter_type_list ')'												{ $$ = new SBaseASTNode("DEFFUNC(p) " + PopString()); printf("\n// function entry\n"); }
	| direct_declarator '(' identifier_list ')'													{ $$ = new SBaseASTNode("dd(i)"); }
	| direct_declarator '(' ')'																	{ $$ = new SBaseASTNode("DEFFUNC() " + PopString()); printf("\n// function entry\n"); }
	;

pointer
	: '*'
	| '*' type_qualifier_list
	| '*' pointer
	| '*' type_qualifier_list pointer
	;

type_qualifier_list
	: type_qualifier
	| type_qualifier_list type_qualifier
	;


parameter_type_list
	: parameter_list
	| parameter_list ',' ELLIPSIS
	;

parameter_list
	: parameter_declaration																		{ $$ = new SBaseASTNode("PARAM " + PopString()); }
	| parameter_list ',' parameter_declaration													{ $$ = new SBaseASTNode("PARAM " + PopString()); }
	;

parameter_declaration
	: declaration_specifiers declarator
	| declaration_specifiers abstract_declarator
	| declaration_specifiers
	;

identifier_list
	: IDENTIFIER
	| identifier_list ',' IDENTIFIER
	;

type_name
	: specifier_qualifier_list
	| specifier_qualifier_list abstract_declarator
	;

abstract_declarator
	: pointer
	| direct_abstract_declarator
	| pointer direct_abstract_declarator
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'														{ $$ = new SBaseASTNode("(a)"); }
	| '[' ']'																			{ $$ = new SBaseASTNode("[]"); }
	| '[' assignment_expression ']'														{ $$ = new SBaseASTNode("[=]"); }
	| direct_abstract_declarator '[' ']'												{ $$ = new SBaseASTNode("d[]"); }
	| direct_abstract_declarator '[' assignment_expression ']'							{ $$ = new SBaseASTNode("[N]"); }
	| '[' '*' ']'																		{ $$ = new SBaseASTNode("[*]"); }
	| direct_abstract_declarator '[' '*' ']'											{ $$ = new SBaseASTNode("d[*]"); }
	| '(' ')'																			{ $$ = new SBaseASTNode("()"); }
	| '(' parameter_type_list ')'														{ $$ = new SBaseASTNode("(p)"); }
	| direct_abstract_declarator '(' ')'												{ $$ = new SBaseASTNode("()"); }
	| direct_abstract_declarator '(' parameter_type_list ')'							{ $$ = new SBaseASTNode("d(p)"); }
	;

initializer
	: assignment_expression
	| '{' initializer_list '}'
	| '{' initializer_list ',' '}'
	;

initializer_list
	: initializer
	| designation initializer
	| initializer_list ',' initializer
	| initializer_list ',' designation initializer
	;

designation
	: designator_list '='
	;

designator_list
	: designator
	| designator_list designator
	;

designator
	: '[' constant_expression ']'														{ $$ = new SBaseASTNode("[dest]"); }
	| '.' IDENTIFIER																	{ $$ = new SBaseASTNode(".dest"); }
	;

statement
	: labeled_statement
	| compound_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	;

labeled_statement
	: IDENTIFIER ':' statement
	| CASE constant_expression ':' statement
	| DEFAULT ':' statement
	;

compound_statement
	: '{' '}'
	| '{' block_item_list '}'
	;

block_item_list
	: block_item
	| block_item_list block_item
	;

block_item
	: declaration															{ printf("\n"); }
	| statement																{ printf("\n"); }
	;

expression_statement
	: ';'
	| expression ';'
	;

selection_statement
	: IF '(' expression ')' statement
	| IF '(' expression ')' statement ELSE statement
	| SWITCH '(' expression ')' statement
	;

iteration_statement_begin
	: FOR '('
	;

iteration_statement_prologue_expr
	: iteration_statement_begin expression_statement
	;
iteration_statement_prologue_decl
	: iteration_statement_begin declaration
	;

iteration_statement
	: WHILE '(' expression ')' statement
	| DO statement WHILE '(' expression ')' ';'
	| iteration_statement_prologue_expr expression_statement ')' statement
	| iteration_statement_prologue_expr expression_statement expression ')' statement
	| iteration_statement_prologue_decl expression_statement ')' statement
	| iteration_statement_prologue_decl expression_statement expression ')' statement
	;

jump_statement
	: GOTO IDENTIFIER ';'
	| CONTINUE ';'
	| BREAK ';'
	| RETURN ';'
	| RETURN expression ';'
	;

translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

external_declaration
	: function_definition																	{ printf("// end of function definition\n"); }
	| declaration																			{ printf("// end of declaration\n"); }
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement
	| declaration_specifiers declarator compound_statement
	;


declaration_list
	: declaration
	| declaration_list declaration
	;
%%

extern int yylineno;
void yyerror(const char *s) {
	printf("%d : %s %s\n", yylineno, s, yytext );
	err++;
}
