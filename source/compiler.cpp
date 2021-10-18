#include "compiler.h"

// GrimR : Person Wearing A Mask / Helmet / The Fierce One
#include "../grammar/grimr.y.hpp"
extern bool GenerateASM(const char *_filename, bool _forX64);

int CompileGrimR(char *_inputname, const char *_outputname, bool _forX64)
{
	// Test Flex/Bison code
	extern FILE *yyin;
	yyin = fopen(_inputname, "r");

	int result = yyparse();
	fclose(yyin);

	printf("Compiling: %s -> %s\n", _inputname,  _outputname);
	bool failed = GenerateASM(_outputname, _forX64);

	return failed ? -1 : 0;
}
