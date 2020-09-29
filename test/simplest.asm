# Instruction count: 181

@ORG 0x00000000

branch main
@LABEL infloop
vsync
jmp infloop
# End of program

@LABEL Sprite
lea r0, Sprite_posY
pop r1
st.w r0, r1
lea r0, Sprite_posX
pop r1
st.w r0, r1
ld.w r0, 0x0
lea r1, Sprite_spanY
st.w [r1], r0

@LABEL beginwhile2
lea r0, Sprite_spanY
ld.w r0, [r0]
ld.w r1, 0x17
cmp r0, r1
test less
jmpifnot endwhile3
ld.w r0, 0x0
lea r1, Sprite_spanX
st.w [r1], r0

@LABEL beginwhile0
lea r0, Sprite_spanX
ld.w r0, [r0]
ld.w r1, 0x10
cmp r0, r1
test less
jmpifnot endwhile1
lea r0, Sprite_spanX
ld.w r0, [r0]
lea r1, Sprite_spanY
ld.w r1, [r1]
ld.w r2, 0x4
bsl r1, r2
iadd r0, r1
lea r1, _sprite
iadd r0, r1
ld.b r0, [r0] # RHS, valueof
lea r1, Sprite_posY
ld.w r1, [r1]
lea r2, Sprite_spanY
ld.w r2, [r2]
iadd r1, r2
ld.w r2, 0x8
bsl r1, r2
lea r2, Sprite_posX
ld.w r2, [r2]
lea r3, Sprite_spanX
ld.w r3, [r3]
iadd r2, r3
iadd r1, r2
lea r2, _VRAM
ld.d r2, [r2]
iadd r1, r2
st.b [r1], r0
ld.w r0, 0x1
lea r1, Sprite_spanX
ld.w r1, [r1]
iadd r0, r1
lea r1, Sprite_spanX
st.w [r1], r0
jmp beginwhile0

@LABEL endwhile1
ld.w r0, 0x1
lea r1, Sprite_spanY
ld.w r1, [r1]
iadd r0, r1
lea r1, Sprite_spanY
st.w [r1], r0
jmp beginwhile2

@LABEL endwhile3
ret 

@LABEL main

@LABEL beginwhile8
lea r0, main_forever
ld.w r0, [r0]
ld.w r1, 0x1
cmp r0, r1
test equal
jmpifnot endwhile9
ld.w r0, 0xff
clf r0
lea r0, main_posX
ld.w r0, [r0]
push r0
lea r0, main_posY
ld.w r0, [r0]
push r0
branch Sprite
lea r0, main_dirX
ld.w r0, [r0]
lea r1, main_posX
ld.w r1, [r1]
iadd r0, r1
lea r1, main_posX
st.w [r1], r0
lea r0, main_dirY
ld.w r0, [r0]
lea r1, main_posY
ld.w r1, [r1]
iadd r0, r1
lea r1, main_posY
st.w [r1], r0
lea r0, main_posY
ld.w r0, [r0]
ld.w r1, 0xa7
cmp r0, r1
test greater
jmpifnot endif4
lea r0, main_dirY
ld.w r0, [r0]
ineg r0
lea r1, main_dirY
st.w [r1], r0

@LABEL endif4
lea r0, main_posY
ld.w r0, [r0]
ld.w r1, 0x2
cmp r0, r1
test less
jmpifnot endif5
lea r0, main_dirY
ld.w r0, [r0]
ineg r0
lea r1, main_dirY
st.w [r1], r0

@LABEL endif5
lea r0, main_posX
ld.w r0, [r0]
ld.w r1, 0xee
cmp r0, r1
test greater
jmpifnot endif6
lea r0, main_dirX
ld.w r0, [r0]
ineg r0
lea r1, main_dirX
st.w [r1], r0

@LABEL endif6
lea r0, main_posX
ld.w r0, [r0]
ld.w r1, 0x2
cmp r0, r1
test less
jmpifnot endif7
lea r0, main_dirX
ld.w r0, [r0]
ineg r0
lea r1, main_dirX
st.w [r1], r0

@LABEL endif7
vsync 
lea r0, main_frame
ld.w r0, [r0]
fsel r0
ld.w r0, 0x1
lea r1, main_frame
ld.w r1, [r1]
iadd r0, r1
lea r1, main_frame
st.w [r1], r0
jmp beginwhile8

@LABEL endwhile9

#-------------Symbol Table-------------

@LABEL _VRAM
# ref:0 dim:1 typename:byteptr
@DW 0x8000 0x0000
@LABEL _loword
# ref:0 dim:1 typename:word
@DW 0x0000 
@LABEL _sprite
# ref:0 dim:368 typename:byte
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFF0B 0x1353 0x0B13 0xF6FF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFF01 0x134E 0x4E06 0x6E0E 0x04EE 0xFFFF 
@DW 0xFFFF 0xFFFF 0x094E 0x0E4E 0x4E67 0x7FFF 0x0BAE 0xFFFF 
@DW 0xFFFF 0xFF13 0x0497 0x4E4E 0x0109 0x1353 0x0009 0xEEFF 
@DW 0xFFFF 0x1304 0x4E8F 0x0101 0x0000 0x0000 0x0000 0x00F6 
@DW 0xFFFF 0x00F7 0x0009 0x0056 0x0016 0x000C 0xACEE 0xACF6 
@DW 0xFF13 0xAE26 0xAE00 0x16F7 0x00EF 0x00AE 0x6E24 0xF7FF 
@DW 0xFF01 0xEF09 0xFF00 0x01FF 0xA4FF 0x64F7 0xAE6E 0x64F6 
@DW 0xFF01 0x0B27 0xFF00 0xA4FF 0x13AF 0xAFAF 0xAFEF 0x146E 
@DW 0xFF64 0x000B 0xF703 0xFF13 0x0003 0x0B0B 0x0B0B 0x54F7 
@DW 0xFFFF 0x6300 0x2716 0xF70B 0x1400 0x0000 0x0009 0xF6FF 
@DW 0xFFFF 0xFFA3 0x090C 0x1616 0x260B 0x0053 0x63F6 0xFFFF 
@DW 0xFFFF 0xFFAE 0x038E 0x1651 0x136C 0xA1EC 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFF00 0x560B 0x0FA0 0xECFC 0xFCA3 0xE4F6 0xFFFF 
@DW 0xFFFF 0xFF01 0x6E6C 0x6E11 0xFFFF 0xF3FF 0x91EC 0xFFFF 
@DW 0xFFFF 0xFF0B 0xFFFF 0xF60B 0xF6F6 0xF4FE 0x89EC 0xFFFF 
@DW 0xFFFF 0xFF03 0xFFFF 0x03E9 0xA188 0xABE9 0x93F6 0xFFFF 
@DW 0xFFFF 0xFF24 0xB6F7 0x1363 0x5149 0x5093 0xF6FF 0xFFFF 
@DW 0xFFFF 0xFFFF 0x0114 0x1414 0x110B 0x1364 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0x0013 0x090B 0x6E00 0x6C00 0xACFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0x0909 0x4911 0x0911 0x0909 0xEEFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@LABEL Sprite_spanX
# ref:0 dim:1 typename:word
@DW 0xCDCDCDCD 
@LABEL Sprite_spanY
# ref:0 dim:1 typename:word
@DW 0xCDCDCDCD 
@LABEL Sprite_posY
# ref:0 dim:1 typename:word
@DW 0xCDCDCDCD 
@LABEL Sprite_posX
# ref:0 dim:1 typename:word
@DW 0xCDCDCDCD 
@LABEL main_forever
# ref:0 dim:1 typename:word
@DW 0x0001 
@LABEL main_frame
# ref:0 dim:1 typename:word
@DW 0x0000 
@LABEL main_posX
# ref:0 dim:1 typename:word
@DW 0x0008 
@LABEL main_dirX
# ref:0 dim:1 typename:word
@DW 0x0002 
@LABEL main_posY
# ref:0 dim:1 typename:word
@DW 0x0008 
@LABEL main_dirY
# ref:0 dim:1 typename:word
@DW 0x0001 
