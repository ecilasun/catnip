// Instruction count: 92

@label test
pop test:thing
ld r0, 0x00000000
lea r1, test:thing
add r0, r1, r0
ld [r0], r0
ld r1, 0x00000001
lea r2, test:thing
add r1, r2, r1
st [r1], r0
ret 

@label DrawRect
pop DrawRect:height
pop DrawRect:width
pop DrawRect:posY
pop DrawRect:posX
ld r0, [DrawRect:posY]
lea r1 spanY
st [r1], r0

@label beginwhile2
ld r0, [DrawRect:spanY]
ld r1, [DrawRect:posY]
ld r2, [DrawRect:height]
add r1, r1, r2
cmp.l r0, r0, r1
jmpz r0, endwhile3
ld r0, [DrawRect:posX]
lea r1 spanX
st [r1], r0

@label beginwhile0
ld r0, [DrawRect:spanX]
ld r1, [DrawRect:posX]
ld r2, [DrawRect:width]
add r1, r1, r2
cmp.l r0, r0, r1
jmpz r0, endwhile1
ld r0, 0x00000004
ld r1, [DrawRect:spanX]
mod r0, r0, r1
ld r1, 0x00000004
ld r2, 0x00000008
ld r3, [DrawRect:spanY]
mod r2, r2, r3
mul r1, r1, r2
add r0, r0, r1
lea r1, :sprite
add r0, r1, r0
ld [r0], r0
lea r1 spanX
ld r2, 0x00000140
lea r3 spanY
mul r2, r2, r3
add r1, r1, r2
lea r2, :VRAM
add r1, r2, r1
st [r1], r0
ld r0, [DrawRect:spanX]
ld r1, 0x00000001
add r0, r0, r1
lea r1 spanX
st [r1], r0
jmp beginwhile0

@label endwhile1
ld r0, [DrawRect:spanY]
ld r1, 0x00000001
add r0, r0, r1
lea r1 spanY
st [r1], r0
jmp beginwhile2

@label endwhile3

@label main
ld r0, 0x00000002
lea r1, :banana
add r0, r1, r0
ld [r0], r0
push r0
ld r0, 0x00000000
push r0
ld r0, 0x00000200
ld r1, 0x00000003
add r0, r0, r1
ld r1, [:cursorY]
sub r0, r0, r1
push r0
ld r0, 0x00000180
push r0
call DrawRect
ld r0, [DrawRect:spanX]
ld r1, 0x00000040
cmp.g r0, r0, r1
jmpz r0, endif4
ld r0, 0x00000040
push r0
ld r0, 0x00000040
push r0
ld r0, 0x00000080
push r0
ld r0, 0x00000060
push r0
call DrawRect

@label endif4

//-------------Symbol Table-------------

// function 'test', hash: BC2C0BE9, refcount: 0
// function 'DrawRect', hash: 032D1965, refcount: 2
// function 'main', hash: BC76E6BA, refcount: 0
@label :cursorX
// reference count 0
// array length 1
@dword 0xCDCDCDCD 
@label :cursorY
// reference count 0
// array length 1
@dword 0xCDCDCDCD 
@label :VRAM
// reference count 0
// array length 1
@dword 0x80000000 
@label :banana
// reference count 0
// array length 16
@dword 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 
@dword 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 
@dword 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 
@dword 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 0xCDCDCDCD 
@dword 
@label :tree
// reference count 0
// array length 4
@dword 0x00000001 0x00000002 0x00000003 0x00000004 
@dword 
@label :sprite
// reference count 0
// array length 32
@dword 0xfffffffa 0xfffffffb 0xfffffffc 0xfffffffd 
@dword 0xfffffffe 0xffffffff 0xffffff00 0xffffff01 
@dword 0xfffffffa 0xfffffffb 0xfffffffc 0xfffffffd 
@dword 0xfffffffa 0xfffffffb 0xfffffffc 0xfffffffd 
@dword 0xfffffffa 0xf00ffffb 0xfffffffc 0xfffffffd 
@dword 0xfffffffa 0xfffffffb 0xff222ffc 0xfffffffd 
@dword 0xfffffffa 0xfffffffb 0xfffffffc 0xfffffffd 
@dword 0xfffffffa 0xfffffffb 0xfffffffc 0xffedcafd 
@dword 
@label test:thing
// reference count 0
// array length 1
@label DrawRect:spanX
// reference count 0
// array length 1
@dword 0xCDCDCDCD 
@label DrawRect:spanY
// reference count 0
// array length 1
@dword 0xCDCDCDCD 
@label DrawRect:height
// reference count 0
// array length 1
@label DrawRect:width
// reference count 0
// array length 1
@label DrawRect:posY
// reference count 0
// array length 1
@label DrawRect:posX
// reference count 0
// array length 1
