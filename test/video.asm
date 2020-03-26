# -------------------------------------------------------
# Software sprite demo
# -------------------------------------------------------

# -------------------------------------------------------
# Formal way to call a function and preserve registers
# -------------------------------------------------------

# 1- Save any local registers that are stomped over by the called function
# 2- Push function parameters in reverse order
# 3- Call the function
# 4- Restore all local registers that the caller uses in reverse order

# -------------------------------------------------------
# Main, the entry point
# -------------------------------------------------------

@ORG 0x0000         # Always has to be at 0
@LABEL Main

branch ClearVRAM

# Load parameters directly into registers
# The disadvantage is that the parameters are hard to change due to no known address / gaps in between
ld.w r6, 0x0008         # X=8
ld.w r7, 0x000C         # Y=12
push r7                 # NOTE: Push parameters in reverse order
push r6
branch DrawSprite

# Load parameters from memory address 0000:0200
# The advantage is that the parameters in memory can be changed and kept around
# or simply a pointer at the parameters can be sent to the function
lea r7:r6, SPRITEPOSDATA  # X/Y positions at 0000:0200 and 0000:0202
ld.w r0, [r7:r6]
inc r6
inc r6
ld.w r1, [r7:r6]
push r1
push r0
branch DrawSprite

# Test loop/neg/push/pop by copying the sprite 13 times with 21 pixel X and 2 pixel Y offsets
# Uses direct register parameters
ld.w r0, 0x000D          # copies
ld.w r1, 0x0015          # X step
ld.w r2, 0x0002          # Y step
ld.w r6, 0x0017          # X=23
ld.w r7, 0x0080          # Y=128
@LABEL MANYSPRITES
    push r0                 # save our loop counter
    push r1                 # save step counter X
    push r2                 # save step counter Y
    push r7                 # save a copy of Y position
    push r6                 # save a copy of X position
    push r7                 # push parameters
    push r6
    branch DrawSprite
    pop r6                  # restore X position
    pop r7                  # restore Y position
    pop r2                  # restore step counter Y
    iadd r7,r2              # inc Y by step
    pop r1                  # restore step counter X
    iadd r6,r1              # inc X by step
    ineg r2                 # negate sign of Y step
    pop r0                  # restore loop counter
    dec r0
    cmp r0,r0
    test notzero
jmpif MANYSPRITES

# Test some integer math by calculating memory address and plotting a pixel
ld.w r5, 0x00A0          # X=160
ld.w r6, 0x0066          # Y=102
ld.w r7, 0x0038          # Color=Green
push r7
push r6
push r5
branch DrawPixel

# Test integer math / push / pop inside loop by drawing a diagonal line
ld.w r5, 0x0080          # X=128
ld.w r6, 0x0040          # Y=64
ld.w r7, 0x07C0          # Color=Red/Blue
ld.w r0, 0x0040          # 64 pixels
@LABEL LINELOOP
    push r0              # save our counter (DrawPixel overwrites r0)
    push r7              # push parameters
    push r6
    push r5
    branch DrawPixel
    pop r0               # restore our counter
    inc r5               # step X
    inc r6               # step Y
    bswap r7,r7          # switch to next color for next pixel
    dec r0
    cmp r0,r0
    test notzero
jmpif LINELOOP

# Set border color to orange - Test for quickest memory write in a loop
ld.w r5, 0x001F          # Orange as start color
ld.d r1:r0, BORDERCOLOR # [r1:r0] Border color (8000:FF00)
@LABEL BORDERLOOP
    st.b [r1:r0], r5
    inc r5
    # vsync
jmp BORDERLOOP

# Stop the CPU so we don't fall through to the code following Main
halt

# -------------------------------------------------------
# Draw a pixel at (r0,r1) with color r2
# -------------------------------------------------------

@LABEL DrawPixel
pop r0                   # X
pop r1                   # Y
pop r2                   # Color
ld.w r3, 0x0140          # Row pitch (320)
imul r1, r3              # Y*320
iadd r0, r1              # X+Y*320
ld.w r1, 0x8000          # 0x8000:(X+Y*320) == VRAM address
st.b [r1:r0], r2
ret

# -------------------------------------------------------
# Draw a sprite at (r0,r1)
# -------------------------------------------------------

@LABEL DrawSprite

pop r0                   # X
pop r1                   # Y

ld.w r2, 0x0140          # Row pitch (320)
imul r1, r2              # Y*320
iadd r0, r1              # X+Y*320
ld.w r1, 0x8000          # 0x8000:(X+Y*320) == VRAM address

ld.w r2, 0x0400          # [r3:r2] sprite in ROM at this address (0000:0400)
ld.w r3, 0x0000
ld.w r4, 0x0011          # column counter (sprite is 17 pixels wide, but has 18 pixel stride)
ld.w r5, 0x0017          # row counter (23 pixels)

@LABEL INNERLOOP
    # for each column
        ld.b r6, [r3:r2]        # read from current pattern buffer location
        # ld.w r7, 0x00FF       # Skip masked pixels
        # cmp r6,r7
        # test equal
        # jmpif SKIPWRITE
        st.b [r1:r0], r6	   	# write to current VRAM location
    # @LABEL SKIPWRITE
        inc r0	    	    	# increment VRAM pointer
        inc r2                  # increment pattern pointer
        dec r4		        	# decrement scanline counter
        cmp r4, r4 			    # compare r4 to r4 (used to trigger 'zero' check)
        test notzero	        # true if r4 is not equal to zero                       
    jmpif INNERLOOP 	        # short jump to start of loop (at 0x0008) while true    

    # for each row
    inc r2                      # skip the unused pixel at the end (18th pixel)
    ld.w r4, 0x0011             # reset column counter back to 17
    ld.w r7, 0x012F             # set row stride (320-17==303)
    iadd r0, r7                 # move to next scanline
    dec r5
    cmp r5, r5
    test notzero
jmpif INNERLOOP                 # for each row

ret

@LABEL ClearVRAM
# preserve the registers we're going to destroy
push r0
push r1
push r2
push r3
ld.d r1:r0, VRAMSTART    # Load data at VRAMSTART into r1:r0 which is the VRAM start address DWORD
ld.w r2, 0xFF00          # 320x204 pixels
ld.w r3, 0x00FF          # Clear color: White
@LABEL CLEARLOOP
    st.b [r1:r0], r3
    inc r0
    dec r2
    cmp r2,r2
    test notzero
jmpif CLEARLOOP
# restore the registers we've destroyed
pop r3
pop r2
pop r1
pop r0
ret

# Sprite position
@ORG 0x0300
@LABEL SPRITEPOSDATA
@DW 0x0028 0x0016
@LABEL VRAMSTART
@DW 0x8000 0x0000
@LABEL BORDERCOLOR
@DW 0x8000 0xFF00

# Sprite data (17x23 just to make it difficult)
@ORG 0x0400
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFF00 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFF0B 0x1353 0xB13 0xF6FF 0xFFFF 0xFF00 
@DW 0xFFFF 0xFFFF 0xFF01 0x134E 0x4E06 0x6E0E 0x4EE 0xFFFF 0xFF00 
@DW 0xFFFF 0xFFFF 0x94E 0xE4E 0x4E67 0x7FFF 0xBAE 0xFFFF 0xFF00 
@DW 0xFFFF 0xFF13 0x497 0x4E4E 0x109 0x1353 0x9 0xEEFF 0xFF00 
@DW 0xFFFF 0x1304 0x4E8F 0x101 0x0 0x0 0x0 0xF6 0xFF00 
@DW 0xFFFF 0xF7 0x9 0x56 0x16 0xC 0xACEE 0xACF6 0xFF00 
@DW 0xFF13 0xAE26 0xAE00 0x16F7 0xEF 0xAE 0x6E24 0xF7FF 0xFF00 
@DW 0xFF01 0xEF09 0xFF00 0x1FF 0xA4FF 0x64F7 0xAE6E 0x64F6 0xFF00 
@DW 0xFF01 0xB27 0xFF00 0xA4FF 0x13AF 0xAFAF 0xAFEF 0x146E 0xFF00 
@DW 0xFF64 0xB 0xF703 0xFF13 0x3 0xB0B 0xB0B 0x54F7 0xFF00 
@DW 0xFFFF 0x6300 0x2716 0xF70B 0x1400 0x0 0x9 0xF6FF 0xFF00 
@DW 0xFFFF 0xFFA3 0x90C 0x1616 0x260B 0x53 0x63F6 0xFFFF 0xFF00 
@DW 0xFFFF 0xFFAE 0x38E 0x1651 0x136C 0xA1EC 0xFFFF 0xFFFF 0xFF00 
@DW 0xFFFF 0xFF00 0x560B 0xFA0 0xECFC 0xFCA3 0xE4F6 0xFFFF 0xFF00 
@DW 0xFFFF 0xFF01 0x6E6C 0x6E11 0xFFFF 0xF3FF 0x91EC 0xFFFF 0xFF00 
@DW 0xFFFF 0xFF0B 0xFFFF 0xF60B 0xF6F6 0xF4FE 0x89EC 0xFFFF 0xFF00 
@DW 0xFFFF 0xFF03 0xFFFF 0x3E9 0xA188 0xABE9 0x93F6 0xFFFF 0xFF00 
@DW 0xFFFF 0xFF24 0xB6F7 0x1363 0x5149 0x5093 0xF6FF 0xFFFF 0xFF00 
@DW 0xFFFF 0xFFFF 0x114 0x1414 0x110B 0x1364 0xFFFF 0xFFFF 0xFF00 
@DW 0xFFFF 0xFFFF 0x13 0x90B 0x6E00 0x6C00 0xACFF 0xFFFF 0xFF00 
@DW 0xFFFF 0xFFFF 0x909 0x4911 0x911 0x909 0xEEFF 0xFFFF 0xFF00 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFF00 

# Font data
# starts from space and goes up to tilda
@ORG 0x0600
@DW 0x0000, 0x0000, 0x0000, 0x0000 # U+0020 ( )
@DW 0x183C, 0x3C18, 0x1800, 0x1800 # U+0021 (!)
@DW 0x3636, 0x0000, 0x0000, 0x0000 # U+0022 (")
@DW 0x3636, 0x7F36, 0x7F36, 0x3600 # U+0023 (#)
@DW 0x0C3E, 0x031E, 0x301F, 0x0C00 # U+0024 ($)
@DW 0x0063, 0x3318, 0x0C66, 0x6300 # U+0025 (%)
@DW 0x1C36, 0x1C6E, 0x3B33, 0x6E00 # U+0026 (&)
@DW 0x0606, 0x0300, 0x0000, 0x0000 # U+0027 (')
@DW 0x180C, 0x0606, 0x060C, 0x1800 # U+0028 (()
@DW 0x060C, 0x1818, 0x180C, 0x0600 # U+0029 ())
@DW 0x0066, 0x3CFF, 0x3C66, 0x0000 # U+002A (*)
@DW 0x000C, 0x0C3F, 0x0C0C, 0x0000 # U+002B (+)
@DW 0x0000, 0x0000, 0x000C, 0x0C06 # U+002C (,)
@DW 0x0000, 0x003F, 0x0000, 0x0000 # U+002D (-)
@DW 0x0000, 0x0000, 0x000C, 0x0C00 # U+002E (.)
@DW 0x6030, 0x180C, 0x0603, 0x0100 # U+002F (/)
@DW 0x3E63, 0x737B, 0x6F67, 0x3E00 # U+0030 (0)
@DW 0x0C0E, 0x0C0C, 0x0C0C, 0x3F00 # U+0031 (1)
@DW 0x1E33, 0x301C, 0x0633, 0x3F00 # U+0032 (2)
@DW 0x1E33, 0x301C, 0x3033, 0x1E00 # U+0033 (3)
@DW 0x383C, 0x3633, 0x7F30, 0x7800 # U+0034 (4)
@DW 0x3F03, 0x1F30, 0x3033, 0x1E00 # U+0035 (5)
@DW 0x1C06, 0x031F, 0x3333, 0x1E00 # U+0036 (6)
@DW 0x3F33, 0x3018, 0x0C0C, 0x0C00 # U+0037 (7)
@DW 0x1E33, 0x331E, 0x3333, 0x1E00 # U+0038 (8)
@DW 0x1E33, 0x333E, 0x3018, 0x0E00 # U+0039 (9)
@DW 0x000C, 0x0C00, 0x000C, 0x0C00 # U+003A (:)
@DW 0x000C, 0x0C00, 0x000C, 0x0C06 # U+003B (;)
@DW 0x180C, 0x0603, 0x060C, 0x1800 # U+003C (<)
@DW 0x0000, 0x3F00, 0x003F, 0x0000 # U+003D (=)
@DW 0x060C, 0x1830, 0x180C, 0x0600 # U+003E (>)
@DW 0x1E33, 0x3018, 0x0C00, 0x0C00 # U+003F (?)
@DW 0x3E63, 0x7B7B, 0x7B03, 0x1E00 # U+0040 (@)
@DW 0x0C1E, 0x3333, 0x3F33, 0x3300 # U+0041 (A)
@DW 0x3F66, 0x663E, 0x6666, 0x3F00 # U+0042 (B)
@DW 0x3C66, 0x0303, 0x0366, 0x3C00 # U+0043 (C)
@DW 0x1F36, 0x6666, 0x6636, 0x1F00 # U+0044 (D)
@DW 0x7F46, 0x161E, 0x1646, 0x7F00 # U+0045 (E)
@DW 0x7F46, 0x161E, 0x1606, 0x0F00 # U+0046 (F)
@DW 0x3C66, 0x0303, 0x7366, 0x7C00 # U+0047 (G)
@DW 0x3333, 0x333F, 0x3333, 0x3300 # U+0048 (H)
@DW 0x1E0C, 0x0C0C, 0x0C0C, 0x1E00 # U+0049 (I)
@DW 0x7830, 0x3030, 0x3333, 0x1E00 # U+004A (J)
@DW 0x6766, 0x361E, 0x3666, 0x6700 # U+004B (K)
@DW 0x0F06, 0x0606, 0x4666, 0x7F00 # U+004C (L)
@DW 0x6377, 0x7F7F, 0x6B63, 0x6300 # U+004D (M)
@DW 0x6367, 0x6F7B, 0x7363, 0x6300 # U+004E (N)
@DW 0x1C36, 0x6363, 0x6336, 0x1C00 # U+004F (O)
@DW 0x3F66, 0x663E, 0x0606, 0x0F00 # U+0050 (P)
@DW 0x1E33, 0x3333, 0x3B1E, 0x3800 # U+0051 (Q)
@DW 0x3F66, 0x663E, 0x3666, 0x6700 # U+0052 (R)
@DW 0x1E33, 0x070E, 0x3833, 0x1E00 # U+0053 (S)
@DW 0x3F2D, 0x0C0C, 0x0C0C, 0x1E00 # U+0054 (T)
@DW 0x3333, 0x3333, 0x3333, 0x3F00 # U+0055 (U)
@DW 0x3333, 0x3333, 0x331E, 0x0C00 # U+0056 (V)
@DW 0x6363, 0x636B, 0x7F77, 0x6300 # U+0057 (W)
@DW 0x6363, 0x361C, 0x1C36, 0x6300 # U+0058 (X)
@DW 0x3333, 0x331E, 0x0C0C, 0x1E00 # U+0059 (Y)
@DW 0x7F63, 0x3118, 0x4C66, 0x7F00 # U+005A (Z)
@DW 0x1E06, 0x0606, 0x0606, 0x1E00 # U+005B ([)
@DW 0x0306, 0x0C18, 0x3060, 0x4000 # U+005C (\)
@DW 0x1E18, 0x1818, 0x1818, 0x1E00 # U+005D (])
@DW 0x081C, 0x3663, 0x0000, 0x0000 # U+005E (^)
@DW 0x0000, 0x0000, 0x0000, 0x00FF # U+005F (_)
@DW 0x0C0C, 0x1800, 0x0000, 0x0000 # U+0060 (`)
@DW 0x0000, 0x1E30, 0x3E33, 0x6E00 # U+0061 (a)
@DW 0x0706, 0x063E, 0x6666, 0x3B00 # U+0062 (b)
@DW 0x0000, 0x1E33, 0x0333, 0x1E00 # U+0063 (c)
@DW 0x3830, 0x303e, 0x3333, 0x6E00 # U+0064 (d)
@DW 0x0000, 0x1E33, 0x3f03, 0x1E00 # U+0065 (e)
@DW 0x1C36, 0x060f, 0x0606, 0x0F00 # U+0066 (f)
@DW 0x0000, 0x6E33, 0x333E, 0x301F # U+0067 (g)
@DW 0x0706, 0x366E, 0x6666, 0x6700 # U+0068 (h)
@DW 0x0C00, 0x0E0C, 0x0C0C, 0x1E00 # U+0069 (i)
@DW 0x3000, 0x3030, 0x3033, 0x331E # U+006A (j)
@DW 0x0706, 0x6636, 0x1E36, 0x6700 # U+006B (k)
@DW 0x0E0C, 0x0C0C, 0x0C0C, 0x1E00 # U+006C (l)
@DW 0x0000, 0x337F, 0x7F6B, 0x6300 # U+006D (m)
@DW 0x0000, 0x1F33, 0x3333, 0x3300 # U+006E (n)
@DW 0x0000, 0x1E33, 0x3333, 0x1E00 # U+006F (o)
@DW 0x0000, 0x3B66, 0x663E, 0x060F # U+0070 (p)
@DW 0x0000, 0x6E33, 0x333E, 0x3078 # U+0071 (q)
@DW 0x0000, 0x3B6E, 0x6606, 0x0F00 # U+0072 (r)
@DW 0x0000, 0x3E03, 0x1E30, 0x1F00 # U+0073 (s)
@DW 0x080C, 0x3E0C, 0x0C2C, 0x1800 # U+0074 (t)
@DW 0x0000, 0x3333, 0x3333, 0x6E00 # U+0075 (u)
@DW 0x0000, 0x3333, 0x331E, 0x0C00 # U+0076 (v)
@DW 0x0000, 0x636B, 0x7F7F, 0x3600 # U+0077 (w)
@DW 0x0000, 0x6336, 0x1C36, 0x6300 # U+0078 (x)
@DW 0x0000, 0x3333, 0x333E, 0x301F # U+0079 (y)
@DW 0x0000, 0x3F19, 0x0C26, 0x3F00 # U+007A (z)
@DW 0x380C, 0x0C07, 0x0C0C, 0x3800 # U+007B ({)
@DW 0x1818, 0x1800, 0x1818, 0x1800 # U+007C (|)
@DW 0x070C, 0x0C38, 0x0C0C, 0x0700 # U+007D (})
@DW 0x6E3B, 0x0000, 0x0000, 0x0000 # U+007E (~)