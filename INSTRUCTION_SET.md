# Project Neko Instruction Set Manual

Project Neko is a small game console aimed at FPGAs.
It has a 16 bit CPU, and has access to 512Kbytes of SRAM. The VRAM is made up of on-chip dual port block memory and delivers an image at 256x192 resolution and 8bpp.

The architecture is currently implemented on the [Terasic Cyclone V GX Starter Kit](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=167&No=830) and uses up about 12 to 13 percent of the resources available on the FPGA.

There is also an assembler/emulator which can generate ROM images out of ASM files and run the ROM files to test out code while the actual hardware is being developed.

Here is a brief list of the architecture details of Neko V3

  * 16 bit instruction set
    * Bottom 4 bits of instructions contain the 'base instruction' code
    * Currently only 8 out of these 16 base instructions are used
    * Each instruction has variety of sub-instructions
    * Rest of the bits on the instruction define either sub-instuctions, register indices, some other useful flag bits in any predetermined order
  * 40Mhz core clock
    * The main CPU unit runs at 40Mhz
    * Most instructions take 1 clock cycle to execute
    * Additional clocks are required for SRAM read/writes if instruction requires
    * Shortest instruction is 16 bits
    * Longest instruction is 48 bits (1 instruction word + 2 words for parameters)
  * 512 kilobytes of SRAM
    * The SRAM is the main memory for Neko
    * It can be addressed in byte or word mode
    * Simplifies the CPU by requiring almost no caching
      * SRAM access is at CPU speed
      * Incurs 1 cycle read/write penalty (on top of instruction cycle cost)
  * 256 x 192 x 8bpp VRAM
    * VRAM can only be accessed as bytes
    * VRAM starts at memory address 0x8000:0000
    * Each byte is packed as 2:3:3 bits (B:G:R)
    * There is a somewhat wide border at the edges of the screen
      * This keeps VRAM addresses in the 0x8000:0000-0x8000:C000 range so access fits into a single WORD
      * Border color can be changed by setting byte at 0x8000:C000 to a 2:3:3 color
    * There is currently no hardware unit drawing onto the screen except the CPU
      * A 2D SRAM->VRAM DMA is being planned (sprites/bitmaps/text output)
      * In addition, a BVH8 voxel rasterization unit is being planned

# Memory layout

```
|----------------|  0x00000000
|      SRAM      |
|                |
|                |
|    ^STACK^     |
|----------------|  0x0007FFFF
|                |
|      TBD       |  NOTE: This region is not addressable for now
|                |
|----------------|  0x80000000
|                |
|      VRAM      |
|                |
|----------------|  0x8000C000
|                |
| DEVICE CONTROL |
|                |
|----------------|  0x8000D000
```

The working memory starts at address 0x00000000 and continues up to 0x7FFFFFFF, out of which currently only 512Kbytes is actual physical memory.
Instructions are often considered to start at even address boundaries to simplify the hardware access pattern and reduce access times.
Starting at 0x80000000 resides the VRAM which only allows for byte access, and ends at address 0x8000BFFF.
At the addresses from 0x8000C000 to 0x8000D000 lives a variety of device control bytes.
Following diagram shows the uses of each byte starting at the device control address
```
|----------------| 
| BORDER COLOR   | 0x8000C000 - Color to use outside drawable area
|----------------| 
| VBSENABLE      | 0x8000C001 - VBlank service control, non-zero if VBLANKSERVICE is to be used
|----------------| 
| UNUSED         | 0x8000C002
|----------------| 
| UNUSED         | 0x8000C003
|----------------| 
| VBLANKSERVICE  | 0x8000C004:0x8000C007 - Address of the vblank service function
|----------------| 
| UNUSED         | 0x8000C008
~                ~
|----------------| 
| UNUSED         | 0x8000D000
```

# Video output
The actual video output resolution in hardware is set to 640x480 @60Hz. Since the video memory is much smaller than this, each pixel is magnified to 2 times the size in both the horizontal and vertical directions, and centered inside a border region, giving an effective resolution of 256x192 pixels.

However, video memory addresseses are kept within 16 bit range for convenience, where the X coordinate occupies the lower 8 bits. This is merely for convenience where address calculations may follow the form:

```c
VRAM_ADDRESS = (0x8000<<16) | (x | y<<8);
```

To compensate for the missing parts of the image due to this address restriction, the video output looks like the following diagram:
```
                     256 pixels
    24  |--------------------------------|
 pixels |           Border               |
        |--------------------------------| 0x8000 0000 (VRAM start)
        |-                               |
        |-                               |
    192 |-                               |
 pixels |-        Video Area             |
        |-                               |
        |- 12x(256x16) pixel slices      |
        |-                               |
        |--------------------------------| 0x8000 BFFF (last pixel, inclusive)
    24  |           Border               |
 pixels |--------------------------------|
```

NOTE:

The video hardware actually splits this 192 pixel region into 12 bands, 256*16 pixels each. There is also an extra (13th) band starting at address 0xC000 which is the video attributes memory (including the border color) and is not part of the video output logic.

The reason for the banded approach is simply for fast clears; each band in hardware is enabled for writes simultaneously using a lane mask, and only 0x1000 writes are made instead of 0xC000 writes giving a speedup of x12 for a single color VRAM clear operation.

# Sprites
Neko supports 16x16 hardware sprites, controlled by a sprite table in SRAM. To select the table and its length, a single instruction can be used as follows:
```c
// R1 points at the sprite sheet to use for a series of sprites
spritesheet r1, mysprites
// R1 points at the sprite table, r2 contains the length of the table
sprite r1, r2
// Sprite bitmaps
@ORG mysprites
@DW 0xFFFF, ...
```

# Registers

Neko has some GPRs that the user can access and some hidden ones that only the CPU uses to do its bookkeeping.
* r0..r15 : User accessible, GPR, 32bit wide
* IP: Internal, Instruction Pointer, 32bit wide
* SP: Internal, Stack Pointer, 32bit wide
* FLAGS: Internal, comparison flag registers, 6bit wide
* CALLSP: Internal, Call Stack Pointer, 16bits wide
* CALLSTACK[...]: Internal, Call Stack (return addresses), 32bits wide per entry
* BRANCHTARGET: Internal, Transient call Target Register, 32bits wide
* TARGETREGISTER: Internal, Transient Target Register Index, 3bits wide

# Instruction Encoding

Neko uses very few instruction formats, with all instructions sharing the same base rule: bottom 4 bits denote a 'macro' instruction, whereas the rest of the bits take on different meanings. It's quite common across instructions to encode register indices 0-7 as adjacent 3 bit groups. This gives Neko a limitation of 16 base instruction groups, though inside those groups encodings might differ, and more words might be fetched from memory as required. The longest instruction currently takes up 3 words in memory, which is the branch instruction group. This format contains the initial instruction word followed by two more words for the call target address.

Therefore for majority of the cases a typical encoding would look like the following:
```
???? ???? ???? 0000
          |    |
          |    Base instruction bits
          Registers or sub-instructions, and other instruction mode flags
```

Throught this document, you'll find all instruction encodings displayed by base instruction, with each sub-instruction encoding clearly visible, after which each subinstruction will be documented.

# Intrinsics

## LEA: Load Effective Address

The LEA intrinsic generates a `ld.d` instructions which loads the address of matching `@LABEL` into a register pair, hardcoded by the assembler. It is a convenience routine to avoid having to type in manual addresses.

Example:
```c
lea r7, SPRITEPOSDATA
// which is equivalent to a load of the address of the label, resulting in the following code:
// ld.d r7, 0x00000300

@ORG 0x00000300
@LABEL SPRITEPOSDATA
@DW 0xFFFF 0xFFE0 0xE000
```

# Instruction Set

## Logic Operations

The instruction encoding for the LOGICOP base instruction is as follows
```
? 0000 0000 000 0000
  |    |    |   LOGICOP
  rB   rA   000:OR rA,rB (Default NOOP instruction encoding when rA rB are both equal to `r0`, maps to byte code '0')
  E:B  A:7  001:AND rA,rB
            010:XOR rA,rB
            011:NOT rA
            100:BSL rA,rB
            101:BSR rA,rB
            110:BSWAP rA, rB
            111: RESERVED
```

Note that it is perfectly valid to use the same register as target in above instructions where rC is mentioned. For example, `BSWAP` can accept the same register both as input and output, effectively doing an in-place swap as in the following example:
```c
// value of r0 before call: 0xABCD
bswap r0,r0
// value of r0 after call: 0xCDAB
```

Whereas if the target register is a different register than the source:
```c
// value of r0 before call: 0xABCD
// value of r1 before call: 0x0000
bswap r1,r0
// value of r0 after call: 0xABCD
// value of r1 after call: 0xCDAB
```

### OR rA, rB
This instruction applies bitwise or between rA and rB and writes the result back to rA, and is equivalent to:
```c
rA = rA|rB;
```

### NOOP
The format of this instruction is `noop` and is equivalent to the following `or` instruction which encodes into a bit pattern of 0x0000:
```c
or r0,r0;
```

### AND rA, rB
This instruction applies bitwise and between rA and rB and writes the result back to rA, and is equivalent to:
```c
rA = rA&rB;
```

### XOR rA, rB
This instruction applies bitwise xor between rA and rB and writes the result back to rA, and is equivalent to:
```c
rA = rA^rB;
```

### NOT rA, rB
This instruction negates all bits of rB and writes the output to rA, and is equivalent to:
```c
rA = ~rB;
```

### BSL rA, rB
This instruction shifts bits of rA by rB positions and writes the output back to rA, and is equivalent to:
```c
rA = rA<<rB;
```

### BSR rA, rB
This instruction shifts bits of rA by rB positions and writes the output back to rA, and is equivalent to:
```c
rA = rA>>rB;
```

### BSWAP rA, rB
Swaps the lower 8 bits of the 16 bit value in register rB with the higher 8 bits and writes the output to rA. rB remains untouched unless it's also the target register. This is equivalent to:
```c
upper = (rB&0xFF00)>>8;
lower = rB&0x00FF;
rA = (lower<<8)|upper;
```

---
## Branch Instructions

Branch instruction is a bit special since it needs to read two extra WORDs from the adjacent addresses in memory, IP+2 and IP+4 and therefore takes up more than one cycle to complete its operation.
```
0 0 0000 0000 00 0001   [IP+2] [IP+4]
| | |    |    |  BRANCH
| | rB   rA   |
| |      9:6  00:UNCONDITIONAL
| |           01:CONDITIONAL based on rB set
| |           10: RESERVED
| |           11:INVCONDITIONAL based on rB not set
| 0:JMP
| 1:CALL
|
0:Jump via register address (19 bits addressable via {rA}[18:0])
1:Jump via address at [IP+2:IP+4] (32 bits, 19 bits addressable (absolute))
```

### CALL {address} / CALL rA

Pushes the next instuction's address onto the call stack and sets the IP to the 2 words following this instruction or the contents of register rA.

### CALLIF {address} rB / CALLIF rA rB

Pushes the next instuction's address onto the call stack and sets the IP to the 2 words following this instruction or the contents of register rA if the rB register is 1.

### CALLIFNOT {address} rB / CALLIFNOT rA rB

Pushes the next instuction's address onto the call stack and sets the IP to the 2 words following this instruction or the contents of register rA if the rB register is 0.

### JMP {address} / JMP rA

Sets the IP to the 2 words following this instruction or the contents of register rA.

### JMPIF {address} rB / JMPIF rA rB

Sets the IP to the 2 words following this instruction or the contents of registers rA if the rB register IS SET.

### JMPIFNOT {address} rB / JMPIFNOT rA rB

Sets the IP to the 2 words following this instruction or the contents of registers rA if the rB register IS NOT SET.

---
## Integer Math Instruction
```
0000 0000 0000 0010
|    |    |    MATHOP
rB   rA   0000:IADD rA,rB (rA=rA+rB)
F:C  B:8  0001:ISUB rA,rB (rA=rA-rB)
          0010:IMUL rA,rB (rA=rA*rB)
          0011:IDIV rA,rB (rA=rA/rB)
          0100:IMOD rA,rB (rA=rA%rB)
          0101:INEG rA    (rA=-rA)
          0110:INC rA     (rA=rA+1)
          0111:DEC rA     (rA=rA-1)
          1000:reserved
          1001:reserved
          1010:reserved
          1011:reserved
          1100:reserved
          1101:reserved
          1110:reserved
          1111:reserved
```

### IADD rA,rB
This is an integer add between rA and rB where the result is written back to rA, which is equivalent to the following code:
```c
rA = rA+rB;
```
NOTE: Overflow is currently not detected and will be ignored, which might give wrong results.

### ISUB rA,rB
This is an integer subtraction between rA and rB where the result is written back to rA, which is equivalent to the following code:
```c
rA = rA-rB;
```
NOTE: Overflow is currently not detected and will be ignored, which might give wrong results.

### IMUL rA,rB
This is an integer multiplication between rA and rB where the result is written back to rA, which is equivalent to the following code:
```c
rA = rA*rB;
```
NOTE: Overflow is currently not detected and will be ignored, which might give wrong results.

### IDIV rA,rB
This is an integer division between rA and rB where the result is written back to rA, which is equivalent to the following code:
```c
rA = rA/rB;
```
NOTE: Overflow or division by zero is currently not detected and will be ignored, which might give wrong results.

### IMOD rA,rB
This is an integer modulo between rA and rB where the result is written back to rA, which is equivalent to the following code:
```c
rA = rA%rB;
```
NOTE: Mod operations where rB==0 are currently not detected and will be ignored, which might give wrong results.

### INEG rA
This is a sign negation operation which is equivalent to the following code:
```c
rA = -rA;
```

### INC rA
This is an integer increment operation which is equivalent to the following code:
```c
rA = rA+1;
```

### DEC rA
This is an integer decrement operation which is equivalent to the following code:
```c
rA = rA-1;
```

---
## Memory Access Instructions

There are two variants for memory access instructions: word access and byte access.

Non-relative address mode:
```
0000 0000 0000 0011
|    |    |    MOV (DWORD / WORD / BYTE)
rB   rA   0000:REG2MEM [rA], rB - st.w
E:B  A:7  0001:MEM2REG rA, [rB] - ld.w
          0010:REG2REG rA, rB - cp.w
          0011:WORD2REG rA, [IP+2] (16 bit constant starting at IP+2) - ld.w
          0100:DWORD2REG rA, [IP+2:IP+4] (32 bit constant address starting at IP+2) - ld.d
          0101:REG2MEM [rA], rB - st.b
          0110:MEM2REG rA, [rB] - ld.b
          0111:BYTE2REG rA, [IP+2] (low 8 bit constant starting at IP+2) - ld.b
          1000:DWMEM2REG rA, [rB] - ld.d
          1001: RESERVED
          1010: RESERVED
          1011: RESERVED
          1100: RESERVED
          1101: RESERVED
          1110: RESERVED
          1111: RESERVED
```


### ST.W [rA], rB / ST.B [rA], rB
Stores the 16 bit value in register rB at memory pointed by rA register. For `ST.B` instrucion, the byte value at the memory address is copied to the lower 8 bits of the register rA.

### LD.W rA, [rB] / LD.B rA, [rB]
Stores the 16 bit value at memory pointed by rB to register rA. For `LD.B` instruction, based on the last bit of the address in rB, it loads the 8 bits at the address in rB to the register rA.

### CP.W rA, rB / CP.B rA, rB
Stores the 16 bit value of register rB in register rA. For `CP.B`, only the lower 8 bits are copied across registers. For example:
```c
cp.b r1, r0
```
would copy only the lower 8 bits of r0 onto r1, keeping the upper 8 bits intact.

### LD.B rA, {word_constant}
Stores the low byte of the WORD following this instruction in low byte of register rA while keeping the high byte intact. For example:
```c
// After the following instruction r1 will contain 0x??BB
ld.b r1, 0xAABB
```

### LD.W rA, {word_constant}
Stores the WORD following this instruction in register rA. For example:
```c
// Write a white pixel
ld.w r1, 0x80000000 // First pixel of VRAM
ld.w r2, 0x00FF     // White
st.b [r1], r2       // Write the low 8 bits of r2
```
would set the register r1 to the VRAM start address, 0x80000000, and r2 to 0x00FF, then write the lower 8 bits of r2 to that address.

NOTE: The byte access form only works on the lower 8 bits of registers.

### LD.D rA, {dword_mem_address}
Stores the contents of the DWORD address following this instruction in register rA.

Example:
```c
ld.d r1, VRAMSTART
// which is equivalent to a load of the value at the given label, resulting in the following register state:
// r1==0x80000000

@ORG 0x0300
@LABEL VRAMSTART
@DW 0x8000 0x0000
```

### LD.REL.D rA, rB, rC / LD.REL.W rA, rB, rC / LD.REL.B rA, rB, rC (NOT IMPLEMENTED YET)
Stores the contents of address pointed by rB plus offset in register rC in register rA.

Example:
```c
// Copies contents at [SPRITEMEMORY(r1)+r2] to  register r0
// Effectively equal to:
// r1 = SRAM[SPRITEMEMORY+r2];
lea r1, SPRITEMEMORY
st.w r2, 0x0100
ld.rel.w r0, r1, r2

@ORG SPRITEMEMORY
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF ...
```

### ST.REL.W rA, rB, rC / ST.REL.B rA, rB, rC (NOT IMPLEMENTED YET)
Stores the contents of register rB address pointed by rA plus offset in register rC.

---
## Return / Halt

The return base instruction also houses the CPU Halt instruction which acts as end-of-program.

```
??????????? 0 0100
            | RET
            0:RET
            1:HALT
```

### RET
Pops the return address from the call stack and sets the new instruction pointer to this value, effectively returning to the valid instruction address of the caller's `CALL`, `CALLIF` or `CALLIFNOT` instruction. This function cannot return if the call was made using a `JMP` or `JMPIF` instruction since those instructions will not update the call stack with the return address.

### HALT
Stops the CPU entirely, going into an infinite loop. Currently, only a reset signal can recover the CPU from this state.

---
## Stack Operations

These instructions implement stack operations for register store/restore operations. The stack grows from end of SRAM backwards to the top of memory to avoid clashing with loaded code. One thing to keep in mind is to avoid placing code or data too close to the end of memory to prevent possible stack overwrites.
```
??????? 0000 0 0101
        |    | STACK rA
        rA   0:PUSH rA (rA->[SP--])
        8:5  1:POP rA  ([++SP]->rA)
```

### PUSH rA
Stores the value of rA at stack pointer `SP` and decrements the stack pointer.

### POP rA
Increments the stack pointer to access a valid stack entry then sets the value at the new stack pointer `SP` to the register rA.

---
## Comparison Instructions

Comparison consists of two base instructions. TEST base instruction is used to set the rA register in the instruction to either 0 or 1 based on a previous COMPARE base instruction's result. TEST receives a FLAG_MASK that is used to pattern match to the FLAGS register.

```
???? 0000 0000 0111
     |    |    CMP rA, rB
     rB   rA
     B:8  7:4
```
```
? 0000 000000 0110
  |    |      TEST rA, FLAG_MASK
  rA   FLAG_MASK
  D:A  9:4
```

The bit order of the FLAGS register is as follows (LSB on the right)
```
    [ZERO:NOTEQUAL:NOTZERO:LESS:GREATER:EQUAL]
```
for a total of 6 bits.

The correct way to invoke a full compare usually consists of these instructions in series similar to the following:
```c
cmp r0,r0
test r1, notzero
jmpif SKIP, r1
```
which is equal to `jump if r0 is not zero (result in r1)`

These masks can be combined by adding a space in between them after the instruction, such as `test less equal` where it makes sense. The actual test will then pass if _any_ of the bits was set in the FLAGS register in the previous compare instruction, therefore in this example we can read it as _'set r1 to one if comparison is less than or equal'_

### CMP rA, rB
Applies all known tests between rA and rB, and subsequently sets the matching bits of FLAGSREGISTER to either one or zero. Use the `TEST` instruction to apply a test mask on the FLAGSREGISTER to be able to use the result in conditional branches.

### TEST rA, {condition_mask}
Sets rA to 0 or 1 based on one or more of the following condition flags. If more than one option us used, each option should be separated by spaces:
```
zero
notequal
notzero
less
greater
equal
```

The test operation is equivalent to `FLAGSREGISTER & {condition_mask}`. If any bit of the result is set, rA register will contain a one, otherwise it will be set to zero. This effectively makes the condition_mask cases acted upon as if they were combined with `OR`.

As an example, one could use multiple tests together as in the following example
```c
// r2 = r0 >= r1 ? 1 : 0;
cmp r0, r1
test r2, greater equal
```

---
## IO Operations
```
? 0000 0000 000 1000
  |    |    |   IO
  rB   rA   000:VSYNC
  E:B  A:7  001:IN rA PORTADDRESS(next WORD in memory)
            010:OUT rA PORTADDRESS(next WORD in memory)
            011:FSEL rA
            100:CLF rA
            101:SPRITE rA, rB
            110:SPRITESHEET rA
            111: RESERVED
```

### VSYNC
Waits for vertical synchronization on the video hardware.

Example:
```c
// This is one valid way to wait for vertical scan then switch to the next frame buffer, i.e. 'flip'
inc rA
vsync
fsel rA
```

### IN rA PORTADDRESS
Reads the input from device at port address and write the data into register rA.

### OUT rA PORTADDRESS
Reads the intput from register rA and write the data to device at port address.

### FSEL rA
Selects the displayed framebuffer index as mentioned in register rA. Only the last bit of rA (0 or 1) is used as framebuffer index, therefore simply incrementing rA will flip between two available buffers. All writes are routed towards the 'other' framebuffer address in this state.

### CLF rA
Clears the framebuffer that currently has write access to the value supplied in low byte of rA.

### SPRITE rA, rB
Points at the sprite table at memory address contained in register rA, and kicks off a draw operation that will show rB entries from that table.
The sprite table has the following format:
```c
{[X Coordinate][Y Coordinate][Sprite ID]}*N
```
Sprites can be placed in SRAM and will be part of the program ROM image, and the sprite table can be either generated by code or pre-built, also as part of the ROM image. One animates the sprites by manipulating the sprite's X/Y coordinates and writing over the sprite table. Since it is possible to use more than one sprite table, one can generate sprite layers and animated/static backdrops by grouping them into the same table.

### SPRITESHEET rA
Points at the actual 16x16 bitmaps to use as sprites.
For each sprite in the sheet, the following format is used:
```c
{[256 bytes of 3:3:2 packed RGBA pixels for a single 16x16 sprite]}*N
```
