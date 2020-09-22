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
	EN_FunctionName,
	EN_Constant,
	EN_String,
	EN_Postfix,
	EN_PostfixArrayExpression,
	EN_PrimaryExpression,
	EN_UnaryValueOf,
	EN_UnaryAddressOf,
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
	EN_LogicAnd,
	EN_LogicOr,
	EN_SelectExpression,
	EN_ExpressionList,
	EN_While,
	EN_If,
	EN_Label,
	EN_Flow,
	EN_FlowNZ,
	EN_DummyString,
	EN_Call,
	EN_Return,
	EN_StackOp,
	EN_Decl,
	EN_DeclInitJunction,
	EN_DeclArray,
	EN_ArrayJunction,
	EN_ArrayWithDataJunction,
	EN_FuncDecl,
	EN_InputParamList,
	EN_InputParam,
	EN_CallParam,
	EN_Prologue,
	EN_Epilogue,
	EN_Statement,
	EN_EndOfProgram,
};

const char* NodeTypes[]=
{
	"EN_Default                   ",
	"EN_Identifier                ",
	"EN_FunctionName              ",
	"EN_Constant                  ",
	"EN_String                    ",
	"EN_Postfix                   ",
	"EN_PostfixArrayExpression    ",
	"EN_PrimaryExpression         ",
	"EN_UnaryValueOf              ",
	"EN_UnaryAddressOf            ",
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
	"EN_LogicAnd                  ",
	"EN_LogicOr                   ",
	"EN_SelectExpression          ",
	"EN_ExpressionList            ",
	"EN_While                     ",
	"EN_If                        ",
	"EN_Label                     ",
	"EN_Flow                      ",
	"EN_FlowNZ                    ",
	"EN_DummyString               ",
	"EN_Call                      ",
	"EN_Return                    ",
	"EN_StackOp                   ",
	"EN_Decl                      ",
	"EN_DeclInit                  ",
	"EN_DeclArray                 ",
	"EN_ArrayJunction             ",
	"EN_ArrayWithDataJunction     ",
	"EN_FuncDecl                  ",
	"EN_InputParamList            ",
	"EN_InputParam                ",
	"EN_CallParam                 ",
	"EN_Prologue                  ",
	"EN_Epilogue                  ",
	"EN_Statement                 ",
	"EN_EndOfProgram              ",
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

class SBaseASTNode
{
public:
	SBaseASTNode() {m_Value = "{n/a}"; }
	SBaseASTNode(EASTNodeType type, std::string val) { m_Type = type; m_Value = val; }

	// Copy while keeping the same order
	void CopySubNodes(SBaseASTNode *sourcenode)
	{
		while (sourcenode->m_SubNodes.size())
		{
			m_SubNodes.push_front(sourcenode->m_SubNodes.front());
			sourcenode->m_SubNodes.pop_front();
		}
	}
	// Copy while reversing the order
	void CopySubNodesReverse(SBaseASTNode *sourcenode)
	{
		while (sourcenode->m_SubNodes.size())
		{
			m_SubNodes.push_front(sourcenode->m_SubNodes.back());
			sourcenode->m_SubNodes.pop_back();
		}
	}
	void PushSubNode(SBaseASTNode *subnode)
	{
		m_SubNodes.push_front(subnode);
	}

	EASTNodeType m_Type{EN_Default};
	ENodeSide m_Side{RIGHT_HAND_SIDE};
	SString *m_String{nullptr};
	std::string m_Value;
	std::string m_Comment;
	std::deque<SBaseASTNode*> m_SubNodes;
};

class SASTNode
{
public:
	EASTNodeType m_Type{EN_Default};
	ENodeSide m_Side{RIGHT_HAND_SIDE};
	int m_ScopeDepth{0};
	SString *m_String{nullptr};
	std::string m_Value;
	std::vector<SASTNode*> m_ASTNodes;
};

struct SVariable
{
	std::string m_Name;
	uint32_t m_Hash{0};
	uint32_t m_Dimension{1};
	SString *m_String{nullptr};
	std::vector<std::string> m_InitializedValues;
	int m_ScopeDepth{0};
};

struct SFunction
{
	std::string m_Name;
	uint32_t m_Hash;
	int m_ScopeDepth{0};
	int m_RefCount{0};
	std::vector<SASTNode*> m_InputParameters;
	std::vector<SASTNode*> m_PrologueBlock;
	std::vector<SASTNode*> m_CodeBlock;
	std::vector<SASTNode*> m_EpilogueBlock;
};

class CCompilerContext
{
public:
	int m_ScopeDepth{0};

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
};

struct SSymbol
{
	std::string m_Value;
	uint32_t m_Address{0xFFFFFFFF};
};

enum EOpcode
{
	OP_NOOP,
	OP_MUL,
	OP_DIV,
	OP_MOD,
	OP_ADD,
	OP_SUB,
	OP_STORE,
	OP_LOAD,
	OP_LESS,
	OP_GREATER,
	OP_LE,
	OP_GE,
	OP_EQ,
	OP_NEQ,
	OP_LABEL,
	OP_JUMP,
	OP_JUMPNZ,
	OP_CALL,
	OP_RETURN,
	OP_PUSH,
	OP_POP,
	OP_LEA,
	OP_DUMMYSTRING,
	OP_BITAND,
	OP_BITOR,
	OP_BITXOR,
	OP_SELECT,
};

const char *Opcodes[]={
	"\tnop   ",
	"\tmul   ",
	"\tdiv   ",
	"\tmod   ",
	"\tadd   ",
	"\tsub   ",
	"\tst    ",
	"\tld    ",
	"\tcmp.l ",
	"\tcmp.g ",
	"\tcmp.le",
	"\tcmp.ge",
	"\tcmp.e ",
	"\tcmp.ne",
	"@label",
	"\tjmp   ",
	"\tjmp.nz",
	"\tcall  ",
	"ret   ",
	"\tpush  ",
	"\tpop   ",
	"\tlea   ",
	"",
	"\tand   ",
	"\tor    ",
	"\txor   ",
	"\tsel   ",
};

struct SCodeNode
{
	EOpcode m_Op{OP_NOOP};
	std::string m_ValueOut;
	std::string m_ValueIn[4];
	int m_OutputCount{1};
	int m_InputCount{0};
};

struct SParserContext
{
	SParserContext()
	{
	}

	SSymbol &DeclareSymbol(std::string &symbol)
	{
		SSymbol sym;

		// Check for duplicate define
		uint32_t hash = HashString(symbol.c_str());
		auto found = m_SymbolTable.find(hash);
		if (found != m_SymbolTable.end())
		{
			//printf("ERROR: symbol %s already defined\n", symbol.c_str());
			return found->second;
		}
		else
		{
			//printf("defining symbol %s\n", symbol.c_str());
			sym.m_Value = symbol;
			m_SymbolTable[hash] = sym;

			return m_SymbolTable[hash];
		}
	}

	bool FindSymbol(std::string &symbol, SSymbol &sym)
	{
		uint32_t hash = HashString(symbol.c_str());
		auto found = m_SymbolTable.find(hash);
		if (found != m_SymbolTable.end())
		{
			sym = found->second;
			return true;
		}

		//printf("ERROR: symbol %s not found\n", symbol.c_str());
		return false;
	}

	void PushNode(SBaseASTNode *node) { m_NodeStack.push_back(node); }
	SBaseASTNode *TopNode() { return m_NodeStack.back(); }
	SBaseASTNode *PopNode() { SBaseASTNode *node = m_NodeStack.back(); m_NodeStack.pop_back(); return node; }

	std::deque<SBaseASTNode*> m_NodeStack;
	std::vector<SASTNode*> m_ASTNodes;
	std::map<uint32_t, SSymbol> m_SymbolTable;
	std::map<uint32_t, SString*> m_StringTable;
	std::vector<CCompilerContext*> m_CompilerContextList;
	std::vector<SCodeNode*> m_CodeNodes;
	uint32_t m_StringAddress{0};
};

static int g_currentregister = 0;
static int g_currentautolabel = 0;

std::string PushRegister()
{
	uint32_t r = g_currentregister++;
	return std::string("r"+std::to_string(r));
}

std::string PopRegister()
{
	uint32_t r = --g_currentregister;
	return std::string("r"+std::to_string(r));
}

void ResetRegister()
{
	g_currentregister = 0;
}

std::string PushLabel(std::string labelname)
{
	uint32_t r = g_currentautolabel++;
	return std::string(labelname+std::to_string(r));
}

void ConvertInputParams(SBaseASTNode *paramlistnode)
{
	size_t sz = paramlistnode->m_SubNodes.size();
	for (size_t i=0; i<sz; ++i)
	{
		SBaseASTNode *idnode = paramlistnode->m_SubNodes.back();
		paramlistnode->m_SubNodes.pop_back();
		SBaseASTNode *param = idnode->m_SubNodes.back();
		param->m_Type = EN_InputParam;
		paramlistnode->m_SubNodes.push_front(idnode);
	}
}

SString *AllocateOrRetreiveString(SParserContext *ctx, const char *string)
{
	uint32_t hash = HashString(string);

	auto found = ctx->m_StringTable.find(hash);
	if (found!=ctx->m_StringTable.end())
		return found->second;

	SString *str = new SString();
	uint32_t allocaddress = ctx->m_StringAddress;
	str->m_Address = allocaddress;
	str->m_Hash = hash;
	str->m_String = string;

	printf("Allocated string at %d\n", allocaddress);

	ctx->m_StringAddress += strlen(string);

	ctx->m_StringTable[hash] = str;

	return str;
}

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

%token LESS_OP GREATER_OP LESSEQUAL_OP GREATEREQUAL_OP EQUAL_OP NOTEQUAL_OP AND_OP OR_OP
%token VAR FUNCTION IF WHILE BEGINBLOCK ENDBLOCK RETURN

%type <astnode> simple_identifier
%type <astnode> simple_constant
%type <astnode> simple_string

%type <astnode> variable_declaration_statement
%type <astnode> function_statement
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
																									$$ = new SBaseASTNode(EN_Identifier, $1);
																									g_context.PushNode($$);
																								}
	;

simple_constant
	: CONSTANT																					{
																									std::stringstream stream;
																									stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << $1;
																									std::string result( stream.str() );
																									$$ = new SBaseASTNode(EN_Constant, std::string("0x")+result);
																									g_context.PushNode($$);
																								}
	;

simple_string
	: STRING_LITERAL																			{
																									$$ = new SBaseASTNode(EN_String, yytext); // $1 is just a single word, yytext includes spaces
																									$$->m_String = AllocateOrRetreiveString(&g_context, yytext);
																									g_context.PushNode($$);
																								}
	;

primary_expression
	: simple_identifier
	| simple_constant
	| simple_string
	;

postfix_expression
	: primary_expression																		{
																									// Only pull the offset from the stack
																									SBaseASTNode *exprnode=g_context.PopNode();

																									// This will be an addition operation to the previous address generated by the target node
																									$$ = new SBaseASTNode(EN_PrimaryExpression, "");

																									$$->PushSubNode(exprnode);
																									g_context.PushNode($$);
																								}
	| postfix_expression '[' expression ']'														{
																									// Only pull the offset from the stack
																									SBaseASTNode *offsetexpressionnode=g_context.PopNode();
																									SBaseASTNode *exprnode=g_context.PopNode();

																									// This will be an addition operation to the previous address generated by the target node
																									$$ = new SBaseASTNode(EN_PostfixArrayExpression, "");
																									$$->PushSubNode(exprnode);
																									$$->PushSubNode(offsetexpressionnode);
																									g_context.PushNode($$);
																								}
	;

unary_expression
	: postfix_expression
	| '&' unary_expression																		{
																									SBaseASTNode *n0=g_context.PopNode();

																									$$ = new SBaseASTNode(EN_UnaryAddressOf, "");
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	| '*' unary_expression																		{
																									SBaseASTNode *n0=g_context.PopNode();
																									$$ = new SBaseASTNode(EN_UnaryValueOf, "");
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	;

multiplicative_expression
	: unary_expression
	| multiplicative_expression '*' unary_expression											{
																									$$ = new SBaseASTNode(EN_Mul, "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->PushSubNode(n0);
																									$$->PushSubNode(n1);
																									g_context.PushNode($$);
																								}
	| multiplicative_expression '/' unary_expression											{
																									$$ = new SBaseASTNode(EN_Div, "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->PushSubNode(n0);
																									$$->PushSubNode(n1);
																									g_context.PushNode($$);
																								}
	| multiplicative_expression '%' unary_expression											{
																									$$ = new SBaseASTNode(EN_Mod, "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->PushSubNode(n0);
																									$$->PushSubNode(n1);
																									g_context.PushNode($$);
																								}
	;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression											{
																									$$ = new SBaseASTNode(EN_Add, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	| additive_expression '-' multiplicative_expression											{
																									$$ = new SBaseASTNode(EN_Sub, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	;

relational_expression
	: additive_expression
	| relational_expression LESS_OP additive_expression											{
																									$$ = new SBaseASTNode(EN_LessThan, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	| relational_expression GREATER_OP additive_expression										{
																									$$ = new SBaseASTNode(EN_GreaterThan, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	| relational_expression LESSEQUAL_OP additive_expression									{
																									$$ = new SBaseASTNode(EN_LessEqual, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	| relational_expression GREATEREQUAL_OP additive_expression									{
																									$$ = new SBaseASTNode(EN_GreaterEqual, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	;
    
equality_expression
	: relational_expression
	| equality_expression EQUAL_OP relational_expression										{
																									$$ = new SBaseASTNode(EN_Equal, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	| equality_expression NOTEQUAL_OP relational_expression										{
																									$$ = new SBaseASTNode(EN_NotEqual, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	;

and_expression
	: equality_expression
	| and_expression '&' equality_expression													{
																									$$ = new SBaseASTNode(EN_BitAnd, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression												{
																									$$ = new SBaseASTNode(EN_BitXor, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	;

inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression										{
																									$$ = new SBaseASTNode(EN_BitOr, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	;

logical_and_expression
	: inclusive_or_expression
	| logical_and_expression AND_OP inclusive_or_expression										{
																									$$ = new SBaseASTNode(EN_LogicAnd, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
	}
	;

logical_or_expression
	: logical_and_expression
	| logical_or_expression OR_OP logical_and_expression										{
																									$$ = new SBaseASTNode(EN_LogicOr, "");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	;

conditional_expression
	: logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression							{
																									$$ = new SBaseASTNode(EN_SelectExpression, "");
																									SBaseASTNode *elseexpression=g_context.PopNode();
																									SBaseASTNode *ifexpression=g_context.PopNode();
																									SBaseASTNode *logicexpression=g_context.PopNode();
																									$$->PushSubNode(elseexpression);
																									$$->PushSubNode(ifexpression);
																									$$->PushSubNode(logicexpression);
																									g_context.PushNode($$);
																								}
	;

assignment_expression
	: conditional_expression
	| unary_expression '=' assignment_expression												{
																									SBaseASTNode *sourcenode=g_context.PopNode(); // identifier
																									SBaseASTNode *targetnode=g_context.PopNode(); // Either identifier or postfixarray
																									SSymbol sym;
																									bool found = false;
																									found = g_context.FindSymbol(targetnode->m_Value, sym);
																									$$ = new SBaseASTNode(EN_AssignmentExpression, "");
																									$$->PushSubNode(targetnode);
																									targetnode->m_Side = LEFT_HAND_SIDE; // Assinee moves to LHS
																									$$->PushSubNode(sourcenode); // source node is RHS
																									g_context.PushNode($$);
																								}
	;

expression
	: assignment_expression																		
	/*| expression ',' assignment_expression														{
																									SBaseASTNode *currentexpr = g_context.m_NodeStack.back();
																									g_context.m_NodeStack.pop();
																									SBaseASTNode *prevexpr = g_context.m_NodeStack.back();
																									prevexpr->PushSubNode(currentexpr);
																								}*/ // NOTE: This is causing much grief and I don't think I need it at this point
	;

expression_statement
	: expression ';'																			/*{
																									$$ = new SBaseASTNode(EN_Expression, "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}*/
	;

if_statement
	: IF '(' expression ')' code_block_start code_block_body code_block_end						{
																									$$ = new SBaseASTNode(EN_If, "");
																									SBaseASTNode *endnode=g_context.PopNode();
																									SBaseASTNode *codeblocknode=g_context.PopNode();
																									SBaseASTNode *startnode=g_context.PopNode();
																									SBaseASTNode *expression=g_context.PopNode();

																									std::string endlabel = PushLabel("endif");
																									$$->PushSubNode(new SBaseASTNode(EN_DummyString, ""));
																									$$->PushSubNode(expression);
																									$$->PushSubNode(new SBaseASTNode(EN_FlowNZ, endlabel));
																									$$->PushSubNode(startnode);
																									$$->PushSubNode(codeblocknode);
																									$$->PushSubNode(endnode);
																									$$->PushSubNode(new SBaseASTNode(EN_Label, endlabel));
																									g_context.PushNode($$);
																								}
	;

while_statement
	: WHILE '(' expression ')' code_block_start code_block_body code_block_end					{
																									$$ = new SBaseASTNode(EN_While, "");
																									SBaseASTNode *endnode=g_context.PopNode();
																									SBaseASTNode *codeblocknode=g_context.PopNode();
																									SBaseASTNode *startnode=g_context.PopNode();
																									SBaseASTNode *expression=g_context.PopNode();
																									std::string toplabel = PushLabel("while");
																									std::string endlabel = PushLabel("endwhile");
																									$$->PushSubNode(new SBaseASTNode(EN_Label, toplabel));
																									$$->PushSubNode(expression);
																									$$->PushSubNode(new SBaseASTNode(EN_FlowNZ, endlabel));
																									$$->PushSubNode(startnode);
																									$$->PushSubNode(codeblocknode);
																									$$->PushSubNode(endnode);
																									$$->PushSubNode(new SBaseASTNode(EN_Flow, toplabel));
																									$$->PushSubNode(new SBaseASTNode(EN_Label, endlabel));
																									g_context.PushNode($$);
																								}
	| WHILE '(' expression ')' function_statement												{
																									$$ = new SBaseASTNode(EN_While, "");
																									SBaseASTNode *funcstatement=g_context.PopNode();
																									SBaseASTNode *expression=g_context.PopNode();
																									std::string toplabel = PushLabel("while");
																									std::string endlabel = PushLabel("endwhile");
																									$$->PushSubNode(new SBaseASTNode(EN_Label, toplabel));
																									$$->PushSubNode(expression);
																									$$->PushSubNode(new SBaseASTNode(EN_FlowNZ, endlabel));
																									$$->PushSubNode(funcstatement);
																									$$->PushSubNode(new SBaseASTNode(EN_Flow, toplabel));
																									$$->PushSubNode(new SBaseASTNode(EN_Label, endlabel));
																									g_context.PushNode($$);
																								}
	| WHILE '(' expression ')' expression_statement												{
																									$$ = new SBaseASTNode(EN_While, "");
																									SBaseASTNode *funcstatement=g_context.PopNode();
																									SBaseASTNode *expression=g_context.PopNode();
																									std::string toplabel = PushLabel("while");
																									std::string endlabel = PushLabel("endwhile");
																									$$->PushSubNode(new SBaseASTNode(EN_Label, toplabel));
																									$$->PushSubNode(expression);
																									$$->PushSubNode(new SBaseASTNode(EN_FlowNZ, endlabel));
																									$$->PushSubNode(funcstatement);
																									$$->PushSubNode(new SBaseASTNode(EN_Flow, toplabel));
																									$$->PushSubNode(new SBaseASTNode(EN_Label, endlabel));
																									g_context.PushNode($$);
																								}
	| WHILE '(' expression ')' variable_declaration_statement									{
																									$$ = new SBaseASTNode(EN_While, "");
																									SBaseASTNode *funcstatement=g_context.PopNode();
																									SBaseASTNode *expression=g_context.PopNode();
																									std::string toplabel = PushLabel("while");
																									std::string endlabel = PushLabel("endwhile");
																									$$->PushSubNode(new SBaseASTNode(EN_Label, toplabel));
																									$$->PushSubNode(expression);
																									$$->PushSubNode(new SBaseASTNode(EN_FlowNZ, endlabel));
																									$$->PushSubNode(funcstatement);
																									$$->PushSubNode(new SBaseASTNode(EN_Flow, toplabel));
																									$$->PushSubNode(new SBaseASTNode(EN_Label, endlabel));
																									g_context.PushNode($$);
																								}
	;

variable_declaration_item
	: simple_identifier 																		{
																									SBaseASTNode *symbolnode=g_context.PopNode();

																									// Add this symbol to the list of known symbols
																									SSymbol &sym = g_context.DeclareSymbol(symbolnode->m_Value);

																									$$ = new SBaseASTNode(EN_Decl, "");

																									SBaseASTNode *initnode = new SBaseASTNode(EN_DeclInitJunction, "");
																									SBaseASTNode *datanode = new SBaseASTNode(EN_Constant, "0x00000000");
																									initnode->PushSubNode(symbolnode);
																									initnode->PushSubNode(datanode);

																									$$->PushSubNode(initnode);
																									g_context.PushNode($$);
																								}
	| simple_identifier '=' expression 															{
																									SBaseASTNode *expressionnode=g_context.PopNode();
																									SBaseASTNode *symbolnode=g_context.PopNode();

																									// Add this symbol to the list of known symbols
																									SSymbol &sym = g_context.DeclareSymbol(symbolnode->m_Value);

																									$$ = new SBaseASTNode(EN_Decl, "");

																									SBaseASTNode *initnode = new SBaseASTNode(EN_DeclInitJunction, "");
																									initnode->PushSubNode(symbolnode);
																									initnode->PushSubNode(expressionnode);

																									$$->PushSubNode(initnode);
																									g_context.PushNode($$);
																								}
	| simple_identifier '[' expression ']'														{
																									SBaseASTNode *expressionnode=g_context.PopNode();
																									SBaseASTNode *symbolnode=g_context.PopNode();

																									// Add this symbol to the list of known symbols
																									SSymbol &sym = g_context.DeclareSymbol(symbolnode->m_Value);

																									// Make a junction of variable name and expression node (array dimension)
																									SBaseASTNode *junc = new SBaseASTNode(EN_ArrayJunction, "");
																									junc->PushSubNode(symbolnode);
																									junc->PushSubNode(expressionnode);

																									$$ = new SBaseASTNode(EN_DeclArray, "");
																									$$->PushSubNode(junc);
																									g_context.PushNode($$);
																								}
	| simple_identifier '[' expression ']' '=' BEGINBLOCK expression_list ENDBLOCK				{
																									SBaseASTNode *datanode=g_context.PopNode();
																									SBaseASTNode *expressionnode=g_context.PopNode();
																									SBaseASTNode *symbolnode=g_context.PopNode();

																									// Add this symbol to the list of known symbols
																									SSymbol &sym = g_context.DeclareSymbol(symbolnode->m_Value);

																									// Make a junction of variable name and expression node (array dimension)
																									SBaseASTNode *junc = new SBaseASTNode(EN_ArrayWithDataJunction, "");
																									junc->PushSubNode(symbolnode);
																									junc->PushSubNode(expressionnode);
																									junc->PushSubNode(datanode);

																									$$ = new SBaseASTNode(EN_DeclArray, "");
																									$$->PushSubNode(junc);
																									g_context.PushNode($$);
																								}
	| simple_identifier '['  ']' '=' BEGINBLOCK expression_list ENDBLOCK						{
																									SBaseASTNode *datanode=g_context.PopNode();
																									SBaseASTNode *symbolnode=g_context.PopNode();

																									std::stringstream stream;
																									stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << datanode->m_SubNodes.size();
																									std::string result( stream.str() );
																									SBaseASTNode *expressionnode = new SBaseASTNode(EN_PrimaryExpression, "");
																									SBaseASTNode *constantnode = new SBaseASTNode(EN_Constant, result); // Auto-set array size
																									expressionnode->PushSubNode(constantnode);

																									// Add this symbol to the list of known symbols
																									SSymbol &sym = g_context.DeclareSymbol(symbolnode->m_Value);

																									// Make a junction of variable name and expression node (array dimension)
																									SBaseASTNode *junc = new SBaseASTNode(EN_ArrayWithDataJunction, "");
																									junc->PushSubNode(symbolnode);
																									junc->PushSubNode(expressionnode);
																									junc->PushSubNode(datanode);

																									$$ = new SBaseASTNode(EN_DeclArray, "");
																									$$->PushSubNode(junc);
																									g_context.PushNode($$);
																								}
	;

variable_declaration
	: VAR variable_declaration_item																{}
	| variable_declaration ',' variable_declaration_item										{}
	;

variable_declaration_statement
	: variable_declaration ';'																	/*{}*/
	;

expression_list
	: expression																				{
																									$$ = new SBaseASTNode(EN_ExpressionList, "");
																									SBaseASTNode *firstexpression=g_context.PopNode();
																									$$->PushSubNode(firstexpression);
																									g_context.PushNode($$);
																								}
	| expression_list ',' expression															{
																									// Append identifier to primary {identifier} node
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.back();
																									varnode->PushSubNode(n0);
																								}
	;

parameter_list
	: '(' ')'																					{
																									$$ = new SBaseASTNode(EN_CallParam, "");
																									g_context.PushNode($$);
																								}
	| '(' expression_list ')'																	{
																									$$ = new SBaseASTNode(EN_CallParam, "");
																									SBaseASTNode *expressionlist = g_context.PopNode();
																									// We should receive a expression list here. Just grab its subnodes in given (inverted) order
																									// so that when we push them they are popped in correct order
																									$$->CopySubNodes(expressionlist);
																									g_context.PushNode($$);
																								}
	;

function_statement
	: simple_identifier parameter_list ';'														{
																									// Grab the function parameter node
																									SBaseASTNode *functionparams=g_context.PopNode();
																									// Grab the function name
																									SBaseASTNode *functionname=g_context.PopNode();
																									functionname->m_Type = EN_FunctionName;

																									// Generate a CALL instruction with parameters as subnodes
																									$$ = new SBaseASTNode(EN_Call, functionname->m_Value);
																									$$->CopySubNodes(functionparams);

																									//$$->PushSubNode(functionname); // Drop name, it's part of instruction now
																									//$$->PushSubNode(functionparams); // Drop parameters, we've already pushed them on stack
																									g_context.PushNode($$);
																								}
	;

code_block_start
	: BEGINBLOCK																				{
																									$$ = new SBaseASTNode(EN_Prologue, "");
																									// This is a prologue section for a code block
																									g_context.PushNode($$);
																								}
	;

code_block_end
	: ENDBLOCK																					{
																									$$ = new SBaseASTNode(EN_Epilogue, "");
																									// This is an epilogue section for a code block
																									g_context.PushNode($$);
																								}
	;

return_statement
	: RETURN ';'																				{
																									$$ = new SBaseASTNode(EN_Return, "");
																									g_context.PushNode($$);
																								}
	;

any_statement
	: function_statement																		{
																									$$ = new SBaseASTNode(EN_Statement, "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	| expression_statement																		{
																									$$ = new SBaseASTNode(EN_Statement, "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	| if_statement																				{
																									$$ = new SBaseASTNode(EN_Statement, "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	| while_statement																			{
																									$$ = new SBaseASTNode(EN_Statement, "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	| variable_declaration_statement															{
																									$$ = new SBaseASTNode(EN_Statement, "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	| return_statement																			{
																									$$ = new SBaseASTNode(EN_Statement, "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	;

code_block_body
	: any_statement
	| code_block_body any_statement																{
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.back();
																									varnode->PushSubNode(n0);
																								}
	;

function_def
	: FUNCTION simple_identifier parameter_list code_block_start code_block_body code_block_end	{
																									$$ = new SBaseASTNode(EN_FuncDecl, "");
																									SBaseASTNode *blockend=g_context.PopNode();
																									SBaseASTNode *codeblock=g_context.PopNode();
																									SBaseASTNode *blockbegin=g_context.PopNode();
																									SBaseASTNode *paramlist=g_context.PopNode();
																									SBaseASTNode *funcnamenode=g_context.PopNode();

																									// Promote parameter list to input parameter
																									paramlist->m_Type = EN_InputParamList;
																									// Scan and promote all identifiers to inputparam
																									ConvertInputParams(paramlist);
																									// Promote function name identifier to functionname
																									funcnamenode->m_Type = EN_FunctionName;

																									// Add this symbol to the list of known symbols
																									SSymbol &sym = g_context.DeclareSymbol(funcnamenode->m_Value);

																									$$->PushSubNode(funcnamenode);
																									$$->PushSubNode(paramlist);
																									$$->PushSubNode(blockbegin);
																									$$->PushSubNode(codeblock);
																									$$->PushSubNode(blockend);
																									g_context.PushNode($$);
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
																									$$ = new SBaseASTNode(EN_EndOfProgram, "");
																									g_context.PushNode($$);
																								}
	;
%%

/*struct SExpressionResult
{
	std::string m_Value;
	std::string m_HasOffset;
	int m_IsRegister;
	int m_HasOffset;
};*/

std::string EvaluateExpression(CCompilerContext *cctx, SASTNode *node, int &isRegister, ENodeSide side=RIGHT_HAND_SIDE)
{
	std::string source;

	if (node->m_Type == EN_PostfixArrayExpression)
	{
		std::string offset = EvaluateExpression(cctx, node->m_ASTNodes[1], isRegister, side);
		std::string base = EvaluateExpression(cctx, node->m_ASTNodes[0], isRegister, side);
		source = base + "+" + offset;
		isRegister = 0; // Not a register anymore
		//printf("EN_PostfixArrayExpression -> %s\n", source.c_str());
	}
	else if (node->m_Type == EN_PrimaryExpression)
	{
		source = EvaluateExpression(cctx, node->m_ASTNodes[0], isRegister, side);
		//printf("EN_PrimaryExpression -> %s\n", source.c_str());
	}
	else if (node->m_Type == EN_Identifier)
	{
		source = node->m_Value;
		//printf("EN_Identifier -> %s\n", source.c_str());
	}
	else if (node->m_Type == EN_Constant)
	{
		source = node->m_Value;
		isRegister = 1; // Consider register, we can't take valueof (i.e.[])
		//printf("EN_Constant -> %s\n", source.c_str());
	}
	else if (node->m_Type == EN_String)
	{
		std::stringstream stream;
		stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << node->m_String->m_Address;
		std::string result( stream.str() );
		source = std::string("0x")+result;
		isRegister = 1; // Consider register, we can't take valueof (i.e.[])
		//printf("EN_String -> %s (%s)\n", source.c_str(), node->m_String->m_String.c_str());
	}
	else
	{
		source = PopRegister();
		isRegister = 1;
		//printf("other: %s -> %s\n", NodeTypes[node->m_Type], source.c_str());
	}

	return source;
}

void ConvertEntry(SBaseASTNode *node, SASTNode *astnode)
{
	size_t sz = node->m_SubNodes.size();
	for(size_t i=0;i<sz;++i)
	{
		SBaseASTNode *sub = node->m_SubNodes.back();

		// Push sub node
		SASTNode *newnode = new SASTNode();
		newnode->m_Type = sub->m_Type;
		newnode->m_Value = sub->m_Value;
		newnode->m_Side = sub->m_Side;
		newnode->m_String = sub->m_String ? sub->m_String : nullptr;
		astnode->m_ASTNodes.push_back(newnode);

		ConvertEntry(sub, newnode);
		node->m_SubNodes.pop_back();
	}
}

void ConvertNodes()
{
	//printf("Converting stack based nodes to vector based nodes\n");

	size_t sz = g_context.m_NodeStack.size();

	//Need to reverse the root stack first
	std::deque<SBaseASTNode*> reversestack;
	for(size_t i=0;i<sz;++i)
	{
		reversestack.push_back(g_context.m_NodeStack.back());
		g_context.m_NodeStack.pop_back();
	}

	// Begin conversion
	for(size_t i=0;i<sz;++i)
	{
		auto node = reversestack.back();

		// Push root node
		SASTNode *newnode = new SASTNode();
		newnode->m_Type = node->m_Type;
		newnode->m_Value = node->m_Value;
		newnode->m_Side = node->m_Side;
		newnode->m_String = node->m_String ? node->m_String : nullptr;
		g_context.m_ASTNodes.push_back(newnode);

		ConvertEntry(node, newnode);
		reversestack.pop_back();
	}
}

void AddSymbols(CCompilerContext *cctx, SASTNode *node)
{
	for (auto &subnode : node->m_ASTNodes)
		AddSymbols(cctx, subnode);

	if (node->m_Type == EN_DeclInitJunction)
	{
		//printf("Adding variable '%s:%s' @%d\n", cctx->m_CurrentFunctionName.c_str(), node->m_Value.c_str(), cctx->m_ScopeDepth);

		SVariable *newvariable = new SVariable();
		newvariable->m_Name = cctx->m_CurrentFunctionName + ":" + node->m_ASTNodes[0]->m_Value;
		newvariable->m_Hash = HashString(newvariable->m_Name.c_str());
		newvariable->m_ScopeDepth = cctx->m_ScopeDepth;
		newvariable->m_String = node->m_String ? node->m_String : nullptr;

		// Populate initializer array
		int isRegister = 0;
		std::string eval = EvaluateExpression(cctx, node->m_ASTNodes[1], isRegister);
		newvariable->m_InitializedValues.push_back(isRegister ? eval : std::string("[")+eval+std::string("]"));

		cctx->m_Variables.push_back(newvariable);
	}
}

void AddArraySymbols(CCompilerContext *cctx, SASTNode *node)
{
	for (auto &subnode : node->m_ASTNodes)
		AddArraySymbols(cctx, subnode);

	if (node->m_Type == EN_ArrayWithDataJunction)
	{
		// expression list: node->m_ASTNodes[2];

		int dim = std::stoi(node->m_ASTNodes[1]->m_ASTNodes[0]->m_Value, 0, 16);

		//printf("Adding array variable '%s:%s[%d]' @%d\n", cctx->m_CurrentFunctionName.c_str(), node->m_ASTNodes[0]->m_Value.c_str(), dim, cctx->m_ScopeDepth);

		SVariable *newvariable = new SVariable();
		newvariable->m_Name = cctx->m_CurrentFunctionName + ":" + node->m_ASTNodes[0]->m_Value;
		newvariable->m_Hash = HashString(newvariable->m_Name.c_str());
		newvariable->m_ScopeDepth = cctx->m_ScopeDepth;
		newvariable->m_Dimension = dim;

		// Populate initializer array
		for (auto &expressionItem : node->m_ASTNodes[2]->m_ASTNodes)
		{
			int isRegister = 0;
			std::string eval = EvaluateExpression(cctx, expressionItem, isRegister);
			newvariable->m_InitializedValues.push_back(isRegister ? eval : std::string("[")+eval+std::string("]"));
		}

		cctx->m_Variables.push_back(newvariable);
	}

	if (node->m_Type == EN_ArrayJunction)
	{
		int dim = std::stoi(node->m_ASTNodes[1]->m_ASTNodes[0]->m_Value, 0, 16);

		//printf("Adding array variable '%s:%s[%d]' @%d\n", cctx->m_CurrentFunctionName.c_str(), node->m_ASTNodes[0]->m_Value.c_str(), dim, cctx->m_ScopeDepth);

		SVariable *newvariable = new SVariable();
		newvariable->m_Name = cctx->m_CurrentFunctionName + ":" + node->m_ASTNodes[0]->m_Value;
		newvariable->m_Hash = HashString(newvariable->m_Name.c_str());
		newvariable->m_ScopeDepth = cctx->m_ScopeDepth;
		newvariable->m_Dimension = dim;
		//newvariable->m_InitializedValues = {}; Result of assingment declaration's expression node (RHS)

		cctx->m_Variables.push_back(newvariable);
	}
}

void AddInputParameters(CCompilerContext *cctx, SASTNode *node)
{
	for (auto &subnode : node->m_ASTNodes)
		AddInputParameters(cctx, subnode);

	if (node->m_Type == EN_InputParam)
	{
		//printf("Adding input parameter '%s:%s' @%d\n", cctx->m_CurrentFunctionName.c_str(), node->m_Value.c_str(), cctx->m_ScopeDepth);

		SVariable *newvariable = new SVariable();
		newvariable->m_Name = cctx->m_CurrentFunctionName + ":" + node->m_Value;
		newvariable->m_Hash = HashString(newvariable->m_Name.c_str());
		newvariable->m_ScopeDepth = cctx->m_ScopeDepth;
		//newvariable->m_InitializedValues = {}; Result of assingment declaration's expression node (RHS)

		cctx->m_Variables.push_back(newvariable);
	}
}

void GatherParamBlock(CCompilerContext *cctx, SFunction *function, SASTNode *codenode)
{
	function->m_CodeBlock.push_back(codenode);
}

void GatherCodeBlock(CCompilerContext *cctx, SFunction *function, SASTNode *codenode)
{
	function->m_CodeBlock.push_back(codenode);
}

void AddFunction(CCompilerContext *cctx, SASTNode *node)
{
	SASTNode *namenode = node->m_ASTNodes[0];
	SASTNode *paramsnode = node->m_ASTNodes[1];
	//SASTNode *prologuenode = node->m_ASTNodes[2];
	SASTNode *codenode = node->m_ASTNodes[3];
	//SASTNode *epiloguenode = node->m_ASTNodes[5];

	//printf("Adding function '%s'\n", namenode->m_Value.c_str());

	SFunction *newfunction = new SFunction();
	newfunction->m_Name = namenode->m_Value;
	newfunction->m_Hash = HashString(newfunction->m_Name.c_str());

	// 'main' function automatically gets a 1 refcount so that it can end up in the final compiled code
	static uint32_t main_hash = HashString("main");
	newfunction->m_RefCount = newfunction->m_Hash == main_hash ? 1 : 0;

	GatherParamBlock(cctx, newfunction, paramsnode);
	//GatherPrologue(cctx, newfunction, prologuenode);
	GatherCodeBlock(cctx, newfunction, codenode);
	//GatherEpilogue(cctx, newfunction, epiloguenode);

	cctx->m_Functions.push_back(newfunction);

	// Remove the epilogue
	node->m_ASTNodes.erase(node->m_ASTNodes.begin()+4);
	// Remove the code block
	node->m_ASTNodes.erase(node->m_ASTNodes.begin()+3);
	// Remove the prologue
	node->m_ASTNodes.erase(node->m_ASTNodes.begin()+2);
	// Remove the parameter block
	node->m_ASTNodes.erase(node->m_ASTNodes.begin()+1);
	// Remove the name block
	node->m_ASTNodes.erase(node->m_ASTNodes.begin());
}

void GatherEntry(CCompilerContext *cctx, SASTNode *node)
{
	node->m_ScopeDepth = cctx->m_ScopeDepth++;

	//printf("%s(%d) %s\n", NodeTypes[node->m_Type], node->m_ScopeDepth, node->m_Value.c_str());

	for (auto &subnode : node->m_ASTNodes)
		GatherEntry(cctx, subnode);
	
	--cctx->m_ScopeDepth;

	switch (node->m_Type)
	{
		/* case EN_Epilogue:
		{
			// Remove variables generated within this scopedepth
			auto beg = cctx->m_Variables.begin();
			while (beg != cctx->m_Variables.end())
			{
				SVariable *var = *beg;
				if (var->m_ScopeDepth == node->m_ScopeDepth+1)
				{
					printf("going out of scope: %s\n", var->m_Name.c_str());
					beg = cctx->m_Variables.erase(beg);
				}
				else
					++beg;
			}
		}
		break; */

		case EN_Call:
		{
			uint32_t nodehash = HashString(node->m_Value.c_str());
			SFunction *fun = cctx->FindFunctionInFunctionTable(nodehash);
			if (fun==nullptr)
				printf("line #%d column #%d : ERROR: Function '%s' called before its body appears in code\n", yylineno, column, node->m_Value.c_str());
			else
				fun->m_RefCount++;
		}
		break;

		case EN_FunctionName:
			cctx->m_CurrentFunctionName = node->m_Value;
		break;

		case EN_InputParamList:
			AddInputParameters(cctx, node);
		break;

		case EN_Decl:
			AddSymbols(cctx, node);
		break;

		case EN_DeclArray:
			AddArraySymbols(cctx, node);
		break;

		case EN_FuncDecl:
			AddFunction(cctx, node);
		break;

		default:
		break;
	}
}

void GatherSymbols()
{
	//printf("Build symbol tables : Gather globals, locals, and function inputs, generate scope depth\n");

	// Create global context
	// Compile function should:
	// -create and push a new compilercontext every time we hit a prologue
	// -pop compiler context stack and destroy the current compilercontext every time we hit an epilogue
	CCompilerContext* globalContext = new CCompilerContext();
	globalContext->m_CurrentFunctionName = "";
	globalContext->m_ScopeDepth = 0;
	g_context.m_CompilerContextList.push_back(globalContext);

	for (auto &node : g_context.m_ASTNodes)
		GatherEntry(globalContext, node);
}

bool ScanSymbolAccessEntry(CCompilerContext *cctx, SASTNode *node)
{
	if (node->m_Type == EN_Identifier)
	{
		bool found = false;
		std::string expandedVarName;

		// Scan function local scope first
		std::string localname = cctx->m_CurrentFunctionName + ":" + node->m_Value;
		expandedVarName = localname;
		uint32_t localhash = HashString(localname.c_str());
		SVariable *localvar = cctx->FindSymbolInSymbolTable(localhash);
		if (localvar==nullptr)
		{
			// Scan global scope next
			std::string globalname = ":" + node->m_Value;
			expandedVarName = globalname;
			uint32_t globalhash = HashString(globalname.c_str());
			SVariable *globalvar = cctx->FindSymbolInSymbolTable(globalhash);
			if (globalvar==nullptr)
			{
				// Scan scoped-names last
				for(auto &func : cctx->m_Functions)
				{
					std::string scopedname = node->m_Value;
					expandedVarName = scopedname;
					uint32_t scopedhash = HashString(scopedname.c_str());
					SVariable *scopedvar = cctx->FindSymbolInSymbolTable(scopedhash);
					if (scopedvar)
					{
						found = true;
						break;
					}
				}
			}
			else
				found = true;
		}
		else
			found = true;

		if (!found)
		{
			printf("line #%d column #%d : ERROR: Symbol '%s' not found\n", yylineno, column, expandedVarName.c_str());
			return false;
		}
	}

	for (auto &subnode : node->m_ASTNodes)
	{
		bool found = ScanSymbolAccessEntry(cctx, subnode);
		if (!found)
			return false;
	}

	switch (node->m_Type)
	{
		case EN_FunctionName:
			cctx->m_CurrentFunctionName = node->m_Value;
		break;
		default:
		break;
	}

	return true;
}

void ScanSymbolAccessErrors()
{
	//printf("Symbol access check : Find undefined symbols\n");

	CCompilerContext* globalContext = g_context.m_CompilerContextList[0];
	globalContext->m_CurrentFunctionName = "";

	// Scan global context
	for (auto &node : g_context.m_ASTNodes)
	{
		bool found = ScanSymbolAccessEntry(globalContext, node);
		if (!found)
			break;
	}

	// Scan function bodies
	for (auto &func : globalContext->m_Functions)
	{
		if (func->m_RefCount == 0)
			continue; // No need to scan unused function bodies
		for (auto &subnode : func->m_CodeBlock)
		{
			globalContext->m_CurrentFunctionName = func->m_Name;
			ScanSymbolAccessEntry(globalContext, subnode);
		}
	}
}

void CompileCodeBlock(CCompilerContext *cctx, SASTNode *node)
{
	// TODO: Code gen
	//printf("\t%s:%s\n", NodeTypes[node->m_Type], node->m_Value.c_str());

	for (auto &subnode : node->m_ASTNodes)
		CompileCodeBlock(cctx, subnode);

	// Do this after child node iteration to ensure deepest node gets pulled first

	switch (node->m_Type)
	{
		case EN_Mul:
		case EN_Div:
		case EN_Mod:
		case EN_Add:
		case EN_Sub:
		{
			int isRegister1 = 0, isRegister2 = 0;

			std::string src1 = EvaluateExpression(cctx, node->m_ASTNodes[0], isRegister1);
			if (isRegister1)
			{
				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = src1;
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}
			else
			{
				SCodeNode *leftoplea = new SCodeNode();
				leftoplea->m_Op = OP_LEA;
				leftoplea->m_ValueIn[0] = src1;
				leftoplea->m_ValueOut = PushRegister();
				leftoplea->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftoplea);

				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = std::string("[") + PopRegister() + std::string("]");
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}

			std::string src2 = EvaluateExpression(cctx, node->m_ASTNodes[1], isRegister2);
			if (isRegister2)
			{
				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = src2;
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}
			else
			{
				SCodeNode *leftoplea = new SCodeNode();
				leftoplea->m_Op = OP_LEA;
				leftoplea->m_ValueIn[0] = src2;
				leftoplea->m_ValueOut = PushRegister();
				leftoplea->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftoplea);

				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = std::string("[") + PopRegister() + std::string("]");
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}

			SCodeNode *newop = new SCodeNode();
			newop->m_Op = EOpcode(int(OP_MUL) + (node->m_Type-EN_Mul));
			newop->m_ValueIn[1] = PopRegister();
			newop->m_ValueIn[0] = PopRegister();
			newop->m_ValueOut = PushRegister();
			newop->m_InputCount = 2;
			g_context.m_CodeNodes.push_back(newop);
		}
		break;

		case EN_Label:
		{
			SCodeNode *newop = new SCodeNode();
			newop->m_Op = OP_LABEL;
			newop->m_ValueOut = node->m_Value;
			newop->m_InputCount = 0;
			g_context.m_CodeNodes.push_back(newop);

			SCodeNode *emptyop = new SCodeNode();
			emptyop->m_Op = OP_DUMMYSTRING;
			emptyop->m_InputCount = 0;
			emptyop->m_OutputCount = 0;
			g_context.m_CodeNodes.push_back(emptyop);
		}
		break;

		case EN_Flow:
		{
			SCodeNode *newop = new SCodeNode();
			newop->m_Op = OP_JUMP;
			newop->m_ValueOut = node->m_Value;
			newop->m_InputCount = 0;
			g_context.m_CodeNodes.push_back(newop);
		}
		break;

		case EN_FlowNZ:
		{
			SCodeNode *newop = new SCodeNode();
			newop->m_Op = OP_JUMPNZ;
			newop->m_ValueIn[0] = PopRegister();
			newop->m_ValueIn[1] = node->m_Value;
			newop->m_InputCount = 2;
			newop->m_OutputCount = 0;
			g_context.m_CodeNodes.push_back(newop);
		}
		break;

		case EN_LessThan:
		case EN_GreaterThan:
		case EN_LessEqual:
		case EN_GreaterEqual:
		case EN_Equal:
		case EN_NotEqual:
		{
			int isRegister1 = 0, isRegister2 = 0;

			std::string src1 = EvaluateExpression(cctx, node->m_ASTNodes[0], isRegister1);
			if (isRegister1)
			{
				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = src1;
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}
			else
			{
				SCodeNode *leftoplea = new SCodeNode();
				leftoplea->m_Op = OP_LEA;
				leftoplea->m_ValueIn[0] = src1;
				leftoplea->m_ValueOut = PushRegister();
				leftoplea->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftoplea);

				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = std::string("[") + PopRegister() + std::string("]");
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}

			std::string src2 = EvaluateExpression(cctx, node->m_ASTNodes[1], isRegister2);
			if (isRegister2)
			{
				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = src2;
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}
			else
			{
				SCodeNode *leftoplea = new SCodeNode();
				leftoplea->m_Op = OP_LEA;
				leftoplea->m_ValueIn[0] = src2;
				leftoplea->m_ValueOut = PushRegister();
				leftoplea->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftoplea);

				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = std::string("[") + PopRegister() + std::string("]");
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}

			SCodeNode *newop = new SCodeNode();
			newop->m_Op = EOpcode(int(OP_LESS) + (node->m_Type-EN_LessThan));
			newop->m_ValueIn[0] = PopRegister();
			newop->m_ValueIn[1] = PopRegister();
			newop->m_ValueOut = PushRegister();
			newop->m_OutputCount = 1;
			newop->m_InputCount = 2;
			g_context.m_CodeNodes.push_back(newop);
		}
		break;

		case EN_BitAnd:
		case EN_BitOr:
		case EN_BitXor:
		{
			int isRegister1 = 0, isRegister2 = 0;

			std::string src1 = EvaluateExpression(cctx, node->m_ASTNodes[0], isRegister1);
			if (isRegister1)
			{
				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = src1;
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}
			else
			{
				SCodeNode *leftoplea = new SCodeNode();
				leftoplea->m_Op = OP_LEA;
				leftoplea->m_ValueIn[0] = src1;
				leftoplea->m_ValueOut = PushRegister();
				leftoplea->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftoplea);

				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = std::string("[") + PopRegister() + std::string("]");
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}

			std::string src2 = EvaluateExpression(cctx, node->m_ASTNodes[1], isRegister2);
			if (isRegister2)
			{
				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = src2;
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}
			else
			{
				SCodeNode *leftoplea = new SCodeNode();
				leftoplea->m_Op = OP_LEA;
				leftoplea->m_ValueIn[0] = src2;
				leftoplea->m_ValueOut = PushRegister();
				leftoplea->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftoplea);

				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = std::string("[") + PopRegister() + std::string("]");
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}

			SCodeNode *newop = new SCodeNode();
			newop->m_Op = EOpcode(int(OP_BITAND) + (node->m_Type-EN_BitAnd));
			newop->m_ValueIn[1] = PopRegister();
			newop->m_ValueIn[0] = PopRegister();
			newop->m_ValueOut = PushRegister();
			newop->m_OutputCount = 1;
			newop->m_InputCount = 2;
			g_context.m_CodeNodes.push_back(newop);
		}
		break;

		case EN_AssignmentExpression:
		{
			// Load RHS into register
			int isRegister1 = 0, isRegister2 = 0;

			std::string srcval = EvaluateExpression(cctx, node->m_ASTNodes[1], isRegister1);
			SCodeNode *leftop;
			if (isRegister1)
			{
				leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = srcval;
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}
			else
			{
				SCodeNode *leftoplea = new SCodeNode();
				leftoplea->m_Op = OP_LEA;
				leftoplea->m_ValueIn[0] = srcval;
				leftoplea->m_ValueOut = PushRegister();
				leftoplea->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftoplea);

				leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = std::string("[") + PopRegister() + std::string("]");
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}

			// Assign to LHS
			SCodeNode *leftoplea = new SCodeNode();
			leftoplea->m_Op = OP_LEA;
			leftoplea->m_ValueOut = PushRegister();

			std::string trgval = EvaluateExpression(cctx, node->m_ASTNodes[0], isRegister2, LEFT_HAND_SIDE);
			if (isRegister2)
				printf("line #%d column #%d : ERROR: Cannot assign to left hand side: %s\n", yylineno, column, trgval.c_str());

			leftoplea->m_ValueIn[0] = trgval;
			leftoplea->m_InputCount = 1;
			g_context.m_CodeNodes.push_back(leftoplea);

			SCodeNode *storeop = new SCodeNode();
			storeop->m_Op = OP_STORE;
			storeop->m_ValueIn[0] = leftop->m_ValueOut;
			PopRegister();
			storeop->m_ValueOut = std::string("[") + PushRegister() + std::string("]");
			storeop->m_InputCount = 1;
			g_context.m_CodeNodes.push_back(storeop);
			PopRegister();
		}
		break;

		case EN_Return:
		{
			SCodeNode *retop = new SCodeNode();
			retop->m_Op = OP_RETURN;
			retop->m_OutputCount = 0;
			retop->m_InputCount = 0;
			g_context.m_CodeNodes.push_back(retop);
		}
		break;

		case EN_Call:
		{
			// TODO: push parameters into stack
			for (auto &param : node->m_ASTNodes)
			{
				//printf("paramnode: %s\n", NodeTypes[param->m_Type]);
				int isRegister = 0;
				std::string srcval = EvaluateExpression(cctx, param, isRegister);

				SCodeNode *loadop = new SCodeNode();

				if (isRegister)
				{
					SCodeNode *leftop = new SCodeNode();
					leftop->m_Op = OP_LOAD;
					leftop->m_ValueIn[0] = srcval;
					leftop->m_ValueOut = PushRegister();
					leftop->m_InputCount = 1;
					g_context.m_CodeNodes.push_back(leftop);
				}
				else
				{
					SCodeNode *leftoplea = new SCodeNode();
					leftoplea->m_Op = OP_LEA;
					leftoplea->m_ValueIn[0] = srcval;
					leftoplea->m_ValueOut = PushRegister();
					leftoplea->m_InputCount = 1;
					g_context.m_CodeNodes.push_back(leftoplea);

					SCodeNode *leftop = new SCodeNode();
					leftop->m_Op = OP_LOAD;
					leftop->m_ValueIn[0] = std::string("[") + PopRegister() + std::string("]");
					leftop->m_ValueOut = PushRegister();
					leftop->m_InputCount = 1;
					g_context.m_CodeNodes.push_back(leftop);
				}

				SCodeNode *callparamop = new SCodeNode();
				callparamop->m_Op = OP_PUSH;
				callparamop->m_ValueIn[0] = PopRegister();
				callparamop->m_OutputCount = 0;
				callparamop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(callparamop);
			}

			// Call the function
			SCodeNode *addrop = new SCodeNode();
			addrop->m_Op = OP_CALL;
			addrop->m_ValueIn[0] = node->m_Value;
			addrop->m_OutputCount = 0;
			addrop->m_InputCount = 1;
			g_context.m_CodeNodes.push_back(addrop);
		}
		break;

		case EN_InputParam:
		{
			// Input parameters will be taken from stack and written to corresponding local variables
			SCodeNode *paramop = new SCodeNode();
			paramop->m_Op = OP_POP;
			paramop->m_ValueIn[0] = node->m_Value;
			paramop->m_OutputCount = 0;
			paramop->m_InputCount = 1;
			g_context.m_CodeNodes.push_back(paramop);
		}
		break;

		case EN_SelectExpression:
		{
			int isRegister1 = 0, isRegister2 = 0, isRegister3 = 0;

			std::string srcval = EvaluateExpression(cctx, node->m_ASTNodes[0], isRegister1);

			if (isRegister1)
			{
				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = srcval;
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}
			else
			{
				SCodeNode *leftoplea = new SCodeNode();
				leftoplea->m_Op = OP_LEA;
				leftoplea->m_ValueIn[0] = srcval;
				leftoplea->m_ValueOut = PushRegister();
				leftoplea->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftoplea);

				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = std::string("[") + PopRegister() + std::string("]");
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}

			std::string srcval2 = EvaluateExpression(cctx, node->m_ASTNodes[1], isRegister2);

			if (isRegister2)
			{
				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = srcval2;
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}
			else
			{
				SCodeNode *leftoplea = new SCodeNode();
				leftoplea->m_Op = OP_LEA;
				leftoplea->m_ValueIn[0] = srcval2;
				leftoplea->m_ValueOut = PushRegister();
				leftoplea->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftoplea);

				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = std::string("[") + PopRegister() + std::string("]");
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}

			std::string srcval3 = EvaluateExpression(cctx, node->m_ASTNodes[2], isRegister3);

			if (isRegister3)
			{
				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = srcval3;
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}
			else
			{
				SCodeNode *leftoplea = new SCodeNode();
				leftoplea->m_Op = OP_LEA;
				leftoplea->m_ValueIn[0] = srcval3;
				leftoplea->m_ValueOut = PushRegister();
				leftoplea->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftoplea);

				SCodeNode *leftop = new SCodeNode();
				leftop->m_Op = OP_LOAD;
				leftop->m_ValueIn[0] = std::string("[") + PopRegister() + std::string("]");
				leftop->m_ValueOut = PushRegister();
				leftop->m_InputCount = 1;
				g_context.m_CodeNodes.push_back(leftop);
			}

			SCodeNode *selop = new SCodeNode();
			selop->m_Op = OP_SELECT;
			selop->m_ValueIn[1] = PopRegister();
			selop->m_ValueIn[2] = PopRegister();
			selop->m_ValueIn[0] = PopRegister();
			selop->m_ValueOut = PushRegister();
			selop->m_OutputCount = 1;
			selop->m_InputCount = 3;
			g_context.m_CodeNodes.push_back(selop);
		}
		break;

		case EN_UnaryAddressOf:
		{
			int isRegister=0;
			std::string srcval = EvaluateExpression(cctx, node->m_ASTNodes[0], isRegister);

			SCodeNode *addrop = new SCodeNode();
			addrop->m_Op = OP_LEA;
			addrop->m_ValueIn[0] = srcval;
			addrop->m_ValueOut = PushRegister();
			addrop->m_OutputCount = 1;
			addrop->m_InputCount = 1;
			g_context.m_CodeNodes.push_back(addrop);
		}
		break;

		case EN_DummyString:
		{
			int isRegister=0;
			SCodeNode *addrop = new SCodeNode();
			addrop->m_Op = OP_DUMMYSTRING;
			addrop->m_ValueIn[0] = node->m_Value;
			addrop->m_OutputCount = 0;
			addrop->m_InputCount = 1;
			g_context.m_CodeNodes.push_back(addrop);
		}
		break;

		/*case EN_UnaryValueOf:
		{
			int isRegister=0;
			std::string srcval = EvaluateExpression(cctx, node->m_ASTNodes[0], isRegister);

			SCodeNode *addrop = new SCodeNode();
			addrop->m_Op = OP_LOAD;
			addrop->m_ValueIn[0] = std::string("[") + srcval + std::string("]");
			addrop->m_ValueOut = PushRegister();
			addrop->m_OutputCount = 1;
			addrop->m_InputCount = 1;
			g_context.m_CodeNodes.push_back(addrop);
		}
		break;*/

		case EN_If:
		case EN_While:
		case EN_InputParamList:
		case EN_String:
		case EN_Constant:
		case EN_Identifier:
		case EN_PrimaryExpression:
		case EN_PostfixArrayExpression:
		case EN_ExpressionList:
		case EN_Decl:
		case EN_DeclArray:
		case EN_DeclInitJunction:
		case EN_ArrayJunction:
		case EN_ArrayWithDataJunction:
		case EN_Prologue:
		case EN_Epilogue:
		case EN_Statement:
			// Nothing to emit for these
		break;

		default:
			SCodeNode *newop = new SCodeNode();
			newop->m_Op = OP_NOOP;
			newop->m_ValueOut = std::string("// ") + NodeTypes[node->m_Type];
			newop->m_InputCount = 0;
			g_context.m_CodeNodes.push_back(newop);
		break;
	}
}

void CompilePassNode(CCompilerContext *cctx, SASTNode *node)
{
	if (node->m_Type == EN_FuncDecl)
	{
		SASTNode *funcname = node->m_ASTNodes[0];
		uint32_t funchash = HashString(funcname->m_Value.c_str());
		SFunction *func = cctx->FindFunctionInFunctionTable(funchash);
		if (func == nullptr)
			printf("line #%d column #%d : ERROR: Can not find function %s\n", yylineno, column, funcname->m_Value.c_str());
		else
		{
			// TODO: Code gen
			//printf("%s (ref==%d):\n", func->m_Name.c_str(), func->m_RefCount);

			// OPTIMIZATION: Only compile functions referred to
			if (func->m_RefCount != 0)
			{
				// Insert label for function
				SCodeNode *labelop = new SCodeNode();
				labelop->m_Op = OP_LABEL;
				labelop->m_ValueOut = funcname->m_Value;
				labelop->m_InputCount = 0;
				g_context.m_CodeNodes.push_back(labelop);

				ResetRegister();

				// Compile the code
				for (auto &subnode : func->m_InputParameters)
					CompileCodeBlock(cctx, subnode);
				for (auto &subnode : func->m_CodeBlock)
					CompileCodeBlock(cctx, subnode);
			}
		}
	}
	else	// Non-function blocks
	{
		// TODO: Code gen
		//printf("%s:%s\n", NodeTypes[node->m_Type], node->m_Value.c_str());

		for (auto &subnode : node->m_ASTNodes)
			CompileCodeBlock(cctx, subnode);
	}
}

void CompilePass()
{
	//printf("Compile pass: Code generation\n");

	/*printf("jmp globalinit\n");
	printf("jmp main\n");
	printf("halt\n");

	printf(":globalinit\n");
	printf("ret\n");*/

	CCompilerContext* globalContext = g_context.m_CompilerContextList[0];
	for (auto &node : g_context.m_ASTNodes)
		CompilePassNode(globalContext, node);
}

void DumpCodeNode(FILE *fp, CCompilerContext *cctx, SCodeNode *codenode)
{
	// Skip redundant ld ra,rb where a==b
	if (codenode->m_Op == OP_LOAD)
	{
		if (codenode->m_ValueIn[0] == codenode->m_ValueOut)
			return;
	}

	if (codenode->m_OutputCount)
		fprintf(fp, "%s %s", Opcodes[codenode->m_Op], codenode->m_ValueOut.c_str());
	else
		fprintf(fp, "%s ", Opcodes[codenode->m_Op]);
	for (int i=0;i<codenode->m_InputCount;++i)
	{
		if (codenode->m_OutputCount==0 && i==0)
			fprintf(fp, "%s", codenode->m_ValueIn[i].c_str());
		else
			fprintf(fp, ", %s", codenode->m_ValueIn[i].c_str());
	}
	fprintf(fp, "\n");

	if (codenode->m_Op == OP_RETURN)
		fprintf(fp, "\n");
}

void DumpSymbolTable(FILE *fp, CCompilerContext *cctx)
{
	fprintf(fp, "\n---------------------------\n");
	fprintf(fp, "        Symbols            \n");
	fprintf(fp, "---------------------------\n\n");

	for (auto &str : g_context.m_StringTable)
	{
		std::stringstream stream;
		stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << str.second->m_Hash;
		std::string result( stream.str() );
		fprintf(fp, "@label 0x%s\n", result.c_str());
		fprintf(fp, "@org %d\n", str.second->m_Address);
		fprintf(fp, "@string %s\n", str.second->m_String.c_str());
	}

	for (auto &var : cctx->m_Variables)
	{
		fprintf(fp, "@label %s\n", var->m_Name.c_str());
		if (var->m_InitializedValues.size())
		{
			if (var->m_Dimension<var->m_InitializedValues.size())
				printf("WARNING: Too many initializers for array '%s[%d]', found %d. Dropping excess entries\n",var->m_Name.c_str(), var->m_Dimension, uint32_t(var->m_InitializedValues.size()));
			int i=0;
			for (auto &initval : var->m_InitializedValues)
			{
				if (i>=var->m_Dimension)
					break;
				std::stringstream stream;
				stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << initval;
				std::string result( stream.str() );
				fprintf(fp, "\t@dword %s\n", result.c_str());
				++i;
			}
			// Pad missing values with zeroes
			for (;i<var->m_Dimension;++i)
				fprintf(fp, "\t@dword 0x00000000\n");
		}
		else
			for (int i=0;i<var->m_Dimension;++i)
				fprintf(fp, "\t@dword 0x00000000\n");
	}
}

void SaveAsm(const char *filename)
{
	//printf("Writing output file\n");

	FILE *fp = fopen(filename, "w");

	fprintf(fp, "\n---------------------------\n");
	fprintf(fp, "     Compiled by GrimR     \n");
	fprintf(fp, "GrimR (c)2020 Engin Cilasun\n");
	fprintf(fp, "---------------------------\n\n");

	CCompilerContext* globalContext = g_context.m_CompilerContextList[0];
	for (auto &codenode : g_context.m_CodeNodes)
		DumpCodeNode(fp, globalContext, codenode);
	
	DumpSymbolTable(fp, globalContext);
	
	fclose(fp);
}

void DebugDumpCodeBlock(CCompilerContext *cctx, SASTNode *node)
{
	printf("\t%s(%d) %s\n", NodeTypes[node->m_Type], node->m_ScopeDepth, node->m_Value.c_str());
	for (auto &subnode : node->m_ASTNodes)
		DebugDumpCodeBlock(cctx, subnode);
}

void DebugDumpNode(CCompilerContext *cctx, SASTNode *node)
{
	printf("%s(%d) %s\n", NodeTypes[node->m_Type], node->m_ScopeDepth, node->m_Value.c_str());

	if (node->m_Type == EN_FuncDecl)
	{
		SASTNode *funcname = node->m_ASTNodes[0];
		uint32_t funchash = HashString(funcname->m_Value.c_str());
		SFunction *func = cctx->FindFunctionInFunctionTable(funchash);
		if (func != nullptr)
		{
			//printf("%s:%s (deferred compile until first use)\n", NodeTypes[node->m_Type], funcname->m_Value.c_str());
			for (auto &subnode : func->m_CodeBlock)
				DebugDumpCodeBlock(cctx, subnode);
		}
	}
	else
	{
		for (auto &subnode : node->m_ASTNodes)
			DebugDumpNode(cctx, subnode);
	}
}

void DebugDump()
{
	//printf("Debug dump\n");

	CCompilerContext* globalContext = g_context.m_CompilerContextList[0];
	for (auto &node : g_context.m_ASTNodes)
		DebugDumpNode(globalContext, node);
}

void yyerror(const char *s) {
	printf("line #%d columnd #%d : %s %s\n", yylineno, column, s, yytext );
	err++;
}
