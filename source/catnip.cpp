#include <stdio.h>
#include <vector>
#include "emulator.h"

struct SAssemblerKeyword
{
    const char *m_Name;     // String to match
};

struct SParserItem
{
    unsigned int m_Index;                           // Index into the SAssemblerKeyword table
    char *m_Value;                                  // Value as string
    unsigned int m_LabelMemoryOffset = 0xFFFFFFFF;  // Recorded while scanning
};

struct SCodeBlock
{
    unsigned int m_StartAddress;
    unsigned int m_ByteCount;
    bool m_IsEmpty;
    unsigned char *m_Words;
};

std::vector<SCodeBlock> m_codeBlocks;

struct SBranchResolvePair
{
    unsigned int m_PatchAddressPointer;
    SParserItem *m_LabelToResolve;
};

struct SLEAResolvePair
{
    unsigned int m_PatchAddressPointer;
    SParserItem *m_LabelToResolve;
};

std::vector<SBranchResolvePair> m_branchResolves;
std::vector<SLEAResolvePair> m_LEAResolves;
std::vector<SLEAResolvePair> m_LDATResolves;

SParserItem *s_parser_table;
unsigned int s_num_parser_entries;
unsigned char *s_binary_output;
unsigned int s_current_binary_offset;

class CAssemblerTokenCompiler
{
public:
    //CAssemblerTokenCompiler(const char *_token, const unsigned char _opcode) : m_Token(_token), m_Opcode(_opcode) {}
    //~CAssemblerTokenCompiler(){};

    // Return value: number of parser items consumed including the current item, or -1 if there was an error
    // _parser_table: the full parser table for easy forward/back tracking
    // _current_parser_offset: index into the current item for which this function is invoked
    // _binary_output: full binary blob being written to for easy backtracking for code patching
    // _current_binary_offset: write cursor for current instruction word sequence
    virtual int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) = 0;

    const char *m_Token;
    unsigned short m_Opcode;
};

// Binary code output origin
// NOTE: when changing origin, all words in between the old origin and new origin will be dumped to output and might contain garbage data!
class COriginOp : public CAssemblerTokenCompiler
{
public:
    COriginOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: NONE - @ORG 0xHHHHH
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        unsigned int org = 0;
        sscanf(_parser_table[_current_parser_offset+1].m_Value, "%x", &org);
        _current_binary_offset = org;
        return 2;
    }
};

// Emit data words
class CDataWordOp : public CAssemblerTokenCompiler
{
public:
    CDataWordOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: NONE - @DW [0xHHHH 0xHHHH ...]
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        int i = _current_parser_offset+1;
        do
        {
            unsigned int db = 0;
            sscanf(_parser_table[i].m_Value, "%x", &db);
            _binary_output[_current_binary_offset++] = ((uint16_t)(db&0x0000FF00))>>8;
            _binary_output[_current_binary_offset++] = (uint16_t)(db&0x000000FF);
            ++i;
        } while(_parser_table[i].m_Index == -1);

        return i-_current_parser_offset;
    }
};

// Branch target or address marker
class CLabelOp : public CAssemblerTokenCompiler
{
public:
    CLabelOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: NONE - @LABEL labelname
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        //printf("Code label %s\n", _parser_table[_current_parser_offset+1].m_Value);
        // Stash the current binray offset so that we can fetch it later on
        _parser_table[_current_parser_offset].m_LabelMemoryOffset = _current_binary_offset;
        return 2;
    }
};

// Logic operators or/and/xor/not/bsl/bsr
class CLogicOpOr : public CAssemblerTokenCompiler
{
public:
    CLogicOpOr(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00000
    // SUBINSTRUCTION: 0x0000
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        int r1=0, r2=0, r3=0;
        sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
        sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r2);
        sscanf(_parser_table[_current_parser_offset+3].m_Value, "r%d", &r1);
        unsigned short code = m_Opcode | 0x0000 | (r1<<7) | (r2<<10) | (r3<<13);
        _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = code&0x00FF;
        return 4;
    }
};

class CLogicOpAnd : public CAssemblerTokenCompiler
{
public:
    CLogicOpAnd(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00000
    // SUBINSTRUCTION: 0x0010
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        int r1=0, r2=0, r3=0;
        sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
        sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r2);
        sscanf(_parser_table[_current_parser_offset+3].m_Value, "r%d", &r1);
        unsigned short code = m_Opcode | 0x0010 | (r1<<7) | (r2<<10) | (r3<<13);
        _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = code&0x00FF;
        return 4;
    }
};

class CLogicOpXor : public CAssemblerTokenCompiler
{
public:
    CLogicOpXor(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00000
    // SUBINSTRUCTION: 0x0020
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        int r1=0, r2=0, r3=0;
        sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
        sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r2);
        sscanf(_parser_table[_current_parser_offset+3].m_Value, "r%d", &r1);
        unsigned short code = m_Opcode | 0x0020 | (r1<<7) | (r2<<10) | (r3<<13);
        _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = code&0x00FF;
        return 4;
    }
};

class CLogicOpNot : public CAssemblerTokenCompiler
{
public:
    CLogicOpNot(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00000
    // SUBINSTRUCTION: 0x0030
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        int r1=0, r2=0, r3=0;
        sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
        sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r1);
        unsigned short code = m_Opcode | 0x0030 | (r1<<7) | (r2<<10) | (r3<<13);
        _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = code&0x00FF;
        return 3;
    }
};

class CLogicOpBsl : public CAssemblerTokenCompiler
{
public:
    CLogicOpBsl(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00000
    // SUBINSTRUCTION: 0x0040
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        int r1=0, r2=0, r3=0;
        sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
        sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r1);
        sscanf(_parser_table[_current_parser_offset+3].m_Value, "r%d", &r2);
        unsigned short code = m_Opcode | 0x0040 | (r1<<7) | (r2<<10) | (r3<<13);
        _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = code&0x00FF;
        return 4;
    }
};

class CLogicOpBsr : public CAssemblerTokenCompiler
{
public:
    CLogicOpBsr(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00000
    // SUBINSTRUCTION: 0x0050
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        int r1=0, r2=0, r3=0;
        sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
        sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r1);
        sscanf(_parser_table[_current_parser_offset+3].m_Value, "r%d", &r2);
        unsigned short code = m_Opcode | 0x0050 | (r1<<7) | (r2<<10) | (r3<<13);
        _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = code&0x00FF;
        return 4;
    }
};

class CLogicOpBswap : public CAssemblerTokenCompiler
{
public:
    CLogicOpBswap(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00000
    // SUBINSTRUCTION: 0x0060
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        int r1=0, r2=0, r3=0;
        sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);
        sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r3);
        unsigned short code = m_Opcode | 0x0060 | (r1<<7) | (r2<<10) | (r3<<13);
        _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = code&0x00FF;
        return 3;
    }
};

class CLogicOpNoop : public CAssemblerTokenCompiler
{
public:
    CLogicOpNoop(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00000
    // SUBINSTRUCTION: 0x0000 (equal to or r0,r0,r0)
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        _binary_output[_current_binary_offset++] = 0x00;
        _binary_output[_current_binary_offset++] = 0x00;
        return 1;
    }
};

// Branch ops
class CBranchOp : public CAssemblerTokenCompiler
{
public:
    CBranchOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00001
    // jmp 0x0000 : short jump to label address in IP+1
    // jmp r1:r2 : jump to address in r1:r2
    // jmpif 0x0000 : short jump to label address in IP+1 if TR==1
    // jmpif r1:r2 : jump to address in r1:r2 if TR==1
    // branch r1:r2 : push IP+1 to branch stack, branch to address in r1:r2
    // branchif r1:r2 : push IP+1 to branch stack, branch to address in r1:r2 if TR==1
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        // Long jump or branch
        bool is_conditional = false;
        bool is_branch = false;
        if (_parser_table[_current_parser_offset+1].m_Value[0] == 'r')
        {
            if (strcmp(_parser_table[_current_parser_offset].m_Value, "jmp")==0)
                ;//printf("Long jump to register pair: %s:%s\n", _parser_table[_current_parser_offset+1].m_Value, _parser_table[_current_parser_offset+2].m_Value);
            if (strcmp(_parser_table[_current_parser_offset].m_Value, "jmpif")==0)
            {
                is_conditional = true;
                //printf("Long jump to register pair if TR==1: %s:%s\n", _parser_table[_current_parser_offset+1].m_Value, _parser_table[_current_parser_offset+2].m_Value);
            }
            if (strcmp(_parser_table[_current_parser_offset].m_Value, "branch")==0)
                is_branch = true;//printf("Long branch to register pair: %s:%s\n", _parser_table[_current_parser_offset+1].m_Value, _parser_table[_current_parser_offset+2].m_Value);
            if (strcmp(_parser_table[_current_parser_offset].m_Value, "branchif")==0)
            {
                is_branch = true;
                is_conditional = true;
                //printf("Long branch to register pair if TR==1: %s:%s\n", _parser_table[_current_parser_offset+1].m_Value, _parser_table[_current_parser_offset+2].m_Value);
            }

            int r1, r2;
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r2);
            unsigned short code = m_Opcode | (r1<<8) | (r2<<11) | (is_conditional ? 0x0010 : 0x0000) | (is_branch ? 0x4000 : 0x0000);
            _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
            _binary_output[_current_binary_offset++] = code&0x00FF;
            return 3;
        }
        else
        {
            if (strcmp(_parser_table[_current_parser_offset].m_Value, "jmp")==0)
                ;//printf("Short jump to address: %s\n", _parser_table[_current_parser_offset+1].m_Value);
            if (strcmp(_parser_table[_current_parser_offset].m_Value, "jmpif")==0)
            {
                is_conditional = true;
                ;//printf("Short jump to address if TR==1: %s\n", _parser_table[_current_parser_offset+1].m_Value);
            }
            if (strcmp(_parser_table[_current_parser_offset].m_Value, "branch")==0)
                is_branch = true;//printf("Long branch to register pair: %s:%s\n", _parser_table[_current_parser_offset+1].m_Value, _parser_table[_current_parser_offset+2].m_Value);
            if (strcmp(_parser_table[_current_parser_offset].m_Value, "branchif")==0)
            {
                is_branch = true;
                is_conditional = true;
                //printf("Long branch to register pair if TR==1: %s:%s\n", _parser_table[_current_parser_offset+1].m_Value, _parser_table[_current_parser_offset+2].m_Value);
            }

            // Scan from start of code for the given label
            //unsigned int branchtarget = 0;
            unsigned int targetfound = 0;
            for (unsigned int i=0; i<s_num_parser_entries; ++i)
            {
                if (strcmp(_parser_table[i].m_Value, "@LABEL") == 0 && i!=_current_parser_offset)
                {
                    if (strcmp(_parser_table[i+1].m_Value, _parser_table[_current_parser_offset+1].m_Value)==0)
                    {
                        // Store unresolved labels for later resolve
                        //if (_parser_table[i].m_LabelMemoryOffset == 0xFFFFFFFF)
                        {
                            SBranchResolvePair postResolve;
                            postResolve.m_PatchAddressPointer = _current_binary_offset+2;
                            postResolve.m_LabelToResolve = &_parser_table[i];
                            m_branchResolves.emplace_back(postResolve);
                        }
                        //branchtarget = _parser_table[i].m_LabelMemoryOffset; // For unresolved labels this is 0xFFFFFFFF
                        ++targetfound;
                        break;
                    }
                }
            }
            if (targetfound==0)
                printf("Branch target not found: %s\n", _parser_table[_current_parser_offset+1].m_Value);

            unsigned short code = m_Opcode | 0x8000 | (is_conditional ? 0x0010 : 0x0000) | (is_branch ? 0x4000 : 0x0000);

            _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
            _binary_output[_current_binary_offset++] = code&0x00FF;

            // Dummy target
            _binary_output[_current_binary_offset++] = 0xFF;
            _binary_output[_current_binary_offset++] = 0xFF;
            _binary_output[_current_binary_offset++] = 0xFF;
            _binary_output[_current_binary_offset++] = 0xFF;

            return 2;
        }
    }
};

// Math operators or/and/xor/not/bsl/bsr
class CMathOp : public CAssemblerTokenCompiler
{
public:
    CMathOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00002
    // iadd r0,r1,r2 : r0=r1+r2
    // isub r0,r1,r2 : r0=r1-r2
    // imul r0,r1,r2 : r0=r1*r2
    // idiv r0,r1,r2 : r0=r1/r2
    // imod r0,r1,r2 : r0=r1%r2
    // ineg r0 : r0=~r0
    // inc r0 : r0++
    // dec r0 : r0--
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        // Single parameter

        unsigned short marker = m_Opcode;
        int step = 4;

        int r1=0, r2=0, r3=0;

        if (strcmp(_parser_table[_current_parser_offset].m_Value, "iadd") == 0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r1);
            sscanf(_parser_table[_current_parser_offset+3].m_Value, "r%d", &r2);
            marker |= 0x0000;
        }
        if (strcmp(_parser_table[_current_parser_offset].m_Value, "isub") == 0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r1);
            sscanf(_parser_table[_current_parser_offset+3].m_Value, "r%d", &r2);
            marker |= 0x0010;
        }
        if (strcmp(_parser_table[_current_parser_offset].m_Value, "imul") == 0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r1);
            sscanf(_parser_table[_current_parser_offset+3].m_Value, "r%d", &r2);
            marker |= 0x0020;
        }
        if (strcmp(_parser_table[_current_parser_offset].m_Value, "idiv") == 0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r1);
            sscanf(_parser_table[_current_parser_offset+3].m_Value, "r%d", &r2);
            marker |= 0x0030;
        }
        if (strcmp(_parser_table[_current_parser_offset].m_Value, "imod") == 0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r1);
            sscanf(_parser_table[_current_parser_offset+3].m_Value, "r%d", &r2);
            marker |= 0x0040;
        }
        if (strcmp(_parser_table[_current_parser_offset].m_Value, "ineg") == 0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);
            marker |= 0x0050;
            step = 2;
            //printf("negate register %s\n", _parser_table[_current_parser_offset+1].m_Value);
        }
        if (strcmp(_parser_table[_current_parser_offset].m_Value, "inc") == 0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);
            marker |= 0x0060;
            step = 2;
            //printf("increment register %s\n", _parser_table[_current_parser_offset+1].m_Value);
        }
        if (strcmp(_parser_table[_current_parser_offset].m_Value, "dec") == 0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);
            marker |= 0x0070;
            step = 2;
            //printf("decrement register %s\n", _parser_table[_current_parser_offset+1].m_Value);
        }

        unsigned short code = marker | (r1<<7) | (r2<<10) | (r3<<13);
        _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = code&0x00FF;

        return step;
    }
};

class CLeaOp : public CAssemblerTokenCompiler
{
public:
    CLeaOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // Not a real instruction
    // Decodes into two individual MOV instuctions
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        int r1=0, r2=0;
        sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d:r%d", &r1,&r2);
        uint32_t extra_dword = 0;
        if (strstr(_parser_table[_current_parser_offset+2].m_Value, "0x"))
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "%x", &extra_dword);
        else
        {
            extra_dword = 0xFFFFFFFF; // To be patched later.

            bool labelfound = false;
            for (unsigned int i=0; i<s_num_parser_entries; ++i)
            {
                if (strcmp(_parser_table[i].m_Value, "@LABEL") == 0 && i!=_current_parser_offset)
                {
                    if (strcmp(_parser_table[i+1].m_Value, _parser_table[_current_parser_offset+2].m_Value)==0)
                    {
                        labelfound = true;
                        SLEAResolvePair postResolve;
                        postResolve.m_PatchAddressPointer = _current_binary_offset+2; // and also +6
                        postResolve.m_LabelToResolve = &_parser_table[i];
                        m_LEAResolves.emplace_back(postResolve);
                    }
                }
            }
            if (labelfound == false)
                printf("ERROR: label not found for LEA intrinsic.\n");
        }

        unsigned int code = 0x03; // W2R
        unsigned short gencode;
        gencode = m_Opcode | (code<<4) | (r1<<7);
        _binary_output[_current_binary_offset++] = (gencode&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = gencode&0x00FF;
        _binary_output[_current_binary_offset++] = (extra_dword&0xFF000000)>>24;
        _binary_output[_current_binary_offset++] = (extra_dword&0x00FF0000)>>16;
        gencode = m_Opcode | (code<<4) | (r2<<7);
        _binary_output[_current_binary_offset++] = (gencode&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = gencode&0x00FF;
        _binary_output[_current_binary_offset++] = (extra_dword&0x0000FF00)>>8;
        _binary_output[_current_binary_offset++] = (extra_dword&0x000000FF);

        return 3;
    }
};

class CLdatOp : public CAssemblerTokenCompiler
{
public:
    CLdatOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // Not a real instruction
    // Decodes into two individual MOV instuctions
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        int r1=0, r2=0;
        sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d:r%d", &r1,&r2);
        uint32_t extra_dword = 0;
        if (strstr(_parser_table[_current_parser_offset+2].m_Value, "0x"))
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "%x", &extra_dword);
        else
        {
            extra_dword = 0xFFFFFFFF; // To be patched later.

            bool labelfound = false;
            for (unsigned int i=0; i<s_num_parser_entries; ++i)
            {
                if (strcmp(_parser_table[i].m_Value, "@LABEL") == 0 && i!=_current_parser_offset)
                {
                    if (strcmp(_parser_table[i+1].m_Value, _parser_table[_current_parser_offset+2].m_Value)==0)
                    {
                        labelfound = true;
                        SLEAResolvePair postResolve;
                        postResolve.m_PatchAddressPointer = _current_binary_offset+2; // and also +6
                        postResolve.m_LabelToResolve = &_parser_table[i];
                        m_LDATResolves.emplace_back(postResolve);
                    }
                }
            }
            if (labelfound == false)
                printf("ERROR: label not found for LEA intrinsic.\n");
        }

        unsigned int code = 0x03; // W2R
        unsigned short gencode;
        gencode = m_Opcode | (code<<4) | (r1<<7);
        _binary_output[_current_binary_offset++] = (gencode&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = gencode&0x00FF;
        _binary_output[_current_binary_offset++] = (extra_dword&0xFF000000)>>24;
        _binary_output[_current_binary_offset++] = (extra_dword&0x00FF0000)>>16;
        gencode = m_Opcode | (code<<4) | (r2<<7);
        _binary_output[_current_binary_offset++] = (gencode&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = gencode&0x00FF;
        _binary_output[_current_binary_offset++] = (extra_dword&0x0000FF00)>>8;
        _binary_output[_current_binary_offset++] = (extra_dword&0x000000FF);

        return 3;
    }
};

// Memory/register move operations
class CMovOp : public CAssemblerTokenCompiler
{
public:
    CMovOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00003
    // mov [r1:r2], r0 : write the contents of register r0 to address r1:r2
    // mov r0, r1 : write the contents of r0 to register r1
    // mov r0, [r1:r2] : write the contents of memory at r1:r2 to register r0
    // mov r0, 0x0000 : write the immediate data at IP+1 to r0
    // mov [r1:r2], IP : write the contents of memory at r1:r2 to IP (instruction pointer)
    // mov IP+1, [r1:r2] : write the contents of IP+1 to address r1:r2 (return address)
    // unused0
    // unused1
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        int retcount = 0;

        if (_parser_table[_current_parser_offset+1].m_Index != -1)
        {
            printf("ERROR: Mov instruction expects a non-reserved keyword\n");
            return -1;
        }

        // int r1=0, r2=0, r3=0;
        // sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);

        int dest = 0;
        int source = 0;
        int r1=0, r2=0, r3=0;

        // Destination
        if (_parser_table[_current_parser_offset+1].m_Value[0] == 'r')
        {
            dest = 0;
            //printf("move to register %s ", _parser_table[_current_parser_offset+1].m_Value);
        }
        if (_parser_table[_current_parser_offset+1].m_Value[0] == '[')
        {
            dest = 1;
            //printf("move to address %s ", _parser_table[_current_parser_offset+1].m_Value);
        }
        if (_parser_table[_current_parser_offset+1].m_Value[0] == '0' && _parser_table[_current_parser_offset+1].m_Value[1] == 'x')
        {
            //dest = 2;
            printf("ERROR: Mov instruction does not accept a literal as destination operand\n");
            return -1;
        }
        // if (_parser_table[_current_parser_offset+1].m_Value[0] == 'I') // IP
        //     dest = 3;

        // Source
        if (_parser_table[_current_parser_offset+2].m_Value[0] == 'r')
        {
            source = 0;
            //printf("from register %s ", _parser_table[_current_parser_offset+2].m_Value);
        }
        if (_parser_table[_current_parser_offset+2].m_Value[0] == '[')
        {
            source = 1;
            //printf("from address %s ", _parser_table[_current_parser_offset+2].m_Value);
        }
        if (_parser_table[_current_parser_offset+2].m_Value[0] == '0' && _parser_table[_current_parser_offset+2].m_Value[1] == 'x')
        {
            source = 2;
            //printf("from literal %s ", _parser_table[_current_parser_offset+2].m_Value);
        }
        // if (_parser_table[_current_parser_offset+2].m_Value[0] == 'I') // IP
        //     source = 3;

        // R2M
        unsigned int code = 0;
        if (source==0 && dest==1)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "[r%d:r%d]", &r2,&r1);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r3);
            code = 0x00;
        }
        // M2R
        if (source==1 && dest==0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "[r%d:r%d]", &r2,&r1);
            code = 0x01;
        }
        // R2R
        if (source==0 && dest==0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r2);
            code = 0x02;
        }
        // W2R
        if (source==2 && dest==0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);
            code = 0x03;
        }

        // //R2IP
        // if (source==0 && dest==3)
        // {
        //     sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);
        //     sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r2);
        //     code = 0x04;
        // }
        // //(IP+1)2R
        // if (source==3 && dest==0)
        // {
        //     sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r1);
        //     sscanf(_parser_table[_current_parser_offset+3].m_Value, "r%d", &r2);
        //     code = 0x05;
        // }

        unsigned short gencode = m_Opcode | (code<<4) | (r1<<7) | (r2<<10) | (r3<<13);
        _binary_output[_current_binary_offset++] = (gencode&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = gencode&0x00FF;
        if (code == 0x03)
        {
            unsigned int extraword = 0;
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "%x", &extraword);
            _binary_output[_current_binary_offset++] = (extraword&0xFF00)>>8;
            _binary_output[_current_binary_offset++] = extraword&0x00FF;
        }

        //printf("\n");
        return 3;
    }
};

// Memory/register move operations
class CMovByteOp : public CAssemblerTokenCompiler
{
public:
    CMovByteOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00008
    // movb [r1:r2], r0 : write the contents of register r0 to address r1:r2
    // movb r0, r1 : write the contents of r0 to register r1
    // movb r0, [r1:r2] : write the contents of memory at r1:r2 to register r0
    // unused0
    // unused1
    // unused2
    // unused3
    // unused4
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        int retcount = 0;

        if (_parser_table[_current_parser_offset+1].m_Index != -1)
        {
            printf("ERROR: Bmov instruction expects a non-reserved keyword\n");
            return -1;
        }

        int dest = 0;
        int source = 0;
        int r1=0, r2=0, r3=0;

        // Destination
        if (_parser_table[_current_parser_offset+1].m_Value[0] == 'r')
        {
            dest = 0;
            //printf("move to register %s ", _parser_table[_current_parser_offset+1].m_Value);
        }
        if (_parser_table[_current_parser_offset+1].m_Value[0] == '[')
        {
            dest = 1;
            //printf("move to address %s ", _parser_table[_current_parser_offset+1].m_Value);
        }
        if (_parser_table[_current_parser_offset+1].m_Value[0] == '0' && _parser_table[_current_parser_offset+1].m_Value[1] == 'x')
        {
            //dest = 2;
            printf("ERROR: Bmov instruction does not accept a literal as destination operand\n");
            return -1;
        }

        // Source
        if (_parser_table[_current_parser_offset+2].m_Value[0] == 'r')
        {
            source = 0;
            //printf("from register %s ", _parser_table[_current_parser_offset+2].m_Value);
        }
        if (_parser_table[_current_parser_offset+2].m_Value[0] == '[')
        {
            source = 1;
            //printf("from address %s ", _parser_table[_current_parser_offset+2].m_Value);
        }

        // R2M
        unsigned int code = 0;
        if (source==0 && dest==1)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "[r%d:r%d]", &r2,&r1);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r3);
            code = 0x00;
        }
        // M2R
        if (source==1 && dest==0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r3);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "[r%d:r%d]", &r2,&r1);
            code = 0x01;
        }
        // R2R
        if (source==0 && dest==0)
        {
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r2);
            code = 0x02;
        }

        unsigned short gencode = m_Opcode | (code<<4) | (r1<<7) | (r2<<10) | (r3<<13);
        _binary_output[_current_binary_offset++] = (gencode&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = gencode&0x00FF;

        return 3;
    }
};

// Return or halt
class CRetHaltOp : public CAssemblerTokenCompiler
{
public:
    CRetHaltOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00004
    // ret : return to caller
    // halt : stop the CPU and go into a spin-state (only a reset will recover from this state)
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        //printf("%s\n", _parser_table[_current_parser_offset].m_Value);

        if(strcmp(_parser_table[_current_parser_offset].m_Value, "ret") == 0)
        {
            _binary_output[_current_binary_offset++] = (m_Opcode&0xFF00)>>8;
            _binary_output[_current_binary_offset++] = m_Opcode&0x00FF;
        }

        if(strcmp(_parser_table[_current_parser_offset].m_Value, "halt") == 0)
        {
            unsigned short code = m_Opcode | 0x0010;
            _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
            _binary_output[_current_binary_offset++] = code&0x00FF;
        }

        return 1;
    }
};

// Push or pop
class CStackOp : public CAssemblerTokenCompiler
{
public:
    CStackOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00005
    // push r0 : write r0 to SP, decrement SP
    // pop r0 : increment SP, read from SP to r0
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        //printf("%s\n", _parser_table[_current_parser_offset].m_Value);

        int r1;
        sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);

        if(strcmp(_parser_table[_current_parser_offset].m_Value, "push") == 0)
        {
            unsigned short code = m_Opcode | (r1<<5);
            _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
            _binary_output[_current_binary_offset++] = code&0x00FF;
        }

        if(strcmp(_parser_table[_current_parser_offset].m_Value, "pop") == 0)
        {
            unsigned short code = m_Opcode | 0x0010 | (r1<<5);
            _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
            _binary_output[_current_binary_offset++] = code&0x00FF;
        }

        return 2;
    }
};

// Test mask
class CTestOp : public CAssemblerTokenCompiler
{
public:
    CTestOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00006
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        unsigned int mask = 0;
        int i = _current_parser_offset+1;
        // Loop and gather mask from all non-keywords after this instruction
        // ZERO:NOTEQUAL:NOTZERO:LESS:GREATER:EQUAL
        do
        {
            if(strcmp(_parser_table[i].m_Value, "zero")==0)
                mask |= 0x20;
            if(strcmp(_parser_table[i].m_Value, "notequal")==0)
                mask |= 0x10;
            if(strcmp(_parser_table[i].m_Value, "notzero")==0)
                mask |= 0x8;
            if(strcmp(_parser_table[i].m_Value, "less")==0)
                mask |= 0x4;
            if(strcmp(_parser_table[i].m_Value, "greater")==0)
                mask |= 0x2;
            if(strcmp(_parser_table[i].m_Value, "equal")==0)
                mask |= 0x1;
            ++i;
        } while(_parser_table[i].m_Index == -1);

        //printf("Test mask on previous compare: %.8X\n", mask);

        unsigned short code = m_Opcode | (mask<<4);
        _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = code&0x00FF;

        return i-_current_parser_offset;
    }
};

// Compare operation
class CCompareOp : public CAssemblerTokenCompiler
{
public:
    CCompareOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00007
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        if (_parser_table[_current_parser_offset+1].m_Value[0] != 'r' || _parser_table[_current_parser_offset+2].m_Value[0] != 'r')
        {
            printf("ERROR: Cmp requires two register operands\n");
            return -1;
        }

        //printf("Compare register %s with register %s\n", _parser_table[_current_parser_offset+1].m_Value, _parser_table[_current_parser_offset+2].m_Value);

        int r1, r2;
        sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);
        sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r2);

        unsigned short code = m_Opcode | (r1<<4) | (r2<<7);
        _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
        _binary_output[_current_binary_offset++] = code&0x00FF;

        return 3;
    }
};

// IO operations and vsync
class CIOOp : public CAssemblerTokenCompiler
{
public:
    CIOOp(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    // INSTRUCTION: 0x00008
    // vsync : halt the CPU until the vsync is tiggered on the video output hardware
    // in r0, 0x0000 : read from port address into given register
    // out 0x0000, r0 : write to port address from given register
    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        if(strcmp(_parser_table[_current_parser_offset].m_Value, "vsync") == 0)
        {
            unsigned short code = m_Opcode;
            _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
            _binary_output[_current_binary_offset++] = code&0x00FF;
            return 1;
        }

        if(strcmp(_parser_table[_current_parser_offset].m_Value, "in") == 0)
        {
            int portaddress, r1;
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "r%d", &r1);
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "%x", &portaddress);

            unsigned short code = m_Opcode | 0x0010 | (r1<<7);
            _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
            _binary_output[_current_binary_offset++] = code&0x00FF;
            _binary_output[_current_binary_offset++] = (portaddress&0xFF00)>>8;
            _binary_output[_current_binary_offset++] = portaddress&0x00FF;
            return 2;
        }

        if(strcmp(_parser_table[_current_parser_offset].m_Value, "out") == 0)
        {
            int portaddress, r1;
            sscanf(_parser_table[_current_parser_offset+1].m_Value, "%x", &portaddress);
            sscanf(_parser_table[_current_parser_offset+2].m_Value, "r%d", &r1);

            unsigned short code = m_Opcode | 0x0020 | (r1<<7);
            _binary_output[_current_binary_offset++] = (code&0xFF00)>>8;
            _binary_output[_current_binary_offset++] = code&0x00FF;
            _binary_output[_current_binary_offset++] = (portaddress&0xFF00)>>8;
            _binary_output[_current_binary_offset++] = portaddress&0x00FF;
            return 2;
        }

        printf("ERROR: Unknown variant in CIOOp class of instructions\n");
        return -1;
    }
};

// Empty / dummy operation
class CNil : public CAssemblerTokenCompiler
{
public:
    CNil(const char *_token, const unsigned short _opcode) { m_Token = _token; m_Opcode = _opcode; }

    int InterpretKeyword(SParserItem *_parser_table, unsigned int _current_parser_offset, unsigned char *_binary_output, unsigned int &_current_binary_offset) override
    {
        printf("Unknown symbol: %d('%s')\n", _current_parser_offset, _parser_table[_current_parser_offset].m_Value);
        return 1;
    }
};

// Instruction generators / parsers
COriginOp s_originop("@ORG", 0x0);
CDataWordOp s_datawordop("@DW", 0x0);
CLabelOp s_labelop("@LABEL", 0x0);
CLogicOpOr s_logicop_or("or", 0x0000);
CLogicOpAnd s_logicop_and("and", 0x0000);
CLogicOpXor s_logicop_xor("xor", 0x0000);
CLogicOpNot s_logicop_not("not", 0x0000);
CLogicOpBsl s_logicop_bsl("bsl", 0x0000);
CLogicOpBsr s_logicop_bsr("bsr", 0x0000);
CLogicOpBswap s_logicop_bswap("bswap", 0x0000);
CLogicOpNoop s_logicop_noop("noop", 0x0000);
CBranchOp s_branchop("jmp", 0x0001);
CMathOp s_mathop("add", 0x0002);
CMovOp s_movop("mov", 0x0003);
CLeaOp s_leaop("lea", 0x0003); // Not a real instruction!
CLdatOp s_ldatop("ldat", 0x0003); // Not a real instruction!
CRetHaltOp s_rethaltop("ret", 0x0004);
CStackOp s_stackop("push", 0x0005);
CTestOp s_testop("test", 0x0006);
CCompareOp s_cmpop("cmp", 0x0007);
CIOOp s_ioop("vsync", 0x0008);
CMovByteOp s_bmovop("bmov", 0x0009);
CNil s_nilop("nil", 0x0000); // 0x0009...0x000F

struct SAssemblerPair
{
    SAssemblerKeyword m_Keyword;
    CAssemblerTokenCompiler *m_Compiler;
};

const SAssemblerPair keywords[] =
{
    {{"@ORG"}, &s_originop},
    {{"@DW"}, &s_datawordop},
    {{"@LABEL"}, &s_labelop},

    {{"or"}, &s_logicop_or},
    {{"and"}, &s_logicop_and},
    {{"xor"}, &s_logicop_xor},
    {{"not"}, &s_logicop_not},
    {{"bsl"}, &s_logicop_bsl},
    {{"bsr"}, &s_logicop_bsr},
    {{"bswap"}, &s_logicop_bswap},
    {{"noop"}, &s_logicop_noop},

    {{"branch"}, &s_branchop},
    {{"jmp"}, &s_branchop},
    {{"branchif"}, &s_branchop},
    {{"jmpif"}, &s_branchop},

    {{"iadd"}, &s_mathop},
    {{"isub"}, &s_mathop},
    {{"imul"}, &s_mathop},
    {{"idiv"}, &s_mathop},
    {{"imod"}, &s_mathop},
    {{"ineg"}, &s_mathop},
    {{"inc"}, &s_mathop},
    {{"dec"}, &s_mathop},

    {{"mov"}, &s_movop},
    {{"bmov"}, &s_bmovop},
    {{"lea"}, &s_leaop},
    {{"ldat"}, &s_ldatop},

    {{"ret"}, &s_rethaltop},
    {{"halt"}, &s_rethaltop},

    {{"push"}, &s_stackop},
    {{"pop"}, &s_stackop},

    {{"test"}, &s_testop},

    {{"cmp"}, &s_cmpop},

    {{"vsync"}, &s_ioop},
    {{"in"}, &s_ioop},
    {{"out"}, &s_ioop},

    {{"unused1"}, &s_nilop},
    {{"unused2"}, &s_nilop},
    {{"unused3"}, &s_nilop},
    {{"unused4"}, &s_nilop},
    {{"unused5"}, &s_nilop},
    {{"unused6"}, &s_nilop},
    {{"unused7"}, &s_nilop},
};

int find_token(const char *token)
{
    //printf("%s:", token);
    for (unsigned int i=0;i<_countof(keywords);++i)
    {
        if (strcmp(token, keywords[i].m_Keyword.m_Name) == 0)
        {
            //printf("%d\n", i);
            return i;
        }
    }
    //printf("???\n");
    return -1;
}

int parse_nip(const char *_inputtext)
{
    char *parsedat = const_cast<char*>(_inputtext);

    s_parser_table = new SParserItem[524286];
    s_num_parser_entries = 0;
    s_binary_output = new unsigned char[524286];
    s_current_binary_offset = 0;

    while(*parsedat != 0)
    {
        // Skip whitespace
        while((*parsedat == ' ' || *parsedat == ',' || *parsedat == '|' || *parsedat == '\r' || *parsedat == '\n' || *parsedat == '\t') && *parsedat != 0)
            ++parsedat;

        // Collect one token
        char token[512];
        int i = 0;

        // Skip comments
        if (*parsedat == '#')
        {
            while(*parsedat != '\r' && *parsedat != '\n' && *parsedat != 0)
                ++parsedat;
        }
        else
        {
            while(*parsedat != ' ' && *parsedat != ',' && *parsedat != '|' && *parsedat != '\r' && *parsedat != '\n' && *parsedat != '\t' && *parsedat != 0)
            {
                token[i++] = *parsedat;
                ++parsedat;
            }
            token[i] = 0;

            if (i==0)
                break;

            unsigned int t = find_token(token);

            // Append to list
            s_parser_table[s_num_parser_entries].m_Index = t;
            s_parser_table[s_num_parser_entries].m_Value = new char[i];
            strcpy(s_parser_table[s_num_parser_entries].m_Value, token);
            ++s_num_parser_entries;
        }
    }

    // Invoke matching functions for each token to produce binary output
    unsigned int current_parser_entry = 0;
    bool done = false;
    while (!done)
    {
        int idx = s_parser_table[current_parser_entry].m_Index;
        if(idx != -1)
        {
            unsigned int prevbinaryoffset = s_current_binary_offset;
            int offset = keywords[idx].m_Compiler->InterpretKeyword(s_parser_table, current_parser_entry, s_binary_output, s_current_binary_offset);

            // Do not generate empty blocks or for long @ORG jumps
            if (s_current_binary_offset>prevbinaryoffset)
            {
                SCodeBlock newblock;
                newblock.m_StartAddress = prevbinaryoffset;
                newblock.m_ByteCount = s_current_binary_offset-prevbinaryoffset;
                newblock.m_Words = &s_binary_output[prevbinaryoffset];
                newblock.m_IsEmpty = strcmp(keywords[idx].m_Keyword.m_Name, "@ORG") == 0 ? true : false;
                m_codeBlocks.emplace_back(newblock);
            }
            

            if (s_current_binary_offset/2 >= 4096)
            {
                s_current_binary_offset = 8192;
                printf("ERROR: Neko ROM files cannot exceed 4095 bytes total in size.\nBinary generation is cut off at this point.\n");
                break;
            }
            /*if (s_current_binary_offset > prevbinaryoffset) // Some entries will advance tokens but won't produce binary data
            {
                for (unsigned int i = prevbinaryoffset; i<s_current_binary_offset;++i)
                    printf("%.4X ", s_binary_output[i]);
                printf("\n");
            }*/
            if (offset == -1)
                break;
            current_parser_entry += offset;
        }
        else
        {
            printf("ERROR: Compiler found an unknown keyword at index %d: %s\n", current_parser_entry, s_parser_table[current_parser_entry].m_Value);
            break;
        }

        if (current_parser_entry >= s_num_parser_entries)
            done = true;
    }

    for(auto &patch : m_branchResolves)
    {
        SParserItem *itm = patch.m_LabelToResolve;
        uint32_t branchtarget = itm->m_LabelMemoryOffset;
        s_binary_output[patch.m_PatchAddressPointer+0] = (branchtarget&0xFF000000)>>24;
        s_binary_output[patch.m_PatchAddressPointer+1] = (branchtarget&0x00FF0000)>>16;
        s_binary_output[patch.m_PatchAddressPointer+2] = (branchtarget&0x0000FF00)>>8;
        s_binary_output[patch.m_PatchAddressPointer+3] = (branchtarget&0x000000FF);
    }

    for (auto &patch : m_LEAResolves)
    {
        SParserItem *itm = patch.m_LabelToResolve;
        uint32_t labeladdress = itm->m_LabelMemoryOffset;
        s_binary_output[patch.m_PatchAddressPointer+0] = (labeladdress&0xFF000000)>>24;
        s_binary_output[patch.m_PatchAddressPointer+1] = (labeladdress&0x00FF0000)>>16;
        s_binary_output[patch.m_PatchAddressPointer+4] = (labeladdress&0x0000FF00)>>8;
        s_binary_output[patch.m_PatchAddressPointer+5] = (labeladdress&0x000000FF);
    }

    for (auto &patch : m_LDATResolves)
    {
        SParserItem *itm = patch.m_LabelToResolve;
        uint32_t labeladdress = itm->m_LabelMemoryOffset;
        uint16_t d0 = s_binary_output[labeladdress];
        uint16_t d1 = s_binary_output[labeladdress+1];
        uint16_t d2 = s_binary_output[labeladdress+2];
        uint16_t d3 = s_binary_output[labeladdress+3];
        s_binary_output[patch.m_PatchAddressPointer+0] = d0;
        s_binary_output[patch.m_PatchAddressPointer+1] = d1;
        s_binary_output[patch.m_PatchAddressPointer+4] = d2;
        s_binary_output[patch.m_PatchAddressPointer+5] = d3;
    }

    return 0;
}

int compile_asm(const char *_inputname, const char *_outputname)
{
    printf("Parsing: %s\n", _inputname);

    // Try to open input file
    FILE *inputfile = fopen(_inputname, "rb");
    if (inputfile == nullptr)
    {
        printf("ERROR: Cannot find input file\n");
        return -1;
    }

    // Measure file size
    unsigned int filebytesize = 0;
	fpos_t pos, endpos;
	fgetpos(inputfile, &pos);
	fseek(inputfile, 0, SEEK_END);
	fgetpos(inputfile, &endpos);
    fsetpos(inputfile, &pos);
    filebytesize = (unsigned int)endpos;

    // Allocate memory and read file contents, then close the file
    char *filedata = new char[filebytesize+1];
    fread(filedata, 1, filebytesize, inputfile);
    filedata[filebytesize] = 0;
    fclose(inputfile);

    if (_outputname == nullptr || strlen(_outputname)==0)
    {
        printf("ERROR: No output file name was provided, aborting.\n");
        return -1;
    }

    // Generate binary blob
    if (parse_nip(filedata)!=0)
        printf("ERROR: Could not parse input file\n");
    
    // Dump binary blob
    if (strstr(_outputname,".mif"))
    {
        printf("Generating memory initialization file: %s\n", _outputname);
        FILE *outputfile = fopen(_outputname, "wb");
        if (outputfile == nullptr)
        {
            printf("ERROR: Cannot open output file\n");
            return -1;
        }
        fprintf(outputfile, "-- Generated by Catnip compiler v0.1\r\n-- Neko CPU and Catnip Assembler are (C) Engin Cilasun 2020\r\n-- Memory Initialization File generated from '%s' for Quartus Prime\r\n\r\n", _inputname);
        fprintf(outputfile, "WIDTH=16;\r\nDEPTH=4096;\r\n\r\nADDRESS_RADIX=HEX;\r\nDATA_RADIX=HEX;\r\n\r\nCONTENT BEGIN\r\n");
        auto beg = m_codeBlocks.begin();
        auto end = m_codeBlocks.end();
        while (beg!=end)
        {
            if (beg->m_IsEmpty)
            {
                // Fill empty blocks which didn't generate any instructions with zeros (mostly due to @ORG jump)
                fprintf(outputfile, "\t[%.4X..%.4X]  :   0000;\r\n", beg->m_StartAddress/2, (beg->m_StartAddress+beg->m_ByteCount)/2-1);
            }
            else
            {
                // Dump code for non-empty blocks
                for (unsigned int i=beg->m_StartAddress/2;i<(beg->m_StartAddress+beg->m_ByteCount)/2;++i)
                {
                    unsigned short theword = (s_binary_output[i*2+0]<<8) | s_binary_output[i*2+1];
                    fprintf(outputfile, "\t%.4X  :   %.4X;\r\n", i, theword);
                }
            }
            ++beg;
        }
        // Fill the rest of the memory with zeros
        if (s_current_binary_offset/2<4096)
            fprintf(outputfile, "\t[%.4X..0FFF]  :   0000;\r\n", s_current_binary_offset/2);
        fprintf(outputfile, "END;\r\n");
        fclose(outputfile);
    }
    else if (strstr(_outputname,".rom"))
    {
        printf("Generating ROM file: %s\n", _outputname);
        FILE *outputfile = fopen(_outputname, "wb");
        if (outputfile == nullptr)
        {
            printf("ERROR: Cannot open output file\n");
            return -1;
        }
        auto beg = m_codeBlocks.begin();
        auto end = m_codeBlocks.end();
        uint16_t zero = 0x0000;
        while (beg!=end)
        {
            if (beg->m_IsEmpty)
            {
                // Fill empty blocks which didn't generate any instructions with zeros (mostly due to @ORG jump)
                for (int i=beg->m_StartAddress/2;i<(beg->m_StartAddress+beg->m_ByteCount)/2;++i)
                    fwrite(&zero, sizeof(uint16_t), 1, outputfile);
            }
            else
            {
                // Dump code for non-empty blocks
                for (unsigned int i=beg->m_StartAddress/2;i<(beg->m_StartAddress+beg->m_ByteCount)/2;++i)
                {
                    unsigned short theword = (s_binary_output[i*2+0]<<8) | s_binary_output[i*2+1];
                    fwrite(&theword, sizeof(uint16_t), 1, outputfile);
                }
            }
            ++beg;
        }
        // Fill the rest of the memory with zeros
        if (s_current_binary_offset/2<4096)
        {
            for (int i=s_current_binary_offset/2;i<4096;++i)
                fwrite(&zero, sizeof(uint16_t), 1, outputfile);
        }
        fclose(outputfile);
    }
    else
        printf("No output was generated, unrecognized output file extension: %s\n", _outputname);

    return 0;
}

int emulate_rom(char *_romname)
{
    // Read ROM file
    FILE *inputfile = fopen(_romname, "rb");
    if (inputfile == nullptr)
    {
        printf("ERROR: Cannot find ROM file\n");
        return -1;
    }

    unsigned int filebytesize = 0;
    fpos_t pos, endpos;
    fgetpos(inputfile, &pos);
    fseek(inputfile, 0, SEEK_END);
    fgetpos(inputfile, &endpos);
    fsetpos(inputfile, &pos);
    filebytesize = (unsigned int)endpos;

    // Allocate memory and read file contents, then close the file
    uint16_t *rom_binary = new uint16_t[0x7FFFF];
    fread(rom_binary, 1, filebytesize, inputfile);
    fclose(inputfile);

    // Start eumulator with input ROM image
    if (InitEmulator((uint16_t*)rom_binary))
    {
        // Run the emulator
        bool running = true;
        do
        {
            running = StepEmulator();
        } while (running);
    }
    
    // Clean up, report errors etc
    TerminateEmulator();

    return 0;
}

int main(int _argc, char **_argv)
{
    if (_argc<=1)
    {
        printf("catnip v0.2\n");
        printf("(C)2020 Engin Cilasun\n");
        printf("Usage: catnip inputfile.asm outputfile.mif - Generates a memory initialization file from assembly input for FPGA device\n");
        printf("Usage: catnip inputfile.asm outputfile.rom - Generates a ROM file from assembly input for emulator\n");
        printf("Usage: catnip inputfile.rom - Runs the emulator with given ROM file\n");
        return 0;
    }

    if (strstr(_argv[1], ".asm"))
        return compile_asm(_argv[1], _argv[2]);     // .ASM->.ROM/.MIF
    else
        return emulate_rom(_argv[1]);               // .ROM->Emulator
}
