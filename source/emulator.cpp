#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
//#include <thread>
#include "../SDL/SDL.h"
#include "emulator.h"
//#include <windows.h>

// Neko emulator

// VGA timings
#define H_FRONT_PORCH 16
#define H_SYNC 64
#define H_BACK_PORCH 80
#define H_ACTIVE 640
#define H_SYNC_TICKS (H_FRONT_PORCH+H_SYNC+H_BACK_PORCH+H_ACTIVE)
#define V_FRONT_PORCH 3
#define V_SYNC 4
#define V_BACK_PORCH 16
#define V_ACTIVE 480
#define V_SYNC_TICKS (V_FRONT_PORCH+V_SYNC+V_BACK_PORCH+V_ACTIVE)

// CPU state machine
#define CPU_INIT						0b0000
#define CPU_ROM_STEP					0b0001
#define CPU_ROM_FETCH					0b0010
#define CPU_WRITE_DATAH                 0b0011
#define CPU_CLEARVRAM					0b0100
#define CPU_FETCH_INSTRUCTION			0b0101
#define CPU_EXECUTE_INSTRUCTION			0b0110
#define CPU_READ_DATAH                  0b0111
#define CPU_STATE_PRE_RUN				0b1000
#define CPU_READ_DATA					0b1001
#define CPU_WRITE_DATA					0b1010
#define CPU_SET_BRANCH_ADDRESSA			0b1011
#define CPU_FETCH_ADDRESS_AND_BRANCH	0b1100
#define CPU_WAIT_VSYNC					0b1101
#define CPU_READ_DATA_BYTE				0b1110
#define CPU_SET_BRANCH_ADDRESSB			0b1111

// CPU instructions
#define INST_LOGIC						0b0000	// 0: run logic operation and/or/xor/not/bsl/bsr on r1 and r2, write result to r3 
#define INST_BRANCH						0b0001	// 1: jump or call (direct/indirect/short/long)
#define INST_MATH						0b0010	// 2: run math operation iadd/isub/imul/idiv/imod/ineg/inc/dec on r1 and r2, write result to r3 
#define INST_MOV						0b0011	// 3: copy reg2mem/mem2reg/reg2reg/word2reg (dword/word/byte)
#define INST_RET						0b0100	// 4: ret/halt
#define INST_STACK						0b0101	// 5: push/pop register to stack
#define INST_TEST						0b0110	// 6: test flags register against mask bits and set TR register to 1 or 0
#define INST_CMP						0b0111	// 7: compare r1 with r2 and set flags register
#define INST_IO							0b1000	// 8: wait for vsync signal / in / out to port
#define INST_RELMOV						0b1001	// 9: same as mov, in relative addressing mode
#define INST_I4							0b1010	// A: TBD
#define INST_I5							0b1011	// B: TBD
#define INST_I6							0b1100	// C: TBD
#define INST_I7							0b1101	// D: TBD
#define INST_I8							0b1110	// E: TBD
#define INST_I9							0b1111	// F: TBD

// CPU unit
uint32_t BRANCHTARGET;          // Branch target
uint32_t IP;                    // Instruction pointer
uint32_t SP;                    // Stack pointer
uint16_t instruction;           // Current instruction
uint32_t register_file[8];	    // Array of 8 32bit registers
uint16_t flags_register;	   	// Flag registers [ZERO:NOTEQUAL:NOTZERO:LESS:GREATER:EQUAL]
uint16_t target_register;	    // Target for some memory read operations
uint16_t target_registerH;	    // Target for some memory read operations (high word)
uint16_t cpu_state = CPU_INIT;	// Default state to boot from
uint16_t TR;					// Test register, holds result of TEST
uint16_t CALLSP;				// Branch stack pointer
uint32_t CALLSTACK[16];	    	// Branch stack

uint8_t *SRAM;                  // SRAM

uint32_t sram_addr;
uint16_t sram_read_req;
uint16_t sram_rdata;
uint16_t sram_wdata;
uint16_t sram_write_req;
uint16_t sram_enable_byteaddress;

// Video unit
#define RGBCOLOR(_r,_g,_b) (_r | (_g<<3) | (_b<<6))
static const int FRAME_WIDTH = 256;
static const int FRAME_HEIGHT = 192;
static uint8_t *VRAM; // Larger than FRAME_HEIGHT, including top and bottom borders

uint16_t framebuffer_select;
uint16_t framebuffer_address;
uint16_t framebuffer_writeena;
uint8_t framebuffer_data;
uint16_t cpu_lane_mask;

// ROM unit
uint16_t *ROM;
uint16_t rom_out;
uint16_t rom_addrs;
uint16_t rom_read_enable;

// SDL
SDL_Window *s_Window;
SDL_Surface *s_Surface;
//HDC hDC;

// Global clock
uint32_t s_SystemClock = 0;
uint32_t s_SystemClockRisingEdge = 0;
uint32_t s_SystemClockFallingEdge = 0;
uint32_t s_VGAClock = 0;
uint32_t s_VGAClockRisingEdge = 0;
uint32_t s_VGAClockFallingEdge = 0;

// CPU emulation
//std::thread *s_CPUThread;
//bool s_CPUDone = false;

// Video emulation
int vga_x = 0;
int vga_y = 0;

const char *s_state_string[]={
    "CPU_INIT",
    "CPU_ROM_STEP",
    "CPU_ROM_FETCH",
    "CPU_WRITE_DATAH",
    "CPU_CLEARVRAM",
    "CPU_FETCH_INSTRUCTION",
    "CPU_EXECUTE_INSTRUCTION",
    "CPU_READ_DATAH",
    "CPU_STATE_PRE_RUN",
    "CPU_READ_DATA",
    "CPU_WRITE_DATA",
    "CPU_SET_BRANCH_ADDRESSA",
    "CPU_FETCH_ADDRESS_AND_BRANCH",
    "CPU_WAIT_VSYNC",
    "CPU_READ_DATA_BYTE",
    "CPU_SET_BRANCH_ADDRESSB"
};

void ClockMain()
{
    uint32_t oldclock = s_SystemClock;
    uint32_t oldvgaclock = s_VGAClock;
    s_SystemClock = (s_SystemClock<<1) | (s_SystemClock>>(32-1));
    s_VGAClock = (s_VGAClock<<1) | (s_VGAClock>>(32-1));

    s_SystemClockRisingEdge = (!(oldclock&0x80000000)) && ((s_SystemClock&0x80000000));
    s_SystemClockFallingEdge = ((oldclock&0x80000000)) && (!(s_SystemClock&0x80000000));

    s_VGAClockRisingEdge = (!(oldvgaclock&0x80000000)) && ((s_VGAClock&0x80000000));
    s_VGAClockFallingEdge = ((oldvgaclock&0x80000000)) && (!(s_VGAClock&0x80000000));
}

void execute(uint16_t instruction)
{
    uint16_t inst = instruction&0x000F;
    switch(inst)
    {
        case INST_LOGIC:
        {
            uint16_t op = (instruction&0b0000000001110000)>>4; // [6:4]
            uint16_t subop = (instruction&0b0000001110000000)>>7; // [9:7]
            uint16_t r1 = (instruction&0b0001110000000000)>>10; // [12:10]
            uint16_t r2 = (instruction&0b1110000000000000)>>13; // [15:13]
            switch (op)
            {
                case 0: // Or
                    register_file[r1] = register_file[r1] | register_file[r2];
                break;
                case 1: // And
                    register_file[r1] = register_file[r1] & register_file[r2];
                break;
                case 2: // Xor
                    register_file[r1] = register_file[r1] ^ register_file[r2];
                break;
                case 3: // Not
                    register_file[r1] = ~register_file[r1];
                break;
                case 4: // BSL
                    register_file[r1] = register_file[r1] << register_file[r2];
                break;
                case 5: // BSR
                    register_file[r1] = register_file[r1] >> register_file[r2];
                break;
                case 6: // BSWAP_L
                {
                    uint16_t lower8 = register_file[r2]&0x000000FF;
                    uint16_t upper8 = (register_file[r2]&0x0000FF00)>>8;
                    register_file[r1] = upper8 | (lower8<<8);
                }
                break;
                case 7: // TODO: BSWAP_H
                break;
            }
            sram_addr = IP+2;
            IP = IP + 2;
            sram_enable_byteaddress = 0;
            sram_read_req = 1;
            cpu_state = CPU_FETCH_INSTRUCTION;
        }
        break;

        case INST_BRANCH:
        {
            uint16_t typ = (instruction&0b0100000000000000)>>14; // [14]
            uint16_t immed = (instruction&0b1000000000000000)>>15; // [15]
            uint16_t si = (instruction&0b0000000000110000)>>4; // [5:4]
            uint16_t r1 = (instruction&0b0000011100000000)>>8; // [10:8]

            // NOTE: BRANCH and JMP share the same logic except the stack bit
            // Push return address to branch stack for 'BRANCH/BRANCHIF'
            if (typ == 1)
            {
                CALLSTACK[CALLSP] = IP + (immed ? 6:2); // Skip current instruction (and two WORDs if this not register based)
                CALLSP = CALLSP + 1;
            }

            switch (si)
            {
                case 0b00: // Unconditional branch
                    if (immed == 1)
                    {
                        // Read branch address from next WORD in memory (short jump, only 16 bits)
                        IP = IP + 2; // CALL WORD
                        cpu_state = CPU_SET_BRANCH_ADDRESSA;
                    }
                    else
                    {
                        // Use address in register pair inside instruction
                        IP = register_file[r1]; // CALL [R1]
                        sram_enable_byteaddress = 0;
                        sram_addr = register_file[r1];
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    }
                break;
                case 0b01: // When test register (TR) is true
                    if (TR == 1)
                        {
                            if (immed == 1)
                            {
                                // Read branch address from next WORD in memory (short jump, only 16 bits)
                                IP = IP + 2; // CALL WORD
                                cpu_state = CPU_SET_BRANCH_ADDRESSA;
                            }
                            else
                            {
                                IP = register_file[r1]; // CALL [R1]
                                sram_enable_byteaddress = 0;
                                sram_addr = register_file[r1];
                                sram_read_req = 1;
                                cpu_state = CPU_FETCH_INSTRUCTION;
                            }
                        }
                        else
                        {
                            if (immed == 1)
                            {
                                sram_addr = IP + 6;
                                IP = IP + 6; // Skip the next WORD in memory since it's not a command (short (16bit) branch address)
                            }
                            else
                            {
                                sram_addr = IP + 2;
                                IP = IP + 2; // Does not take the branch if previous call to TEST failed
                            }
                            sram_enable_byteaddress = 0;
                            sram_read_req = 1;
                            cpu_state = CPU_FETCH_INSTRUCTION;
                        }
                    break;
                    case 0b10:
                        // UNUSED YET - HALT
                        IP = 0x7FFFF;
                        sram_enable_byteaddress = 0;
                        sram_addr = 0x7FFFF;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                    case 0b11:
                        // UNUSED YET - HALT
                        IP = 0x7FFFF;
                        sram_enable_byteaddress = 0;
                        sram_addr = 0x7FFFF;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                }
            }
            break;

            case INST_MATH:
            {
                uint16_t op = (instruction&0b0000000001110000)>>4; // [6:4]
                uint16_t subop = (instruction&0b0000001110000000)>>7; // [9:7]
                uint16_t r1 = (instruction&0b0001110000000000)>>10; // [12:10]
                uint16_t r2 = (instruction&0b1110000000000000)>>13; // [15:13]
                switch (op)
                {
                    case 0: // Iadd
                        register_file[r1] = register_file[r1] + register_file[r2];
                    break;
                    case 1: // Isub
                        register_file[r1] = register_file[r1] - register_file[r2];
                    break;
                    case 2: // Imul
                        register_file[r1] = register_file[r1] * register_file[r2];
                    break;
                    case 3: // Idiv
                        register_file[r1] = register_file[r1] / register_file[r2];
                    break;
                    case 4: // Imod
                        register_file[r1] = register_file[r1] % register_file[r2];
                    break;
                    case 5: // Ineg
                        register_file[r1] = -register_file[r1];
                    break;
                    case 6: // Inc
                        register_file[r1] = register_file[r1] + 1;
                    break;
                    case 7: // Dec
                        register_file[r1] = register_file[r1] - 1;
                    break;
                }
                sram_addr = IP+2;
                IP = IP + 2;
                sram_enable_byteaddress = 0;
                sram_read_req = 1;
                cpu_state = CPU_FETCH_INSTRUCTION;
            }
            break;

            case INST_MOV:
            {
                uint16_t op = (instruction&0b0000000001110000)>>4; // [6:4]
                uint16_t r1 = (instruction&0b0000001110000000)>>7; // [9:7]
                uint16_t r2 = (instruction&0b0001110000000000)>>10; // [12:10]
                switch (op)
                {
                    case 0: // reg2mem
                    {
                        bool is_vram_address = (register_file[r1]&0x80000000)>>31 ? true:false;
                        if (is_vram_address) // VRAM write (address>=0x80000000)
                        {
                            if ((register_file[r1]&0x0000FFFF) < 0xD000) // Only if within VRAM region
                            {
                                // NOTE: VRAM ends at 0xC000 but we need to be able to address the rest for
                                // other attributes such as border color, sprite tables and such
                                framebuffer_address = register_file[r1]&0x0000FFFF;
                                framebuffer_writeena = 1;
                                // TODO: Somehow need to implement a WORD mov to VRAM
                                framebuffer_data = uint8_t(register_file[r2]&0x00FF);
                                sram_addr = IP+2;
                                IP = IP + 2;
                                sram_enable_byteaddress = 0;
                                sram_read_req = 1;
                                cpu_state = CPU_FETCH_INSTRUCTION;
                            }
                            else // Otherwise noop
                            {
                                sram_addr = IP+2;
                                IP = IP + 2;
                                sram_enable_byteaddress = 0;
                                sram_read_req = 1;
                                cpu_state = CPU_FETCH_INSTRUCTION;
                            }
                        }
                        else
                        {
                            // SRAM
                            sram_enable_byteaddress = 0;
                            sram_addr = register_file[r1]; // SRAM write
                            sram_wdata = (uint16_t)(register_file[r2]&0x0000FFFF);
                            sram_write_req = 1;
                            IP = IP + 2;
                            cpu_state = CPU_WRITE_DATA;
                        }
                    }
                    break;
                    case 1: // mem2reg
                        // NOTE: VRAM reads are not possible at the moment
                        sram_enable_byteaddress = 0;
                        sram_addr = register_file[r2];
                        target_register = r1;
                        sram_read_req = 1;
                        IP = IP + 2;
                        cpu_state = CPU_READ_DATA;
                    break;
                    case 2: // reg2reg
                        register_file[r1] = register_file[r2];
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                    case 3: // word2reg
                        target_register = r1;
                        sram_enable_byteaddress = 0;
                        sram_addr = IP + 2;
                        sram_read_req = 1;
                        IP = IP + 4; // Skip the WORD we read plus the instruction
                        cpu_state = CPU_READ_DATA;
                    break;
                    case 4: // dword2regs
                        target_register = r1;
                        sram_enable_byteaddress = 0;
                        sram_addr = IP + 2;
                        sram_read_req = 1;
                        IP = IP + 6; // Skip the WORDs we read plus the instruction
                        cpu_state = CPU_READ_DATAH;
                    break;
                    case 5: // reg2mem (byte)
                    {
                        bool is_vram_address = (register_file[r1]&0x80000000)>>31 ? true:false;
                        if (is_vram_address) // VRAM write (address>=0x80000000)
                        {
                            if ((register_file[r1]&0x0000FFFF) < 0xD000) // Only if within VRAM region
                            {
                                // NOTE: VRAM ends at 0xC000 but we need to be able to address the rest for
                                // other attributes such as border color, sprite tables and such
                                framebuffer_address = register_file[r1]&0x0000FFFF;
                                framebuffer_writeena = 1;
                                // TODO: Somehow need to implement a WORD mov to VRAM
                                framebuffer_data = uint8_t(register_file[r2]&0x00FF);
                                sram_addr = IP+2;
                                IP = IP + 2;
                                sram_enable_byteaddress = 0;
                                sram_read_req = 1;
                                cpu_state = CPU_FETCH_INSTRUCTION;
                            }
                            else // Otherwise noop
                            {
                                sram_addr = IP+2;
                                IP = IP + 2;
                                sram_enable_byteaddress = 0;
                                sram_read_req = 1;
                                cpu_state = CPU_FETCH_INSTRUCTION;
                            }
                        }
                        else
                        {
                            // SRAM
                            sram_enable_byteaddress = 1;
                            sram_addr = register_file[r1]; // SRAM write
                            sram_wdata = (uint16_t)(register_file[r2]&0x000000FF);
                            sram_write_req = 1;
                            IP = IP + 2;
                            cpu_state = CPU_WRITE_DATA;
                        }
                    }
                    break;
                    case 6: // mem2reg (byte)
                        // NOTE: VRAM reads are not possible at the moment
                        sram_enable_byteaddress = 1;
                        sram_addr = register_file[r2];
                        target_register = r1;
                        sram_read_req = 1;
                        IP = IP + 2;
                        cpu_state = CPU_READ_DATA_BYTE;
                    break;
                    case 7: // byte2reg
                        target_register = r1;
                        sram_enable_byteaddress = 1;
                        sram_addr = IP + 2;
                        sram_read_req = 1;
                        IP = IP + 4; // Skip the WORD we read plus the instruction
                        cpu_state = CPU_READ_DATA_BYTE;
                    break;
                }
            }
            break;

            case INST_RET:
            {
                uint16_t op = (instruction&0b0000000000010000)>>4; // [4]
                if (op == 1) // HALT
                {
                    IP = 0x7FFFF;
                    sram_enable_byteaddress = 0;
                    sram_addr = 0x7FFFF;
                    sram_read_req = 1;
                    cpu_state = CPU_FETCH_INSTRUCTION;
                }
                else
                {
                    // Return address is in call stack - NOOP for now
                    IP = CALLSTACK[CALLSP-1];
                    sram_enable_byteaddress = 0;
                    sram_addr = CALLSTACK[CALLSP-1];
                    sram_read_req = 1;
                    CALLSP = CALLSP-1;
                    cpu_state = CPU_FETCH_INSTRUCTION;
                }
            }
            break;

            case INST_STACK:
            {
                uint16_t op = (instruction&0b0000000000010000)>>4; // [4]
                uint16_t r1 = (instruction&0b0000000011100000)>>5; // [7:5]
                switch (op)
                {
                    case 0:
                    {
                        // Push register or IP to stack
                        sram_enable_byteaddress = 0;
                        sram_addr = SP;
                        SP = SP - 4;
                        target_register = r1;
                        sram_wdata = (register_file[r1]&0xFFFF0000)>>16;
                        sram_write_req = 1;
                        IP = IP + 2;
                        cpu_state = CPU_WRITE_DATAH;
                    }
                    break;
                    case 1:
                    {
                        // Pop from stack to register
                        sram_enable_byteaddress = 0;
                        sram_addr = SP + 4;
                        SP = SP + 4;
                        target_register = r1;
                        sram_read_req = 1;
                        IP = IP + 2;
                        cpu_state = CPU_READ_DATAH;
                    }
                    break;
                }
            }
            break;

            case INST_TEST:
            {
                // [ZERO:NOTEQUAL:NOTZERO:LESS:GREATER:EQUAL] & FLAG_MASK
                uint16_t flg = (flags_register&0b0000000000111111); // [5:0]
                uint16_t msk = (instruction&0b0000001111110000)>>4; // [9:4]
                TR = flg&msk ? 1:0; // At least one bit out of the masked bits passed test against mask or no bits passed
                sram_addr = IP+2;
                IP = IP + 2;
                sram_enable_byteaddress = 0;
                sram_read_req = 1;
                cpu_state = CPU_FETCH_INSTRUCTION;
            }
            break;

            case INST_CMP:
            {
                uint16_t r1 = (instruction&0b0000000001110000)>>4; // [6:4]
                uint16_t r2 = (instruction&0b0000001110000000)>>7; // [9:7]
                flags_register = 0;
                flags_register |= (register_file[r1] == register_file[r2]) ? 1 : 0; // EQUAL
                flags_register |= (register_file[r1] > register_file[r2]) ? 2 : 0; // GREATER
                flags_register |= (register_file[r1] < register_file[r2]) ? 4 : 0; // LESS
                flags_register |= (register_file[r1] != 0) ? 8 : 0; // NOTZERO
                flags_register |= (register_file[r1] != register_file[r2]) ? 16 : 0; // NOTEQUAL
                flags_register |= (register_file[r1] == 0) ? 32 : 0; // ZERO
                sram_addr = IP+2;
                IP = IP + 2;
                sram_enable_byteaddress = 0;
                sram_read_req = 1;
                cpu_state = CPU_FETCH_INSTRUCTION;
            }
            break;

            case INST_IO:
            {
                uint16_t sub = (instruction&0b0000000001110000)>>4; // [6:4]
                uint16_t r1 = (instruction&0b0000001110000000)>>7; // [9:7]
                switch(sub)
                {
                    case 0b000: // VSYNC
                    {
                        IP = IP + 2;
                        cpu_state = CPU_WAIT_VSYNC;
                    }
                    break;
                    case 0b001: // IN
                    {
                        // TODO: Read next word (PORT)
                        // TODO: Input from given port to register_file[instruction[9:7]]
                        // TODO: Isn't this a memory mapped device MOV?
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    }
                    break;
                    case 0b010: // OUT
                    {
                        // TODO: Read next word (PORT)
                        // TODO: Output register_file[instruction[9:7]] to given port
                        // TODO: Isn't this a memory mapped device MOV?
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    }
                    break;
                    case 0b011: // FSEL
                        framebuffer_select = register_file[r1]&0x0001;
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                    case 0b100: // CLF
                        cpu_lane_mask = 0xFFFF;
                        framebuffer_address = 0x0000;
                        framebuffer_data = register_file[r1]&0x00FF;
                        IP = IP + 2;
                        cpu_state = CPU_CLEARVRAM;
                    break;
                    default: // Reserved
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                };
            }
            break;

            case INST_RELMOV:
            {
                uint16_t op = (instruction&0b0000000001110000)>>4; // [6:4]
                uint16_t r1 = (instruction&0b0000001110000000)>>7; // [9:7]
                uint16_t r2 = (instruction&0b0001110000000000)>>10; // [12:10]
                switch (op)
                {
                    case 0: // reserved
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                    case 1: // reserved
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                    case 2: // reserved
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                    case 3: // reserved
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                    case 4: // unused
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                    case 5: // unused
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                    case 6: // unused
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                    case 7: // unused
                        sram_addr = IP+2;
                        IP = IP + 2;
                        sram_enable_byteaddress = 0;
                        sram_read_req = 1;
                        cpu_state = CPU_FETCH_INSTRUCTION;
                    break;
                }
            }
            break;

            default:
            {
                sram_addr = IP+2;
                IP = IP + 2; // Unknown instructions act as NOOP during development
                sram_enable_byteaddress = 0;
                sram_read_req = 1;
                cpu_state = CPU_FETCH_INSTRUCTION;
            }
            break;
    }
}

void CPUMain()
{
    // --------------------------------------------------------------
    // CPU State Machine (same code as hardware device)
    // --------------------------------------------------------------

    if (!s_SystemClockRisingEdge)
        return;

    switch (cpu_state)
    {
        case CPU_INIT:
            IP = 0;
            SP = 0x7FFF0;
            
            // Reset write cursor for framebuffer
            framebuffer_select = 0;
            framebuffer_address = 0000;
            framebuffer_writeena = 0;
            framebuffer_data = 0;
            cpu_lane_mask = 0x0000;

            // Clear instruction and instruction data word
            instruction = 0xFFFF;

            // Clear source/target register indices and the register file
            register_file[0] = 0x00000000;
            register_file[1] = 0x00000000;
            register_file[2] = 0x00000000;
            register_file[3] = 0x00000000;
            register_file[4] = 0x00000000;
            register_file[5] = 0x00000000;
            register_file[6] = 0x00000000;
            register_file[7] = 0x00000000;

            CALLSTACK[0] = 0;
            CALLSTACK[1] = 0;
            CALLSTACK[2] = 0;
            CALLSTACK[3] = 0;
            CALLSTACK[4] = 0;
            CALLSTACK[5] = 0;
            CALLSTACK[6] = 0;
            CALLSTACK[7] = 0;
            CALLSTACK[8] = 0;
            CALLSTACK[9] = 0;
            CALLSTACK[10] = 0;
            CALLSTACK[11] = 0;
            CALLSTACK[12] = 0;
            CALLSTACK[13] = 0;
            CALLSTACK[14] = 0;
            CALLSTACK[15] = 0;
            CALLSP = 0;

            target_register = 0;
            target_registerH = 0;
            BRANCHTARGET = 0;

            // Clear status flags and Test register
            flags_register = 0; // [ZERO:NOTEQUAL:NOTZERO:LESS:GREATER:EQUAL]
            TR = 0;

            // Reset SRAM access
            sram_addr = 0;// 0x7FFFF; Slightly different behavior in hardware
            sram_read_req = 0;
            sram_wdata = 0;
            sram_write_req = 0;
            sram_enable_byteaddress = 0; // Initially we access WORDS

            // Set up ROM copy start
            rom_addrs = 0;
            rom_read_enable = 1;
            
            // Set next state to copy BIOS to top of SRAM
            cpu_state = CPU_ROM_STEP;
        break;

	    case CPU_ROM_STEP:
            // Copy current ROM data to ROM shadow address
            sram_wdata = rom_out;
            sram_write_req = 1;
            cpu_state = CPU_ROM_FETCH;
        break;

        case CPU_ROM_FETCH:
            sram_write_req = 0;
            if (rom_addrs == 0xFFF)
            {
                // Kick off the CPU state machine's pre-run stage
                cpu_state = CPU_STATE_PRE_RUN;
            }
            else
            {
                // Increment ROM address for next phase since we're not done yet
                rom_addrs = rom_addrs + 1; // Source addresses are at 16bit boundaries
                sram_addr = sram_addr + 2; // Increment 2 bytes at a time
                cpu_state = CPU_ROM_STEP;
            }
        break;

        case CPU_STATE_PRE_RUN:
            // Transitional state after ROM copy to shut off access to SRAM
            rom_read_enable = 0;
            sram_addr = 0; // Reset read address (not really required)
            sram_write_req = 0;
            sram_enable_byteaddress = 0;
            sram_read_req = 1;
            cpu_state = CPU_FETCH_INSTRUCTION;
        break;

        case CPU_FETCH_INSTRUCTION:
            sram_read_req = 0;
            framebuffer_writeena = 0;
            if (sram_addr == 0x7FFFF)
                cpu_state = CPU_FETCH_INSTRUCTION; // Spin here
            else
            {
                instruction = sram_rdata;
                cpu_state = CPU_EXECUTE_INSTRUCTION;
            }
        break;

        case CPU_SET_BRANCH_ADDRESSA:
            sram_enable_byteaddress = 0;
            sram_addr = IP;
            sram_read_req = 1;
            cpu_state = CPU_SET_BRANCH_ADDRESSB;
        break;

        case CPU_SET_BRANCH_ADDRESSB:
            BRANCHTARGET = sram_rdata;
            sram_enable_byteaddress = 0;
            sram_addr = IP+2;
            sram_read_req = 1;
            cpu_state = CPU_FETCH_ADDRESS_AND_BRANCH;
        break;

        case CPU_FETCH_ADDRESS_AND_BRANCH:
            IP = (BRANCHTARGET<<16) | sram_rdata; // Top 3 bits are not available from a 16bit read
            sram_enable_byteaddress = 0;
            sram_addr = (BRANCHTARGET<<16) | sram_rdata;
            sram_read_req = 1;
            cpu_state = CPU_FETCH_INSTRUCTION;
        break;

		case CPU_EXECUTE_INSTRUCTION:
            execute(instruction);
        break;

        case CPU_READ_DATAH:
            register_file[target_register] = (register_file[target_register]&0x0000FFFF) | (sram_rdata<<16);
            sram_addr = sram_addr + 2;
            cpu_state = CPU_READ_DATA;
        break;

        case CPU_READ_DATA:
            register_file[target_register] = (register_file[target_register]&0xFFFF0000) | sram_rdata;
            sram_enable_byteaddress = 0;
            sram_addr = IP;
            sram_read_req = 1;
            cpu_state = CPU_FETCH_INSTRUCTION;
        break;

        case CPU_READ_DATA_BYTE:
            register_file[target_register] = (register_file[target_register]&0xFFFFFF00) | sram_rdata&0x000000FF; // No C equivalent to partially assign
            sram_enable_byteaddress = 0;
            sram_addr = IP;
            sram_read_req = 1;
            cpu_state = CPU_FETCH_INSTRUCTION;
        break;

        case CPU_WRITE_DATAH:
            sram_addr = sram_addr + 2;
            // Write the low word next
            sram_wdata = register_file[target_register]&0x0000FFFF;
            cpu_state = CPU_WRITE_DATA;
        break;

        case CPU_WRITE_DATA:
            sram_write_req = 0;
            sram_enable_byteaddress = 0;
            sram_addr = IP;
            sram_read_req = 1;
            cpu_state = CPU_FETCH_INSTRUCTION;
        break;
            
        case CPU_WAIT_VSYNC:
            //if (vga_y>=V_FRONT_PORCH && vga_y<(V_FRONT_PORCH+V_SYNC))
            if (vga_y==0) // Wait for beam to reach top of horizontal pass
            {
                sram_enable_byteaddress = 0;
                sram_addr = IP;
                sram_read_req = 1;
                cpu_state = CPU_FETCH_INSTRUCTION;
            }
            else
            {
                // Spin
                cpu_state = CPU_WAIT_VSYNC;
            }
        break;

        case CPU_CLEARVRAM:
        {
            if (framebuffer_address != 0xBFFF) // NOTE: hardware clears only 0x1000 but on 12 parallel memory units
            {
                framebuffer_writeena = 1;
                framebuffer_address = framebuffer_address+1;
            }
            else
            {
                // IP = IP + 19'd2;
                cpu_lane_mask = 0x0000;
                framebuffer_writeena = 0;
                sram_enable_byteaddress = 0;
                sram_addr = IP;
                sram_read_req = 1;
                cpu_state = CPU_FETCH_INSTRUCTION;
            }
        }
        break;

        default:
        break;
    }
}

void MemoryMain()
{
    if (!s_SystemClockRisingEdge)
        return;

    // --------------------------------------------------------------
    // Update ROM/SRAM/VRAM memory access for next pass
    // --------------------------------------------------------------

    // ROM read access
    if (rom_addrs<0x7FFFF && rom_read_enable)
        rom_out = ROM[rom_addrs];

    // SRAM read/write (byte or word) access
    if (sram_addr<0x7FFFF && (sram_write_req || sram_read_req))
    {
        if (sram_enable_byteaddress)
        {
            uint16_t *sramasword = (uint16_t *)SRAM;
            uint16_t val = sramasword[sram_addr>>1];
            if (sram_read_req)
                sram_rdata = (sram_addr&1) ? val&0x00FF : (val&0xFF00)>>8;
            if (sram_write_req)
                SRAM[sram_addr] = sram_wdata&0x00FF;
        }
        else
        {
            uint16_t *wordsram = (uint16_t *)&SRAM[sram_addr];
            if (sram_read_req)
                sram_rdata = *wordsram;
            if (sram_write_req)
                *wordsram = sram_wdata;
        }
    }

    // VRAM write access
    if (framebuffer_writeena)
        VRAM[(1-framebuffer_select)*0xFFFF+framebuffer_address] = framebuffer_data;    
}

void VideoMain()
{
    if (!s_VGAClockRisingEdge)
        return;

    if (vga_x>=H_SYNC_TICKS)
    {
        vga_x = 0;
        vga_y++;
    }
    else
        vga_x++;
    if (vga_y>=V_SYNC_TICKS)
    {
        vga_y = 0;
        vga_x = 0;
    }

    int32_t scanline = vga_y-(V_FRONT_PORCH+V_SYNC+V_BACK_PORCH);

    if (vga_x>=H_FRONT_PORCH+H_SYNC+H_BACK_PORCH+64 && vga_x<H_SYNC_TICKS-64 && vga_y>=V_FRONT_PORCH+V_SYNC+V_BACK_PORCH+48 && vga_y<V_SYNC_TICKS-60) // Inside active region
    {
        uint8_t* pixels = (uint8_t*)s_Surface->pixels;

        // VRAM section
        int32_t y = scanline-48;
        int32_t actual_scanline = scanline>>1;
        int32_t actual_y = actual_scanline-18;
        uint32_t x = vga_x-(H_FRONT_PORCH+H_SYNC+H_BACK_PORCH);
        int32_t actual_x = x-64;
        uint32_t vram_out = (actual_x>>1) | (actual_y<<8);
        uint8_t vram_val = VRAM[framebuffer_select*0xFFFF+vram_out];
        uint8_t R = vram_val&0x07;
        uint8_t G = (vram_val>>3)&0x07;
        uint8_t B = (vram_val>>6)&0x03;
        pixels[4*((y+48)*s_Surface->w+x)+0] = (B*255)/3;
        pixels[4*((y+48)*s_Surface->w+x)+1] = (G*255)/7;
        pixels[4*((y+48)*s_Surface->w+x)+2] = (R*255)/7;
        pixels[4*((y+48)*s_Surface->w+x)+3] = 255;
    }
    else
    {
        uint8_t* pixels = (uint8_t*)s_Surface->pixels;

        int32_t y = scanline;
        int32_t x = vga_x-(H_FRONT_PORCH+H_SYNC+H_BACK_PORCH);
        if (x<640 && y<480 && x>=0 && y>=0)
        {
            uint32_t R = VRAM[framebuffer_select*0xFFFF+0xC000]&0x07;
            uint32_t G = (VRAM[framebuffer_select*0xFFFF+0xC000]>>3)&0x07;
            uint32_t B = (VRAM[framebuffer_select*0xFFFF+0xC000]>>6)&0x03;
            pixels[4*(y*s_Surface->w+x)+0] = (B*255)/3;
            pixels[4*(y*s_Surface->w+x)+1] = (G*255)/7;
            pixels[4*(y*s_Surface->w+x)+2] = (R*255)/7;
            pixels[4*(y*s_Surface->w+x)+3] = 255;
        }
    }
}

// NOTE: Return 'true' for 'still running'
bool StepEmulator()
{
    ClockMain();    // Clock ticks first (rising/falling edge)
    CPUMain();      // CPU state machine
    VideoMain();    // Video scan out (to tie it with 'read old data' in dualport VRAM in hardware)
    MemoryMain();   // Update all memory (SRAM/VRAM) after video data is processed

    static uint32_t K = 0;
    if (K > 0xC000)
    {
        K -= 0xC000;
        SDL_UpdateWindowSurface(s_Window);
        //static BITMAPINFO bmi = {{sizeof(BITMAPINFOHEADER),256,-192,1,8,BI_RGB,0,0,0,0,0},{0,0,0,0}};
        //StretchDIBits(hDC, 64, 48, 512, 384, 0, 0, 256, 192, VRAM, &bmi, DIB_RGB_COLORS, SRCCOPY);
    }
    ++K;

    if (vga_y == 502)
    {
        SDL_Event event;
        while(SDL_PollEvent(&event))
        {
            if(event.type == SDL_QUIT)
                return false;
            if(event.type == SDL_KEYUP)
            {
                if(event.key.keysym.sym == SDLK_SPACE)
                    cpu_state = CPU_INIT;
                if(event.key.keysym.sym == SDLK_ESCAPE)
                    return false;
            }
        }
    }

    return true;
}

bool InitEmulator(uint16_t *_rom_binary)
{
    s_SystemClock = 0b10101010101010101010101010101010;    // 50Mhz corresponds to this bit frequency
    s_VGAClock    = 0b00110011001100110011001100110011;    // 25Mhz corresponds to this bit frequency
    s_SystemClockRisingEdge  = 0;
    s_SystemClockFallingEdge = 0;
    s_VGAClockRisingEdge     = 0;
    s_VGAClockFallingEdge    = 0;
    vga_x = 0;
    vga_y = 0;

    // Initialize NEKO cpu, framebuffer and other devices
    VRAM = new uint8_t[0xFFFF * 2];
    for (uint32_t i=0;i<0xFFFF * 2;++i)
        VRAM[i] = RGBCOLOR(0,0,0);

    SRAM = new uint8_t[0x7FFFF];
    for (uint32_t i=0;i<0x7FFFF;++i)
        SRAM[i] = 0x00;

    ROM = new uint16_t[0x7FFFF];
    uint16_t *romdata = (uint16_t*)_rom_binary;
    for (uint32_t i=0;i<0x7FFFF;++i)
        ROM[i] = romdata[i];
    
    // Emulator specific:
    sram_rdata = 0;
    rom_out = 0;

    // Start SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        printf("Failed to initialize SDL video: %s\n", SDL_GetError());
        return false;
    }
    else
    {
        s_Window = SDL_CreateWindow("Neko", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480, SDL_WINDOW_SHOWN);
        if (s_Window != nullptr)
        {
            //hDC = GetDC(CreateWindowEx(WS_EX_TOPMOST,TEXT("static"), 0, WS_VISIBLE|WS_POPUP|WS_CLIPSIBLINGS|WS_CLIPCHILDREN, 0, 0, 640, 480, 0, 0, 0, 0));
            s_Surface = SDL_GetWindowSurface(s_Window);
        }
        else
        {
            printf("Failed to create SDL window: %s\n", SDL_GetError());
            return false;
        }
    }

     if (SDL_MUSTLOCK(s_Surface))
         SDL_LockSurface(s_Surface);

    // Start CPU thread
    // Video code stays on main thread async to CPU execution
    //s_CPUThread = new std::thread(CPUMain);
    //s_CPUThread->detach();

    return true;
}

void TerminateEmulator()
{
    //s_CPUDone = true;
    //s_CPUThread->join();
    //delete s_CPUThread;

    if (SDL_MUSTLOCK(s_Surface))
        SDL_UnlockSurface(s_Surface);

    SDL_FreeSurface(s_Surface);
    SDL_DestroyWindow(s_Window);
    SDL_Quit();
    
    // Clean up memory
    delete []VRAM;
    delete []SRAM;
    delete []ROM;
}