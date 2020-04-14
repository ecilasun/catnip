#include "compiler.h"

// ---------------------------------------------------------------------------
// Lexical analyzer
// Convert text stream to tokens
// ---------------------------------------------------------------------------

std::string tokenizer_symbols = ",;{}()\\'\":";
std::string tokenizer_operators = "! = == < > != >= <= + - * / % ~ | & ^ ; { } ( ) [ ]";
std::string tokenizer_numerals = "0123456789";
std::string tokenizer_hexNumerals = "0123456789xABCDEF";
std::string tokenizer_keywords = " return for while do if continue break switch case asm ";
std::string tokenizer_asmkeywords = " ldd ldw ldb stw stb out in jmp jmpif call callif ret cmp test vsync fsel ";
std::string tokenizer_typenames = " dword dwordptr word wordptr byte byteptr void ";

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

        std::string tokenaswholeword = " "+token+" ";
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

void ReportError(SASTContext * _context, TTokenTable &_tokenTable, uint32_t _currentToken, const char *_message)
{
    int K = _currentToken;
    while (K>0 && _tokenTable[K].m_Type != TK_EndStatement && _tokenTable[K].m_Type != TK_BeginBlock)
        --K;
    _context->m_ErrorString = "------------------------------ERROR---------------------------------------------------\n" + std::string(_message) + ":\n";
    for (int i=K+1;i<=_currentToken;++i)
            _context->m_ErrorString += _tokenTable[i].m_Value+" ";
    _context->m_ErrorString += "\n--------------------------------------------------------------------------------------";
    _context->m_HasError++;
}

// ---------------------------------------------------------------------------
// Syntax analyzer
// Convert tokens to abstract syntax tree
// ---------------------------------------------------------------------------

void ParseAndGenerateAST(TTokenTable &_tokenTable, TAbstractSyntaxTree &_ast, SParserState &state, uint32_t &currentToken, SASTContext *_context)
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
    //                       (empty)
    // statements ---------> statements statement
    //                       (empty)
    // expression ---------> expression term

    // EXPRESSION
    while (state == PS_Expression)
    {
        if (_context->m_AssignmentTargetNode == nullptr)
        {
            ReportError(_context, _tokenTable, currentToken, "There's nowhere for this expression to go");
            return;
        }

        // ;
        bool is_endstatement = _tokenTable[currentToken].m_Type == TK_EndStatement;
        // )
        bool is_endparams = _tokenTable[currentToken].m_Type == TK_EndParams;
        // ]
        bool is_endarray = _tokenTable[currentToken].m_Type == TK_EndArray;

        if (is_endstatement || is_endparams || is_endarray)
        {
            ++currentToken;

            if (_context->m_LHS != "")
            {
                SASTNode *nodeOp = _context->m_AssignmentTargetNode;
                nodeOp->m_Self.m_Value = _context->m_LHS;                                 // Leftovers
                nodeOp->m_Self.m_Type = NT_Unknown;
            }

            // Expecting: STATEMENT
            state = PS_Statement;
            return;
        }

        // +
        bool is_opadd = _tokenTable[currentToken].m_Type == TK_OpAdd;
        // -
        bool is_opsub = _tokenTable[currentToken].m_Type == TK_OpSub;
        // *
        bool is_opmul = _tokenTable[currentToken].m_Type == TK_OpMul;
        // /
        bool is_opdiv = _tokenTable[currentToken].m_Type == TK_OpDiv;

        if (is_opadd || is_opsub || is_opmul || is_opdiv)
        {
            ++currentToken;

            if (_context->m_AssignmentTargetNode)
            {
                SASTNode *nodeOp = _context->m_AssignmentTargetNode;
                nodeOp->m_Self.m_Value = "BINOP";                                         // Binary Operator
                nodeOp->m_Self.m_Type = NT_BinaryOperator;
                nodeOp->m_Left = new SASTNode();                                          // TypeName
                nodeOp->m_Left->m_Self.m_Value = _context->m_LHS;
                nodeOp->m_Left->m_Self.m_Type = NT_TypeName;
                nodeOp->m_Right = new SASTNode();                                         // FunctionName
                nodeOp->m_Right->m_Self.m_Value = "";
                nodeOp->m_Right->m_Self.m_Type = NT_Unknown;

                _context->m_AssignmentTargetNode = nodeOp->m_Right;
                _context->m_LHS = "";

                continue;
            }
            else
            {
                ReportError(_context, _tokenTable, currentToken, "Malformed AST, can't write operator since the parent didn't allocate space");
                return;
            }
        }
        else
        {
            _context->m_LHS += _tokenTable[currentToken].m_Value;
        }

        ++currentToken;
    }

    // PARAMETER LIST
    while (state == PS_ParameterList)
    {
        if (_context->m_AssignmentTargetNode == nullptr)
        {
            ReportError(_context, _tokenTable, currentToken, "Can't list parameters without a valid target (please check left hand side of the statement)");
            return;
        }

        // )
        bool is_endparams = _tokenTable[currentToken].m_Type == TK_EndParams;
        // ,
        bool is_separator = _tokenTable[currentToken].m_Type == TK_Separator;

        if (is_endparams)
        {
            ++currentToken;
            // Expecting: STATEMENT
            state = PS_Statement;
            return;
        }

        if (_context->m_AssignmentTargetNode)
        {
            _context->m_AssignmentTargetNode->m_Self.m_Value += _tokenTable[currentToken].m_Value + " ";
            _context->m_AssignmentTargetNode->m_Self.m_Type = NT_Expression;
        }
        else
        {
            ReportError(_context, _tokenTable, currentToken, "Malformed AST, can't populate parameters since function definition node didn't allocate space");
            return;
        }

        ++currentToken;
    }

    // INITIALIZER LIST
    while (state == PS_InitializerList)
    {
        if (_context->m_AssignmentTargetNode == nullptr)
        {
            ReportError(_context, _tokenTable, currentToken, "Can't assign without a valid target (please check left hand side of the statement");
            return;
        }

        // ;
        bool is_endstatement = _tokenTable[currentToken].m_Type == TK_EndStatement;
        // }
        bool is_endblock = _tokenTable[currentToken].m_Type == TK_EndBlock;
        // ,
        bool is_separator = _tokenTable[currentToken].m_Type == TK_Separator;

        if (is_endstatement)
        {
            ++currentToken;
            // Expecting: STATEMENT
            state = PS_Statement;
            return;
        }

        if (!is_endblock && !is_separator)
        {
            bool is_intliteral = _tokenTable[currentToken].m_Type == TK_LitNumeric;
            if (is_intliteral)
            {
                if (_context->m_AssignmentTargetNode)
                {
                    uint32_t variablepointer = std::stoi(_context->m_AssignmentTargetNode->m_Right->m_Left->m_Self.m_Value) + _context->m_CurrentInitializerOffset;
                    uint32_t variablestride = std::stoi(_context->m_AssignmentTargetNode->m_Left->m_Right->m_Self.m_Value);

                    if (variablestride == 4) // DWORD/PTR
                    {
                        bool is_hex = _tokenTable[currentToken].m_Value.find("x") != std::string::npos;
                        unsigned long val = std::stoul(_tokenTable[currentToken].m_Value, nullptr, is_hex ? 16 : 10);
                        _context->m_VariableStore[variablepointer+0] = (val&0xFF000000)>>24;
                        _context->m_VariableStore[variablepointer+1] = (val&0x00FF0000)>>16;
                        _context->m_VariableStore[variablepointer+2] = (val&0x0000FF00)>>8;
                        _context->m_VariableStore[variablepointer+3] = (val&0x000000FF);
                    }

                    if (variablestride == 2) // WORD
                    {
                        bool is_hex = _tokenTable[currentToken].m_Value.find("x") != std::string::npos;
                        unsigned long val = std::stoul(_tokenTable[currentToken].m_Value, nullptr, is_hex ? 16 : 10);
                        if (val > 0x0000FFFF)
                        {
                            ReportError(_context, _tokenTable, currentToken, "Assigning a value larger than WORD to WORD storage");
                            return;
                        }
                        _context->m_VariableStore[variablepointer+0] = (val&0x0000FF00)>>8;
                        _context->m_VariableStore[variablepointer+1] = (val&0x000000FF);
                    }

                    if (variablestride == 1) // BYTE / CHAR
                    {
                        bool is_hex = _tokenTable[currentToken].m_Value.find("x") != std::string::npos;
                        unsigned long val = std::stoul(_tokenTable[currentToken].m_Value, nullptr, is_hex ? 16 : 10);
                        if (val > 0x000000FF)
                        {
                            ReportError(_context, _tokenTable, currentToken, "Assigning a value larger than BYTE to BYTE storage");
                            return;
                        }
                        _context->m_VariableStore[variablepointer+0] = (val&0x000000FF);
                       
                    }

                    _context->m_CurrentInitializerOffset += variablestride;
                }
                else
                {
                    ReportError(_context, _tokenTable, currentToken, "Malformed AST, can't initialize left hand side since variable is inaccessible");
                    return;
                }
            }
        }

        ++currentToken;
    }

    // STATEMENT MODE
    while (state == PS_Statement)
    {
        // ;
        bool is_endstatement = _tokenTable[currentToken].m_Type == TK_EndStatement;
        // }
        bool is_endblock = _tokenTable[currentToken].m_Type == TK_EndBlock;
        if (is_endstatement || is_endblock)
        {
            ++currentToken;
            _context->m_BlockDepth -= is_endblock ? 1 : 0;
            if (_context->m_BlockDepth<0)
            {
                ReportError(_context, _tokenTable, currentToken, "Statement block depth is negative, please check for mismatching { }");
                return;
            }
            // Reset this across statements to prevent assignment across statements
            _context->m_AssignmentTargetNode = nullptr;
            // Expecting: STATEMENT
            state = PS_Statement;
            return;
        }

        // {
        bool is_beginblock = _tokenTable[currentToken].m_Type == TK_BeginBlock;
        if (is_beginblock)
        {
            _context->m_BlockDepth++;
            ++currentToken;
            // Expecting: STATEMENT
            state = PS_Statement;
            return;
        }

        // typename
        bool is_typename = _tokenTable[currentToken].m_Type == TK_Typename;
        bool is_identifier = _tokenTable[currentToken].m_Type == TK_Identifier;
        bool is_builtin = _tokenTable[currentToken].m_Type == TK_Keyword;
        if(is_typename)
        {
            ++currentToken;

            // identifier
            is_identifier = _tokenTable[currentToken].m_Type == TK_Identifier;
            if (is_identifier)
            {
                ++currentToken;

                std::string variabledim = "1";
                std::string variablename = _tokenTable[currentToken-1].m_Value;
                std::string variabletype = _tokenTable[currentToken-2].m_Value;

                // (
                bool is_beginparams = _tokenTable[currentToken].m_Type == TK_BeginParams;
                if (is_beginparams)
                {
                    ++currentToken;

                    SASTNode nodeDef;
                    nodeDef.m_Self.m_Value = "FUNC";                                          // Function definition
                    nodeDef.m_Self.m_Type = NT_FunctionDefinition;
                    nodeDef.m_Left = new SASTNode();                                          // TypeName
                    nodeDef.m_Left->m_Self.m_Value = variabletype;
                    nodeDef.m_Left->m_Self.m_Type = NT_TypeName;
                    nodeDef.m_Right = new SASTNode();                                         // FunctionName
                    nodeDef.m_Right->m_Self.m_Value = variablename;
                    nodeDef.m_Right->m_Self.m_Type = NT_Identifier;
                    nodeDef.m_Right->m_Left = new SASTNode();
                    nodeDef.m_Right->m_Left->m_Self.m_Value = "";
                    nodeDef.m_Right->m_Left->m_Self.m_Type = NT_Unknown;
                    _ast.emplace_back(nodeDef);

                    // Target function definition to receive the parameter list
                    _context->m_AssignmentTargetNode = nodeDef.m_Right->m_Left;

                    // Gather parameters
                    state = PS_ParameterList;
                    return;
                }

                // [
                bool is_beginarray = _tokenTable[currentToken].m_Type == TK_BeginArray;
                if (is_beginarray)
                {
                    ++currentToken;

                    // numliteral
                    bool is_numlit = _tokenTable[currentToken].m_Type == TK_LitNumeric;
                    if (is_numlit)
                    {
                        ++currentToken;

                        // Set array dimension
                        variabledim = _tokenTable[currentToken-1].m_Value;

                        // ]
                        bool is_endarray = _tokenTable[currentToken].m_Type == TK_EndArray;
                        if (is_endarray)
                        {
                            ++currentToken;
                        }
                        else
                        {
                            ReportError(_context, _tokenTable, currentToken, "Expected ] after numeric literal");
                            return;
                        }
                    }
                    else
                    {
                        ReportError(_context, _tokenTable, currentToken, "Expected numeric literal after [");
                        return;
                    }
                }

                uint32_t variablestride = variabletype=="byte" ? 1 : 2;
                variablestride = (variabletype=="byteptr" || variabletype=="wordptr") ? 4 : variablestride;

                SASTNode nodeDecl;
                nodeDecl.m_Self.m_Value = "DECL";                                          // Declaration
                nodeDecl.m_Self.m_Type = NT_VariableDeclaration;
                nodeDecl.m_Left = new SASTNode();                                          // TypeName
                nodeDecl.m_Left->m_Self.m_Value = variabletype;
                nodeDecl.m_Left->m_Self.m_Type = NT_TypeName;
                nodeDecl.m_Left->m_Left = new SASTNode();                                  // Count
                nodeDecl.m_Left->m_Left->m_Self.m_Value = variabledim;
                nodeDecl.m_Left->m_Left->m_Self.m_Type = NT_LiteralConstant;
                nodeDecl.m_Left->m_Right = new SASTNode();                                 // Stride
                nodeDecl.m_Left->m_Right->m_Self.m_Value = std::to_string(variablestride);
                nodeDecl.m_Left->m_Right->m_Self.m_Type = NT_LiteralConstant;
                nodeDecl.m_Right = new SASTNode();                                         // VariableName
                nodeDecl.m_Right->m_Self.m_Value = variablename;
                nodeDecl.m_Right->m_Self.m_Type = NT_Identifier;
                nodeDecl.m_Right->m_Left = new SASTNode();                                 // VariableStorage
                nodeDecl.m_Right->m_Left->m_Self.m_Value = std::to_string(_context->m_VariableStoreCursor);
                nodeDecl.m_Right->m_Left->m_Self.m_Type = NT_VariablePointer;
                // Align cursor so that next allocation starts at a 2 byte boundary
                uint32_t alignedsize = EAlignUp(std::stoi(variabledim)*variablestride, 2);
                _context->m_VariableStoreCursor += alignedsize;

                // =
                bool is_assignop = _tokenTable[currentToken].m_Type == TK_OpAssignment;
                if (is_assignop)
                {
                    ++currentToken;

                    _context->m_AssignmentTargetNode = &nodeDecl;

                    // initializerlist
                    // Gather initializer list
                    state = PS_InitializerList;
                    _context->m_CurrentInitializerOffset = 0;
                }

                _ast.emplace_back(nodeDecl);
                return;
            }
            else
            {
                ReportError(_context, _tokenTable, currentToken, "Expected identifier after typename");
                return;
            }

            continue;
        }
        else if (is_identifier || is_builtin) // identifier / keyword
        {
            ++currentToken;

            // (
            bool is_beginparams = _tokenTable[currentToken].m_Type == TK_BeginParams;
            if (is_beginparams)
            {
                ++currentToken;

                SASTNode nodeDef;
                nodeDef.m_Self.m_Value = "CALL";                                          // Function call
                nodeDef.m_Self.m_Type = NT_FunctionDefinition;
                nodeDef.m_Left = new SASTNode();                                          // FunctionName
                nodeDef.m_Left->m_Self.m_Value = _tokenTable[currentToken-2].m_Value;
                nodeDef.m_Left->m_Self.m_Type = NT_Identifier;
                nodeDef.m_Right = new SASTNode();                                         // ReturnType
                nodeDef.m_Right->m_Self.m_Value = "";
                nodeDef.m_Right->m_Self.m_Type = NT_TypeName;
                nodeDef.m_Right->m_Left = new SASTNode();
                nodeDef.m_Right->m_Left->m_Self.m_Value = "";
                nodeDef.m_Right->m_Left->m_Self.m_Type = NT_Unknown;
                _ast.emplace_back(nodeDef);

                // Target function definition to receive the parameter list
                _context->m_AssignmentTargetNode = nodeDef.m_Right->m_Left;

                // Gather parameters
                state = PS_ParameterList;
                return;
            }

            // [
            bool is_beginarray = _tokenTable[currentToken].m_Type == TK_BeginArray;
            if (is_beginarray)
            {
                ++currentToken;

                ReportError(_context, _tokenTable, currentToken, "Array indexing not implemented yet");

                return;
            }

            // =
            bool is_assignment = _tokenTable[currentToken].m_Type == TK_OpAssignment;
            if (is_assignment)
            {
                ++currentToken;

                SASTNode nodeDecl;
                nodeDecl.m_Self.m_Value = "ASSIGN";                                        // Assignment
                nodeDecl.m_Self.m_Type = NT_VariableDeclaration;
                nodeDecl.m_Left = new SASTNode();                                          // VariableName
                nodeDecl.m_Left->m_Self.m_Value = _tokenTable[currentToken-2].m_Value;
                nodeDecl.m_Left->m_Self.m_Type = NT_OpAssignment;
                nodeDecl.m_Right = new SASTNode();                                         // Expression
                nodeDecl.m_Right->m_Self.m_Value = "";
                nodeDecl.m_Right->m_Self.m_Type = NT_Unknown;
                _ast.emplace_back(nodeDecl);

                // Target assignment op to receive the expressions
                _context->m_AssignmentTargetNode = nodeDecl.m_Right;

                _context->m_LHS = "";
                state = PS_Expression;
                return;
            }

            // BINARYOP (>= <= == != < >)
        }
        else
        {
            ReportError(_context, _tokenTable, currentToken, "Expected identifier, builtin or typename as first item of statement");
            return;
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
    SASTContext astcontext;
    astcontext.m_VariableStore = new uint8_t[65536];
    // Start with 'statement' state at token 0
    SParserState state = PS_Statement;
    uint32_t tokenIndex = 0;
    while (tokenIndex < tokentable.size())
    {
        ParseAndGenerateAST(tokentable, ast, state, tokenIndex, &astcontext);
        if (astcontext.m_HasError)
        {
            std::cout << astcontext.m_ErrorString << std::endl;
            break;
        }
    }

    if (astcontext.m_BlockDepth != 0)
    {
        ReportError(&astcontext, tokentable, tokenIndex, "Mismatching { } at the end of program");
        std::cout << astcontext.m_ErrorString << std::endl;
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
