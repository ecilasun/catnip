#include "compiler.h"

//#include "../build/release/source/cparse.hpp"
//#include "../build/release/source/elang.hpp"

// ------------------------------------------- BISON/FLEX

//SCNode *g_root = nullptr, *g_trackingNode = nullptr;
extern int goparse(const char *_inputname);
int CompileCode(char *_inputname, char *_outputname)
{
	//goparse(_inputname);

	/*extern FILE *yyin;
	yyin = fopen(_inputname, "r");
	int res = yyparse();
	fclose(yyin);
	//dumpNodes(g_root, 0);
	return res;*/
	return 0;
}

// ------------------------------------------- CUSTOM

std::string builtin_typequalifier = " const restrict volatile ";
std::string builtin_storageclass = " typedef extern static auto register ";
std::string builtin_typeidentifier = " void char short int ";
std::string builtin_keywords = " for while if else break return continue ";
std::string builtin_numerals = "0123456789";
std::string builtin_markers = " ? ( ) [ ] { } : = >= <= == != *= += -= ++ -- * / + - ; ^ ~ ! | || & && , ";
std::string builtin_whitespace = " \t\r\n";

enum class EGrammarNodeType : uint32_t
{
	// Terminals
	Unknown,
	NumericConstant,
	StringLiteral,
	StorageClass,
	TypeQualifier,
	TypeName,
	Keyword,
	Identifier,
	Dereference,
	AddressOf,
	QuestionMark,
	OpenParenthesis,
	CloseParenthesis,
	OpenBracket,
	CloseBracket,
	OpenCurlyBracket,
	CloseCurlyBracket,
	Colon,
	Assignment,
	GreaterEqual,
	LessEqual,
	Equal,
	NotEqual,
	MulAssign,
	AddAssign,
	SubAssign,
	Increment,
	Decrement,
	Mul,
	Div,
	Add,
	Sub,
	EndStatement,
	BitXor,
	BitNot,
	LogicNot,
	BitOr,
	LogicOr,
	BitAnd,
	LogicAnd,
	Separator,
	// Non-terminals
	DeclSpec,
	Declaration,
	InitDecl,
	InitDeclList,
	Initializer,
	Declarator,
	Pointer,
	DirectDecl,
	AssignOp,
	AssignmentExpression
};

std::string grammarnodetypenames[]=
{
	// Terminals
	"Unknown",
	"NumericConstant",
	"StringLiteral",
	"StorageClass",
	"TypeQualifier",
	"TypeName",
	"Keyword",
	"Identifier",
	"Dereference",
	"AddressOf",
	"QuestionMark",
	"OpenParenthesis",
	"CloseParenthesis",
	"OpenBracket",
	"CloseBracket",
	"OpenCurlyBracket",
	"CloseCurlyBracket",
	"Colon",
	"Assignment",
	"GreaterEqual",
	"LessEqual",
	"Equal",
	"NotEqual",
	"MulAssign",
	"AddAssign",
	"SubAssign",
	"Increment",
	"Decrement",
	"Mul",
	"Div",
	"Add",
	"Sub",
	"EndStatement",
	"BitXor",
	"BitNot",
	"LogicNot",
	"BitOr",
	"LogicOr",
	"BitAnd",
	"LogicAnd",
	"Separator",
	// Non-terminals
	"DeclSpec",
	"Declaration",
	"InitDecl",
	"InitDeclList",
	"Initializer",
	"Declarator",
	"Pointer",
	"DirectDecl",
	"AssignOp",
	"AssignmentExpression"
};

typedef std::vector<struct SGrammarNode> EGrammarNodes;

struct SGrammarNode
{
	std::string word;
	EGrammarNodeType type{EGrammarNodeType::Unknown};
	EGrammarNodes subnodes;
};

void Tokenize(std::string &input, EGrammarNodes &nodes)
{
	// Split input string into tokens including whitespace (carriage return/line feed/tab/space)
	std::regex words_symbols_whitespace("(\\w+)|(>=)|(<=)|(==)|(!=)|(\\+=)|(\\-=)|(\\*=)|(/=)|(/\\*)|(\\*/)|(\\+\\+)|(\\-\\-)|(//)|[ \r\n\t]|[\"';=\\[\\]\\{\\},:\\+\\-<>~!?%^&\\*\\(\\)]");

	auto beg = std::sregex_iterator(input.begin(), input.end(), words_symbols_whitespace);
	//auto end = std::sregex_iterator();

	bool gathering_string = false;
	bool gathering_comment = false;
	bool multilinecomment = false;
	bool singlelinecomment = false;
	std::string gathered = "";
	while (beg != std::sregex_iterator()) // Re-iterate end because we're removing words on the fly
	{
		std::smatch match = *beg;

		std::string currentword = match.str();
		std::string aswholeword = " " + match.str() + " ";

		// String gathering
		if (gathering_string)
		{
			if (currentword == "\"")
			{
				gathering_string = false;
				SGrammarNode node;
				node.word = gathered;
				node.type = EGrammarNodeType::StringLiteral;
				nodes.emplace_back(node);
				++beg;
				continue;
			}
			else
			{
				gathered += currentword;
				++beg;
				continue;
			}
		}

		if (gathering_comment)
		{
			if (multilinecomment && (currentword == "*/"))
			{
				multilinecomment = false;
				gathering_comment = false;
			}
			if (singlelinecomment && (currentword == "\r" || currentword == "\n"))
			{
				singlelinecomment = false;
				gathering_comment = false;
			}
			++beg;
			continue;
		}

		if (builtin_typequalifier.find(aswholeword) != std::string::npos) // Type qualifier
		{
			SGrammarNode node;
			node.word = currentword;
			node.type = EGrammarNodeType::TypeQualifier;
			nodes.emplace_back(node);
		}
		else if (builtin_storageclass.find(aswholeword) != std::string::npos) // Storage class
		{
			SGrammarNode node;
			node.word = currentword;
			node.type = EGrammarNodeType::StorageClass;
			nodes.emplace_back(node);
		}
		else if (builtin_typeidentifier.find(aswholeword) != std::string::npos) // Type identifier
		{
			SGrammarNode node;
			node.word = currentword;
			node.type = EGrammarNodeType::TypeName;
			nodes.emplace_back(node);
		}
		else if(builtin_keywords.find(aswholeword) != std::string::npos) // Keyword
		{
			SGrammarNode node;
			node.word = currentword;
			node.type = EGrammarNodeType::Keyword;
			nodes.emplace_back(node);
		}
		else
		{
			if (currentword == "//" ) // Single line comment scan start
			{
				singlelinecomment = true;
				gathering_comment = true;
			}
			else if (currentword == "/*") // Multi line comment scan start
			{
				multilinecomment = true;
				gathering_comment = true;
			}
			else if (currentword == "\"") // String literal scan start
			{
				gathering_string = true;
			}
			else if (builtin_whitespace.find_first_of(currentword) != std::string::npos)
			{
			}
			else if (builtin_markers.find(aswholeword) != std::string::npos)
			{
				SGrammarNode node;
				node.word = currentword;

				if (currentword == "?")
					node.type = EGrammarNodeType::QuestionMark;
				if (currentword == "(")
					node.type = EGrammarNodeType::OpenParenthesis;
				if (currentword == ")")
					node.type = EGrammarNodeType::CloseParenthesis;
				if (currentword == "[")
					node.type = EGrammarNodeType::OpenBracket;
				if (currentword == "]")
					node.type = EGrammarNodeType::CloseBracket;
				if (currentword == "{")
					node.type = EGrammarNodeType::OpenCurlyBracket;
				if (currentword == "}")
					node.type = EGrammarNodeType::CloseCurlyBracket;
				if (currentword == ":")
					node.type = EGrammarNodeType::Colon;
				if (currentword == "=")
					node.type = EGrammarNodeType::Assignment;
				if (currentword == ">=")
					node.type = EGrammarNodeType::GreaterEqual;
				if (currentword == "<=")
					node.type = EGrammarNodeType::LessEqual;
				if (currentword == "==")
					node.type = EGrammarNodeType::Equal;
				if (currentword == "!=")
					node.type = EGrammarNodeType::NotEqual;
				if (currentword == "*=")
					node.type = EGrammarNodeType::MulAssign;
				if (currentword == "+=")
					node.type = EGrammarNodeType::AddAssign;
				if (currentword == "-=")
					node.type = EGrammarNodeType::SubAssign;
				if (currentword == "++")
					node.type = EGrammarNodeType::Increment;
				if (currentword == "--")
					node.type = EGrammarNodeType::Decrement;
				if (currentword == "*")
					node.type = EGrammarNodeType::Mul;
				if (currentword == "/")
					node.type = EGrammarNodeType::Div;
				if (currentword == "+")
					node.type = EGrammarNodeType::Add;
				if (currentword == "-")
					node.type = EGrammarNodeType::Sub;
				if (currentword == ";")
					node.type = EGrammarNodeType::EndStatement;
				if (currentword == "^")
					node.type = EGrammarNodeType::BitXor;
				if (currentword == "~")
					node.type = EGrammarNodeType::BitNot;
				if (currentword == "!")
					node.type = EGrammarNodeType::LogicNot;
				if (currentword == "|")
					node.type = EGrammarNodeType::BitOr;
				if (currentword == "||")
					node.type = EGrammarNodeType::LogicOr;
				if (currentword == "&")
					node.type = EGrammarNodeType::BitAnd;
				if (currentword == "&&")
					node.type = EGrammarNodeType::LogicAnd;
				if (currentword == ",")
					node.type = EGrammarNodeType::Separator;

				nodes.emplace_back(node);
			}
			else if (builtin_numerals.find_first_of(currentword[0]) != std::string::npos)
			{
				SGrammarNode node;
				node.word = currentword;
				node.type = EGrammarNodeType::NumericConstant;
				nodes.emplace_back(node);
			}
			else // Identifier
			{
				SGrammarNode node;
				node.word = currentword;
				node.type = EGrammarNodeType::Identifier;
				nodes.emplace_back(node);
			}
		}

		++beg;
	}
}

void DumpNode(SGrammarNode &node, int depth)
{
	static const std::string tabulator = "                                                                                                              ";
	bool done = false;
	std::cout << tabulator.substr(0, depth);
	std::cout << grammarnodetypenames[static_cast<uint32_t>(node.type)] << "[" << node.word << "] " << std::endl;
	for (auto n : node.subnodes)
		DumpNode(n, depth+1);
}

int CompileCode2(char *_inputname, char *_outputname)
{
	EGrammarNodes nodes;

	std::string str;
	FILE *inputfile;
	inputfile = fopen(_inputname, "r");
	if (inputfile)
	{
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

		char *filedata = new char[filebytesize+1];
		fread(filedata, 1, filebytesize, inputfile);
		filedata[filebytesize] = 0;
		str = std::string(filedata);
		fclose(inputfile);
	}
	else
	{
		printf("ERROR: Cannot find input file\n");
		return -1;
	}

	Tokenize(str, nodes);

	// TEST: Grammar rule application attempt
	// When applying a rule, the idea is to start from the simplest pattern
	// and group those together. This group now has a new name and can be
	// re-inserted into the same position in the graph (first, delete grouped items)
	// Iteratively applying this method will eventually collapse the list into
	// a reasonable syntax tree we can work with.
	uint32_t tok;

	// Loop until the list can't be reduced further
	bool done = false;
	while (!done)
	{
		size_t oldsize = nodes.size();

		tok = 0;
		if (nodes.size() != 0) do
		{
			// Pointer type
			if (nodes[tok].type == EGrammarNodeType::TypeName && 
				nodes[tok+1].type == EGrammarNodeType::Mul)
			{
				SGrammarNode vardecl;
				vardecl.type = EGrammarNodeType::Pointer;
				vardecl.word = "pointer";
				//vardecl.subnodes.emplace_back(nodes[tok]);
				//vardecl.subnodes.emplace_back(nodes[tok+1]);
				//nodes.erase(nodes.begin()+tok+1);
				nodes[tok+1] = vardecl;
			}

			// Pointer dereference
			if (nodes[tok].type == EGrammarNodeType::Mul &&
				nodes[tok+1].type == EGrammarNodeType::Identifier)
			{
				if (tok==0 || nodes[tok-1].type != EGrammarNodeType::Identifier)
				{
					SGrammarNode vardecl;
					vardecl.type = EGrammarNodeType::Dereference;
					vardecl.word = "deref";
					//vardecl.subnodes.emplace_back(nodes[tok]);
					//vardecl.subnodes.emplace_back(nodes[tok+1]);
					//nodes.erase(nodes.begin()+tok+1);
					nodes[tok] = vardecl;
				}
			}

			tok++;
		} while (tok<nodes.size());

		if (nodes.size() == oldsize)
			break;
	}

	for (auto n : nodes)
		DumpNode(n, 0);

	return 0;
}

