#include <stdio.h>

#include <string>
#include <vector>
#include <stack>
#include <map>
#include <regex>
#include <iostream>
#include <inttypes.h>
#include <functional>

// ---------------------------------------------------------------------------
// Useful macros
// ---------------------------------------------------------------------------

#define EAlignUp(_x_, _align_) ((_x_ + (_align_ - 1)) & (~(_align_ - 1)))

// ---------------------------------------------------------------------------
// Compiler driver
// ---------------------------------------------------------------------------

int CompileCode(char *_inputname, const char *_outputname);
