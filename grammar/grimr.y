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
	SBaseASTNode() { m_Value = "{n/a}"; m_Code = ""; }
	SBaseASTNode(std::string val, std::string code) { m_Value = val; m_Code = code; }

	std::string m_Value;
	std::string m_Code;
	std::stack<SBaseASTNode*> m_SubNodes;
};

struct SParserContext
{
	SParserContext()
	{
	}

	void PushNode(SBaseASTNode *node) { m_NodeStack.push(node); }
	SBaseASTNode *TopNode() { return m_NodeStack.top(); }
	SBaseASTNode *PopNode() { SBaseASTNode *node = m_NodeStack.top(); m_NodeStack.pop(); return node; }

	std::stack<SBaseASTNode*> m_NodeStack;
	//std::stack<uint32_t> m_RegisterStack;
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
%type <astnode> unary_expression
%type <astnode> postfix_expression

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
																									$$ = new SBaseASTNode($1, " // LEA Ra, identifier");
																									g_context.PushNode($$);
																								}
	;

simple_constant
	: CONSTANT																					{
																									std::string tmp;
																									tmp = std::to_string($1);
																									$$ = new SBaseASTNode(tmp, " // LD R?, constant");
																									g_context.PushNode($$);
																								}
	;

simple_string
	: STRING_LITERAL																			{
																									$$ = new SBaseASTNode($1, " // push string to conststring pool, R?=address");
																									// TODO: Allocate string constant in string heap and convert this literal to its address
																									g_context.PushNode($$);
																								}
	;

primary_expression
	: simple_identifier
	| simple_constant
	| simple_string
	;

postfix_expression
	: primary_expression
	| postfix_expression '[' expression ']'														{
																									$$ = new SBaseASTNode("{[]}", " // Offset current variable by expression's result");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	;

unary_expression
	: postfix_expression
	| '&' unary_expression																		{
																									$$ = new SBaseASTNode("{&}", "LD R?, variableaddress");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	| '*' unary_expression																		{
																									$$ = new SBaseASTNode("{*}", "LD Rn, [Rn]");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	;

multiplicative_expression
	: unary_expression
	| multiplicative_expression '*' unary_expression											{
																									$$ = new SBaseASTNode("MUL Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	| multiplicative_expression '/' unary_expression											{
																									$$ = new SBaseASTNode("DIV Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	| multiplicative_expression '%' unary_expression											{
																									$$ = new SBaseASTNode("MOD Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression											{
																									$$ = new SBaseASTNode("ADD Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	| additive_expression '-' multiplicative_expression											{
																									$$ = new SBaseASTNode("SUB Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	;

relational_expression
	: additive_expression
	| relational_expression LESS_OP additive_expression											{
																									$$ = new SBaseASTNode("CMP.L Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	| relational_expression GREATER_OP additive_expression										{
																									$$ = new SBaseASTNode("CMP.G Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	| relational_expression LESSEQUAL_OP additive_expression									{
																									$$ = new SBaseASTNode("CMP.LE Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	| relational_expression GREATEREQUAL_OP additive_expression									{
																									$$ = new SBaseASTNode("CMP.GE Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	;
    
equality_expression
	: relational_expression
	| equality_expression EQUAL_OP relational_expression										{
																									$$ = new SBaseASTNode("CMP.EQ Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	| equality_expression NOTEQUAL_OP relational_expression										{
																									$$ = new SBaseASTNode("CMP.NE Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	;

and_expression
	: equality_expression
	| and_expression '&' equality_expression													{
																									$$ = new SBaseASTNode("AND Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression												{
																									$$ = new SBaseASTNode("XOR Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	;

inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression										{
																									$$ = new SBaseASTNode("OR Ra, Rb", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	;

logical_and_expression
	: inclusive_or_expression
	| logical_and_expression AND_OP inclusive_or_expression										{
																									$$ = new SBaseASTNode("{&&}", "// ???");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
	}
	;

logical_or_expression
	: logical_and_expression
	| logical_or_expression OR_OP logical_and_expression										{
																									$$ = new SBaseASTNode("{||}", "// ???");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	;

conditional_expression
	: logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression							{
																									$$ = new SBaseASTNode("{?:}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									SBaseASTNode *n2=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									$$->m_SubNodes.push(n2);
																									g_context.PushNode($$);
																								}
	;

assignment_expression
	: conditional_expression
	| unary_expression '=' assignment_expression												{
																									$$ = new SBaseASTNode("LEA Ra, target / LEA Rb, source / LD Rb, [Rb] / ST [Ra], Rb", " // assignment");
																									SBaseASTNode *sourcenode=g_context.PopNode();
																									SBaseASTNode *targetnode=g_context.PopNode();
																									$$->m_SubNodes.push(sourcenode);
																									$$->m_SubNodes.push(targetnode);
																									g_context.PushNode($$);
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
																									$$ = new SBaseASTNode("{expression}", " // Result in register");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	;

while_statement
	: WHILE '(' expression ')' code_block_start code_block_body code_block_end					{
																									$$ = new SBaseASTNode("{whilestatement}", "");
																									SBaseASTNode *endnode=g_context.PopNode();
																									SBaseASTNode *codeblocknode=g_context.PopNode();
																									SBaseASTNode *startnode=g_context.PopNode();
																									SBaseASTNode *conditionnode=g_context.PopNode();
																									$$->m_SubNodes.push(new SBaseASTNode("@LABEL: endofwhile?", ""));
																									$$->m_SubNodes.push(endnode);
																									$$->m_SubNodes.push(codeblocknode);
																									$$->m_SubNodes.push(startnode);
																									$$->m_SubNodes.push(new SBaseASTNode("JNZ endofwhile?", ""));
																									$$->m_SubNodes.push(conditionnode);
																									g_context.PushNode($$);
																								}
	| WHILE '(' expression ')' function_statement												{
																									$$ = new SBaseASTNode("{whilestatement}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(new SBaseASTNode("@LABEL: endofwhile?", ""));
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(new SBaseASTNode("JNZ endofwhile?", ""));
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	| WHILE '(' expression ')' expression_statement												{
																									$$ = new SBaseASTNode("{whilestatement}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(new SBaseASTNode("@LABEL: endofwhile?", ""));
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(new SBaseASTNode("JNZ endofwhile?", ""));
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	| WHILE '(' expression ')' variable_declaration_statement									{
																									$$ = new SBaseASTNode("{whilestatement}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(new SBaseASTNode("@LABEL: endofwhile?", ""));
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(new SBaseASTNode("JNZ endofwhile?", ""));
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	| WHILE '(' expression ')' using_statement													{
																									$$ = new SBaseASTNode("{whilestatement}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(new SBaseASTNode("@LABEL: endofwhile?", ""));
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(new SBaseASTNode("{whileprologue}", "JNZ endofwhile?"));
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	;

variable_declaration
	: VAR simple_identifier 																	{
																									$$ = new SBaseASTNode("{var}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	| variable_declaration ',' simple_identifier												{
																									// Append rest of the list items to primary {var} node
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(n0);
																								}

variable_declaration_statement
	: variable_declaration ';'																	{
																									$$ = new SBaseASTNode("{vardeclstatement}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}

using_list
	: USING simple_identifier 																	{
																									$$ = new SBaseASTNode("{param}", "POP R?");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	| using_list ',' simple_identifier															{
																									// Append rest of the list items to primary {param} node
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(n0);
																								}
	;

using_statement
	: using_list ';'																			{
																									$$ = new SBaseASTNode("{usingstatement}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	;

expression_list
	: expression																				{
																									$$ = new SBaseASTNode("{expressionlist}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	| expression_list ',' expression															{
																									// Append identifier to primary {identifier} node
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(n0);
																								}
	;

parameter_list
	: '(' ')'																					{
																									$$ = new SBaseASTNode("{()}", "");
																									g_context.PushNode($$);
																								}
	| '(' expression_list ')'																	{
																									$$ = new SBaseASTNode("{(...)}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	;

function_statement
	: simple_identifier parameter_list ';'														{
																									$$ = new SBaseASTNode("{call}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									g_context.PushNode($$);
																								}
	;

code_block_start
	: BEGINBLOCK																				{
																									$$ = new SBaseASTNode("{codeblockbegin}", " // NOTE: push a new scope here");
																									// This is a prologue section for a code block
																									g_context.PushNode($$);
																								}
	;

code_block_end
	: ENDBLOCK																					{
																									$$ = new SBaseASTNode("{codeblockend}", " // NOTE: pop the current scope here (taking down variables within scope)");
																									// This is an epilogue section for a code block
																									g_context.PushNode($$);
																								}
	;

code_block_body
	:																							{
																									$$ = new SBaseASTNode("{statement:null}", "");
																									g_context.PushNode($$);
																								}
	| function_statement																		{
																									$$ = new SBaseASTNode("{statement:F}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	| code_block_body function_statement														{
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(n0);
																								}
	| expression_statement																		{
																									$$ = new SBaseASTNode("{expressionstatement}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	| code_block_body expression_statement														{
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(n0);
																								}
	| while_statement																			{
																									$$ = new SBaseASTNode("{while}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	| code_block_body while_statement															{
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(n0);
																								}
	| variable_declaration_statement															{
																									$$ = new SBaseASTNode("{statement:V}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	| code_block_body variable_declaration_statement											{
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(n0);
																								}
	| using_statement																			{
																									$$ = new SBaseASTNode("{statement:P}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									g_context.PushNode($$);
																								}
	| code_block_body using_statement															{
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *varnode = g_context.m_NodeStack.top();
																									varnode->m_SubNodes.push(n0);
																								}
	;

function_def
	: FUNCTION simple_identifier parameter_list code_block_start code_block_body code_block_end	{
																									$$ = new SBaseASTNode("{func}", "");
																									SBaseASTNode *n0=g_context.PopNode();
																									SBaseASTNode *n1=g_context.PopNode();
																									SBaseASTNode *n2=g_context.PopNode();
																									SBaseASTNode *n3=g_context.PopNode();
																									SBaseASTNode *n4=g_context.PopNode();
																									$$->m_SubNodes.push(n0);
																									$$->m_SubNodes.push(n1);
																									$$->m_SubNodes.push(n2);
																									$$->m_SubNodes.push(n3);
																									$$->m_SubNodes.push(n4);
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
%%

void DumpEntry(int nodelevel, SBaseASTNode *node)
{
	static const std::string nodespaces="                                                                                        ";
	size_t sz = node->m_SubNodes.size();

	bool isvardecl = false;
	if (node->m_Value == "{var}")
		isvardecl = true;

	// TODO: This is where we can somewhat start adding prologues / epilogues / labels and generate some code
	printf("%s%s\t%s\n", nodespaces.substr(0,nodelevel).c_str(), node->m_Value.c_str(), node->m_Code.c_str());

	for(size_t i=0;i<sz;++i)
	{
		SBaseASTNode *sub = node->m_SubNodes.top();
		DumpEntry(nodelevel+1, sub);
		if (isvardecl)
			printf("// DEFVAR %s\n", sub->m_Value.c_str());
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
