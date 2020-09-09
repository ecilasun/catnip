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

bool stackempty();
void push(const char *str);
void pop(std::string &_str);

enum EUnaryOp
{
	U_NONE,
	U_ADDRS,
	U_VAL,
	U_POS,
	U_NEGATE,
	U_BITINV,
	U_LOGICNOT,
};

enum ETypeName
{
	T_VOID,
	T_CHAR,
	T_INT,
	T_CUSTOM
};

enum ETypeModifier
{
	T_SIGNED,
	T_UNSIGNED,
};

struct SParserContext
{
	SParserContext()
	{
		m_Heap = new uint32_t[0xFFFFF];
		memset(m_Heap, 0xCC, 131072*sizeof(uint32_t));
		memset(m_Registers, 0x00, 512*sizeof(uint32_t));
	}
	std::stack<std::string> m_Stack;
	uint32_t m_DeclDim{1};
	uint32_t m_InitAsgnCounter{1};
	uint32_t m_DeclReg{0};
	uint32_t m_IsConstant{0};
	uint32_t m_VarAlloc{0x00000000}; // Default base address in heap
	uint32_t *m_Heap{nullptr};
	uint32_t m_Registers[512];
	uint32_t m_CurrentRegister{0};
	EUnaryOp m_UnaryOp{U_NONE};
	ETypeName m_TypeName{T_VOID};
	ETypeModifier m_TypeModifier{T_SIGNED};
	int m_IsPointer{0};
	int m_LHS{1};
	int m_AddressOp{0};
	int m_IsForLoop{0};
	int m_IsGlobalInit{1};
	uint32_t m_ForLoopName{0};
	uint32_t m_CurrentFunction{0};
	std::stack<uint32_t> m_ForLoopStack;
};

SParserContext g_context;

struct SVariable
{
	uint32_t m_Address;
	ETypeName m_TypeName;
	ETypeModifier m_TypeModifier;
	int m_IsPointer;
};

struct SFunction
{
	int m_TBD;
	std::vector<std::string> m_Parameters;
};

std::map<uint32_t, SVariable> g_variables;
std::map<uint32_t, SFunction> g_functions;

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

void PushForLoop(uint32_t forloopname)
{
	g_context.m_ForLoopStack.push(forloopname);
}

uint32_t PopForLoop()
{
	g_context.m_ForLoopStack.pop();
	if (g_context.m_ForLoopStack.size()!=0)
	{
		printf("ERROR: For loop stack underflow\n");
		uint32_t forloopname = g_context.m_ForLoopStack.top();
		return forloopname;
	}
	return 0xFFFFFFFF;
}

uint32_t PushRegister()
{
	if (g_context.m_CurrentRegister == 511)
		printf("   ERROR: Register overflow\n");
	return g_context.m_CurrentRegister++;
}

void ResetRegisters()
{
	g_context.m_CurrentRegister = 0;
}

uint32_t PopRegister()
{
	if (g_context.m_CurrentRegister == 0)
		printf("   ERROR: Register underflow\n");
	return --g_context.m_CurrentRegister;
}

uint32_t PreviousRegister()
{
	return g_context.m_CurrentRegister-1;
}

uint32_t AllocVar(uint32_t size)
{
	uint32_t addr = g_context.m_VarAlloc;
	g_context.m_VarAlloc += size;
	return addr;
}

uint32_t CreateVar(char *varname, uint32_t size)
{
	uint32_t var = HashString(varname);
	uint32_t addr = AllocVar(size);

	g_variables[var] = {addr, g_context.m_TypeName, g_context.m_TypeModifier, g_context.m_IsPointer};

	return addr;
}

void CreateFunction(char *funcname, uint32_t &fun)
{
	fun = HashString(funcname);
	g_functions[fun] = { 0 };
}

bool FindFunction(char *funcname, SFunction &function)
{
	uint32_t fun = HashString(funcname);

	auto found = g_functions.find(fun);
	if (found!=g_functions.end())
	{
		function = found->second;
		return true;
	}
	else
		return false;
}

uint32_t FindVar(char *varname, SVariable &variable)
{
	uint32_t var = HashString(varname);

	auto found = g_variables.find(var);
	if (found!=g_variables.end())
	{
		variable = found->second;
		return found->second.m_Address;
	}
	else
		return 0xFFFFFFFF;
}

void SetReg(uint32_t r, uint32_t V)
{
	g_context.m_Registers[r] = V;
}

uint32_t RegVal(uint32_t r)
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
	: IDENTIFIER																			{
																								SVariable var;
																								uint32_t var_addrs = FindVar($1, var);
																								if (var_addrs != 0xFFFFFFFF)
																								{
																									uint32_t r = PushRegister();
																									if (var.m_IsPointer)
																									{
																										printf("SET R%d, 0x%.8x", r, g_context.m_Heap[var.m_Address]);
																										SetReg(r, g_context.m_Heap[var.m_Address]);
																									}
																									else
																									{
																										printf("SET R%d, 0x%.8x", r, var_addrs);
																										SetReg(r, var_addrs);
																									}
																									g_context.m_DeclReg = r;
																									printf("  // R%d = %s%s (at 0x%.8x)\n", r, var.m_IsPointer ? "*":"", $1, var_addrs);
																								}
																								else
																								{	
																									bool found = false;
																									SFunction &fun = g_functions[g_context.m_CurrentFunction];
																									for (int i=0;i<fun.m_Parameters.size();++i)
																									{
																										if (fun.m_Parameters[i] == $1)
																										{
																											uint32_t r = PushRegister();
																											printf("READFROMSTACKCURSOR R%d, %d", r, i);
																											printf("  // Read parameter address from stack offset %d (%s)\n", i, $1);
																											found = true;
																										}
																									}

																									if (!found)
																										push($1); // Possibly function name for a function call then
																								}

																								g_context.m_IsConstant = 0;
																								g_context.m_InitAsgnCounter = g_context.m_DeclDim = 1;
																								g_context.m_IsPointer = 0;
																							}
	| CONSTANT																				{
																								uint32_t r = PushRegister();
																								printf("SET R%d, %d", r, $1);
																								SetReg(r, $1);
																								printf("  // R%d = %d\n", r, RegVal(r));
																								g_context.m_IsConstant = 1;
																								//g_context.m_IsPointer = 0;
																							}
	| STRING_LITERAL																		{
																								// TODO: store address of pooled string in a register
																								push($1);
																							}
	| '(' expression ')'
	;

postfix_expression
	: primary_expression
	| postfix_expression '[' expression ']'													{
																								uint32_t r = PopRegister();
																								if (g_context.m_LHS)
																								{
																									uint32_t r2 = PreviousRegister();
																									printf("ADD R%d, R%d", r2, r);
																									SetReg(r2, RegVal(r2) + RegVal(r));
																									printf("  // R%d = %d\n", r2, RegVal(r2));
																								}
																								else
																								{
																									uint32_t r2 = PreviousRegister();
																									printf("ADD R%d, R%d", r2, r);
																									SetReg(r2, RegVal(r2) + RegVal(r));
																									printf("  // R%d = %d\n", r2, RegVal(r2));
																									printf("LD R%d, [R%d]", r2, r2);
																									SetReg(r2, g_context.m_Heap[RegVal(r2)]);
																									printf("  // R%d = %d\n", r2, RegVal(r2));
																								}
																							}
	| postfix_expression '(' ')'
	| postfix_expression '(' argument_expression_list ')'									{
																								std::string V;
																								pop(V);
																								printf("// Push parameters for %s\n", V.c_str());
																								printf("SAVESTACKCURSOR\n");
																								SFunction fun;
																								bool isfunc = FindFunction((char*)V.c_str(), fun);
																								if (isfunc)
																								{
																									for (uint32_t i=0; i<fun.m_Parameters.size(); ++i)
																									{
																										uint32_t r = PopRegister();
																										printf("PUSH R%d\n", r);
																									}
																									printf("CALL @%s\n", V.c_str());
																									uint32_t r = PushRegister();
																								}
																							}
	| postfix_expression '.' IDENTIFIER
	| postfix_expression PTR_OP IDENTIFIER
	| postfix_expression INC_OP																{	uint32_t r = PreviousRegister();
																								printf("INC [R%d]", r);
																								uint32_t val = g_context.m_Heap[RegVal(r)] + 1;
																								g_context.m_Heap[RegVal(r)] = val;
																								printf("  // R%d++ = %d\n", r, val); }
	| postfix_expression DEC_OP																{	uint32_t r = PreviousRegister();
																								printf("DEC [R%d]", r);
																								uint32_t val = g_context.m_Heap[RegVal(r)] - 1;
																								g_context.m_Heap[RegVal(r)] = val;
																								printf("  // R%d-- = %d\n", r, val); }
	| '(' type_name ')' '{' initializer_list '}'
	| '(' type_name ')' '{' initializer_list ',' '}'
	;

argument_expression_list
	: assignment_expression
	| argument_expression_list ',' assignment_expression
	;

unary_expression
	: postfix_expression
	| INC_OP unary_expression												{	uint32_t r = PreviousRegister();
																				printf("INC [R%d]", r);
																				uint32_t val = g_context.m_Heap[RegVal(r)] + 1;
																				g_context.m_Heap[RegVal(r)] = val;
																				printf("  // ++R%d = %d\n", r, val); }
	| DEC_OP unary_expression												{	uint32_t r = PreviousRegister();
																				printf("DEC [R%d]", r);
																				uint32_t val = g_context.m_Heap[RegVal(r)] - 1;
																				g_context.m_Heap[RegVal(r)] = val;
																				printf("  // --R%d = %d\n", r, val); }
	| unary_operator cast_expression										{
																				if (g_context.m_UnaryOp == U_NEGATE) { uint32_t r = PreviousRegister(); printf("NEG R%d\n", r); SetReg(r, -RegVal(r)); }
																				if (g_context.m_UnaryOp == U_BITINV) { uint32_t r = PreviousRegister(); printf("INV R%d\n", r); SetReg(r, ~RegVal(r)); }
																				if (g_context.m_UnaryOp == U_LOGICNOT) { uint32_t r = PreviousRegister(); printf("NOT R%d\n", r); SetReg(r, !RegVal(r)); }
																				//if (g_context.m_UnaryOp == U_ADDRS) { uint32_t r = PreviousRegister(); printf("// address of on R%d\n", r); }
																				if (g_context.m_UnaryOp == U_VAL) { uint32_t r = PreviousRegister(); printf("ST R%d, [R%d]\n", r, r); SetReg(r, g_context.m_Heap[RegVal(r)]);}
																				if (g_context.m_UnaryOp == U_POS) { uint32_t r = PreviousRegister(); printf("POS ????\n"); }

																				g_context.m_UnaryOp = U_NONE;
																			}
	| SIZEOF unary_expression
	| SIZEOF '(' type_name ')'
	;

unary_operator
	: '&'																	{	g_context.m_UnaryOp = U_ADDRS; g_context.m_AddressOp = 1;}
	| '*'																	{	g_context.m_UnaryOp = U_VAL; }
	| '+'																	{	g_context.m_UnaryOp = U_POS; }
	| '-'																	{	g_context.m_UnaryOp = U_NEGATE; }
	| '~'																	{	g_context.m_UnaryOp = U_BITINV; }
	| '!'																	{	g_context.m_UnaryOp = U_LOGICNOT; }
	;

cast_expression
	: unary_expression																		{
																								if (!g_context.m_IsConstant)
																								{
																									if (!g_context.m_AddressOp /*&& !g_context.m_IsForLoop*/ /*TODO*/)
																									{
																										// Swap register contents (address) with value at that adress
																										uint32_t r = PreviousRegister();
																										printf("LD R%d, [R%d]", r, r);
																										SetReg(r, g_context.m_Heap[RegVal(r)]);
																										printf("  // R%d = %d\n", r, RegVal(r));
																									}
																								}
																								else
																								{
																									// Already got the value loaded in previous register
																									//uint32_t r = PreviousRegister();
																									//printf("// R%d = %d\n", r, RegVal(r));
																								}
																							}
	| '(' type_name ')' cast_expression
	;

multiplicative_expression
	: cast_expression																		{ g_context.m_AddressOp = 0; /* Get rid of addressof operation */ }
	| multiplicative_expression '*' cast_expression											{
																								uint32_t r2=PopRegister();
																								uint32_t r1=PopRegister();
																								printf("MUL R%d R%d", r1,r2);
																								uint32_t V = int(RegVal(r1)) * int(RegVal(r2));
																								SetReg(r1, V); PushRegister();
																								printf("  // R%d = %d\n", r1, V); 
																							}
	| multiplicative_expression '/' cast_expression											{
																								uint32_t r2=PopRegister();
																								uint32_t r1=PopRegister();
																								printf("DIV R%d R%d", r1,r2);
																								uint32_t V = int(RegVal(r1)) / int(RegVal(r2));
																								SetReg(r1, V);
																								PushRegister();
																								printf("  // R%d = %d\n", r1, V);
																							}
	| multiplicative_expression '%' cast_expression											{
																								uint32_t r2=PopRegister();
																								uint32_t r1=PopRegister();
																								printf("MOD R%d R%d", r1,r2);
																								uint32_t V = int(RegVal(r1)) % int(RegVal(r2));
																								SetReg(r1, V);
																								PushRegister();
																								printf("  // R%d = %d\n", r1, V);
																							}
	;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression										{
																								uint32_t r2=PopRegister();
																								uint32_t r1=PopRegister();
																								printf("ADD R%d R%d", r1,r2);
																								uint32_t V = int(RegVal(r1)) + int(RegVal(r2));
																								SetReg(r1, V);
																								PushRegister();
																								printf("  // R%d = %d\n", r1, V);
																							}
	| additive_expression '-' multiplicative_expression										{
																								uint32_t r2=PopRegister();
																								uint32_t r1=PopRegister();
																								printf("SUB R%d R%d", r1,r2);
																								uint32_t V = int(RegVal(r1)) - int(RegVal(r2));
																								SetReg(r1, V);
																								PushRegister();
																								printf("  // R%d = %d\n", r1, V);
																							}
	;

shift_expression
	: additive_expression
	| shift_expression LEFT_OP additive_expression
	| shift_expression RIGHT_OP additive_expression
	;

relational_expression
	: shift_expression
	| relational_expression LESS_OP shift_expression										{	uint32_t r2 = PopRegister();
																								uint32_t r1 = PopRegister();
																								printf("CMPL R%d R%d\n", r1,r2);
																								printf("JMPNZ @end_for_loop%d\n", g_context.m_ForLoopName); }
	| relational_expression GREATER_OP shift_expression										{	uint32_t r2 = PopRegister();
																								uint32_t r1 = PopRegister();
																								printf("CMPG R%d R%d\n", r1,r2);
																								printf("JMPNZ @end_for_loop%d\n", g_context.m_ForLoopName); }
	| relational_expression LE_OP shift_expression											{	uint32_t r2 = PopRegister();
																								uint32_t r1 = PopRegister();
																								printf("CMPLE R%d R%d\n", r1,r2);
																								printf("JMPNZ @end_for_loop%d\n", g_context.m_ForLoopName); }
	| relational_expression GE_OP shift_expression											{	uint32_t r2 = PopRegister();
																								uint32_t r1 = PopRegister();
																								printf("CMPGE R%d R%d\n", r1,r2);
																								printf("JMPNZ @end_for_loop$d\n", g_context.m_ForLoopName); }
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
	| unary_expression assignment_operator assignment_expression							{
																								uint32_t r1 = PopRegister();
																								uint32_t r2 = PopRegister();
																								printf("ST [R%d], R%d", r2, r1);
																								uint32_t addr = RegVal(r2);
																								g_context.m_Heap[addr] = RegVal(r1);
																								printf("  // [0x%.8x] = 0x%.8x\n", addr, RegVal(r1));
																							}
	;

assignment_operator
	: '='																					{	g_context.m_LHS = 0; /* Switching to right hand side */ }
	| MUL_ASSIGN																			{	printf("\t*MULASGN\n"); }
	| DIV_ASSIGN																			{	printf("\t*DIVASGN\n"); }
	| MOD_ASSIGN																			{	printf("\t*MODASGN\n"); }
	| ADD_ASSIGN																			{	printf("\t*ADDASGN\n"); }
	| SUB_ASSIGN																			{	printf("\t*SUBASGN\n"); }
	| LEFT_ASSIGN																			{	printf("\t*LEFTASGN\n"); }
	| RIGHT_ASSIGN																			{	printf("\t*RIGHTASGN\n"); }
	| AND_ASSIGN																			{	printf("\t*ANDASGN\n"); }
	| XOR_ASSIGN																			{	printf("\t*XORASGN\n"); }
	| OR_ASSIGN																				{	printf("\t*ORASGN\n"); }
	;

expression
	: assignment_expression																	{	/*if (g_context.m_IsForLoop) printf("//Part of FOR\n");*/ }
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
	: storage_class_specifier																{	printf("// TODO: storage_class_specifier\n"); }
	| storage_class_specifier declaration_specifiers
	| type_specifier																		{	//printf("// Type: TypeModifier: %d\n", g_context.m_TypeName, g_context.m_TypeModifier);
																								g_context.m_InitAsgnCounter = g_context.m_DeclDim = 1;
																							}
	| type_specifier declaration_specifiers
	| type_qualifier																		{	printf("// TODO: type_qualifier\n"); }
	| type_qualifier declaration_specifiers
	| function_specifier																	{	printf("// TODO: function_specifier\n"); }
	| function_specifier declaration_specifiers
	;

init_declarator_list
	: init_declarator
	| init_declarator_list ',' init_declarator
	;

init_declarator
	: declarator																			{
																								if (!stackempty())
																								{
																									// Just remove from stack and create the variable
																									std::string V;
																									pop(V);
																									//g_context.m_DeclReg = PushRegister();
																									uint32_t addrs0 = CreateVar((char*)V.c_str(), g_context.m_DeclDim);
																									printf("// VARDECL %s%s[%d]\n", g_context.m_IsPointer ? "*":"", V.c_str(), g_context.m_DeclDim);
																									//printf("SET R%d, 0x%.8x # %s[%d] (new)\n", g_context.m_DeclReg, (uint32_t)addrs0, V.c_str(), g_context.m_DeclDim);
																									//SetReg(g_context.m_DeclReg, (uint64_t)addrs0);
																									//PopRegister(); // Pop decl. register
																								}
																							}
	| declarator '=' initializer
	;

storage_class_specifier
	: TYPEDEF
	| EXTERN
	| STATIC
	| AUTO
	| REGISTER
	;

type_specifier
	: VOID											{ g_context.m_TypeName = T_VOID; }
	| CHAR											{ g_context.m_TypeName = T_CHAR;}
	| SHORT											{ printf("ERROR: SHORT not supported!"); }
	| INT											{ g_context.m_TypeName = T_INT; }
	| LONG											{ printf("ERROR: LONG not supported!"); }
	| FLOAT											{ printf("ERROR: FLOAT not supported!"); }
	| DOUBLE										{ printf("ERROR: DOUBLE not supported!"); }
	| SIGNED										{ g_context.m_TypeModifier = T_SIGNED; }
	| UNSIGNED										{ g_context.m_TypeModifier = T_UNSIGNED; }
	| struct_or_union_specifier
	| enum_specifier
	| TYPE_NAME										{ g_context.m_TypeName = T_CUSTOM; }
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
	: pointer direct_declarator																{ /* TODO */}
	| direct_declarator																		{ /**/ }
	;

direct_declarator
	: IDENTIFIER																			{	push($1);			}
	| '(' declarator ')'
	| direct_declarator '[' type_qualifier_list assignment_expression ']'					{	printf("  -00A\n"); }
	| direct_declarator '[' type_qualifier_list ']'											{	printf("  -009\n"); }
	| direct_declarator '[' assignment_expression ']'										{
																								uint32_t r = PopRegister();
																								g_context.m_InitAsgnCounter = g_context.m_DeclDim = RegVal(r);
																								printf("DIM R%d  // Array dimension = %d\n", r, g_context.m_DeclDim);
																							}
	| direct_declarator '[' STATIC type_qualifier_list assignment_expression ']'			{	printf("  -008\n"); }
	| direct_declarator '[' type_qualifier_list STATIC assignment_expression ']'			{	printf("  -007\n"); }
	| direct_declarator '[' type_qualifier_list '*' ']'										{	printf("  -006\n"); }
	| direct_declarator '[' '*' ']'															{	printf("  -005\n"); }
	| direct_declarator '[' ']'																{	printf("  -004\n"); }
	| direct_declarator '(' parameter_type_list ')'											{
																								if (g_context.m_IsGlobalInit)
																								{
																									printf("RET\n");
																									printf("// ENDGLOBALINIT\n\n");
																									g_context.m_IsGlobalInit = 0;
																								}
																								printf("\n@FUNCTION\n");
																								std::vector<std::string> parameters;
																								std::string V;
																								do{
																									pop(V);
																									parameters.push_back(V);
																									printf("@PARAM %s\n", V.c_str());
																								} while(g_context.m_Stack.size()>1);
																								pop(V);
																								printf("@NAME '%s'\n", V.c_str());
																								uint32_t fun;
																								CreateFunction((char*)V.c_str(), fun);
																								g_functions[fun].m_Parameters = parameters;
																								ResetRegisters();
																								g_context.m_CurrentFunction = fun;
																							}
	| direct_declarator '(' identifier_list ')'												{
																								printf("\n@FUNCTION\n");
																								std::string V;
																								pop(V);
																								printf("@NAME(ilist) '%s'\n", V.c_str());
																								uint32_t fun;
																								CreateFunction((char*)V.c_str(), fun);
																								g_functions[fun].m_Parameters.clear();
																								ResetRegisters();
																							}
	| direct_declarator '(' ')'																{
																								printf("\n@FUNCTION\n");
																								std::string V;
																								pop(V);
																								printf("@NAME '%s'\n", V.c_str());
																								uint32_t fun;
																								CreateFunction((char*)V.c_str(), fun);
																								g_functions[fun].m_Parameters.clear();
																								ResetRegisters();
																							}
	;

pointer
	: '*'																					{ g_context.m_IsPointer = 1; }
	| '*' type_qualifier_list																{ printf("// * ?\n"); g_context.m_IsPointer = 1; }
	| '*' pointer																			{ printf("// * ??\n"); g_context.m_IsPointer = 1; }
	| '*' type_qualifier_list pointer														{ printf("// * ???\n"); g_context.m_IsPointer = 1; }
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
	: pointer															{ printf("// pointer"); }
	| direct_abstract_declarator										{ printf("// direct_abstract_declarator"); }
	| pointer direct_abstract_declarator								{ printf("// pointer direct_abstract_declarator"); }
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
	: assignment_expression														{
																					if (!stackempty())
																					{
																						std::string V;
																						pop(V);
																						g_context.m_DeclReg = PushRegister();
																						uint32_t addrs0 = CreateVar((char*)V.c_str(), g_context.m_DeclDim);
																						printf("// VARDECL %s%s[%d]\n", V.c_str(), g_context.m_IsPointer ? "*":"", g_context.m_DeclDim);
																						printf("SET R%d, 0x%.8x", g_context.m_DeclReg, (uint32_t)addrs0);
																						printf("  // &%s\n", V.c_str());
																						SetReg(g_context.m_DeclReg, (uint64_t)addrs0);
																						PopRegister(); // Pop decl. register
																					}

																					uint32_t r = PopRegister();
																					uint32_t i = g_context.m_DeclDim-g_context.m_InitAsgnCounter;
																					
																					printf("ST [R%d+%d], R%d", g_context.m_DeclReg, i, r);
																					uint32_t addrs1 = (RegVal(g_context.m_DeclReg))+i;
																					g_context.m_Heap[addrs1] = RegVal(r);
																					printf("  // [0x%.8x] = 0x%.8x\n", addrs1, RegVal(r));

																					g_context.m_InitAsgnCounter--;
																					g_context.m_IsPointer = 0;
																				}
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
	| expression ';'																			{	/*printf("// expression_statement\n");*/ g_context.m_LHS = 1; }
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
	: iteration_statement_begin expression_statement											{	printf("@LABEL for_loop%d\n", ++g_context.m_ForLoopName); PushForLoop(g_context.m_ForLoopName); g_context.m_IsForLoop = 1; }
	;
iteration_statement_prologue_decl
	: iteration_statement_begin declaration														{	printf("@LABEL for_loop%d\n", ++g_context.m_ForLoopName); PushForLoop(g_context.m_ForLoopName); g_context.m_IsForLoop = 1; }
	;

iteration_statement
	: WHILE '(' expression ')' statement
	| DO statement WHILE '(' expression ')' ';'
	| iteration_statement_prologue_expr expression_statement ')' statement						{	printf("JMP @for_loop%d\n@LABEL end_for_loop%d\n", g_context.m_ForLoopName, g_context.m_ForLoopName); g_context.m_ForLoopName = PopForLoop(); g_context.m_IsForLoop = 0; }
	| iteration_statement_prologue_expr expression_statement expression ')' statement			{	printf("JMP @for_loop%d\n@LABEL end_for_loop%d\n", g_context.m_ForLoopName, g_context.m_ForLoopName); g_context.m_ForLoopName = PopForLoop(); g_context.m_IsForLoop = 0; }
	| iteration_statement_prologue_decl expression_statement ')' statement						{	printf("JMP @for_loop%d\n@LABEL end_for_loop%d\n", g_context.m_ForLoopName, g_context.m_ForLoopName); g_context.m_ForLoopName = PopForLoop(); g_context.m_IsForLoop = 0; }
	| iteration_statement_prologue_decl expression_statement expression ')' statement			{	printf("JMP @for_loop%d\n@LABEL end_for_loop%d\n", g_context.m_ForLoopName, g_context.m_ForLoopName); g_context.m_ForLoopName = PopForLoop(); g_context.m_IsForLoop = 0; }
	;

jump_statement
	: GOTO IDENTIFIER ';'																{	printf("\t*GOTO %s\n", $2); }
	| CONTINUE ';'																		{	printf("\t*CONT\n"); }
	| BREAK ';'																			{	printf("\t*BREAK\n"); }
	| RETURN ';'																		{	
																							printf("REWINDSTACKCURSOR\n");
																							printf("RET\n"); }
	| RETURN expression ';'																{	
																							uint32_t r = PreviousRegister();
																							printf("REWINDSTACKCURSOR\n");
																							printf("RET R%d\n", r);
																						}
	;

translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

external_declaration
	: function_definition																{	printf("// ENDFUNCTION\n\n"); }
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

bool stackempty()
{
	return g_context.m_Stack.size() == 0 ? true : false;
}

void pop(std::string &_str)
{
	if (stackempty())
		printf("ERROR: string stack underflow\n");
	_str = g_context.m_Stack.top();
	g_context.m_Stack.pop();
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
