#include "compiler.h"

// GrimR : Person Wearing A Mask / Helmet / The Fierce One
#include "../grammar/grimr.y.hpp"
extern bool CompileGrimR(const char *_filename);

int CompileGrimR(char *_inputname, const char *_outputname)
{
	// Test Flex/Bison code
	extern FILE *yyin;
	yyin = fopen(_inputname, "r");

	int result = yyparse();
	fclose(yyin);

	printf("Compiling: %s\n", _inputname);
	bool failed = CompileGrimR(_outputname);

	return failed ? -1 : 0;
}
