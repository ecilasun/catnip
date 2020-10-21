D	[0-9]
L	[a-zA-Z:]
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
void stripquotes(char *string);

%}

%option nounistd
%option noyywrap

%%
"/*"						{ comment(); }
"//"[^\n]*					{ /* consume //-comment */ }

"void"						{ count();  return(VOID); }
"int"						{ count();  return(DWORD); }
"short"						{ count();  return(WORD); }
"char"						{ count();  return(BYTE); }

"def"						{ count();  return(FUNCTION); }
"if"						{ count();  return(IF); }
"else"						{ count();  return(ELSE); }
"while"						{ count();  return(WHILE); }
"{"							{ count();  return(BEGINBLOCK); }
"}"							{ count();  return(ENDBLOCK); }
"return"					{ count();  return(RETURN); }

"vsync"						{ count();  return(VSYNC); }
"fsel"						{ count();  return(FSEL); }
"asel"						{ count();  return(ASEL); }
"clf"						{ count();  return(CLF); }
"spritesheet"				{ count();  return(SPRITESHEET); }
"sprite"					{ count();  return(SPRITE); }
"spriteorigin"				{ count();  return(SPRITEORIGIN); }

"["							{ count();  return('['); }
"]"							{ count();  return(']'); }

"("							{ count();  return('('); }
")"							{ count();  return(')'); }

":"							{ count();  return(':'); }
";"							{ count();  return(';'); }
","							{ count();  return(','); }

"<<"						{ count();  return(SHIFTLEFT_OP); }
">>"						{ count();  return(SHIFTRIGHT_OP); }

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

"++"						{ count();  return(INC_OP); }
"--"						{ count();  return(DEC_OP); }

{L}({L}|{D})*				{ count(); sscanf(yytext, "%s", yylval.string); return(IDENTIFIER); }

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

L?\"(\\.|[^\\"\n])*\"		{ count(); sscanf(yytext, "%s", yylval.string); stripquotes(yytext); return(STRING_LITERAL); }

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

void stripquotes(char *string)
{
	char *copy = strdup(string);
	int l = strlen(string);
	strncpy(string, copy+1, l-2);
	string[l-2] = 0;
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

int column = 0;

void count()
{
	int i;

	for (i = 0; yytext[i] != '\0'; i++)
		if (yytext[i] == '\n')
		{
			column = 0;
			++yylineno;
		}
		else if (yytext[i] == '\t')
			column += 8 - (column % 8);
		else
			++column;

	// ECHO;
}