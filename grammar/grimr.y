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

%token LESS_OP GREATER_OP LESSEQUAL_OP GREATEREQUAL_OP EQUAL_OP NOTEQUAL_OP AND_OP OR_OP
%token VAR FUNCTION USING IF THEN ELSE WHILE BEGINBLOCK ENDBLOCK GOTO RETURN

%type <astnode> simple_identifier
%type <astnode> simple_constant
%type <astnode> simple_string

%type <astnode> function_statement
%type <astnode> using_statement
%type <astnode> expression_statement
%type <astnode> variable_declaration_statement
%type <astnode> while_statement

%type <astnode> code_block_start
%type <astnode> code_block_end
%type <astnode> code_block_body

%type <astnode> primary_expression

%type <astnode> variable_declaration
%type <astnode> function_def

%type <astnode> parameter_list
%type <astnode> expression_list
%type <astnode> using_list

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

primary_expression
	: simple_identifier
	| simple_constant
	| simple_string
	;

multiplicative_expression
	: primary_expression
	| multiplicative_expression '*' primary_expression											{
																									$$ = new SBaseASTNode("{MUL}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| multiplicative_expression '/' primary_expression											{
																									$$ = new SBaseASTNode("{DIV}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| multiplicative_expression '%' primary_expression											{
																									$$ = new SBaseASTNode("{MOD}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression											{
																									$$ = new SBaseASTNode("{ADD}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| additive_expression '-' multiplicative_expression											{
																									$$ = new SBaseASTNode("{SUB}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

relational_expression
	: additive_expression
	| relational_expression LESS_OP additive_expression											{
																									$$ = new SBaseASTNode("{<}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| relational_expression GREATER_OP additive_expression										{
																									$$ = new SBaseASTNode("{>}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| relational_expression LESSEQUAL_OP additive_expression									{
																									$$ = new SBaseASTNode("{<=}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| relational_expression GREATEREQUAL_OP additive_expression									{
																									$$ = new SBaseASTNode("{>=}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;
    
equality_expression
	: relational_expression
	| equality_expression EQUAL_OP relational_expression										{
																									$$ = new SBaseASTNode("{==}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| equality_expression NOTEQUAL_OP relational_expression										{
																									$$ = new SBaseASTNode("{!=}");
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
																									$$ = new SBaseASTNode("{AND}");
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
																									$$ = new SBaseASTNode("{XOR}");
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
																									$$ = new SBaseASTNode("{OR}");
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
																									$$ = new SBaseASTNode("{&&}");
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
																									$$ = new SBaseASTNode("{||}");
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
																									$$ = new SBaseASTNode("{?:}");
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
	| primary_expression '=' assignment_expression												{
																									$$ = new SBaseASTNode("{=}");
																									// assignment expression
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									// primary expression
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

expression
	: assignment_expression																		
	/*| expression ',' assignment_expression														{
																									SBaseASTNode *currentexpr = g_context.m_NodeStack.top();
																									g_context.m_NodeStack.pop();
																									SBaseASTNode *prevexpr = g_context.m_NodeStack.top();
																									prevexpr->m_SubNodes.push(currentexpr);
																								}*/ // NOTE: This is causing much grief and I don't think I need it at this point
	;

expression_statement
	: expression ';'																			{
																									$$ = new SBaseASTNode("{expression}");
																									// Expression precedes, pop from stack
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

while_statement
	: WHILE '(' expression ')' code_block_start code_block_body code_block_end					{
																									$$ = new SBaseASTNode("{whilestatement}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| WHILE '(' expression ')' function_statement												{
																									$$ = new SBaseASTNode("{whilestatement}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| WHILE '(' expression ')' expression_statement												{
																									$$ = new SBaseASTNode("{whilestatement}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| WHILE '(' expression ')' variable_declaration_statement									{
																									$$ = new SBaseASTNode("{whilestatement}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| WHILE '(' expression ')' using_statement													{
																									$$ = new SBaseASTNode("{whilestatement}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

variable_declaration
	: VAR simple_identifier 																	{
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

variable_declaration_statement
	: variable_declaration ';'																	{
																									$$ = new SBaseASTNode("{vardeclstatement}");
																									// Variable name precedes, pop from stack
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}

using_list
	: USING simple_identifier 																	{
																									$$ = new SBaseASTNode("{using}");
																									// parameter name
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| using_list ',' simple_identifier															{
																									// Append rest of the list items to primary {using} node
																									SBaseASTNode *sinode = g_context.m_NodeStack.top();
																									g_context.m_NodeStack.pop();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(sinode);
																								}
	;

using_statement
	: using_list ';'																			{
																									$$ = new SBaseASTNode("{usingstatement}");
																									// Variable name precedes, pop from stack
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

expression_list
	: expression																				{
																									$$ = new SBaseASTNode("{identifier}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| expression_list ',' expression															{
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
	| '(' expression_list ')'																	{
																									$$ = new SBaseASTNode("{(...)}");
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	;

function_statement
	: simple_identifier parameter_list ';'														{
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
																									$$ = new SBaseASTNode("{statement:F}");
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
	| expression_statement																		{
																									$$ = new SBaseASTNode("{expressionstatement}");
																									// Pull the statement as subnode
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| code_block_body expression_statement														{
																									// Append param statement to primary {statement} node
																									SBaseASTNode *sinode = g_context.m_NodeStack.top();
																									g_context.m_NodeStack.pop();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(sinode);
																								}
	| while_statement																			{
																									$$ = new SBaseASTNode("{while}");
																									// Pull the statement as subnode
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| code_block_body while_statement															{
																									// Append while statement to primary {while} node
																									SBaseASTNode *sinode = g_context.m_NodeStack.top();
																									g_context.m_NodeStack.pop();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(sinode);
																								}
	| variable_declaration_statement															{
																									$$ = new SBaseASTNode("{statement:V}");
																									// Pull the statement as subnode
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| code_block_body variable_declaration_statement											{
																									// Append param statement to primary {statement} node
																									SBaseASTNode *sinode = g_context.m_NodeStack.top();
																									g_context.m_NodeStack.pop();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(sinode);
																								}
	| using_statement																			{
																									$$ = new SBaseASTNode("{statement:P}");
																									// Pull the statement as subnode
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
																								}
	| code_block_body using_statement															{
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
																									// function name
																									$$->m_SubNodes.push(g_context.m_NodeStack.top());
																									g_context.m_NodeStack.pop();
																									g_context.m_NodeStack.push($$);
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
