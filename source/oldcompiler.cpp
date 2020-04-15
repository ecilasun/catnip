#include <stdio.h>
#include <vector>
#include <iostream>
#include "oldcompiler.h"

#include <string>

enum ETokenClass
{
	ETC_Unknown,
	ETC_Keyword,
	ETC_AsmInstruction,
	ETC_TypeName,
	ETC_VariableDeclaration,
	ETC_VariableReference,
	ETC_Symbol,
	ETC_BeginArray,
	ETC_EndArray,
	ETC_Name,
	ETC_StringLiteral,
	ETC_NumericLiteral,
	ETC_FunctionDefinition,
	ETC_FunctionCall,
	ETC_Builtin,
	ETC_BeginParameterList,
	ETC_EndParameterList,
	ETC_VariableAssignment,
	ETC_BodyStart,
	ETC_BodyEnd,
	ETC_EndStatement,
};

enum ETokenSubClass
{
	ETSC_Actual = 0,
	ETSC_Pointer = 1,
	ETSC_Handle = 2,
	ETSC_Reference = 4,
};

std::string g_whitespace = " \r\n\t";
std::string g_letters = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVQXYZ";
std::string g_symbols = "<>!=,;{}()[]+-*%^/\\'#@&|\":";
std::string g_numerals = "0123456789";
std::string g_numeralsAlsoHex = "0123456789xABCDEF";
std::string g_keywords = "return for while do if continue break switch case asm";
std::string g_asmkeywords = "ldd ldw ldb stw stb out in jmp jmpif call callif ret cmp test vsync fsel";
std::string g_typenames = "dword word byte void";

struct STokenParserContext
{
	int m_MaxBodyDepth{0};
	int m_MaxParameterDepth{0};
	int m_CurrentIndentation{0};
};

typedef std::vector<struct SToken> TTokenList;

struct SToken
{
	std::string m_Value;						// String representation of token
	ETokenClass m_Class{ETC_Unknown};		   // Class of token
	ETokenSubClass m_SubClass{ETSC_Actual};	 // Subclass of variable
	int m_BodyDepth{0};						 // Level of depth for this tokens
	int m_ParameterDepth{0};					// Level of depth for this parameter
	TTokenList m_LeftTokenList;				 // Left child nodes
	TTokenList m_RightTokenList;				// Right child nodes
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
	"VariableReference",
	"Symbol",
	"BeginArray",
	"EndArray",
	"Name",
	"StringLiteral",
	"NumericLiteral",
	"FunctionDefinition",
	"FunctionCall",
	"Builtin",
	"BeginParameterList",
	"EndParameterList",
	"VariableAssignment",
	"BodyStart",
	"BodyEnd",
	"EndStatement",
};

static std::string indentation = "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t";

void ASTDumpTokens(TTokenList &root, STokenParserContext &_ctx)
{
	for (auto &t : root)
	{
		/*if (t.m_Class == ETC_BodyStart || t.m_Class == ETC_BeginParameterList || t.m_Class == ETC_BeginArray || t.m_Class == ETC_VariableAssignment)
		{
			std::cout << "\n" << indentation.substr(0, _ctx.m_CurrentIndentation);
			_ctx.m_CurrentIndentation++;
		}

		if (t.m_Class == ETC_BodyEnd || t.m_Class == ETC_EndParameterList || t.m_Class == ETC_EndArray)
		{
			_ctx.m_CurrentIndentation--;
			std::cout << "\n" << indentation.substr(0, _ctx.m_CurrentIndentation);
		}*/

		// Show token data
		std::cout << s_tokenTypeNames[t.m_Class] << ":" << t.m_Value;
		//std::cout << t.m_Value << "(" << t.m_BodyDepth << ":" << t.m_ParameterDepth << ")";

		// Dump child nodes
		if (t.m_LeftTokenList.size())
		{
			std::cout << "\nL:\n";
			ASTDumpTokens(t.m_LeftTokenList, _ctx);
		}
		if (t.m_RightTokenList.size())
		{
			std::cout << "\nR:\n";
			ASTDumpTokens(t.m_RightTokenList, _ctx);
		}

		if (t.m_Class == ETC_EndStatement || t.m_Class == ETC_BodyStart || t.m_Class == ETC_BodyEnd || t.m_Class == ETC_BeginParameterList || t.m_Class == ETC_EndParameterList || t.m_Class == ETC_BeginArray || t.m_Class == ETC_EndArray || t.m_Class == ETC_VariableAssignment)
		{
			//std::cout << "\n" << indentation.substr(0, _ctx.m_CurrentIndentation);
			std::cout << "\n";
		}
		else
			std::cout << " ";
	}
}

int ASTGenerate(std::string &_input, STokenParserContext &_ctx)
{
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
					bool endstatement = token == ";" ? true:false;
					bool beginarray = token == "[" ? true:false;
					bool endarray = token == "]" ? true:false;
					bodydepth += beginbody ? 1 : 0;
					parameterdepth += beginparameter ? 1 : 0;
					SToken t;
					t.m_Value = token;
					t.m_Class = beginbody ? ETC_BodyStart : (endbody ? ETC_BodyEnd : (beginparameter ? ETC_BeginParameterList : (endparameter ? ETC_EndParameterList : ETC_Symbol)));
					if (t.m_Class==ETC_Symbol && endstatement)
						t.m_Class = ETC_EndStatement;
					if (t.m_Class==ETC_Symbol && (beginarray || endarray))
						t.m_Class = beginarray ? ETC_BeginArray : ETC_EndArray;
					t.m_BodyDepth = bodydepth;
					t.m_ParameterDepth = parameterdepth;
					g_TokenList.emplace_back(t);
					bodydepth -= endbody ? 1 : 0;
					parameterdepth -= endparameter ? 1 : 0;

					_ctx.m_MaxBodyDepth = _ctx.m_MaxBodyDepth > bodydepth ? _ctx.m_MaxBodyDepth : bodydepth;
					_ctx.m_MaxParameterDepth = _ctx.m_MaxParameterDepth > parameterdepth ? _ctx.m_MaxParameterDepth : parameterdepth;
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

	// 1) Remove 'empty' tokens
	{
		auto beg = g_TokenList.begin();
		while (beg != g_TokenList.end())
		{
			// ''
			if (beg->m_Value == "")
			{
				beg = g_TokenList.erase(beg);
				continue;
			}
			++beg;
		}
	}

	// 2) Collapse function definitions
	{
		auto beg = g_TokenList.begin();
		while (beg != g_TokenList.end())
		{
			// typename + unknown + '('
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

	// 3) Collapse variable declarations
	{
		auto beg = g_TokenList.begin();
		while (beg != g_TokenList.end())
		{
			// typename + unknown
			if (beg->m_Class == ETC_TypeName && (beg+1)->m_Class == ETC_Unknown)
			{
				(beg+1)->m_Class = ETC_VariableDeclaration;
				beg+=2;
				continue;
			}
			// typename + symbol + unknown
			if (beg->m_Class == ETC_TypeName && (beg+1)->m_Class == ETC_Symbol && (beg+2)->m_Class == ETC_Unknown)
			{
				// This could be 'char * blah' or 'char & somestuff'
				(beg+2)->m_Class = ETC_VariableDeclaration;
				beg+=3;
				continue;
			}
			++beg;
		}
	}

	// 4) Scan for function and variable references (pretty much most leftover unknowns at this point)
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
						beg->m_Class = ETC_VariableReference;
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
					std::cout << "WARNING: '" << beg->m_Value << "' is not declared in this module.\n";
				}
			}
			++beg;
		}
	}

	// 5) Deduce subtypes
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

	// 6) Detect builtin functions (if/return/continue etc) and function calls
	{
		auto beg = g_TokenList.begin();
		while (beg != g_TokenList.end())
		{
			// 'unknown' or keyword followed by a "(" is a function / builtin call (since we didn't find any prior definition of this function)
			if ((beg->m_Class == ETC_Unknown || beg->m_Class == ETC_Keyword) && (beg+1)->m_Value == "(")
			{
				if (g_keywords.find_first_of(beg->m_Value) != std::string::npos)
				{
					std::string builtinname = beg->m_Value;
					beg->m_Class = ETC_Builtin;
					beg->m_Value = builtinname;
				}
				else // This wasn't a function definition so this means we're now calling one
				{
					std::string functionname = beg->m_Value;
					beg->m_Class = ETC_FunctionCall;
					beg->m_Value = functionname;
				}
				beg += 2;
				continue;
			}
			++beg;
		}
	}

	// 7) Collapse assignments
	{
		auto beg = g_TokenList.begin();
		while (beg != g_TokenList.end())
		{
			if ((beg->m_Class == ETC_VariableReference || beg->m_Class == ETC_VariableDeclaration || beg->m_Class == ETC_EndArray)  && (beg+1)->m_Value == "=")
			{
				(beg+1)->m_Class = ETC_VariableAssignment;
				beg+=2;
				continue;
			}
			++beg;
		}
	}

	// 8) Gather array accessor into variable reference or declaration
	{
		auto beg = g_TokenList.begin();
		while (beg != g_TokenList.end())
		{
			if ((beg->m_Class == ETC_VariableReference || beg->m_Class == ETC_VariableDeclaration) && (beg+1)->m_Class == ETC_BeginArray)
			{
				auto cbeg = beg+1;
				bool breaknext = false;
				TTokenList &leftupdatelist = beg->m_LeftTokenList;
				while (cbeg != g_TokenList.end())
				{
					SToken copytoken = *cbeg;
					leftupdatelist.emplace_back(copytoken);
					cbeg = g_TokenList.erase(cbeg);
					if (breaknext)
						break;
					if (cbeg->m_Class == ETC_EndArray)
						breaknext = true;
				}
				++beg;
			}
			else
				++beg;
		}
	}

	// 9) Gather assignment operators after variables
	{
		auto beg = g_TokenList.begin();
		while (beg != g_TokenList.end())
		{
			if ((beg->m_Class == ETC_VariableReference || beg->m_Class == ETC_VariableDeclaration) && (beg+1)->m_Class == ETC_VariableAssignment)
			{
				auto cbeg = beg+1;
				TTokenList &leftupdatelist = beg->m_RightTokenList;
				while (cbeg != g_TokenList.end())
				{
					if (cbeg->m_Class == ETC_EndParameterList || cbeg->m_Class == ETC_EndStatement)
						break;
					SToken copytoken = *cbeg;
					leftupdatelist.emplace_back(copytoken);
					cbeg = g_TokenList.erase(cbeg);
				}
				++beg;
			}
			else
				++beg;
		}
	}

	// 10) Gather function bodies into 'EndParameterList'
	{
		auto beg = g_TokenList.begin();
		while (beg != g_TokenList.end())
		{
			// Found a function definition or a builtin or a function call, start collapsing parameter list
			if (beg->m_Class == ETC_FunctionDefinition || beg->m_Class == ETC_Builtin || beg->m_Class == ETC_FunctionCall)
			{
				auto cbeg = beg+1;
				bool breaknext = false;
				TTokenList &leftupdatelist = beg->m_LeftTokenList;
				TTokenList &rightupdatelist = beg->m_RightTokenList;
				while (cbeg != g_TokenList.end())
				{
					SToken copytoken = *cbeg;
					leftupdatelist.emplace_back(copytoken);
					cbeg = g_TokenList.erase(cbeg);
					if (breaknext)
						break;
					if (cbeg->m_Class == ETC_EndParameterList)
						breaknext = true;
				}

				// Start collapsing function body
				breaknext = false;
				int bodyDepth = cbeg->m_BodyDepth;
				while (cbeg != g_TokenList.end())
				{
					SToken copytoken = *cbeg;
					rightupdatelist.emplace_back(copytoken);
					cbeg = g_TokenList.erase(cbeg);
					if (breaknext)
						break;
					if (cbeg->m_Class == ETC_BodyEnd && cbeg->m_BodyDepth == bodyDepth)
						breaknext = true;
				}
				++beg;
			}
			else
				++beg;
		}
	}

	// DEBUG: Dump tokens
	ASTDumpTokens(g_TokenList, _ctx);

	std::cout << std::endl;
	std::cout << "Max Body Depth: " << _ctx.m_MaxBodyDepth << "\n";
	std::cout << "Max Parameter Depth: " << _ctx.m_MaxParameterDepth << "\n";

	return 0; // No error
}

int compile_c(char *_inputname, char *_outputname)
{
	// Read ROM file
	FILE *inputfile = fopen(_inputname, "rb");
	if (inputfile == nullptr)
	{
		printf("ERROR: Cannot find .c file\n");
		return -1;
	}

	unsigned int filebytesize = 0;
	fpos_t pos, endpos;
	fgetpos(inputfile, &pos);
	fseek(inputfile, 0, SEEK_END);
	fgetpos(inputfile, &endpos);
	fsetpos(inputfile, &pos);
#if defined(CAT_LINUX)
	filebytesize = (unsigned int)endpos.__pos;
#else
	filebytesize = (unsigned int)endpos;
#endif

	// Allocate memory and read file contents, then close the file
	char *filedata = new char[filebytesize];
	fread(filedata, 1, filebytesize, inputfile);
	fclose(inputfile);

	STokenParserContext parsercontext;
	std::string filecontents = std::string(filedata);
	return ASTGenerate(filecontents, parsercontext);
}
