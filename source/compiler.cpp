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
	// Atoms
	Unknown,
	NumericConstant,
	StringLiteral,
	StorageClass,
	TypeQualifier,
	TypeName,
	Keyword,
	Identifier,
	QuestionMark,
	OpenParenthesis,
	CloseParenthesis,
	OpenBracket,
	CloseBracket,
	OpenCurlyBracket,
	CloseCurlyBracket,
	Colon,
	EqualSign,
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

	// 
	Assignment,
	FunctionHeader,
	FunctionBegin,
	FunctionEnd,
	TypedIdentifier,
	Root,
	Expression,
	Pointer,
	Copy,
	Dereference,
	AddressOf,
	Return,
};

std::string grammarnodetypenames[]=
{
	// Atoms
	"Unknown",
	"NumericConstant",
	"StringLiteral",
	"StorageClass",
	"TypeQualifier",
	"TypeName",
	"Keyword",
	"Identifier",
	"QuestionMark",
	"OpenParenthesis",
	"CloseParenthesis",
	"OpenBracket",
	"CloseBracket",
	"OpenCurlyBracket",
	"CloseCurlyBracket",
	"Colon",
	"EqualSign",
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

	// 
	"Assignment",
	"FunctionHeader",
	"FunctionBegin",
	"FunctionEnd",
	"TypedIdentifier",
	"Root",
	"Expression",
	"Pointer",
	"Copy",
	"Dereference",
	"AddressOf",
	"Return",
};

typedef std::vector<struct SGrammarNode> EGrammarNodes;

struct SGrammarNode
{
	std::string word;
	EGrammarNodeType type{EGrammarNodeType::Unknown};
	EGrammarNodes subnodes;
};

typedef std::function<int(uint32_t, SGrammarNode &, EGrammarNodes *, EGrammarNodes *)> FPostReduceCallback;

struct SGrammarRule
{
	EGrammarNodeType reduce;				// Grammar node type to replace the provided list with
	std::vector<EGrammarNodeType> match;	// List of grammar node types to match
	FPostReduceCallback callback;			// Function to call after reduction is applied
};

// Post-reduce callbacks
int PRDefault(uint32_t popcount, SGrammarNode &replacementnode, EGrammarNodes *sourcenodes, EGrammarNodes *targetnodes)
{
	// Remove replaced entries from stack
	for (uint32_t i=0;i<popcount;++i)
		sourcenodes->pop_back();

	// Push the new node onto stack for next tour
	sourcenodes->push_back(replacementnode);

	return 1;
}

int PRFunction(uint32_t popcount, SGrammarNode &replacementnode, EGrammarNodes *sourcenodes, EGrammarNodes *targetnodes)
{
	// Copy onto target
	targetnodes->push_back(replacementnode);

	// Clear the entire stack
	sourcenodes->clear();

	return 1;
}

// Grammar rules
typedef std::vector<struct SGrammarRule> EGrammarRules;

EGrammarRules s_grammar_rules = {
	{EGrammarNodeType::TypedIdentifier, {EGrammarNodeType::TypeName, EGrammarNodeType::Identifier}, PRDefault},
	{EGrammarNodeType::FunctionHeader, {EGrammarNodeType::TypedIdentifier, EGrammarNodeType::Colon}, PRDefault},
	{EGrammarNodeType::FunctionBegin, {EGrammarNodeType::FunctionHeader, EGrammarNodeType::OpenCurlyBracket}, PRDefault},
	{EGrammarNodeType::FunctionEnd, {EGrammarNodeType::FunctionBegin, EGrammarNodeType::CloseCurlyBracket}, PRFunction},
	{EGrammarNodeType::Assignment, {EGrammarNodeType::Identifier, EGrammarNodeType::EqualSign}, PRDefault},
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
					node.type = EGrammarNodeType::EqualSign;
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

void ShiftReduce(EGrammarNodes &nodes)
{
	EGrammarNodes product;		// A meaningful portion of work is always moved here
	EGrammarNodes stack;		// Stack to use during shift-reduce

	bool done = false;
	int nextnode = 0;
	SGrammarNode lookahead = nodes[nextnode++];
	while (!done)
	{
		// Try to reduce
		int matching_rule=-1;
		int ruleindex = 0;
		int popcount = 0;
		for(auto &r : s_grammar_rules)
		{
			uint32_t matches=0;
			int i=0;
			// Always rewind to top of stack
			for (auto &s : stack)
				matches += (r.match[i++] == s.type) ? 1 : 0;
			if (matches == r.match.size())
			{
				matching_rule = ruleindex;
				popcount = r.match.size();
				//std::cout << "SUCCESS: Reduce successful for rule " << ruleindex << std::endl;
				break;
			}
			++ruleindex;
		}

		// Did we match any rule so far?
		if (matching_rule!=-1)
		{
			// Generate a new node with reduced type, and assign all stack entries as subnodes
			SGrammarNode replacementnode;
			replacementnode.type = s_grammar_rules[matching_rule].reduce;
			// TODO: This is too naiive, callback required to truly 'collapse' stack onto the replaced version
			for (auto &n : stack)
				replacementnode.subnodes.push_back(n); // This also carries over the subnodes of stack entries
			replacementnode.word = grammarnodetypenames[static_cast<uint32_t>(replacementnode.type)];

			// Apply the post-rule
			int count = s_grammar_rules[matching_rule].callback(popcount, replacementnode, &stack, &product);
		}
		else
		{
			if (nextnode >= nodes.size())
			{
				done = true;
				std::cout << "ERROR: input underflow, aborting. " << std::endl;
				break;
			}

			// stack doesn't have enough items for a rule match, push lookahead
			stack.push_back(lookahead);
			lookahead = nodes[nextnode++];
		}
	}

	// Dump the output we've produced so far
	std::cout << "Final result:" << std::endl;
	for (auto &n : product)
		DumpNode(n, 0);
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

	ShiftReduce(nodes);

	/*for (auto n : nodes)
		DumpNode(n, 0);*/

	return 0;
}

