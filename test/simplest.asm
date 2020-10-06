# Instruction count: 262

@ORG 0x00000000

call main
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
ld.d r0, 0x0
lea r1, Sprite_y
st.w [r1], r0

@LABEL beginwhile2
lea r0, Sprite_y
ld.w r0, [r0]
ld.d r1, 0x17
cmp r0, r1
test r0, less
jmpifnot endwhile3, r0
ld.d r0, 0x0
lea r1, Sprite_x
st.w [r1], r0

@LABEL beginwhile0
lea r0, Sprite_x
ld.w r0, [r0]
ld.d r1, 0x10
cmp r0, r1
test r0, less
jmpifnot endwhile1, r0
lea r0, Sprite_x
ld.w r0, [r0]
lea r1, Sprite_y
ld.w r1, [r1]
ld.d r2, 0x4
bsl r1, r2
iadd r0, r1
lea r1, _sprite
iadd r0, r1
ld.b r0, [r0] # RHS, valueof
lea r1, Sprite_posY
ld.w r1, [r1]
lea r2, Sprite_y
ld.w r2, [r2]
iadd r1, r2
ld.d r2, 0x8
bsl r1, r2
lea r2, Sprite_posX
ld.w r2, [r2]
lea r3, Sprite_x
ld.w r3, [r3]
iadd r2, r3
iadd r1, r2
lea r2, _VRAM
ld.d r2, [r2]
iadd r1, r2
st.b [r1], r0
lea r0, Sprite_x
ld.w r0, [r0]
inc r0
lea r1, Sprite_x
st.w [r1], r0
jmp beginwhile0

@LABEL endwhile1
lea r0, Sprite_y
ld.w r0, [r0]
inc r0
lea r1, Sprite_y
st.w [r1], r0
jmp beginwhile2

@LABEL endwhile3
ret 

@LABEL MaskedSprite
lea r0, MaskedSprite_posY
pop r1
st.w r0, r1
lea r0, MaskedSprite_posX
pop r1
st.w r0, r1
ld.d r0, 0x0
lea r1, MaskedSprite_y
st.w [r1], r0

@LABEL beginwhile7
lea r0, MaskedSprite_y
ld.w r0, [r0]
ld.d r1, 0x17
cmp r0, r1
test r0, less
jmpifnot endwhile8, r0
ld.d r0, 0x0
lea r1, MaskedSprite_x
st.w [r1], r0

@LABEL beginwhile5
lea r0, MaskedSprite_x
ld.w r0, [r0]
ld.d r1, 0x10
cmp r0, r1
test r0, less
jmpifnot endwhile6, r0
lea r0, MaskedSprite_x
ld.w r0, [r0]
lea r1, MaskedSprite_y
ld.w r1, [r1]
ld.d r2, 0x4
bsl r1, r2
iadd r0, r1
lea r1, _sprite
iadd r0, r1
ld.b r0, [r0] # RHS, valueof
lea r1, MaskedSprite_K
st.w [r1], r0
lea r0, MaskedSprite_K
ld.w r0, [r0]
ld.d r1, 0xff
cmp r0, r1
test r0, notequal
jmpifnot endif4, r0
lea r0, MaskedSprite_K
ld.w r0, [r0]
lea r1, MaskedSprite_posY
ld.w r1, [r1]
lea r2, MaskedSprite_y
ld.w r2, [r2]
iadd r1, r2
ld.d r2, 0x8
bsl r1, r2
lea r2, MaskedSprite_posX
ld.w r2, [r2]
lea r3, MaskedSprite_x
ld.w r3, [r3]
iadd r2, r3
iadd r1, r2
lea r2, _VRAM
ld.d r2, [r2]
iadd r1, r2
st.b [r1], r0

@LABEL endif4
lea r0, MaskedSprite_x
ld.w r0, [r0]
inc r0
lea r1, MaskedSprite_x
st.w [r1], r0
jmp beginwhile5

@LABEL endwhile6
lea r0, MaskedSprite_y
ld.w r0, [r0]
inc r0
lea r1, MaskedSprite_y
st.w [r1], r0
jmp beginwhile7

@LABEL endwhile8
ret 

@LABEL main

@LABEL beginwhile11
ld.d r0, 0x1
jmpifnot endwhile12, r0
ld.d r0, 0xec
clf r0
lea r0, main_frame
ld.w r0, [r0]
ld.d r1, 0x4
bsr r0, r1
ld.d r1, 0x0
lea r2, _BORDERCOLOR
ld.d r2, [r2]
iadd r1, r2
st.b [r1], r0
ld.d r0, 0x30
push r0
ld.d r0, 0x30
push r0
call Sprite
lea r0, main_posX
ld.w r0, [r0]
push r0
lea r0, main_posY
ld.w r0, [r0]
push r0
call MaskedSprite
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
ld.d r1, 0xa9
cmp r0, r1
test r0, greater
lea r1, main_posY
ld.w r1, [r1]
ld.d r2, 0x8
cmp r1, r2
test r1, less
or r0, r1
jmpifnot endif9, r0
lea r0, main_dirY
ld.w r0, [r0]
ineg r0
lea r1, main_dirY
st.w [r1], r0

@LABEL endif9
lea r0, main_posX
ld.w r0, [r0]
ld.d r1, 0xf0
cmp r0, r1
test r0, greater
lea r1, main_posX
ld.w r1, [r1]
ld.d r2, 0x1
cmp r1, r2
test r1, less
or r0, r1
jmpifnot endif10, r0
lea r0, main_dirX
ld.w r0, [r0]
ineg r0
lea r1, main_dirX
st.w [r1], r0

@LABEL endif10
vsync 
lea r0, main_frame
ld.w r0, [r0]
fsel r0
lea r0, main_frame
ld.w r0, [r0]
inc r0
lea r1, main_frame
st.w [r1], r0
jmp beginwhile11

@LABEL endwhile12

#-------------Symbol Table-------------

# function 'Sprite', hash: E90371F2, refcount: 1
# function 'MaskedSprite', hash: 4978B879, refcount: 1
# function 'main', hash: BC76E6BA, refcount: 1
@LABEL _VRAM
# dim:1 typename:byteptr refcount:4
@DW 0x8000 0x0000
@LABEL _BORDERCOLOR
# dim:1 typename:byteptr refcount:2
@DW 0x8000 0xC000
@LABEL _sprite
# dim:368 typename:byte refcount:4
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFF0B 0x1353 0x0B13 0xF6FF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFF01 0x134E 0x4E06 0x6E0E 0x04EE 0xFFFF 
@DW 0xFFFF 0xFFFF 0x094E 0x0E4E 0x4E67 0x7FFE 0x0BAE 0xFFFF 
@DW 0xFFFF 0xFF13 0x0497 0x4E4E 0x0109 0x1353 0x0009 0xEEFF 
@DW 0xFFFF 0x1304 0x4E8F 0x0101 0x0000 0x0000 0x0000 0x00F6 
@DW 0xFFFF 0x00F7 0x0009 0x0056 0x0016 0x000C 0xACEE 0xACF6 
@DW 0xFF13 0xAE26 0xAE00 0x16F7 0x00EF 0x00AE 0x6E24 0xF7FF 
@DW 0xFF01 0xEF09 0xFE00 0x01FE 0xA4FE 0x64F7 0xAE6E 0x64F6 
@DW 0xFF01 0x0B27 0xFE00 0xA4FE 0x13AF 0xAFAF 0xAFEF 0x146E 
@DW 0xFF64 0x000B 0xF703 0xFE13 0x0003 0x0B0B 0x0B0B 0x54F7 
@DW 0xFFFF 0x6300 0x2716 0xF70B 0x1400 0x0000 0x0009 0xF6FF 
@DW 0xFFFF 0xFFA3 0x090C 0x1616 0x260B 0x0053 0x63F6 0xFFFF 
@DW 0xFFFF 0xFFAE 0x038E 0x1651 0x136C 0xA1EC 0xFEFF 0xFFFF 
@DW 0xFFFF 0xFF00 0x560B 0x0FA0 0xECFC 0xFCA3 0xE4F6 0xFFFF 
@DW 0xFFFF 0xFF01 0x6E6C 0x6E11 0xFEFE 0xF3FE 0x91EC 0xFFFF 
@DW 0xFFFF 0xFF0B 0xFEFE 0xF60B 0xF6F6 0xF4FE 0x89EC 0xFFFF 
@DW 0xFFFF 0xFF03 0xFEFE 0x03E9 0xA188 0xABE9 0x93F6 0xFFFF 
@DW 0xFFFF 0xFF24 0xB6F7 0x1363 0x5149 0x5093 0xF6FF 0xFFFF 
@DW 0xFFFF 0xFFFF 0x0114 0x1414 0x110B 0x1364 0xFEFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0x0013 0x090B 0x6E00 0x6C00 0xACFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0x0909 0x4911 0x0911 0x0909 0xEEFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@LABEL Sprite_x
# dim:1 typename:word refcount:12
@DW 0xCDCDCDCD 
@LABEL Sprite_y
# dim:1 typename:word refcount:12
@DW 0xCDCDCDCD 
@LABEL Sprite_posY
# dim:1 typename:word refcount:2
@DW 0xCDCDCDCD 
@LABEL Sprite_posX
# dim:1 typename:word refcount:2
@DW 0xCDCDCDCD 
@LABEL MaskedSprite_x
# dim:1 typename:word refcount:12
@DW 0xCDCDCDCD 
@LABEL MaskedSprite_y
# dim:1 typename:word refcount:12
@DW 0xCDCDCDCD 
@LABEL MaskedSprite_K
# dim:1 typename:word refcount:6
@DW 0xCDCDCDCD 
@LABEL MaskedSprite_posY
# dim:1 typename:word refcount:2
@DW 0xCDCDCDCD 
@LABEL MaskedSprite_posX
# dim:1 typename:word refcount:2
@DW 0xCDCDCDCD 
@LABEL main_frame
# dim:1 typename:word refcount:8
@DW 0x0000 
@LABEL main_posX
# dim:1 typename:word refcount:10
@DW 0x0080 
@LABEL main_dirX
# dim:1 typename:word refcount:6
@DW 0x0001 
@LABEL main_posY
# dim:1 typename:word refcount:10
@DW 0x0040 
@LABEL main_dirY
# dim:1 typename:word refcount:6
@DW 0x0001 
