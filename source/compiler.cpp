#include "compiler.h"

// ----------------------------------------------------------------------------------------------------------------------
// Tokens, nodes etc
// ----------------------------------------------------------------------------------------------------------------------

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
	Asterisk,
	Div,
	Plus,
	Minus,
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
	Mul,
	Sub,
	Add,
	Statement,
	VariableDeclaration,
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
	"Asterisk",
	"Div",
	"Plus",
	"Minus",
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
	"Mul",
	"Sub",
	"Add",
	"Statement",
	"VariableDeclaration",
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

// ----------------------------------------------------------------------------------------------------------------------
// Grammar rule related
// ----------------------------------------------------------------------------------------------------------------------

struct SGrammarContext
{
	int codeblockdepth{0};
};

typedef std::vector<struct SGrammarNode> EGrammarNodes;

struct SGrammarNode
{
	std::string word;
	EGrammarNodeType type{EGrammarNodeType::Unknown};
	EGrammarNodes subnodes;
};

// typedef std::function<int(uint32_t, SGrammarNode &, EGrammarNodes *, EGrammarNodes *)> FSRCallback;

struct SGrammarRule
{
	EGrammarNodeType reduce;				// Grammar node type to replace the provided list with
	std::vector<EGrammarNodeType> match;	// List of grammar node types to match
};

// ----------------------------------------------------------------------------------------------------------------------
// Shift
// ----------------------------------------------------------------------------------------------------------------------

int SRDefaultShift(SGrammarContext &context, uint32_t popcount, SGrammarNode &replacementnode, EGrammarNodes *sourcenodes, EGrammarNodes *targetnodes)
{
	// Push the new node onto stack for next tour
	sourcenodes->push_back(replacementnode);

	return popcount;
}

// ----------------------------------------------------------------------------------------------------------------------
// Reduce
// ----------------------------------------------------------------------------------------------------------------------

int SRDefaultReduce(SGrammarContext &context, uint32_t popcount, SGrammarNode &replacementnode, EGrammarNodes *sourcenodes, EGrammarNodes *targetnodes)
{
	// Remove reduced items from stack
	for (uint32_t i=0; i<popcount; ++i)
		sourcenodes->pop_back();

	// If we're generating a function header, get rid of the { and : symbols, and also 'enter' code block
	if (replacementnode.type == EGrammarNodeType::FunctionHeader)
	{
		replacementnode.subnodes.pop_back();
		replacementnode.subnodes.pop_back();
		context.codeblockdepth++;
	}

	// If we're closing a code block, check to see if we can
	// do it, and also remove the } symbol
	if (replacementnode.type == EGrammarNodeType::FunctionEnd)
	{
		if (context.codeblockdepth<=0)
		{
			std::cout << "ERROR: can't close code block" << std::endl;
			return -1;
		}
		context.codeblockdepth--;
		replacementnode.subnodes.pop_back();
	}

	// For Add, remove the middle operator sign
	if (replacementnode.type == EGrammarNodeType::Add || replacementnode.type == EGrammarNodeType::Sub || replacementnode.type == EGrammarNodeType::Mul)
	{
		SGrammarNode lastitem = replacementnode.subnodes.back();
		replacementnode.subnodes.pop_back();
		replacementnode.subnodes.pop_back(); // The operator
		replacementnode.subnodes.push_back(lastitem);
		SGrammarNode expression;
		expression.type = EGrammarNodeType::Expression;
		expression.word = "";
		expression.subnodes.push_back(replacementnode);
		replacementnode = expression;
	}

	// If we have a variable, remove the semicolumn at the end
	if (replacementnode.type == EGrammarNodeType::VariableDeclaration)
	{
		replacementnode.subnodes.pop_back();
	}

	// Copy new collapsed node onto target
	sourcenodes->push_back(replacementnode);

	return popcount;
}

// Grammar rules
typedef std::vector<struct SGrammarRule> EGrammarRules;

EGrammarRules s_grammar_rules = {
	{EGrammarNodeType::TypedIdentifier, {EGrammarNodeType::TypeName, EGrammarNodeType::Identifier}},
	{EGrammarNodeType::VariableDeclaration, {EGrammarNodeType::TypedIdentifier, EGrammarNodeType::EndStatement}},
	{EGrammarNodeType::FunctionHeader, {EGrammarNodeType::TypedIdentifier, EGrammarNodeType::Colon, EGrammarNodeType::OpenCurlyBracket}},
	{EGrammarNodeType::FunctionEnd, {EGrammarNodeType::CloseCurlyBracket}},
	//{EGrammarNodeType::Expression, {EGrammarNodeType::Identifier}},
	{EGrammarNodeType::Expression, {EGrammarNodeType::NumericConstant}},
	{EGrammarNodeType::Expression, {EGrammarNodeType::OpenParenthesis, EGrammarNodeType::Expression, EGrammarNodeType::CloseParenthesis}},
	{EGrammarNodeType::Mul, {EGrammarNodeType::Expression, EGrammarNodeType::Asterisk, EGrammarNodeType::Expression}},
	{EGrammarNodeType::Sub, {EGrammarNodeType::Expression, EGrammarNodeType::Minus, EGrammarNodeType::Expression}},
	{EGrammarNodeType::Add, {EGrammarNodeType::Expression, EGrammarNodeType::Plus, EGrammarNodeType::Expression}},
	/*{EGrammarNodeType::Assignment, {EGrammarNodeType::Identifier, EGrammarNodeType::EqualSign}},*/
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
					node.type = EGrammarNodeType::Asterisk;
				if (currentword == "/")
					node.type = EGrammarNodeType::Div;
				if (currentword == "+")
					node.type = EGrammarNodeType::Plus;
				if (currentword == "-")
					node.type = EGrammarNodeType::Minus;
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
	SGrammarContext context;	// Current grammar context
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

		// If there is at least one item on the stack
		if (stack.size() != 0)
		{
			for(auto &r : s_grammar_rules)
			{
				uint32_t matches=0;
				// Always rewind back in stack as long as the current rule
				int i = stack.size()-r.match.size();
				// If the stack has enough items to test against the rule
				if (i>=0)
				{
					int idxrule = 0;
					while (i<stack.size())
					{
						if (idxrule > r.match.size())
						{
							done = true;
							std::cout << "ERROR: ran out of rules vs stack" << std::endl;
							break;
						}

						SGrammarNode &s = stack[i];
						matches += (r.match[idxrule++] == s.type) ? 1 : 0;
						++i;
					}
					if (matches == r.match.size())
					{
						matching_rule = ruleindex;
						popcount = r.match.size();
						//std::cout << "SUCCESS: Reduce successful for rule " << ruleindex << std::endl;
						break;
					}
				}
				++ruleindex;
			}
		}

		// Did we match any rule so far?
		if (matching_rule!=-1)
		{
			// Generate a new node with reduced type, and assign all stack entries as subnodes
			SGrammarNode replacementnode;
			replacementnode.type = s_grammar_rules[matching_rule].reduce;
			// TODO: This is too naiive, callback required to truly 'collapse' stack onto the replaced version
			int sidx = stack.size()-popcount;
			for (int i=sidx;i<stack.size();++i)
				replacementnode.subnodes.push_back(stack[i]); // This also carries over the subnodes of stack entries
			replacementnode.word = "";//grammarnodetypenames[static_cast<uint32_t>(replacementnode.type)];

			// Apply the shift-reduce
			int is_reduce = SRDefaultReduce(context, popcount, replacementnode, &stack, &product);
		}
		else
		{
			if (nextnode >= nodes.size())
			{
				done = true;
				std::cout << "ERROR: input underflow, aborting. " << std::endl;
				break;
			}

			// Shift onto stack
			SRDefaultShift(context, popcount, lookahead, &stack, &product);

			lookahead = nodes[nextnode++];
		}
	}

	// Dump the output we've produced so far
	std::cout << "Final result:" << std::endl;
	for (auto &n : stack)
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

