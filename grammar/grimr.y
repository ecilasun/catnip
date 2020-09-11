%{

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
	SBaseASTNode() { m_Value = "{n/a}"; }
	SBaseASTNode(std::string str) { m_Value = str; }

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

%token LESS_OP GREATER_OP LESSEQUAL_OP GREATEREQUAL_OP EQUAL_OP NOTEQUAL_OP
%token VAR FUNCTION PARAM IF THEN ELSE FOR BEGINBLOCK ENDBLOCK GOTO RETURN

%type <astnode> simple_identifier
%type <astnode> simple_constant
%type <astnode> simple_string

%type <astnode> function_statement
%type <astnode> param_statement

%type <astnode> code_block_start
%type <astnode> code_block_end
%type <astnode> code_block_body

%type <astnode> expression_atom

%type <astnode> variable_declaration
%type <astnode> function_def

%type <astnode> parameter_list
%type <astnode> simple_identifier_list

%start translation_unit
%%

simple_identifier
	: IDENTIFIER																				{
																									$$ = new SBaseASTNode($1);
																									g_context.m_NodeStack.push($$);
																								}
	;

simple_constant
	: CONSTANT																					{
																									std::string tmp;
																									tmp = std::to_string($1);
																									$$ = new SBaseASTNode(tmp);
																									g_context.m_NodeStack.push($$);
																								}
	;

simple_string
	: STRING_LITERAL																			{
																									$$ = new SBaseASTNode($1);
																									g_context.m_NodeStack.push($$);
																								}
	;

expression_atom
	: simple_identifier
	| simple_constant
	| simple_string
	;

variable_declaration
	: VAR simple_identifier																		{
																									$$ = new SBaseASTNode("{var}");
																									// Variable name precedes, pop from stack
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| variable_declaration ',' simple_identifier												{
																									// Append rest of the list items to primary {var} node
																									SBaseASTNode *sinode = g_context.m_NodeStack.top();
																									g_context.m_NodeStack.pop();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(sinode);
																								}

param_statement
	: PARAM simple_identifier																	{
																									$$ = new SBaseASTNode("{param}");
																									// parameter name
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| param_statement ',' simple_identifier														{
																									// Append rest of the list items to primary {param} node
																									SBaseASTNode *sinode = g_context.m_NodeStack.top();
																									g_context.m_NodeStack.pop();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(sinode);
																								}
	;

simple_identifier_list
	: simple_identifier																			{
																									$$ = new SBaseASTNode("{identifier}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| simple_identifier_list ',' simple_identifier												{
																									// Append identifier to primary {identifier} node
																									SBaseASTNode *sinode = g_context.m_NodeStack.top();
																									g_context.m_NodeStack.pop();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(sinode);
																								}
	;

parameter_list
	: '(' ')'																					{
																									$$ = new SBaseASTNode("{()}");
																									g_context.m_NodeStack.push($$);
																								}
	| '(' simple_identifier_list ')'															{
																									$$ = new SBaseASTNode("{(...)}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

function_statement
	: simple_identifier parameter_list															{
																									$$ = new SBaseASTNode("{call}");
																									// Parameter list
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// Function name
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

code_block_start
	: BEGINBLOCK																				{
																									$$ = new SBaseASTNode("{beginblock}");
																									// This is a prologue section for a code block
																									g_context.m_NodeStack.push($$);
																								}
	;

code_block_end
	: ENDBLOCK																					{
																									$$ = new SBaseASTNode("{endblock}");
																									// This is an epilogue section for a code block
																									g_context.m_NodeStack.push($$);
																								}
	;

code_block_body
	:																							{
																									$$ = new SBaseASTNode("{statement:null}");
																									g_context.m_NodeStack.push($$);
																								}
	| function_statement																		{
																									$$ = new SBaseASTNode("{statement}");
																									// Pull the statement as subnode
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| code_block_body function_statement														{
																									// Append statement to primary {statement} node
																									SBaseASTNode *sinode = g_context.m_NodeStack.top();
																									g_context.m_NodeStack.pop();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(sinode);
																								}
	| param_statement																			{
																									$$ = new SBaseASTNode("{statement:P}");
																									// Pull the statement as subnode
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| code_block_body param_statement															{
																									// Append param statement to primary {statement} node
																									SBaseASTNode *sinode = g_context.m_NodeStack.top();
																									g_context.m_NodeStack.pop();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(sinode);
																								}
	;

function_def
	: FUNCTION simple_identifier code_block_start code_block_body code_block_end				{
																									$$ = new SBaseASTNode("{func}");
																									// endblock
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// body
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// beginblock
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									/*$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();*/
																									g_context.m_NodeStack.push($$);
																								}
	;

translation_unit
	: variable_declaration
	| function_statement
	| translation_unit function_statement
	| function_def
	| translation_unit function_def
	| translation_unit variable_declaration
	;
%%

void DumpEntry(int nodelevel, SBaseASTNode *node)
{
	static const std::string nodespaces="..........................................................................";

	// TODO: This is where we can somewhat start adding prologues / epilogues / labels and generate some code
	printf("%s%s\n", nodespaces.substr(0,nodelevel).c_str(), node->m_Value.c_str());

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
