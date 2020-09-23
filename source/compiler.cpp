#include "compiler.h"

// GrimR : Person Wearing A Mask / Helmet / The Fierce One
#include "../grammar/grimr.y.hpp"
extern void DebugDump(const char *_filename);

int CompileCode(char *_inputname, char *_outputname)
{
	// Test Flex/Bison code
	extern FILE *yyin;
	yyin = fopen(_inputname, "r");

	int result = yyparse();
	fclose(yyin);

	/*
	GatherSymbols();
	ScanSymbolAccessErrors();
	CompilePass();

	SaveAsm(_outputname);*/

	DebugDump(_outputname);

	return 0;
}
