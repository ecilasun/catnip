D	[0-9]
L	[a-zA-Z_]
H	[a-fA-F0-9]
E	([Ee][+-]?{D}+)
P	([Pp][+-]?{D}+)
FS	(f|F|l|L)
IS	((u|U)|(u|U)?(l|L|ll|LL)|(l|L|ll|LL)(u|U))


%{
// 1st revisioon: Based on https://www.lysator.liu.se/c/ANSI-C-grammar-l.html
// 2nd revision: Based on https://gist.github.com/codebrainz/2933703

#include <stdio.h>
#if defined(CAT_WINDOWS)
#include <io.h>
#else
#include <unistd.h>
#endif
#include "cparse.hpp"

extern YYSTYPE yylval;

void comment();
void count();
int check_type();

%}

%option nounistd
%option noyywrap

%%
"/*"			{ comment(); }
"//"[^\n]*		{ /* consume //-comment */ }

"auto"			{ count();  return(AUTO); }
"break"			{ count();  return(BREAK); }
"byte"			{ count();  return(BYTE); }
"case"			{ count();  return(CASE); }
"char"			{ count();  return(CHAR); }
"const"			{ count();  return(CONST); }
"continue"		{ count();  return(CONTINUE); }
"default"		{ count();  return(DEFAULT); }
"do"			{ count();  return(DO); }
"double"		{ count();  return(DOUBLE); }
"dword"			{ count();  return(DWORD); }
"else"			{ count();  return(ELSE); }
"enum"			{ count();  return(ENUM); }
"extern"		{ count();  return(EXTERN); }
"float"			{ count();  return(FLOAT); }
"for"			{ count();  return(FOR); }
"goto"			{ count();  return(GOTO); }
"if"			{ count();  return(IF); }
"inline"		{ count(); return(INLINE); }
"int"			{ count();  return(INT); }
"long"			{ count();  return(LONG); }
"register"		{ count();  return(REGISTER); }
"restrict"		{ count(); return(RESTRICT); }
"return"		{ count();  return(RETURN); }
"short"			{ count();  return(SHORT); }
"signed"		{ count();  return(SIGNED); }
"sizeof"		{ count();  return(SIZEOF); }
"static"		{ count();  return(STATIC); }
"struct"		{ count();  return(STRUCT); }
"switch"		{ count();  return(SWITCH); }
"typedef"		{ count();  return(TYPEDEF); }
"union"			{ count();  return(UNION); }
"unsigned"		{ count();  return(UNSIGNED); }
"void"			{ count();  return(VOID); }
"volatile"		{ count();  return(VOLATILE); }
"while"			{ count();  return(WHILE); }
"_Bool"			{ count();  return(BOOL); }
"_Complex"		{ count();  return(COMPLEX); }
"_Imaginary"	{ count();  return(IMAGINARY); }
"word"			{ count();  return(WORD); }

{L}({L}|{D})*	{ count();  sscanf(yytext, "%s", yylval.string); return check_type(); }

0[xX]{H}+{IS}?		{ count(); sscanf(yytext, "%x", &yylval.numeric); return(CONSTANT); }
0[0-7]*{IS}?		{ count(); yylval.numeric = atoi(yytext); return(CONSTANT); }
[1-9]{D}*{IS}?		{ count(); yylval.numeric = atoi(yytext); return(CONSTANT); }
L?'(\\.|[^\\'\n])+'	{ count(); return(CONSTANT); }

{D}+{E}{FS}?				{ count(); return(CONSTANT); }
{D}*"."{D}+{E}?{FS}?		{ count(); return(CONSTANT); }
{D}+"."{D}*{E}?{FS}?		{ count(); return(CONSTANT); }
0[xX]{H}+{P}{FS}?			{ count(); return(CONSTANT); }
0[xX]{H}*"."{H}+{P}?{FS}?	{ count(); return(CONSTANT); }
0[xX]{H}+"."{H}*{P}?{FS}?	{ count(); return(CONSTANT); }

L?\"(\\.|[^\\"\n])*\"	{ count(); sscanf(yytext, "%s", yylval.string); return(STRING_LITERAL); }

"..."			{ count();  return(ELLIPSIS); }
">>="			{ count();  return(RIGHT_ASSIGN); }
"<<="			{ count();  return(LEFT_ASSIGN); }
"+="			{ count();  return(ADD_ASSIGN); }
"-="			{ count();  return(SUB_ASSIGN); }
"*="			{ count();  return(MUL_ASSIGN); }
"/="			{ count();  return(DIV_ASSIGN); }
"%="			{ count();  return(MOD_ASSIGN); }
"&="			{ count();  return(AND_ASSIGN); }
"^="			{ count();  return(XOR_ASSIGN); }
"|="			{ count();  return(OR_ASSIGN); }
">>"			{ count();  return(RIGHT_OP); }
"<<"			{ count();  return(LEFT_OP); }
"++"			{ count();  return(INC_OP); }
"--"			{ count();  return(DEC_OP); }
"->"			{ count();  return(PTR_OP); }
"&&"			{ count();  return(AND_OP); }
"||"			{ count();  return(OR_OP); }
"<="			{ count();  return(LE_OP); }
">="			{ count();  return(GE_OP); }
"=="			{ count();  return(EQ_OP); }
"!="			{ count();  return(NE_OP); }
";"				{ count();  return(';'); }
("{"|"<%")		{ count();  return('{'); }
("}"|"%>")		{ count();  return('}'); }
","				{ count();  return(','); }
":"				{ count();  return(':'); }
"="				{ count();  return('='); }
"("				{ count();  return('('); }
")"				{ count();  return(')'); }
("["|"<:")		{ count();  return('['); }
("]"|":>")		{ count();  return(']'); }
"."			{ count();  return('.'); }
"&"			{ count();  return('&'); }
"!"			{ count();  return('!'); }
"~"			{ count();  return('~'); }
"-"			{ count();  return('-'); }
"+"			{ count();  return('+'); }
"*"			{ count();  return('*'); }
"/"			{ count();  return('/'); }
"%"			{ count();  return('%'); }
"<"			{ count();  return(LESS_OP); }
">"			{ count();  return(GREATER_OP); }
"^"			{ count();  return('^'); }
"|"			{ count();  return('|'); }
"?"			{ count();  return('?'); }

[ \t\v\n\f]		{ count(); }
.			{ /* ignore bad characters */ }

%%

int check_type()
{
	// TODO: Or any of the previous typedefs / structs / unions
	if (yytext == "byte" || yytext == "word" || yytext == "dword" || yytext == "char" || yytext == "short" || yytext == "int" || yytext == "long" || yytext == "double" || yytext == "_Bool" || yytext == "_Complex" || yytext == "_Imaginary")
		return(TYPEDEF_NAME);

	return(IDENTIFIER);
}

void comment()
{
	char c, prev = 0;
	while ((c = yyinput()) != 0)      /* (EOF maps to 0) */
	{
		if (c == '/' && prev == '*')
			return;
		prev = c;
	}
	printf("ERROR: unterminated comment");
}

int line = 0;
int column = 0;

void count()
{
	int i;

	for (i = 0; yytext[i] != '\0'; i++)
		if (yytext[i] == '\n')
		{
			column = 0;
			++line;
		}
		else if (yytext[i] == '\t')
			column += 8 - (column % 8);
		else
			++column;

	ECHO;
}
