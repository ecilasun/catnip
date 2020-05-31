#include "compiler.h"

//#include "lug/lug.hpp"

int CompileCode2(char * /*_inputname*/, char * /*_outputname*/)
{
	//using namespace lug::language;
	//lug::grammar grammar_;
	//lug::environment environment_;
	//lug::variable<std::string> id_{ environment_ };

	//rule Expr;
	//implicit_space_rule SP = *"[ \t\n\r]"_rx;

	// simple language
	//rule CIdentifier, CStringLiteral, CIntegerConst, CHexConst;

	//CIdentifier = lexeme[capture(id_)["[A-Za-z]"_rx > *"[0-9A-Za-z]"_rx]] < [this] { printf("id(%s) ", id_->c_str()); return lug::utf8::toupper(*id_); };
	//CStringLiteral = lexeme["\"" > capture(id_)[*"[^\"]"_rx] > "\""]													< [this] { printf("str(%s) ", id_->c_str()); return lug::utf8::toupper(*id_); };
	//CIntegerConst	= lexeme[capture(id_)[+"[0-9]"_rx]]																	< [this] { printf("deci(%s) ", id_->c_str()); return lug::utf8::toupper(*id_); };
	//CHexConst	= lexeme[capture(id_)["0[xX][a-fA-F0-9] + *(u|U|l|L)?"_rx]]												< [this] { printf("hex(%s) ", id_->c_str()); return lug::utf8::toupper(*id_); };

	//grammar_ = start(CTranslationUnit);

	return 0;
}

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
	ForwardSlash,
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
	Products,
	Sums,
	Value,
	Assignment,

	Div,
	Mul,
	Sub,
	Add,
	Statement,
	VariableDeclaration,
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
	"ForwardSlash",
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
	"Products",
	"Sums",
	"Value",
	"Assignment",

	"Div",
	"Mul",
	"Sub",
	"Add",
	"Statement",
	"VariableDeclaration",
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
	EGrammarNodeType reduce{EGrammarNodeType::Unknown};		// Grammar node type to replace the provided list with
	std::vector<EGrammarNodeType> match;					// List of grammar node types to match
	int cursor {-1};										// Set to max matching position for each time the rule is tested (highest number (or ==rule size) wins)
};

// ----------------------------------------------------------------------------------------------------------------------
// Grammar rules
// ----------------------------------------------------------------------------------------------------------------------
typedef std::vector<struct SGrammarRule> EGrammarRules;

EGrammarRules s_grammar_rules = {
	/*{EGrammarNodeType::TypedIdentifier, {EGrammarNodeType::TypeName, EGrammarNodeType::Identifier}},
	{EGrammarNodeType::VariableDeclaration, {EGrammarNodeType::TypedIdentifier, EGrammarNodeType::EndStatement}},
	{EGrammarNodeType::FunctionHeader, {EGrammarNodeType::TypedIdentifier, EGrammarNodeType::Colon, EGrammarNodeType::OpenCurlyBracket}},
	{EGrammarNodeType::FunctionEnd, {EGrammarNodeType::CloseCurlyBracket}},*/

	/*{EGrammarNodeType::Assignment, {EGrammarNodeType::Identifier, EGrammarNodeType::EqualSign, EGrammarNodeType::Sums, EGrammarNodeType::EndStatement}},			// ASSIGNMENT:	ID '=' SUMS ';'
	{EGrammarNodeType::Products, {EGrammarNodeType::Products, EGrammarNodeType::Asterisk, EGrammarNodeType::Value}},												// PRODUCTS:	PRODUCTS '*' VALUE | PRODUCTS '/' VALUE | VALUE
	{EGrammarNodeType::Products, {EGrammarNodeType::Products, EGrammarNodeType::ForwardSlash, EGrammarNodeType::Value}},
	{EGrammarNodeType::Products, {EGrammarNodeType::Value}},
	{EGrammarNodeType::Sums, {EGrammarNodeType::Sums, EGrammarNodeType::Plus, EGrammarNodeType::Products}},															// SUMS:		SUMS '+' PRODUCS | SUMS '-' PRODUCTS | PRODUCTS
	{EGrammarNodeType::Sums, {EGrammarNodeType::Sums, EGrammarNodeType::Minus, EGrammarNodeType::Products}},
	{EGrammarNodeType::Sums, {EGrammarNodeType::Products}},
	{EGrammarNodeType::Value, {EGrammarNodeType::NumericConstant}},																									// VALUE:		NUMCONST | ID
	{EGrammarNodeType::Value, {EGrammarNodeType::Identifier}},*/

	// TEST
	{EGrammarNodeType::Value, {EGrammarNodeType::Value, EGrammarNodeType::Plus, EGrammarNodeType::Value}},
	{EGrammarNodeType::Value, {EGrammarNodeType::Value, EGrammarNodeType::Asterisk, EGrammarNodeType::Value}},
	{EGrammarNodeType::Value, {EGrammarNodeType::Identifier}},

	//{EGrammarNodeType::Expression, {EGrammarNodeType::Identifier}},
	//{EGrammarNodeType::Expression, {EGrammarNodeType::NumericConstant}},
	//{EGrammarNodeType::Expression, {EGrammarNodeType::OpenParenthesis, EGrammarNodeType::Expression, EGrammarNodeType::CloseParenthesis}},
	//{EGrammarNodeType::Mul, {EGrammarNodeType::Expression, EGrammarNodeType::Asterisk, EGrammarNodeType::Expression}},
	//{EGrammarNodeType::Sub, {EGrammarNodeType::Expression, EGrammarNodeType::Minus, EGrammarNodeType::Expression}},
	//{EGrammarNodeType::Add, {EGrammarNodeType::Expression, EGrammarNodeType::Plus, EGrammarNodeType::Expression}},
};

// ----------------------------------------------------------------------------------------------------------------------
// Shift
// ----------------------------------------------------------------------------------------------------------------------

int SRDefaultShift(SGrammarContext & /*context*/, uint32_t popcount, SGrammarNode &replacementnode, EGrammarNodes *sourcenodes, EGrammarNodes * /*targetnodes*/)
{
	// Push the new node onto stack for next tour
	sourcenodes->push_back(replacementnode);

	std::cout << "Shift: " << grammarnodetypenames[(uint32_t)replacementnode.type] << std::endl;
	std::cout << "     : ";
	for (uint32_t i=0;i<sourcenodes->size();++i)
		std::cout << grammarnodetypenames[(uint32_t)(*sourcenodes)[i].type] << ", ";
	std::cout << std::endl;

	return popcount;
}

// ----------------------------------------------------------------------------------------------------------------------
// Reduce
// ----------------------------------------------------------------------------------------------------------------------

int SRDefaultReduce(int grammarRuleIndex, SGrammarContext & /*context*/, uint32_t popcount, SGrammarNode &replacementnode, EGrammarNodes *sourcenodes, EGrammarNodes * /*targetnodes*/)
{
	// Remove reduced items from stack
	for (uint32_t i=0; i<popcount; ++i)
		sourcenodes->pop_back();

	std::cout << "Reduce: " << grammarnodetypenames[(uint32_t)s_grammar_rules[grammarRuleIndex].reduce] << " -> ";
	for (uint32_t i=0;i<s_grammar_rules[grammarRuleIndex].match.size();++i)
		std::cout << grammarnodetypenames[(uint32_t)s_grammar_rules[grammarRuleIndex].match[i]] << ", ";
	std::cout << std::endl;

	// If we're generating a function header, get rid of the { and : symbols, and also 'enter' code block
	/*if (replacementnode.type == EGrammarNodeType::FunctionHeader)
	{
		replacementnode.subnodes.pop_back();
		replacementnode.subnodes.pop_back();
		context.codeblockdepth++;
	}*/

	// If we're closing a code block, check to see if we can
	// do it, and also remove the } symbol
	/*if (replacementnode.type == EGrammarNodeType::FunctionEnd)
	{
		if (context.codeblockdepth<=0)
		{
			std::cout << "ERROR: can't close code block" << std::endl;
			return -1;
		}
		context.codeblockdepth--;
		replacementnode.subnodes.pop_back();
	}*/

	// For Add, remove the middle operator sign
	/*if (replacementnode.type == EGrammarNodeType::Add || replacementnode.type == EGrammarNodeType::Sub || replacementnode.type == EGrammarNodeType::Mul)
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
	}*/

	// If we have a variable, remove the semicolumn at the end
	/*if (replacementnode.type == EGrammarNodeType::VariableDeclaration)
	{
		replacementnode.subnodes.pop_back();
	}*/

	// Copy new collapsed node onto target
	sourcenodes->push_back(replacementnode);

	std::cout << "     : ";
	for (uint32_t i=0;i<sourcenodes->size();++i)
		std::cout << grammarnodetypenames[(uint32_t)(*sourcenodes)[i].type] << ", ";
	std::cout << std::endl;

	return popcount;
}

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
					node.type = EGrammarNodeType::ForwardSlash;
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
	int depth2 = depth-1; depth2 = depth2<0 ? 0 : depth2;
	static const std::string tabulator = "|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
	std::cout << "\t" << tabulator.substr(0, depth2) << (depth==0 ? "" : "|-");
	std::cout << grammarnodetypenames[static_cast<uint32_t>(node.type)] << "[" << node.word << "] " << std::endl;
	for (auto n : node.subnodes)
		DumpNode(n, depth+1);
}

int MatchRule(SGrammarRule &rule, EGrammarNodes &stack)
{
	int matchIndex = 0;
	int matchCursor = -1;
	rule.cursor = -1;

	// Go down in stack by rule length
	int i = int(stack.size())-int(rule.match.size());
	// Truncate so that we can't go past the start of the stack
	// This ensures that we get at least the first few matches tested for long rules
	i = i<0 ? 0 : i;

	// Walk over match list in rule
	while (i<stack.size() && matchIndex<rule.match.size())
	{
		SGrammarNode &s = stack[i];
		if (rule.match[matchIndex] != s.type)
			break;
		// Set match cursor
		matchCursor = matchIndex++;
		// Next stack position
		++i;
	}

	// Update rule match state
	rule.cursor = matchCursor;
	return rule.match.size();
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
		int popcount = 0;
		int matchingRuleIndex = -1;

		// We need at least one item on the stack to run compares
		if (stack.size() != 0)
		{
			// Run a match with each rule and update match cursor
			for(auto &r : s_grammar_rules)
				/*int m =*/ MatchRule(r, stack);
	
			// Now pick the best candidate (longest rule that partially or fully matches)
			int ruleCounter = 0;
			int bestMatchSize = -1;
			for(auto &r : s_grammar_rules)
			{
				// Longer rule, cursor advanced more (more matches), and lookahead item matches long rule's next entry
				if (r.cursor!=-1 && ((r.match.size() != r.cursor+1) ? (lookahead.type == r.match[r.cursor+1] ? true:false) : true))
				{
					// Pick the longest one
					if (int(r.match.size()) > bestMatchSize)
					{
						bestMatchSize = r.match.size();
						matchingRuleIndex = ruleCounter;
						popcount = r.match.size();
					}
				}
				++ruleCounter;
			}
		}

		// Did we match any rule so far?
		if (matchingRuleIndex != -1 && stack.size() >= s_grammar_rules[matchingRuleIndex].match.size())
		{
			// Generate a new node with reduced type, and assign all stack entries as subnodes
			SGrammarNode replacementnode;
			replacementnode.type = s_grammar_rules[matchingRuleIndex].reduce;
			// TODO: This is too naiive, callback required to truly 'collapse' stack onto the replaced version
			int sidx = int(stack.size()) - popcount;
			for (int i=sidx;i<int(stack.size());++i)
				replacementnode.subnodes.push_back(stack[i]); // This also carries over the subnodes of stack entries
			replacementnode.word = "";//grammarnodetypenames[static_cast<uint32_t>(replacementnode.type)];

			// Apply the shift-reduce
			/*int is_reduce =*/ SRDefaultReduce(matchingRuleIndex, context, popcount, replacementnode, &stack, &product);
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

int CompileCode(char *_inputname, char * /*_outputname*/)
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

