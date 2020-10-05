#include "compiler.h"

// GrimR : Person Wearing A Mask / Helmet / The Fierce One
#include "../grammar/grimr.y.hpp"
extern void CompileGrimR(const char *_filename);

int CompileGrimR(char *_inputname, const char *_outputname)
{
	// Test Flex/Bison code
	extern FILE *yyin;
	yyin = fopen(_inputname, "r");

	int result = yyparse();
	fclose(yyin);

	printf("Compiling: %s\n", _inputname);
	CompileGrimR(_outputname);

	return 0;
}
