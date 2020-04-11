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
                //foundend = _input.find_first_not_of(tokenizer_symbols, foundstart);
                // Dice symbols into one character size blocks since we don't want a batch of combinations to cope with
                foundend = 1;
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
    // TODO: Fill _tokenTable with individual tokens and their types
    
    std::string str = _inputStream;

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
        SToken tokenEntry;
        tokenEntry.m_Type = tokenType;
        tokenEntry.m_Value = token;
        _tokenTable.emplace_back(tokenEntry);
    };
}

// ---------------------------------------------------------------------------
// Syntax analyzer
// Convert tokens to abstract syntax tree
// ---------------------------------------------------------------------------

std::string ast_keywords = "return for while do if continue break switch case asm";
std::string ast_asmkeywords = "ldd ldw ldb stw stb out in jmp jmpif call callif ret cmp test vsync fsel";
std::string ast_typenames = "dword word byte void";

void GenerateAST(TTokenTable &_tokenTable, TAbstractSyntaxTree &_ast)
{
    // TODO: Fill _tokenTable with individual tokens and their types
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
    "Unknown",
    "Identifier",
    "LitNumeric",
    "LitString",
    "Symbol",
};

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
        std::cout << s_typeAsString[t.m_Type] << ":" << t.m_Value << " ";
    std::cout << std::endl;
#endif

    TAbstractSyntaxTree ast;
    GenerateAST(tokentable, ast);

#if defined(DEBUG)
    std::cout << "AST" << std::endl;
    for(auto &a : ast)
        std::cout << a.m_Self.m_Name << ":" << a.m_Self.m_Value << "(" << (a.m_Left ? a.m_Left->m_Self.m_Value : "n/a") << "," << (a.m_Right ? a.m_Right->m_Self.m_Value : "n/a") << ")" << std::endl;
    std::cout << std::endl;
#endif

    return 0;
}
