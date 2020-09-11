D	[0-9]
L	[a-zA-Z_]
H	[a-fA-F0-9]
E	([Ee][+-]?{D}+)
P	([Pp][+-]?{D}+)
FS	(f|F|l|L)
IS	((u|U)|(u|U)?(l|L|ll|LL)|(l|L|ll|LL)(u|U))


%{

#include <stdio.h>
#if defined(__clang__)
#include <unistd.h>
#else
#include <io.h>
#endif
#include "grimr.y.hpp"

extern YYSTYPE yylval;

int check_type();
void comment();
void count();

%}

%option nounistd
%option noyywrap

%%
"#"[^\n]*					{ /* consume //-comment */ }

"var"						{ count();  return(VAR); }
"function"					{ count();  return(FUNCTION); }

"using"						{ count();  return(USING); }

"if"						{ count();  return(IF); }
"then"						{ count();  return(THEN); }
"else"						{ count();  return(ELSE); }

"for"						{ count();  return(FOR); }

"begin"						{ count();  return(BEGINBLOCK); }
"end"						{ count();  return(ENDBLOCK); }

"goto"						{ count();  return(GOTO); }
"return"					{ count();  return(RETURN); }

"["							{ count();  return('['); }
"]"							{ count();  return(']'); }

"("							{ count();  return('('); }
")"							{ count();  return(')'); }

":"							{ count();  return(':'); }
";"							{ count();  return(';'); }
","							{ count();  return(','); }

"&"							{ count();  return('&'); }
"!"							{ count();  return('!'); }
"~"							{ count();  return('~'); }
"-"							{ count();  return('-'); }
"+"							{ count();  return('+'); }
"*"							{ count();  return('*'); }
"/"							{ count();  return('/'); }
"%"							{ count();  return('%'); }
"^"							{ count();  return('^'); }
"|"							{ count();  return('|'); }
"?"							{ count();  return('?'); }
"="							{ count();  return('='); }
"<="						{ count();  return(LESSEQUAL_OP); }
"<"							{ count();  return(LESS_OP); }
">"							{ count();  return(GREATER_OP); }
">="						{ count();  return(GREATEREQUAL_OP); }
"=="						{ count();  return(EQUAL_OP); }
"!="						{ count();  return(NOTEQUAL_OP); }
"&&"						{ count();  return(AND_OP); }
"||"						{ count();  return(OR_OP); }

{L}({L}|{D})*				{ count();  sscanf(yytext, "%s", yylval.string); return(IDENTIFIER); }

0[xX]{H}+{IS}?				{ count(); sscanf(yytext, "%x", &yylval.numeric); return(CONSTANT); }
0[0-7]*{IS}?				{ count(); yylval.numeric = atoi(yytext); return(CONSTANT); }
[1-9]{D}*{IS}?				{ count(); yylval.numeric = atoi(yytext); return(CONSTANT); }
L?'(\\.|[^\\'\n])+'			{ count(); return(CONSTANT); }

{D}+{E}{FS}?				{ count(); return(CONSTANT); }
{D}*"."{D}+{E}?{FS}?		{ count(); return(CONSTANT); }
{D}+"."{D}*{E}?{FS}?		{ count(); return(CONSTANT); }
0[xX]{H}+{P}{FS}?			{ count(); return(CONSTANT); }
0[xX]{H}*"."{H}+{P}?{FS}?	{ count(); return(CONSTANT); }
0[xX]{H}+"."{H}*{P}?{FS}?	{ count(); return(CONSTANT); }

L?\"(\\.|[^\\"\n])*\"		{ count(); sscanf(yytext, "%s", yylval.string); return(STRING_LITERAL); }

[ \t\v\n\f]					{ count(); }
.							{ /* ignore bad characters */ }

%%

int check_type()
{
/*
* pseudo code --- this is what it should check
*
*	if (yytext == type_name)
*		return(TYPE_NAME);
*
*	return(IDENTIFIER);
*/

/*
*	it actually will only return IDENTIFIER
*/

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

	// ECHO;
}