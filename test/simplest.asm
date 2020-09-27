# Instruction count: 34

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

@LABEL main
ld.w r0, 0x8000
ld.w r1, 0x10
bsl r0, r1
lea r1, _VRAM
st.b [r1], r0

@LABEL beginwhile0
lea r0, _loword
ld.w r0, [r0]
ld.w r1, 0xc000
cmp r0, r1
test less
jmpifnot endwhile1
ld.w r0, 0xff
lea r1, _loword
ld.w r1, [r1]
lea r2, _VRAM
ld.w r2, [r2]
iadd r1, r2
ld.b r1, [r1]
st.b [r1], r0
lea r0, _loword
ld.w r0, [r0]
ld.w r1, 0x1
iadd r0, r1
lea r1, _loword
st.w [r1], r0
jmp beginwhile0

@LABEL endwhile1
ret 

#-------------Symbol Table-------------

@LABEL _loword
# ref:0 dim:1 typename:word
@DW 0x0000 
@LABEL _VRAM
# ref:0 dim:1 typename:byte
@DW 0x0281 
