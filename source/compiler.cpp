#include "compiler.h"

//#define OLD_COMPILER_ONE
//#define OLD_COMPILER_TWO

#if defined(OLD_COMPILER_ONE)
#include "../grammar/nanoc.y.hpp"
#elif defined(OLD_COMPILER_TWO)
#include "../grammar/ec.y.hpp"
extern void dumpnodes(void);
#else
// GrimR - Person Wearing A Mask / Helmet / The Fierce One
#include "../grammar/grimr.y.hpp"
extern void dumpnodes(void);
#endif

int CompileCode(char *_inputname, char * /*_outputname*/)
{
	// Test Flex/Bison code
	extern FILE *yyin;
	yyin = fopen(_inputname, "r");

#if defined(OLD_COMPILER_ONE)
	// Prologue
	printf("// Prologue\n");
	printf("RESETSTACKCURSOR\n  // Set stack cursor to zero\n");
	printf("CALL @__global_init\n");
	printf("CALL @main\n");
	printf("BREAK\n\n");

	// Global initalizer function
	printf("// Global initialization\n");
	printf("@FUNCTION\n");
	printf("@NAME '__global_init'\n");
#endif

	int result = yyparse();
	fclose(yyin);

	dumpnodes();

	return 0;
}
