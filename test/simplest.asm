# Instruction count: 135

@ORG 0x00000000

# Select frame buffer 0 for writes and clear it
ld.w r0, 0x0000
fsel r0
ld.w r0, 0x00EC # bgcolor
clf r0
branch main
# Select frame buffer 1 so we can see frame buffer 0
ld.w r0, 0x0001
fsel r0
@LABEL infloop
vsync
jmp infloop
# End of program

@LABEL TileSprite
lea r0, TileSprite_height
pop r1
st.w r0, r1
lea r0, TileSprite_width
pop r1
st.w r0, r1
lea r0, TileSprite_posY
pop r1
st.w r0, r1
lea r0, TileSprite_posX
pop r1
st.w r0, r1
ld.w r0, 0x0
lea r1, TileSprite_j
st.w [r1], r0
lea r0, TileSprite_posY
ld.w r0, [r0]
lea r1, TileSprite_spanY
st.w [r1], r0

@LABEL beginwhile2
lea r0, TileSprite_spanY
ld.w r0, [r0]
lea r1, TileSprite_height
ld.w r1, [r1]
lea r2, TileSprite_posY
ld.w r2, [r2]
iadd r1, r2
cmp r0, r1
test less
jmpifnot endwhile3
ld.w r0, 0x0
lea r1, TileSprite_i
st.w [r1], r0
lea r0, TileSprite_posX
ld.w r0, [r0]
lea r1, TileSprite_spanX
st.w [r1], r0

@LABEL beginwhile0
lea r0, TileSprite_spanX
ld.w r0, [r0]
lea r1, TileSprite_width
ld.w r1, [r1]
lea r2, TileSprite_posX
ld.w r2, [r2]
iadd r1, r2
cmp r0, r1
test less
jmpifnot endwhile1
lea r0, TileSprite_i
ld.w r0, [r0]
ld.w r1, 0x10
lea r2, TileSprite_j
ld.w r2, [r2]
imul r1, r2
iadd r0, r1
lea r1, _sprite
iadd r0, r1
ld.b r0, [r0] # RHS, valueof
ld.w r1, 0x8000
ld.w r2, 0x10
bsl r1, r2
ld.w r2, 0x100
lea r3, TileSprite_spanY
ld.w r3, [r3]
imul r2, r3
lea r3, TileSprite_spanX
ld.w r3, [r3]
iadd r2, r3
or r1, r2
lea r2, _VRAM
ld.w r2, [r2]
iadd r1, r2
st.b [r1], r0
ld.w r0, 0x1
lea r1, TileSprite_spanX
ld.w r1, [r1]
iadd r0, r1
lea r1, TileSprite_spanX
st.w [r1], r0
ld.w r0, 0x1
lea r1, TileSprite_i
ld.w r1, [r1]
iadd r0, r1
lea r1, TileSprite_i
st.w [r1], r0
jmp beginwhile0

@LABEL endwhile1
ld.w r0, 0x1
lea r1, TileSprite_spanY
ld.w r1, [r1]
iadd r0, r1
lea r1, TileSprite_spanY
st.w [r1], r0
ld.w r0, 0x1
lea r1, TileSprite_j
ld.w r1, [r1]
iadd r0, r1
lea r1, TileSprite_j
st.w [r1], r0
jmp beginwhile2

@LABEL endwhile3
ret 

@LABEL main
ld.w r0, 0x20
push r0
ld.w r0, 0x30
push r0
ld.w r0, 0x10
push r0
ld.w r0, 0x10
push r0
branch TileSprite
ld.w r0, 0x60
push r0
ld.w r0, 0x40
push r0
ld.w r0, 0x10
push r0
ld.w r0, 0x10
push r0
branch TileSprite
ret 

#-------------Symbol Table-------------

@LABEL _loword
# ref:0 dim:1 typename:word
@DW 0x7FFFFFFF 
@LABEL _VRAM
# ref:0 dim:1 typename:byteptr
@DW 0x0000 0x0000
@LABEL _sprite
# ref:0 dim:256 typename:byte
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 0xFFFF 
@DW 0xFFFF 0xFFFF 0x0000 0x0000 0x0000 0x0000 0x0000 0x00FF 
@DW 0xFFFF 0xFF00 0xF69A 0x9A9A 0x9A9A 0x9A9A 0x9A9A 0x5100 
@DW 0xFFFF 0xFF00 0x9A09 0x0909 0x0909 0x0909 0x0909 0x5100 
@DW 0xFFFF 0xFF00 0x9A09 0x0909 0x0909 0x0909 0x0909 0x5100 
@DW 0xFFFF 0xFF00 0x9A09 0x0909 0x0909 0x0909 0x0909 0x5100 
@DW 0xFFFF 0xFF00 0x9A09 0x0909 0x0909 0x0909 0x0909 0x5100 
@DW 0xFFFF 0xFF00 0x9A09 0x0909 0x0909 0x0909 0x0909 0x5100 
@DW 0xFFFF 0xFF00 0x9A09 0x0909 0x0909 0x0909 0x0909 0x5151 
@LABEL TileSprite_spanX
# ref:0 dim:1 typename:word
@DW 0x7FFFFFFF 
@LABEL TileSprite_spanY
# ref:0 dim:1 typename:word
@DW 0x7FFFFFFF 
@LABEL TileSprite_i
# ref:0 dim:1 typename:word
@DW 0x7FFFFFFF 
@LABEL TileSprite_j
# ref:0 dim:1 typename:word
@DW 0x7FFFFFFF 
@LABEL TileSprite_height
# ref:0 dim:1 typename:word
@DW 0xCDCDCDCD 
@LABEL TileSprite_width
# ref:0 dim:1 typename:word
@DW 0xCDCDCDCD 
@LABEL TileSprite_posY
# ref:0 dim:1 typename:word
@DW 0xCDCDCDCD 
@LABEL TileSprite_posX
# ref:0 dim:1 typename:word
@DW 0xCDCDCDCD 
