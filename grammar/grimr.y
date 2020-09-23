%{

#include <stdio.h>
#include <stdlib.h>
#include <stack>
#include <deque>
#include <string>
#include <sstream>
#include <iomanip>
#include <map>
#include <vector>

extern int yylex(void);
void yyerror(const char *);
int yyparse(void);

extern int yylineno;
extern int column;
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

enum EASTNodeType
{
	EN_Default,
	EN_Identifier,
	EN_Constant,
	EN_String,
	EN_PostfixArrayExpression,
	EN_PrimaryExpression,
	EN_UnaryValueOf,
	EN_UnaryAddressOf,
	EN_UnaryBitNot,
	EN_UnaryNegate,
	EN_UnaryLogicNot,
	EN_Mul,
	EN_Div,
	EN_Mod,
	EN_Add,
	EN_Sub,
	EN_Expression,
	EN_AssignmentExpression,
	EN_LessThan,
	EN_GreaterThan,
	EN_LessEqual,
	EN_GreaterEqual,
	EN_Equal,
	EN_NotEqual,
	EN_BitAnd,
	EN_BitOr,
	EN_BitXor,
	EN_ConditionalExpr,
	EN_LogicAnd,
	EN_LogicOr,
	EN_SelectExpression,
	EN_While,
	EN_If,
	EN_Label,
	EN_Flow,
	EN_FlowNZ,
	EN_DummyString,
	EN_Call,
	EN_Return,
	EN_EndCodeBlock,
	EN_BeginCodeBlock,
	EN_StackPush,
	EN_StackPop,
	EN_Decl,
	EN_DeclInitJunction,
	EN_DeclArray,
	EN_ArrayJunction,
	EN_ArrayWithDataJunction,
	EN_FuncDecl,
	EN_InputParamList,
	EN_InputParam,
	EN_Prologue,
	EN_Epilogue,
	EN_Statement,
	EN_EndOfProgram,
};

const char* NodeTypes[]=
{
	"EN_Default                   ",
	"EN_Identifier                ",
	"EN_Constant                  ",
	"EN_String                    ",
	"EN_PostfixArrayExpression    ",
	"EN_PrimaryExpression         ",
	"EN_UnaryValueOf              ",
	"EN_UnaryAddressOf            ",
	"EN_UnaryBitNot               ",
	"EN_UnaryNegate               ",
	"EN_UnaryLogicNot             ",
	"EN_Mul                       ",
	"EN_Div                       ",
	"EN_Mod                       ",
	"EN_Add                       ",
	"EN_Sub                       ",
	"EN_Expression                ",
	"EN_AssignmentExpression      ",
	"EN_LessThan                  ",
	"EN_GreaterThan               ",
	"EN_LessEqual                 ",
	"EN_GreaterEqual              ",
	"EN_Equal                     ",
	"EN_NotEqual                  ",
	"EN_BitAnd                    ",
	"EN_BitOr                     ",
	"EN_BitXor                    ",
	"EN_ConditionalExpr           ",
	"EN_LogicAnd                  ",
	"EN_LogicOr                   ",
	"EN_SelectExpression          ",
	"EN_While                     ",
	"EN_If                        ",
	"EN_Label                     ",
	"EN_Flow                      ",
	"EN_FlowNZ                    ",
	"EN_DummyString               ",
	"EN_Call                      ",
	"EN_Return                    ",
	"EN_EndCodeBlock              ",
	"EN_BeginCodeBlock            ",
	"EN_StackPush                 ",
	"EN_StackPop                  ",
	"EN_Decl                      ",
	"EN_DeclInitJunction          ",
	"EN_DeclArray                 ",
	"EN_ArrayJunction             ",
	"EN_ArrayWithDataJunction     ",
	"EN_FuncDecl                  ",
	"EN_InputParamList            ",
	"EN_InputParam                ",
	"EN_Prologue                  ",
	"EN_Epilogue                  ",
	"EN_Statement                 ",
	"EN_EndOfProgram              ",
};

enum EOpcode
{
	OP_NOOP,
	OP_CONST,
	OP_ADDRESSOF,
	OP_VALUEOF,
	OP_BITNOT,
	OP_NEG,
	OP_LOGICNOT,
	OP_MUL,
	OP_DIV,
	OP_MOD,
	OP_ADD,
	OP_SUB,
	OP_IDENT,
	OP_ASSIGN,
	OP_BULKASSIGN,
	OP_DATAARRAY,
	OP_RETURN,
	OP_PUSHCONTEXT,
	OP_POPCONTEXT,
	OP_IF,
	OP_WHILE,
	OP_CALL,
	OP_PUSH,
	OP_POP,
};

const char *Opcodes[]={
	"nop",
	"mov",
	"addrof",
	"valof",
	"bnot",
	"neg",
	"lnot",
	"mul",
	"div",
	"mod",
	"add",
	"sub",
	"lea",
	"st",
	"bulkassign",
	"dataarray",
	"ret",
	"pushcontext",
	"popcontext",
	"if",
	"while",
	"call",
	"push",
	"pop",
};

enum ENodeSide
{
	RIGHT_HAND_SIDE,
	LEFT_HAND_SIDE
};

struct SString
{
	std::string m_String;
	uint32_t m_Hash{0};
	uint32_t m_Address{0xFFFFFFFF};
};

struct SVariable
{
	std::string m_Name;
	uint32_t m_Hash{0};
	uint32_t m_Dimension{1};
	int m_RefCount{0};
	std::string m_Value;
	class SASTNode *m_RootNode{nullptr};
	SString *m_String{nullptr};
	std::vector<std::string> m_InitialValues;
};

struct SFunction
{
	std::string m_Name;
	uint32_t m_Hash;
	int m_RefCount{0};
	class SASTNode *m_RootNode{nullptr};
};

struct SSymbol
{
	std::string m_Value;
	uint32_t m_Address{0xFFFFFFFF};
};

class SASTNode
{
public:
	SASTNode(EASTNodeType _type, std::string _value) : m_Type(_type), m_Value(_value) {}

	void PushNode(SASTNode *_node)
	{
		m_ASTNodes.push_back(_node);
	}

	SASTNode *PeekNode()
	{
		SASTNode *node = m_ASTNodes.back();
		return node;
	}

	SASTNode *PopNode()
	{
		SASTNode *node = m_ASTNodes.back();
		m_ASTNodes.pop_back();
		return node;
	}

	EOpcode m_Opcode{OP_NOOP};
	EASTNodeType m_Type{EN_Default};
	ENodeSide m_Side{RIGHT_HAND_SIDE};
	int m_ScopeDepth{0};
	SString *m_String{nullptr};
	std::string m_Value;
	std::vector<SASTNode*> m_ASTNodes;
};

struct SASTScanContext
{
	std::vector<SASTNode*> m_ASTNodes;

	void PushNode(SASTNode *_node)
	{
		m_ASTNodes.push_back(_node);
	}

	SASTNode *PeekNode()
	{
		SASTNode *node = m_ASTNodes.back();
		return node;
	}

	SASTNode *PopNode()
	{
		SASTNode *node = m_ASTNodes.back();
		m_ASTNodes.pop_back();
		return node;
	}

	SString *AllocateOrRetreiveString(const char *string)
	{
		uint32_t hash = HashString(string);

		auto found = m_StringTable.find(hash);
		if (found!=m_StringTable.end())
			return found->second;

		SString *str = new SString();
		uint32_t allocaddress = m_StringAddress;
		str->m_Address = allocaddress;
		str->m_Hash = hash;
		str->m_String = string;

		printf("Allocated string at %d\n", allocaddress);

		m_StringAddress += strlen(string);

		m_StringTable[hash] = str;

		return str;
	}

	std::string PushRegister()
	{
		uint32_t r = m_CurrentRegister++;
		return std::string("r"+std::to_string(r));
	}

	std::string PopRegister()
	{
		uint32_t r = --m_CurrentRegister;
		return std::string("r"+std::to_string(r));
	}

	void ResetRegister()
	{
		m_CurrentRegister = 0;
	}

	std::string PushLabel(std::string labelname)
	{
		uint32_t r = m_CurrentAutoLabel++;
		return std::string(labelname+std::to_string(r));
	}

	SVariable *FindSymbolInSymbolTable(uint32_t hash)
	{
		for(auto &var : m_Variables)
			if (var->m_Hash == hash)
				return var;
		return nullptr;
	}

	SFunction *FindFunctionInFunctionTable(uint32_t hash)
	{
		for(auto &fun : m_Functions)
			if (fun->m_Hash == hash)
				return fun;
		return nullptr;
	}

	std::string m_CurrentFunctionName;
	std::vector<SVariable*> m_Variables;
	std::vector<SFunction*> m_Functions;
	std::map<uint32_t, SSymbol> m_SymbolTable;
	std::map<uint32_t, SString*> m_StringTable;
	uint32_t m_StringAddress{0};
	int m_CurrentRegister{0};
	int m_CurrentAutoLabel{0};
};

SASTScanContext g_ASC;

%}

%union
{
	char string[128];
	unsigned int numeric;
	class SASTNode *astnode;
}

%token <string> IDENTIFIER
%token <numeric> CONSTANT
%token <string> STRING_LITERAL

%token LESS_OP GREATER_OP LESSEQUAL_OP GREATEREQUAL_OP EQUAL_OP NOTEQUAL_OP AND_OP OR_OP
%token VAR FUNCTION IF WHILE BEGINBLOCK ENDBLOCK RETURN

%type <astnode> simple_identifier
%type <astnode> simple_constant
%type <astnode> simple_string

%type <astnode> variable_declaration_statement
%type <astnode> functioncall_statement
%type <astnode> expression_statement
%type <astnode> while_statement
%type <astnode> if_statement
%type <astnode> return_statement
%type <astnode> any_statement

%type <astnode> code_block_start
%type <astnode> code_block_end
%type <astnode> code_block_body

%type <astnode> primary_expression
%type <astnode> unary_expression
%type <astnode> postfix_expression

%type <astnode> variable_declaration_item
%type <astnode> variable_declaration
%type <astnode> function_def

%type <astnode> parameter_list
%type <astnode> expression_list

%type <astnode> additive_expression
%type <astnode> multiplicative_expression
%type <astnode> relational_expression
%type <astnode> equality_expression
%type <astnode> and_expression
%type <astnode> exclusive_or_expression
%type <astnode> inclusive_or_expression
%type <astnode> logical_and_expression
%type <astnode> logical_or_expression
%type <astnode> conditional_expression
%type <astnode> assignment_expression
%type <astnode> expression

%type <astnode> translation_unit
%type <astnode> program

%start program
%%

simple_identifier
	: IDENTIFIER																				{
																									uint32_t hash = HashString($1);
																									$$ = new SASTNode(EN_Identifier, std::string($1));
																									$$->m_Opcode = OP_IDENT;
																									g_ASC.PushNode($$);
																								}
	;

simple_constant
	: CONSTANT																					{
																									std::stringstream stream;
																									stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << $1;
																									std::string result( stream.str() );
																									$$ = new SASTNode(EN_Constant, std::string("0x")+result);
																									$$->m_Opcode = OP_CONST;
																									g_ASC.PushNode($$);
																								}
	;

simple_string
	: STRING_LITERAL																			{
																									$$ = new SASTNode(EN_String, yytext); // $1 is just a single word, yytext includes spaces
																									$$->m_String = g_ASC.AllocateOrRetreiveString(yytext);
																									g_ASC.PushNode($$);
																								}
	;

primary_expression
	: simple_identifier
	| simple_constant
	| simple_string
	;

postfix_expression
	: primary_expression																		/*{
																									SASTNode *exprnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_PrimaryExpression, "");
																									$$->PushNode(exprnode);
																									g_ASC.PushNode($$);
																								}*/
	| postfix_expression '[' expression ']'														{
																									SASTNode *offsetexpressionnode = g_ASC.PopNode();
																									SASTNode *exprnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_PostfixArrayExpression, "");
																									$$->PushNode(exprnode);
																									$$->PushNode(offsetexpressionnode);
																									$$->m_Opcode = OP_ADD;
																									g_ASC.PushNode($$);
																								}
	;

unary_expression
	: postfix_expression
	| '~' unary_expression																		{
																									SASTNode *unaryexpressionnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_UnaryBitNot, "");
																									$$->PushNode(unaryexpressionnode);
																									$$->m_Opcode = OP_BITNOT;
																									g_ASC.PushNode($$);
																								}
	| '-' unary_expression																		{
																									SASTNode *unaryexpressionnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_UnaryNegate, "");
																									$$->PushNode(unaryexpressionnode);
																									$$->m_Opcode = OP_NEG;
																									g_ASC.PushNode($$);
																								}
	| '!' unary_expression																		{
																									SASTNode *unaryexpressionnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_UnaryLogicNot, "");
																									$$->PushNode(unaryexpressionnode);
																									$$->m_Opcode = OP_LOGICNOT;
																									g_ASC.PushNode($$);
																								}
	| '&' unary_expression																		{
																									SASTNode *unaryexpressionnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_UnaryAddressOf, "");
																									$$->PushNode(unaryexpressionnode);
																									$$->m_Opcode = OP_ADDRESSOF;
																									g_ASC.PushNode($$);
																								}
	| '*' unary_expression																		{
																									SASTNode *n0=g_ASC.PopNode();
																									$$ = new SASTNode(EN_UnaryValueOf, "");
																									$$->PushNode(n0);
																									$$->m_Opcode = OP_VALUEOF;
																									g_ASC.PushNode($$);
																								}
	;

multiplicative_expression
	: unary_expression
	| multiplicative_expression '*' unary_expression											{
																									$$ = new SASTNode(EN_Mul, "");
																									SASTNode *n0=g_ASC.PopNode();
																									SASTNode *n1=g_ASC.PopNode();
																									$$->PushNode(n0);
																									$$->PushNode(n1);
																									$$->m_Opcode = OP_MUL;
																									g_ASC.PushNode($$);
																								}
	| multiplicative_expression '/' unary_expression											{
																									$$ = new SASTNode(EN_Div, "");
																									SASTNode *n0=g_ASC.PopNode();
																									SASTNode *n1=g_ASC.PopNode();
																									$$->PushNode(n0);
																									$$->PushNode(n1);
																									$$->m_Opcode = OP_DIV;
																									g_ASC.PushNode($$);
																								}
	| multiplicative_expression '%' unary_expression											{
																									$$ = new SASTNode(EN_Mod, "");
																									SASTNode *n0=g_ASC.PopNode();
																									SASTNode *n1=g_ASC.PopNode();
																									$$->PushNode(n0);
																									$$->PushNode(n1);
																									$$->m_Opcode = OP_MOD;
																									g_ASC.PushNode($$);
																								}
	;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression											{
																									$$ = new SASTNode(EN_Add, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_ADD;
																									g_ASC.PushNode($$);
																								}
	| additive_expression '-' multiplicative_expression											{
																									$$ = new SASTNode(EN_Sub, "");
																									SASTNode *rightnode = g_ASC.PopNode();
																									SASTNode *leftnode = g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_SUB;
																									g_ASC.PushNode($$);
																								}
	;

relational_expression
	: additive_expression
	| relational_expression LESS_OP additive_expression											{
																									$$ = new SASTNode(EN_LessThan, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									g_ASC.PushNode($$);
																								}
	| relational_expression GREATER_OP additive_expression										{
																									$$ = new SASTNode(EN_GreaterThan, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									g_ASC.PushNode($$);
																								}
	| relational_expression LESSEQUAL_OP additive_expression									{
																									$$ = new SASTNode(EN_LessEqual, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									g_ASC.PushNode($$);
																								}
	| relational_expression GREATEREQUAL_OP additive_expression									{
																									$$ = new SASTNode(EN_GreaterEqual, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									g_ASC.PushNode($$);
																								}
	;
    
equality_expression
	: relational_expression
	| equality_expression EQUAL_OP relational_expression										{
																									$$ = new SASTNode(EN_Equal, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									g_ASC.PushNode($$);
																								}
	| equality_expression NOTEQUAL_OP relational_expression										{
																									$$ = new SASTNode(EN_NotEqual, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									g_ASC.PushNode($$);
																								}
	;

and_expression
	: equality_expression
	| and_expression '&' equality_expression													{
																									$$ = new SASTNode(EN_BitAnd, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									g_ASC.PushNode($$);
																								}
	;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression												{
																									$$ = new SASTNode(EN_BitXor, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									g_ASC.PushNode($$);
																								}
	;

inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression										{
																									$$ = new SASTNode(EN_BitOr, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									g_ASC.PushNode($$);
																								}
	;

logical_and_expression
	: inclusive_or_expression
	| logical_and_expression AND_OP inclusive_or_expression										{
																									$$ = new SASTNode(EN_LogicAnd, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									g_ASC.PushNode($$);
	}
	;

logical_or_expression
	: logical_and_expression
	| logical_or_expression OR_OP logical_and_expression										{
																									$$ = new SASTNode(EN_LogicOr, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									g_ASC.PushNode($$);
																								}
	;

conditional_expression
	: logical_or_expression																		/*{
																									$$ = new SASTNode(EN_ConditionalExpr, "");
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);
																									g_ASC.PushNode($$);
																								}*/
	;

assignment_expression
	: conditional_expression
	| unary_expression '=' assignment_expression												{
																									$$ = new SASTNode(EN_AssignmentExpression, "");
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_ASSIGN;
																									g_ASC.PushNode($$);
																								}
	;

expression
	: assignment_expression																	
	/*| expression ',' assignment_expression														{
																								}*/ // NOTE: This is causing much grief and I don't think I need it at this point
	;

expression_statement
	: expression ';'																			{
																									$$ = new SASTNode(EN_Statement, "");
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);
																									g_ASC.PushNode($$);
																								}
	;

if_statement
	: IF '(' expression ')' code_block_start code_block_body code_block_end						{
																									$$ = new SASTNode(EN_If, "");

																									// Remove epilogue
																									g_ASC.PopNode();

																									// Create code block node
																									SASTNode *codeblocknode = new SASTNode(EN_BeginCodeBlock, "");
																									codeblocknode->m_Opcode = OP_PUSHCONTEXT;

																									SASTNode *endcodeblocknode = new SASTNode(EN_EndCodeBlock, "");
																									endcodeblocknode->m_Opcode = OP_POPCONTEXT;

																									// Collect everything up till prologue
																									bool done = false;
																									do
																									{
																										SASTNode *n0 = g_ASC.PeekNode();
																										done = n0->m_Type == EN_Prologue ? true:false;
																										if (done)
																											break;
																										g_ASC.PopNode();
																										codeblocknode->PushNode(n0);
																									} while (1);

																									// Remove prologue
																									g_ASC.PopNode();

																									SASTNode *exprnode=g_ASC.PopNode();
																									$$->PushNode(exprnode);
																									$$->PushNode(codeblocknode);
																									$$->PushNode(endcodeblocknode);
																									$$->m_Opcode = OP_IF;
																									g_ASC.PushNode($$);
																								}
	;

while_statement
	: WHILE '(' expression ')' code_block_start code_block_body code_block_end					{
																									$$ = new SASTNode(EN_While, "");

																									// Remove epilogue
																									g_ASC.PopNode();

																									// Create code block node
																									SASTNode *codeblocknode = new SASTNode(EN_BeginCodeBlock, "");
																									codeblocknode->m_Opcode = OP_PUSHCONTEXT;

																									SASTNode *endcodeblocknode = new SASTNode(EN_EndCodeBlock, "");
																									endcodeblocknode->m_Opcode = OP_POPCONTEXT;

																									// Collect everything up till prologue
																									bool done = false;
																									do
																									{
																										SASTNode *n0 = g_ASC.PeekNode();
																										done = n0->m_Type == EN_Prologue ? true:false;
																										if (done)
																											break;
																										g_ASC.PopNode();
																										codeblocknode->PushNode(n0);
																									} while (1);

																									// Remove prologue
																									g_ASC.PopNode();

																									SASTNode *exprnode=g_ASC.PopNode();
																									$$->PushNode(exprnode);
																									$$->PushNode(codeblocknode);
																									$$->PushNode(endcodeblocknode);
																									$$->m_Opcode = OP_WHILE;
																									g_ASC.PushNode($$);
																								}
	;

variable_declaration_item
	: simple_identifier 																		{
																								}
	| simple_identifier '=' expression 															{
																									$$ = new SASTNode(EN_DeclInitJunction, "");
																									SASTNode *valnode=g_ASC.PopNode();
																									SASTNode *namenode=g_ASC.PopNode();
																									$$->PushNode(namenode);
																									$$->PushNode(valnode);
																									$$->m_Opcode = OP_ASSIGN;
																									g_ASC.PushNode($$);
																								}
	| simple_identifier '[' expression ']'														{
																									$$ = new SASTNode(EN_DeclArray, "");
																									SASTNode *dimnode=g_ASC.PopNode();
																									SASTNode *namenode=g_ASC.PopNode();
																									$$->PushNode(namenode);
																									$$->PushNode(dimnode);
																									g_ASC.PushNode($$);
																								}
	| simple_identifier '[' expression ']' '=' code_block_start expression_list code_block_end	{
																									$$ = new SASTNode(EN_DeclInitJunction, "");

																									// Discard epilogue
																									g_ASC.PopNode();

																									// Create initializer array
																									SASTNode *initarray = new SASTNode(EN_ArrayWithDataJunction, "");
																									// Collect everything up till prologue
																									bool done = false;
																									do
																									{
																										SASTNode *n0 = g_ASC.PeekNode();
																										done = n0->m_Type == EN_Prologue ? true:false;
																										if (done)
																											break;
																										g_ASC.PopNode();
																										initarray->PushNode(n0->m_ASTNodes[0]); // Remove the EN_Expression
																									} while (1);
																									initarray->m_Opcode = OP_DATAARRAY;

																									// Discard prologue
																									g_ASC.PopNode();

																									SASTNode *dimnode=g_ASC.PopNode();
																									SASTNode *namenode=g_ASC.PopNode();
																									$$->PushNode(namenode);
																									$$->PushNode(dimnode);
																									$$->PushNode(initarray);
																									$$->m_Opcode = OP_BULKASSIGN;
																									g_ASC.PushNode($$);
																								}
	| simple_identifier '['  ']' '=' code_block_start expression_list code_block_end			{
																									$$ = new SASTNode(EN_DeclInitJunction, "");

																									// Discard epilogue
																									g_ASC.PopNode();

																									// Create initializer array
																									SASTNode *initarray = new SASTNode(EN_ArrayWithDataJunction, "");
																									// Collect everything up till prologue
																									bool done = false;
																									do
																									{
																										SASTNode *n0 = g_ASC.PeekNode();
																										done = n0->m_Type == EN_Prologue ? true:false;
																										if (done)
																											break;
																										g_ASC.PopNode();
																										initarray->PushNode(n0->m_ASTNodes[0]); // Remove the EN_Expression
																									} while (1);
																									initarray->m_Opcode = OP_DATAARRAY;

																									// Discard prologue
																									g_ASC.PopNode();

																									// Set dimension to init array size
																									std::string dim = std::to_string(initarray->m_ASTNodes.size());
																									SASTNode *dimnode=new SASTNode(EN_Constant, dim);
																									dimnode->m_Opcode = OP_CONST;
																									SASTNode *namenode=g_ASC.PopNode();
																									$$->PushNode(namenode);
																									$$->PushNode(dimnode);
																									$$->PushNode(initarray);
																									$$->m_Opcode = OP_BULKASSIGN;
																									g_ASC.PushNode($$);
																								}
	;

variable_declaration
	: VAR variable_declaration_item																{
																									$$ = new SASTNode(EN_Decl, "");
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);
																									g_ASC.PushNode($$);

																									// Also store the variable in function list for later retreival
																									SVariable *var = new SVariable();
																									var->m_Name = (n0->m_Type==EN_DeclInitJunction || n0->m_Type==EN_DeclArray) ? n0->m_ASTNodes[0]->m_Value : n0->m_Value;
																									var->m_Hash = HashString(var->m_Name.c_str());
																									var->m_RootNode = $$;
																									var->m_Dimension = 1;
																									var->m_RefCount = 0;
																									var->m_Value = "";
																									g_ASC.m_Variables.push_back(var);
																								}
	| variable_declaration ',' variable_declaration_item										{
																									$$ = new SASTNode(EN_Decl, "");
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);
																									g_ASC.PushNode($$);

																									// Also store the variable in function list for later retreival
																									SVariable *var = new SVariable();
																									var->m_Name = (n0->m_Type==EN_DeclInitJunction || n0->m_Type==EN_DeclArray) ? n0->m_ASTNodes[0]->m_Value : n0->m_Value;
																									var->m_Hash = HashString(var->m_Name.c_str());
																									var->m_RootNode = $$;
																									var->m_Dimension = 1;
																									var->m_RefCount = 0;
																									var->m_Value = "";
																									g_ASC.m_Variables.push_back(var);
																								}
	;

variable_declaration_statement
	: variable_declaration ';'																	/*{}*/
	;

expression_list
	: expression																				{
																									$$ = new SASTNode(EN_Expression, "");
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);
																									g_ASC.PushNode($$);
																								}
	| expression_list ',' expression															{
																									$$ = new SASTNode(EN_Expression, "");
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);
																									g_ASC.PushNode($$);
																								}
	;

parameter_list
	: '(' ')'																					{}
	| '(' expression_list ')'																	{}
	;

functioncall_statement
	: simple_identifier parameter_list ';'														{
																									$$ = new SASTNode(EN_Call, "");
																									bool done = false;
																									int paramcount = 0;
																									do
																									{
																										SASTNode *paramnode = g_ASC.PeekNode();
																										done = paramnode->m_Type == EN_Expression ? false:true;
																										if (done)
																											break;
																										g_ASC.PopNode();
																										// Replace EN_Expression with EN_StackPush
																										paramnode->m_Type = EN_StackPush;
																										paramnode->m_Opcode = OP_PUSH;
																										$$->PushNode(paramnode);
																										++paramcount;
																									} while (1);
																									SASTNode *namenode = g_ASC.PopNode();
																									$$->PushNode(namenode);
																									$$->m_Opcode = OP_CALL;
																									$$->m_Value = std::string("(paramcount: ") + std::to_string(paramcount) + std::string(")");
																									g_ASC.PushNode($$);
																								}
	;

code_block_start
	: BEGINBLOCK																				{
																									$$ = new SASTNode(EN_Prologue, "");
																									g_ASC.PushNode($$);
																								}
	;

code_block_end
	: ENDBLOCK																					{
																									$$ = new SASTNode(EN_Epilogue, "");
																									g_ASC.PushNode($$);
																								}
	;

return_statement
	: RETURN ';'																				{
																									$$ = new SASTNode(EN_Return, "");
																									$$->m_Opcode = OP_RETURN;
																									g_ASC.PushNode($$);
																								}
	;

any_statement
	: functioncall_statement																	{
																								}
	| expression_statement																		{
																								}
	| if_statement																				{
																								}
	| while_statement																			{
																								}
	| variable_declaration_statement															{
																								}
	| return_statement																			{
																								}
	;

code_block_body
	: any_statement
	| code_block_body any_statement
	;

function_def
	: FUNCTION simple_identifier parameter_list code_block_start code_block_body code_block_end	{
																									$$ = new SASTNode(EN_FuncDecl, "");

																									// Remove epilogue
																									g_ASC.PopNode();

																									// Create code block node
																									SASTNode *codeblocknode = new SASTNode(EN_BeginCodeBlock, "");
																									codeblocknode->m_Opcode = OP_PUSHCONTEXT;

																									SASTNode *endcodeblocknode = new SASTNode(EN_EndCodeBlock, "");
																									endcodeblocknode->m_Opcode = OP_POPCONTEXT;

																									// Collect everything up till prologue
																									bool done = false;
																									do
																									{
																										SASTNode *n0 = g_ASC.PeekNode();
																										done = n0->m_Type == EN_Prologue ? true:false;
																										if (done)
																											break;
																										g_ASC.PopNode();
																										codeblocknode->PushNode(n0);
																									} while (1);

																									// Remove prologue
																									g_ASC.PopNode();
																									// Collect call parameter nodes
																									done = false;
																									do
																									{
																										SASTNode *n0 = g_ASC.PeekNode();
																										done = n0->m_Type == EN_Expression ? false:true;
																										if (done)
																											break;
																										n0->m_Type = EN_StackPop;
																										g_ASC.PopNode();
																										// Add the input parameter to code block
																										$$->PushNode(n0);
																									} while (1);

																									// Add the name after input parameters
																									SASTNode *namenode = g_ASC.PopNode();
																									$$->PushNode(namenode);

																									// Add the code block after name
																									$$->PushNode(codeblocknode);
																									$$->PushNode(endcodeblocknode);

																									g_ASC.PushNode($$);

																									// Also store the function in function list for later retreival
																									SFunction *func = new SFunction();
																									func->m_Name = namenode->m_Value;
																									func->m_Hash = HashString(func->m_Name.c_str());
																									func->m_RootNode = $$;
																									g_ASC.m_Functions.push_back(func);
																								}
	;

translation_unit
	: translation_unit variable_declaration_statement
	| translation_unit function_def
	| variable_declaration_statement
	| function_def
	;

program
	: translation_unit																			{
																								}
	;
%%

void DebugDumpNode(FILE *_fp, int scopeDepth, SASTNode *node)
{
	node->m_ScopeDepth = scopeDepth;

	std::string spaces = ".................................................................................";
	fprintf(_fp, "%s%s(%d) %s %s\n", spaces.substr(0, node->m_ScopeDepth).c_str(), NodeTypes[node->m_Type], node->m_ScopeDepth, Opcodes[node->m_Opcode], node->m_Value.c_str());

	for (auto &subnode : node->m_ASTNodes)
		DebugDumpNode(_fp, scopeDepth+1, subnode);
}

void DebugDump(const char *_filename)
{
	FILE *fp = fopen(_filename, "w");

	fprintf(fp, "\n------------Code----------------------\n");

	int scopeDepth = 0;
	for (auto &node : g_ASC.m_ASTNodes)
		DebugDumpNode(fp, scopeDepth, node);

	fprintf(fp, "\n------------Symbol table--------------\n");

	for (auto &func : g_ASC.m_Functions)
		fprintf(fp, "Function '%s', hash %.8X\n", func->m_Name.c_str(), func->m_Hash);

	for (auto &var : g_ASC.m_Variables)
		fprintf(fp, "Variable '%s', hash %.8X\n", var->m_Name.c_str(), var->m_Hash);
	fclose(fp);
}

void yyerror(const char *s) {
	printf("line #%d columnd #%d : %s %s\n", yylineno, column, s, yytext );
	err++;
}
