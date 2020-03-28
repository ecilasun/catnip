# Project Neko Instruction Set Manual

Project Neko is a small game console aimed at FPGAs.
It has a 16 bit CPU, and has access to 512Kbytes of SRAM. The VRAM is made up of on-chip dual port block memory and delivers an image at 320x204 resolution and 8bpp.

The architecture is currently implemented on the [Terasic Cyclone V GX Starter Kit](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=167&No=830) and uses up about 6 to 7 percent of the resources available on the FPGA.

There is also an assembler/emulator which can generate ROM images out of ASM files and run the ROM files to test out code while the actual hardware is being developed.

Here is a brief list of the architecture details of Neko V3

  * 16 bit instruction set
    * Bottom 4 bits of instructions contain the 'base instruction' code
    * Currently only 8 out of these 16 base instructions are used
    * Each instruction has variety of sub-instructions
    * Rest of the bits on the instruction define either sub-instuctions, register indices, some other useful flag bits in any predetermined order
  * 50Mhz core clock
    * The main CPU unit runs at 50Mhz
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
  * 320 x 204 x 8bpp VRAM
    * VRAM can only be accessed as bytes
    * VRAM starts at memory address 0x8000:0000
    * Each byte is packed as 2:3:3 bits (B:G:R)
    * There are two 18 pixel borders at the top and bottom of the screen
      * This keeps VRAM addresses in the 0x8000:0000-0x8000:FF00 range so access fits into a single WORD
      * Border color can be changed by setting byte at 0x8000:FF00 to a 2:3:3 color
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
|----------------|  0x8000FF00
|                |
| DEVICE CONTROL |
|                |
|----------------|  0x8000FFFF
```
The working memory starts at address 0x00000000 and continues up to 0x7FFFFFFF, out of which currently only 512Kbytes is actual physical memory.
Instructions are often considered to start at even address boundaries to simplify the hardware access pattern and reduce access times.
Starting at 0x80000000 resides the VRAM which only allows for byte access, and ends at address 0x8000FEFF.
At the addresses from 0x8000FF00 to 0x8000FFFF lives a variety of device control bytes.
Following diagram shows the uses of each byte starting at the device control address
```
|----------------| 
| BORDER COLOR   | 0x8000FF00
|----------------| 
| TBD            | 0x8000FF01
|----------------| 
| TBD            | 0x8000FF02
|----------------| 
| TBD            | 0x8000FF03
|----------------| 
| TBD            | 0x8000FF04
~                ~
|----------------| 
| TBD            | 0x8000FFFF
```

# Video output
The actual video output resolution in hardware is set to 640x480 @60Hz. Since the video memory is much smaller than this, each pixel is magnified to 2 times the size in both the horizontal and vertical directions giving an effective resolution of 320x240 pixels.

However, video memory addresseses are kept within 16 bit range for convenience. This is so that the caller may modify one register to scan the entire VRAM by using only one `INC` instruction on the lower address register out of a register pair. This results in an actual video region of 204 pixels in height.

To compensate for the missing parts of the image due to this address restriction, the video output looks like the following diagram:
```
                     320 pixels
    18  |--------------------------------|
 pixels |           Border               |
        |--------------------------------| 0x8000 0000 (VRAM start)
    204 |                                |
 pixels |         Video Area             |
        |                                |
        |--------------------------------| 0x8000 FEFF (last pixel, inclusive)
    18  |           Border               |
 pixels |--------------------------------|
```

# Registers

Neko has some GPRs that the user can access and some hidden ones that only the CPU uses to do its bookkeeping.
* r0..r7 : User accessible, GPR, 16bit wide
* IP: Internal, Instruction Pointer, 32bit wide
* SP: Internal, Stack Pointer, 32bit wide
* FLAGS: Internal, comparison flag registers, 6bit wide
* CALLSP: Internal, Branch Stack Pointer, 16bits wide
* CALLSTACK[...]: Internal, Branch Stack (return addresses), 32bits wide per entry
* TR: Internal, Test Result Register, 1bit wide
* BRANCHTARGET: Internal, Transient Branch Target Register, 32bits wide
* TARGETREGISTER: Internal, Transient Target Register Index, Xbits wide (TBD)

# Instruction Encoding

Neko uses very few instruction formats, with all instructions sharing the same base rule: bottom 4 bits denote a 'macro' instruction, whereas the rest of the bits take on different meanings. It's quite common across instructions to encode register indices 0-7 as adjacent 3 bit groups. This gives Neko a limitation of 16 base instruction groups, though inside those groups encodings might differ, and more words might be fetched from memory as required. The longest instruction currently takes up 3 words in memory, which is the branch instruction group. This format contains the initial instruction word followed by two more words for the branch target address.

Therefore for majority of the cases a typical encoding would look like the following:
```
???? ???? ???? 0000
          |    |
          |    Instruction bits
          Registers or sub-instructions, and other instruction mode flags
```

Throught this document, you'll find all instruction encodings displayed by base instruction, with each sub-instruction encoding clearly visible, after which each subinstruction will be documented.

# Intrinsics

## LEA: Load Effective Address

The LEA intrinsic generates two `mov` instructions which loads the address of matching `@LABEL` into a register pair.

Example:
```c
lea r7:r6, SPRITEPOSDATA
// which is equivalent to a load of the address of the label, resulting in the following code:
// mov r7, 0x0000
// mov r6, 0x0300

@ORG 0x0300
@LABEL SPRITEPOSDATA
@DW 0xFFFF 0xFFE0 0xE000
```

# Instruction Set

## Logic Operations

The instruction encoding for the LOGICOP base instruction is as follows
```
000 000 ??? 000 0000
|   |       |   LOGICOP
rB  rA      000:OR rA,rB (Default NOOP instruction encoding when rA rB are both equal to `r0`, maps to byte code '0')
            001:AND rA,rB
            010:XOR rA,rB
            011:NOT rA
            100:BSL rA,rB
            101:BSR rA,rB
            110:BSWAP rA, rB
            111:reserved
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

Branch instruction is a bit special since it needs to read two extra WORDs from the adjacent addresses in memory, IP+1 and IP+2 and therefore takes up more than one cycle to complete its operation.
```
0 0 000 000 ??00 0001   [IP+1] [IP+2]
| | |   |     |  BRANCH
| | rB  rA    |
| |           00:UNCONDITIONAL
| |           01:CONDITIONAL based on TEST
| 0:JMP
| 1:CALL
|
0:Jump via register address (18 bits addressable via {R2,R1}[17:0])
1:Jump via address at [IP+1:IP+2] (32 bits, 18 bits addressable (absolute))
```

### BRANCH {address} / BRANCH rB:rA

Pushes the next instuction's address onto the branch stack and sets the IP to the 2 words following this instruction or the contents of registers rA and rB.

### BRANCHIF {address} / BRANCHIF rB:rA

Pushes the next instuction's address onto the branch stack and sets the IP to the 2 words following this instruction or the contents of registers rA and rB if the TR register is set.

### JMP {address} / JMP rB:rA

Sets the IP to the 2 words following this instruction or the contents of registers rA and rB.

### JMPIF {address} / JMPIF rB:rA

Sets the IP to the 2 words following this instruction or the contents of registers rA and rB if the TR register is set.

---
## Integer Math Instruction
```
000 000 ??? 000 0010
|   |       |   MATHOP
rB  rA      000:IADD rA,rB (rA=rA+rB)
            001:ISUB rA,rB (rA=rA-rB)
            010:IMUL rA,rB (rA=rA*rB)
            011:IDIV rA,rB (rA=rA/rB)
            100:IMOD rA,rB (rA=rA%rB)
            101:INEG rA    (rA=-rA)
            110:INC rA     (rA=rA+1)
            111:DEC rA     (rA=rA-1)
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

For word access, use:
```
000 000 000 000 0011
|   |   |   |   MOV (WORD / DWORD)
rC  rB  rA  000:REG2MEM [rA:rB], rC - st.w
            001:MEM2REG rA, [rB:rC] - ld.w
            010:REG2REG rA, rB - cp.w
            011:WORD2REG rA, [IP+1] (16 bit constant starting at IP+1) - ld.w
            100:DWORD2REGS rA:rB, [IP+1:IP+2] (32 bit constant address starting at IP+1) - ld.d
            101:reserved
            110:reserved
            111:reserved
```
For byte access, use:
```
000 000 000 000 1001
|   |   |   |   MOV (BYTE)
rC  rB  rA  000:REG2MEM [rA:rB], rC - st.b
            001:MEM2REG rA, [rB:rC] - ld.b
            010:REG2REG rA, rB - cp.b
            011:BYTE2REG rA, [IP+1] (low 8 bit constant starting at IP+1) - ld.b
            100:reserved
            101:reserved
            110:reserved
            111:reserved
```

### ST.W [rA:rB], rC / ST.B [rA:rB], rC
Stores the 16 bit value in register rC at memory pointed by rA:rB register pair. For `ST.B`, the byte value at the memory address is copied to the lower 8 bits of the register rA.

### LD.W rA, [rB:rC] / LD.B rA, [rB:rC]
Stores the 16 bit value at memory pointed by rB:rC to register rA. For `LD.B`, based on the last bit off the address, it loads either the even or the odd byte onto the lower 8 bits of the register rA.

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
// Write a white pixel at first VRAM address
ld.w r1, 0x8000
ld.w r0, 0x0000
ld.w r2, 0x00FF // White
st.b [r1:r0], r2
```
would set the register pair r1:r0 to the VRAM start address, 0x80000000, and r2 to 0x00FF, then write the lower 8 bits of r2 to that address.

NOTE: The byte access form only works on the lower 8 bits of registers.

### LD.D rA:rB, {dword_mem_address}
Stores the contents of the DWORD address following this instruction in register pair rA:rB. rA receives the high word whereas register rB receives the low word of the DWORD.

Example:
```c
ld.d r1:r0, VRAMSTART
// which is equivalent to a load of the value at the given label, resulting in the following register state:
// r1==0x8000 
// r6==0x0000

@ORG 0x0300
@LABEL VRAMSTART
@DW 0x8000 0x0000
```

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
Pops the return address from the branch stack and sets the new instruction pointer to this value, effectively returning to the valid instruction address of the caller's `BRANCH` or `BRANCHIF` instruction. This function cannot return if the branch was made using a `JMP` or `JMPIF` instruction since those instructions will not update the branch stack with the return address.

### HALT
Stops the CPU entirely, going into an infinite loop. Currently, only a reset signal can recover the CPU from this state.

---
## Stack Operations

These instructions implement stack operations for register store/restore operations. The stack grows from end of SRAM backwards to the top of memory to avoid clashing with loaded code. One thing to keep in mind is to avoid placing code or data too close to the end of memory to prevent possible stack overwrites.
```
???????? 000 0 0101
         |   | STACK rA
         rA  0:PUSH rA (rA->[SP--])
             1:POP rA  ([++SP]->rA)
```

### PUSH rA
Stores the value of rA at stack pointer `SP` and decrements the stack pointer.

### POP rA
Increments the stack pointer to access a valid stack entry then sets the value at the new stack pointer `SP` to the register rA.

---
## Comparison Instructions

Comparison consists of two base instructions. TEST base instruction is used to set the TR register to either 0 or 1 based on a previous COMPARE base instruction's result. TEST receives a FLAG_MASK that matches the FLAGS register.

```
?????? 000 000 0111
       |   |   CMP rA, rB
       rB  rA
```
```
????? 000000 0110
      |      TEST FLAG_MASK
      FLAG_MASK
```

The bit order of the FLAGS register is as follows (LSB on the right)
```
    [ZERO:NOTEQUAL:NOTZERO:LESS:GREATER:EQUAL]
```
for a total of 6 bits.

The correct way to invoke a full compare usually consists of these instructions in series similar to the following:
```c
cmp r0,r0
test notzero
jmpif SKIP
```
which is equal to `branch if r0 is not zero`

These masks can be combined by adding a space in between them after the instruction, such as `test less equal` where it makes sense. The actual test will then pass if _any_ of the bits was set in the FLAGS register in the previous compare instruction, therefore in this example we can read it as _'set TR to one if comparison is less than or equal'_

### CMP rA, rB
Applies all known tests between rA and rB, and subsequently sets the matching bits of FLAGSREGISTER to either one or zero. Use the `TEST` instruction to apply a test mask on the FLAGSREGISTER to be able to use the result in conditional branches.

### TEST {condition_mask}
Sets the TR bit based on one or more of the following condition flags. If more than one option us used, each option should be separated by spaces:
```
zero
notequal
notzero
less
greater
equal
```

The test operation is equivalent to `FLAGSREGISTER & {condition_mask}`. If any bit of the result is set, TR register will contain a one, otherwise it will be set to zero. This effectively makes the condition_mask cases acted upon as if they were combined with `OR`.

As an example, one could use multiple tests together as in the following example
```c
// TR = r0 >= r1 ? 1 : 0;
cmp r0, r1
test greater equal
```

---
## IO Operations
```
?????? 000 000 1000
       |   |   IO
       rA  000:VSYNC
           001:IN rA PORTADDRESS(next WORD in memory)
           010:OUT rA PORTADDRESS(next WORD in memory)
           011:FSEL rA
           100:reserved
           101:reserved
           110:reserved
           111:reserved
```

### VSYNC
Waits for vertical synchronization on the video hardware.

### IN rA PORTADDRESS
Reads the input from device at port address and write the data into register rA.

### OUT rA PORTADDRESS
Reads the intput from register rA and write the data to device at port address.

### FSEL rA
Selects the framebuffer index as mentioned in register rA. Only the last bit of rA (0 or 1) is used as framebuffer index, therefore simply incrementing rA will flip between two available buffers.

Example:
```c
// This is one valid way to wait for vertical scan then switch to the next frame buffer, i.e. 'flip'
inc rA
vsync
fsel rA
```

---
## Reserved

---
## Reserved

---
## Reserved

---
## Reserved

---
## Reserved

---
## Reserved

---
## Reserved
