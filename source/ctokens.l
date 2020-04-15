%{
#include <io.h>
#include "cparse.hpp"
%}

%option noyywrap
%option nounistd

alpha [a-zA-Z]
digit [0-9,x]
%%
[ \t]			;
[ \n]   	{ yylineno = yylineno + 1;}
dword		return DWORD;
word		return WORD;
byte 		return BYTE;
dwordptr	return DWORDPTR;
wordptr		return WORDPTR;
byteptr 	return BYTEPTR;
void 		return VOID;
for 		return FOR;
while		return WHILE;
if		return IF;
do		return DO;
return  	return RETURN;
break		return BREAK;
define  	return DEFINE;
include 	return INCLUDE;
case 		return CASE;
switch		return SWITCH;
main		return MAIN;
default 	return DEFAULT;
continue 	return CONTINUE;
else		return ELSE;
struct 		return STRUCT;
{digit}+    return NUM;
{alpha}({alpha}|{digit})* return ID;
"<="   		return LE;
">="    	return GE;
"=="    	return EQ;
"!="    	return NE;
">"		return GT;
"<"		return LT;
\.     		return DOT;
[!%]		return ID;
\/\/.* 			 ;
\/\*(.*\n)*.*\*\/ 	 ;
.      		return yytext[0];
%%
