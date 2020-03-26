#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <thread>
#include "../SDL/SDL.h"
#include "emulator.h"

// Neko emulator

// Video
// CPU clock(50Mhz) is twice as fast as VGA clock(25Mhz)
// Each horizontal scan is 800 VGA clocks
// This means CPU has taken 1600 clocks until the end of one scanline
// However since out video unit ticks at half the rate, we can count 800 of these
#define HSYNC_TICKS 800

// CPU state machine
#define CPU_INIT						0b0000
#define CPU_ROM_STEP					0b0001
#define CPU_ROM_FETCH					0b0010
#define CPU_SET_INSTRUCTION_POINTER		0b0011
#define CPU_HALT						0b0100
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
#define INST_MOV						0b0011	// 3: copy reg2mem/mem2reg/reg2reg/word2reg
#define INST_RET						0b0100	// 4: ret/halt
#define INST_STACK						0b0101	// 5: push/pop register to stack
#define INST_TEST						0b0110	// 6: test flags register against mask bits and set TR register to 1 or 0
#define INST_CMP						0b0111	// 7: compare r1 with r2 and set flags register
#define INST_IO							0b1000	// 8: wait for vsync signal / in / out to port
#define INST_BMOV						0b1001	// 9: copy reg2mem/mem2reg/reg2reg (byte)
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
uint16_t register_file[8];	    // Array of 8 16bit registers
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
static const int FRAME_WIDTH = 320;
static const int FRAME_HEIGHT = 204;
static uint8_t *VRAM; // Larger than FRAME_HEIGHT, including top and bottom borders

uint16_t framebuffer_address;
uint16_t framebuffer_writeena;
uint8_t framebuffer_data;

// ROM unit
uint16_t *ROM;
uint16_t rom_out;
uint16_t rom_addrs;
uint16_t rom_read_enable;

// SDL
SDL_Window *s_Window;
SDL_Surface *s_Surface;

// Global clock
uint64_t s_GlobalClock = 0;

// CPU emulation
std::thread *s_CPUThread;
bool s_CPUDone = false;

// Video emulation
int video_refresh_ticks = 0;
uint32_t scanline = 0;

const char *s_state_string[]={
    "CPU_INIT",
    "CPU_ROM_STEP",
    "CPU_ROM_FETCH",
    "CPU_SET_INSTRUCTION_POINTER",
    "CPU_HALT",
    "CPU_FETCH_INSTRUCTION",
    "CPU_EXECUTE_INSTRUCTION",
    "CPU_UNUSED",
    "CPU_STATE_PRE_RUN",
    "CPU_READ_DATA",
    "CPU_WRITE_DATA",
    "CPU_SET_BRANCH_ADDRESSA",
    "CPU_FETCH_ADDRESS_AND_BRANCH",
    "CPU_WAIT_VSYNC",
    "CPU_READ_DATA_BYTE",
    "CPU_SET_BRANCH_ADDRESSB"
};

// NOTE: Return 'true' for 'still running'
bool StepEmulator()
{
    s_GlobalClock++;

    video_refresh_ticks += s_GlobalClock%2 == 0 ? 1 : 0;

    // --------------------------------------------------------------
    // Video output: processed every HSYNC_TICKS clock cycles
    // --------------------------------------------------------------

    if (video_refresh_ticks>HSYNC_TICKS)
    {
        video_refresh_ticks -= HSYNC_TICKS;

        uint8_t* pixels = (uint8_t*)s_Surface->pixels;

        // VRAM section
        if (scanline>=18 && scanline<222)
        {
            //for (uint32_t y=0;y<204;++y)
            uint32_t y = scanline-18;
            {
                for (uint32_t x=0;x<320;++x)
                {
                    uint32_t vram_out = x + y*320;
                    uint8_t vram_val = VRAM[vram_out];
                    uint8_t R = vram_val&0x07;
                    uint8_t G = (vram_val>>3)&0x07;
                    uint8_t B = (vram_val>>6)&0x03;
                    pixels[4*((y+18)*s_Surface->w+x)+0] = B*(256/3);
                    pixels[4*((y+18)*s_Surface->w+x)+1] = G*(256/7);
                    pixels[4*((y+18)*s_Surface->w+x)+2] = R*(256/7);
                    pixels[4*((y+18)*s_Surface->w+x)+3] = 255;
                }
            }
        }

        // Top border color
        if (scanline<18)
        {
            //for (uint32_t y=0;y<18;++y)
            uint32_t y = scanline;
            {
                for (uint32_t x=0;x<320;++x)
                {
                    uint32_t R = VRAM[0xFF00]&0x07;
                    uint32_t G = (VRAM[0xFF00]>>3)&0x07;
                    uint32_t B = (VRAM[0xFF00]>>6)&0x03;
                    pixels[4*(y*s_Surface->w+x)+0] = B*(256/3);
                    pixels[4*(y*s_Surface->w+x)+1] = G*(256/7);
                    pixels[4*(y*s_Surface->w+x)+2] = R*(256/7);
                    pixels[4*(y*s_Surface->w+x)+3] = 255;
                }
            }
        }

        // Bottom border color
        if (scanline>=222)
        {
            //for (uint32_t y=222;y<240;++y)
            uint32_t y = scanline;
            {
                for (uint32_t x=0;x<320;++x)
                {
                    uint32_t R = VRAM[0xFF00]&0x07;
                    uint32_t G = (VRAM[0xFF00]>>3)&0x07;
                    uint32_t B = (VRAM[0xFF00]>>6)&0x03;
                    pixels[4*(y*s_Surface->w+x)+0] = B*(256/3);
                    pixels[4*(y*s_Surface->w+x)+1] = G*(256/7);
                    pixels[4*(y*s_Surface->w+x)+2] = R*(256/7);
                    pixels[4*(y*s_Surface->w+x)+3] = 255;
                }
            }
        }

        ++scanline;

        if (scanline >= 240)
        {
            //SDL_PumpEvents();

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

            SDL_UpdateWindowSurface(s_Window);
            scanline = 0;
        }
    }

    return true; // Still alive
}

void CPUMain()
{
    // --------------------------------------------------------------
    // CPU State Machine (same code as hardware device)
    // --------------------------------------------------------------

    while (!s_CPUDone)
    {
    switch (cpu_state)
    {
        case CPU_INIT:
            IP = 0;
            SP = 0x7FFFE;
            
            // Reset write cursor for framebuffer
            framebuffer_address = 0000;
            framebuffer_writeena = 0;
            framebuffer_data = 0;

            // Clear instruction and instruction data word
            instruction = 0xFFFF;

            // Clear source/target register indices and the register file
            register_file[0] = 0x0000;
            register_file[1] = 0x0000;
            register_file[2] = 0x0000;
            register_file[3] = 0x0000;
            register_file[4] = 0x0000;
            register_file[5] = 0x0000;
            register_file[6] = 0x0000;
            register_file[7] = 0x0000;
            
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
            cpu_state = CPU_SET_INSTRUCTION_POINTER;
        break;

        case CPU_HALT:
            // Does nothing
            // At a CPU halt time, We're supposed to sit here and wait for a hard reset
            // Loop back to our own tail
            framebuffer_writeena = 0; // Stop VRAM writes from previous instruction
            sram_write_req = 0;
            sram_read_req = 0;
            cpu_state = CPU_HALT;
        break;

        case CPU_SET_INSTRUCTION_POINTER:
            framebuffer_writeena = 0; // Stop VRAM writes from previous instruction
            // Halt the CPU if we are going past the end of memory (last 16 bytes of memory are inaccessible for this purpose)
            if (IP == 0x7FFFF)
            {
                cpu_state = CPU_HALT;
            }
            else
            {
                sram_enable_byteaddress = 0;
                sram_addr = IP;
                sram_read_req = 1;
                cpu_state = CPU_FETCH_INSTRUCTION;
            }
        break;

        case CPU_FETCH_INSTRUCTION:
            instruction = sram_rdata;
            sram_read_req = 0;
            cpu_state = CPU_EXECUTE_INSTRUCTION;
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
            sram_read_req = 0;
            cpu_state = CPU_SET_INSTRUCTION_POINTER;
        break;

		case CPU_EXECUTE_INSTRUCTION:
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
                        case 6: // BSWAP
                        {
                            uint16_t lower8 = register_file[r2]&0x00FF;
                            uint16_t upper8 = (register_file[r2]&0xFF00)>>8;
                            register_file[r1] = upper8 | (lower8<<8);
                        }
                        break;
                        case 7: // unused
                        break;
                    }
                    IP = IP + 2;
                    cpu_state = CPU_SET_INSTRUCTION_POINTER;
                }
                break;

                case INST_BRANCH:
                {
                    uint16_t typ = (instruction&0b0100000000000000)>>14; // [14]
                    uint16_t immed = (instruction&0b1000000000000000)>>15; // [15]
                    uint16_t si = (instruction&0b0000000000110000)>>4; // [5:4]
                    uint16_t r1 = (instruction&0b0011100000000000)>>11; // [13:11]
                    uint16_t r2 = (instruction&0b0000011100000000)>>8; // [10:8]

                    // NOTE: BRANCH and JMP share the same logic except the stack bit
                    {
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
                                    IP = ((register_file[r1]&0x0003)<<16) | register_file[r2]; // CALL [R1:R2]
                                    cpu_state = CPU_SET_INSTRUCTION_POINTER;
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
                                            IP = ((register_file[r1]&0x0003)<<16) | register_file[r2]; // CALL [R1:R2]
                                            cpu_state = CPU_SET_INSTRUCTION_POINTER;
                                        }
                                    }
                                    else
                                    {
                                        if (immed == 1)
                                        {
                                            IP = IP + 6; // Skip the next WORD in memory since it's not a command (short (16bit) branch address)
                                        }
                                        else
                                        {
                                            IP = IP + 2; // Does not take the branch if previous call to TEST failed
                                        }
                                        cpu_state = CPU_SET_INSTRUCTION_POINTER;
                                    }
                                break;
                                case 0b10:
                                    // UNUSED YET - HALT
                                    IP = 0x7FFFF;
                                    cpu_state = CPU_SET_INSTRUCTION_POINTER;
                                break;
                                case 0b11:
                                    // UNUSED YET - HALT
                                    IP = 0x7FFFF;
                                    cpu_state = CPU_SET_INSTRUCTION_POINTER;
                                break;
                            }
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
                        IP = IP + 2;
                        cpu_state = CPU_SET_INSTRUCTION_POINTER;
                    }
                    break;

                    case INST_MOV:
                    {
                        uint16_t op = (instruction&0b0000000001110000)>>4; // [6:4]
                        uint16_t r1 = (instruction&0b0000001110000000)>>7; // [9:7]
                        uint16_t r2 = (instruction&0b0001110000000000)>>10; // [12:10]
                        uint16_t r3 = (instruction&0b1110000000000000)>>13; // [15:13]
                        switch (op)
                        {
                            case 0: // reg2mem
                            {
                                bool is_vram_address = (register_file[r1]&0b1000000000000000)>>15 ? true:false;
                                if (is_vram_address) // VRAM write (address>=0x80000000)
                                {
                                    // NOTE: VRAM ends at 0xFF00 but we need to be able to address the rest for
                                    // other attributes such as border color, sprite tables and such
                                    framebuffer_address = register_file[r2];
                                    framebuffer_writeena = 1;
                                    // TODO: Somehow need to implement a WORD mov to VRAM
                                    framebuffer_data = uint8_t(register_file[r3]&0x00FF);
                                    IP = IP + 2;
                                    cpu_state = CPU_SET_INSTRUCTION_POINTER;
                                }
                                else
                                {
                                    // SRAM
                                    sram_enable_byteaddress = 0;
                                    sram_addr = ((register_file[r1]&0x0003)<<16) | register_file[r2]; // SRAM write
                                    sram_wdata = register_file[r3];
                                    sram_write_req = 1;
                                    IP = IP + 2;
                                    cpu_state = CPU_WRITE_DATA;
                                }
                            }
                            break;
                            case 1: // mem2reg
                                // NOTE: VRAM reads are not possible at the moment
                                sram_enable_byteaddress = 0;
                                sram_addr = ((register_file[r2]&0x0003)<<16) | register_file[r3];
                                target_register = r1;
                                sram_read_req = 1;
                                IP = IP + 2;
                                cpu_state = CPU_READ_DATA;
                            break;
                            case 2: // reg2reg
                                register_file[r1] = register_file[r2];
                                IP = IP + 2;
                                cpu_state = CPU_SET_INSTRUCTION_POINTER;
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
                                target_register = r2;
                                target_registerH = r1;
                                sram_enable_byteaddress = 0;
                                sram_addr = IP + 2;
                                sram_read_req = 1;
                                IP = IP + 6; // Skip the WORDs we read plus the instruction
                                cpu_state = CPU_READ_DATAH;
                            break;
                            case 5: // unused
                                IP = IP + 2;
                                cpu_state = CPU_SET_INSTRUCTION_POINTER;
                            break;
                            case 6: // unused
                                IP = IP + 2;
                                cpu_state = CPU_SET_INSTRUCTION_POINTER;
                            break;
                            case 7: // unused
                                IP = IP + 2;
                                cpu_state = CPU_SET_INSTRUCTION_POINTER;
                            break;
                        }
                    }
                    break;

                    case INST_RET:
                    {
                        uint16_t op = (instruction&0b0000000000010000)>>4; // [4]
                        if (op == 1) // HALT
                        {
                            cpu_state = CPU_HALT;
                        }
                        else
                        {
                            // Return address is in call stack - NOOP for now
                            IP = CALLSTACK[CALLSP-1];
                            CALLSP = CALLSP-1;
                            cpu_state = CPU_SET_INSTRUCTION_POINTER;
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
                                SP = SP - 2;
                                sram_wdata = register_file[r1];
                                sram_write_req = 1;
                                IP = IP + 2;
                                cpu_state = CPU_WRITE_DATA;
                            }
                            break;
                            case 1:
                            {
                                // Pop from stack to register
                                sram_enable_byteaddress = 0;
                                sram_addr = SP + 2;
                                SP = SP + 2;
                                target_register = r1;
                                sram_read_req = 1;
                                IP = IP + 2;
                                cpu_state = CPU_READ_DATA;
                            }
                            break;
                        }
                    }
                    break;

                    case INST_TEST:
                    {
                        // [ZERO:NOTEQUAL:CARRY:LESS:GREATER:EQUAL] & FLAG_MASK
                        uint16_t flg = (flags_register&0b0000000000111111); // [5:0]
                        uint16_t msk = (instruction&0b0000001111110000)>>4; // [9:4]
                        TR = flg&msk ? 1:0; // At least one bit out of the masked bits passed test against mask or no bits passed
                        IP = IP + 2;
                        cpu_state = CPU_SET_INSTRUCTION_POINTER;
                    }
                    break;

                    case INST_CMP:
                    {
                        uint16_t r1 = (instruction&0b0000000001110000)>>4; // [6:4]
                        uint16_t r2 = (instruction&0b0000001110000000)>>7; // [9:7]
                        flags_register = 0;
                        flags_register |= register_file[r2] == register_file[r1] ? 1 : 0; // EQUAL
                        flags_register |= register_file[r2] > register_file[r1] ? 2 : 0; // GREATER
                        flags_register |= register_file[r2] < register_file[r1] ? 4 : 0; // LESS
                        flags_register |= register_file[r2] != 0 ? 8 : 0; // NOTZERO
                        flags_register |= register_file[r2] != register_file[r1] ? 16 : 0; // NOTEQUAL
                        flags_register |= register_file[r2] == 0 ? 32 : 0; // ZERO
                        IP = IP + 2;
                        cpu_state = CPU_SET_INSTRUCTION_POINTER;
                    }
                    break;

                    case INST_IO:
                    {
                        uint16_t sub = (instruction&0b0000000001110000)>>4; // [6:4]
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
                                IP = IP + 2;
                                cpu_state = CPU_SET_INSTRUCTION_POINTER;
                            }
                            break;
                            case 0b010: // OUT
                            {
                                // TODO: Read next word (PORT)
                                // TODO: Output register_file[instruction[9:7]] to given port
                                // TODO: Isn't this a memory mapped device MOV?
                                IP = IP + 2;
                                cpu_state = CPU_SET_INSTRUCTION_POINTER;
                            }
                            break;
                            default:
                            break;
                        };
                    }
                    break;

                    case INST_BMOV:
                    {
                        uint16_t op = (instruction&0b0000000001110000)>>4; // [6:4]
                        uint16_t r1 = (instruction&0b0000001110000000)>>7; // [9:7]
                        uint16_t r2 = (instruction&0b0001110000000000)>>10; // [12:10]
                        uint16_t r3 = (instruction&0b1110000000000000)>>13; // [15:13]
                        switch (op)
                        {
                            case 0: // reg2mem
                            {
                                bool is_vram_address = (register_file[r1]&0b1000000000000000)>>15 ? true:false;
                                if (is_vram_address) // VRAM write (address>=0x80000000)
                                {
                                    // NOTE: VRAM ends at 0xFF00 but we need to be able to address the rest for
                                    // other attributes such as border color, sprite tables and such
                                    framebuffer_address = register_file[r2];
                                    framebuffer_writeena = 1;
                                    // TODO: Somehow need to implement a WORD mov to VRAM
                                    framebuffer_data = uint8_t(register_file[r3]&0x00FF);
                                    IP = IP + 2;
                                    cpu_state = CPU_SET_INSTRUCTION_POINTER;
                                }
                                else
                                {
                                    // SRAM
                                    sram_enable_byteaddress = 1;
                                    sram_addr = ((register_file[r1]&0x0003)<<16) | register_file[r2]; // SRAM write
                                    sram_wdata = register_file[r3]&0x00FF;
                                    sram_write_req = 1;
                                    IP = IP + 2;
                                    cpu_state = CPU_WRITE_DATA;
                                }
                            }
                            break;
                            case 1: // mem2reg
                                // NOTE: VRAM reads are not possible at the moment
                                sram_enable_byteaddress = 1;
                                sram_addr = ((register_file[r2]&0x0003)<<16) | register_file[r3];
                                target_register = r1;
                                sram_read_req = 1;
                                IP = IP + 2;
                                cpu_state = CPU_READ_DATA_BYTE;
                            break;
                            case 2: // reg2reg
                                register_file[r1] = (register_file[r1]&0xFF00) | register_file[r2];
                                IP = IP + 2;
                                cpu_state = CPU_SET_INSTRUCTION_POINTER;
                            break;
                            case 3: // byte2reg
                                target_register = r1;
                                sram_enable_byteaddress = 1;
                                sram_addr = IP + 2;
                                sram_read_req = 1;
                                IP = IP + 4; // Skip the WORD we read plus the instruction
                                cpu_state = CPU_READ_DATA_BYTE;
                            break;
                            case 4: // unused
                                IP = IP + 2;
                                cpu_state = CPU_SET_INSTRUCTION_POINTER;
                            break;
                            case 5: // unused
                                IP = IP + 2;
                                cpu_state = CPU_SET_INSTRUCTION_POINTER;
                            break;
                            case 6: // unused
                                IP = IP + 2;
                                cpu_state = CPU_SET_INSTRUCTION_POINTER;
                            break;
                            case 7: // unused
                                IP = IP + 2;
                                cpu_state = CPU_SET_INSTRUCTION_POINTER;
                            break;
                        }
                    }
                    break;

                    default:
                    {
                        IP = IP + 2; // Unknown instructions act as NOOP during development
                        cpu_state = CPU_SET_INSTRUCTION_POINTER;
                    }
                    break;

                }
            }
            break;

            case CPU_READ_DATAH:
                register_file[target_registerH] = sram_rdata; // Copy read data to target register
                sram_addr = sram_addr + 2;
                cpu_state = CPU_READ_DATA;
            break;

            case CPU_READ_DATA:
                register_file[target_register] = sram_rdata; // Copy read data to target register
                sram_read_req = 0; // Stop read request and resume
                cpu_state = CPU_SET_INSTRUCTION_POINTER;
            break;

            case CPU_READ_DATA_BYTE:
                register_file[target_register] = (register_file[target_register]&0xFF00) | sram_rdata&0x00FF; // No C equivalent to partially assign
                sram_read_req = 0; // Stop read request and resume
                cpu_state = CPU_SET_INSTRUCTION_POINTER;
            break;

            case CPU_WRITE_DATA:
                sram_write_req = 0; // Stop write request and resume
                cpu_state = CPU_SET_INSTRUCTION_POINTER;
            break;
            
            case CPU_WAIT_VSYNC:
                if(scanline>=239) // TODO: Video out is not really precise in the emulator
                    cpu_state = CPU_SET_INSTRUCTION_POINTER;
            break;

            default:
            break;
        }

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
                if (sram_write_req == 0) // Read SRAM
                    sram_rdata = (sram_addr&1) ? val&0x00FF : (val&0xFF00)>>8;
                else
                    SRAM[sram_addr] = sram_wdata&0x00FF;
            }
            else
            {
                uint16_t *wordsram = (uint16_t *)&SRAM[sram_addr];
                if (sram_write_req == 0) // Read SRAM
                    sram_rdata = *wordsram;
                else
                    *wordsram = sram_wdata;
            }
        }

        // VRAM write access
        if (framebuffer_writeena)
            VRAM[framebuffer_address] = framebuffer_data;
    }
}

bool InitEmulator(uint16_t *_rom_binary)
{
    s_GlobalClock = 0;
    video_refresh_ticks = 0;
    scanline = 0;

    // Initialize NEKO cpu, framebuffer and other devices
    VRAM = new uint8_t[FRAME_WIDTH*FRAME_HEIGHT];
    for (uint32_t i=0;i<FRAME_WIDTH*FRAME_HEIGHT;++i)
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
        s_Window = SDL_CreateWindow("Neko", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 320, 240, SDL_WINDOW_SHOWN);
        if (s_Window != nullptr)
            s_Surface = SDL_GetWindowSurface(s_Window);
        else
        {
            printf("Failed to create SDL window: %s\n", SDL_GetError());
            return false;
        }
    }

    // Start CPU thread
    // Video code stays on main thread async to CPU execution
    s_CPUThread = new std::thread(CPUMain);
    s_CPUThread->detach();

    return true;
}

void TerminateEmulator()
{
    s_CPUDone = true;
    //s_CPUThread->join();
    delete s_CPUThread;

    SDL_FreeSurface(s_Surface);
    SDL_DestroyWindow(s_Window);
    SDL_Quit();
    
    // Clean up memory
    delete []VRAM;
    delete []SRAM;
    delete []ROM;
}