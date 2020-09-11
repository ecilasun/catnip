#include "compiler.h"

// GrimR : Person Wearing A Mask / Helmet / The Fierce One
#include "../grammar/grimr.y.hpp"
extern void dumpnodes(void);

int CompileCode(char *_inputname, char * /*_outputname*/)
{
	// Test Flex/Bison code
	extern FILE *yyin;
	yyin = fopen(_inputname, "r");

	int result = yyparse();
	fclose(yyin);

	dumpnodes();

	return 0;
}
