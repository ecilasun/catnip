#include "compiler.h"

#include "../grammar/nanoc.y.hpp"

int CompileCode(char *_inputname, char * /*_outputname*/)
{
	// Test Flex/Bison code
	extern FILE *yyin;
	yyin = fopen(_inputname, "r");
	int result = yyparse();
	fclose(yyin);

	return -1;
}
