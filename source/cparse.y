%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *);

extern FILE *yyin;
extern char *yytext;
extern FILE *fp;
int err=0;
%}

%token DWORD WORD BYTE DWORDPTR WORDPTR BYTEPTR VOID
%token FOR WHILE DO 
%token IF ELSE RETURN BREAK CONTINUE DEFINE CASE SWITCH DEFAULT MAIN
%token STRUCT
%token NUM ID
%token INCLUDE
%token DOT
%token SPACE HASH

%right '='
%left '+' '-'
%left '*' '/'
%left AND OR
%left '<' '>' LE GE EQ NE LT GT
%%

/* Program structure */
start:   multi_Declaration  MainFunction 
	| include multi_Declaration  MainFunction
	| include MainFunction
	| MainFunction
	;

/* Multi declaration */
multi_Declaration:Declaration 
		 |multi_Declaration Declaration 
		 ;

/* Declaration block */
Declaration: Type Assignment ';' 
	| Assignment ';'  	
	| FunctionCall ';' 	
	| ArrayUsage ';'	
	| Type ArrayUsage ';'   
	| StructStmt 
	| error	
	;

/* Assignment block */
Assignment: ID '=' Assignment
	| ID '=' FunctionCall
	| ID '=' ArrayUsage
	| ID '+''+'',' Assignment
	| ID '-''-' ',' Assignment
	| '+''+' ID ',' Assignment
	| '-''-' ID  ','Assignment
	| ArrayUsage '=' Assignment
	| ID ',' Assignment
	| Numeric ',' Assignment
	| ID '+' Assignment
	| ID '-' Assignment
	| ID '*' Assignment
	| ID '/' Assignment	
	| Numeric '+' Assignment
	| Numeric '-' Assignment
	| Numeric '*' Assignment
	| Numeric '/' Assignment
	| '\'' Assignment '\''	
	| '(' Assignment ')'
	| '-' '(' Assignment ')'
	| '-' Numeric
	| '-' ID
	|ID '+''+'
	|ID '-''-'
	|'+''+' ID
	|'-''-' ID
	|Numeric
	|ID
	;

/* Macro or Preprocessor block */
include:'#' INCLUDE LT ID DOT ID GT 
	|'#' DEFINE ID Numeric
	|'#' DEFINE ID ID
	|include '#' INCLUDE LT ID DOT ID GT
	|include '#' DEFINE ID Numeric
	|include '#' DEFINE ID ID
	;

/* Function Call Block */
FunctionCall : ID'('')'
	| ID'('Assignment')'
	;

/* Array Usage */
ArrayUsage : ID'['Numeric']'
	   | ID'['Numeric']''['Numeric']'
	;

/* Function block */
MainFunction: Type MAIN '(' ArgListOpt ')' CompoundStmt 
	;
	
/* Multi_Function */
ArgListOpt: ArgList
	|
	;
	
/* Argument List */
ArgList:  ArgList ',' Arg
	| Arg
	;
	
/* Argument type */
Arg:	Type ID
	;
	
/* Compound statements */
CompoundStmt:	'{' StmtList '}'
	;
	
/* Statement List */
StmtList:	StmtList Stmt
	|
	;
	
/* Statements */
Stmt:	WhileStmt
	| doWhileStmt
	| multi_Declaration
	| ForStmt
	| IfStmt
	| retStmt
	| SwitchStmt
	| ';'
	;
	
/* Return Statement */
retStmt:RETURN '(' ID ')' ';'
	|RETURN '(' Numeric ')' ';'
	;
	
loopStmt: Stmt
	  |breakStmt
	  |contStmt
	;
	
/*loop Compound statements */
loopCompoundStmt:	'{' loopStmtList '}'
	;
	
/*loop Statement List */
loopStmtList:	loopStmtList loopStmt
	|
	;
	
/* Break Statement */	
breakStmt:BREAK ';';

/* Continue Statement */
contStmt:CONTINUE ';';

/* Type Identifier block */
Type:	DWORDPTR
	| WORDPTR 
	| BYTEPTR
	| DWORD
	| WORD 
	| BYTE
	| VOID 
	;

/*  While Loop Block */ 
WhileStmt: WHILE '(' Expr ')' loopStmt  
	| WHILE '(' Expr ')' loopCompoundStmt 
	;

/*  Do While Loop Block */ 
doWhileStmt: DO loopStmt WHILE '(' Expr ')' ';' 
	| DO loopCompoundStmt WHILE  '(' Expr ')' ';'
	;

/* For Block */
ForStmt: FOR '(' Expr ';' Expr ';' Expr ')' loopStmt 
       | FOR '(' Expr ';' Expr ';' Expr ')' loopCompoundStmt 
       | FOR '(' Expr ')' loopStmt 
       | FOR '(' Expr ')' loopCompoundStmt 
	;

/* IfStmt Block */
IfStmt : IF '(' Expr ')' 
	 	Stmt 
	|IF '(' Expr ')' CompoundStmt
	|IF '(' Expr ')' CompoundStmt ELSE CompoundStmt
	|IF '(' Expr ')' CompoundStmt ELSE Stmt
	;
/* Switch Statement */
SwitchStmt:SWITCH '(' ID ')' '{' CaseBlock '}' 
	  |SWITCH '(' ID ')' '{' CaseBlock   DEFAULT ':'  loopCompoundStmt '}'
	  |SWITCH '(' ID ')' '{' CaseBlock   DEFAULT ':'  loopStmt '}'
	  ;
/* Case Block */
CaseBlock:CASE Numeric ':'  loopCompoundStmt 
	 |CASE Numeric ':'  loopStmt 
	 |CaseBlock CASE Numeric ':'  loopCompoundStmt 
	 |CaseBlock CASE Numeric ':'  loopStmt
	 ;
	 

/* Struct Statement */
StructStmt : STRUCT ID '{' multi_Declaration '}' ';'
	   | STRUCT ID '{' multi_Declaration '}'  ID ';'
	   | STRUCT ID '{' multi_Declaration '}'  ID '['NUM']' ';'
	;
	
/* Expression Block */
Expr:	
	| Expr LE Expr 
	| Expr GE Expr
	| Expr NE Expr
	| Expr EQ Expr
	| Expr GT Expr
	| Expr LT Expr
	| Expr '+' Expr
	| Expr '-' Expr
	| Expr '*' Expr
	| Expr '/' Expr
	| '(' Expr ')'
	| Assignment
	| ArrayUsage
	;

/* Numeric */
Numeric:	'0' 'x' NUM
	| NUM
	;
%%
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
