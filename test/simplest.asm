# Instruction count: 94

@ORG 0x00000000

# Select frame buffer 0 for writes and clear it
ld.w r0, 0x0000
fsel r0
ld.w r0, 0x00E0
clf r0
branch main
# Select frame buffer 1 so we can see frame buffer 0
ld.w r0, 0x0001
fsel r0
halt
# End of program

@LABEL DrawRect
lea r0, DrawRect:height
pop r1
st.w r0, r1
lea r0, DrawRect:width
pop r1
st.w r0, r1
lea r0, DrawRect:posY
pop r1
st.w r0, r1
lea r0, DrawRect:posX
pop r1
st.w r0, r1
ld.w r0, [DrawRect:posY]
lea r1, DrawRect:spanY
st.w r1, r0

@LABEL beginwhile2
ld.w r0, [DrawRect:spanY]
ld.w r1, [DrawRect:posY]
ld.w r2, [DrawRect:height]
iadd r1, r2
cmp r0, r1
test less
jmpifnot endwhile3
ld.w r0, [DrawRect:posX]
lea r1, DrawRect:spanX
st.w r1, r0

@LABEL beginwhile0
ld.w r0, [DrawRect:spanX]
ld.w r1, [DrawRect:posX]
ld.w r2, [DrawRect:width]
iadd r1, r2
cmp r0, r1
test less
jmpifnot endwhile1
ld.w r0, 0x10
ld.w r1, [DrawRect:spanX]
imod r0, r1
ld.w r1, 0x10
ld.w r2, 0x8
ld.w r3, [DrawRect:spanY]
imod r2, r3
imul r1, r2
iadd r0, r1
lea r1, :sprite
iadd r0, r1
ld.b r0, [r0]
ld.d r1, 0x10000
ld.w r2, 0x8000
imul r1, r2
lea r2, DrawRect:spanX
iadd r1, r2
ld.w r2, 0x140
lea r3, DrawRect:spanY
imul r2, r3
iadd r1, r2
lea r2, :VRAM
ld.w r2, [r2]
iadd r1, r2
st.b r1, r0
ld.w r0, [DrawRect:spanX]
ld.w r1, 0x1
iadd r0, r1
lea r1, DrawRect:spanX
st.w r1, r0
jmp beginwhile0

@LABEL endwhile1
ld.w r0, [DrawRect:spanY]
ld.w r1, 0x1
iadd r0, r1
lea r1, DrawRect:spanY
st.w r1, r0
jmp beginwhile2

@LABEL endwhile3
ret 

@LABEL main
ld.w r0, 0x0
push r0
ld.w r0, 0x0
push r0
ld.w r0, 0x10
push r0
ld.w r0, 0x10
push r0
branch DrawRect
ret 

#-------------Symbol Table-------------

@LABEL :VRAM
# ref:0 dim:1 typename:byte
@DW 0x0000 
@LABEL :sprite
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
@LABEL DrawRect:spanX
# ref:0 dim:1 typename:word
@DW 0x7FFFFFFF 
@LABEL DrawRect:spanY
# ref:0 dim:1 typename:word
@DW 0x7FFFFFFF 
@LABEL DrawRect:height
# ref:0 dim:1 typename:word
@DW 0xCDCDCDCD 
@LABEL DrawRect:width
# ref:0 dim:1 typename:word
@DW 0xCDCDCDCD 
@LABEL DrawRect:posY
# ref:0 dim:1 typename:word
@DW 0xCDCDCDCD 
@LABEL DrawRect:posX
# ref:0 dim:1 typename:word
@DW 0xCDCDCDCD 
