%{

#include <stdio.h>
#include <stdlib.h>
#include <stack>
#include <deque>
#include <string>
#include <sstream>
#include <iomanip>
#include <map>
#include <vector>

extern int yylex(void);
void yyerror(const char *);
int yyparse(void);

extern int yylineno;
extern int column;
extern FILE *yyin;
extern char *yytext;
extern FILE *fp;
int err=0;

static uint32_t s_prevLineNo;

uint32_t HashString(const char *_str)
{
	size_t Val = 2166136261U;

	if(_str == nullptr)
		return (uint32_t)Val;

	char *pStr = (char *)_str;
	while(*pStr)
	{
		Val = 16777619U * Val ^ (size_t)*pStr;
		++pStr;
	}

	return (uint32_t)(Val);
}

enum EASTNodeType
{
	EN_Default,
	EN_CompoundStatement,
	EN_VarDeclStatement,
	EN_ConstructDecl,
	EN_Identifier,
	EN_StrucName,
	EN_ArrayIdentifier,
	EN_Constant,
	EN_String,
	EN_PostfixArrayExpression,
	EN_PrimaryExpression,
	EN_UnaryValueOf,
	EN_UnaryAddressOf,
	EN_UnaryBitNot,
	EN_UnaryNegate,
	EN_UnaryLogicNot,
	EN_Mul,
	EN_Div,
	EN_Mod,
	EN_Add,
	EN_Abs,
	EN_BitShiftLeft,
	EN_BitShiftRight,
	EN_Expression,
	EN_AssignmentExpression,
	EN_LessThan,
	EN_GreaterThan,
	EN_LessEqual,
	EN_GreaterEqual,
	EN_Equal,
	EN_NotEqual,
	EN_BitAnd,
	EN_BitOr,
	EN_BitXor,
	EN_PrefixInc,
	EN_PrefixDec,
	EN_ConditionalExpr,
	EN_LogicAnd,
	EN_LogicOr,
	EN_SelectExpression,
	EN_While,
	EN_Do,
	EN_For,
	EN_If,
	EN_Label,
	EN_Jump,
	EN_JumpNZ,
	EN_Flow,
	EN_FlowNZ,
	EN_DummyString,
	EN_Call,
	EN_Return,
	EN_ReturnVal,
	EN_Break,
	EN_FrameSelect,
	EN_ClearFrame,
	EN_Sprite,
	EN_SpriteSheet,
	EN_SpriteOrigin,
	EN_Vsync,
	EN_AudioSelect,
	EN_In,
	EN_Out,
	EN_CodeBlock,
	EN_StackPush,
	EN_StackPop,
	EN_Decl,
	EN_DeclInitJunction,
	EN_DeclArray,
	EN_ArrayJunction,
	EN_ArrayWithDataJunction,
	EN_TypedIdentifier,
	EN_FuncDecl,
	EN_Prologue,
	EN_Epilogue,
	EN_Statement,
	EN_EndOfProgram,
};

const char* NodeTypes[]=
{
	"EN_Default                   ",
	"EN_CompoundStatement         ",
	"EN_VarDeclStatement          ",
	"EN_ConstructDecl             ",
	"EN_Identifier                ",
	"EN_StrucName                 ",
	"EN_ArrayIdentifier           ",
	"EN_Constant                  ",
	"EN_String                    ",
	"EN_PostfixArrayExpression    ",
	"EN_PrimaryExpression         ",
	"EN_UnaryValueOf              ",
	"EN_UnaryAddressOf            ",
	"EN_UnaryBitNot               ",
	"EN_UnaryNegate               ",
	"EN_UnaryLogicNot             ",
	"EN_Mul                       ",
	"EN_Div                       ",
	"EN_Mod                       ",
	"EN_Add                       ",
	"EN_Abs                       ",
	"EN_BitShiftLeft              ",
	"EN_BitShiftRight             ",
	"EN_Expression                ",
	"EN_AssignmentExpression      ",
	"EN_LessThan                  ",
	"EN_GreaterThan               ",
	"EN_LessEqual                 ",
	"EN_GreaterEqual              ",
	"EN_Equal                     ",
	"EN_NotEqual                  ",
	"EN_BitAnd                    ",
	"EN_BitOr                     ",
	"EN_BitXor                    ",
	"EN_PrefixInc                 ",
	"EN_PrefixDec                 ",
	"EN_ConditionalExpr           ",
	"EN_LogicAnd                  ",
	"EN_LogicOr                   ",
	"EN_SelectExpression          ",
	"EN_While                     ",
	"EN_Do                        ",
	"EN_For                       ",
	"EN_If                        ",
	"EN_Label                     ",
	"EN_Jump                      ",
	"EN_JumpNZ                    ",
	"EN_Flow                      ",
	"EN_FlowNZ                    ",
	"EN_DummyString               ",
	"EN_Call                      ",
	"EN_Return                    ",
	"EN_ReturnVal                 ",
	"EN_Break                     ",
	"EN_FrameSelect               ",
	"EN_ClearFrame                ",
	"EN_Sprite                    ",
	"EN_SpriteSheet               ",
	"EN_SpriteOrigin              ",
	"EN_Vsync                     ",
	"EN_AudioSelect               ",
	"EN_In                        ",
	"EN_Out                       ",
	"EN_CodeBlock                 ",
	"EN_StackPush                 ",
	"EN_StackPop                  ",
	"EN_Decl                      ",
	"EN_DeclInitJunction          ",
	"EN_DeclArray                 ",
	"EN_ArrayJunction             ",
	"EN_ArrayWithDataJunction     ",
	"EN_TypedIdentifier           ",
	"EN_FuncDecl                  ",
	"EN_Prologue                  ",
	"EN_Epilogue                  ",
	"EN_Statement                 ",
	"EN_EndOfProgram              ",
};

enum EOpcode
{
	OP_PASSTHROUGH,
	OP_PULLINITEXPRESSION,
	OP_PULLINITSTRING,
	OP_NOOP,
	OP_INC,
	OP_DEC,
	OP_ADDRESSOF,
	OP_VALUEOF,
	OP_NOT,
	OP_NEG,
	OP_MUL,
	OP_DIV,
	OP_MOD,
	OP_ADD,
	OP_ABS,
	OP_BSL,
	OP_BSR,
	OP_ARRAYINDEX,
	OP_LEA,
	OP_LEA_RELATIVE,
	OP_LOAD,
	OP_DEFSTRING,
	OP_STORE,
	OP_COPY,
	OP_BULKASSIGN,
	OP_DATAARRAY,
	OP_RETURN,
	OP_RETURNVAL,
	OP_BREAK,
	OP_RESETREGISTERS,
	OP_FSEL,
	OP_ASEL,
	OP_CLF,
	OP_SPRITE,
	OP_SPRITESHEET,
	OP_SPRITEORIGIN,
	OP_IN,
	OP_OUT,
	OP_VSYNC,
	OP_PUSHCONTEXT,
	OP_POPCONTEXT,
	OP_PUSHLOCALREGISTERS,
	OP_POPLOCALREGISTERS,
	OP_IF,
	OP_WHILE,
	OP_DO,
	OP_FOR,
	OP_CALL,
	OP_PUSH,
	OP_POP,
	OP_DIRECTTOREGISTER,
	OP_JUMP,
	OP_JUMPIF,
	OP_JUMPIFNOT,
	OP_LABEL,
	OP_DECL,
	OP_DIM,
	OP_CMPL,
	OP_CMPG,
	OP_CMPLE,
	OP_CMPGE,
	OP_CMPE,
	OP_CMPNE,
	OP_TEST,
	OP_BITAND,
	OP_BITXOR,
	OP_BITOR,
};

const std::string OpcodesNeko[]={
	"",
	"st",
	"st", // OP_PULLINITSTRING
	"nop",
	"inc",
	"dec",
	"lea",
	"valof",
	"not",
	"ineg",
	"imul",
	"idiv",
	"imod",
	"iadd",
	"iabs",
	"bsl",
	"bsr",
	"arrayindex",
	"lea",
	"leaidx",
	"ld",
	"defstring",
	"st",
	"cp",
	"bulkassign",
	"dataarray",
	"ret",
	"ret",
	"brk",
	"resetregisters",
	"fsel",
	"asel",
	"clf",
	"sprite",
	"spritesheet",
	"spriteorigin",
	"in",
	"out",
	"vsync",
	"pushcontext",
	"popcontext",
	"pushregs",
	"popregs",
	"if",
	"while",
	"do",
	"for",
	"call",
	"push",
	"pop",
	"pop",
	"jmp",
	"jmpif",
	"jmpifnot",
	"@LABEL",
	"decl",
	"dim",
	"cmp",
	"cmp",
	"cmp",
	"cmp",
	"cmp",
	"cmp",
	"test",
	"and",
	"xor",
	"or",
};

const std::string OpcodesX64[]={
	"",
	"st",
	"st", // OP_PULLINITSTRING
	"nop",
	"inc",
	"dec",
	"lea",
	"valof",
	"not",
	"ineg",
	"imul",
	"idiv",
	"imod",
	"iadd",
	"iabs",
	"bsl",
	"bsr",
	"arrayindex",
	"lea",
	"leaidx",
	"ld",
	"defstring",
	"st",
	"cp",
	"bulkassign",
	"dataarray",
	"ret",
	"ret",
	"brk",
	"resetregisters",
	"fsel",
	"asel",
	"clf",
	"sprite",
	"spritesheet",
	"spriteorigin",
	"in",
	"out",
	"vsync",
	"pushcontext",
	"popcontext",
	"pushregs",
	"popregs",
	"if",
	"while",
	"do",
	"for",
	"call",
	"push",
	"pop",
	"pop",
	"jmp",
	"jmpif",
	"jmpifnot",
	"@LABEL",
	"decl",
	"dim",
	"cmp",
	"cmp",
	"cmp",
	"cmp",
	"cmp",
	"cmp",
	"test",
	"and",
	"xor",
	"or",
};

enum ENodeSide
{
	NO_SIDE,
	RIGHT_HAND_SIDE,
	LEFT_HAND_SIDE
};

struct SString
{
	std::string m_String;
	std::string m_StringTempName;
	uint32_t m_EndMarker{0};
	uint32_t m_Hash{0};
};

enum EAllocationModifier
{
	AM_NONE,
	AM_DYNAMIC,
	AM_STATIC,
};

enum ETypeName
{
	TN_CONSTRUCT,
	TN_VOID,
	TN_DWORD,
	TN_WORD,
	TN_BYTE,
	TN_VOIDPTR,
	TN_DWORDPTR,
	TN_WORDPTR,
	TN_BYTEPTR,
};

int TypeNameToStride[]={
	0,
	0,
	4,
	2,
	1,
	4,
	4,
	4,
	4
};

const char* TypeNameToInstructionSize[]={
	".?",
	".?",
	".d",
	".w",
	".b",
	".d",
	".d",
	".d",
	".d"
};

const char* TypeNameToInstructionSizeNotPointer[]={
	".?",
	".?",
	".d",
	".w",
	".b",
	".d",
	".d",
	".w",
	".b"
};

const char* TypeNames[]={
	"construct",
	"void",
	"dword",
	"word",
	"byte",
	"voidptr",
	"dwordptr",
	"wordptr",
	"byteptr",
};

const char* ReturnTypes[]={
	"construct",
	"void",
	"int",
	"short",
	"char",
	"void*",
	"int*",
	"short*",
	"char*",
};

struct SVariable
{
	std::string m_Name;
	std::string m_Scope;
	uint32_t m_NameHash{0};
	uint32_t m_ScopeHash{0};
	uint32_t m_DynamicAllocation{0};
	uint32_t m_Dimension{1};
	ETypeName m_TypeName{TN_WORD};
	std::string m_ConstructName;
	int m_RefCount{0};
	std::string m_Value;
	class SASTNode *m_RootNode{nullptr};
	SString *m_String{nullptr};
	std::vector<uint32_t> m_InitialValues;
};

struct SConstruct
{
	std::string m_Name;
	void PushVariable(std::string var)
	{
		m_Variables.push_back(var);
	}
	uint32_t m_Hash;
	int m_RefCount{0};
	class SASTNode *m_RootNode{nullptr};
	std::vector<std::string> m_Variables;
};

struct SFunction
{
	std::string m_Name;
	ETypeName m_ReturnType{TN_VOID};
	uint32_t m_Hash;
	int m_RefCount{0};
	class SASTNode *m_RootNode{nullptr};
};

struct SSymbol
{
	std::string m_Value;
	uint32_t m_Address{0xFFFFFFFF};
};

std::string RegisterPool[]=
{
	"eax",
	"ebx",
	"ecx",
	"edx",
	"r10",
	"r11",
	"r12",
	"r13",
	"r14",
	"r15",
	"REGERR0",
	"REGERR1",
	"REGERR2",
	"REGERR3",
	"REGERR4",
	"REGERR5",
};

class SASTNode
{
public:
	SASTNode(EASTNodeType _type, std::string _value) : m_Type(_type), m_Value(_value) {}

	void PushNode(SASTNode *_node)
	{
		m_ASTNodes.push_back(_node);
	}

	SASTNode *PeekNode()
	{
		SASTNode *node = m_ASTNodes.back();
		return node;
	}

	SASTNode *PopNode()
	{
		SASTNode *node = m_ASTNodes.back();
		m_ASTNodes.pop_back();
		return node;
	}

	EAllocationModifier m_AllocationModifier{AM_NONE};
	EOpcode m_Opcode{OP_PASSTHROUGH};
	EASTNodeType m_Type{EN_Default};
	ETypeName m_TypeName{TN_VOID};
	ENodeSide m_Side{RIGHT_HAND_SIDE};
	int m_Offset{0};
	int m_ScopeDepth{0};
	int m_Visited{0};
	uint32_t m_LineNumber{0xFFFFFFFF};
	ETypeName m_InheritedTypeName{TN_WORD};
	SString *m_String{nullptr};
	std::string m_Value;
	std::vector<SASTNode*> m_ASTNodes;
	std::string m_Instructions;
};

struct SASTScanContext
{
	void PushNode(SASTNode *_node)
	{
		m_ASTNodes.push_back(_node);
	}

	SASTNode *PeekNode()
	{
		SASTNode *node = m_ASTNodes.back();
		return node;
	}

	SASTNode *PopNode()
	{
		SASTNode *node = m_ASTNodes.back();
		m_ASTNodes.pop_back();
		return node;
	}

	SString *AllocateOrRetreiveString(const char *string)
	{
		uint32_t hash = HashString(string);

		auto found = m_StringTable.find(hash);
		if (found!=m_StringTable.end())
			return found->second;

		SString *str = new SString();
		str->m_Hash = hash;
		str->m_String = string;
		str->m_EndMarker = str->m_String.length();
		if (str->m_String.length()%2!=0) // Make sure the string is a multiple of WORD size
			str->m_String += " ";
		else
			str->m_String += "  ";
		std::stringstream stream;
		stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << str->m_Hash;
		str->m_StringTempName = "string_" + stream.str();

		m_StringTable[hash] = str;

		return str;
	}

	std::string PushRegister()
	{
		uint32_t r = m_CurrentRegister++;
		if (m_X64Mode)
			return std::string(RegisterPool[r]);
		else
			return std::string("r"+std::to_string(r));
	}

	std::string CurrentRegister()
	{
		if (m_X64Mode)
			return std::string(RegisterPool[m_CurrentRegister]);
		else
			return std::string("r"+std::to_string(m_CurrentRegister));
	}

	std::string PreviousRegister()
	{
		if (m_X64Mode)
			return std::string(RegisterPool[m_CurrentRegister-1]);
		else
			return std::string("r"+std::to_string(m_CurrentRegister-1));
	}

	std::string PopRegister()
	{
		uint32_t r = --m_CurrentRegister;
		if (m_X64Mode)
			return std::string(RegisterPool[r]);
		else
			return std::string("r"+std::to_string(r));
	}

	void ResetRegister()
	{
		m_CurrentRegister = 0;
	}

	std::string PushLabel(std::string labelname)
	{
		uint32_t r = m_CurrentAutoLabel++;
		//return std::string(labelname+std::to_string(r));
		std::stringstream stream;
		stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << r;
		return labelname+stream.str();
	}

	/*std::string PopLabel(std::string labelname)
	{
		return std::string(labelname+std::to_string(m_CurrentAutoLabel--));
	}*/

	SVariable *FindVariable(uint32_t namehash, uint32_t scopehash)
	{
		for(auto &var : m_Variables)
			if (var->m_NameHash == namehash && var->m_ScopeHash == scopehash)
				return var;
		return nullptr;
	}

	SFunction *FindFunction(uint32_t hash)
	{
		for(auto &fun : m_Functions)
			if (fun->m_Hash == hash)
				return fun;
		return nullptr;
	}

	SConstruct *FindConstruct(uint32_t hash)
	{
		for(auto &fun : m_Constructs)
			if (fun->m_Hash == hash)
				return fun;
		return nullptr;
	}

	std::vector<SASTNode*> m_ASTNodes;
	std::string m_CurrentFunctionName;
	ETypeName m_CurrentFunctionTypeName{TN_VOID};
	ETypeName m_CurrentTypeName{TN_WORD};
	std::string m_CurrentConstruct;
	std::vector<SVariable*> m_Variables;
	std::vector<SFunction*> m_Functions;
	std::vector<SConstruct*> m_Constructs;
	std::map<uint32_t, SSymbol> m_SymbolTable;
	std::map<uint32_t, SString*> m_StringTable;
	int m_CurrentRegister{0};
	int m_CurrentAutoLabel{0};
	int m_InstructionCount{0};
	bool m_IsConstruct{false};
	bool m_CompileFailed{false};
	bool m_X64Mode{false};
};

typedef void (*FVisitCallback)(SASTNode *node);

void VisitNode(SASTNode *node, FVisitCallback callback)
{
	// Visit op : parent first
	callback(node);

	for (auto &subnode : node->m_ASTNodes)
		VisitNode(subnode, callback);

	// Visit op : child first
}

void VisitNodeHierarchy(SASTNode *rootNode, FVisitCallback callback)
{
	VisitNode(rootNode, callback);
}

void SetAsRightHandSideCallback(SASTNode *node)
{
	node->m_Side = RIGHT_HAND_SIDE;
}

void SetAsLeftHandSideCallback(SASTNode *node)
{
	node->m_Side = LEFT_HAND_SIDE;
}

SASTScanContext g_ASC;

std::string GetOpcode(const int _idx)
{
	return g_ASC.m_X64Mode ? OpcodesX64[_idx] : OpcodesNeko[_idx];
}

%}

%union
{
	char string[128];
	unsigned int numeric;
	class SASTNode *astnode;
}

%token <string> IDENTIFIER
%token <string> LABEL
%token <numeric> CONSTANT
%token <string> STRING_LITERAL

%token LESS_OP GREATER_OP LESSEQUAL_OP GREATEREQUAL_OP EQUAL_OP NOTEQUAL_OP AND_OP OR_OP
%token SHIFTLEFT_OP SHIFTRIGHT_OP
%token STATIC
%token CONSTRUCT VOID DWORD WORD BYTE WORDPTR DWORDPTR BYTEPTR FUNCTION IF ELSE WHILE DO FOR BEGINBLOCK ENDBLOCK RETURN BREAK GOTO
%token ABS VSYNC FSEL ASEL CLF SPRITE SPRITESHEET SPRITEORIGIN IN OUT
%token INC_OP DEC_OP

%left '-' '+'
%left '*' '/'

// %precedence '='
// %precedence NEG
// %right '^'
//%nonassoc '('

%type <astnode> simple_identifier
%type <astnode> simple_constant
%type <astnode> simple_string

%type <astnode> variable_declaration_statement
%type <astnode> functioncall_statement
%type <astnode> expression_statement
%type <astnode> for_statement
%type <astnode> while_statement
%type <astnode> if_statement
%type <astnode> builtin_statement
%type <astnode> any_statement

%type <astnode> code_block_start
%type <astnode> code_block_end

%type <astnode> compound_statement

%type <astnode> primary_expression
%type <astnode> unary_expression
%type <astnode> postfix_expression

%type <astnode> variable_declaration_item
%type <astnode> variable_declaration
%type <astnode> typed_identifier
%type <astnode> function_def
%type <astnode> construct_def

%type <astnode> parameter_list
%type <astnode> function_parameters
%type <astnode> expression_list
%type <astnode> input_param_list

%type <astnode> additive_expression
%type <astnode> multiplicative_expression
%type <astnode> shift_expression
%type <astnode> relational_expression
%type <astnode> equality_expression
%type <astnode> and_expression
%type <astnode> exclusive_or_expression
%type <astnode> inclusive_or_expression
%type <astnode> logical_and_expression
%type <astnode> logical_or_expression
%type <astnode> conditional_expression
%type <astnode> assignment_expression
%type <astnode> expression

%type <astnode> translation_unit
%type <astnode> program

%start program

%%

simple_identifier
	: IDENTIFIER																				{
																									$$ = new SASTNode(EN_Identifier, std::string($1));
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_LEA;
																									g_ASC.PushNode($$);
																								}
	;

simple_constant
	: CONSTANT																					{
																									std::stringstream stream;
																									//stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << $1;
																									stream << std::hex << $1;
																									std::string result( stream.str() );
																									$$ = new SASTNode(EN_Constant, std::string("0x")+result);
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_LOAD;
																									g_ASC.PushNode($$);
																								}
	;

simple_string
	: STRING_LITERAL																			{
																									$$ = new SASTNode(EN_String, yytext); // $1 is just a single word, yytext includes spaces
																									$$->m_LineNumber = yylineno;
																									$$->m_String = g_ASC.AllocateOrRetreiveString(yytext);
																									$$->m_Opcode = OP_DEFSTRING;
																									g_ASC.PushNode($$);
																								}
	;

primary_expression
	: simple_identifier
	| simple_identifier parameter_list															{
																									// We need a 'call' as a child node
																									SASTNode *callnode = new SASTNode(EN_Call, "");
																									bool done = false;
																									int paramcount = 0;
																									do
																									{
																										SASTNode *paramnode = g_ASC.PeekNode();
																										done = paramnode->m_Type == EN_Expression ? false:true;
																										if (done)
																											break;
																										g_ASC.PopNode();
																										// Replace EN_Expression with EN_StackPush
																										paramnode->m_Type = EN_StackPush;
																										paramnode->m_Opcode = OP_PUSH;
																										callnode->m_ASTNodes.emplace(callnode->m_ASTNodes.begin(),paramnode);
																										++paramcount;
																									} while (1);
																									SASTNode *namenode = g_ASC.PopNode();
																									uint32_t hash = HashString(namenode->m_Value.c_str());
																									SFunction *func = g_ASC.FindFunction(hash);
																									if (func)
																									{
																										if (func->m_ReturnType==TN_VOID)
																										{
																											printf("ERROR: Cannot use void function %s in an expression\n", func->m_Name.c_str());
																											g_ASC.m_CompileFailed = true;
																										}
																										func->m_RefCount++;
																									}
																									else
																									{
																										printf("ERROR: Function %s not declared before use\n", namenode->m_Value.c_str());
																										g_ASC.m_CompileFailed = true;
																									}
																									//callnode->PushNode(namenode); // No need to push name node, this is part of the 'call' opcode (as a target label)
																									callnode->m_Opcode = OP_CALL;
																									callnode->m_Value = namenode->m_Value;

																									// We need a 'pop' for the return value
																									$$ = new SASTNode(EN_StackPop, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_DIRECTTOREGISTER;
																									$$->m_Value = namenode->m_Value;
																									g_ASC.PushNode($$);

																									$$->PushNode(callnode);
																									//g_ASC.PushNode(callnode);
																								}
	| simple_constant
	| simple_string
	| '(' expression ')'																		{}
	;

postfix_expression
	: primary_expression																		/*{
																									SASTNode *exprnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_PrimaryExpression, "");
																									$$->m_LineNumber = yylineno;
																									$$->PushNode(exprnode);
																									g_ASC.PushNode($$);
																								}*/
	| postfix_expression '[' expression ']'														{
																									SASTNode *offsetexpressionnode = g_ASC.PopNode();
																									SASTNode *exprnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_PostfixArrayExpression, "");
																									$$->m_LineNumber = yylineno;
																									// We need to evaluate offset first
																									$$->PushNode(offsetexpressionnode);
																									$$->PushNode(exprnode);
																									exprnode->m_Opcode = OP_ARRAYINDEX;
																									g_ASC.PushNode($$);
																								}
	;

unary_expression
	: postfix_expression
	| '~' unary_expression																		{
																									SASTNode *unaryexpressionnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_UnaryBitNot, "");
																									$$->m_LineNumber = yylineno;
																									$$->PushNode(unaryexpressionnode);
																									$$->m_Opcode = OP_NOT;
																									g_ASC.PushNode($$);
																								}
	| '-' unary_expression																		{
																									SASTNode *unaryexpressionnode = g_ASC.PopNode();
																									// Hardcode a negative constant if the node is a constant
																									if (unaryexpressionnode->m_Type == EN_Constant)
																									{
																										uint32_t constval = strtoul(unaryexpressionnode->m_Value.c_str(), nullptr, 16);
																										constval = (constval^0xFFFFFFFF)+1;
																										std::stringstream stream;
																										stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << constval;
																										unaryexpressionnode->m_Value = "0x"+stream.str();
																										g_ASC.PushNode(unaryexpressionnode);
																									}
																									else
																									{
																										$$ = new SASTNode(EN_UnaryNegate, "");
																										$$->m_LineNumber = yylineno;
																										$$->PushNode(unaryexpressionnode);
																										$$->m_Opcode = OP_NEG;
																										g_ASC.PushNode($$);
																									}
																								}
	| '!' unary_expression																		{
																									SASTNode *unaryexpressionnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_UnaryLogicNot, "");
																									$$->m_LineNumber = yylineno;
																									$$->PushNode(unaryexpressionnode);
																									$$->m_Opcode = OP_NOT;
																									g_ASC.PushNode($$);
																								}
	| '&' unary_expression																		{
																									SASTNode *unaryexpressionnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_UnaryAddressOf, "");
																									$$->m_LineNumber = yylineno;
																									$$->PushNode(unaryexpressionnode);
																									unaryexpressionnode->m_Opcode = OP_ADDRESSOF;
																									g_ASC.PushNode($$);
																								}
	| '*' unary_expression																		{
																									SASTNode *n0=g_ASC.PopNode();
																									$$ = new SASTNode(EN_UnaryValueOf, "");
																									$$->m_LineNumber = yylineno;
																									$$->PushNode(n0);
																									$$->m_Opcode = OP_VALUEOF;
																									g_ASC.PushNode($$);
																								}
	| INC_OP unary_expression																	{
																									SASTNode *exprnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_PrefixInc, "");
																									$$->m_LineNumber = yylineno;
																									$$->PushNode(exprnode);
																									$$->m_Opcode = OP_INC;
																									g_ASC.PushNode($$);
																								}
	| DEC_OP unary_expression																	{
																									SASTNode *exprnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_PrefixDec, "");
																									$$->m_LineNumber = yylineno;
																									$$->PushNode(exprnode);
																									$$->m_Opcode = OP_DEC;
																									g_ASC.PushNode($$);
																								}
	| ABS '(' expression ')'																	{
																									SASTNode *exprnode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_Abs, "");
																									$$->m_LineNumber = yylineno;
																									$$->PushNode(exprnode);
																									$$->m_Opcode = OP_ABS;
																									g_ASC.PushNode($$);
																								}
	;

// Accumulates right
multiplicative_expression
	: unary_expression
	| multiplicative_expression '*' unary_expression											{
																									$$ = new SASTNode(EN_Mul, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_MUL;
																									g_ASC.PushNode($$);
																								}
	| multiplicative_expression '/' unary_expression											{
																									$$ = new SASTNode(EN_Div, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_DIV;
																									g_ASC.PushNode($$);
																								}
	| multiplicative_expression '%' unary_expression											{
																									$$ = new SASTNode(EN_Mod, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_MOD;
																									g_ASC.PushNode($$);
																								}
	;

// Accumulates left
additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression											{
																									$$ = new SASTNode(EN_Add, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_ADD;
																									g_ASC.PushNode($$);
																								}
	| additive_expression '-' multiplicative_expression											{
																									$$ = new SASTNode(EN_Add, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode = g_ASC.PopNode();
																									SASTNode *leftnode = g_ASC.PopNode();
																									$$->PushNode(leftnode);

																									// Hardware doesn't have sub instruction
																									// Apply a neg and an add instead
																									SASTNode *negnode = new SASTNode(EN_UnaryNegate, "");
																									negnode->m_LineNumber = yylineno;
																									negnode->PushNode(rightnode);
																									negnode->m_Opcode = OP_NEG;
																									$$->PushNode(negnode);
																									$$->m_Opcode = OP_ADD;

																									// Sub instruction does not exist
																									/*$$->PushNode(rightnode);
																									$$->m_Opcode = OP_SUB;*/

																									g_ASC.PushNode($$);
																								}
	;

shift_expression
	: additive_expression
	| shift_expression SHIFTLEFT_OP additive_expression											{
																									$$ = new SASTNode(EN_BitShiftLeft, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_BSL;
																									g_ASC.PushNode($$);
																								}
	| shift_expression SHIFTRIGHT_OP additive_expression										{
																									$$ = new SASTNode(EN_BitShiftRight, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_BSR;
																									g_ASC.PushNode($$);
																								}
	;

relational_expression
	: shift_expression
	| relational_expression LESS_OP additive_expression											{
																									$$ = new SASTNode(EN_LessThan, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_CMPL;
																									g_ASC.PushNode($$);
																								}
	| relational_expression GREATER_OP additive_expression										{
																									$$ = new SASTNode(EN_GreaterThan, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_CMPG;
																									g_ASC.PushNode($$);
																								}
	| relational_expression LESSEQUAL_OP additive_expression									{
																									$$ = new SASTNode(EN_LessEqual, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_CMPLE;
																									g_ASC.PushNode($$);
																								}
	| relational_expression GREATEREQUAL_OP additive_expression									{
																									$$ = new SASTNode(EN_GreaterEqual, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_CMPGE;
																									g_ASC.PushNode($$);
																								}
	;
    
equality_expression
	: relational_expression
	| equality_expression EQUAL_OP relational_expression										{
																									$$ = new SASTNode(EN_Equal, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_CMPE;
																									g_ASC.PushNode($$);
																								}
	| equality_expression NOTEQUAL_OP relational_expression										{
																									$$ = new SASTNode(EN_NotEqual, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_CMPNE;
																									g_ASC.PushNode($$);
																								}
	;

and_expression
	: equality_expression
	| and_expression '&' equality_expression													{
																									$$ = new SASTNode(EN_BitAnd, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_BITAND;
																									g_ASC.PushNode($$);
																								}
	;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression												{
																									$$ = new SASTNode(EN_BitXor, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_BITXOR;
																									g_ASC.PushNode($$);
																								}
	;

inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression										{
																									$$ = new SASTNode(EN_BitOr, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_BITOR;
																									g_ASC.PushNode($$);
																								}
	;

logical_and_expression
	: inclusive_or_expression
	| logical_and_expression AND_OP inclusive_or_expression										{
																									$$ = new SASTNode(EN_LogicAnd, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_BITAND;
																									g_ASC.PushNode($$);
	}
	;

logical_or_expression
	: logical_and_expression
	| logical_or_expression OR_OP logical_and_expression										{
																									$$ = new SASTNode(EN_LogicOr, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									$$->PushNode(leftnode);
																									$$->PushNode(rightnode);
																									$$->m_Opcode = OP_BITOR;
																									g_ASC.PushNode($$);
																								}
	;

conditional_expression
	: logical_or_expression																		/*{
																									$$ = new SASTNode(EN_ConditionalExpr, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);
																									g_ASC.PushNode($$);
																								}*/
	;

assignment_expression
	: conditional_expression
	| unary_expression '=' assignment_expression												{
																									$$ = new SASTNode(EN_AssignmentExpression, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *rightnode=g_ASC.PopNode();
																									SASTNode *leftnode=g_ASC.PopNode();
																									//printf("LSH:%s\n", NodeTypes[leftnode->m_Type]);
																									//printf("RHS:%s\n", NodeTypes[rightnode->m_Type]); // EN_PostfixArrayExpression
																									if (leftnode->m_Type != EN_PostfixArrayExpression)
																										VisitNodeHierarchy(leftnode, SetAsLeftHandSideCallback);
																									else
																										VisitNodeHierarchy(leftnode->m_ASTNodes[1], SetAsLeftHandSideCallback);
																									VisitNodeHierarchy(rightnode, SetAsRightHandSideCallback);
																									// NOTE: Swap left and right nodes because we want to
																									// evaluate LHS last
																									$$->PushNode(rightnode);
																									$$->PushNode(leftnode);
																									$$->m_Opcode = OP_STORE;
																									g_ASC.PushNode($$);
																								}
	;

expression
	: assignment_expression
	/*| expression ',' assignment_expression														{
																								}*/ // NOTE: This is causing much grief and I don't think I need it at this point
	;

expression_statement
	: expression ';'																			{
																									$$ = new SASTNode(EN_Statement, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);
																									g_ASC.PushNode($$);
																								}
	;

if_statement
	: IF '(' expression ')' compound_statement													{
																									$$ = new SASTNode(EN_If, "");
																									$$->m_LineNumber = yylineno;

																									SASTNode *ifblocknode = g_ASC.PopNode();

																									std::string label = g_ASC.PushLabel("endif");
																									SASTNode *callcode = new SASTNode(EN_JumpNZ, label);
																									callcode->m_Opcode = OP_JUMPIFNOT;
																									SASTNode *endlabel = new SASTNode(EN_Label, label);
																									endlabel->m_Opcode = OP_LABEL;
																									SASTNode *exprnode=g_ASC.PopNode();

																									$$->PushNode(exprnode);
																									$$->PushNode(callcode);
																									$$->PushNode(ifblocknode);
																									$$->PushNode(endlabel);
																									g_ASC.PushNode($$);
																								}
	| IF '(' expression ')' compound_statement ELSE compound_statement							{
																									$$ = new SASTNode(EN_If, "");
																									$$->m_LineNumber = yylineno;

																									SASTNode *elseblocknode = g_ASC.PopNode();
																									SASTNode *ifblocknode = g_ASC.PopNode();

																									std::string label = g_ASC.PushLabel("endif");
																									std::string finallabel = g_ASC.PushLabel("exitif");
																									SASTNode *callcode = new SASTNode(EN_JumpNZ, label);
																									callcode->m_Opcode = OP_JUMPIFNOT;
																									SASTNode *endlabel = new SASTNode(EN_Label, label);
																									endlabel->m_Opcode = OP_LABEL;
																									SASTNode *exitlabel = new SASTNode(EN_Label, finallabel);
																									exitlabel->m_Opcode = OP_LABEL;
																									SASTNode *jumpnode = new SASTNode(EN_Jump, finallabel);
																									jumpnode->m_Opcode = OP_JUMP;
																									SASTNode *exprnode=g_ASC.PopNode();

																									$$->PushNode(exprnode);
																									$$->PushNode(callcode);
																									$$->PushNode(ifblocknode);
																									$$->PushNode(jumpnode);
																									$$->PushNode(endlabel);
																									$$->PushNode(elseblocknode);
																									$$->PushNode(exitlabel);
																									g_ASC.PushNode($$);
																								}
	;

for_statement
	: FOR '(' expression ';' expression ';' expression ')' compound_statement					{
																									$$ = new SASTNode(EN_For, "");
																									$$->m_LineNumber = yylineno;

																									SASTNode *codeblocknode = g_ASC.PopNode();

																									std::string startlabel = g_ASC.PushLabel("beginfor");
																									std::string label = g_ASC.PushLabel("endfor");
																									SASTNode *callcode = new SASTNode(EN_JumpNZ, label);
																									callcode->m_Opcode = OP_JUMPIFNOT;
																									SASTNode *callcodeend = new SASTNode(EN_Jump, startlabel);
																									callcodeend->m_Opcode = OP_JUMP;
																									SASTNode *beginlabel = new SASTNode(EN_Label, startlabel);
																									beginlabel->m_Opcode = OP_LABEL;
																									SASTNode *endlabel = new SASTNode(EN_Label, label);
																									endlabel->m_Opcode = OP_LABEL;

																									SASTNode *exprnodeC=g_ASC.PopNode();
																									SASTNode *exprnodeB=g_ASC.PopNode();
																									SASTNode *exprnodeA=g_ASC.PopNode();
																									$$->PushNode(exprnodeA);
																									$$->PushNode(beginlabel);
																									$$->PushNode(exprnodeB);
																									$$->PushNode(callcode);
																									$$->PushNode(codeblocknode);
																									$$->PushNode(exprnodeC);
																									$$->PushNode(callcodeend);
																									$$->PushNode(endlabel);
																									//$$->m_Opcode = OP_FOR;
																									g_ASC.PushNode($$);
																								}
;

while_statement
	: WHILE '(' expression ')' compound_statement												{
																									$$ = new SASTNode(EN_While, "");
																									$$->m_LineNumber = yylineno;

																									SASTNode *codeblocknode = g_ASC.PopNode();

																									std::string startlabel = g_ASC.PushLabel("beginwhile");
																									std::string label = g_ASC.PushLabel("endwhile");
																									SASTNode *callcode = new SASTNode(EN_JumpNZ, label);
																									callcode->m_Opcode = OP_JUMPIFNOT;
																									SASTNode *callcodeend = new SASTNode(EN_Jump, startlabel);
																									callcodeend->m_Opcode = OP_JUMP;
																									SASTNode *beginlabel = new SASTNode(EN_Label, startlabel);
																									beginlabel->m_Opcode = OP_LABEL;
																									SASTNode *endlabel = new SASTNode(EN_Label, label);
																									endlabel->m_Opcode = OP_LABEL;

																									SASTNode *exprnode=g_ASC.PopNode();
																									$$->PushNode(beginlabel);
																									$$->PushNode(exprnode);
																									$$->PushNode(callcode);
																									$$->PushNode(codeblocknode);
																									//$$->PushNode(endcodeblocknode);
																									$$->PushNode(callcodeend);
																									$$->PushNode(endlabel);
																									//$$->m_Opcode = OP_WHILE;
																									g_ASC.PushNode($$);
																								}
	| DO compound_statement WHILE '(' expression ')' ';'										{
																									$$ = new SASTNode(EN_Do, "");
																									$$->m_LineNumber = yylineno;

																									SASTNode *exprnode=g_ASC.PopNode();

																									// Create code block node
																									SASTNode *codeblocknode = g_ASC.PopNode();

																									std::string startlabel = g_ASC.PushLabel("begindowhile");
																									std::string label = g_ASC.PushLabel("enddowhile");
																									SASTNode *callcode = new SASTNode(EN_JumpNZ, label);
																									callcode->m_Opcode = OP_JUMPIFNOT;
																									SASTNode *callcodeend = new SASTNode(EN_Jump, startlabel);
																									callcodeend->m_Opcode = OP_JUMP;
																									SASTNode *beginlabel = new SASTNode(EN_Label, startlabel);
																									beginlabel->m_Opcode = OP_LABEL;
																									SASTNode *endlabel = new SASTNode(EN_Label, label);
																									endlabel->m_Opcode = OP_LABEL;

																									$$->PushNode(beginlabel);
																									$$->PushNode(codeblocknode);
																									$$->PushNode(exprnode);
																									$$->PushNode(callcode);
																									$$->PushNode(callcodeend);
																									$$->PushNode(endlabel);
																									//$$->m_Opcode = OP_WHILE;
																									g_ASC.PushNode($$);
																								}
	;

variable_declaration_item
	: simple_identifier 																		{
																									$$ = new SASTNode(EN_DeclInitJunction, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *namenode=g_ASC.PopNode();
																									$$->PushNode(namenode);
																									// Fake initial value of zero since there's no initializer
																									SASTNode *valnode=new SASTNode(EN_Constant, "");
																									valnode->m_Value = "0x0";
																									$$->PushNode(valnode);
																									$$->m_Opcode = OP_STORE;
																									$$->m_AllocationModifier = AM_DYNAMIC;
																									g_ASC.PushNode($$);																								}
	| simple_identifier '=' expression 															{
																									SASTNode *valnode=g_ASC.PopNode();
																									$$ = new SASTNode(EN_DeclInitJunction, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *namenode=g_ASC.PopNode();
																									$$->PushNode(namenode);
																									$$->PushNode(valnode);
																									$$->m_Opcode = OP_STORE;
																									$$->m_AllocationModifier = AM_DYNAMIC;
																									g_ASC.PushNode($$);
																								}
	| simple_identifier '[' expression ']'														{
																									$$ = new SASTNode(EN_DeclArray, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *dimnode=g_ASC.PopNode();
																									SASTNode *namenode=g_ASC.PopNode();
																									$$->PushNode(namenode);
																									$$->PushNode(dimnode);
																									dimnode->m_Opcode = OP_DIM;
																									$$->m_AllocationModifier = AM_DYNAMIC;
																									g_ASC.PushNode($$);
																								}
	| simple_identifier '[' expression ']' '=' code_block_start expression_list code_block_end	{
																									$$ = new SASTNode(EN_DeclInitJunction, "");
																									$$->m_LineNumber = yylineno;

																									// Discard epilogue
																									g_ASC.PopNode();

																									// Create initializer array
																									SASTNode *initarray = new SASTNode(EN_ArrayWithDataJunction, "");
																									// Collect everything up till prologue
																									bool done = false;
																									do
																									{
																										SASTNode *n0 = g_ASC.PeekNode();
																										done = n0->m_Type == EN_Prologue ? true:false;
																										if (done)
																											break;
																										g_ASC.PopNode();
																										// Remove the EN_Expression
																										initarray->m_ASTNodes.emplace(initarray->m_ASTNodes.begin(),n0->m_ASTNodes[0]);
																									} while (1);
																									initarray->m_Opcode = OP_DATAARRAY;

																									// Discard prologue
																									g_ASC.PopNode();

																									SASTNode *dimnode=g_ASC.PopNode();
																									SASTNode *namenode=g_ASC.PopNode();
																									$$->PushNode(namenode);
																									$$->PushNode(dimnode);
																									dimnode->m_Opcode = OP_DIM;
																									$$->PushNode(initarray);
																									$$->m_Opcode = OP_BULKASSIGN;
																									$$->m_AllocationModifier = AM_STATIC;
																									g_ASC.PushNode($$);
																								}
	| simple_identifier '['  ']' '=' code_block_start expression_list code_block_end			{
																									$$ = new SASTNode(EN_DeclInitJunction, "");
																									$$->m_LineNumber = yylineno;

																									// Discard epilogue
																									g_ASC.PopNode();

																									// Create initializer array
																									SASTNode *initarray = new SASTNode(EN_ArrayWithDataJunction, "");
																									// Collect everything up till prologue
																									bool done = false;
																									do
																									{
																										SASTNode *n0 = g_ASC.PeekNode();
																										done = n0->m_Type == EN_Prologue ? true:false;
																										if (done)
																											break;
																										g_ASC.PopNode();
																										initarray->m_ASTNodes.emplace(initarray->m_ASTNodes.begin(),n0->m_ASTNodes[0]);
																									} while (1);
																									initarray->m_Opcode = OP_DATAARRAY;

																									// Discard prologue
																									g_ASC.PopNode();

																									// Set dimension to init array size
																									std::stringstream stream;
																									//stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << initarray->m_ASTNodes.size();
																									stream << std::hex << initarray->m_ASTNodes.size();
																									std::string result( stream.str() );

																									SASTNode *dimnode=new SASTNode(EN_Constant, std::string("0x")+result);
																									dimnode->m_Opcode = OP_LOAD;
																									SASTNode *namenode=g_ASC.PopNode();
																									$$->PushNode(namenode);
																									$$->PushNode(dimnode);
																									dimnode->m_Opcode = OP_DIM;
																									$$->PushNode(initarray);
																									$$->m_Opcode = OP_BULKASSIGN;
																									$$->m_AllocationModifier = AM_STATIC;
																									g_ASC.PushNode($$);
																								}
	;

type_name
	: CONSTRUCT																					{ g_ASC.m_CurrentTypeName = TN_CONSTRUCT; }
	| VOID																						{ g_ASC.m_CurrentTypeName = TN_VOID; }
	| DWORD																						{ g_ASC.m_CurrentTypeName = TN_DWORD; }
	| WORD																						{ g_ASC.m_CurrentTypeName = TN_WORD; }
	| BYTE																						{ g_ASC.m_CurrentTypeName = TN_BYTE; }
	| VOID '*'																					{ g_ASC.m_CurrentTypeName = TN_VOIDPTR; }
	| DWORD '*'																					{ g_ASC.m_CurrentTypeName = TN_DWORDPTR; }
	| WORD '*'																					{ g_ASC.m_CurrentTypeName = TN_WORDPTR; }
	| BYTE '*'																					{ g_ASC.m_CurrentTypeName = TN_BYTEPTR; }
	| IDENTIFIER																				{ g_ASC.m_CurrentTypeName = TN_CONSTRUCT; g_ASC.m_CurrentConstruct = $1; }
	;

variable_declaration
	: type_name variable_declaration_item														{
																									$$ = new SASTNode(EN_Decl, "");
																									$$->m_Opcode = OP_DECL;
																									$$->m_LineNumber = yylineno;
																									SASTNode *declnode=g_ASC.PopNode();
																									$$->PushNode(declnode);

																									// Also store the variable in function list for later retreival
																									SVariable *var = new SVariable();
																									var->m_Name = (declnode->m_Type==EN_DeclInitJunction || declnode->m_Type==EN_DeclArray) ? declnode->m_ASTNodes[0]->m_Value : declnode->m_Value;
																									var->m_Scope = g_ASC.m_CurrentFunctionName;
																									var->m_NameHash = HashString(var->m_Name.c_str());
																									var->m_ScopeHash = HashString(var->m_Scope.c_str());
																									var->m_RootNode = $$;
																									var->m_Dimension = 1;
																									var->m_RefCount = g_ASC.m_IsConstruct ? 1 : 0;
																									var->m_Value = "";
																									var->m_TypeName = g_ASC.m_CurrentTypeName;
																									if (g_ASC.m_CurrentTypeName == TN_CONSTRUCT)
																										var->m_ConstructName = g_ASC.m_CurrentConstruct;

																									if (var->m_Scope.length()>0)
																										var->m_DynamicAllocation = 1;

																									if (declnode->m_ASTNodes.size())
																									{
																										if (declnode->m_Type == EN_DeclArray)
																										{
																											var->m_Dimension = strtoul(declnode->m_ASTNodes[1]->m_Value.c_str(), nullptr, 16);
																											/*for (int i=0;i<var->m_Dimension;++i)
																												var->m_InitialValues.push_back(0xCDCDCDCD);*/
																										}
																										else if (declnode->m_Type == EN_DeclInitJunction)
																										{
																											if (declnode->m_ASTNodes.size()>=3 && declnode->m_ASTNodes[2]->m_Type == EN_ArrayWithDataJunction)
																											{
																												var->m_Dimension = strtoul(declnode->m_ASTNodes[1]->m_Value.c_str(), nullptr, 16);
																												int offset = 0;
																												for (auto &val : declnode->m_ASTNodes[2]->m_ASTNodes)
																												{
																													if (val->m_Type == EN_Constant)
																													{
																														uint32_t V = strtoul(val->m_Value.c_str(), nullptr, 16);
																														var->m_InitialValues.push_back(V);
																													}
																													else
																													{
																														printf("WARNING: expression in initializer(0) : %s, will generate code\n", var->m_Name.c_str());

																														//$$->PopNode();
																														g_ASC.PushNode(val);
																														SASTNode *popnode = new SASTNode(EN_Default, "");
																														popnode->m_Opcode = val->m_Type == EN_String ? OP_PULLINITSTRING : OP_PULLINITEXPRESSION;
																														popnode->m_Value = var->m_Scope + ":" + var->m_Name;
																														popnode->m_Offset = offset*TypeNameToStride[var->m_TypeName];
																														popnode->m_TypeName = var->m_TypeName;
																														g_ASC.PushNode(popnode);

																														var->m_InitialValues.push_back(0);
																													}
																													++offset;
																												}
																											}
																											else
																											{
																												//printf("VAR:%s VAL:%s\n", var->m_Name.c_str(), declnode->m_ASTNodes[1]->m_Value.c_str());
																												if (declnode->m_ASTNodes[1]->m_Type == EN_Constant)
																												{
																													uint32_t V = strtoul(declnode->m_ASTNodes[1]->m_Value.c_str(), nullptr, 16);
																													var->m_InitialValues.push_back(V);
																												}
																												else
																												{
																													printf("WARNING: expression in initializer(1) : %s, will generate code\n", var->m_Name.c_str());

																													//$$->PopNode();
																													g_ASC.PushNode(declnode->m_ASTNodes[1]);
																													SASTNode *popnode = new SASTNode(EN_Default, "");
																													//var->m_Dimension = declnode->m_ASTNodes[1]->m_Type == EN_String ? 2 : 1; // Fake a dimension to prevent pointer-like access
																													popnode->m_Opcode = declnode->m_ASTNodes[1]->m_Type == EN_String ? OP_PULLINITSTRING : OP_PULLINITEXPRESSION;
																													popnode->m_Value = var->m_Scope + ":" + var->m_Name;
																													popnode->m_Offset = 0;
																													popnode->m_TypeName = var->m_TypeName;
																													g_ASC.PushNode(popnode);

																													var->m_InitialValues.push_back(0);
																												}
																											}
																										}
																										else if (declnode->m_Type == EN_ArrayWithDataJunction)
																										{
																											int offset = 0;
																											for (auto &val : declnode->m_ASTNodes)
																											{
																												if (val->m_Type == EN_Constant)
																												{
																													uint32_t V = strtoul(val->m_Value.c_str(), nullptr, 16);
																													var->m_InitialValues.push_back(V);
																												}
																												else
																												{
																													printf("WARNING: expression in initializer(2) : %s, will generate code\n", var->m_Name.c_str());

																													//$$->PopNode();
																													g_ASC.PushNode(val);
																													SASTNode *popnode = new SASTNode(EN_Default, "");
																													//var->m_Dimension = val->m_Type == EN_String ? 2 : 1; // Fake a dimension to prevent pointer-like access
																													popnode->m_Opcode = val->m_Type == EN_String ? OP_PULLINITSTRING : OP_PULLINITEXPRESSION;
																													popnode->m_Value = var->m_Scope + ":" + var->m_Name;
																													popnode->m_Offset = offset*TypeNameToStride[var->m_TypeName];
																													popnode->m_TypeName = var->m_TypeName;
																													g_ASC.PushNode(popnode);

																													var->m_InitialValues.push_back(0);
																												}
																												++offset;
																											}
																										}
																									}
																									/*else
																										var->m_InitialValues.push_back(0xCDCDCDCD);*/

																									if (g_ASC.m_IsConstruct) g_ASC.PushNode($$); // Variable already added to var stack but for constructs we need it here
																									g_ASC.m_Variables.push_back(var);
																								}
	| variable_declaration ',' variable_declaration_item										{
																									$$ = new SASTNode(EN_Decl, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);

																									// Also store the variable in function list for later retreival
																									SVariable *var = new SVariable();
																									var->m_Name = (n0->m_Type==EN_DeclInitJunction || n0->m_Type==EN_DeclArray) ? n0->m_ASTNodes[0]->m_Value : n0->m_Value;
																									var->m_Scope = g_ASC.m_CurrentFunctionName;
																									var->m_NameHash = HashString(var->m_Name.c_str());
																									var->m_ScopeHash = HashString(var->m_Scope.c_str());
																									var->m_RootNode = $$;
																									var->m_Dimension = 1;
																									var->m_RefCount = g_ASC.m_IsConstruct ? 1 : 0;
																									var->m_Value = "";
																									var->m_TypeName = g_ASC.m_CurrentTypeName;
																									if (g_ASC.m_CurrentTypeName == TN_CONSTRUCT)
																										var->m_ConstructName = g_ASC.m_CurrentConstruct;

																									if (var->m_Scope.length()>0)
																										var->m_DynamicAllocation = 1;

																									if (n0->m_ASTNodes.size())
																									{
																										if (n0->m_Type == EN_DeclArray)
																										{
																											var->m_Dimension = strtoul(n0->m_ASTNodes[1]->m_Value.c_str(), nullptr, 16);
																											/*for (int i=0;i<var->m_Dimension;++i)
																												var->m_InitialValues.push_back(0xCDCDCDCD);*/
																										}
																										else if (n0->m_Type == EN_DeclInitJunction)
																										{
																											if (n0->m_ASTNodes.size()>=3 && n0->m_ASTNodes[2]->m_Type == EN_ArrayWithDataJunction)
																											{
																												var->m_Dimension = strtoul(n0->m_ASTNodes[1]->m_Value.c_str(), nullptr, 16);
																												for (auto &val : n0->m_ASTNodes[2]->m_ASTNodes)
																												{
																													uint32_t V = strtoul(val->m_Value.c_str(), nullptr, 16);
																													var->m_InitialValues.push_back(V);
																												}
																											}
																											else
																											{
																												//printf("VAR:%s VAL:%s\n", var->m_Name.c_str(), n0->m_ASTNodes[1]->m_Value.c_str());
																												uint32_t V = strtoul(n0->m_ASTNodes[1]->m_Value.c_str(), nullptr, 16);
																												var->m_InitialValues.push_back(V);
																											}
																										}
																										else if (n0->m_Type == EN_ArrayWithDataJunction)
																										{
																											for (auto &val : n0->m_ASTNodes)
																											{
																												uint32_t V = strtoul(val->m_Value.c_str(), nullptr, 16);
																												var->m_InitialValues.push_back(V);
																											}
																										}
																									}
																									//else
																									//	var->m_InitialValues.push_back(0xCDCDCDCD);

																									$$->m_Opcode = OP_DECL;
																									if (g_ASC.m_IsConstruct) g_ASC.PushNode($$); // Variable already added to var stack but for constructs we need it here
																									g_ASC.m_Variables.push_back(var);
																								}
	;

variable_declaration_statement
	: variable_declaration ';'																	{
																									$$ = new SASTNode(EN_VarDeclStatement, "");
																									$$->m_LineNumber = yylineno;
																									g_ASC.PushNode($$);
																									g_ASC.m_CurrentConstruct = "";
																								}
	;

expression_list
	: expression																				{
																									$$ = new SASTNode(EN_Expression, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);
																									g_ASC.PushNode($$);
																								}
	| expression_list ',' expression															{
																									$$ = new SASTNode(EN_Expression, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);
																									g_ASC.PushNode($$);
																								}
	;

parameter_list
	: '(' ')'																					{
																								}
	| '(' expression_list ')'																	{
																									/*$$ = g_ASC.PopNode();
																									$$->m_Type = EN_StackPush;
																									$$->m_Opcode = OP_PUSH;
																									g_ASC.PushNode($$);*/
																								}
	;

input_param_list
	: type_name simple_identifier																{
																									$$ = new SASTNode(EN_Expression, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);
																									$$->m_InheritedTypeName = g_ASC.m_CurrentTypeName;
																									g_ASC.PushNode($$);
																								}
	| input_param_list ',' type_name simple_identifier											{
																									$$ = new SASTNode(EN_Expression, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *n0=g_ASC.PopNode();
																									$$->PushNode(n0);
																									$$->m_InheritedTypeName = g_ASC.m_CurrentTypeName;
																									g_ASC.PushNode($$);
																								}
	;

function_parameters
	: '(' ')'																					{}
	| '(' input_param_list ')'																	{}
	;

functioncall_statement
	: simple_identifier parameter_list ';'														{
																									$$ = new SASTNode(EN_Call, "");
																									$$->m_LineNumber = yylineno;

																									bool done = false;
																									int paramcount = 0;
																									do
																									{
																										SASTNode *paramnode = g_ASC.PeekNode();
																										done = paramnode->m_Type == EN_Expression ? false:true;
																										if (done)
																											break;
																										g_ASC.PopNode();
																										// Replace EN_Expression with EN_StackPush
																										paramnode->m_Type = EN_StackPush;
																										paramnode->m_Opcode = OP_PUSH;
																										$$->m_ASTNodes.emplace($$->m_ASTNodes.begin(),paramnode);
																										++paramcount;
																									} while (1);

																									SASTNode *namenode = g_ASC.PopNode();
																									uint32_t hash = HashString(namenode->m_Value.c_str());
																									SFunction *func = g_ASC.FindFunction(hash);
																									if (func)
																										func->m_RefCount++;
																									else
																									{
																										printf("ERROR: Function %s not declared before use\n", namenode->m_Value.c_str());
																										g_ASC.m_CompileFailed = true;
																									}

																									//$$->PushNode(namenode); // No need to push name node, this is part of the 'call' opcode (as a target label)
																									$$->m_Opcode = OP_CALL;
																									$$->m_Value = namenode->m_Value;
																									g_ASC.PushNode($$);
																								}
	;

code_block_start
	: BEGINBLOCK																				{
																									$$ = new SASTNode(EN_Prologue, "");
																									$$->m_LineNumber = yylineno;
																									g_ASC.PushNode($$);
																								}
	;

code_block_end
	: ENDBLOCK																					{
																									$$ = new SASTNode(EN_Epilogue, "");
																									$$->m_LineNumber = yylineno;
																									g_ASC.PushNode($$);
																								}
	;

builtin_statement
	: RETURN ';'																				{
																									$$ = new SASTNode(EN_Return, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_RETURN;
																									g_ASC.PushNode($$);
																								}
	| RETURN '(' expression ')' ';'																{
																									$$ = new SASTNode(EN_ReturnVal, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_RETURNVAL;
																									g_ASC.PushNode($$);
																								}
	| BREAK ';'																					{
																									$$ = new SASTNode(EN_Break, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_BREAK;
																									g_ASC.PushNode($$);
																								}
	| FSEL '(' expression ')' ';'																{
																									$$ = new SASTNode(EN_FrameSelect, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_FSEL;
																									g_ASC.PushNode($$);
																								}
	| ASEL '(' expression ',' expression ')' ';'												{
																									$$ = new SASTNode(EN_AudioSelect, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_ASEL;
																									g_ASC.PushNode($$);
																								}
	| CLF '(' expression ')' ';'																{
																									$$ = new SASTNode(EN_ClearFrame, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_CLF;
																									g_ASC.PushNode($$);
																								}
	| SPRITE '(' expression ',' expression ')' ';'												{
																									$$ = new SASTNode(EN_Sprite, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_SPRITE;
																									g_ASC.PushNode($$);
																								}
	| SPRITESHEET '(' expression ')' ';'														{
																									$$ = new SASTNode(EN_SpriteSheet, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_SPRITESHEET;
																									g_ASC.PushNode($$);
																								}
	| SPRITEORIGIN '(' expression ',' expression ')' ';'										{
																									$$ = new SASTNode(EN_SpriteOrigin, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_SPRITEORIGIN;
																									g_ASC.PushNode($$);
																								}
	| IN '(' expression ',' expression ')' ';'													{
																									$$ = new SASTNode(EN_In, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_IN;
																									g_ASC.PushNode($$);
																								}
	| OUT '(' expression ',' expression ')' ';'													{
																									$$ = new SASTNode(EN_Out, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_OUT;
																									g_ASC.PushNode($$);
																								}
	| VSYNC '(' ')' ';'																			{
																									$$ = new SASTNode(EN_Vsync, "");
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_VSYNC;
																									g_ASC.PushNode($$);
																								}
	| GOTO IDENTIFIER ';'																		{
																									$$ = new SASTNode(EN_Jump, $2);
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_JUMP;
																									g_ASC.PushNode($$);
																								}
	;

any_statement
	: functioncall_statement																	{
																								}
	| expression_statement																		{
																								}
	| if_statement																				{
																								}
	| while_statement																			{
																								}
	| for_statement																				{
																								}
	| variable_declaration_statement															{
																								}
	| builtin_statement																			{
																								}
	| LABEL																						{
																									$$ = new SASTNode(EN_Label, $1);
																									$$->m_Value = $$->m_Value.substr(0, $$->m_Value.size()-1); // Remove trailing column
																									$$->m_LineNumber = yylineno;
																									$$->m_Opcode = OP_LABEL;
																									g_ASC.PushNode($$);
																								}
	;

compound_statement
	: any_statement																				{
																									$$ = new SASTNode(EN_CompoundStatement, "");
																									$$->m_LineNumber = yylineno;
																									SASTNode *singlestatement = g_ASC.PopNode();
																									$$->PushNode(singlestatement);
																									g_ASC.PushNode($$);
																								}
	| code_block_start code_block_end															{	// Empty compound statement
																									$$ = new SASTNode(EN_CompoundStatement, "");
																									$$->m_LineNumber = yylineno;
																									// Remove epilogue
																									g_ASC.PopNode();
																									// Remove prologue
																									g_ASC.PopNode();
																									g_ASC.PushNode($$);
																								}
	| code_block_start block_item_list code_block_end											{
																									$$ = new SASTNode(EN_CompoundStatement, "");
																									$$->m_LineNumber = yylineno;

																									// Remove epilogue
																									g_ASC.PopNode();

																									// Create code block node
																									SASTNode *codeblocknode = new SASTNode(EN_CodeBlock, "");

																									// Collect everything up till prologue
																									bool done = false;
																									do
																									{
																										SASTNode *n0 = g_ASC.PeekNode();
																										done = n0->m_Type == EN_Prologue ? true:false;
																										if (done)
																											break;
																										g_ASC.PopNode();
																										codeblocknode->m_ASTNodes.emplace(codeblocknode->m_ASTNodes.begin(), n0);
																									} while (1);

																									// Remove prologue
																									g_ASC.PopNode();

																									$$->m_ASTNodes.push_back(codeblocknode);
																									g_ASC.PushNode($$);
																								}
	;

block_item_list
	: any_statement
	| block_item_list any_statement
	;

typed_identifier
	: type_name simple_identifier																{
																									SASTNode *namenode = g_ASC.PopNode();
																									$$ = new SASTNode(EN_TypedIdentifier, "");
																									$$->m_LineNumber = yylineno;
																									$$->PushNode(namenode);
																									g_ASC.m_CurrentFunctionName = namenode->m_Value;
																									g_ASC.m_CurrentFunctionTypeName = g_ASC.m_CurrentTypeName;
																									g_ASC.m_IsConstruct = g_ASC.m_CurrentTypeName == TN_CONSTRUCT ? true : false;
																									g_ASC.PushNode($$);
																								}
	;

construct_def
	: typed_identifier compound_statement ';'													{
																									SASTNode *declnode = new SASTNode(EN_ConstructDecl, "");
																									declnode->m_LineNumber = yylineno;

																									// Remove compound statemebt
																									SASTNode *codeblocknode = g_ASC.PopNode();

																									// Remove header (contains name as subnode)
																									g_ASC.PopNode();

																									SASTNode *labelnode = new SASTNode(EN_Label, g_ASC.m_CurrentFunctionName);
																									labelnode->m_Opcode = OP_LABEL;
																									declnode->PushNode(labelnode);

																									// Add the code block after name
																									declnode->PushNode(codeblocknode);
																									//declnode->PushNode(endcodeblocknode);

																									declnode->m_Opcode = OP_RESETREGISTERS;
																									//g_ASC.PushNode($$);

																									// Store construct in list for easy search
																									SConstruct *construct = new SConstruct();
																									construct->m_Name = g_ASC.m_CurrentFunctionName;
																									construct->m_Hash = HashString(construct->m_Name.c_str());
																									construct->m_RootNode = declnode;
																									g_ASC.m_Constructs.push_back(construct);
																									g_ASC.m_CurrentFunctionName = "";
																									g_ASC.m_IsConstruct = false;
																								}
	;

function_def
	: typed_identifier function_parameters compound_statement									{
																									SASTNode *declnode = new SASTNode(EN_FuncDecl, "");
																									declnode->m_LineNumber = yylineno;

																									// Remove code block
																									SASTNode *codeblocknode = g_ASC.PopNode();

																									// Collect call parameter nodes
																									bool done = false;
																									SASTNode *tmp = new SASTNode(EN_Default, "");
																									do
																									{
																										SASTNode *n0 = g_ASC.PeekNode();
																										done = n0->m_Type == EN_Expression ? false:true;
																										if (done)
																											break;

																										n0->m_Type = EN_StackPop;
																										n0->m_Opcode = OP_POP;
																										g_ASC.PopNode();
																										n0->m_Value = n0->m_ASTNodes[0]->m_Value; // Copy value
																										n0->m_ASTNodes.clear(); // Remove identifier
																										// Add the input parameter to code block
																										tmp->PushNode(n0);

																										// Create function-local variable
																										SVariable *var = new SVariable();
																										var->m_Name = n0->m_Value;
																										var->m_Scope = g_ASC.m_CurrentFunctionName;
																										var->m_NameHash = HashString(var->m_Name.c_str());
																										var->m_ScopeHash = HashString(var->m_Scope.c_str());
																										var->m_RootNode = n0;
																										var->m_Dimension = 1;
																										var->m_RefCount = 0;
																										var->m_Value = "";
																										var->m_TypeName = n0->m_InheritedTypeName;
																										g_ASC.m_Variables.push_back(var);

																									} while (1);

																									// Remove function header (contains name as subnode)
																									g_ASC.PopNode();

																									/*SASTNode *commentnode = new SASTNode(EN_Default, g_ASC.m_CurrentFunctionName);
																									commentnode->m_Opcode = OP_PASSTHROUGH;
																									commentnode->m_Value = "\n# Start of function " + g_ASC.m_CurrentFunctionName;
																									g_ASC.PushNode(commentnode);*/

																									SASTNode *labelnode = new SASTNode(EN_Label, g_ASC.m_CurrentFunctionName);
																									labelnode->m_Opcode = OP_LABEL;
																									declnode->PushNode(labelnode);

																									// Copy the parameter pop instructions
																									for (auto &P : tmp->m_ASTNodes)
																										declnode->PushNode(P);
																									delete tmp;

																									// Add the code block after name
																									declnode->PushNode(codeblocknode);
																									//declnode->PushNode(endcodeblocknode);

																									declnode->m_Opcode = OP_RESETREGISTERS;
																									//g_ASC.PushNode($$);

																									// Also store the function in function list for later retreival
																									SFunction *func = new SFunction();
																									func->m_Name = g_ASC.m_CurrentFunctionName;
																									func->m_ReturnType = g_ASC.m_CurrentFunctionTypeName;
																									func->m_Hash = HashString(func->m_Name.c_str());
																									func->m_RootNode = declnode;
																									g_ASC.m_Functions.push_back(func);
																									g_ASC.m_CurrentFunctionName = "";
																									g_ASC.m_IsConstruct = false;
																								}
	;

translation_unit
	: variable_declaration_statement
	| construct_def
	| function_def
	| translation_unit variable_declaration_statement
	| translation_unit construct_def
	| translation_unit function_def
	;

program
	: translation_unit																			{
																								}
	;
%%

void AssignScopeNode(FILE *_fp, int scopeDepth, SASTNode *node)
{
	node->m_ScopeDepth = scopeDepth;

	for (auto &subnode : node->m_ASTNodes)
		AssignScopeNode(_fp, scopeDepth+1, subnode);
}

void DumpConstruct(FILE *_fp, SConstruct *construct, SASTNode *node)
{
	//fprintf(_fp, "# depth:%d type: %s\n", node->m_ScopeDepth, NodeTypes[node->m_Type]);
	if (node->m_Type == EN_DeclInitJunction)
	{
		construct->PushVariable(construct->m_Name + ":" + node->m_ASTNodes[0]->m_Value);
		//fprintf(_fp, "# construct var: %s:%s\n", construct->m_Name.c_str(), node->m_ASTNodes[0]->m_Value.c_str());
		fprintf(_fp, "@LABEL %s:%s\n", construct->m_Name.c_str(), node->m_ASTNodes[0]->m_Value.c_str());
		fprintf(_fp, "@DW %s\n", node->m_ASTNodes[1]->m_Value.c_str());
	}
	else
	{
		for (auto &subnode : node->m_ASTNodes)
			DumpConstruct(_fp, construct, subnode);
	}
}

void DumpNodes(FILE *_fp, SASTNode *node)
{
	for (auto &subnode : node->m_ASTNodes)
		DumpNodes(_fp, subnode);

	if (node->m_Value.length()>0)
		fprintf(_fp, "# %s\n", node->m_Value.c_str());
}

void DumpCode(FILE *_fp, SASTNode *node, bool _forX64)
{
	for (auto &subnode : node->m_ASTNodes)
		DumpCode(_fp, subnode, _forX64);
	
	if (node->m_Opcode != OP_PASSTHROUGH)
	{
		if (node->m_LineNumber!=0xFFFFFFFF && node->m_LineNumber!=s_prevLineNo)
		{
			//if (!_forX64)
				//fprintf(_fp, "# code_line_%d\n", node->m_LineNumber);
			s_prevLineNo = node->m_LineNumber;
		}
		fprintf(_fp, "%s\n", node->m_Instructions.c_str());
	}
	else
	{
		if (node->m_Value.length()>0)
			fprintf(_fp, "%s\n", node->m_Value.c_str());
	}
}

void AssignRegistersAndGenerateCode(FILE *_fp, SASTNode *node)
{
	if (g_ASC.m_CompileFailed)
		return;

	// Set current scope name
	if (node->m_Type == EN_FuncDecl)
		g_ASC.m_CurrentFunctionName = node->m_ASTNodes[0]->m_Value;

	if (node->m_Type == EN_Identifier)
	{
		uint32_t namehash = HashString(node->m_Value.c_str());
		uint32_t scopehash = HashString(g_ASC.m_CurrentFunctionName.c_str());
		uint32_t emptyhash = HashString("");
		SVariable *var = g_ASC.FindVariable(namehash, scopehash);
		if (!var)
			var = g_ASC.FindVariable(namehash, emptyhash);
		if (var)
		{
			var->m_RefCount++;
			g_ASC.m_CurrentTypeName = var->m_TypeName;
		}
		if (!var)
		{
			SFunction *func = g_ASC.FindFunction(namehash);
			if (!func)
			{
				//if (prevnode->m_Type == EN_Struct)
				printf("ERROR: Variable or function %s not declared before use (1)\n", node->m_Value.c_str());
				g_ASC.m_CompileFailed = true;
			}
			else
			{
				func->m_RefCount++;
				g_ASC.m_CurrentTypeName = TN_DWORD;
			}
		}
	}

	for (auto &subnode : node->m_ASTNodes)
		AssignRegistersAndGenerateCode(_fp, subnode);

	switch(node->m_Opcode)
	{
		case OP_DIRECTTOREGISTER:
		{
			std::string src = g_ASC.PushRegister();
			//std::string src = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + src;
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_POP:
		{
			uint32_t namehash = HashString(node->m_Value.c_str());
			uint32_t scopehash = HashString(g_ASC.m_CurrentFunctionName.c_str());
			uint32_t emptyhash = HashString("");
			SVariable *var = g_ASC.FindVariable(namehash, scopehash);
			if (!var)
				var = g_ASC.FindVariable(namehash, emptyhash);

			if (var)
			{
				//var->m_RefCount++;
				std::string val = g_ASC.PushRegister();
				std::string trg = g_ASC.PushRegister();
				node->m_Instructions = GetOpcode(OP_LEA) + " " + val + ", " + var->m_Scope + ":" + var->m_Name;
				node->m_Instructions += std::string("\n") + GetOpcode(node->m_Opcode) + " " + trg;
				node->m_Instructions += std::string("\n") + GetOpcode(OP_STORE) + TypeNameToInstructionSize[var->m_TypeName] + " [" + val + "], " + trg;
				g_ASC.PopRegister(); // Forget trg and val
				g_ASC.PopRegister();
				g_ASC.m_InstructionCount+=3;
			}
			else
			{
				printf("ERROR: Variable %s not declared before use (2)\n", node->m_Value.c_str());
				g_ASC.m_CompileFailed = true;
			}
		}
		break;

		case OP_PUSH:
		{
			std::string src = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + src;
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_JUMP:
		{
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + node->m_Value;
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_JUMPIF:
		case OP_JUMPIFNOT:
		{
			std::string src = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + node->m_Value + ", " + src;
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_CMPL:
		case OP_CMPG:
		case OP_CMPLE:
		case OP_CMPGE:
		case OP_CMPE:
		case OP_CMPNE:
		{
			std::string srcB = g_ASC.PopRegister();
			std::string srcA = g_ASC.PopRegister();
			std::string trg = g_ASC.PushRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + srcA + ", " + srcB;
			std::string test = "notequal";
			// Hardware has: ZERO:NOTEQUAL:NOTZERO:LESS:GREATER:EQUAL
			//if (node->m_Opcode == OP_CMPZ) test = "zero";
			if (node->m_Opcode == OP_CMPNE) test = "notequal";
			//if (node->m_Opcode == OP_CMPNZ) test = "notzero";
			if (node->m_Opcode == OP_CMPL) test = "less";
			if (node->m_Opcode == OP_CMPG) test = "greater";
			if (node->m_Opcode == OP_CMPE) test = "equal";
			if (node->m_Opcode == OP_CMPLE) test = "lessequal";
			if (node->m_Opcode == OP_CMPGE) test = "greaterequal";

			node->m_Instructions += std::string("\n") + GetOpcode(OP_TEST) + " " + trg + ", " + test;
			g_ASC.m_InstructionCount+=2;
		}
		break;

		case OP_ABS:
		{
			std::string srcA = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + srcA + ", " + srcA;
			g_ASC.PushRegister(); // Result goes back into srcA
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_MUL:
		case OP_DIV:
		case OP_MOD:
		case OP_ADD:
		case OP_BSL:
		case OP_BSR:
		{
			std::string srcB = g_ASC.PopRegister();
			std::string srcA = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + srcA + ", " + srcB;
			g_ASC.PushRegister(); // Result goes back into srcA
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_BITAND:
		case OP_BITXOR:
		case OP_BITOR:
		{
			std::string srcB = g_ASC.PopRegister();
			std::string srcA = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + srcA + ", " + srcB;
			g_ASC.PushRegister(); // Result goes back into srcA
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_ARRAYINDEX:
		{
			std::string tgt = g_ASC.PushRegister();

			uint32_t namehash = HashString(node->m_Value.c_str());
			uint32_t scopehash = HashString(g_ASC.m_CurrentFunctionName.c_str());
			uint32_t emptyhash = HashString("");
			SVariable *var = g_ASC.FindVariable(namehash, scopehash);
			if (!var)
				var = g_ASC.FindVariable(namehash, emptyhash);

			if (var)
			{
				//var->m_RefCount++;
				//printf("arrayindex identifier type: %s[%d]\n", NodeTypes[node->m_Type], var->m_Dimension);
				node->m_Instructions = GetOpcode(OP_LEA) + " " + tgt + ", " + var->m_Scope + ":" + var->m_Name;
				g_ASC.m_InstructionCount+=1;
				// This is not a 'real' array, fetch data at address to treat as array base address (Except for strings)
				if (var->m_Dimension <= 1)
				{
					node->m_Instructions += std::string("\n") + GetOpcode(OP_LOAD) + TypeNameToInstructionSize[var->m_TypeName] + " " + tgt + ", [" + tgt + "]";
					g_ASC.m_InstructionCount+=1;
				}
			}
			else
			{
				printf("ERROR: Variable %s not declared before use (3)\n", node->m_Value.c_str());
				g_ASC.m_CompileFailed = true;
			}

			// Temporary register in case we need to use the BSL code path
			std::string trg = "";
			if (var->m_TypeName != TN_BYTE && var->m_TypeName != TN_BYTEPTR)
			{
				trg = g_ASC.PushRegister();
				g_ASC.PopRegister(); // No need after this step
			}

			std::string srcB = g_ASC.PopRegister();
			std::string srcA = g_ASC.PopRegister();

			if (var->m_TypeName != TN_BYTE && var->m_TypeName != TN_BYTEPTR)
			{
				// Need to multiply address by two for WORD or four for DWORD
				if (var->m_TypeName == TN_WORD || var->m_TypeName == TN_WORDPTR)
					node->m_Instructions += std::string("\n") + GetOpcode(OP_LOAD) + ".w " + trg + ", 0x1";
				else
					node->m_Instructions += std::string("\n") + GetOpcode(OP_LOAD) + ".w " + trg + ", 0x2";
				node->m_Instructions += std::string("\n") + GetOpcode(OP_BSL) + " " + srcA + ", " + trg;
				g_ASC.m_InstructionCount+=1;
			}

			node->m_Instructions += std::string("\n") + GetOpcode(OP_ADD) + " " + srcA + ", " + srcB;
			g_ASC.m_InstructionCount+=1;
			g_ASC.PushRegister(); // re-use srcA as target

			// Need to make sure [] on LHS doesn't run this code path but only RHS does
			if (node->m_Side == RIGHT_HAND_SIDE)
			{
				node->m_Instructions += std::string("\n") + GetOpcode(OP_LOAD) + TypeNameToInstructionSizeNotPointer[var->m_TypeName] + " " + srcA + ", [" + srcA + "] # RHS array access, valueof: " + TypeNameToInstructionSizeNotPointer[var->m_TypeName];
				g_ASC.m_InstructionCount+=1;
			}
		}
		break;

		case OP_ADDRESSOF:
		{
			std::string trg = g_ASC.PushRegister();

			uint32_t namehash = HashString(node->m_Value.c_str());
			uint32_t scopehash = HashString(g_ASC.m_CurrentFunctionName.c_str());
			uint32_t emptyhash = HashString("");
			SVariable *var = g_ASC.FindVariable(namehash, scopehash);
			if (!var)
				var = g_ASC.FindVariable(namehash, emptyhash);
			if (!var)
			{
				SFunction *func = g_ASC.FindFunction(namehash);
				if (!func)
				{
					printf("ERROR: Variable or function %s not declared before use (4)\n", node->m_Value.c_str());
					g_ASC.m_CompileFailed = true;
				}
				else
				{
					func->m_RefCount++;
					node->m_Instructions = GetOpcode(node->m_Opcode) + " " + trg + ", " + func->m_Name;
					g_ASC.m_InstructionCount+=1;
				}
			}
			else
			{
				node->m_Instructions = GetOpcode(node->m_Opcode) + " " + trg + ", " + var->m_Scope + ":" + var->m_Name;
				var->m_RefCount++;
				g_ASC.m_InstructionCount+=1;
			}
		}
		break;

		case OP_DEFSTRING:
		{
			// Load the address of the string we just generated
			std::string trg = g_ASC.PushRegister();
			node->m_Instructions = GetOpcode(OP_LEA) + " " + trg + ", " + node->m_String->m_StringTempName;
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_LEA:
		{
			std::string trg = g_ASC.PushRegister();

			uint32_t namehash = HashString(node->m_Value.c_str());
			uint32_t scopehash = HashString(g_ASC.m_CurrentFunctionName.c_str());
			uint32_t emptyhash = HashString("");
			SVariable *var = g_ASC.FindVariable(namehash, scopehash);
			if (!var)
				var = g_ASC.FindVariable(namehash, emptyhash);

			//if (var)
			//	var->m_RefCount++;

			if (node->m_Side == RIGHT_HAND_SIDE)
			{
				if (var)
				{
					node->m_Instructions = GetOpcode(OP_LEA) + " " + trg + ", " + var->m_Scope + ":" + var->m_Name;
					node->m_Instructions += std::string("\n") + GetOpcode(OP_LOAD) + TypeNameToInstructionSize[var->m_TypeName] + " " + trg + ", [" + trg + "]";
					g_ASC.m_InstructionCount+=2;
				}
				else
				{
					printf("ERROR: Cannot find symbol %s\n", node->m_Value.c_str());
					g_ASC.m_CompileFailed = true;
				}
			}
			else
			{
				if (var)
				{
					node->m_Instructions = GetOpcode(node->m_Opcode) + " " + trg + ", " + var->m_Scope + ":" + var->m_Name;
					g_ASC.m_InstructionCount+=1;
					//node->m_Instructions += std::string("\n") + GetOpcode(OP_LOAD) + TypeNameToInstructionSize[var->m_TypeName] + " " + trg + ", [" + trg + "]";
				}
				else
				{
					node->m_Instructions = GetOpcode(node->m_Opcode) + " " + trg + ", " + node->m_Value;
					g_ASC.m_InstructionCount+=1;
				}
			}
		}
		break;

		case OP_FSEL:
		case OP_CLF:
		case OP_SPRITESHEET:
		{
			std::string srcA = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + srcA;
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_ASEL:
		case OP_SPRITE:
		case OP_SPRITEORIGIN:
		case OP_IN:
		case OP_OUT:
		{
			std::string srcB = g_ASC.PopRegister();
			std::string srcA = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + srcA + ", " + srcB;
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_NOT:
		{
			std::string srcA = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + srcA + ", " + srcA;
			g_ASC.m_InstructionCount+=1;
			g_ASC.PushRegister(); // Keep output in same register
		}
		break;

		case OP_RETURNVAL:
		{
			// Result of return expression in register

			uint32_t hash = HashString(g_ASC.m_CurrentFunctionName.c_str());
			SFunction *func = g_ASC.FindFunction(hash);
			//printf("return value in function %s, should be of type %s\n", func->m_Name.c_str(), TypeNames[func->m_ReturnType]);
			if (func->m_ReturnType == TN_VOID)
			{
				printf("ERROR: Function %s has a return type of void but trying to return a value\n", func->m_Name.c_str());
				g_ASC.m_CompileFailed = true;
			}
			std::string srcA = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(OP_PUSH) + " " + srcA;
			node->m_Instructions += std::string("\n") + GetOpcode(node->m_Opcode);
			g_ASC.m_InstructionCount+=2;
			g_ASC.PushRegister(); // Keep output in same register
		}
		break;

		case OP_NEG:
		{
			std::string srcA = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + srcA;
			g_ASC.m_InstructionCount+=1;
			g_ASC.PushRegister(); // Keep output in same register
		}
		break;

		case OP_INC:
		case OP_DEC:
		{
			std::string srcA = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + srcA;
			g_ASC.m_InstructionCount+=1;

			// Assign back to self if this is a variable

			uint32_t namehash = HashString(node->m_ASTNodes[0]->m_Value.c_str());
			uint32_t scopehash = HashString(g_ASC.m_CurrentFunctionName.c_str());
			uint32_t emptyhash = HashString("");
			SVariable *var = g_ASC.FindVariable(namehash, scopehash);
			if (!var)
				var = g_ASC.FindVariable(namehash, emptyhash);
			if (var)
			{
				g_ASC.PushRegister(); // Have to skip over the one we already read as srcA
				std::string trg = g_ASC.PushRegister();
				node->m_Instructions += std::string("\n") + GetOpcode(OP_LEA) + " " + trg + ", " + var->m_Scope + ":" + var->m_Name;
				node->m_Instructions += std::string("\n") + GetOpcode(OP_STORE) + TypeNameToInstructionSize[var->m_TypeName]+" [" + trg + "], " + srcA;
				g_ASC.PopRegister(); // Discard trg
				g_ASC.PopRegister(); // Discard second copy of srcA
				g_ASC.m_InstructionCount+=2;
				//var->m_RefCount++; ?? Does the self-assignment count as another ref?
			}
			else
			{
				printf("WARNING: Inc/Dec prefix on non-variable, ignoring self assignment. Incremented value is transient.\n");
			}

			g_ASC.PushRegister(); // Keep output in same register
		}
		break;

		case OP_LOAD:
		{
			std::string trg = g_ASC.PushRegister();
			int value = strtol(node->m_Value.c_str(), nullptr, 16);
			if (value <=65535 && value >=-65535)
				node->m_Instructions = GetOpcode(node->m_Opcode) + ".w" + " " + trg + ", " + node->m_Value;
			else
				node->m_Instructions = GetOpcode(node->m_Opcode) + ".d" + " " + trg + ", " + node->m_Value;
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_COPY:
		{
			// NOTE: target and source are swapped due to evaluation order
			std::string trg = g_ASC.PopRegister(); // We have no further use of the target register
			std::string srcA = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + TypeNameToInstructionSizeNotPointer[g_ASC.m_CurrentTypeName] + " [" + trg + "], " + srcA;
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_STORE:
		{
			// NOTE: target and source are swapped due to evaluation order
			std::string trg = g_ASC.PopRegister(); // We have no further use of the target register
			std::string srcA = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(node->m_Opcode) + TypeNameToInstructionSizeNotPointer[g_ASC.m_CurrentTypeName] + " [" + trg + "], " + srcA;
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_PULLINITSTRING:
		{
			std::string trg = g_ASC.PushRegister();
			g_ASC.PopRegister();
			std::string src = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(OP_LEA) + " " + trg + ", " + node->m_Value;
			if (node->m_Offset != 0)
			{
				std::stringstream stream;
				stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << node->m_Offset;
				node->m_Instructions += std::string("\n") + "ld.d r15, 0x" + stream.str();
				node->m_Instructions += std::string("\n") + "iadd " + trg + ", r15";
				g_ASC.m_InstructionCount+=2;
			}
			node->m_Instructions += std::string("\n") + GetOpcode(node->m_Opcode) + TypeNameToInstructionSize[node->m_TypeName] + " [" + trg + "], " + src;
			g_ASC.m_InstructionCount+=2;
		}
		break;

		case OP_PULLINITEXPRESSION:
		{
			std::string trg = g_ASC.PushRegister();
			g_ASC.PopRegister();
			std::string src = g_ASC.PopRegister();
			node->m_Instructions = GetOpcode(OP_LEA) + " " + trg + ", " + node->m_Value;
			if (node->m_Offset != 0)
			{
				std::stringstream stream;
				stream << std::setfill ('0') << std::setw(sizeof(uint32_t)*2) << std::hex << node->m_Offset;
				node->m_Instructions += std::string("\n") + "ld.d r15, 0x" + stream.str();
				node->m_Instructions += std::string("\n") + "iadd " + trg + ", r15";
				g_ASC.m_InstructionCount+=2;
			}
			node->m_Instructions += std::string("\n") + GetOpcode(node->m_Opcode) + TypeNameToInstructionSize[node->m_TypeName] + " [" + trg + "], " + src;
			g_ASC.m_InstructionCount+=2;
		}
		break;

		case OP_CALL:
		{
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + node->m_Value;
			g_ASC.m_InstructionCount+=1;
		}
		break;

		case OP_RESETREGISTERS:
		{
			g_ASC.m_CurrentRegister = 0;
			node->m_Instructions = "# end_" + g_ASC.m_CurrentFunctionName + "\n";
		}
		break;

		default:
			node->m_Instructions = GetOpcode(node->m_Opcode) + " " + node->m_Value;
			if (node->m_Opcode != OP_LABEL)
				g_ASC.m_InstructionCount+=1;
		break;
	}

	/*fprintf(_fp, "# %s: %s (%s) %s\n",
		node->m_Side==NO_SIDE?"N":(node->m_Side==LEFT_HAND_SIDE?"L":"R"),
		NodeTypes[node->m_Type],
		node->m_Value.c_str(),
		node->m_Instructions.c_str());*/
}

bool GenerateASM(const char *_filename, bool _forX64)
{
	FILE *fp = fopen(_filename, "w");

	g_ASC.m_X64Mode = _forX64;

	// Set up scope depth
	int scopeDepth = 0;
	for (auto &node : g_ASC.m_ASTNodes)
		AssignScopeNode(fp, scopeDepth, node);

	// Increment ref count of 'main' (entry point) if there's one
	uint32_t mainhash = HashString("main");
	SFunction *mainfunc = g_ASC.FindFunction(mainhash);
	if (mainfunc)
		mainfunc->m_RefCount++;
	else
		printf("WARNING: No entry point (main) found in input file.\n");


	// Dump free-standing code
	for (auto &node : g_ASC.m_ASTNodes)
		AssignRegistersAndGenerateCode(fp, node);

	// Dump functions
	for (uint32_t i=0;i<g_ASC.m_Functions.size();++i)
	{
		//if (g_ASC.m_Functions[i]->m_RefCount != 0)m
		{
			AssignRegistersAndGenerateCode(fp, g_ASC.m_Functions[i]->m_RootNode);
		}
	}

	fprintf(fp, "# ASM file for Neko CPU.\n# Generated by CatNip compiler\n# (c)2020 Engin Cilasun\n");
	fprintf(fp, "# Instruction count: %d\n", g_ASC.m_InstructionCount);

	fprintf(fp, "\n# --------------------------------------\n");
	fprintf(fp, "#                Bootstrap              \n");
	fprintf(fp, "# --------------------------------------\n\n");

	// Add boot code
	if (_forX64)
	{
		fprintf(fp, "option casemap:none\n");
		fprintf(fp, "includelib libucrt.lib\n");
		fprintf(fp, "includelib libvcruntime.lib\n");
		fprintf(fp, "includelib libcmt.lib\n");
		fprintf(fp, "includelib kernel32.lib\n");
	}
	else
	{
		fprintf(fp, "@ORG 0x00000000\n");
		fprintf(fp, "@CODE\n\n");
		fprintf(fp, "call _builtin_global_init\n");
		fprintf(fp, "call main\n");
		fprintf(fp, "ld.w r0, 0x0\n");
		fprintf(fp, "@LABEL infloop\n");
		//fprintf(fp, "vsync\n");
		fprintf(fp, "fsel r0\n");
		fprintf(fp, "inc r0\n");
		fprintf(fp, "jmp infloop\n");
		fprintf(fp, "# End boot\n");
	}

	if (!_forX64)
	{
		fprintf(fp, "\n# --------------------------------------\n");
		fprintf(fp, "#               Global Init               \n");
		fprintf(fp, "# --------------------------------------\n\n");
	}
	if (_forX64)
		fprintf(fp, "\n_builtin_global_init:\n");
	else
		fprintf(fp, "@LABEL _builtin_global_init\n");

	// Dump free-standing code
	s_prevLineNo = 0xCCCCCCCC;
	for (auto &node : g_ASC.m_ASTNodes)
		DumpCode(fp, node, _forX64);
	
	if (_forX64)
		fprintf(fp, "%s\n", GetOpcode(OP_RETURN).c_str());
	else
		fprintf(fp, "%s\n", GetOpcode(OP_RETURN).c_str());

	if (!_forX64)
	{
		fprintf(fp, "\n# --------------------------------------\n");
		fprintf(fp, "#               Functions               \n");
		fprintf(fp, "# --------------------------------------\n\n");
	}

	if (_forX64)
		fprintf(fp, "\n.code\n\n");

	// Dump functions
	for (uint32_t i=0;i<g_ASC.m_Functions.size();++i)
	{
		if (g_ASC.m_Functions[i]->m_RefCount != 0)
		{
			DumpCode(fp, g_ASC.m_Functions[i]->m_RootNode, _forX64);
		}
	}

	// TODO: FUTURE: Keep function even if not used when the function is marked as 'export'
	for (uint32_t i=0;i<g_ASC.m_Functions.size();++i)
		if (g_ASC.m_Functions[i]->m_RefCount == 0)
			printf("WARNING: Function '%s %s' not referenced in code, removing code.\n", TypeNames[g_ASC.m_Functions[i]->m_ReturnType], g_ASC.m_Functions[i]->m_Name.c_str());

	if (_forX64)
		fprintf(fp, ".data\n\n");
	else
		fprintf(fp, "@DATA\n\n");

	if (!_forX64)
	{
		fprintf(fp, "# --------------------------------------\n");
		fprintf(fp, "#               Constructs              \n");
		fprintf(fp, "# --------------------------------------\n\n");
	}

	for (uint32_t i=0;i<g_ASC.m_Constructs.size();++i)
	{
		//fprintf(fp, "# Construct: %s\n", g_ASC.m_Constructs[i]->m_Name.c_str());
		fprintf(fp, "@LABEL %s\n", g_ASC.m_Constructs[i]->m_Name.c_str());
		DumpConstruct(fp, g_ASC.m_Constructs[i], g_ASC.m_Constructs[i]->m_RootNode);
	}

	if (!_forX64)
	{
		fprintf(fp, "\n# --------------------------------------\n");
		fprintf(fp, "#               String Table             \n");
		fprintf(fp, "# --------------------------------------\n\n");
	}

	auto beg = g_ASC.m_StringTable.begin();
	auto end = g_ASC.m_StringTable.end();
	while(beg!=end)
	{
		fprintf(fp, "@LABEL %s\n", beg->second->m_StringTempName.c_str());
		fprintf(fp, "# '%s'\n", beg->second->m_String.c_str());
		fprintf(fp, "@DW ");
		for (uint32_t i=0;i<beg->second->m_String.length()/2;++i)
		{
			uint32_t A = (i*2+0==beg->second->m_EndMarker) ? 0 : beg->second->m_String[i*2+0];
			uint32_t B = (i*2+1==beg->second->m_EndMarker) ? 0 : beg->second->m_String[i*2+1];
			uint32_t AB = (A<<8) | (B);
			fprintf(fp, "0x%.4X ", AB);
		}
		fprintf(fp, "\n");
		++beg;
	}

	/* uint32_t interruptservice = HashString("vblank");
	if (interruptservice)
		printf("Found a vblank interrupt service\n"); */

	// Dump symbol table
	if (!_forX64)
	{
		fprintf(fp, "\n# --------------------------------------\n");
		fprintf(fp, "#              Symbol Table             \n");
		fprintf(fp, "# --------------------------------------\n\n");
	}

	for (auto &var : g_ASC.m_Variables)
	{
		fprintf(fp, "# variable '%s', dim:%d typename:%s refcount:%d\n", var->m_Name.c_str(), var->m_Dimension, TypeNames[var->m_TypeName], var->m_RefCount);
		if (var->m_RefCount == 0)
		{
			printf("WARNING: Variable '%s %s' not referenced in code, removing initializer and allocated space.\n", TypeNames[var->m_TypeName], var->m_Name.c_str());
			continue;
		}
		if (_forX64)
			fprintf(fp, "%s:%s:\n", var->m_Scope.c_str(), var->m_Name.c_str());
		else
			fprintf(fp, "@LABEL %s:%s\n", var->m_Scope.c_str(), var->m_Name.c_str());
		{
			if (var->m_TypeName == TN_CONSTRUCT)
			{
				uint32_t chash = HashString(var->m_ConstructName.c_str());
				SConstruct *construct = g_ASC.FindConstruct(chash);
				if (construct)
				{
					//for (uint32_t c=0;c<var->m_Dimension;++c)
					{
						DumpNodes(fp, construct->m_RootNode);
					}
				}
			}
			if (var->m_TypeName == TN_WORD)
			{
				fprintf(fp, "@DW ");
				int i=0;
				for (auto &data : var->m_InitialValues)
				{
					if (i%8 == 0 && i!=0)
						fprintf(fp, "\n@DW ");
					fprintf(fp, "0x%.4X ", data);
					++i;
				}
				if (var->m_InitialValues.size()==0)
				{
					for (int i=0;i<var->m_Dimension;++i)
						fprintf(fp, "0xCDCD ");
				}
				fprintf(fp, "\n");
			}
			if (var->m_TypeName == TN_BYTE)
			{
				fprintf(fp, "@DW ");
				if (var->m_InitialValues.size()%2 == 1)
					var->m_InitialValues.push_back(0x0);
				auto beg = var->m_InitialValues.begin();
				auto end = var->m_InitialValues.end();
				int i=0;
				while(beg!=end)
				{
					if (i%8 == 0 && i!=0)
						fprintf(fp, "\n@DW ");
					fprintf(fp, "0x%.2X%.2X ", *beg, *(beg+1));
					beg+=2;
					++i;
				}
				if (var->m_InitialValues.size()==0)
				{
					int count = var->m_Dimension/2;
					count = count==0 ? 1 : count;
					for (int i=0;i<count;++i)
						fprintf(fp, "0xCDCD ");
				}
				fprintf(fp, "\n");
			}
			if (var->m_TypeName == TN_WORDPTR || var->m_TypeName == TN_BYTEPTR)
			{
				fprintf(fp, "@DW ");
				int i=0;
				for (auto &data : var->m_InitialValues)
				{
					if (i%8 == 0 && i!=0)
						fprintf(fp, "\n@DW ");
					fprintf(fp, "0x%.4X 0x%.4X", (data&0xFFFF0000)>>16, data&0x0000FFFF);
					++i;
				}
				if (var->m_InitialValues.size()==0)
				{
					for (int i=0;i<var->m_Dimension;++i)
						fprintf(fp, "0xCDCD 0xCDCD ");
				}
				fprintf(fp, "\n");
			}
			if (var->m_TypeName == TN_DWORDPTR || var->m_TypeName == TN_DWORD || var->m_TypeName == TN_VOIDPTR)
			{
				fprintf(fp, "@DW ");
				int i=0;
				for (auto &data : var->m_InitialValues)
				{
					if (i%8 == 0 && i!=0)
						fprintf(fp, "\n@DW ");
					fprintf(fp, "0x%.4X 0x%.4X", (data&0xFFFF0000)>>16, data&0x0000FFFF);
					++i;
				}
				if (var->m_InitialValues.size()==0)
				{
					for (int i=0;i<var->m_Dimension;++i)
						fprintf(fp, "0xCDCD 0xCDCD ");
				}
				fprintf(fp, "\n");
			}
		}
	}
	fclose(fp);

	return g_ASC.m_CompileFailed;
}

void yyerror(const char *s) {
	printf("line #%d columnd #%d : %s %s\n", yylineno, column, s, yytext );
	err++;
}
