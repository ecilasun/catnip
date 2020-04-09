#include <stdio.h>
#include <vector>
#include <iostream>
#include "astgen.h"

std::string g_whitespace = " \r\n\t";
std::string g_letters = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVQXYZ";
std::string g_symbols = "<>!=,;{}()[]+-*%^/\\'#@&|\":";
std::string g_numerals = "0123456789";
std::string g_numeralsAlsoHex = "0123456789xABCDEF";
std::string g_keywords = "return for while do if continue break switch case asm";
std::string g_asmkeywords = "mov out in branch call branchif callif ret cmp test";
std::string g_typenames = "register uint int ushort short bool void uchar char";

typedef std::vector<struct SToken> TTokenList;

struct SToken
{
    std::string m_Value;                        // String representation of token
    ETokenClass m_Class{ETC_Unknown};           // Class of token
    ETokenSubClass m_SubClass{ETSC_Actual};     // Subclass of variable
    int m_BodyDepth{0};                         // Level of depth for this tokens
    int m_ParameterDepth{0};                    // Level of depth for this parameter
    //TTokenList m_TokenList;                     // Child nodes
};

TTokenList g_TokenList;

class CASTNode
{
public:
    SToken *m_Token;
    std::vector<SToken*> m_ChildNodes;
};

class CASTTree
{
    CASTNode m_RootNode;
};

void ASTSkipComment(std::string &_input, std::string &_output)
{
    if (_input[0]=='/' && _input[1]=='/')
    {
        size_t found = _input.find("\n", 1);
        if (found != std::string::npos)
            _output = _input.substr(found+1);
        else
            _output = _input.substr(2);
    }
    else if (_input[0]=='/' && _input[1]=='*')
    {
        size_t found = _input.find("*/", 2);
        if (found != std::string::npos)
            _output = _input.substr(found+2);
        else
            _output = _input.substr(2);
    }
    else
        _output = _input;
}

void ASTSkipWhiteSpace(std::string &_input, std::string &_output)
{
    std::string::size_type found = 0;
    found = _input.find_first_not_of(g_whitespace);
    if (found != std::string::npos)
        _output = _input.substr(found);
    else
        _output = "";
}

void ASTStringLiteralEnd(std::string &_input, std::string &_token, std::string::size_type &_offset)
{
    _offset = _input.find("\"");
    _token = _input.substr(0, _offset);
    _offset += 1; // Make the close quote vanish from scanner
}

void ASTNextToken(std::string &_input, std::string &_token, std::string::size_type &_offset)
{
    std::string::size_type foundstart = 0;
    if (g_letters.find_first_of(_input[0]) != std::string::npos)
    {
        // Was a letter, continue until not a letter
        std::string::size_type foundend = 0;
        foundend = _input.find_first_not_of(g_letters, foundstart);
        _token = _input.substr(foundstart, foundend);
        _offset = foundend;
    }
    else
    {
        if (g_symbols.find_first_of(_input[0]) != std::string::npos)
        {
            // Was a symbol, continue until not a symbol
            std::string::size_type foundend = 0;
            // Dice symbols into one character size blocks since we don't want a batch of combinations to cope with
            //foundend = _input.find_first_not_of(g_symbols, foundstart);
            foundend = 1;
            _token = _input.substr(foundstart, foundend);
            _offset = foundend;
        }
        else
        {
            if (g_numerals.find_first_of(_input[0]) != std::string::npos)
            {
                // Was a numeral, continue until not a symbol
                std::string::size_type foundend = 0;
                foundend = _input.find_first_not_of(g_numeralsAlsoHex, foundstart);
                _token = _input.substr(foundstart, foundend);
                _offset = foundend;
            }
            else
            {
                _token = "";
                _offset = std::string::npos;
            }
        }
    }
}

static const char *s_tokenTypeNames[]=
{
    "Unknown",
    "Keyword",
    "AsmInstruction",
    "TypeName",
    "VariableDeclaration",
    "Variable",
    "Symbol",
    "Name",
    "StringLiteral",
    "NumericLiteral",
    "FunctionDefinition",
    "FunctionCall",
    "Builtin",
    "BeginParameterList",
    "EndParameterList",
    "Assignment",
    "BodyStart",
    "BodyEnd",
};

void ASTDumpTokens(TTokenList &root, STokenParserContext &_ctx)
{
    HANDLE hStdout = _ctx.m_hStdout;

    for (auto &t : root)
    {
        //if (rootNode == nullptr)
        /*if (nodelevel != t.m_BodyDepth)
        {
            if (t.m_Class == ETC_FunctionDefinition || t.m_Class == ETC_FunctionCall)
            {
                nodelevel = t.m_BodyDepth;
                rootNode->m_Token = &t;
                std::cout << "\nroot(" << nodelevel << ") = '" << t.m_Value << "'\n";
            }
        }*/
        SetConsoleTextAttribute(hStdout, FOREGROUND_RED|FOREGROUND_GREEN|FOREGROUND_BLUE);
        std::cout << s_tokenTypeNames[t.m_Class] << ": ";
        // if (t.m_Class == ETC_Keyword || t.m_Class == ETC_FunctionCall || t.m_Class == ETC_Builtin)
        //     SetConsoleTextAttribute(hStdout, FOREGROUND_BLUE|FOREGROUND_INTENSITY);
        // else if (t.m_Class == ETC_TypeName)
        //     SetConsoleTextAttribute(hStdout, FOREGROUND_RED);
        // else if (t.m_Class == ETC_Symbol)
        //     SetConsoleTextAttribute(hStdout, BACKGROUND_RED|BACKGROUND_GREEN|BACKGROUND_INTENSITY);
        // else if (t.m_Class == ETC_NumericLiteral)
        //     SetConsoleTextAttribute(hStdout, BACKGROUND_GREEN|BACKGROUND_INTENSITY);
        // else if (t.m_Class == ETC_FunctionDefinition)
        //     SetConsoleTextAttribute(hStdout, FOREGROUND_RED|FOREGROUND_BLUE|FOREGROUND_INTENSITY);
        // else if (t.m_Class == ETC_Variable)
        //     SetConsoleTextAttribute(hStdout, FOREGROUND_RED|FOREGROUND_INTENSITY|BACKGROUND_GREEN);
        // else if (t.m_Class == ETC_BeginParameterList || t.m_Class == ETC_EndParameterList)
        //     SetConsoleTextAttribute(hStdout, FOREGROUND_RED|FOREGROUND_GREEN);
        // else if (t.m_Class == ETC_Assignment)
        //     SetConsoleTextAttribute(hStdout, FOREGROUND_RED|FOREGROUND_BLUE);
        // else if (t.m_Class == ETC_VariableDeclaration)
        // {
        //     SetConsoleTextAttribute(hStdout, FOREGROUND_RED|FOREGROUND_GREEN|FOREGROUND_BLUE);
        //     if (t.m_SubClass&ETSC_Pointer) std::cout << "pointer::";
        //     if (t.m_SubClass&ETSC_Handle) std::cout << "handle::";
        // }
        // else if (t.m_Class == ETC_StringLiteral)
        //     SetConsoleTextAttribute(hStdout, BACKGROUND_RED|BACKGROUND_GREEN|BACKGROUND_BLUE);
        // else if (t.m_Class == ETC_BodyStart || t.m_Class == ETC_BodyEnd)
        //     SetConsoleTextAttribute(hStdout, FOREGROUND_GREEN|BACKGROUND_RED);
        // else // Unknown
        //     SetConsoleTextAttribute(hStdout, BACKGROUND_RED|BACKGROUND_INTENSITY);

        // Show token data
        //std::cout << t.m_Value << "(" << t.m_BodyDepth << ":" << t.m_ParameterDepth << ")";
        SetConsoleTextAttribute(hStdout, BACKGROUND_RED|BACKGROUND_GREEN|BACKGROUND_BLUE|BACKGROUND_INTENSITY);
        std::cout << t.m_Value;
        SetConsoleTextAttribute(hStdout, FOREGROUND_RED|FOREGROUND_GREEN|FOREGROUND_BLUE);

        // Dump children
        //ASTDumpTokens(t.m_TokenList, _ctx);

        //SetConsoleTextAttribute(hStdout, FOREGROUND_RED|FOREGROUND_GREEN|FOREGROUND_BLUE);
        if (t.m_Value == ";" || t.m_Value == "{" || t.m_Value == "}")
            std::cout << "\n";
        else
            std::cout << " ";
    }
}

int ASTGenerate(std::string &_input, STokenParserContext &_ctx)
{
    HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE);
    //SetConsoleTextAttribute(hStdout, FOREGROUND_RED|FOREGROUND_GREEN|FOREGROUND_BLUE);
    _ctx.m_hStdout = hStdout;

    std::string out, token;
    std::string::size_type offset;
    uint32_t stringliteralstack = 0;
    int bodydepth = 0;
    int parameterdepth = 0;
    do{
        if (stringliteralstack)
        {
            ASTStringLiteralEnd(_input, token, offset);
            SToken t;
            t.m_Value = token;
            t.m_Class = ETC_StringLiteral;
            t.m_BodyDepth = bodydepth;
            t.m_ParameterDepth = parameterdepth;
            g_TokenList.emplace_back(t);
            stringliteralstack = 0;
        }
        else
        {
            ASTSkipWhiteSpace(_input, _input);
            ASTSkipComment(_input, _input);

            ASTSkipWhiteSpace(_input, _input);
            ASTNextToken(_input, token, offset);

            if (g_keywords.find(token) != std::string::npos)
            {
                SToken t;
                t.m_Value = token;
                t.m_Class = ETC_Keyword;
                t.m_BodyDepth = bodydepth;
                t.m_ParameterDepth = parameterdepth;
                g_TokenList.emplace_back(t);
            }
            else if (g_asmkeywords.find(token) != std::string::npos)
            {
                SToken t;
                t.m_Value = token;
                t.m_Class = ETC_AsmInstruction;
                t.m_BodyDepth = bodydepth;
                t.m_ParameterDepth = parameterdepth;
                g_TokenList.emplace_back(t);
            }
            else if (g_typenames.find(token) != std::string::npos)
            {
                SToken t;
                t.m_Value = token;
                t.m_Class = ETC_TypeName;
                t.m_BodyDepth = bodydepth;
                t.m_ParameterDepth = parameterdepth;
                g_TokenList.emplace_back(t);
            }
            else if (g_symbols.find(token) != std::string::npos)
            {
                if (token == "\"") // Make the first open quote vanish
                    stringliteralstack = 1;
                else
                {
                    bool beginbody = token == "{" ? true:false;
                    bool endbody = token == "}" ? true:false;
                    bool beginparameter = token == "(" ? true:false;
                    bool endparameter = token == ")" ? true:false;
                    bodydepth += beginbody ? 1 : 0;
                    parameterdepth += beginparameter ? 1 : 0;
                    SToken t;
                    t.m_Value = token;
                    t.m_Class = beginbody ? ETC_BodyStart : (endbody ? ETC_BodyEnd : (beginparameter ? ETC_BeginParameterList : (endparameter ? ETC_EndParameterList : ETC_Symbol)));
                    t.m_BodyDepth = bodydepth;
                    t.m_ParameterDepth = parameterdepth;
                    g_TokenList.emplace_back(t);
                    bodydepth -= endbody ? 1 : 0;
                    parameterdepth -= endparameter ? 1 : 0;

                    _ctx.m_MaxBodyDepth = max(_ctx.m_MaxBodyDepth, bodydepth);
                    _ctx.m_MaxParameterDepth = max(_ctx.m_MaxParameterDepth, parameterdepth);
                }
            }
            else
            {
                SToken t;
                t.m_Value = token;
                if (g_numerals.find_first_of(token[0]) != std::string::npos)
                    t.m_Class = ETC_NumericLiteral;
                else
                    t.m_Class = ETC_Unknown;
                t.m_BodyDepth = bodydepth;
                t.m_ParameterDepth = parameterdepth;
                g_TokenList.emplace_back(t);
            }
        }
        if (offset == std::string::npos)
            break;
        _input = _input.substr(offset);
    } while (1);

    // ) Remove 'empty' tokens
    {
        auto beg = g_TokenList.begin();
        while (beg != g_TokenList.end())
        {
            // An 'unknown' followed by a "(" is a function call if not followed by "{" (if followed by "{" it is a definition)
            if (beg->m_Value == "")
            {
                beg = g_TokenList.erase(beg);
                continue;
            }
            ++beg;
        }
    }

    // ) Collapse function definitions
    {
        auto beg = g_TokenList.begin();
        while (beg != g_TokenList.end())
        {
            // A type followed by an 'unknown' followed by a "(" is a function definition
            if (beg->m_Class == ETC_TypeName && (beg+1)->m_Class == ETC_Unknown && (beg+2)->m_Value == "(")
            {
                std::string returntype = beg->m_Value;
                std::string functionname = (beg+1)->m_Value;
                std::string beginparameterlist = (beg+2)->m_Value;
                beg->m_Class = ETC_TypeName;
                beg->m_Value = returntype;
                (beg+1)->m_Class = ETC_FunctionDefinition;
                (beg+1)->m_Value = functionname;
                (beg+2)->m_Class = ETC_BeginParameterList;
                (beg+2)->m_Value = beginparameterlist;
                beg += 3;
                continue;
            }
            ++beg;
        }
    }

    // ) Collapse variables
    {
        auto beg = g_TokenList.begin();
        while (beg != g_TokenList.end())
        {
            // An 'unknown' followed by a "(" is a function call if not followed by "{" (if followed by "{" it is a definition)
            if (beg->m_Class == ETC_TypeName && (beg+1)->m_Class == ETC_Unknown)
            {
                (beg+1)->m_Class = ETC_VariableDeclaration;
                beg+=2;
                continue;
            }
            // cases such as char*
            if (beg->m_Class == ETC_TypeName && (beg+1)->m_Class == ETC_Symbol && (beg+2)->m_Class == ETC_Unknown)
            {
                (beg+2)->m_Class = ETC_VariableDeclaration;
                beg+=3;
                continue;
            }
            // cases such as char**
            if (beg->m_Class == ETC_TypeName && (beg+1)->m_Class == ETC_Symbol && (beg+2)->m_Class == ETC_Symbol && (beg+3)->m_Class == ETC_Unknown)
            {
                (beg+3)->m_Class = ETC_VariableDeclaration;
                beg+=4;
                continue;
            }
            ++beg;
        }
    }

    // ) Scan for variable usages
    {
        auto beg = g_TokenList.begin();
        while (beg != g_TokenList.end())
        {
            if (beg->m_Class == ETC_Unknown)
            {
                bool declarationfound = false;
                // Look for a variable declaration with the same name
                auto vbeg = g_TokenList.begin();
                while (vbeg != beg)
                {
                    if (vbeg->m_Class == ETC_VariableDeclaration && vbeg->m_Value == beg->m_Value) // variable
                    {
                        beg->m_Class = ETC_Variable;
                        declarationfound = true;
                        break;
                    }
                    if (vbeg->m_Class == ETC_FunctionDefinition && vbeg->m_Value == beg->m_Value) // or function
                    {
                        beg->m_Class = ETC_FunctionCall;
                        declarationfound = true;
                        break;
                    }
                    ++vbeg;
                }
                if (declarationfound == false)
                {
                    //SetConsoleTextAttribute(hStdout, FOREGROUND_RED|FOREGROUND_GREEN);
                    std::cout << "WARNING: '" << beg->m_Value << "' is not declared in this module.\n";
                }
            }
            ++beg;
        }
    }

    // ) Deduce subtypes
    {
        auto beg = g_TokenList.begin();
        while (beg != g_TokenList.end())
        {
            // An 'unknown' followed by a "(" is a function call if not followed by "{" (if followed by "{" it is a definition)
            if (beg->m_Class == ETC_VariableDeclaration)
            {
                if ((beg-2)->m_Value == "*" && (beg-1)->m_Value == "*")
                {
                    beg->m_SubClass = ETSC_Handle;
                    beg = g_TokenList.erase(beg-1);
                    beg = g_TokenList.erase(beg-1);
                }
                else if ((beg-1)->m_Value == "*")
                {
                    beg->m_SubClass = ETSC_Pointer;
                    beg = g_TokenList.erase(beg-1);
                }
                else if ((beg-1)->m_Value == "&")
                {
                    beg->m_SubClass = ETSC_Reference;
                    beg = g_TokenList.erase(beg-1);
                }
            }
            ++beg;
        }
    }

    // ) Collapse function calls
    {
        auto beg = g_TokenList.begin();
        while (beg != g_TokenList.end())
        {
            // 'unknown' or keyword followed by a "(" is a function / builtin call
            if ((beg->m_Class == ETC_Unknown || beg->m_Class == ETC_Keyword) && (beg+1)->m_Value == "(")
            {
                if (g_keywords.find_first_of(beg->m_Value) != std::string::npos)
                {
                    std::string builtinname = beg->m_Value;
                    beg->m_Class = ETC_Builtin;
                    beg->m_Value = builtinname;
                }
                else
                {
                    std::string functionname = beg->m_Value;
                    beg->m_Class = ETC_FunctionCall;
                    beg->m_Value = functionname;

                    // TODO: Collect all nodes and add them as child nodes to beg, then erase them from main list
                    /*auto cbeg = beg+1;
                    int skipcount = 0;
                    bool breaknext = false;
                    while (cbeg != g_TokenList.end())
                    {
                        beg->m_TokenList.emplace_back(*cbeg);
                        cbeg = g_TokenList.erase(cbeg);
                        ++skipcount;
                        if (breaknext)
                            break;
                        if (cbeg->m_Class == ETC_EndParameterList)
                            breaknext = true;
                    }
                    beg += skipcount+1;*/
                }
                beg += 2;
                continue;
            }
            ++beg;
        }
    }

    // ) Collapse assignments
    {
        auto beg = g_TokenList.begin();
        while (beg != g_TokenList.end())
        {
            if ((beg->m_Class == ETC_Variable || beg->m_Class == ETC_VariableDeclaration)  && (beg+1)->m_Value == "=")
            {
                (beg+1)->m_Class = ETC_Assignment;
                beg+=2;
                continue;
            }
            ++beg;
        }
    }

    // DEBUG: Dump tokens
    //CASTNode *rootNode = new CASTNode();
    //int nodelevel = -1;
    ASTDumpTokens(g_TokenList, _ctx);

    std::cout << "Max Body Depth: " << _ctx.m_MaxBodyDepth << "\n";
    std::cout << "Max Parameter Depth: " << _ctx.m_MaxParameterDepth << "\n";

    return 0; // No error
}