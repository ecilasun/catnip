#include "compiler.h"

#include "../build/release/source/cparse.hpp"

int CompileCode(char *_inputname, char *_outputname)
{
	extern FILE *yyin;
	yyin = fopen(_inputname, "r");
	int res = yyparse();
	fclose(yyin);
	return res;
}
