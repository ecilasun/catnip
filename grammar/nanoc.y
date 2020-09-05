%{
// 1st revisioon: Based on https://www.lysator.liu.se/c/ANSI-C-grammar-l.html
// 2nd revision: Based on https://gist.github.com/codebrainz/2933703

#include <stdio.h>
#include <stdlib.h>
#include <stack>
#include <string>
#include <map>

extern int yylex(void);
void yyerror(const char *);
int yyparse(void);

extern FILE *yyin;
extern char *yytext;
extern FILE *fp;
int err=0;

void push(const char *str);
void pop(std::string &_str);
uint32_t regidx();

struct SParserContext
{
	SParserContext()
	{
		m_varAlloc = new uint32_t[131072];
		memset(m_varAlloc, 0xCC, 131072*sizeof(uint32_t));
		memset(m_Registers, 0x00, 512*sizeof(uint64_t));
	}
	std::stack<std::string> m_Stack;
	uint32_t m_DeclDim{1};
	uint32_t m_DeclReg{0};
	uint32_t *m_varAlloc{0};
	uint64_t m_Registers[512];
};

SParserContext g_context;

std::map<uint32_t, uint32_t*> g_variableAddresses;

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

uint32_t *AllocVar(uint32_t size)
{
	uint32_t *addr = g_context.m_varAlloc;
	g_context.m_varAlloc += size;
	return addr;
}

// Will advance the allocation forward using dimensionality of an array (1+adv total)
void AdvanceAlloc(uint32_t adv)
{
	g_context.m_varAlloc += adv;
}

uint32_t *CreateVar(char *varname, uint32_t size)
{
	uint32_t var = HashString(varname);
	uint32_t *addr = AllocVar(size);

	g_variableAddresses[var] = addr;

	return addr;
}

uint32_t *FindVar(char *varname)
{
	uint32_t var = HashString(varname);

	auto found = g_variableAddresses.find(var);
	if (found!=g_variableAddresses.end())
		return found->second;
	else
	{
		printf("ERROR: Variable not found!\n");
		return 0x0; // nullptr
	}
}

void SetReg(uint32_t r, uint64_t V)
{
	g_context.m_Registers[r] = V;
}

uint64_t RegVal(uint32_t r)
{
	return g_context.m_Registers[r];
}

%}

%union
{
	char string[128];
	unsigned int numeric;
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

%start translation_unit
%%

primary_expression
	: IDENTIFIER																			{ uint32_t r = regidx(); uint32_t *addrs = FindVar($1); uint32_t V = *addrs; printf("SET R%d, [0x%.llx] # %s, %d\n", r, (uint64_t)addrs, $1, V); SetReg(r, V); char buf[64]; itoa(RegVal(r),buf,10); push(buf); }
	| CONSTANT																				{ uint32_t r = regidx(); SetReg(r, $1); printf("SET R%d, %d\n", r, $1); char buf[64]; itoa(RegVal(r),buf,10); push(buf); }
	| STRING_LITERAL { uint32_t r = regidx(); push($1); }
	| '(' expression ')'
	;

postfix_expression
	: primary_expression
	| postfix_expression '[' expression ']'
	| postfix_expression '(' ')'
	| postfix_expression '(' argument_expression_list ')'
	| postfix_expression '.' IDENTIFIER
	| postfix_expression PTR_OP IDENTIFIER
	| postfix_expression INC_OP
	| postfix_expression DEC_OP
	| '(' type_name ')' '{' initializer_list '}'
	| '(' type_name ')' '{' initializer_list ',' '}'
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
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

cast_expression
	: unary_expression
	| '(' type_name ')' cast_expression
	;

multiplicative_expression
	: cast_expression
	| multiplicative_expression '*' cast_expression											{ uint32_t r = regidx(); std::string lhs,rhs; pop(rhs); pop(lhs); uint32_t L = std::stoi(lhs); uint32_t R = std::stoi(rhs); char buf[64]; itoa(L*R,buf,10); push(buf); printf("MUL R%d, R%d # %s\n", r-2, r-1, buf); SetReg(r-2, RegVal(r-2)*RegVal(r-1));}
	| multiplicative_expression '/' cast_expression											{ uint32_t r = regidx(); std::string lhs,rhs; pop(rhs); pop(lhs); uint32_t L = std::stoi(lhs); uint32_t R = std::stoi(rhs); char buf[64]; itoa(L/R,buf,10); push(buf); printf("DIV R%d, R%d # %s\n", r-2, r-1, buf); SetReg(r-2, RegVal(r-2)/RegVal(r-1));}
	| multiplicative_expression '%' cast_expression											{ uint32_t r = regidx(); std::string lhs,rhs; pop(rhs); pop(lhs); uint32_t L = std::stoi(lhs); uint32_t R = std::stoi(rhs); char buf[64]; itoa(L%R,buf,10); push(buf); printf("MOD R%d, R%d # %s\n", r-2, r-1, buf); SetReg(r-2, RegVal(r-2)%RegVal(r-1));}
	;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression										{ uint32_t r = regidx(); std::string lhs,rhs; pop(rhs); pop(lhs); uint32_t L = std::stoi(lhs); uint32_t R = std::stoi(rhs); char buf[64]; itoa(L+R,buf,10); push(buf); printf("ADD R%d, R%d # %s\n", r-2, r-1, buf); SetReg(r-2, RegVal(r-2)+RegVal(r-1)); }
	| additive_expression '-' multiplicative_expression										{ uint32_t r = regidx(); std::string lhs,rhs; pop(rhs); pop(lhs); uint32_t L = std::stoi(lhs); uint32_t R = std::stoi(rhs); char buf[64]; itoa(L-R,buf,10); push(buf); printf("SUB R%d, R%d # %s\n", r-2, r-1, buf); SetReg(r-2, RegVal(r-2)-RegVal(r-1)); }
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
	: conditional_expression
	| unary_expression assignment_operator assignment_expression
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
	: declarator
	| declarator '=' initializer															{
																								uint32_t r = regidx();
																								printf("#arraysize=%d declreg=R%d\n", g_context.m_DeclDim, g_context.m_DeclReg);
																								std::string lhs,rhs;
																								// TODO: Reverse this to ensure forward memory write order (it's inverted atm)
																								for (int i=int(g_context.m_DeclDim)-1;i>=0;--i)
																								{
																									pop(rhs);
																									printf("ST [R%d+%d], R%d # = %s\n", g_context.m_DeclReg, i, r+(i-g_context.m_DeclDim), rhs.c_str());
																									uint32_t *addrs = (uint32_t*)(RegVal(g_context.m_DeclReg))+i;
																									*addrs = RegVal(r+(i-g_context.m_DeclDim));
																									printf("   (%.8llx <- %.8llx)\n", RegVal(g_context.m_DeclReg)+i*4, RegVal(r+(i-g_context.m_DeclDim)));
																								}
																								pop(lhs); // Pop decl. register
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
	: pointer direct_declarator
	| direct_declarator
	;

direct_declarator
	: IDENTIFIER																			{ uint32_t r = regidx(); g_context.m_DeclReg = r; uint32_t *addrs = CreateVar($1, 1); printf("SET R%d, 0x%llx # %s (new)\n", r, (uint64_t)addrs, $1); SetReg(r, (uint64_t)addrs); push($1); }
	| '(' declarator ')'
	| direct_declarator '[' type_qualifier_list assignment_expression ']'
	| direct_declarator '[' type_qualifier_list ']'
	| direct_declarator '[' assignment_expression ']'										{ uint32_t r = regidx(); std::string V; pop(V); printf("DIM R%d # %s\n", r-1, V.c_str()); g_context.m_DeclDim = std::stoi(V); AdvanceAlloc(g_context.m_DeclDim/4-1); }
	| direct_declarator '[' STATIC type_qualifier_list assignment_expression ']'
	| direct_declarator '[' type_qualifier_list STATIC assignment_expression ']'
	| direct_declarator '[' type_qualifier_list '*' ']'
	| direct_declarator '[' '*' ']'
	| direct_declarator '[' ']'
	| direct_declarator '(' parameter_type_list ')'
	| direct_declarator '(' identifier_list ')'
	| direct_declarator '(' ')'
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
	: parameter_declaration
	| parameter_list ',' parameter_declaration
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
	: '(' abstract_declarator ')'
	| '[' ']'
	| '[' assignment_expression ']'
	| direct_abstract_declarator '[' ']'
	| direct_abstract_declarator '[' assignment_expression ']'
	| '[' '*' ']'
	| direct_abstract_declarator '[' '*' ']'
	| '(' ')'
	| '(' parameter_type_list ')'
	| direct_abstract_declarator '(' ')'
	| direct_abstract_declarator '(' parameter_type_list ')'
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
	: '[' constant_expression ']'
	| '.' IDENTIFIER
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
	: declaration
	| statement
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


iteration_statement
	: WHILE '(' expression ')' statement
	| DO statement WHILE '(' expression ')' ';'
	| FOR '(' expression_statement expression_statement ')' statement
	| FOR '(' expression_statement expression_statement expression ')' statement
	| FOR '(' declaration expression_statement ')' statement
	| FOR '(' declaration expression_statement expression ')' statement
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
	: function_definition
	| declaration
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

void push(const char *str)
{
	g_context.m_Stack.push(std::string(str));
}

void pop(std::string &_str)
{
	_str = g_context.m_Stack.top();
	g_context.m_Stack.pop();
}

uint32_t regidx()
{
	return uint32_t(g_context.m_Stack.size());
}

int parseC90()
{

	if (!yyparse() && err==0)
		printf("\nC90: no errors!\n");
	else
		printf("\nC90: parse error\n");

	return 0;
}

extern int yylineno;
void yyerror(const char *s) {
	printf("%d : %s %s\n", yylineno, s, yytext );
	err++;
}
