// Instruction count: 94

@label test
pop test:thing
ld.w r0, 0x0
lea r1, test:thing
add r0, r1, r0*4
ld.d r0, [r0]
ld.w r1, 0x1
lea r2, test:thing
add r1, r2, r1*4
ld.d r1, [r1]
add r0, r0, r1
lea r1, test:result
st.d r1, r0

@label DrawRect
pop DrawRect:height
pop DrawRect:width
pop DrawRect:posY
pop DrawRect:posX
ld.w r0, [DrawRect:posY]
lea r1, DrawRect:spanY
st.w r1, r0

@label beginwhile2
ld.w r0, [DrawRect:spanY]
ld.w r1, [DrawRect:posY]
ld.w r2, [DrawRect:height]
add r1, r1, r2
cmp.l r0, r1
jmpz endwhile3
ld.w r0, [DrawRect:posX]
lea r1, DrawRect:spanX
st.w r1, r0

@label beginwhile0
ld.w r0, [DrawRect:spanX]
ld.w r1, [DrawRect:posX]
ld.w r2, [DrawRect:width]
add r1, r1, r2
cmp.l r0, r1
jmpz endwhile1
ld.w r0, 0x4
ld.w r1, [DrawRect:spanX]
mod r0, r0, r1
ld.w r1, 0x4
ld.w r2, 0x8
ld.w r3, [DrawRect:spanY]
mod r2, r2, r3
mul r1, r1, r2
add r0, r0, r1
lea r1, :sprite
add r0, r1, r0*1
ld.b r0, [r0]
lea r1, DrawRect:spanX
ld.w r2, 0x140
lea r3, DrawRect:spanY
mul r2, r2, r3
add r1, r1, r2
lea r2, :VRAM
add r1, r2, r1*1
st.b r1, r0
ld.w r0, [DrawRect:spanX]
ld.w r1, 0x1
add r0, r0, r1
lea r1, DrawRect:spanX
st.w r1, r0
jmp beginwhile0

@label endwhile1
ld.w r0, [DrawRect:spanY]
ld.w r1, 0x1
add r0, r0, r1
lea r1, DrawRect:spanY
st.w r1, r0
jmp beginwhile2

@label endwhile3

@label main
ld.w r0, 0x2
lea r1, :tree
add r0, r1, r0*4
ld.d r0, [r0]
push r0
ld.w r0, 0x0
push r0
ld.w r0, 0x200
ld.w r1, 0x3
add r0, r0, r1
ld.d r1, [:cursorY]
sub r0, r0, r1
push r0
ld.w r0, 0x180
push r0
call DrawRect
ld.w r0, [DrawRect:spanX]
ld.w r1, 0x40
cmp.g r0, r1
jmpz endif4
ld.w r0, 0x1
push r0
call test
ld.w r0, 0x2
ld.d r1, [test:result]
mul r0, r0, r1
lea r1, main:A
st.d r1, r0

@label endif4

//-------------Symbol Table-------------

@label :cursorX
// ref:0 dim:1 typename:dword
@dword 0xCDCDCDCD 
@label :cursorY
// ref:0 dim:1 typename:dword
@dword 0xCDCDCDCD 
@label :VRAM
// ref:0 dim:1 typename:byte
@byte 0x80000000 
@label :banana
// ref:0 dim:16 typename:dword
@dword 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 
@dword 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 
@dword 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 
@dword 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 
@dword 
@label :tree
// ref:0 dim:4 typename:dword
@dword 0x1 0x2 0x3 0x4 
@dword 
@label :sprite
// ref:0 dim:32 typename:byte
@byte 0xff 0xff 0xff 0xfa 0xff 0xff 0xff 0xfb 0xff 0xff 0xff 0xfc 0xff 0xff 0xff 0xfd 
@byte 0xff 0xff 0xff 0xfe 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0x0 0xff 0xff 0xff 0x1 
@byte 0xff 0xff 0xff 0xfa 0xff 0xff 0xff 0xfb 0xff 0xff 0xff 0xfc 0xff 0xff 0xff 0xfd 
@byte 0xff 0xff 0xff 0xfa 0xff 0xff 0xff 0xfb 0xff 0xff 0xff 0xfc 0xff 0xff 0xff 0xfd 
@byte 0xff 0xff 0xff 0xfa 0xf0 0xf 0xff 0xfb 0xff 0xff 0xff 0xfc 0xff 0xff 0xff 0xfd 
@byte 0xff 0xff 0xff 0xfa 0xff 0xff 0xff 0xfb 0xff 0x22 0x2f 0xfc 0xff 0xff 0xff 0xfd 
@byte 0xff 0xff 0xff 0xfa 0xff 0xff 0xff 0xfb 0xff 0xff 0xff 0xfc 0xff 0xff 0xff 0xfd 
@byte 0xff 0xff 0xff 0xfa 0xff 0xff 0xff 0xfb 0xff 0xff 0xff 0xfc 0xff 0xed 0xca 0xfd 
@byte 
@label test:result
// ref:0 dim:1 typename:dword
@dword 0xCDCDCDCD 
@label test:thing
// ref:0 dim:1 typename:dword
@label DrawRect:spanX
// ref:0 dim:1 typename:word
@word 0xCDCDCDCD 
@label DrawRect:spanY
// ref:0 dim:1 typename:word
@word 0xCDCDCDCD 
@label DrawRect:height
// ref:0 dim:1 typename:word
@label DrawRect:width
// ref:0 dim:1 typename:word
@label DrawRect:posY
// ref:0 dim:1 typename:word
@label DrawRect:posX
// ref:0 dim:1 typename:word
@label main:A
// ref:0 dim:1 typename:dword
@dword 0xCDCDCDCD 
@label main:B
// ref:0 dim:1 typename:dword
@dword 0xCDCDCDCD 
