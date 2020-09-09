#include "compiler.h"

#include "../grammar/nanoc.y.hpp"

int CompileCode(char *_inputname, char * /*_outputname*/)
{
	// Test Flex/Bison code
	extern FILE *yyin;
	yyin = fopen(_inputname, "r");

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

	int result = yyparse();
	fclose(yyin);

	return -1;
}
