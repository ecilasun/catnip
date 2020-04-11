#include "compiler.h"

// ---------------------------------------------------------------------------
// Lexical analyzer
// Convert text stream to tokens
// ---------------------------------------------------------------------------

std::string tokenizer_whitespace = " \r\n\t";
std::string tokenizer_letters = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVQXYZ";
std::string tokenizer_symbols = "<>!=,;{}()[]+-*%^/\\'#@&|\":";
std::string tokenizer_numerals = "0123456789";
std::string tokenizer_hexNumerals = "0123456789xABCDEF";
std::string tokenizer_keywords = "return for while do if continue break switch case asm";
std::string tokenizer_asmkeywords = "ldd ldw ldb stw stb out in jmp jmpif call callif ret cmp test vsync fsel";
std::string tokenizer_typenames = "dword dwordptr word wordptr byte byteptr void";

void TokenizeSkipWhiteSpace(std::string &_input, std::string &_output)
{
    if (_input.length() == 0)
    {
        _output = "";
        return;
    }

    std::string::size_type found = 0;
    found = _input.find_first_not_of(tokenizer_whitespace);
    if (found != std::string::npos)
        _output = _input.substr(found);
    else
        _output = "";
}

void TokenizeSkipComment(std::string &_input, std::string &_output)
{
    if (_input.length() == 0)
    {
        _output = "";
        return;
    }

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

void TokenizeNextToken(std::string &_input, std::string &_token, std::string::size_type &_offset, ETokenType &_tokenType)
{
    if (_input.length() == 0)
    {
        _token = "";
        _tokenType = TK_Unknown;
        _offset = std::string::npos;
        return;
    }

    std::string::size_type foundstart = 0;
    if (tokenizer_letters.find_first_of(_input[0]) != std::string::npos)
    {
        // Was a letter, continue until not a letter
        std::string::size_type foundend = 0;
        foundend = _input.find_first_not_of(tokenizer_letters, foundstart);
        _token = _input.substr(foundstart, foundend);
        _tokenType = TK_Identifier;
        _offset = foundend;
    }
    else
    {
        if (tokenizer_symbols.find_first_of(_input[0]) != std::string::npos)
        {
            if (_input[0] == '\"')
            {
                std::string::size_type foundend = 0;
                foundend = _input.find_first_not_of("\n", foundstart);
                _token = _input.substr(foundstart, foundend);
                _tokenType = TK_LitString;
                _offset = foundend;
            }
            else
            {
                // Was any other symbol apart from string quotes, continue until not a symbol
                std::string::size_type foundend = 0;
                // Symbols might be concatenated such as '==' or '+=' etc
                foundend = _input.find_first_not_of(tokenizer_symbols, foundstart);
                _token = _input.substr(foundstart, foundend);
                _tokenType = TK_Symbol;
                _offset = foundend;
            }
        }
        else
        {
            if (tokenizer_numerals.find_first_of(_input[0]) != std::string::npos)
            {
                // Was a numeral, continue until not a symbol
                std::string::size_type foundend = 0;
                foundend = _input.find_first_not_of(tokenizer_hexNumerals, foundstart);
                _token = _input.substr(foundstart, foundend);
                _tokenType = TK_LitNumeric;
                _offset = foundend;
            }
            else
            {
                _token = "";
                _tokenType = TK_Unknown;
                _offset = std::string::npos;
            }
        }
    }
}

void Tokenize(std::string &_inputStream, TTokenTable &_tokenTable)
{
    // Fill _tokenTable with individual tokens and their initial types
    
    std::string str = _inputStream;

    // Generate initial tokens and basic types
    bool done = false;
    while (str.length() != 0)
    {
        TokenizeSkipWhiteSpace(str, str);
        TokenizeSkipComment(str, str);

        std::string token;
        std::string::size_type offset;
        ETokenType tokenType;
        TokenizeSkipWhiteSpace(str, str);
        TokenizeNextToken(str, token, offset, tokenType);

        if (offset == std::string::npos)
            break;
        str = str.substr(offset);

        // Place each token into the token table
        // disregarding any syntax rules
        STokenEntry tokenEntry;
        tokenEntry.m_Type = tokenType;
        tokenEntry.m_Value = token;
        _tokenTable.emplace_back(tokenEntry);
    }

    // Loop further to refine token types
    for (auto &t : _tokenTable)
    {
        if(t.m_Type == TK_Symbol && t.m_Value == ";")
            t.m_Type = TK_EndStatement;
        if(t.m_Type == TK_Symbol && t.m_Value == "=")
            t.m_Type = TK_OpAssignment;
        if(t.m_Type == TK_Symbol && t.m_Value == "==")
            t.m_Type = TK_OpCmpEqual;
        if(t.m_Type == TK_Symbol && t.m_Value == "<")
            t.m_Type = TK_OpCmpLess;
        if(t.m_Type == TK_Symbol && t.m_Value == ">")
            t.m_Type = TK_OpCmpGreater;
        if(t.m_Type == TK_Symbol && t.m_Value == "!=")
            t.m_Type = TK_OpCmpNotEqual;
        if(t.m_Type == TK_Symbol && t.m_Value == ">=")
            t.m_Type = TK_OpCmpGreaterEqual;
        if(t.m_Type == TK_Symbol && t.m_Value == "<=")
            t.m_Type = TK_OpCmpLessEqual;

        if (tokenizer_keywords.find(t.m_Value) != std::string::npos)
            t.m_Type = TK_Keyword;
        if (tokenizer_asmkeywords.find(t.m_Value) != std::string::npos)
            t.m_Type = TK_AsmKeyword;
        if (tokenizer_typenames.find(t.m_Value) != std::string::npos)
            t.m_Type = TK_Typename;
    }
}

// ---------------------------------------------------------------------------
// Syntax analyzer
// Convert tokens to abstract syntax tree
// ---------------------------------------------------------------------------

void ParseAndGenerateAST(TTokenTable &_tokenTable, TAbstractSyntaxTree &_ast, SParserState &state, uint32_t &currentToken, SASTNode *_payload)
{
    // statement ----------> typename identifier ;
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
        // 1) typename identifier ;
        {
            bool is_typename = _tokenTable[currentToken].m_Type == TK_Typename;
            bool is_identifier = _tokenTable[currentToken+1].m_Type == TK_Identifier;
            bool is_endstatement = _tokenTable[currentToken+2].m_Type == TK_EndStatement;
            if (is_typename && is_identifier && is_endstatement)
            {
                SASTNode node;
                // Self is variable name
                node.m_Self.m_Value = _tokenTable[currentToken+1].m_Value;
                node.m_Self.m_Type = NT_VariableDeclaration;
                // Type on left node
                node.m_Left = new SASTNode();
                node.m_Left->m_Self.m_Value = _tokenTable[currentToken].m_Value;
                node.m_Left->m_Self.m_Type = NT_TypeName;
                // No right node
                // Store
                _ast.emplace_back(node);
                // Advance
                currentToken += 3;
            }
        }

        // 2) typename identifier = expression ;
        {
            bool is_typename = _tokenTable[currentToken].m_Type == TK_Typename;
            bool is_identifier = _tokenTable[currentToken+1].m_Type == TK_Identifier;
            bool is_assignment = _tokenTable[currentToken+2].m_Type == TK_OpAssignment;
            if (is_typename && is_identifier && is_assignment)
            {
                // Insert the declaration part
                SASTNode node;
                // Self is variable name
                node.m_Self.m_Value = _tokenTable[currentToken+1].m_Value;
                node.m_Self.m_Type = NT_VariableDeclaration;
                // Type on left node
                node.m_Left = new SASTNode();
                node.m_Left->m_Self.m_Value = _tokenTable[currentToken].m_Value; // Typename
                node.m_Left->m_Self.m_Type = NT_TypeName;
                // Assignment operation on right node
                node.m_Right = new SASTNode();
                node.m_Right->m_Self.m_Value = _tokenTable[currentToken+2].m_Value; // Assignment
                node.m_Right->m_Self.m_Type = NT_OpAssignment;
                // node.m_Right->m_Left ?

                // Resume parsing as expression
                state = PS_Expression;
                currentToken += 3;
                // Subtree will be in payload after return
                SASTNode payload;
                ParseAndGenerateAST(_tokenTable, _ast, state, currentToken, &payload);

                // Insert expression from payload on right node of right node
                node.m_Right->m_Right = new SASTNode();
                *node.m_Right->m_Right = payload;
                // Nothing on right node
                // Store
                _ast.emplace_back(node);
                // Cursor already advanced
            }
        }
    }

    if (state == PS_Expression)
    {
        // 1) expression term
        {
            bool is_string = _tokenTable[currentToken].m_Type == TK_LitString;
            bool is_numeric = _tokenTable[currentToken].m_Type == TK_LitNumeric;
            //bool is_identifier = _tokenTable[currentToken+1].m_Type == TK_Identifier;

            if (is_string || is_numeric)
            {
                if (_payload)
                {
                    _payload->m_Self.m_Value = _tokenTable[currentToken].m_Value;
                    _payload->m_Self.m_Type = NT_LiteralConstant;
                    // Advance
                    ++currentToken;
                }
                else
                {
                    std::cout << "Found standalone expression" << std::endl;
                    return;
                }
                
            }
        }
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
    // Further expanded types
    "OpAssignment",
    "OpCmpEqual",
    "OpCmpLess",
    "OpCmpGreater",
    "OpCmpNotEqual",
    "OpCmpGreaterEqual",
    "OpCmpLessEqual",
    "EndStatement",
    "Keyword",
    "AsmKeyword",
    "Typename"
};

void DebugDumpAST(SASTNode &_root)
{
    std::cout << _root.m_Self.m_Value << "(";
    if (_root.m_Left)
        DebugDumpAST(*_root.m_Left);
    std::cout << ",";
    if (_root.m_Right)
        DebugDumpAST(*_root.m_Right);
    std::cout << ") ";
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
    ParseAndGenerateAST(tokentable, ast, state, tokenIndex, nullptr);

    std::cout << "AST" << std::endl;
    for(auto &node : ast)
    {
        DebugDumpAST(node);
        std::cout << std::endl;
    }

    return 0;
}
