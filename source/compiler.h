#include <vector>
#include <string>
#include <iostream>
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
    TK_Unknown,
    TK_Identifier,
    TK_LitNumeric,
    TK_LitString,
    TK_Symbol,
};

struct SToken
{
    ETokenType m_Type{TK_Unknown};
    std::string m_Value;
};

typedef std::vector<SToken> TTokenTable;

void Tokenize(std::string &_inputStream, TSymbolTable &_symTable, TTokenTable &_tokenTable, ETokenType &_tokenType);

// ---------------------------------------------------------------------------
// Syntax analyzer structs/enums
// ---------------------------------------------------------------------------

struct SASTNode
{
    SSymbolTableEnty m_Self;
    SASTNode *m_Left{nullptr};
    SASTNode *m_Right{nullptr};
};

typedef std::vector<struct SASTNode> TAbstractSyntaxTree;

void GenerateAST(TTokenTable &_tokenTable, TAbstractSyntaxTree &_ast);

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
