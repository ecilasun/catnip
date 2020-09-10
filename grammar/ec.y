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

class SBaseASTNode
{
public:
	SBaseASTNode() { m_Value = "."; }
	SBaseASTNode(std::string str) { m_Value = str; /*printf("%s ", str.c_str());*/ }

	std::string m_Value;
	std::stack<SBaseASTNode*> m_SubNodes;
};

struct SParserContext
{
	SParserContext()
	{
	}
	std::stack<SBaseASTNode*> m_NodeStack;
};

SParserContext g_context;

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
%type <astnode> jump_statement
%type <astnode> relational_expression
%type <astnode> equality_expression
%type <astnode> shift_expression
%type <astnode> unary_expression
%type <astnode> conditional_expression
%type <astnode> logical_and_expression
%type <astnode> logical_or_expression
%type <astnode> inclusive_or_expression
%type <astnode> exclusive_or_expression
%type <astnode> and_expression
%type <astnode> selection_statement_logic
%type <astnode> selection_statement_logic_else
%type <astnode> selection_statement
%type <astnode> primary_expression
%type <astnode> initializer
%type <astnode> compound_statement
%type <astnode> block_item_list
%type <astnode> argument_expression_list
%type <astnode> parameter_type_list
%type <astnode> iteration_statement

%start translation_unit
%%

primary_expression
	: IDENTIFIER																				{
																									$$ = new SBaseASTNode($1);
																									g_context.m_NodeStack.push($$);
																								}
	| CONSTANT																					{
																									std::string tmp;
																									tmp = std::to_string($1);
																									$$ = new SBaseASTNode(tmp);
																									g_context.m_NodeStack.push($$);
																								}
	| STRING_LITERAL																			{
																									$$ = new SBaseASTNode($1);
																									g_context.m_NodeStack.push($$);
																								}
	| '(' expression ')'
	;

postfix_expression
	: primary_expression
	| postfix_expression '[' expression ']'														{
																									$$ = new SBaseASTNode("OFFSET[]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| postfix_expression '(' ')'																{
																									$$ = new SBaseASTNode("CALL");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| postfix_expression '(' argument_expression_list ')'										{
																									$$ = new SBaseASTNode("CALL(..)");
																									// Parameters
																									do{
																										$$->m_SubNodes.push(g_context.m_NodeStack.top());
																										g_context.m_NodeStack.pop();
																									} while(g_context.m_NodeStack.top()->m_Value=="ARG");
																									// Function name
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| postfix_expression '.' IDENTIFIER															{
																									$$ = new SBaseASTNode(".");
																									g_context.m_NodeStack.push($$);
																								}
	| postfix_expression PTR_OP IDENTIFIER														{
																									$$ = new SBaseASTNode("PTROP");
																									g_context.m_NodeStack.push($$);
																								}
	| postfix_expression INC_OP																	{
																									$$ = new SBaseASTNode("++");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| postfix_expression DEC_OP																	{
																									$$ = new SBaseASTNode("--");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| '(' type_name ')' '{' initializer_list '}'												{
																									$$ = new SBaseASTNode();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| '(' type_name ')' '{' initializer_list ',' '}'											{
																									$$ = new SBaseASTNode();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

argument_expression_list
	: assignment_expression																		{
																									$$ = new SBaseASTNode("ARG");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| argument_expression_list ',' assignment_expression										{
																									$$ = new SBaseASTNode("ARG");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

unary_expression
	: postfix_expression
	| INC_OP unary_expression																	{
																									$$ = new SBaseASTNode("++");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| DEC_OP unary_expression																	{
																									$$ = new SBaseASTNode("--");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| unary_operator cast_expression															{
																									$$ = new SBaseASTNode("CAST");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}

	| SIZEOF unary_expression																	{
																									$$ = new SBaseASTNode("sizeof(expr)");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| SIZEOF '(' type_name ')'																	{
																									$$ = new SBaseASTNode("sizeof(..)");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

unary_operator
	: '&'																						{
																									$$ = new SBaseASTNode("&");
																									g_context.m_NodeStack.push($$);
																								}
	| '*'																						{
																									$$ = new SBaseASTNode("*");
																									g_context.m_NodeStack.push($$);
																								}
	| '+'																						{
																									$$ = new SBaseASTNode("+");
																									g_context.m_NodeStack.push($$);
																								}
	| '-'																						{
																									$$ = new SBaseASTNode("-");
																									g_context.m_NodeStack.push($$);
																								}
	| '~'																						{
																									$$ = new SBaseASTNode("~");
																									g_context.m_NodeStack.push($$);
																								}
	| '!'																						{
																									$$ = new SBaseASTNode("!");
																									g_context.m_NodeStack.push($$);
																								}
	;

cast_expression
	: unary_expression
	| '(' type_name ')' cast_expression
	;

multiplicative_expression
	: cast_expression																			/*{
																									// Looks like here I can decide on final value of a variable, constant or function return value
																									$$ = new SBaseASTNode("CAST");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}*/
	| multiplicative_expression '*' cast_expression												{
																									$$ = new SBaseASTNode("MUL");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| multiplicative_expression '/' cast_expression												{
																									$$ = new SBaseASTNode("DIV");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| multiplicative_expression '%' cast_expression												{
																									$$ = new SBaseASTNode("MOD");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

additive_expression
	: multiplicative_expression																	//{ $$ = new SBaseASTNode("MulExp"); }
	| additive_expression '+' multiplicative_expression											{
																									$$ = new SBaseASTNode("ADD");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| additive_expression '-' multiplicative_expression											{
																									$$ = new SBaseASTNode("SUB");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

shift_expression
	: additive_expression
	| shift_expression LEFT_OP additive_expression												{
																									$$ = new SBaseASTNode("<<");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| shift_expression RIGHT_OP additive_expression												{
																									$$ = new SBaseASTNode(">>");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

relational_expression
	: shift_expression
	| relational_expression LESS_OP shift_expression											{
																									$$ = new SBaseASTNode("<");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| relational_expression GREATER_OP shift_expression											{
																									$$ = new SBaseASTNode(">");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| relational_expression LE_OP shift_expression												{
																									$$ = new SBaseASTNode("<=");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| relational_expression GE_OP shift_expression												{
																									$$ = new SBaseASTNode(">=");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

equality_expression
	: relational_expression
	| equality_expression EQ_OP relational_expression											{
																									$$ = new SBaseASTNode("==");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| equality_expression NE_OP relational_expression											{
																									$$ = new SBaseASTNode("!=");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

and_expression
	: equality_expression
	| and_expression '&' equality_expression													{
																									$$ = new SBaseASTNode("AND");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression												{
																									$$ = new SBaseASTNode("XOR");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression										{
																									$$ = new SBaseASTNode("OR");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

logical_and_expression
	: inclusive_or_expression
	| logical_and_expression AND_OP inclusive_or_expression										{
																									$$ = new SBaseASTNode("&&");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

logical_or_expression
	: logical_and_expression
	| logical_or_expression OR_OP logical_and_expression										{
																									$$ = new SBaseASTNode("||");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

conditional_expression
	: logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression							{
																									$$ = new SBaseASTNode("?:");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

assignment_expression
	: conditional_expression
	| unary_expression assignment_operator assignment_expression								{
																									$$ = new SBaseASTNode("AsnExp");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
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
	: declarator																				{
																									$$ = new SBaseASTNode("DECL");
																									bool isDim = g_context.m_NodeStack.top()->m_Value == "DIM";
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									if(isDim)
																									{
																										$$->m_SubNodes.push(g_context.m_NodeStack.top());
																										g_context.m_NodeStack.pop();
																									}
																									else
																									{
																										// TODO: Add a dummy DIM 1 here
																									}
																									g_context.m_NodeStack.push($$);
																								}
	| declarator '=' initializer																{
																									$$ = new SBaseASTNode("DECL=");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									bool isDim = g_context.m_NodeStack.top()->m_Value == "DIM";
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									if(isDim)
																									{
																										$$->m_SubNodes.push(g_context.m_NodeStack.top());
																										g_context.m_NodeStack.pop();
																									}
																									g_context.m_NodeStack.push($$);
																								}
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
	: pointer direct_declarator																	{
																									$$ = new SBaseASTNode("PTR");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_declarator
	;

direct_declarator
	: IDENTIFIER																				{
																									$$ = new SBaseASTNode($1);
																									g_context.m_NodeStack.push($$);
																								}
	| '(' declarator ')'																		{
																									$$ = new SBaseASTNode("(d)");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_declarator '[' type_qualifier_list assignment_expression ']'						{
																									$$ = new SBaseASTNode("dd[ta]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_declarator '[' type_qualifier_list ']'												{
																									$$ = new SBaseASTNode("dd[t]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_declarator '[' assignment_expression ']'											{
																									$$ = new SBaseASTNode("DIM");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_declarator '[' STATIC type_qualifier_list assignment_expression ']'				{
																									$$ = new SBaseASTNode("dd[sta]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_declarator '[' type_qualifier_list STATIC assignment_expression ']'				{
																									$$ = new SBaseASTNode("dd[tsa]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_declarator '[' type_qualifier_list '*' ']'											{
																									$$ = new SBaseASTNode("dd[t*]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_declarator '[' '*' ']'																{
																									$$ = new SBaseASTNode("dd[*]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_declarator '[' ']'																	{
																									$$ = new SBaseASTNode("dd[]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_declarator '(' parameter_type_list ')'												{
																									$$ = new SBaseASTNode("DEFFUNC");
																									// Function name
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// PARAMS
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// Statement block
																									//$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									//g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_declarator '(' identifier_list ')'													{
																									$$ = new SBaseASTNode("dd(i)");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_declarator '(' ')'																	{
																									$$ = new SBaseASTNode("DEFFUNC");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																									//printf(" {\n");
																								}
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
	: parameter_list																			{
																									$$ = new SBaseASTNode("PARAMS");
																									do{
																										$$->m_SubNodes.push(g_context.m_NodeStack.top());
																										g_context.m_NodeStack.pop();
																									} while(g_context.m_NodeStack.top()->m_Value=="PARAM");
																									g_context.m_NodeStack.push($$);
																								}
	| parameter_list ',' ELLIPSIS
	;

parameter_list
	: parameter_declaration																		{
																									$$ = new SBaseASTNode("PARAM");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| parameter_list ',' parameter_declaration													{
																									$$ = new SBaseASTNode("PARAM");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
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
	: '(' abstract_declarator ')'																{
																									$$ = new SBaseASTNode("(a)");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| '[' ']'																					{
																									$$ = new SBaseASTNode("[]");
																									g_context.m_NodeStack.push($$);
																								}
	| '[' assignment_expression ']'																{
																									$$ = new SBaseASTNode("[=]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_abstract_declarator '[' ']'														{
																									$$ = new SBaseASTNode("d[]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_abstract_declarator '[' assignment_expression ']'									{
																									$$ = new SBaseASTNode("[N]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| '[' '*' ']'																				{
																									$$ = new SBaseASTNode("[*]");
																									g_context.m_NodeStack.push($$);
																								}
	| direct_abstract_declarator '[' '*' ']'													{
																									$$ = new SBaseASTNode("d[*]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| '(' ')'																					{
																									$$ = new SBaseASTNode("()");
																									g_context.m_NodeStack.push($$);
																								}
	| '(' parameter_type_list ')'																{
																									$$ = new SBaseASTNode("(p)");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_abstract_declarator '(' ')'														{
																									$$ = new SBaseASTNode("()");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| direct_abstract_declarator '(' parameter_type_list ')'									{
																									$$ = new SBaseASTNode("d(p)");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

initializer
	: assignment_expression
	| '{' initializer_list '}'																	{
																									$$ = new SBaseASTNode("{}");
																									do{
																										$$->m_SubNodes.push(g_context.m_NodeStack.top());
																										g_context.m_NodeStack.pop();
																									} while(g_context.m_NodeStack.top()->m_Value!="DIM");
																									g_context.m_NodeStack.push($$);
																								}
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
	: '[' constant_expression ']'																{
																									$$ = new SBaseASTNode("[dest]");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| '.' IDENTIFIER																			{
																									$$ = new SBaseASTNode(".dest");
																									g_context.m_NodeStack.push($$);
																								}
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
	: '{' '}'																					{
																									$$ = new SBaseASTNode("{emptyblk}");
																									g_context.m_NodeStack.push($$);
																								}
	| '{' block_item_list '}'																	{
																									$$ = new SBaseASTNode("{compound_statement}");
																									do {
																										$$->m_SubNodes.push(g_context.m_NodeStack.top());
																										g_context.m_NodeStack.pop();
																									} while(g_context.m_NodeStack.top()->m_Value=="{blockitem}" || g_context.m_NodeStack.top()->m_Value=="{blockitems}");
																									// Do we belong to a function definition?
																									if (g_context.m_NodeStack.top()->m_Value=="DEFFUNC")
																										g_context.m_NodeStack.top()->m_SubNodes.push($$);
																									else
																										g_context.m_NodeStack.push($$);
																								}
	;

block_item_list
	: block_item																				{
																									$$ = new SBaseASTNode("{blockitem}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| block_item_list block_item																{
																									$$ = new SBaseASTNode("{blockitems}");
																									//do{
																										$$->m_SubNodes.push(g_context.m_NodeStack.top());
																										g_context.m_NodeStack.pop();
																									//} while(g_context.m_NodeStack.top()->m_Value!="DEFFUNC");
																									g_context.m_NodeStack.push($$);
																								}
	;

block_item
	: declaration																				//{ printf(";\n"); }
	| statement																					//{ printf(";\n"); }
	;

expression_statement
	: ';'
	| expression ';'																			//{ printf(";\n"); }
	;

selection_statement_logic
	: IF '(' expression ')'
	;

selection_statement
	: selection_statement_logic statement														{
																									$$ = new SBaseASTNode("if");
																									// If condition
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// If statement or statement block
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| selection_statement_logic statement ELSE	statement										{
																									$$ = new SBaseASTNode("ifelse");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| SWITCH '(' expression ')' statement														{
																									$$ = new SBaseASTNode("switch");
																									g_context.m_NodeStack.push($$);
																								}
	;

iteration_statement_begin
	: FOR '('
	;

iteration_statement_prologue_expr
	: iteration_statement_begin expression_statement											//{ printf(" {\n//forstartlabel0000:\n");}
	;
iteration_statement_prologue_decl
	: iteration_statement_begin declaration														//{ printf(" {\n//forstartlabel0000:\n");}
	;

iteration_statement
	: WHILE '(' expression ')' statement
	| DO statement WHILE '(' expression ')' ';'
	| iteration_statement_prologue_expr expression_statement ')' statement						{
																									$$ = new SBaseASTNode("for0");
																									// expression_statement
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// statement
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| iteration_statement_prologue_expr expression_statement expression ')' statement			{
																									$$ = new SBaseASTNode("for1");
																									// expression_statement
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// expression
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// statement
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| iteration_statement_prologue_decl expression_statement ')' statement						{
																									$$ = new SBaseASTNode("for2");
																									// prologue_decl
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// expression_statement
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// statement
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| iteration_statement_prologue_decl expression_statement expression ')' statement			{
																									$$ = new SBaseASTNode("for3");
																									// prologue
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// expression_statement
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// Expression
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// Statement
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

jump_statement
	: GOTO IDENTIFIER ';'																		{
																									$$ = new SBaseASTNode("goto");
																									g_context.m_NodeStack.push($$);
																								}
	| CONTINUE ';'																				{
																									$$ = new SBaseASTNode("continue");
																									g_context.m_NodeStack.push($$);
																								}
	| BREAK ';'																					{
																									$$ = new SBaseASTNode("break");
																									g_context.m_NodeStack.push($$);
																								}
	| RETURN ';'																				{
																									$$ = new SBaseASTNode("ret");
																									g_context.m_NodeStack.push($$);
																								}
	| RETURN expression ';'																		{
																									$$ = new SBaseASTNode("ret(...)");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

external_declaration
	: function_definition																		//{ printf(" }\n"); }
	| declaration																				//{ printf(" ;\n"); }
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

void DumpEntry(int nodelevel, SBaseASTNode *node)
{
	static const std::string nodetabs="                                                                                                              ";
	printf("%s%s\n", nodetabs.substr(0,nodelevel).c_str(), node->m_Value.c_str());
	size_t sz = node->m_SubNodes.size();
	for(size_t i=0;i<sz;++i)
	{
		DumpEntry(nodelevel+1, node->m_SubNodes.top());
		node->m_SubNodes.pop();
	}
}

void dumpnodes()
{
	int nodelevel = 0;
	size_t sz = g_context.m_NodeStack.size();
	//Need to reverse the root stack first
	std::stack<SBaseASTNode*> reversestack;
	for(size_t i=0;i<sz;++i)
	{
		reversestack.push(g_context.m_NodeStack.top());
		g_context.m_NodeStack.pop();
	}
	for(size_t i=0;i<sz;++i)
	{
		DumpEntry(nodelevel, reversestack.top());
		reversestack.pop();
	}
}

extern int yylineno;
void yyerror(const char *s) {
	printf("%d : %s %s\n", yylineno, s, yytext );
	err++;
}
