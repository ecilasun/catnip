#include "compiler.h"

// ---------------------------------------------------------------------------
// Lexical analyzer
// Convert text stream to tokens
// ---------------------------------------------------------------------------

std::string tokenizer_symbols = ",;{}()\\'\":";
std::string tokenizer_operators = "! = == < > != >= <= + - * / % ~ | & ^ ; { } ( ) [ ]";
std::string tokenizer_numerals = "0123456789";
std::string tokenizer_hexNumerals = "0123456789xABCDEF";
std::string tokenizer_keywords = "return for while do if continue break switch case asm ";
std::string tokenizer_asmkeywords = "ldd ldw ldb stw stb out in jmp jmpif call callif ret cmp test vsync fsel ";
std::string tokenizer_typenames = "dword dwordptr word wordptr byte byteptr void ";

void Tokenize(std::string &_inputStream, TTokenTable &_tokenTable)
{
    // Fill _tokenTable with individual tokens and their initial types
    
    std::string str = _inputStream;

    // Strip comments
    do {
        size_t foundStart = str.find("/*");
        if (foundStart != std::string::npos)
        {
            size_t foundEnd = str.find("*/");
            str = str.substr(0, foundStart) + str.substr(foundEnd+2);
        }
        else
            break;
    } while(str.length() != 0);

    // Find words, operators and symbols
    std::regex words_and_symbols("(\\w+)|(>=)|(<=)|(==)|(!=)|(\\+\\+)|(\\-\\-)|[\"';=\\[\\]\\{\\},:\\+\\-<>~!%^&\\*\\(\\)]");
    auto words_begin = std::sregex_iterator(str.begin(), str.end(), words_and_symbols);
    auto words_end = std::sregex_iterator();
    for (std::sregex_iterator i=words_begin; i!=words_end; ++i)
    {
        std::smatch match = *i;
        std::string token = match.str();

        STokenEntry tokenEntry;
        tokenEntry.m_Value = token;
        tokenEntry.m_Type = TK_Identifier;

        // Token is numeric if first character is numeric
        if (tokenizer_numerals.find_first_of(token[0]) != std::string::npos)
            tokenEntry.m_Type = TK_LitNumeric;

        std::string tokenaswholeword = token+" ";
        if (tokenizer_keywords.find(tokenaswholeword) != std::string::npos)
            tokenEntry.m_Type = TK_Keyword;
        if (tokenizer_asmkeywords.find(tokenaswholeword) != std::string::npos)
            tokenEntry.m_Type = TK_AsmKeyword;
        if (tokenizer_typenames.find(tokenaswholeword) != std::string::npos)
            tokenEntry.m_Type = TK_Typename;
        if (tokenizer_operators.find(token) != std::string::npos)
            tokenEntry.m_Type = TK_Operator;
        if (tokenizer_symbols.find(token) != std::string::npos)
            tokenEntry.m_Type = TK_Symbol;

        if(token == "!")
            tokenEntry.m_Type = TK_OpLogicNegate;
        if(token == "=")
            tokenEntry.m_Type = TK_OpAssignment;

        if(token == "==")
            tokenEntry.m_Type = TK_OpCmpEqual;
        if(token == "<")
            tokenEntry.m_Type = TK_OpCmpLess;
        if(token == ">")
            tokenEntry.m_Type = TK_OpCmpGreater;
        if(token == "!=")
            tokenEntry.m_Type = TK_OpCmpNotEqual;
        if(token == ">=")
            tokenEntry.m_Type = TK_OpCmpGreaterEqual;
        if(token == "<=")
            tokenEntry.m_Type = TK_OpCmpLessEqual;

        if(token == "+")
            tokenEntry.m_Type = TK_OpAdd;
        if(token == "-")
            tokenEntry.m_Type = TK_OpSub;
        if(token == "*")
            tokenEntry.m_Type = TK_OpMul;
        if(token == "/")
            tokenEntry.m_Type = TK_OpDiv;
        if(token == "%")
            tokenEntry.m_Type = TK_OpMod;

        if(token == "~")
            tokenEntry.m_Type = TK_OpBitNot;
        if(token == "|")
            tokenEntry.m_Type = TK_OpBitOr;
        if(token == "&")
            tokenEntry.m_Type = TK_OpBitAnd;
        if(token == "^")
            tokenEntry.m_Type = TK_OpBitXor;

        if(token == ";")
            tokenEntry.m_Type = TK_EndStatement;

        if(token == "{")
            tokenEntry.m_Type = TK_BeginBlock;
        if(token == "}")
            tokenEntry.m_Type = TK_EndBlock;
        if(token == "(")
            tokenEntry.m_Type = TK_BeginParams;
        if(token == ")")
            tokenEntry.m_Type = TK_EndParams;
        if(token == "[")
            tokenEntry.m_Type = TK_BeginArray;
        if(token == "]")
            tokenEntry.m_Type = TK_EndArray;

        if(token == ",")
            tokenEntry.m_Type = TK_Separator;

        _tokenTable.emplace_back(tokenEntry);
    }
}

// ---------------------------------------------------------------------------
// Syntax analyzer
// Convert tokens to abstract syntax tree
// ---------------------------------------------------------------------------

void ParseAndGenerateAST(TTokenTable &_tokenTable, TAbstractSyntaxTree &_ast, SParserState &state, uint32_t &currentToken, SASTNode *_payload)
{
    // statement ----------> typename identifier ;
    //                       typename identifier [ numericliteral ] ;
    //                       typename identifier = expression ;
    //                       identifier = expression ;
    //                       if (expression) statement
    //                       for (optionalexpression ; optionalexpression ; optionalexpression) statement
    //                       if (expression) statement else statement
    //                       while (expression) statement
    //                       do statement while (expression) ;
    //                       { statements }
    // optionalexpression -> expression
    //                       ?
    // statements ---------> statements statement
    //                       ?
    // expression ---------> expression term

    // Statement mode
    if (state == PS_Statement)
    {
        // 1) typename identifier
        {
            bool is_typename = _tokenTable[currentToken].m_Type == TK_Typename;
            bool is_identifier = _tokenTable[currentToken+1].m_Type == TK_Identifier;
            if (is_typename && is_identifier)
            {
                // DECL(type, identifier)
                SASTNode node;
                // Self is variable name
                node.m_Self.m_Value = "DECL";
                node.m_Self.m_Type = NT_VariableDeclaration;
                // Type on left node
                node.m_Left = new SASTNode();
                node.m_Left->m_Self.m_Value = _tokenTable[currentToken].m_Value;
                node.m_Left->m_Self.m_Type = NT_TypeName;
                // Element count on left of left node
                node.m_Left->m_Left = new SASTNode();
                node.m_Left->m_Left->m_Self.m_Value = "1";
                node.m_Left->m_Left->m_Self.m_Type = NT_LiteralConstant;
                // Identifier on right node
                node.m_Right = new SASTNode();
                node.m_Right->m_Self.m_Value = _tokenTable[currentToken+1].m_Value;
                node.m_Right->m_Self.m_Type = NT_Identifier;
                // Store
                _ast.emplace_back(node);
                currentToken += 2;

                // expected ; or , or )
                bool is_endstatement = _tokenTable[currentToken].m_Type == TK_EndStatement;
                // or expected =
                bool is_assignment = _tokenTable[currentToken].m_Type == TK_OpAssignment;
                // or expected [
                bool is_beginarray = _tokenTable[currentToken].m_Type == TK_BeginArray;
                // or expected (
                bool is_beginparams = _tokenTable[currentToken].m_Type == TK_BeginParams;

                // typename identifier ;
                if (is_endstatement)
                {
                    // Advance
                    currentToken++;
                    return;
                }

                // Update array size
                std::string variableName = "";
                if (is_beginarray)
                {
                    node.m_Left->m_Left->m_Self.m_Value = _tokenTable[currentToken+1].m_Value;
                    currentToken+=3;
                    is_assignment = _tokenTable[currentToken].m_Type == TK_OpAssignment;
                    variableName = _tokenTable[currentToken-4].m_Value;
                }
                else
                {
                    variableName = _tokenTable[currentToken-1].m_Value;
                }
                

                // typename identifier = expression ;
                if (is_assignment)
                {
                    // ASSIGN(identifier, expression)
                    SASTNode nodeAssign;
                    nodeAssign.m_Self.m_Value = "ASSIGN";
                    nodeAssign.m_Self.m_Type = NT_OpAssignment;
                    // Left: identifier
                    nodeAssign.m_Left = new SASTNode();
                    nodeAssign.m_Left->m_Self.m_Value = variableName;
                    nodeAssign.m_Left->m_Self.m_Type = NT_Identifier;
                    // Right: Resume parsing expression into right node
                    nodeAssign.m_Right = new SASTNode();
                    state = PS_Expression;
                    currentToken++; // Skip assignment operator and parse the expression
                    ParseAndGenerateAST(_tokenTable, _ast, state, currentToken, nodeAssign.m_Right);
                    // Store
                    _ast.emplace_back(nodeAssign);

                    // Skip the endstatement
                    bool is_endstatement = _tokenTable[currentToken].m_Type == TK_EndStatement;
                    if (is_endstatement)
                    {
                        // Back to statement
                        state = PS_Statement;
                        ++currentToken;
                    }
                    else
                        std::cout << "Statement not terminated after assignment" << std::endl;
                    return;
                }
            }
        }

        // Unknown
        {
            ++currentToken;
            return;
        }
    }

    while (state == PS_Expression)
    {
        // 0) end of statement or separator
        {
            bool is_endstatement = _tokenTable[currentToken].m_Type == TK_EndStatement;
            if (is_endstatement)
            {
                state = PS_Statement;
                ++currentToken;
                return;
            }
        }

        // 1) expression term
        {
            //bool is_identifier = _tokenTable[currentToken+1].m_Type == TK_Identifier;
            bool is_string = _tokenTable[currentToken].m_Type == TK_LitString;
            bool is_numeric = _tokenTable[currentToken].m_Type == TK_LitNumeric;
            if (is_string || is_numeric)
            {
                if (!_payload)
                {
                    std::cout << "ERROR: Found standalone expression" << std::endl;
                    return;
                }

                _payload->m_Self.m_Value += _tokenTable[currentToken].m_Value + " ";
                _payload->m_Self.m_Type = NT_LiteralConstant;
            }
        }

        ++currentToken;
    }
}

// ---------------------------------------------------------------------------
// Semantic analyzer
// Apply type conversion / type checking / language rule checking on the AST
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Intermediate code generator
// Three address code generation from the analyzed AST
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Intermediate code optimizer
// Reduce code to simpler form by removing redundant assignments
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Machine code generator
// Convert to machine instructions
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Machine code optimizer
// Apply machine optimization rules
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// Compiler driver
// ---------------------------------------------------------------------------

static const char *s_typeAsString[]=
{
    // Initial basic types
    "Unknown",
    "Identifier",
    "LitNumeric",
    "LitString",
    "Symbol",
    "Operator",

    // Further expanded types
    "Keyword",
    "AsmKeyword",
    "Typename",

    "OpLogicNegate",
    "OpAssignment",

    "OpCmpEqual",
    "OpCmpLess",
    "OpCmpGreater",
    "OpCmpNotEqual",
    "OpCmpGreaterEqual",
    "OpCmpLessEqual",

    "OpAdd",
    "OpSub",
    "OpMul",
    "OpDiv",
    "OpMod",

    "OpBitNot",
    "OpBitOr",
    "OpBitAnd",
    "OpBitXor",

    "EndStatement",

    "BeginBlock",
    "EndBlock",
    "BeginParams",
    "EndParams",
    "BeginArray",
    "EndArray",

    "Separator",
};

void DebugDumpAST(SASTNode &_root)
{
    if (_root.m_Left && _root.m_Right)
    {
        std::cout << _root.m_Self.m_Value << "(";
        DebugDumpAST(*_root.m_Left);
        std::cout << ",";
        DebugDumpAST(*_root.m_Right);
        std::cout << ") ";
    }
    else if (_root.m_Left)
    {
        std::cout << _root.m_Self.m_Value << "(";
        DebugDumpAST(*_root.m_Left);
        std::cout << ") ";
    }
    else if (_root.m_Right)
    {
        std::cout << _root.m_Self.m_Value << "(,";
        DebugDumpAST(*_root.m_Right);
        std::cout << ") ";
    }
    else
    {
        std::cout << _root.m_Self.m_Value;
    }
}

int CompileCode(char *_inputname, char *_outputname)
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
    char *filedata = new char[filebytesize+1];
    fread(filedata, 1, filebytesize, inputfile);
    fclose(inputfile);

    filedata[filebytesize] = 0;
    std::string filecontents = std::string(filedata);
    TTokenTable tokentable;
    Tokenize(filecontents, tokentable); 

#if defined(DEBUG)
    std::cout << "Tokens" << std::endl;
    for(auto &t : tokentable)
    {
        std::cout << s_typeAsString[t.m_Type] << ":" << t.m_Value << " ";
        if (t.m_Type == TK_EndStatement)
            std::cout << std::endl;
    }
    std::cout << std::endl;
#endif

    TAbstractSyntaxTree ast;
    // Start with 'statement' state at token 0
    SParserState state = PS_Statement;
    uint32_t tokenIndex = 0;
    while (tokenIndex < tokentable.size())
    {
        ParseAndGenerateAST(tokentable, ast, state, tokenIndex, nullptr);
    }

#if defined(DEBUG)
    std::cout << "AST" << std::endl;
    for(auto &node : ast)
    {
        DebugDumpAST(node);
        std::cout << std::endl;
    }
#endif

    return 0;
}
