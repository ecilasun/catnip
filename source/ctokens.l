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

case        return CASE;
default     return DEFAULT;
if          return IF;
else        return ELSE;
switch      return SWITCH;
while       return WHILE;
do          return DO;
for         return FOR;
goto        return GOTO;
continue    return CONTINUE;
break       return BREAK;
return      return RETURN;
char        return CHAR;
short       return SHORT;
int         return INT;
long        return LONG;
signed      return SIGNED;
unsigned    return UNSIGNED;
float       return FLOAT;
double      return DOUBLE;
const       return CONST;
volatile    return VOLATILE;
void        return VOID;

for 		return FOR;
while		return WHILE;
if		    return IF;
do		    return DO;
return  	return RETURN;
break		return BREAK;
case 		return CASE;
switch		return SWITCH;
default 	return DEFAULT;
continue 	return CONTINUE;
else		return ELSE;
struct 		return STRUCT;

"<="   		return LE_OP;
">="    	return GE_OP;
"=="    	return EQ_OP;
"!="    	return NE_OP;
">" 		return GREATER_OP;
"<"	    	return LESS_OP;

\/\/.* 			 ;
\/\*(.*\n)*.*\*\/ 	 ;

{digit}+    return CONSTANT;
{alpha}({alpha}|{digit})* return IDENTIFIER;
[!%]		return IDENTIFIER;

.      		return yytext[0];
%%
