%{

#include <stdio.h>
#include <stdlib.h>
#include <stack>
#include <deque>
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

enum EASTNodeType
{
	EN_Default,
	EN_Symbol,
	EN_Identifier,
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
	EN_Label,
	EN_Flow,	 
	EN_Call,
	EN_StackOp,
	EN_Decl,
	EN_FuncDecl,
	EN_InputParam,
	EN_CallParam,
	EN_FunctionPrologue,
	EN_FunctionEpilogue,
	EN_Statement,
	EN_EndOfProgram,
};

const char* NodeTypes[]=
{
	"EN_Default                   ",
	"EN_Symbol                    ",
	"EN_Identifier                ",
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
	"EN_Label                     ",
	"EN_Flow                      ",
	"EN_Call                      ",
	"EN_StackOp                   ",
	"EN_Decl                      ",
	"EN_FuncDecl                  ",
	"EN_InputParam                ",
	"EN_CallParam                 ",
	"EN_FunctionPrologue          ",
	"EN_FunctionEpilogue          ",
	"EN_Statement                 ",
	"EN_EndOfProgram              ",
};

enum ENodeSide
{
	RIGHT_HAND_SIDE,
	LEFT_HAND_SIDE
};

class SBaseASTNode
{
public:
	SBaseASTNode() {m_Value = "{n/a}"; m_Comment = ""; }
	SBaseASTNode(EASTNodeType type, std::string val, std::string comment) { m_Type = type; m_Value = val; m_Comment = comment; }

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
	std::string m_Value;
	std::vector<SASTNode*> m_ASTNodes;
};

struct SCompilerContext
{
	int m_ScopeDepth{0};
};

struct SSymbol
{
	std::string m_Value;
	uint32_t m_Address{0};
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

%token LESS_OP GREATER_OP LESSEQUAL_OP GREATEREQUAL_OP EQUAL_OP NOTEQUAL_OP AND_OP OR_OP
%token VAR FUNCTION IF THEN ELSE WHILE BEGINBLOCK ENDBLOCK GOTO RETURN

%type <astnode> simple_identifier
%type <astnode> simple_constant
%type <astnode> simple_string

%type <astnode> function_statement
%type <astnode> expression_statement
%type <astnode> variable_declaration_statement
%type <astnode> while_statement

%type <astnode> code_block_start
%type <astnode> code_block_end
%type <astnode> code_block_body

%type <astnode> primary_expression
%type <astnode> unary_expression
%type <astnode> postfix_expression

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
																									$$ = new SBaseASTNode(EN_Identifier, $1, "");
																									g_context.PushNode($$);
																								}
	;

simple_constant
	: CONSTANT																					{
																									std::string tmp;
																									tmp = std::to_string($1);
																									$$ = new SBaseASTNode(EN_Constant, tmp, "");
																									g_context.PushNode($$);
																								}
	;

simple_string
	: STRING_LITERAL																			{
																									$$ = new SBaseASTNode(EN_String, $1, "");
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
																									$$ = new SBaseASTNode(EN_PrimaryExpression, "", "// primary expression");

																									$$->PushSubNode(exprnode);
																									g_context.PushNode($$);
																								}
	| postfix_expression '[' expression ']'														{
																									// Only pull the offset from the stack
																									SBaseASTNode *offsetnode=g_context.PopNode();
																									SBaseASTNode *exprnode=g_context.PopNode();

																									// This will be an addition operation to the previous address generated by the target node
																									$$ = new SBaseASTNode(EN_PostfixArrayExpression, "", "// indexed value read");
																									$$->PushSubNode(exprnode);
																									$$->PushSubNode(offsetnode);
																									g_context.PushNode($$);
																								}
	;

unary_expression
	: postfix_expression
	| '&' unary_expression																		{
																									SBaseASTNode *n0=g_context.PopNode();

																									$$ = new SBaseASTNode(EN_UnaryAddressOf, "", "// unary address of");
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	| '*' unary_expression																		{
																									SBaseASTNode *n0=g_context.PopNode();
																									$$ = new SBaseASTNode(EN_UnaryValueOf, "", "// unary value of");
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	;

multiplicative_expression
	: unary_expression
	| multiplicative_expression '*' unary_expression											{
																									$$ = new SBaseASTNode(EN_Mul, "", "MUL");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->PushSubNode(n0);
																									$$->PushSubNode(n1);
																									g_context.PushNode($$);
																								}
	| multiplicative_expression '/' unary_expression											{
																									$$ = new SBaseASTNode(EN_Div, "", "DIV");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->PushSubNode(n0);
																									$$->PushSubNode(n1);
																									g_context.PushNode($$);
																								}
	| multiplicative_expression '%' unary_expression											{
																									$$ = new SBaseASTNode(EN_Mod, "", "MOD");
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
																									$$ = new SBaseASTNode(EN_Add, "", "+");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	| additive_expression '-' multiplicative_expression											{
																									$$ = new SBaseASTNode(EN_Sub, "", "-");
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
																									$$ = new SBaseASTNode(EN_LessThan, "", "<");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	| relational_expression GREATER_OP additive_expression										{
																									$$ = new SBaseASTNode(EN_GreaterThan, "", ">");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	| relational_expression LESSEQUAL_OP additive_expression									{
																									$$ = new SBaseASTNode(EN_LessEqual, "", "<=");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	| relational_expression GREATEREQUAL_OP additive_expression									{
																									$$ = new SBaseASTNode(EN_GreaterEqual, "", ">=");
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
																									$$ = new SBaseASTNode(EN_Equal, "", "CMP.EQ Ra, Rb");
																									SBaseASTNode *rightnode=g_context.PopNode();
																									SBaseASTNode *leftnode=g_context.PopNode();
																									$$->PushSubNode(leftnode);
																									$$->PushSubNode(rightnode);
																									g_context.PushNode($$);
																								}
	| equality_expression NOTEQUAL_OP relational_expression										{
																									$$ = new SBaseASTNode(EN_NotEqual, "", "CMP.NE Ra, Rb");
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
																									$$ = new SBaseASTNode(EN_BitAnd, "", "AND Ra, Rb");
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
																									$$ = new SBaseASTNode(EN_BitXor, "", "XOR Ra, Rb");
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
																									$$ = new SBaseASTNode(EN_BitOr, "", "OR Ra, Rb");
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
																									$$ = new SBaseASTNode(EN_LogicAnd, "", "// &&");
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
																									$$ = new SBaseASTNode(EN_LogicOr, "", "// ||");
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
																									$$ = new SBaseASTNode(EN_SelectExpression, "", "// ? : ");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									SBaseASTNode *n2=g_context.PopNode();
																									$$->PushSubNode(n0);
																									$$->PushSubNode(n1);
																									$$->PushSubNode(n2);
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
																									$$ = new SBaseASTNode(EN_AssignmentExpression, "", "// assignment expression");
																									$$->PushSubNode(targetnode);
																									targetnode->m_Comment = "// assignment target";
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
																									$$ = new SBaseASTNode(EN_Expression, "", "// expression statement");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}*/
	;

while_statement
	: WHILE '(' expression ')' code_block_start code_block_body code_block_end					{
																									$$ = new SBaseASTNode(EN_While, "", "// while statement type0");
																									SBaseASTNode *endnode=g_context.PopNode();
																									SBaseASTNode *codeblocknode=g_context.PopNode();
																									SBaseASTNode *startnode=g_context.PopNode();
																									SBaseASTNode *expression=g_context.PopNode();
																									$$->PushSubNode(expression);
																									$$->PushSubNode(new SBaseASTNode(EN_Flow, "", "JNZ endofwhile?"));
																									$$->PushSubNode(startnode);
																									$$->PushSubNode(codeblocknode);
																									$$->PushSubNode(endnode);
																									$$->PushSubNode(new SBaseASTNode(EN_Label, "", "@LABEL: endofwhile?"));
																									g_context.PushNode($$);
																								}
	| WHILE '(' expression ')' function_statement												{
																									$$ = new SBaseASTNode(EN_While, "", "// while statement type1");
																									SBaseASTNode *funcstatement=g_context.PopNode();
																									SBaseASTNode *expression=g_context.PopNode();
																									$$->PushSubNode(expression);
																									$$->PushSubNode(new SBaseASTNode(EN_Flow, "", "JNZ endofwhile?"));
																									$$->PushSubNode(funcstatement);
																									$$->PushSubNode(new SBaseASTNode(EN_Label, "", "@LABEL: endofwhile?"));
																									g_context.PushNode($$);
																								}
	| WHILE '(' expression ')' expression_statement												{
																									$$ = new SBaseASTNode(EN_While, "", "// while statement type2");
																									SBaseASTNode *funcstatement=g_context.PopNode();
																									SBaseASTNode *expression=g_context.PopNode();
																									$$->PushSubNode(expression);
																									$$->PushSubNode(new SBaseASTNode(EN_Flow, "", "JNZ endofwhile?"));
																									$$->PushSubNode(funcstatement);
																									$$->PushSubNode(new SBaseASTNode(EN_Label, "", "@LABEL: endofwhile?"));
																									g_context.PushNode($$);
																								}
	| WHILE '(' expression ')' variable_declaration_statement									{
																									$$ = new SBaseASTNode(EN_While, "", "// while statement type3");
																									SBaseASTNode *funcstatement=g_context.PopNode();
																									SBaseASTNode *expression=g_context.PopNode();
																									$$->PushSubNode(expression);
																									$$->PushSubNode(new SBaseASTNode(EN_Flow, "", "JNZ endofwhile?"));
																									$$->PushSubNode(funcstatement);
																									$$->PushSubNode(new SBaseASTNode(EN_Label, "", "@LABEL: endofwhile?"));
																									g_context.PushNode($$);
																								}
	;

variable_declaration
	: VAR simple_identifier 																	{
																									SBaseASTNode *symbolnode=g_context.PopNode();

																									// Add this symbol to the list of known symbols
																									SSymbol &sym = g_context.DeclareSymbol(symbolnode->m_Value);

																									$$ = new SBaseASTNode(EN_Decl, "", "DEFVAR");
																									$$->PushSubNode(symbolnode);
																									g_context.PushNode($$);
																								}
	| variable_declaration ',' simple_identifier												{
																									// Append rest of the list items to primary {var} node
																									SBaseASTNode *symbolnode=g_context.PopNode();

																									// Add this symbol to the list of known symbols
																									SSymbol &sym = g_context.DeclareSymbol(symbolnode->m_Value);

																									SBaseASTNode *varnode = g_context.m_NodeStack.back();
																									varnode->PushSubNode(symbolnode);
																								}

variable_declaration_statement
	: variable_declaration ';'																	/*{
																									$$ = new SBaseASTNode(EN_Decl, "", "// variable declaration statement");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}*/

expression_list
	: expression																				{
																									$$ = new SBaseASTNode(EN_ExpressionList, "", "// expression list");
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
																									$$ = new SBaseASTNode(EN_CallParam, "", "// () empty parameter list");
																									g_context.PushNode($$);
																								}
	| '(' expression_list ')'																	{
																									$$ = new SBaseASTNode(EN_CallParam, "", "// (...) parameter list");
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

																									// Generate a CALL instruction with parameters as subnodes
																									$$ = new SBaseASTNode(EN_Call, functionname->m_Value, "");
																									$$->CopySubNodes(functionparams);

																									//$$->PushSubNode(functionname); // Drop name, it's part of instruction now
																									//$$->PushSubNode(functionparams); // Drop parameters, we've already pushed them on stack
																									g_context.PushNode($$);
																								}
	;

code_block_start
	: BEGINBLOCK																				{
																									$$ = new SBaseASTNode(EN_FunctionPrologue, "", " // code block prologue");
																									// This is a prologue section for a code block
																									g_context.PushNode($$);
																								}
	;

code_block_end
	: ENDBLOCK																					{
																									$$ = new SBaseASTNode(EN_FunctionEpilogue, "", "// code block epilogue");
																									// This is an epilogue section for a code block
																									g_context.PushNode($$);
																								}
	;

code_block_body
	:																							{
																									$$ = new SBaseASTNode(EN_Statement, "", "// Empty code block");
																									g_context.PushNode($$);
																								}
	| function_statement																		{
																									$$ = new SBaseASTNode(EN_Statement, "", "// function statement");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	| code_block_body function_statement														{
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.back();
																									varnode->PushSubNode(n0);
																								}
	| expression_statement																		{
																									$$ = new SBaseASTNode(EN_Statement, "", "// expression statement");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	| code_block_body expression_statement														{
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.back();
																									varnode->PushSubNode(n0);
																								}
	| while_statement																			{
																									$$ = new SBaseASTNode(EN_Statement, "", "// while statement");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	| code_block_body while_statement															{
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.back();
																									varnode->PushSubNode(n0);
																								}
	| variable_declaration_statement															{
																									$$ = new SBaseASTNode(EN_Statement, "", "// variable declaration statement");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->PushSubNode(n0);
																									g_context.PushNode($$);
																								}
	| code_block_body variable_declaration_statement											{
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.back();
																									varnode->PushSubNode(n0);
																								}
	;

function_def
	: FUNCTION simple_identifier parameter_list code_block_start code_block_body code_block_end	{
																									$$ = new SBaseASTNode(EN_FuncDecl, "", "DEFUNC");
																									SBaseASTNode *blockend=g_context.PopNode();
																									SBaseASTNode *codeblock=g_context.PopNode();
																									SBaseASTNode *blockbegin=g_context.PopNode();
																									SBaseASTNode *paramlist=g_context.PopNode();
																									SBaseASTNode *funcnamenode=g_context.PopNode();

																									// Promote parameter list to input parameter
																									paramlist->m_Type = EN_InputParam;

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
	: variable_declaration_statement
	| function_statement
	| translation_unit function_statement
	| function_def
	| translation_unit function_def
	| translation_unit variable_declaration_statement
	;

program
	: translation_unit																			{
																									$$ = new SBaseASTNode(EN_EndOfProgram, "", "");
																									g_context.PushNode($$);
																								}
	;
%%

void ConvertEntry(int nodelevel, SBaseASTNode *node, SASTNode *astnode)
{
	static const std::string nodespaces="_______________________________________________________________________________________________________";
	size_t sz = node->m_SubNodes.size();

	//printf("%s|%s%s %s\n", NodeTypes[node->m_Type], nodespaces.substr(0,nodelevel).c_str(), node->m_Comment.c_str(), node->m_Value.c_str());

	for(size_t i=0;i<sz;++i)
	{
		SBaseASTNode *sub = node->m_SubNodes.back();

		// Push sub node
		SASTNode *newnode = new SASTNode();
		newnode->m_Type = sub->m_Type;
		newnode->m_Value = sub->m_Value;
		newnode->m_Side = sub->m_Side;
		astnode->m_ASTNodes.push_back(newnode);

		ConvertEntry(nodelevel+1, sub, newnode);
		node->m_SubNodes.pop_back();
	}
}

void ConvertNodes()
{
	printf("Converting stack based nodes to vector based nodes\n");

	int nodelevel = 0;
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
		g_context.m_ASTNodes.push_back(newnode);

		ConvertEntry(nodelevel, node, newnode);
		reversestack.pop_back();
	}
}

void CompileEntry(SCompilerContext &cctx, SASTNode *node)
{
	node->m_ScopeDepth = cctx.m_ScopeDepth++;

	printf("%s(%d):%s\n", NodeTypes[node->m_Type], node->m_ScopeDepth, node->m_Value.c_str());

	for (auto &subnode : node->m_ASTNodes)
		CompileEntry(cctx, subnode);
	
	--cctx.m_ScopeDepth;

	// Code gen
	switch (node->m_Type)
	{
		case EN_Decl:
			printf("// process variable declaration at scope depth %d (%s)\n", node->m_ScopeDepth, node->m_ScopeDepth==0?"global":"local");
		break;

		case EN_FuncDecl:
			printf("// process function declaration at scope depth %d\n", node->m_ScopeDepth);
		break;

		case EN_InputParam:
			printf("// pop function parameters at scope depth %d\n", node->m_ScopeDepth);
		break;

		default:
		break;
	}
}

void CompileNodes()
{
	printf("Compiling vector based nodes\n");

	SCompilerContext cctx;

	cctx.m_ScopeDepth = 0;
	for (auto &node : g_context.m_ASTNodes)
		CompileEntry(cctx, node);
}

extern int yylineno;
void yyerror(const char *s) {
	printf("%d : %s %s\n", yylineno, s, yytext );
	err++;
}
