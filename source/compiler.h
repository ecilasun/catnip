#include <stdio.h>

#include <string>
#include <vector>
#include <regex>
#include <iostream>
#include <inttypes.h>

// ---------------------------------------------------------------------------
// Usefult macros
// ---------------------------------------------------------------------------

#define EAlignUp(_x_, _align_) ((_x_ + (_align_ - 1)) & (~(_align_ - 1)))

// ---------------------------------------------------------------------------
// Compiler drivers
// ---------------------------------------------------------------------------

int CompileCode(char *_inputname, char *_outputname);

int CompileCode2(char *_inputname, char *_outputname);
