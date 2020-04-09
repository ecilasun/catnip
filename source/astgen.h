#include <windows.h>
#include <string>

struct STokenParserContext
{
    int m_MaxBodyDepth{0};
    int m_MaxParameterDepth{0};
    HANDLE m_hStdout;
};

enum ETokenClass
{
    ETC_Unknown,
    ETC_Keyword,
    ETC_AsmInstruction,
    ETC_TypeName,
    ETC_VariableDeclaration,
    ETC_Variable,
    ETC_Symbol,
    ETC_Name,
    ETC_StringLiteral,
    ETC_NumericLiteral,
    ETC_FunctionDefinition,
    ETC_FunctionCall,
    ETC_Builtin,
    ETC_BeginParameterList,
    ETC_EndParameterList,
    ETC_Assignment,
    ETC_BodyStart,
    ETC_BodyEnd,
};

enum ETokenSubClass
{
    ETSC_Actual = 0,
    ETSC_Pointer = 1,
    ETSC_Handle = 2,
    ETSC_Reference = 4,
};

int ASTGenerate(std::string &_input, STokenParserContext &_ctx);
