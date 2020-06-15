#include "compiler.h"

#include "lug/lug.hpp"

class CSimpleCompiler
{
	public:

	CSimpleCompiler()
	{
		using namespace lug::language;
		rule Expr;
		implicit_space_rule SP = *"[ \t\n\r]"_rx;

		rule CTranslationUnit, CStatement, CStatementList;
		rule CVarStatement, CVar, CVarArray, CVarList;
		rule CIdentifierLHS, CIdentifierRHS, CStringLiteral, CIntegerConst, CHexConst, CConstant;
		rule CExpressionStatement, CExpression;
		rule CTerm, CFactor;
		rule CAssignmentStatement, CCompoundStatement;

		// TODO: add function calls
		// TODO: add function definitions

		CIdentifierLHS			= lexeme[capture(id_)["[A-Za-z]"_rx > *"[0-9A-Za-z]"_rx]]						< [this] { return lug::utf8::toupper(*id_); };
		CIdentifierRHS			= lexeme[capture(id_)["[A-Za-z]"_rx > *"[0-9A-Za-z]"_rx]]						< [this] { uint32_t H; if (Eval(*id_,0,H)) { stack_.push(H); printf("PUSH [%s]\n", id_->c_str()); } else { parserdone = true; } return lug::utf8::toupper(*id_); };
		//CStringLiteral		= lexeme["\"" > capture(id_)[*"[^\"]"_rx] > "\""]								< [this] { stack_.push(*id_); return lug::utf8::toupper(*id_); };
		CIntegerConst			= lexeme[capture(id_)[+"[0-9]"_rx]]												< [this] { uint32_t V = std::stoi(*id_); stack_.push(V); printf("PUSH [%d]\n", V); return lug::utf8::toupper(*id_); };
		CHexConst				= lexeme[capture(id_)["0[xX]"_rx > *"[a-fA-F0-9]"_rx]]							< [this] { uint32_t V = std::stoul(*id_, nullptr, 16); stack_.push(V); printf("PUSH [%d]\n", V); return lug::utf8::toupper(*id_); };

		CConstant				= CHexConst
								| CIntegerConst;

		CStatement				= CAssignmentStatement
								| CExpressionStatement
								| CVarStatement
								| CCompoundStatement;

		CStatementList			= CStatement > CStatementList
								| CStatement;

		CCompoundStatement		= "{"_sx < [this] { scope_++; printf("{\t\t\t#beginscope:%d\n",scope_); return lug::utf8::toupper(*id_); } > CStatementList > "}"_sx < [this] { CleanupScope(scope_); printf("}\t\t\t#endscope:%d, stacksize=%d\n", scope_, uint32_t(stack_.size())); scope_--; return lug::utf8::toupper(*id_); }
								| "{"_sx < [this] { scope_++; printf("{\t\t\t#beginscope:%d\n",scope_); return lug::utf8::toupper(*id_); } > "}"_sx < [this] { CleanupScope(scope_); printf("}\t\t\t#endscope:%d, stacksize=%d\n", scope_, uint32_t(stack_.size())); scope_--; return lug::utf8::toupper(*id_); };

		// Variable declaration
		CVar					= capture(id_)[CIdentifierLHS]													< [this] { NewVariable(*id_,1); printf("ALLOC %s, 4\n", id_->c_str()); };
		CVarArray				= capture(id_)[CIdentifierLHS] > "["_sx > CExpression > "]"_sx					< [this] { uint32_t V = stack_.top(); stack_.pop(); NewVariable(*id_,V); printf("ALLOC %s, %d*uint32_t\n", id_->c_str(), V); };
		CVarList				= CVar > ","_sx > CVarList
								| CVarArray > ","_sx > CVarList
								| CVarArray
								| CVar;
		CVarStatement			= "var"_sx > CVarList > ";"_sx;

		// Assignment
		CAssignmentStatement	= capture(id_)[CIdentifierLHS] > "="_sx > CExpressionStatement					< [this] { uint32_t V = stack_.top(); stack_.pop(); if (AssignVariable(*id_, 0, V)) printf("SET [%s]\t\t\t#=%d\n", id_->c_str(), V); else { parserdone = true; } }
								| capture(id_)[CIdentifierLHS] > "["_sx > CExpression > "]"_sx > "="_sx > CExpressionStatement	< [this] { uint32_t V = stack_.top(); stack_.pop(); uint32_t I = stack_.top(); stack_.pop(); AssignVariable(*id_, I, V); printf("SET [%s+%d] #=%d\n", id_->c_str(), I, V); };

		// Expressions
		CExpressionStatement	= CExpression > ";"_sx
								| ";"_sx;
		CExpression				= CTerm > "+"_sx > CExpression													< [this] { uint32_t B = stack_.top(); stack_.pop(); uint32_t A = stack_.top(); stack_.pop(); printf("ADD\t\t\t#%d+%d\n", A, B); stack_.push(A+B); }
								| CTerm > "-"_sx > CExpression													< [this] { uint32_t B = stack_.top(); stack_.pop(); uint32_t A = stack_.top(); stack_.pop(); printf("SUB\t\t\t#%d-%d\n", A, B); stack_.push(A-B); }
								| CTerm;
		CTerm					= CFactor > "*"_sx > CTerm														< [this] { uint32_t B = stack_.top(); stack_.pop(); uint32_t A = stack_.top(); stack_.pop(); printf("MUL\t\t\t#%d*%d\n", A, B); stack_.push(A*B); }
								| CFactor > "/"_sx > CTerm														< [this] { uint32_t B = stack_.top(); stack_.pop(); uint32_t A = stack_.top(); stack_.pop(); printf("DIV\t\t\t#%d/%d\n", A, B); stack_.push(A/B); }
								| CFactor;
		CFactor					= "("_sx > CExpression > ")"_sx
								| CConstant
								| capture(id_)[CIdentifierLHS] > "["_sx > CExpression > "]"_sx					< [this] { uint32_t V,H; V = stack_.top(); stack_.pop(); if (Eval(*id_,V,H)) { stack_.push(H); printf("PUSH [%s+%d]\n", id_->c_str(), V); } else { parserdone = true; } return lug::utf8::toupper(*id_); }
								| CIdentifierRHS;

		// Main body
		CTranslationUnit		= CStatementList
								| "<::EOF::>"_sx																< [this] { parserdone = true; }
								| !any																			< [this] { parserdone = true; };

		// The grammar
		grammar_ = start(CTranslationUnit);
	}

	// Remove all variables that went out of scope
	void CleanupScope(uint32_t cleanScope)
	{
		for (auto &var : variables_[cleanScope])
		{
			uint32_t *varaddr = var.second;
			delete [] varaddr;
			printf("DEALLOC %s\n", var.first.c_str());
		}
		variables_[cleanScope].clear();
	}

	// If the identifier is available in current or lower scope, set its value
	bool AssignVariable(std::string& identifier, uint32_t offset, uint32_t value)
	{
		uint32_t foundScope = scope_;
		uint32_t spinScope = scope_;
		bool found = false;
		do
		{
			if (variables_[spinScope].find(identifier) != variables_[spinScope].end())
			{
				foundScope = spinScope;
				found = true;
				break;
			}
		}
		while(spinScope-- != 0);

		if (found)
		{
			uint32_t* varaddrs = variables_[foundScope][identifier];
			varaddrs[offset] = value;
		}
		else
			std::cout << "E0001: Variable '" << identifier << "' not declared within scope." << std::endl;
		return found;
	}

	// Declare a new variable in current scope
	// When the scope terminates, variable will be removed
	void NewVariable(std::string& identifier, uint32_t size)
	{
		variables_[scope_][identifier] = new uint32_t[size/sizeof(uint32_t)];
	}

	// If the identifier is available in current or lower scope, retrieve its value
	bool Eval(std::string &identifier, uint32_t offset, uint32_t &result)
	{
		uint32_t foundScope = scope_;
		uint32_t spinScope = scope_;
		bool found = false;
		do
		{
			if (variables_[spinScope].find(identifier) != variables_[spinScope].end())
			{
				foundScope = spinScope;
				found = true;
				break;
			}
		}
		while(spinScope-- != 0);

		if (found)
		{
			uint32_t* varaddrs = variables_[foundScope][identifier];
			result = varaddrs[offset];
		}
		else
		{
			std::cout << "E0000: Variable '" << identifier << "' not found within scope." << std::endl;
			result=0;
		}

		return found;
	}

	void Process(std::string& sourcecode)
	{
		lug::parser parser{grammar_, environment_};
		parser.push_source([this, &sourcecode](std::string& out)
			{
			out = sourcecode;
			return true;
		});
		parserdone = false;
		bool success = false;
		do {
			success = parser.parse();
			if (success == false)
			{
				std::cout << "Parse error" << std::endl;
				break;
			}
		}
		while (!parserdone && success);
	}

private:
	bool parserdone{false};
	lug::grammar grammar_;
	lug::environment environment_;
	lug::variable<std::string> idx_{environment_};
	lug::variable<std::string> id_{environment_};

	typedef std::map<std::string, uint32_t*> TVariableMap; // Map of variable name -> pointer to variable
	std::map<uint32_t, TVariableMap> variables_; // Map of scope -> variable map
	uint32_t scope_{0}; // Current scope depth

	std::stack<uint32_t> stack_;
};

int CompileCode(char *_inputname, char * /*_outputname*/)
{
	CSimpleCompiler compiler;

	std::cout << "Compiling...\n" << std::endl;

	std::string sourcecode;
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
		sourcecode = std::string(filedata);
		fclose(inputfile);
	}
	else
	{
		printf("ERROR: Cannot find input file\n");
		return -1;
	}

	bool commentError = false;
	// Strip multiline comments
	do {
		size_t foundStart = sourcecode.find("/*");
		if (foundStart != std::string::npos)
		{
			size_t foundEnd = sourcecode.find("*/", foundStart);
			if (foundEnd == std::string::npos)
			{
				std::cout << "E0002: Multiline comment not terminated." << std::endl;
				commentError = true;
				break;
			}
			sourcecode = sourcecode.substr(0, foundStart) + sourcecode.substr(foundEnd+2);
		}
		else
			break;
	} while(sourcecode.length() != 0);

	// Strip single line comments
	do {
		size_t foundStart = sourcecode.find("//");
		if (foundStart != std::string::npos)
		{
			//size_t foundEnd = sourcecode.find("\r", foundStart);
			size_t foundEnd = sourcecode.find("\n", foundStart);
			if (foundEnd == std::string::npos)
			{
				std::cout << "E0003: Single line comment not terminated." << std::endl;
				commentError = true;
				break;
			}
			sourcecode = sourcecode.substr(0, foundStart) + sourcecode.substr(foundEnd+1);
		}
		else
			break;
	} while(sourcecode.length() != 0);

	// Add default outer scope (TODO: and header code in the future)
	//sourcecode = "{ " + sourcecode + " }";

	if (!commentError)
	{
		// This is the source termination marker
		sourcecode += " <::EOF::>";
		// Parse the code which is now stripped from all comments
		compiler.Process(sourcecode);
		return 0;
	}

	return -1;
}
