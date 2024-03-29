#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#if defined(CAT_LINUX) || defined(CAT_MACOSX)
  #include <SDL2/SDL.h>
#else
  #include "../SDL/SDL.h"
#endif
#include "emulator.h"

#include <xmmintrin.h>
#if defined(CAT_LINUX) || defined(CAT_MACOSX)
	// 
#else
#include <intrin.h>
#endif

#if !defined(__clang__)
#pragma intrinsic(_mm_pause)
#endif
#define ECPUIdle _mm_pause

// Neko emulator

// Enable this to switch to single-step mode
//#define DEBUG_EXECUTE

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
#define CPU_INIT						0b00000
#define CPU_ROM_STEP					0b00001
#define CPU_ROM_FETCH					0b00010
#define CPU_CLEARVRAM					0b00011
#define CPU_FETCH_INSTRUCTION			0b00100
#define CPU_EXECUTE_INSTRUCTION			0b00101
#define CPU_READ_DATAH					0b00110
#define CPU_READ_DATAL					0b00111
#define CPU_READ_DATA					0b01000
#define CPU_READ_DATA_BYTE				0b01001
#define CPU_WRITE_DATAH					0b01010
#define CPU_WRITE_DATA					0b01011
#define CPU_SET_BRANCH_ADDRESSH			0b01100
#define CPU_FETCH_ADDRESS_AND_BRANCH	0b01101
#define CPU_WAIT_VSYNC					0b01110
#define CPU_SPRITECOPY					0b01111
#define CPU_DIV							0b10000
#define CPU_READ_DATAH_OFFSET			0b10001
#define CPU_READ_DATAL_OFFSET			0b10010

// Sprite state machine
#define SPRITE_IDLE						0b00
#define SPRITE_FETCH_DESCRIPTOR			0b01
#define SPRITE_READ_DATA				0b10
#define SPRITE_WRITE_DATA				0b11

// CPU instructions
#define INST_LOGIC						0b0000	// 0: run logic operation and/or/xor/not/bsl/bsr on r1 and r2, write result to r3 
#define INST_BRANCH						0b0001	// 1: jump or call (direct/indirect/short/long)
#define INST_MATH						0b0010	// 2: run math operation iadd/iabs/imul/idiv/imod/ineg/inc/dec on r1 and r2, write result to r3 
#define INST_MOV						0b0011	// 3: copy reg2mem/mem2reg/reg2reg/word2reg (dword/word/byte)
#define INST_RET						0b0100	// 4: ret/halt
#define INST_STACK						0b0101	// 5: push/pop register to stack
#define INST_TEST						0b0110	// 6: test flags register against mask bits and set register to 1 or 0
#define INST_CMP						0b0111	// 7: compare r1 with r2 and set flags in given register
#define INST_IO							0b1000	// 8: wait for vsync signal / in / out to port / clear frame / frame select
#define INST_UNUSED0					0b1001	// 9: TBD
#define INST_UNUSED1					0b1010	// A: TBD
#define INST_UNUSED2					0b1011	// B: TBD
#define INST_UNUSED3					0b1100	// C: TBD
#define INST_UNUSED4					0b1101	// D: TBD
#define INST_UNUSED5					0b1110	// E: TBD
#define INST_UNUSED6					0b1111	// F: TBD

// CPU unit
uint32_t BRANCHTARGET;			// Branch target
uint32_t IP;					// Instruction pointer
uint32_t SP;					// Stack pointer
uint16_t instruction;			// Current instruction
uint32_t register_file[16];		// Array of 16 x 32bit registers
uint16_t flags_register;	   	// Flag registers [ZERO:NOTEQUAL:NOTZERO:LESS:GREATER:EQUAL]
uint16_t target_register;		// Target for some memory read operations
uint16_t offset_register;		// Used in relative addressing modes
uint16_t cpu_state = CPU_INIT;	// Default state to boot from
uint16_t CALLSP;				// Branch stack pointer
uint32_t CALLSTACK[16];			// Branch stack
uint32_t div_R;					// Div remainder
uint32_t div_Q;					// Div quotient
uint32_t div_D;					// Abs B
uint32_t div_A;					// Divident
uint32_t div_B;					// Divisor
uint32_t div_state;
uint32_t gpio_ports[16];

uint32_t sram_addr;
uint16_t sram_read_req;
uint16_t sram_rdata;
uint16_t sram_wdata;
uint16_t sram_write_req;
uint16_t sram_enable_byteaddress;

uint32_t sprite_list_addr;
uint32_t sprite_list_count;
uint32_t sprite_list_countup;
uint32_t sprite_list_el;
uint32_t sprite_sheet;
uint32_t sprite_fetch_count;
int16_t sprite_origin_x;
int16_t sprite_origin_y;
int16_t sprite_start_x;
int16_t sprite_start_y;
int16_t sprite_current_x;
int16_t sprite_current_y;
uint16_t sprite_current_id;
uint16_t sprite_flip_x;
uint16_t sprite_flip_y;
uint16_t sprite_state = SPRITE_IDLE;

uint16_t framebuffer_select;
uint16_t framebuffer_address;
uint16_t framebuffer_writeena;
uint8_t framebuffer_data;
uint16_t cpu_lane_mask;

uint16_t audio_enable;
uint16_t aram_select;
uint16_t aram_address;
uint16_t aram_writeena;
uint16_t aram_data;

// ROM unit
uint16_t rom_out;
uint16_t rom_addrs;
uint16_t rom_read_enable;

// Global clock
uint32_t s_SystemClock = 0;
uint32_t s_SystemClockRisingEdge = 0;
uint32_t s_SystemClockFallingEdge = 0;
uint32_t s_VGAClock = 0;
uint32_t s_VGAClockRisingEdge = 0;
uint32_t s_VGAClockFallingEdge = 0;

// Emulation
uint16_t *ROM;					// ROM
uint8_t *SRAM;					// SRAM
static uint8_t *VRAM;			// VRAM (Larger than FRAME_HEIGHT, including top and bottom borders)
static uint16_t *ARAM;			// ARAM (Audio RAM, 512 entries, double-buffered)
int vga_x = 0;
int vga_y = 0;
SDL_Window *s_Window;
SDL_Surface *s_Surface;
#define RGBCOLOR(_r,_g,_b) (_r | (_g<<3) | (_b<<6))
static const int FRAME_WIDTH = 256;
static const int FRAME_HEIGHT = 192;
static bool s_Done = false;
static uint32_t GPIO_CPU[16];	// Actual 'device' reads happen to here

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

void GPIOMainInput()
{
	// Read from devices (to facilitate direct pin read in hardware in IO instruction IN)
	/*GPIO_CPU[0] = 0;
	GPIO_CPU[1] = 0;
	GPIO_CPU[2] = 0;
	GPIO_CPU[3] = 0;
	GPIO_CPU[4] = 0;
	GPIO_CPU[5] = 0;
	GPIO_CPU[6] = 0;
	GPIO_CPU[7] = 0;
	GPIO_CPU[8] = 0;
	GPIO_CPU[9] = 0;
	GPIO_CPU[10] = 0;
	GPIO_CPU[11] = 0;
	GPIO_CPU[12] = 0;
	GPIO_CPU[13] = 0;
	GPIO_CPU[14] = 0;
	GPIO_CPU[15] = 0;*/
}

void GPIOMainOutput()
{
	// Write from CPU ('assign GPIO_CPU=gpio_ports' statement on hardware)
	/*for (uint32_t i=0;i<16;++i)
		GPIO_CPU[i] = gpio_ports[i];*/
}

//int breakpoint = 0xBE;
//volatile bool break_loop = true;//IP != breakpoint ? true : false;

void execute(uint16_t instr)
{
	uint16_t baseopcode = instr&0x000F;

	switch(baseopcode)
	{
		case INST_LOGIC:
		{
			uint16_t op = (instr&0b0000000001110000)>>4; // [6:4]
			uint16_t r1 = (instr&0b0000011110000000)>>7; // [10:7]
			uint16_t r2 = (instr&0b0111100000000000)>>11; // [14:11]
			switch (op)
			{
				case 0: // Or
				{
					register_file[r1] = register_file[r1] | register_file[r2];
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: or r%d, r%d (r%d = %.8X) \n", IP, r1, r2, r1, register_file[r1]);
					#endif
				}
				break;
				case 1: // And
				{
					register_file[r1] = register_file[r1] & register_file[r2];
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: and r%d, r%d (r%d = %.8X) \n", IP, r1, r2, r1, register_file[r1]);
					#endif
				}
				break;
				case 2: // Xor
				{
					register_file[r1] = register_file[r1] ^ register_file[r2];
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: xor r%d, r%d (r%d = %.8X) \n", IP, r1, r2, r1, register_file[r1]);
					#endif
				}
				break;
				case 3: // Not
				{
					register_file[r1] = ~register_file[r2];
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: not r%d (r%d = %.8X) \n", IP, r1, r1, register_file[r1]);
					#endif
				}
				break;
				case 4: // BSL
				{
					register_file[r1] = register_file[r1] << register_file[r2];
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: bsl r%d, r%d (r%d = %.8X) \n", IP, r1, r2, r1, register_file[r1]);
					#endif
				}
				break;
				case 5: // BSR
				{
					register_file[r1] = register_file[r1] >> register_file[r2];
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: bsr r%d, r%d (r%d = %.8X) \n", IP, r1, r2, r1, register_file[r1]);
					#endif
				}
				break;
				case 6: // BSWAP
				{
					uint16_t lower8 = register_file[r2]&0x000000FF;
					uint16_t upper8 = (register_file[r2]&0x0000FF00)>>8;
					register_file[r1] = upper8 | (lower8<<8);
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: bswap_l r%d, r%d (r%d = %.8X) \n", IP, r1, r2, r1, register_file[r1]);
					#endif
				}
				break;
				case 7: // RESERVED
				{
					// Nothing to do for now
				}
				break;
			}
			sram_addr = IP + 2;
			IP = IP + 2;
			sram_enable_byteaddress = 0;
			sram_read_req = 1;
			cpu_state = CPU_FETCH_INSTRUCTION;
		}
		break;

		case INST_BRANCH:
		{
			uint16_t typ = (instr&0b0100000000000000)>>14; // [14]
			uint16_t immed = (instr&0b1000000000000000)>>15; // [15]
			uint16_t si = (instr&0b0000000000110000)>>4; // [5:4]
			uint16_t r1 = (instr&0b0000001111000000)>>6; // [9:6]
			uint16_t r2 = (instr&0b0011110000000000)>>10; // [13:10]

			// NOTE: BRANCH and JMP share the same logic except the stack bit
			// Push return address to branch stack for 'BRANCH/BRANCHIF'
			#if defined(DEBUG_EXECUTE)
			const char *op = "jmp";
			#endif
			if (typ == 1)
			{
				#if defined(DEBUG_EXECUTE)
				op = "call";
				#endif
				CALLSTACK[CALLSP] = IP + (immed ? 6:2); // Skip current instruction (and two WORDs if this not register based)
				CALLSP = CALLSP + 1;
			}

			switch (si)
			{
				case 0b00: // Unconditional branch - jmp/branch
				{
					if (immed == 1)
					{
						#if defined(DEBUG_EXECUTE)
						uint16_t *wordsram0 = (uint16_t *)&SRAM[IP+2];
						uint16_t *wordsram1 = (uint16_t *)&SRAM[IP+4];
						printf("%.8X: %s %.4X%.4X\n", IP, op, *wordsram0, *wordsram1);
						#endif
						// Read branch address from next DWORD in memory
						sram_enable_byteaddress = 0;
						sram_addr = IP + 2;
						IP = IP + 2; // CALL DWORD
						sram_read_req = 1;
						cpu_state = CPU_SET_BRANCH_ADDRESSH;
					}
					else
					{
						#if defined(DEBUG_EXECUTE)
						printf("%.8X: %s r%d (%.8X)\n", IP, op, r1, register_file[r1]);
						#endif
						// Use address in register pair inside instruction
						IP = register_file[r1]; // CALL [R1]
						sram_enable_byteaddress = 0;
						sram_addr = register_file[r1];
						sram_read_req = 1;
						cpu_state = CPU_FETCH_INSTRUCTION;
					}
				}
				break;

				case 0b01: // When tested register is true - jmp/branch if
				{
					if ((register_file[r2]&0x00000001) == 1)
					{
						if (immed == 1)
						{
							#if defined(DEBUG_EXECUTE)
							uint16_t *wordsram0 = (uint16_t *)&SRAM[IP+2];
							uint16_t *wordsram1 = (uint16_t *)&SRAM[IP+4];
							printf("%.8X: %sif %.4X%.4X (taken)\n", IP, op, *wordsram0, *wordsram1);
							#endif
							// Read branch address from next DWORD in memory
							sram_enable_byteaddress = 0;
							sram_addr = IP + 2;
							IP = IP + 2; // CALL DWORD
							sram_read_req = 1;
							cpu_state = CPU_SET_BRANCH_ADDRESSH;
						}
						else
						{
							#if defined(DEBUG_EXECUTE)
							printf("%.8X: %sif r%d (%.8X) (taken)\n", IP, op, r1, register_file[r1]);
							#endif
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
							#if defined(DEBUG_EXECUTE)
							uint16_t *wordsram0 = (uint16_t *)&SRAM[IP+2];
							uint16_t *wordsram1 = (uint16_t *)&SRAM[IP+4];
							printf("%.8X: %sif %.4X%.4X (not taken)\n", IP, op, *wordsram0, *wordsram1);
							#endif
							sram_addr = IP + 6;
							IP = IP + 6; // Skip the next WORD in memory since it's not a command (short (16bit) branch address)
						}
						else
						{
							#if defined(DEBUG_EXECUTE)
							printf("%.8X: %sif r%d (%.8X) (not taken)\n", IP, op, r1, register_file[r1]);
							#endif
							sram_addr = IP + 2;
							IP = IP + 2; // Does not take the branch if previous call to TEST failed
						}
						sram_enable_byteaddress = 0;
						sram_read_req = 1;
						cpu_state = CPU_FETCH_INSTRUCTION;
					}
				}
				break;

				case 0b10:
				{
					// UNUSED YET - HALT
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: undefined - halt\n", IP);
					#endif
					IP = 0x7FFFF;
					sram_enable_byteaddress = 0;
					sram_addr = 0x7FFFF;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;

				case 0b11: // When tested register is false - jmp/branch ifnot
				{
					if ((register_file[r2]&0x00000001) == 0)
					{
						if (immed == 1)
						{
							#if defined(DEBUG_EXECUTE)
							uint16_t *wordsram0 = (uint16_t *)&SRAM[IP+2];
							uint16_t *wordsram1 = (uint16_t *)&SRAM[IP+4];
							printf("%.8X: %sifnot %.4X%.4X (taken)\n", IP, op, *wordsram0, *wordsram1);
							#endif
							// Read branch address from next WORD in memory (short jump, only 16 bits)
							sram_enable_byteaddress = 0;
							sram_addr = IP + 2;
							IP = IP + 2; // CALL WORD
							sram_read_req = 1;
							cpu_state = CPU_SET_BRANCH_ADDRESSH;
						}
						else
						{
							#if defined(DEBUG_EXECUTE)
							printf("%.8X: %sifnot r%d (%.8X) (taken)\n", IP, op, r1, register_file[r1]);
							#endif
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
							#if defined(DEBUG_EXECUTE)
							uint16_t *wordsram0 = (uint16_t *)&SRAM[IP+2];
							uint16_t *wordsram1 = (uint16_t *)&SRAM[IP+4];
							printf("%.8X: %sifnot %.4X%.4X (not taken)\n", IP, op, *wordsram0, *wordsram1);
							#endif
							sram_addr = IP + 6;
							IP = IP + 6; // Skip the next WORD in memory since it's not a command (short (16bit) branch address)
						}
						else
						{
							#if defined(DEBUG_EXECUTE)
							printf("%.8X: %sifnot r%d (%.8X) (not taken)\n", IP, op, r1, register_file[r1]);
							#endif
							sram_addr = IP + 2;
							IP = IP + 2; // Does not take the branch if previous call to TEST failed
						}
						sram_enable_byteaddress = 0;
						sram_read_req = 1;
						cpu_state = CPU_FETCH_INSTRUCTION;
					}
				}
				break;
			}
		}
		break;

		case INST_MATH:
		{
			uint16_t op = (instr&0b0000000001110000)>>4; // [6:4]
			//uint16_t subop = (instr&0b0000001110000000)>>7; // [9:7]
			uint16_t r1 = (instr&0b0000111100000000)>>8; // [11:8]
			uint16_t r2 = (instr&0b1111000000000000)>>12; // [15:12]
			switch (op)
			{
				case 0: // iadd
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: iadd r%d, r%d (r%d = %.8X, r%d = %.8X)\n", IP, r1, r2, r1, register_file[r1], r2, register_file[r2]);
					#endif
					register_file[r1] = register_file[r1] + register_file[r2];
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
				case 1: // iabs
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: iabs r%d, r%d (r%d = %.8X, r%d = %.8X)\n", IP, r1, r2, r1, register_file[r1], r2, register_file[r2]);
					#endif
					register_file[r1] = register_file[r2]&0x80000000 ? ((register_file[r2]^0xFFFFFFFF) + 1)&0x7FFFFFFF : register_file[r2];
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
				case 2: // imul
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: imul r%d, r%d (r%d = %.8X + r%d = %.8X)\n", IP, r1, r2, r1, register_file[r1], r2, register_file[r2]);
					#endif
					register_file[r1] = register_file[r1] * register_file[r2];
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
				case 3: // idiv
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: idiv r%d, r%d (r%d = %.8X + r%d = %.8X)\n", IP, r1, r2, r1, register_file[r1], r2, register_file[r2]);
					#endif
					div_A = register_file[r1];
					div_B = register_file[r2];
					div_Q = 0;
					div_state = 0;
					target_register = r1;
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_DIV;
				}
				break;
				case 4: // imod
				{
					register_file[r1] = register_file[r1] % register_file[r2];
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: imod r%d, r%d (r%d = %.8X + r%d = %.8X)\n", IP, r1, r2, r1, register_file[r1], r2, register_file[r2]);
					#endif
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
				case 5: // ineg
				{
					register_file[r1] = (register_file[r1]^0xFFFFFFFF)+1;
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: ineg r%d (r%d = %.8X)\n", IP, r1, r1, register_file[r1]);
					#endif
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
				case 6: // inc
				{
					register_file[r1] = register_file[r1] + 1;
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: inc r%d (r%d = %.8X)\n", IP, r1, r1, register_file[r1]);
					#endif
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
				case 7: // dec
				{
					register_file[r1] = register_file[r1] - 1;
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: dec r%d (r%d = %.8X)\n", IP, r1, r1, register_file[r1]);
					#endif
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
			}
		}
		break;

		case INST_MOV:
		{
			uint16_t op = (instr&0b0000000011110000)>>4; // [7:4]
			uint16_t r1 = (instr&0b0000111100000000)>>8; // [11:8]
			uint16_t r2 = (instr&0b1111000000000000)>>12; // [15:12]
			switch (op)
			{
				case 0: // [r1] <- (word)r2
				{
					bool is_aram_address = (register_file[r1]&0x40000000)>>30 ? true:false;
					if (is_aram_address) // ARAM write (0x40000000)
					{
						#if defined(DEBUG_EXECUTE)
						printf("%.8X: st.b(aram) r%d (%.8X), r%d (%.8X)\n", IP, r1, register_file[r1], r2, register_file[r2]);
						#endif
						// Warning! In hardware, incoming addresses will be byte-adjusted therefore are x2 (even), we need to divide them by 2 (i.e use [10:1] instead of [9:0])
						aram_address = (register_file[r1]&0x0000FFFF)>>1;
						aram_writeena = 1;
						aram_data = uint16_t(register_file[r2]&0x0000FFFF);
						sram_addr = IP + 2;
						IP = IP + 2;
						sram_enable_byteaddress = 0;
						sram_read_req = 1;
						cpu_state = CPU_FETCH_INSTRUCTION;
					}
					else
					{
						// SRAM
						#if defined(DEBUG_EXECUTE)
						printf("%.8X: st.w(sram) r%d (%.8X), r%d (%.8X)\n", IP, r1, register_file[r1], r2, register_file[r2]);
						#endif
						sram_enable_byteaddress = 0;
						sram_addr = register_file[r1]; // SRAM write
						sram_wdata = (uint16_t)(register_file[r2]&0x0000FFFF);
						sram_write_req = 1;
						IP = IP + 2;
						cpu_state = CPU_WRITE_DATA;
					}
				}
				break;

				case 1: // r1 <- (word)[r2]
				{
					// NOTE: VRAM reads are not possible at the moment
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: ld.w r%d, [r%d] (r%d=[%.8X])\n", IP, r1, r2, r1, register_file[r2]);
					#endif
					sram_enable_byteaddress = 0;
					sram_addr = register_file[r2];
					target_register = r1;
					sram_read_req = 1;
					IP = IP + 2;
					cpu_state = CPU_READ_DATA;
				}
				break;

				case 2: // r1 <- (dword)r2
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: reg2reg(sram) r%d (%.8X), r%d (%.8X)\n", IP, r1, register_file[r1], r2, register_file[r2]);
					#endif
					register_file[r1] = register_file[r2];
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;

				case 3: // r1 <- (word)[IP+2]
				{
					#if defined(DEBUG_EXECUTE)
					uint16_t *wordsram0 = (uint16_t *)&SRAM[IP+2];
					printf("%.8X: ld.w r%d, %.4X\n", IP, r1, *wordsram0);
					#endif
					target_register = r1;
					sram_enable_byteaddress = 0;
					sram_addr = IP + 2;
					sram_read_req = 1;
					IP = IP + 4; // Skip the WORD we read plus the instruction
					cpu_state = CPU_READ_DATA;
				}
				break;

				case 4: // r1 <- (dword)([IP+2],[IP+4])
				{
					#if defined(DEBUG_EXECUTE)
					uint16_t *wordsram0 = (uint16_t *)&SRAM[IP+2];
					uint16_t *wordsram1 = (uint16_t *)&SRAM[IP+4];
					printf("%.8X: ld.d/lea r%d, %.4X%.4X\n", IP, r1, *wordsram0, *wordsram1);
					#endif
					target_register = r1;
					sram_enable_byteaddress = 0;
					sram_addr = IP + 2;
					sram_read_req = 1;
					IP = IP + 6; // Skip the DWORD read read plus the instruction
					cpu_state = CPU_READ_DATAH;
				}
				break;

				case 5: // [r1] <- (byte)r2
				{
					bool is_vram_address = (register_file[r1]&0x80000000)>>31 ? true:false;
					if (is_vram_address) // VRAM write (0x80000000)
					{
						//if ((register_file[r1]&0x0000FFFF) < 0xD000) // Only if within VRAM region
						{
							#if defined(DEBUG_EXECUTE)
							printf("%.8X: st.b(vram) r%d (%.8X), r%d (%.8X)\n", IP, r1, register_file[r1], r2, register_file[r2]);
							#endif
							// NOTE: VRAM ends at 0xC000 but we need to be able to address the rest for
							// other attributes such as border color etc
							framebuffer_address = register_file[r1]&0x0000FFFF;
							framebuffer_writeena = 1;
							// TODO: Somehow need to implement a WORD mov to VRAM
							framebuffer_data = uint8_t(register_file[r2]&0x00FF);
						}
						sram_addr = IP + 2;
						IP = IP + 2;
						sram_enable_byteaddress = 0;
						sram_read_req = 1;
						cpu_state = CPU_FETCH_INSTRUCTION;
					}
					else
					{
						// SRAM
						#if defined(DEBUG_EXECUTE)
						printf("%.8X: st.b(sram) r%d r%d (%.8X = %.8X)\n", IP, r1, r2, register_file[r1], register_file[r2]);
						#endif
						sram_enable_byteaddress = 1;
						sram_addr = register_file[r1]; // SRAM write
						sram_wdata = (uint16_t)(register_file[r2]&0x000000FF);
						sram_write_req = 1;
						IP = IP + 2;
						cpu_state = CPU_WRITE_DATA;
					}
				}
				break;

				case 6: // r1 <- (byte)[r2]
				{
					// NOTE: VRAM reads are not possible at the moment
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: ld.b r%d, [r%d] (r%d=[%.8X])\n", IP, r1, r2, r1, register_file[r2]);
					#endif
					sram_enable_byteaddress = 1;
					sram_addr = register_file[r2];
					target_register = r1;
					sram_read_req = 1;
					IP = IP + 2;
					cpu_state = CPU_READ_DATA_BYTE;
				}
				break;

				case 7: // r1 <- (byte)[IP+2]
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: byte2reg(sram,byte) r%d (%.8X), r%d (%.8X)\n", IP, r1, register_file[r1], r2, register_file[r2]);
					#endif
					target_register = r1;
					sram_enable_byteaddress = 1;
					sram_addr = IP + 2;
					sram_read_req = 1;
					IP = IP + 4; // Skip the WORD we read plus the instruction
					cpu_state = CPU_READ_DATA_BYTE;
				}
				break;

				case 8: // r1 <- (dword)[r2]
				{
					// NOTE: VRAM reads are not possible at the moment
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: ld.d r%d, [r%d] (r%d=[%.8X])\n", IP, r1, r2, r1, register_file[r2]);
					#endif
					sram_enable_byteaddress = 0;
					sram_addr = register_file[r2];
					target_register = r1;
					sram_read_req = 1;
					IP = IP + 2;
					cpu_state = CPU_READ_DATAH;
				}
				break;

				case 9: // [r1] <- (dword)r2
				{
					// SRAM only
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: st.d(sram) r%d (%.8X), r%d (%.8X)\n", IP, r1, register_file[r1], r2, register_file[r2]);
					#endif
					sram_enable_byteaddress = 0;
					sram_addr = register_file[r1]; // SRAM write
					target_register = r2;
					sram_wdata = (register_file[r2]&0xFFFF0000)>>16;
					sram_write_req = 1;
					IP = IP + 2;
					cpu_state = CPU_WRITE_DATAH;
				}
				break;

				case 10: // r1 <- (dword)([IP+2],[IP+4] + r2)
				{
					#if defined(DEBUG_EXECUTE)
					uint16_t *wordsram0 = (uint16_t *)&SRAM[IP+2];
					uint16_t *wordsram1 = (uint16_t *)&SRAM[IP+4];
					printf("%.8X: ldidx.d/leaidx r%d, %.4X%.4X + r%d (%.8x)\n", IP, r1, *wordsram0, *wordsram1, r2, register_file[r2]);
					#endif
					target_register = r1;
					offset_register = r2;
					sram_enable_byteaddress = 0;
					sram_addr = IP + 2;
					sram_read_req = 1;
					IP = IP + 6; // Skip the DWORD read read plus the instruction
					cpu_state = CPU_READ_DATAH_OFFSET;
				}
				break;

				default:
				{
					IP = IP + 2;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
			}
		}
		break;

		case INST_RET:
		{
			uint16_t op = (instr&0b0000000000010000)>>4; // [4]
			if (op == 1) // HALT
			{
				#if defined(DEBUG_EXECUTE)
				printf("%.8X: halt\n", IP);
				#endif
				IP = 0x7FFFF;
				sram_enable_byteaddress = 0;
				sram_addr = 0x7FFFF;
				sram_read_req = 1;
				cpu_state = CPU_FETCH_INSTRUCTION;
			}
			else
			{
				#if defined(DEBUG_EXECUTE)
				printf("%.8X: ret\n", IP);
				#endif
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
			uint16_t op = (instr&0b0000000000010000)>>4; // [4]
			uint16_t r1 = (instr&0b0000000111100000)>>5; // [8:5]
			switch (op)
			{
				case 0:
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: push r%d (%.8X) (SP=%.8X)\n", IP, r1, register_file[r1], SP);
					#endif
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
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: pop r%d (SP=%.8X)\n", IP, r1, SP);
					#endif
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
			uint16_t msk = (instr&0b0000001111110000)>>4; // [9:4]
			uint16_t r1 =  (instr&0b0011110000000000)>>10; // [13:10]
			register_file[r1] = (flg&msk) ? 1:0; // At least one bit out of the masked bits passed test against mask or no bits passed
			sram_addr = IP + 2;
			IP = IP + 2;
			sram_enable_byteaddress = 0;
			sram_read_req = 1;
			cpu_state = CPU_FETCH_INSTRUCTION;
			#if defined(DEBUG_EXECUTE)
			printf("%.8X: test %d -> r1==%d\n", IP, msk, register_file[r1]);
			#endif
		}
		break;

		case INST_CMP:
		{
			uint16_t r1 = (instr&0b0000000011110000)>>4; // [7:4]
			uint16_t r2 = (instr&0b0000111100000000)>>8; // [11:8]
			#if defined(DEBUG_EXECUTE)
			printf("%.8X: cmp r%d (%.8X), r%d  (%.8X)\n", IP, r1, register_file[r1], r2, register_file[r2]);
			#endif
			flags_register = 0;
			flags_register |= (register_file[r1] == register_file[r2]) ? 1 : 0;		// EQUAL
			flags_register |= (register_file[r1] > register_file[r2]) ? 2 : 0;		// GREATER
			flags_register |= (register_file[r1] < register_file[r2]) ? 4 : 0;		// LESS
			flags_register |= (register_file[r1] != 0) ? 8 : 0;						// NOTZERO
			flags_register |= (register_file[r1] != register_file[r2]) ? 16 : 0;	// NOTEQUAL
			flags_register |= (register_file[r1] == 0) ? 32 : 0;					// ZERO
			sram_addr = IP + 2;
			IP = IP + 2;
			sram_enable_byteaddress = 0;
			sram_read_req = 1;
			cpu_state = CPU_FETCH_INSTRUCTION;
		}
		break;

		case INST_IO:
		{
			uint16_t sub = (instr&0b0000000011110000)>>4; // [7:4]
			uint16_t r1  = (instr&0b0000111100000000)>>8; // [11:8]
			uint16_t r2  = (instr&0b1111000000000000)>>12; // [15:12]
			switch(sub)
			{
				case 0b0000: // VSYNC
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: vsync\n", IP);
					#endif
					IP = IP + 2;
					cpu_state = CPU_WAIT_VSYNC;
				}
				break;
				case 0b0001: // IN
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: in r%d<-r%d\n", IP, r1, r2);
					#endif
					sram_enable_byteaddress = 0;
					sram_addr = register_file[r1];
					sram_wdata = uint16_t(GPIO_CPU[register_file[r2]]);
					sram_write_req = 1;
					IP = IP + 2;
					cpu_state = CPU_WRITE_DATA;
				}
				break;
				case 0b0010: // OUT
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: out r%d<-r%d\n", IP, r1, r2);
					#endif
					gpio_ports[register_file[r2]] = register_file[r1];
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
				case 0b0011: // FSEL
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: fsel r%d (%.8X)\n", IP, r1, register_file[r1]);
					#endif
					framebuffer_select = register_file[r1]&0x0001;
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
				case 0b0100: // CLF
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: clf r%d (%.8X)\n", IP, r1, register_file[r1]);
					#endif
					cpu_lane_mask = 0xFFFF;
					framebuffer_address = 0x0000;
					framebuffer_data = register_file[r1]&0x00FF;
					IP = IP + 2;
					cpu_state = CPU_CLEARVRAM;
				}
				break;
				case 0b0101: // SPRITE
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: sprite r%d, r%d\n", IP, r1, r2);
					#endif
					// Kick sprite table DMA
					sprite_list_addr = register_file[r1];
					sprite_list_count = register_file[r2]&0x0000FFFF;
					sprite_list_countup = 0;
					sprite_list_el = 0;
					IP = IP + 2;
					sram_read_req = 0;
					framebuffer_address = 0;
					sprite_fetch_count = 0;
					sprite_state = SPRITE_FETCH_DESCRIPTOR;
					cpu_state = CPU_SPRITECOPY;
				}
				break;
				case 0b0110: // SPRITESHEET
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: spritesheet r%d\n", IP, r1);
					#endif
					sprite_sheet = register_file[r1];
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
				case 0b0111: // ASEL
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: asel r%d (%.8X), r%d (%.8X)\n", IP, r1, register_file[r1], r2, register_file[r2]);
					#endif
					aram_select = register_file[r1]&0x0001;
					audio_enable = register_file[r2]&0x0001;
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
				case 0b1000: // SPRITEORIGIN
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: spriteorigin r%d, r%d\n", IP, r1, r2);
					#endif
					// Kick sprite table DMA
					sprite_origin_x = register_file[r1]&0xFFFF;
					sprite_origin_y = register_file[r2]&0xFFFF;
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
				default: // RESERVED
				{
					#if defined(DEBUG_EXECUTE)
					printf("%.8X: io(undef) r%d (%.8X)\n", IP, r1, register_file[r1]);
					#endif
					// ???
					sram_addr = IP + 2;
					IP = IP + 2;
					sram_enable_byteaddress = 0;
					sram_read_req = 1;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
			};
		}
		break;

		default:
		{
			printf("%.8X: illegal instruction %.4X, CPU halted\n", IP, instr);
			IP = 0x7FFFF;
			sram_enable_byteaddress = 0;
			sram_addr = 0x7FFFF;
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

	// Main CPU
	switch (cpu_state)
	{
		case CPU_INIT:
		{
			div_A = 0;
			div_B = 0;
			div_Q = 0;
			div_R = 0;
			div_D = 0;
			div_state = 0;

			for (int i=0;i<16;++i)
				gpio_ports[i] = 0;

			sprite_list_addr = 0;
			sprite_list_count = 0;
			sprite_list_countup = 0;
			sprite_list_el = 0;
			sprite_sheet = 0;
			sprite_fetch_count = 0;
			sprite_origin_x = 0;
			sprite_origin_y = 0;
			sprite_start_x = 0;
			sprite_start_y = 0;
			sprite_current_x = 0;
			sprite_current_y = 0;
			sprite_current_id = 0;
			sprite_flip_x = 0;
			sprite_flip_y = 0;
			sprite_state = SPRITE_IDLE;

			IP = 0;
			SP = 0x7FFF0;
			
			// Reset write cursor for framebuffer
			framebuffer_select = 0;
			framebuffer_address = 0x000;
			framebuffer_writeena = 0;
			framebuffer_data = 0;
			cpu_lane_mask = 0x0000;

			// Reset write cursor for audio buffer
			aram_select = 0;
			audio_enable = 0;
			aram_address = 0x0000;
			aram_writeena = 0;
			aram_data = 0;

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
			register_file[8] = 0x00000000;
			register_file[9] = 0x00000000;
			register_file[10] = 0x00000000;
			register_file[11] = 0x00000000;
			register_file[12] = 0x00000000;
			register_file[13] = 0x00000000;
			register_file[14] = 0x00000000;
			register_file[15] = 0x00000000;

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
			BRANCHTARGET = 0;

			// Clear status flags and Test register
			flags_register = 0; // [ZERO:NOTEQUAL:NOTZERO:LESS:GREATER:EQUAL]

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
		}
		break;

		case CPU_ROM_STEP:
		{
			// Copy current ROM data to ROM shadow address
			sram_wdata = rom_out;
			sram_write_req = 1;
			cpu_state = CPU_ROM_FETCH;
		}
		break;

		case CPU_ROM_FETCH:
		{
			sram_write_req = 0;
			if (rom_addrs == 0xFFFF)
			{
				rom_read_enable = 0;
				sram_addr = 0; // Reset read address (not really required)
				sram_write_req = 0;
				sram_enable_byteaddress = 0;
				sram_read_req = 1;
				cpu_state = CPU_FETCH_INSTRUCTION;
			}
			else
			{
				// Increment ROM address for next phase since we're not done yet
				rom_addrs = rom_addrs + 1; // Source addresses are at 16bit boundaries
				sram_addr = sram_addr + 2; // Increment 2 bytes at a time
				cpu_state = CPU_ROM_STEP;
			}
		}
		break;

		case CPU_FETCH_INSTRUCTION:
		{
			target_register = 0;
			sram_read_req = 0;
			framebuffer_writeena = 0;
			aram_writeena = 0;
			if (sram_addr == 0x7FFFF)
				cpu_state = CPU_FETCH_INSTRUCTION; // Spin here
			else
			{
				instruction = sram_rdata;
				cpu_state = CPU_EXECUTE_INSTRUCTION;
			}
		}
		break;

		case CPU_SET_BRANCH_ADDRESSH:
		{
			BRANCHTARGET = sram_rdata;
			sram_enable_byteaddress = 0;
			sram_addr = IP + 2;
			sram_read_req = 1;
			cpu_state = CPU_FETCH_ADDRESS_AND_BRANCH;
		}
		break;

		case CPU_FETCH_ADDRESS_AND_BRANCH:
		{
			IP = ((BRANCHTARGET&7)<<16) | sram_rdata; // Top 3 bits are not available from a 16bit read
			sram_enable_byteaddress = 0;
			sram_addr = (BRANCHTARGET<<16) | sram_rdata;
			sram_read_req = 1;
			cpu_state = CPU_FETCH_INSTRUCTION;
		}
		break;

		case CPU_EXECUTE_INSTRUCTION:
		{
			execute(instruction);
		}
		break;

		case CPU_READ_DATAH_OFFSET:
		{
			register_file[target_register] = (sram_rdata<<16) | (register_file[target_register]&0x0000FFFF);
			sram_addr = sram_addr + 2;
			cpu_state = CPU_READ_DATAL_OFFSET;
		}
		break;

		case CPU_READ_DATAL_OFFSET:
		{
			register_file[target_register] = ((register_file[target_register]&0xFFFF0000) | sram_rdata) + register_file[offset_register];
			sram_enable_byteaddress = 0;
			sram_addr = IP;
			sram_read_req = 1;
			cpu_state = CPU_FETCH_INSTRUCTION;
		}
		break;

		case CPU_READ_DATAH:
		{
			register_file[target_register] = (sram_rdata<<16) | (register_file[target_register]&0x0000FFFF);
			sram_addr = sram_addr + 2;
			cpu_state = CPU_READ_DATAL;
		}
		break;

		case CPU_READ_DATAL:
		{
			register_file[target_register] = (register_file[target_register]&0xFFFF0000) | sram_rdata;
			sram_enable_byteaddress = 0;
			sram_addr = IP;
			sram_read_req = 1;
			cpu_state = CPU_FETCH_INSTRUCTION;
		}
		break;

		case CPU_READ_DATA:
		{
			//uint32_t signextend = sram_rdata&0x8000 ? 0xFFFF0000 : 0x00000000;
			register_file[target_register] = /*signextend |*/ sram_rdata;
			sram_enable_byteaddress = 0;
			sram_addr = IP;
			sram_read_req = 1;
			cpu_state = CPU_FETCH_INSTRUCTION;
		}
		break;

		case CPU_READ_DATA_BYTE:
		{
			//uint32_t signextend = sram_rdata&0x80 ? 0xFFFFFF00 : 0x00000000;
			register_file[target_register] = /*signextend |*/ (sram_rdata&0xFF);
			sram_enable_byteaddress = 0;
			sram_addr = IP;
			sram_read_req = 1;
			cpu_state = CPU_FETCH_INSTRUCTION;
		}
		break;

		case CPU_WRITE_DATAH:
		{
			sram_addr = sram_addr + 2;
			// Write the low word next
			sram_wdata = register_file[target_register]&0x0000FFFF;
			cpu_state = CPU_WRITE_DATA;
		}
		break;

		case CPU_WRITE_DATA:
		{
			sram_write_req = 0;
			sram_enable_byteaddress = 0;
			sram_addr = IP;
			sram_read_req = 1;
			cpu_state = CPU_FETCH_INSTRUCTION;
		}
		break;

		case CPU_WAIT_VSYNC:
		{
			//if (vga_y>=V_FRONT_PORCH && vga_y<(V_FRONT_PORCH+V_SYNC)) // Wait for beam to reach vsync region
			if (vga_y>=490)
			{
				// TODO: Kick vblank handler here?
				// Will resume from next instruction
				// CALLSTACK[CALLSP] = IP + 2;
				// CALLSP = CALLSP + 1;

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
		}
		break;

		case CPU_CLEARVRAM:
		{
			if (framebuffer_address != 0xBFFF) // NOTE: Hardware version clears only 0x1000 entries x 12 in parallel
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

		case CPU_SPRITECOPY:
		{
			switch (sprite_state)
			{
				case SPRITE_IDLE:
					sprite_state = SPRITE_IDLE; // Spin
				break;

				case SPRITE_FETCH_DESCRIPTOR:
				{
					if (sprite_fetch_count == 0)
					{
						sram_addr = sprite_list_addr + sprite_list_countup*6; // Y
						sram_read_req = 1;
						sram_enable_byteaddress = 0;
						sprite_fetch_count = sprite_fetch_count + 1;
						sprite_state = SPRITE_FETCH_DESCRIPTOR;
					}
					else if (sprite_fetch_count == 1)
					{
						sprite_start_y = sprite_origin_y + sram_rdata; // Store Y
						sram_read_req = 0;
						sprite_fetch_count = sprite_fetch_count + 1;
						sprite_state = SPRITE_FETCH_DESCRIPTOR;
					}
					else if (sprite_fetch_count == 2)
					{
						sram_addr = sprite_list_addr + sprite_list_countup*6 + 2; // X
						sram_read_req = 1;
						sram_enable_byteaddress = 0;
						sprite_fetch_count = sprite_fetch_count + 1;
						sprite_state = SPRITE_FETCH_DESCRIPTOR;
					}
					else if (sprite_fetch_count == 3)
					{
						sprite_start_x = sprite_origin_x + sram_rdata; // Store X
						sram_read_req = 0;
						sprite_fetch_count = sprite_fetch_count + 1;
						sprite_state = SPRITE_FETCH_DESCRIPTOR;
					}
					else if (sprite_fetch_count == 4)
					{
						sram_addr = sprite_list_addr + sprite_list_countup*6 + 4; // ID
						sram_read_req = 1;
						sram_enable_byteaddress = 0;
						sprite_fetch_count = sprite_fetch_count + 1;
						sprite_state = SPRITE_FETCH_DESCRIPTOR;
					}
					else if (sprite_fetch_count == 5)
					{
						sram_read_req = 0;
						sprite_current_id = sram_rdata&0x0FFF; // Store ID
						sprite_flip_x = sram_rdata&0x8000 ? 0xF : 0x0;
						sprite_flip_y = sram_rdata&0x4000 ? 0xF : 0x0;
						sprite_list_countup = sprite_list_countup + 1;

						// Sprite tile early reject
						if (sprite_start_y>192 || sprite_start_y<-15 || sprite_start_x>255 || sprite_start_x<-15)
							sprite_list_el = 0x100;
						else
							sprite_list_el = 0;

						sprite_state = SPRITE_READ_DATA;
					}
				}
				break;

				case SPRITE_READ_DATA:
				{
					sram_addr = sprite_sheet + (sprite_current_id<<8) + sprite_list_el;
					sprite_current_x = sprite_start_x + (sprite_flip_x ^ (sprite_list_el&0x0F));
					sprite_current_y = sprite_start_y + (sprite_flip_y ^ ((sprite_list_el&0xF0)>>4));
					sram_read_req = 1;
					sram_enable_byteaddress = 1;
					framebuffer_writeena = 0;
					sprite_state = SPRITE_WRITE_DATA;
				}
				break;

				case SPRITE_WRITE_DATA:
				{
					if (((sprite_list_el&0x100)>>8) == 1) // Past the end of sprite
					{
						if (sprite_list_countup < sprite_list_count)
						{
							// Read more sprites
							sram_read_req = 0;
							sprite_fetch_count = 0;
							sprite_state = SPRITE_FETCH_DESCRIPTOR;
						}
						else
						{
							// Done with all sprites
							sram_addr = IP;
							sram_read_req = 1;
							sram_enable_byteaddress = 0;
							sprite_fetch_count = 0;
							cpu_state = CPU_FETCH_INSTRUCTION;
							sprite_state = SPRITE_IDLE;
						}
					}
					else
					{
						if ((sram_rdata&0xFF) != 0xFF && sprite_current_id!=0x0FFF) // TODO: Make mask color code controlled
						{
							// Per pixel sprite cull
							if (sprite_current_y < 192 && sprite_current_x < 256 && sprite_current_y >= 0 && sprite_current_x >= 0)
							{
								framebuffer_address = (sprite_current_y<<8) + sprite_current_x;
								framebuffer_writeena = 1;
								framebuffer_data = sram_rdata&0x00FF;
							}
						}
						sprite_list_el = sprite_list_el + 1; // Next pixel
						sram_read_req = 0;
						sprite_state = SPRITE_READ_DATA;
					}
				}
				break;
			}
		}
		break;

		case CPU_DIV:
		{
			switch(div_state)
			{
				case 0:
				{
					div_R = div_A&0x80000000 ? ((div_A^0xFFFFFFFF) + 1)&0x7FFFFFFF : div_A; // Abs A
					div_D = div_B&0x80000000 ? ((div_B^0xFFFFFFFF) + 1)&0x7FFFFFFF : div_B; // Abs B
					div_state = 1;
					cpu_state = CPU_DIV;
				}
				break;
				case 1:
				{
					div_Q = div_R / div_D;
					//div_R = div_R + ((div_D^0xFFFFFFFF)+1);
					//if((div_R&0x80000000)) // Done dividing when remainder goes negative
						div_state = 2;
					//else
					//	div_Q++;
					cpu_state = CPU_DIV;
				}
				break;
				case 2:
				{
					// Final result has the sign of xor of A and B
					register_file[target_register] = ((div_A&0x80000000) ^ (div_B&0x80000000)) ? ((div_Q^0xFFFFFFFF)+1) : div_Q;
					div_state = 0;
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
				default:
				{
					cpu_state = CPU_FETCH_INSTRUCTION;
				}
				break;
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
	// Update ROM/SRAM/VRAM/ARAM memory access for next pass
	// --------------------------------------------------------------

	// ROM read access
	if (/*rom_addrs<0x7FFFF &&*/ rom_read_enable)
		rom_out = ROM[rom_addrs];

	/*if (!sram_read_req)
		sram_rdata = rand()%0xFFFF; // NOTE: Ruin the contents so that we are sure that we read correctly
	if (!sram_write_req)
		sram_wdata = rand()%0xFFFF;*/

	// SRAM read/write (byte or word) access
	if (sram_addr<0x7FFFF && (sram_write_req || sram_read_req))
	{
		if (sram_enable_byteaddress)
		{
			if (sram_read_req)
			{
				uint16_t *sramasword = (uint16_t *)SRAM;
				uint16_t val = sramasword[sram_addr>>1];
				sram_rdata = (sram_addr&1) ? val&0x00FF : (val&0xFF00)>>8;
				//if (!rom_read_enable) printf("(R:B)0x%.8x -> 0x%.8x\n", sram_addr, sram_rdata);
			}
			if (sram_write_req)
			{
				SRAM[sram_addr] = sram_wdata&0x00FF;
				//if (!rom_read_enable) printf("(W:B)0x%.8x <- 0x%.8x\n", sram_addr, sram_wdata&0x00FF);
			}
		}
		else
		{
			uint16_t *wordsram = (uint16_t *)&SRAM[sram_addr];
			if (sram_read_req)
			{
				sram_rdata = *wordsram;
				//if (!rom_read_enable) printf("(R:W)0x%.8x -> 0x%.8x\n", sram_addr, sram_rdata);
			}
			if (sram_write_req)
			{
				*wordsram = sram_wdata;
				//if (!rom_read_enable) printf("(W:W)0x%.8x <- 0x%.8x\n", sram_addr, sram_wdata);
			}
		}
	}

	// TODO: ARAM write access
	if (aram_writeena)
		ARAM[(1-aram_select)*1024+aram_address] = aram_data;

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

	if (vga_x>=H_FRONT_PORCH+H_SYNC+H_BACK_PORCH+64 && vga_x<H_SYNC_TICKS-64 && vga_y>=V_FRONT_PORCH+V_SYNC+V_BACK_PORCH+48 && vga_y<V_SYNC_TICKS-48) // Inside active region
	{
		uint8_t* pixels = (uint8_t*)s_Surface->pixels;

		// VRAM section
		int32_t y = scanline-48;
		int32_t actual_scanline = scanline>>1;
		int32_t actual_y = actual_scanline-24;
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
			pixels[4*(y*s_Surface->w+x)+0] = uint8_t((B*255)/3);
			pixels[4*(y*s_Surface->w+x)+1] = uint8_t((G*255)/7);
			pixels[4*(y*s_Surface->w+x)+2] = uint8_t((R*255)/7);
			pixels[4*(y*s_Surface->w+x)+3] = 255;
		}
	}
}

int RunDevice(void *data)
{
	while(!s_Done)
	{
		ClockMain();		// Clock ticks first (rising/falling edge)
		//if (break_loop)
		{
   			GPIOMainInput();	// Update inputs on pins
			CPUMain();			// CPU state machine
			VideoMain();		// Video scan out (to tie it with 'read old data' in dualport VRAM in hardware, memory writes come after)
			MemoryMain();		// Update all memory (SRAM/VRAM/ARAM) after video data is processed
			//GPIOMainOutput();	// Update outputs on pins
			//_mm_pause();
		}
		//break_loop = cpu_state>=CPU_FETCH_INSTRUCTION ? false : true;
	}
	return 0;
}

// NOTE: Return 'true' for 'still running'
bool StepEmulator()
{
	static uint32_t K = 0;
	if (K > 0x623E0) // 800*503 pixel's worth of video clock (full VGA clock cycle for one frame for 640*480 image)
	{
		ECPUIdle();
		K -= 0x623E0;
		SDL_UpdateWindowSurface(s_Window);

		SDL_Event event;
		while(SDL_PollEvent(&event))
		{
			if(event.type == SDL_QUIT)
				s_Done = true;
			if(event.type == SDL_KEYUP)
			{
				/*if(event.key.keysym.sym == SDLK_SPACE)
 					break_loop = true;*/
				if(event.key.keysym.sym == SDLK_r)
					cpu_state = CPU_INIT;
				if(event.key.keysym.sym == SDLK_ESCAPE)
					s_Done = true;
			}
		}
	}
	K += s_VGAClockRisingEdge ? 1:0;

	return s_Done ? false : true;
}

void MyAudioCallback(void*  userdata,
                       Uint8* stream,
                       int    len)
{
	float *output = (float*)stream;
	int count = len/sizeof(float); // bytes to indices
	for(int i=0; i<count; ++i)
		output[i] = audio_enable ? ((float)ARAM[aram_select*1024 + i]+16384.f)/32768.f : 0.f;
}

bool InitEmulator(uint16_t *_rom_binary)
{
	s_SystemClock	= 0b10101010101010101010101010101010;	// 50Mhz corresponds to this bit frequency
	s_VGAClock		= 0b00110011001100110011001100110011;	// 25Mhz corresponds to this bit frequency
	s_SystemClockRisingEdge		= 0;
	s_SystemClockFallingEdge	= 0;
	s_VGAClockRisingEdge		= 0;
	s_VGAClockFallingEdge		= 0;
	vga_x = 0;
	vga_y = 0;

	// Init VRAM
	VRAM = new uint8_t[0xFFFF * 2];
	for (uint32_t i=0;i<0xFFFF * 2;++i)
		VRAM[i] = 0;

	// Init ARAM
	ARAM = new uint16_t[1024 * 2];
	for (uint32_t i=0;i<1024 * 2;++i)
		ARAM[i] = 0;

	// Init SRAM to all zeros
	SRAM = new uint8_t[0x7FFFF];
	for (uint32_t i=0;i<0x7FFFF;++i)
		SRAM[i] = 0x00;

	// Init ROM to binary from file
	ROM = new uint16_t[0x20000];
	uint16_t *romdata = (uint16_t*)_rom_binary;
	for (uint32_t i=0;i<0x20000;++i)
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

	SDL_InitSubSystem(SDL_INIT_AUDIO);
	SDL_AudioSpec want, have;
	SDL_AudioDeviceID dev;
	SDL_memset(&want, 0, sizeof(want)); /* or SDL_zero(want) */
	want.freq = 18750;
	want.format = AUDIO_F32;
	want.channels = 2;
	want.samples = 512; // *2 for stereo
	want.callback = MyAudioCallback;

	dev = SDL_OpenAudioDevice(NULL, 0, &want, &have, SDL_AUDIO_ALLOW_FORMAT_CHANGE);
	if (dev == 0) {
		SDL_Log("Failed to open audio: %s", SDL_GetError());
	} else {
		if (have.format != want.format) { /* we let this one thing change. */
			SDL_Log("We didn't get correct audio format.");
		}
		SDL_PauseAudioDevice(dev, 0); /* start audio playing. */
	}

	 if (SDL_MUSTLOCK(s_Surface))
		 SDL_LockSurface(s_Surface);

	SDL_CreateThread(RunDevice, "RunDevice", nullptr);

	return true;
}

void TerminateEmulator()
{
	if (SDL_MUSTLOCK(s_Surface))
		SDL_UnlockSurface(s_Surface);

	SDL_FreeSurface(s_Surface);
	SDL_DestroyWindow(s_Window);
	SDL_QuitSubSystem(SDL_INIT_AUDIO);
	SDL_Quit();
	
	// Clean up memory
	delete []ARAM;
	delete []VRAM;
	delete []SRAM;
	delete []ROM;
}

int EmulateROMImage(const char *_romname)
{
	// Read ROM file
	FILE *inputfile = fopen(_romname, "rb");
	if (inputfile == nullptr)
	{
		printf("ERROR: Cannot find ROM file %s\n", _romname);
		return -1;
	}

	printf("Running ROM file %s\n", _romname);

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
	filebytesize = filebytesize<0x20000 ? filebytesize : 0x20000;

	// Allocate memory and read file contents, then close the file
	uint16_t *rom_binary = new uint16_t[0x20000];
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

	delete [] rom_binary;
	
	// Clean up, report errors etc
	TerminateEmulator();

	return 0;
}
