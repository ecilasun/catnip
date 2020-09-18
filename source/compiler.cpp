#include "compiler.h"

// GrimR : Person Wearing A Mask / Helmet / The Fierce One
#include "../grammar/grimr.y.hpp"
extern void ConvertNodes(void);
extern void GatherSymbols(void);
extern void ScanSymbolAccessErrors(void);
extern void CompilePrePass(void);
extern void DebugDump(void);
extern void CompilePass(void);

int CompileCode(char *_inputname, char * /*_outputname*/)
{
	// Test Flex/Bison code
	extern FILE *yyin;
	yyin = fopen(_inputname, "r");

	int result = yyparse();
	fclose(yyin);

	ConvertNodes();
	GatherSymbols();
	ScanSymbolAccessErrors();
	CompilePass();

	DebugDump();

	return 0;
}
