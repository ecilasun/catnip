#include <vector>
#include <string>
#include <iostream>
#include <regex>
#include "inttypes.h"

// ---------------------------------------------------------------------------
// Symbol table structs/enums
// ---------------------------------------------------------------------------

enum EStorageType
{
    ST_Unknown,
    ST_StringLiteral,
    ST_NumericLiteral,
    ST_Pointer,
    ST_Word,
    ST_WordArray,
    ST_Byte,
    ST_ByteArray,
    ST_Define,
    ST_Function,
    ST_Void,
};

struct SSymbolTableEnty
{
    std::string m_Name;
    std::string m_Value;
    EStorageType m_Type;
};

typedef std::vector<SSymbolTableEnty> TSymbolTable;

// ---------------------------------------------------------------------------
// Lexical analyzer structs/enums
// ---------------------------------------------------------------------------

enum ETokenType
{
    // Initial basic types
    TK_Unknown,
    TK_Identifier,
    TK_LitNumeric,
    TK_LitString,
    TK_Symbol,
    TK_Operator,

    // Further expanded types
    TK_OpAssignment,
    TK_OpCmpEqual,
    TK_OpCmpLess,
    TK_OpCmpGreater,
    TK_OpCmpNotEqual,
    TK_OpCmpGreaterEqual,
    TK_OpCmpLessEqual,
    TK_OpAdd,
    TK_OpSub,
    TK_OpMul,
    TK_OpDiv,
    TK_OpMod,
    TK_EndStatement,
    TK_Keyword,
    TK_AsmKeyword,
    TK_Typename,
    TK_BeginBlock,
    TK_EndBlock,
    TK_BeginParams,
    TK_EndParams,
    TK_BeginArray,
    TK_EndArray,
    TK_Separator,
};

struct STokenEntry
{
    ETokenType m_Type{TK_Unknown};
    std::string m_Value;
};

typedef std::vector<STokenEntry> TTokenTable;

void Tokenize(std::string &_inputStream, TSymbolTable &_symTable, TTokenTable &_tokenTable, ETokenType &_tokenType);

// ---------------------------------------------------------------------------
// Syntax analyzer structs/enums
// ---------------------------------------------------------------------------

enum SParserState
{
    PS_Unknown,
    PS_Statement,
    PS_Expression,
    PS_OptionalExpression,
    PS_Statements,
};

enum EASTNodeType
{
    NT_Unknown,
    NT_VariableDeclaration,
    NT_TypeName,
    NT_Identifier,
    NT_OpAssignment,
    NT_LiteralConstant,
};

struct SASTEntry
{
    std::string m_Value{};
    EASTNodeType m_Type{NT_Unknown};
};

struct SASTNode
{
    SASTEntry m_Self;
    SASTNode *m_Left{nullptr};
    SASTNode *m_Right{nullptr};
};

typedef std::vector<struct SASTNode> TAbstractSyntaxTree;

void ParseAndGenerateAST(TTokenTable &_tokenTable, TAbstractSyntaxTree &_ast, SParserState &state, uint32_t &currentToken, SASTNode *_payload);

// ---------------------------------------------------------------------------
// Semantic analyzer structs/enums
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Intermediate code generator structs/enums
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Intermediate code optimizer structs/enums
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Machine code generator structs/enums
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Machine code optimizer structs/enums
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Compiler driver
// ---------------------------------------------------------------------------

int CompileCode(char *_inputname, char *_outputname);
