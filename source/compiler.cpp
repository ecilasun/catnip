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

		rule CTranslationUnit, CStatement, CStatementList, CStatementBlock;
		rule CVarStatement, CVar, CVarList;
		rule CIdentifierLHS, CIdentifierRHS, CStringLiteral, CIntegerConst, CHexConst, CConstant;
		rule CExpressionStatement, CExpression;
		rule CTerm, CFactor;
		rule CAssignmentStatement;

		// TODO: add function calls
		// TODO: add function definitions

		CIdentifierLHS		= lexeme[capture(id_)["[A-Za-z]"_rx > *"[0-9A-Za-z]"_rx]]							< [this] { return lug::utf8::toupper(*id_); };
		CIdentifierRHS		= lexeme[capture(id_)["[A-Za-z]"_rx > *"[0-9A-Za-z]"_rx]]							< [this] { uint32_t H = Eval(*id_); stack_.push(H); printf("PUSH [%s]\n", id_->c_str()); return lug::utf8::toupper(*id_); };
		//CStringLiteral	= lexeme["\"" > capture(id_)[*"[^\"]"_rx] > "\""]									< [this] { stack_.push(*id_); return lug::utf8::toupper(*id_); };
		CIntegerConst		= lexeme[capture(id_)[+"[0-9]"_rx]]													< [this] { uint32_t V = std::stoi(*id_); stack_.push(V); printf("PUSH [%d]\n", V); return lug::utf8::toupper(*id_); };
		CHexConst			= lexeme[capture(id_)["0[xX]"_rx > *"[a-fA-F0-9]"_rx]]								< [this] { uint32_t V = std::stoul(*id_, nullptr, 16); stack_.push(V); printf("PUSH [%d]\n", V); return lug::utf8::toupper(*id_); };

		CConstant	= CHexConst
					| CIntegerConst
					;

		CStatement				= CAssignmentStatement
								| CExpressionStatement
								| CVarStatement;

		CStatementList			= CStatement > CStatementList
								| CStatement;

		CStatementBlock			= "{"_sx < [this] { printf("BEGIN\n"); } > CStatementList > "}"_sx				< [this] { printf("END  #stacksize=%d\n", uint32_t(stack_.size())); };

		// Variable declaration
		CVar					= capture(id_)[CIdentifierLHS]				 									< [this] { NewVariable(*id_); printf("ALLOC %s, 4\n", id_->c_str()); };
		CVarList				= CVar > ","_sx > CVarList
								| CVar;
		CVarStatement			= "var"_sx > CVarList > ";"_sx 													< [this] { /* var A,B,C; */ };

		// Assignment
		CAssignmentStatement	= capture(id_)[CIdentifierLHS] > "="_sx > CExpressionStatement					< [this] { uint32_t V = stack_.top(); stack_.pop(); AssignVariable(*id_, V); printf("SET [%s] #=%d\n", id_->c_str(), V); };
								/*| capture(id_)[CIdentifierLHS] > "["_sx > CExpression > "]"_sx > "="_sx > CExpressionStatement	< [this] { uint32_t V = stack_.top(); stack_.pop(); uint32_t I = stack_.top(); stack_.pop(); AssignVariable(*id_, V); printf("SET [%s+%d] #=%d\n", id_->c_str(), I, V); };*/

		CExpressionStatement	= CExpression > ";"_sx															< [this] { }
								| ";"_sx																		< [this] { };
		CExpression				= CTerm > "+"_sx > CExpression													< [this] { uint32_t B = stack_.top(); stack_.pop(); uint32_t A = stack_.top(); stack_.pop(); printf("ADD #%d+%d\n", A, B); stack_.push(A+B); }
								| CTerm > "-"_sx > CExpression													< [this] { uint32_t B = stack_.top(); stack_.pop(); uint32_t A = stack_.top(); stack_.pop(); printf("SUB #%d-%d\n", A, B); stack_.push(A-B); }
								| CTerm																			< [this] { };
		CTerm					= CFactor > "*"_sx > CTerm														< [this] { uint32_t B = stack_.top(); stack_.pop(); uint32_t A = stack_.top(); stack_.pop(); printf("MUL #%d*%d\n", A, B); stack_.push(A*B); }
								| CFactor > "/"_sx > CTerm														< [this] { uint32_t B = stack_.top(); stack_.pop(); uint32_t A = stack_.top(); stack_.pop(); printf("DIV #%d/%d\n", A, B); stack_.push(A/B); }
								| CFactor																		< [this] { };
		CFactor					= "("_sx > CExpression > ")"_sx													< [this] { }
								| CConstant
								| CIdentifierRHS;

		CTranslationUnit		= CStatement
								| CStatementBlock
								| "<::EOF::>"_sx																< [this] { parserdone = true; };

		grammar_ = start(CTranslationUnit);

	}

	void AssignVariable(std::string& identifier, uint32_t value)
	{
		variables_[identifier] = value;
	}

	void NewVariable(std::string& identifier)
	{
		variables_[identifier] = 0; // Variables default to zero
	}

	uint32_t Eval(std::string &identifier)
	{
		return variables_[identifier];
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
	std::map<std::string, uint32_t> variables_;
	std::stack<uint32_t> stack_;
	uint32_t handle_{1024};
};

int CompileCode(char *_inputname, char * /*_outputname*/)
{
	CSimpleCompiler compiler;

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

	// This is the source termination marker
	sourcecode += "\n\n\n\n<::EOF::>";

	compiler.Process(sourcecode);

	return 0;
}
