#include <vector>
#include <string>
#include <iostream>
#include <regex>
#include "inttypes.h"

// ---------------------------------------------------------------------------
// Usefult macros
// ---------------------------------------------------------------------------

#define EAlignUp(_x_, _align_) ((_x_ + (_align_ - 1)) & (~(_align_ - 1)))

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
	TK_Keyword,
	TK_AsmKeyword,
	TK_Typename,

	TK_OpLogicNegate,
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

	TK_OpBitNot,
	TK_OpBitOr,
	TK_OpBitAnd,
	TK_OpBitXor,

	TK_EndStatement,

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
	PS_ParameterList,
	PS_InitializerList,
	PS_Expression,
	PS_ExpressionParamList,
	PS_OptionalExpression,
	PS_Statements,
};

enum EASTNodeType
{
	NT_Unknown,
	NT_BinaryOperator,
	NT_FunctionDefinition,
	NT_VariableDeclaration,
	NT_Initializer,
	NT_TypeName,
	NT_Identifier,
	NT_VariablePointer,
	NT_OpAssignment,
	NT_LiteralConstant,
	NT_Expression,
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

struct SASTContext
{
	uint8_t *m_VariableStore{nullptr};		  // Array of bytes used as variable declaration/initialization pool during AST generation
	std::string m_ErrorString;				  // Containst the error string if the m_HasError flag is nonzero
	std::string m_LHS;						  // Used during expression gather
	uint32_t m_HasError{0};					 // Nonzero if there is an error during AST generation
	int32_t m_BlockDepth{0};					// Depth of current statement block (zero=root)
	uint32_t m_VariableStoreCursor{0};		  // Advances every time a persistent value is declared
	SASTNode *m_AssignmentTargetNode{nullptr};  // Previous node that's the recipient of an assignment operation
	uint32_t m_CurrentInitializerOffset{0};	 // Variable initialization list cursor
};

typedef std::vector<struct SASTNode> TAbstractSyntaxTree;

void ParseAndGenerateAST(TTokenTable &_tokenTable, TAbstractSyntaxTree &_ast, SParserState &state, uint32_t &currentToken, SASTContext *_context);

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
