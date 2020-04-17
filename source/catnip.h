#include <stdio.h>
#include <iostream>
#if defined(CAT_LINUX) || defined(CAT_MACOSX)
#include <string.h>
#endif
#include <string>

#include "emulator.h"
#include "assembler.h"
#include "compiler.h"
