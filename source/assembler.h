
#include <vector>
#if defined(CAT_LINUX) || defined(CAT_MACOSX)
#include "string.h"
#include "stdio.h"
#endif
#include "inttypes.h"
int compile_asm(const char *_inputname, const char *_outputname);