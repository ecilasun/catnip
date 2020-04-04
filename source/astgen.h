#include <windows.h>
#include <string>

struct STokenParserContext
{
    int m_MaxBodyDepth{0};
    int m_MaxParameterDepth{0};
    HANDLE m_hStdout;
};

int ASTGenerate(std::string &_input, STokenParserContext &_ctx);
